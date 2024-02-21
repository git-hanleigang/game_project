---
--xcyy
--2018年5月23日
--ToroLocoJackpotWinView.lua
local PublicConfig = require "ToroLocoPublicConfig"
local ToroLocoJackpotWinView = class("ToroLocoJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}
function ToroLocoJackpotWinView:initUI(params)
    --jackpot类型统一转化为小写
    local viewType = string.lower(params.jackpotType) 
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine
    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    if self.m_jackpotIndex == 1 then
        self:createCsbNode("ToroLoco/JackpotWinView_grand.csb")
    else
        self:createCsbNode("ToroLoco/JackpotWinView.csb")
    end
    -- 处理乘倍jackpot 显隐性
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local fifthColumnInfo = selfMakeData.fifthColumnInfo or {}
    if #fifthColumnInfo > 0 then
        if fifthColumnInfo[2] == "multiple" then --乘倍
            self.m_jackpotChengBei = fifthColumnInfo[1]
            self:findChild("m_lb_num"):setVisible(true)
            self:findChild("m_lb_num"):setString("X"..fifthColumnInfo[1])
        else
            self:findChild("m_lb_num"):setVisible(false)
        end
    else
        self:findChild("m_lb_num"):setVisible(false)
    end

    --创建分享按钮
    self:createGrandShare()
    
    --设置控件显示
    for jpType,index in pairs(JACKPOT_INDEX) do
        local node = self:findChild("node_"..jpType)
        if node then
            node:setVisible(viewType == jpType)
        end

        local nodeBan = self:findChild(tostring(jpType))
        if nodeBan then
            nodeBan:setVisible(viewType == jpType)
        end
    end

    self.m_allowClick = false

    -- 添加光
    local guangNode = util_createAnimation("ToroLoco_glow.csb")
    self:findChild("Node_glow"):addChild(guangNode)
    guangNode:runCsbAction("idle", true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_glow"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_glow"), true)

    local jueSeSpine = util_spineCreate("ToroLoco_guochang",true,true)
    self:findChild("Node_juese"):addChild(jueSeSpine)
    util_spinePlay(jueSeSpine, "jackpot_start", false)
    util_spineEndCallFunc(jueSeSpine, "jackpot_start", function ()
        util_spinePlay(jueSeSpine, "jackpot_idle", true)
    end)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_ToroLoco_jackpotView"..jackpotIndex])

    self:showView(self.m_winCoin)

    if globalData.slotRunData.m_isAutoSpinAction then --自动spin 5s后自动点击一次按钮
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            self:clickFunc(self:findChild("Button_1"))
        end,5)
    end
end


--[[
    显示界面
]]
function ToroLocoJackpotWinView:showView(winCoin)
    if self.m_jackpotChengBei then
        self:findChild("m_lb_coins"):setString(util_formatCoins(tonumber(winCoin)/tonumber(self.m_jackpotChengBei), 50))
        local info={label = self:findChild("m_lb_coins"),sx = 1,sy = 1}
        self:updateLabelSize(info, 690)

        self:runCsbAction("start",false,function()
            self:runCsbAction("chengbei",false,function()
                self.m_allowClick = true
                self:runCsbAction("idle",true)
            end)
            performWithDelay(self,function()
                self:jumpCoins({
                    label = self:findChild("m_lb_coins"),
                    duration = 15/60,
                    startCoins = tonumber(winCoin)/tonumber(self.m_jackpotChengBei),
                    endCoins = winCoin,
                    maxWidth = 690
                })
            end, 30/60)
        end)
    else
        self:runCsbAction("start",false,function()
            self.m_allowClick = true
            self:runCsbAction("idle",true)
        end)

        self:jumpCoins({
            label = self:findChild("m_lb_coins"),
            duration = 2,
            endCoins = winCoin,
            maxWidth = 690
        })
    end
end

--[[
    关闭界面
]]
function ToroLocoJackpotWinView:showOver()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ToroLoco_jackpotView_over)

    self.m_allowClick = false
    self:runCsbAction("over",false,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:removeFromParent()
    end)
end

--[[
    金币跳动
]]
function ToroLocoJackpotWinView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound = PublicConfig.SoundConfig.sound_ToroLoco_jump_coins --跳动音效
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_ToroLoco_jump_coins_end --跳动结束音效
    self.m_jumpSoundEnd = jumpSoundEnd
    self.maxWidth = maxWidth

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (60  * duration)   --1秒跳动120次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    label:stopAllActions()

    if jumpSound then
        self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    end
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            self:jumpCoinsFinish()
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    点击按钮
]]
function ToroLocoJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    if PublicConfig.SoundConfig.sound_ToroLoco_click then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ToroLoco_click)
    end
    

    if self:checkShareState() then
        return
    end

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then

        self:jumpCoinsFinish()
        return
    end

    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end

    self:jackpotViewOver(function(  )
        self:showOver()
    end)
    
end

---------------------------------------------------------------------------------------------------------
--[[
    自动分享 | 手动分享
]]
function ToroLocoJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function ToroLocoJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoins(self.m_winCoin,50))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,self.maxWidth)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function ToroLocoJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function ToroLocoJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return ToroLocoJackpotWinView