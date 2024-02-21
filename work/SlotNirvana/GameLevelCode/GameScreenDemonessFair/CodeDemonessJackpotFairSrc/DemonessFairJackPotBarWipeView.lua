---
--xcyy
--2018年5月23日
--DemonessFairJackPotBarWipeView.lua
local PublicConfig = require "DemonessFairPublicConfig"
local DemonessFairJackPotBarWipeView = class("DemonessFairJackPotBarWipeView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

function DemonessFairJackPotBarWipeView:initUI()
    self:createCsbNode("DemonessFair_JackpotBar_Wipe.csb")

    local effectNodeNameTbl = {"Node_effect_grand", "Node_effect_mega", "Node_effect_major", "Node_effect_minor", "Node_effect_mini"}
    self.m_jackpotEccectAniTbl = {}
    for i=1, 5 do
        self.m_jackpotEccectAniTbl[i] = util_createAnimation("DemonessFair_JackpotBar_Effect.csb")
        self:findChild(effectNodeNameTbl[i]):addChild(self.m_jackpotEccectAniTbl[i])
        self.m_jackpotEccectAniTbl[i]:setVisible(false)
    end

    self:setIdle()
end

function DemonessFairJackPotBarWipeView:initMachine(machine)
    self.m_machine = machine
end

function DemonessFairJackPotBarWipeView:setIdle()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe1", true)
end

function DemonessFairJackPotBarWipeView:onEnter()
    DemonessFairJackPotBarWipeView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- 触发jackpot
function DemonessFairJackPotBarWipeView:playTriggerJackpot(_jackpotIndex)
    local jackpotIdleNameTbl = {"idleframe1", "idleframe1", "idleframe1", "idleframe2", "idleframe2"}
    local jackpotIndex = _jackpotIndex
    util_resetCsbAction(self.m_csbAct)

    self:runCsbAction(jackpotIdleNameTbl[jackpotIndex], true)
    self.m_jackpotEccectAniTbl[jackpotIndex]:setVisible(true)
    self.m_jackpotEccectAniTbl[jackpotIndex]:runCsbAction("actionframe", true)
end

-- 重置jackpot
function DemonessFairJackPotBarWipeView:resetJackpot()
    for _index, jackpotNode in pairs(self.m_jackpotEccectAniTbl) do
        jackpotNode:setVisible(false)
    end
    self:setIdle()
end

-- 更新jackpot 数值信息
--
function DemonessFairJackPotBarWipeView:updateJackpotInfo()
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

function DemonessFairJackPotBarWipeView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.5, sy = 0.5}
    local info2 = {label = label2, sx = 0.35, sy = 0.35}
    local info3 = {label = label3, sx = 0.35, sy = 0.35}
    local info4 = {label = label4, sx = 0.35, sy = 0.35}
    local info5 = {label = label5, sx = 0.35, sy = 0.35}

    self:updateLabelSize(info1, 374)
    self:updateLabelSize(info2, 374)
    self:updateLabelSize(info3, 374)
    self:updateLabelSize(info4, 374)
    self:updateLabelSize(info5, 374)
end

function DemonessFairJackPotBarWipeView:changeNode(label, index, isJump)
    local isAvgBet = self.m_machine.m_refreshJackpotBar
    local curBet = self.m_machine:getCurSpinStateBet(isAvgBet)
    local value = self.m_machine:BaseMania_updateJackpotScore(index, curBet)
    label:setString(util_formatCoins(value, 12, nil, nil, true))
end

return DemonessFairJackPotBarWipeView
