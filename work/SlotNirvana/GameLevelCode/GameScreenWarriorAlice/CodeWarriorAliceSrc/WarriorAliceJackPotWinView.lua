---
--island
--2018年4月12日
--WarriorAliceJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PublicConfig = require "WarriorAlicePublicConfig"
local WarriorAliceJackPotWinView = class("WarriorAliceJackPotWinView", util_require("Levels.BaseLevelDialog"))

WarriorAliceJackPotWinView.BtnName = "Button_collect"
local JACKPOT_TYPE = {
    "grand",
    "major",
    "minor",
    "mini"
}

function WarriorAliceJackPotWinView:onEnter()
    WarriorAliceJackPotWinView.super.onEnter(self)

end
function WarriorAliceJackPotWinView:onExit()
    self:stopUpDateCoins()

    WarriorAliceJackPotWinView.super.onExit(self)
end

function WarriorAliceJackPotWinView:initUI(_initData)
    self:createCsbNode("WarriorAlice/JackpotWinView.csb")

    self.m_soundId = nil
    self.m_soundEndId = nil
    self.m_allowClick = false

    self.juese = util_spineCreate("Socre_WarriorAlice_Bonus",true,true)
    self:findChild("juese"):addChild(self.juese)
    util_spinePlay(self.juese, "idleframe2", true)

    self.m_guangNode = util_createAnimation("WarriorAlice_tanban_guang.csb")
    self:findChild("guang"):addChild(self.m_guangNode)
    self.m_guangNode:runCsbAction("idle", true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("guang"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("guang"), true)
end

-- 根据jackpot类型刷新展示
function WarriorAliceJackPotWinView:upDateJackPotShow()
    local JackPotNodeName = {
        [1] = "Node_grand",
        [2] = "Node_major",
        [3] = "Node_minor",
        [4] = "Node_mini",
    }
    for _jpIndex,_nodeName in ipairs(JackPotNodeName) do
        local isVisible = _jpIndex == self.m_data.index
        local jpNode = self:findChild(_nodeName)
        jpNode:setVisible(isVisible)
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WarriorAlice_show_jackpot_win_"..JACKPOT_TYPE[self.m_data.index]])
end

-- 弹板入口 刷新
function WarriorAliceJackPotWinView:initViewData(_data)

    self.m_data = _data

    self:createGrandShare(_data.machine)
    self:upDateJackPotShow()
    self:setWinCoinsLab(0)
    
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
    end)

    self:jumpCoins(self.m_data.coins, 0)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_data.coins, _data.index)
end
--跳钱
function WarriorAliceJackPotWinView:jumpCoins(_targetCoins)
    local jumpSound = PublicConfig.SoundConfig.sound_WarriorAlice_jackpotUp
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_WarriorAlice_jackpotUpOver
    self.m_jumpSoundEnd = jumpSoundEnd
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (4 * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    local node = self:findChild("m_lb_coins")

    if jumpSound then
        self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    end

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < _targetCoins and curCoins or _targetCoins

        self:setWinCoinsLab(curCoins)
        if curCoins >= _targetCoins then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            self:stopUpDateCoins()
            self:jumpCoinsFinish()
        end
    end,0.008)
end

function WarriorAliceJackPotWinView:setWinCoinsLab(_coins)
    local labCoins = self:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=1,sy=1}, 597)
end

--点击回调
function WarriorAliceJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    
    if self:checkShareState() then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_btn_click)

    self:clickCollectBtn(sender)
end
function WarriorAliceJackPotWinView:clickCollectBtn(_sender)
    -- gLobalSoundManager:playSound(WarriorAlicePublicConfig.sound_WarriorAlice_commonClick)

    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setWinCoinsLab(self.m_data.coins)
        self:jumpCoinsFinish()
    else
        self:playOverAnim()
    end
end

function WarriorAliceJackPotWinView:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        -- gLobalSoundManager:playSound(WarriorAlicePublicConfig.sound_WarriorAlice_jackpotView_jumpCoinsOver)
    end
end

function WarriorAliceJackPotWinView:playOverAnim()
    self.m_allowClick = false
    self:findChild("Button_1"):setEnabled(false)
    self:jackpotViewOver(function()
        self:stopAllActions()

        if self.m_btnClickFunc then
            self.m_btnClickFunc()
            self.m_btnClickFunc = nil
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_jackpot_win_over)
        self:runCsbAction("over", false)
        local overTime = util_csbGetAnimTimes(self.m_csbAct, "over")
        performWithDelay(self,function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end
            self.juese:removeFromParent()
            self:removeFromParent()
        end,overTime)
    end)
end


--[[
    点击回调 和 结束回调
]]
function WarriorAliceJackPotWinView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function WarriorAliceJackPotWinView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--[[
    自动分享 | 手动分享
]]
function WarriorAliceJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function WarriorAliceJackPotWinView:jumpCoinsFinish()
    
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_data.index)
    end
end

function WarriorAliceJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function WarriorAliceJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return WarriorAliceJackPotWinView

