---
--xcyy
--2018年5月23日
--TurkeyDayJackpotWinView.lua
local PublicConfig = require "TurkeyDayPublicConfig"
local TurkeyDayJackpotWinView = class("TurkeyDayJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 3,
    minor = 4,
    mini = 5
}
function TurkeyDayJackpotWinView:initUI(params)
    --jackpot类型统一转化为小写
    local viewType = string.lower(params.jackpotType) 
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    if self.m_jackpotIndex == 1 then
        self:createCsbNode("TurkeyDay/JackpotWinView_Grand.csb")

        local tbSpine_zi = util_spineCreate("Socre_TurkeyDay_Bonus",true,true)
        self:findChild("jp_tb_juese2_1"):addChild(tbSpine_zi)
        util_spinePlay(tbSpine_zi, "tb_zi_idle", true)
        tbSpine_zi:setSkin("zi")

        local tbSpine_huang = util_spineCreate("Socre_TurkeyDay_Bonus",true,true)
        self:findChild("jp_tb_juese2_2"):addChild(tbSpine_huang)
        util_spinePlay(tbSpine_huang, "tb_huang_idle2", true)
        tbSpine_huang:setSkin("huang")
    else
        self:createCsbNode("TurkeyDay/JackpotWinView.csb")

        local tbSpine = util_spineCreate("Socre_TurkeyDay_Bonus",true,true)
        self:findChild("jp_tb_juese1"):addChild(tbSpine)
        util_spinePlay(tbSpine, "tb_huang_idle", true)
        tbSpine:setSkin("huang")
    end

    local lightAni = util_createAnimation("TurkeyDay_tb_guang.csb")
    self:findChild("zg"):addChild(lightAni)
    lightAni:runCsbAction("idleframe", true)

    --创建分享按钮
    self:createGrandShare()
    
    --设置控件显示
    for jpType,index in pairs(JACKPOT_INDEX) do
        local node = self:findChild("node_"..jpType)
        if node then
            node:setVisible(viewType == jpType)
        end
    end

    self.m_allowClick = false

    local jackporSound = PublicConfig.SoundConfig.Music_Jackpot_Reward[jackpotIndex]
    if jackporSound then
        gLobalSoundManager:playSound(jackporSound)
    end

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
function TurkeyDayJackpotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)

        local btnSpine = util_spineCreate("TurkeyDay_tbsg",true,true)
        self:findChild("anniusg"):addChild(btnSpine)
        util_spinePlay(btnSpine, "anniu_idle", true)
    end)

    self:jumpCoins({label = self:findChild("m_lb_coins"), endCoins = winCoin, maxWidth = 711})
end

--[[
    关闭界面
]]
function TurkeyDayJackpotWinView:showOver()
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Over)
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
function TurkeyDayJackpotWinView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = toLongNumber(params.startCoins or 0) -- 起始金币
    local endCoins = toLongNumber(params.endCoins or 0)   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound = PublicConfig.SoundConfig.sound_TurkeyDay_jump_coins --跳动音效
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_TurkeyDay_jump_coins_end --跳动结束音效
    self.m_jumpSoundEnd = jumpSoundEnd
    self.maxWidth = maxWidth

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (60  * duration)   --1秒跳动60次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    label:stopAllActions()

    -- 数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Jump_Coins)
    
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
            label:setString(util_formatCoinsLN(curCoins,50))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end
    end, 1/60)
end

--[[
    点击按钮
]]
function TurkeyDayJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Normal_Click)

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
function TurkeyDayJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function TurkeyDayJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoinsLN(self.m_winCoin,50))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,self.maxWidth)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Jump_Stop)
        self.m_soundId = nil
    end
end

function TurkeyDayJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function TurkeyDayJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return TurkeyDayJackpotWinView