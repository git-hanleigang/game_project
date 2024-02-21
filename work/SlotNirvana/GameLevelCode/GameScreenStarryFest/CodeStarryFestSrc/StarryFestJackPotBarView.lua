---
--xcyy
--2018年5月23日
--StarryFestJackPotBarView.lua
local PublicConfig = require "StarryFestPublicConfig"
local StarryFestJackPotBarView = class("StarryFestJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local SuperName = "m_lb_super"
local MaxiName = "m_lb_maxi"
local MegaName = "m_lb_mega"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"
local totalCount = 7
local ENUM_LOCK_STATE = {
    LOCK = 0,
    UNLOCK = 1,
}

function StarryFestJackPotBarView:initUI()
    self:createCsbNode("StarryFest_Jackpot.csb")

    -- grand,super状态
    self.m_lockStateTbl = {1, 1}

    local nodeTbl = {"Node_idle_grand", "Node_idle_super", "Node_idle_maxi", "Node_idle_mega", "Node_idle_major", "Node_idle_minor", "Node_idle_mini"}
    self.m_idleNameTbl = {"idle_GRAND_jin", "idle_super_hong", "idle_maxi_Qlan", "idle_mega_fen", "idle_major_zi", "idle_minor_lan", "idle_mini_lv"}
    self.m_lockNameTbl = {"lock_grand", "lock_super"}
    self.m_unLockNameTbl = {"unlock_grand", "unlock_super"}
    self.m_jackpotSpineTbl = {}
    for i=1, totalCount do
        local jackpotNode = self:findChild(nodeTbl[i])
        self.m_jackpotSpineTbl[i] = util_spineCreate("StarryFest_jackpot",true,true)
        jackpotNode:addChild(self.m_jackpotSpineTbl[i])
        util_spinePlay(self.m_jackpotSpineTbl[i], self.m_idleNameTbl[i], true)
    end

    --锁jackpot
    self.m_lockJackpotSpine = {}
    self.m_lockJackpotSpine[1] = util_spineCreate("StarryFest_jackpot",true,true)
    self:findChild("Node_lock_grand"):addChild(self.m_lockJackpotSpine[1])
    
    self.m_lockJackpotSpine[2] = util_spineCreate("StarryFest_jackpot",true,true)
    self:findChild("Node_lock_super"):addChild(self.m_lockJackpotSpine[2])

    -- super解锁
    self.m_superUnLockPanel = self:findChild("Panel_super")
    -- grand解锁
    self.m_grandUnLockPanel = self:findChild("Panel_grand")

    self:addClick(self.m_superUnLockPanel)
    self:addClick(self.m_grandUnLockPanel)
end

--默认按钮监听回调
function StarryFestJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_machine:tipsBtnIsCanClick() and globalData.betFlag then
        if name == "Panel_super" and self.m_machine.m_iBetLevel == 0  then
            self.m_machine.m_bottomUI:changeBetCoinNumToUnLock(1)
        elseif name == "Panel_grand" and self.m_machine.m_iBetLevel < 2 then
            self.m_machine.m_bottomUI:changeBetCoinNumToUnLock(2)
        end
    end
end

function StarryFestJackPotBarView:setLockJackpot(_lockIndex)
    --0:锁grand和super；1：锁grand；2：不锁
    local lockIndex = _lockIndex
    self.m_superUnLockPanel:setVisible(lockIndex<1)
    self.m_grandUnLockPanel:setVisible(lockIndex<2)
    -- 初始化
    if not self.m_lastLockIndex then
        if lockIndex == 0 then
            for i=1, 2 do
                self.m_lockJackpotSpine[i]:setVisible(true)
                util_spinePlay(self.m_lockJackpotSpine[i], self.m_lockNameTbl[i], false)
                self.m_jackpotSpineTbl[i]:setVisible(false)
                self.m_lockStateTbl[i] = ENUM_LOCK_STATE.LOCK
            end
        elseif lockIndex == 1 then
            self.m_lockJackpotSpine[1]:setVisible(true)
            util_spinePlay(self.m_lockJackpotSpine[1], self.m_lockNameTbl[1], false)
            self.m_jackpotSpineTbl[1]:setVisible(false)
            self.m_lockStateTbl[1] = ENUM_LOCK_STATE.LOCK
        elseif lockIndex == 2 then
            for i=1, 2 do
                self.m_jackpotSpineTbl[i]:setVisible(true)
                self.m_lockJackpotSpine[i]:setVisible(false)
                self.m_lockStateTbl[i] = ENUM_LOCK_STATE.UNLOCK
            end
        end
    -- 切bet
    else
        --锁定
        if self.m_lastLockIndex > lockIndex then
            if lockIndex == 0 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Bet_Lock)
                for i=1, 2 do
                    if self.m_lockStateTbl[i] == ENUM_LOCK_STATE.UNLOCK then
                        self.m_lockJackpotSpine[i]:setVisible(true)
                        util_spinePlay(self.m_lockJackpotSpine[i], self.m_lockNameTbl[i], false)
                        self.m_jackpotSpineTbl[i]:setVisible(false)
                        self.m_lockStateTbl[i] = ENUM_LOCK_STATE.LOCK
                    end
                end
            elseif lockIndex == 1 then
                if self.m_lockStateTbl[1] == ENUM_LOCK_STATE.UNLOCK then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Bet_Lock)
                    self.m_lockJackpotSpine[1]:setVisible(true)
                    util_spinePlay(self.m_lockJackpotSpine[1], self.m_lockNameTbl[1], false)
                    self.m_jackpotSpineTbl[1]:setVisible(false)
                    self.m_lockStateTbl[1] = ENUM_LOCK_STATE.LOCK
                end
            else
                for i=1, 2 do
                    self.m_jackpotSpineTbl[i]:setVisible(true)
                    self.m_lockJackpotSpine[i]:setVisible(false)
                    self.m_lockStateTbl[i] = ENUM_LOCK_STATE.UNLOCK
                end
            end
        --解锁
        elseif self.m_lastLockIndex < lockIndex then
            if lockIndex == 1 then
                if self.m_lockStateTbl[2] == ENUM_LOCK_STATE.LOCK then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Bet_UnLock)
                    self.m_lockJackpotSpine[2]:setVisible(true)
                    util_spinePlay(self.m_lockJackpotSpine[2], self.m_unLockNameTbl[2], false)
                    util_spineEndCallFunc(self.m_lockJackpotSpine[2], self.m_unLockNameTbl[2], function()
                        self.m_lockJackpotSpine[2]:setVisible(false)
                        self.m_jackpotSpineTbl[2]:setVisible(true)
                    end)
                    self.m_lockStateTbl[2] = ENUM_LOCK_STATE.UNLOCK
                end
            elseif lockIndex == 2 then
                if self.m_lastLockIndex == 0 then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Bet_UnLock)
                    for i=1, 2 do
                        if self.m_lockStateTbl[i] == ENUM_LOCK_STATE.LOCK then
                            self.m_lockJackpotSpine[i]:setVisible(true)
                            util_spinePlay(self.m_lockJackpotSpine[i], self.m_unLockNameTbl[i], false)
                            util_spineEndCallFunc(self.m_lockJackpotSpine[i], self.m_unLockNameTbl[i], function()
                                self.m_lockJackpotSpine[i]:setVisible(false)
                                self.m_jackpotSpineTbl[i]:setVisible(true)
                            end)
                            self.m_lockStateTbl[i] = ENUM_LOCK_STATE.UNLOCK
                        end
                    end
                else
                    if self.m_lockStateTbl[1] == ENUM_LOCK_STATE.LOCK then
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Bet_UnLock)
                        self.m_lockJackpotSpine[1]:setVisible(true)
                        util_spinePlay(self.m_lockJackpotSpine[1], self.m_unLockNameTbl[1], false)
                        util_spineEndCallFunc(self.m_lockJackpotSpine[1], self.m_unLockNameTbl[1], function()
                            self.m_lockJackpotSpine[1]:setVisible(false)
                            self.m_jackpotSpineTbl[1]:setVisible(true)
                        end)
                        self.m_lockStateTbl[1] = ENUM_LOCK_STATE.UNLOCK
                    end
                end
            else
                for i=1, 2 do
                    self.m_jackpotSpineTbl[i]:setVisible(true)
                    self.m_lockJackpotSpine[i]:setVisible(false)
                    self.m_lockStateTbl[i] = ENUM_LOCK_STATE.UNLOCK
                end
            end
        end
    end
    
    self.m_lastLockIndex = _lockIndex
end

function StarryFestJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function StarryFestJackPotBarView:onEnter()
    StarryFestJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function StarryFestJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(SuperName), 2, true)
    self:changeNode(self:findChild(MaxiName), 3, true)
    self:changeNode(self:findChild(MegaName), 4, true)
    self:changeNode(self:findChild(MajorName), 5, true)
    self:changeNode(self:findChild(MinorName), 6)
    self:changeNode(self:findChild(MiniName), 7)

    self:updateSize()
end

function StarryFestJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[SuperName]
    local label3 = self.m_csbOwner[MaxiName]
    local label4 = self.m_csbOwner[MegaName]
    local label5 = self.m_csbOwner[MajorName]
    local label6 = self.m_csbOwner[MinorName]
    local label7 = self.m_csbOwner[MiniName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 0.725, sy = 0.75}
    local info3 = {label = label3, sx = 0.725, sy = 0.75}
    local info4 = {label = label4, sx = 0.725, sy = 0.75}
    local info5 = {label = label5, sx = 0.725, sy = 0.75}
    local info6 = {label = label6, sx = 0.725, sy = 0.75}
    local info7 = {label = label7, sx = 0.725, sy = 0.75}
    self:updateLabelSize(info1, 406)
    self:updateLabelSize(info2, 420)
    self:updateLabelSize(info3, 420)
    self:updateLabelSize(info4, 420)
    self:updateLabelSize(info5, 420)
    self:updateLabelSize(info6, 420)
    self:updateLabelSize(info7, 420)
end

function StarryFestJackPotBarView:changeNode(label, index, isJump)
    -- local value = self.m_machine:BaseMania_updateJackpotScore(index)
    -- label:setString(util_formatCoins(value, 20, nil, nil, true))

    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_machine.m_isSuperFree and self.m_machine.m_runSpinResultData.p_selfMakeData.avgBet then
        lineBet = self.m_machine.m_runSpinResultData.p_selfMakeData.avgBet
    end
    local value=self.m_machine:BaseMania_updateJackpotScore(index,lineBet)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return StarryFestJackPotBarView
