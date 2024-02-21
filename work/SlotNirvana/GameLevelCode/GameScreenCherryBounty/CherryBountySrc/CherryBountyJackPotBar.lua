--[[
    彩金栏
]]
local PublicConfig = require "CherryBountyPublicConfig"
local CherryBountyJackPotBar = class("CherryBountyJackPotBar", util_require("base.BaseView"))

function CherryBountyJackPotBar:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("CherryBounty_jackpot.csb")
    self:initJackpotLabInfo()
    self:initLockAnim()
    self:initUnLockClick()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CherryBountyJackPotBar:onEnter()
    CherryBountyJackPotBar.super.onEnter(self)

    self:playJackpotBarIdle()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end
--[[
    jackpot文本刷新
]]
function CherryBountyJackPotBar:initJackpotLabInfo()
    self.m_jackpotCsbInfo = {
        -- jackpot索引, 宽度, x缩放, y缩放
        {1, 373, 1, 1},
        {2, 373, 1, 1},
        {3, 373, 0.82, 0.82},
        {4, 373, 0.82, 0.82},
    }
end
-- 更新jackpot 数值信息
function CherryBountyJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        local name  = string.format("m_lb_coins_%d", _labInfo[1])
        local label = self:findChild(name)
        local value = self.m_machine:BaseMania_updateJackpotScore(_labInfo[1])
        label:setString(util_formatCoins(value, 12, nil, nil, true))
        local info = {label=label, sx=_labInfo[3], sy=_labInfo[4]}
        self:updateLabelSize(info, _labInfo[2])
    end
end

--时间线-idle
function CherryBountyJackPotBar:playJackpotBarIdle()
    self:runCsbAction("idle", false)
end
--时间线-触发
function CherryBountyJackPotBar:playJackpotBarTrigger(_jpIndexList)
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_JackpotBar_trigger)
    for i=1,4 do
        self:findChild(string.format("Node_%d", i)):setVisible(false)
    end
    for i,v in ipairs(_jpIndexList) do
        self:findChild(string.format("Node_%d", v)):setVisible(true)
    end
    self:runCsbAction("actionframe", true)
end

--[[
    高低bet锁定
]]
function CherryBountyJackPotBar:initLockAnim()
    self.m_lockCsb = util_createAnimation("CherryBounty_jackpot_grandsuo.csb")
    self:findChild("Node_lock"):addChild(self.m_lockCsb)
    self.m_lockCsb:setVisible(false)
    self.m_lockSpine = util_spineCreate("CherryBounty_jackpot_grandsuo2", true, true)
    self.m_lockCsb:findChild("Node_spine"):addChild(self.m_lockSpine)
end
function CherryBountyJackPotBar:playLockAnim()
    self.m_lockCsb:stopAllActions()
    self.m_lockCsb:setVisible(true)

    local lockBet = self.m_machine:getLockBetValue()
    local labCoins = self.m_lockCsb:findChild("m_lb_coins")
    labCoins:setString(util_formatCoins(lockBet, 3))
    self:updateLabelSize({label=labCoins, sx=0.9, sy=0.9}, 92) 

    local animName = "start"
    self.m_lockCsb:runCsbAction(animName, false)
    util_spinePlay(self.m_lockSpine, animName, false)

    performWithDelay(self.m_lockCsb,function()
        animName = "idle"
        util_spinePlay(self.m_lockSpine, animName, true)
        self.m_lockCsb:runCsbAction(animName, true)
        self.m_panelUnLock:setVisible(true)
    end, 24/30)
end
function CherryBountyJackPotBar:playUnLockAnim()
    self.m_lockCsb:stopAllActions()

    local animName = "over"
    self.m_lockCsb:runCsbAction(animName, false)
    util_spinePlay(self.m_lockSpine, animName, false)
    
    performWithDelay(self.m_lockCsb,function()
        self.m_panelUnLock:setVisible(false)
        self.m_lockCsb:setVisible(false)
    end, 18/30)
end
--[[
    点击切换到可以解锁的bet
]]
function CherryBountyJackPotBar:initUnLockClick()
    self.m_panelUnLock = self:findChild("Panel_click")
    self:addClick(self.m_panelUnLock)
end
function CherryBountyJackPotBar:clickFunc(sender)
    local bottomUi  = self.m_machine.m_bottomUI
    local btnBetAdd = bottomUi.m_btn_add
    local bEnabled1 = btnBetAdd:isEnabled()
    local bEnabled2 = btnBetAdd:isTouchEnabled()
    local bEnabled  = bEnabled1 and bEnabled2
    if not bEnabled then
        return
    end
    self:onPanelUnLockClick()
end
function CherryBountyJackPotBar:onPanelUnLockClick()
    self.m_panelUnLock:setVisible(false)
    local lockBet = self.m_machine:getLockBetValue()
    local betId = globalData.slotRunData:changeMoreThanBet(lockBet)
    globalData.slotRunData.iLastBetIdx =   betId
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

return CherryBountyJackPotBar