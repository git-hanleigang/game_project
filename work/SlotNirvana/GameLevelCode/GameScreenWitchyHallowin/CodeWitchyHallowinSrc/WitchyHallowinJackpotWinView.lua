---
--xcyy
--2018年5月23日
--WitchyHallowinJackpotWinView.lua
local PublicConfig = require "WitchyHallowinPublicConfig"
local WitchyHallowinJackpotWinView = class("WitchyHallowinJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}
function WitchyHallowinJackpotWinView:initUI(params)
    local viewType = params.jackpotType
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    self:createCsbNode("WitchyHallowin/JackpotWinView.csb")

    --创建分享按钮
    self:createGrandShare()

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    self.m_node_mini = self:findChild("mini")
    self.m_node_minor = self:findChild("minor")
    self.m_node_major = self:findChild("major")
    self.m_node_grand = self:findChild("grand")

    self.m_node_mini:setVisible(viewType == "mini")
    self.m_node_minor:setVisible(viewType == "minor")
    self.m_node_major:setVisible(viewType == "major")
    self.m_node_grand:setVisible(viewType == "grand")
    self:findChild("di_mini"):setVisible(viewType == "mini")
    self:findChild("di_mini_0"):setVisible(viewType == "mini")
    self:findChild("di_minor"):setVisible(viewType == "minor")
    self:findChild("di_minor_0"):setVisible(viewType == "minor")
    self:findChild("di_major"):setVisible(viewType == "major")
    self:findChild("di_major_0"):setVisible(viewType == "major")
    self:findChild("di_grand"):setVisible(viewType == "grand")
    self:findChild("di_grand_0"):setVisible(viewType == "grand")

    if viewType == "grand" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_grand_win)
    elseif viewType == "major" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_major_win)
    elseif viewType == "minor" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_minor_win)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_mini_win)
    end

    self.m_allowClick = false

    local spine = util_spineCreate("WitchyHallowin_nvwu",true,true)
    self:findChild("juese"):addChild(spine)
    util_spinePlay(spine,"idle_tanban",true)

    self:showView(self.m_winCoin)

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
function WitchyHallowinJackpotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 616
    })
end

--[[
    关闭界面
]]
function WitchyHallowinJackpotWinView:showOver()
    self.m_allowClick = false
    if self.m_viewType == "grand" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_hide_grand_win)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_hide_jackpot_win)
    end
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
function WitchyHallowinJackpotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.SoundConfig.sound_WitchyHallowin_jump_coins
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_WitchyHallowin_jump_coins_end
    self.m_jumpSoundEnd = jumpSoundEnd

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动60次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0
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
function WitchyHallowinJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_click)

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
function WitchyHallowinJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function WitchyHallowinJackpotWinView:jumpCoinsFinish()
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
    self:updateLabelSize(info,616)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function WitchyHallowinJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function WitchyHallowinJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return WitchyHallowinJackpotWinView