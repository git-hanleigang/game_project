---
--xcyy
--2018年5月23日
--DemonessFairJackPotBarWipeMaxRowView.lua
local PublicConfig = require "DemonessFairPublicConfig"
local DemonessFairJackPotBarWipeMaxRowView = class("DemonessFairJackPotBarWipeMaxRowView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

function DemonessFairJackPotBarWipeMaxRowView:initUI()
    self:createCsbNode("DemonessFair_JackpotBar_Wipe_MaxRow.csb")

    self.m_jackpotEccectAni = util_createAnimation("DemonessFair_JackpotBar_Effect.csb")
    self:findChild("Node_effect"):addChild(self.m_jackpotEccectAni)
    self.m_jackpotEccectAni:setVisible(false)

    self:setIdle()
end

function DemonessFairJackPotBarWipeMaxRowView:initMachine(machine)
    self.m_machine = machine
end

function DemonessFairJackPotBarWipeMaxRowView:setIdle()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", true)
end

function DemonessFairJackPotBarWipeMaxRowView:onEnter()
    DemonessFairJackPotBarWipeMaxRowView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- 触发jackpot
function DemonessFairJackPotBarWipeMaxRowView:playTriggerJackpot(_jackpotIndex)
    local jackpotIdleNameTbl = {"idle1", "idle2", "idle3", "idle4", "idle5"}
    local jackpotIndex = _jackpotIndex
    util_resetCsbAction(self.m_csbAct)

    self:runCsbAction(jackpotIdleNameTbl[jackpotIndex], true)
    self.m_jackpotEccectAni:setVisible(true)
    self.m_jackpotEccectAni:runCsbAction("actionframe", true)
end

-- 重置jackpot
function DemonessFairJackPotBarWipeMaxRowView:resetJackpot()
    self.m_jackpotEccectAni:setVisible(false)
    self:setIdle()
end

-- 更新jackpot 数值信息
--
function DemonessFairJackPotBarWipeMaxRowView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MegaName), 2, true)
    self:changeNode(self:findChild(MajorName), 3, true)
    self:changeNode(self:findChild(MinorName), 4)
    self:changeNode(self:findChild(MiniName), 5)

    self:updateSize()
end

function DemonessFairJackPotBarWipeMaxRowView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.5, sy = 0.5}
    local info2 = {label = label2, sx = 0.5, sy = 0.5}
    local info3 = {label = label3, sx = 0.5, sy = 0.5}
    local info4 = {label = label4, sx = 0.5, sy = 0.5}
    local info5 = {label = label5, sx = 0.5, sy = 0.5}

    self:updateLabelSize(info1, 374)
    self:updateLabelSize(info2, 374)
    self:updateLabelSize(info3, 374)
    self:updateLabelSize(info4, 374)
    self:updateLabelSize(info5, 374)
end

function DemonessFairJackPotBarWipeMaxRowView:changeNode(label, index, isJump)
    local isAvgBet = self.m_machine.m_refreshJackpotBar
    local curBet = self.m_machine:getCurSpinStateBet(isAvgBet)
    local value = self.m_machine:BaseMania_updateJackpotScore(index, curBet)
    label:setString(util_formatCoins(value, 12, nil, nil, true))
end

return DemonessFairJackPotBarWipeMaxRowView
