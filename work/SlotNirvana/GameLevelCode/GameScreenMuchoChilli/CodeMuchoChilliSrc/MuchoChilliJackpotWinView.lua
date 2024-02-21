---
--xcyy
--2018年5月23日
--MuchoChilliJackpotWinView.lua
local MuchoChilliJackpotWinView = class("MuchoChilliJackpotWinView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MuchoChilliPublicConfig"

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 3,
    minor = 4,
    mini = 5
}

local JACKPOT_NAME = {
    "grand",
    "mega",
    "major",
    "minor",
    "mini",
}
function MuchoChilliJackpotWinView:initUI(params)
    local viewType = params.jackpotType
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    self:createCsbNode("MuchoChilli/JackpotWinView.csb")

    --创建分享按钮
    self:createGrandShare()

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = viewType

    self.m_node_mini = self:findChild("mini")
    self.m_node_minor = self:findChild("minor")
    self.m_node_major = self:findChild("major")
    self.m_node_grand = self:findChild("grand")

    self.m_node_mini:setVisible(viewType == "mini")
    self.m_node_minor:setVisible(viewType == "minor")
    self.m_node_major:setVisible(viewType == "major")
    self.m_node_grand:setVisible(viewType == "grand")
    self:findChild("Node_grand_zuoyou"):setVisible(JACKPOT_NAME[viewType] == "grand")
    self:findChild("Node_huo_grand"):setVisible(JACKPOT_NAME[viewType] == "grand")
    self:findChild("shang_grand"):setVisible(JACKPOT_NAME[viewType] == "grand")
    self:findChild("shang_putong"):setVisible(JACKPOT_NAME[viewType] ~= "grand")
    self:findChild("xia_lajiao"):setVisible(JACKPOT_NAME[viewType] ~= "grand")
    self:findChild("xia_grand"):setVisible(JACKPOT_NAME[viewType] == "grand")
    for i, _nodeName in ipairs(JACKPOT_NAME) do
        self:findChild(_nodeName):setVisible(JACKPOT_NAME[viewType] == _nodeName)
        self:findChild(_nodeName.."_zi"):setVisible(JACKPOT_NAME[viewType] == _nodeName)
    end

    local roleSpine = util_spineCreate("MuchoChilli_JS",true,true)
    self:findChild("Node_juese"):addChild(roleSpine)
    util_spinePlay(roleSpine,"idleframe11",true)

    -- grand需要显示火
    self.m_roleHuoSpine = util_spineCreate("MuchoChilli_JS",true,true)
    self:findChild("Node_huo"):addChild(self.m_roleHuoSpine)
    self.m_roleHuoSpine:setVisible(false)

    self.m_allowClick = false

    self:showView(tonumber(self.m_winCoin))

    if globalData.slotRunData.m_isAutoSpinAction then
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
function MuchoChilliJackpotWinView:showView(winCoin)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_MuchoChilli_jackpot_start"..self.m_viewType])

    local isJiMan = self.m_machine:getIsJiManRespin()
    if isJiMan then
        self.m_roleHuoSpine:setVisible(true)
        util_spinePlay(self.m_roleHuoSpine,"idleframe12",true)

        self:findChild("m_lb_coins"):setString(util_formatCoins(tonumber(winCoin)/2, 50))
        local info={label = self:findChild("m_lb_coins"),sx = 1,sy = 1}
        self:updateLabelSize(info,574)

        performWithDelay(self,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_jackpot_chengbei)
        end, 80/60)

        self:runCsbAction("start2",false,function()
            self.m_allowClick = true
            self:runCsbAction("idle",true)

            self:jumpCoins({
                label = self:findChild("m_lb_coins"),
                startCoins = tonumber(winCoin)/2,
                endCoins = winCoin,
                maxWidth = 574
                })
        end)
        performWithDelay(
        self,
        function()
            -- 收集辣椒的时候 反馈动画
            local fanKuiEffect = util_createAnimation("MuchoChilli_fankui.csb")
            self:findChild("tbfankui"):addChild(fanKuiEffect)
            if not tolua.isnull(fanKuiEffect) then
                fanKuiEffect:runCsbAction("tbfankui", false)
            end
        end,
        2
    )
        
    else
        self:runCsbAction("start",false,function()
            self.m_allowClick = true
            self:runCsbAction("idle",true)
        end)

        self:jumpCoins({
            label = self:findChild("m_lb_coins"),
            endCoins = winCoin,
            maxWidth = 574
        })
    end
end

--[[
    关闭界面
]]
function MuchoChilliJackpotWinView:showOver()
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_jackpot_over)
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
function MuchoChilliJackpotWinView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 3   --持续时间
    local maxWidth = params.maxWidth or 574 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound = PublicConfig.SoundConfig.sound_MuchoChilli_jump_coins
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_MuchoChilli_jump_coins_end
    self.m_jumpSoundEnd = jumpSoundEnd

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (60  * duration)   --1秒跳动60次

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
function MuchoChilliJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_click)

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
function MuchoChilliJackpotWinView:createGrandShare()
    local parent = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MuchoChilliJackpotWinView:jumpCoinsFinish()
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
    self:updateLabelSize(info,574)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function MuchoChilliJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MuchoChilliJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return MuchoChilliJackpotWinView