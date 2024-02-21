---
--xcyy
--2018年5月23日
--AquaQuestJackPotBarView.lua
local PublicConfig = require "AquaQuestPublicConfig"
local AquaQuestJackPotBarView = class("AquaQuestJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

function AquaQuestJackPotBarView:initUI()
    self:createCsbNode("AquaQuest_jackpot.csb")

    self.m_jackpotBar_3X7 = util_createAnimation("AquaQuest_jackpot_3X7.csb")
    self:addChild(self.m_jackpotBar_3X7)
end

function AquaQuestJackPotBarView:runIdleAni()
    self:runCsbAction("idle",true)
    self.m_jackpotBar_3X7:runCsbAction("idle",true)
end

function AquaQuestJackPotBarView:changJackpotBar(isExtra)
    self.m_jackpotBar_3X7:setVisible(isExtra)
    self:findChild("Node_jackpot"):setVisible(not isExtra)
end

function AquaQuestJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function AquaQuestJackPotBarView:onEnter()
    AquaQuestJackPotBarView.super.onEnter(self)
    self:runIdleAni()
    self:stopAllActions()
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

-- 更新jackpot 数值信息
--
function AquaQuestJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3)
    self:changeNode(self:findChild(MiniName), 4)

    self:changeNode(self.m_jackpotBar_3X7:findChild(GrandName), 1, true)
    self:changeNode(self.m_jackpotBar_3X7:findChild(MajorName), 2, true)
    self:changeNode(self.m_jackpotBar_3X7:findChild(MinorName), 3)
    self:changeNode(self.m_jackpotBar_3X7:findChild(MiniName), 4)

    self:updateSize()
end

function AquaQuestJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local label3 = self.m_csbOwner[MinorName]
    local label4 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local info3 = {label = label3, sx = 1, sy = 1}
    local info4 = {label = label4, sx = 1, sy = 1}

    self:updateLabelSize(info1, 230)
    self:updateLabelSize(info2, 230)
    self:updateLabelSize(info3, 230)
    self:updateLabelSize(info4, 230)

    local label1_3X7 = self.m_jackpotBar_3X7:findChild(GrandName)
    local label2_3X7 = self.m_jackpotBar_3X7:findChild(MajorName)
    local label3_3X7 = self.m_jackpotBar_3X7:findChild(MinorName)
    local label4_3X7 = self.m_jackpotBar_3X7:findChild(MiniName)

    local info1_3X7 = {label = label1_3X7, sx = 1, sy = 1}
    local info2_3X7 = {label = label2_3X7, sx = 1, sy = 1}
    local info3_3X7 = {label = label3_3X7, sx = 1, sy = 1}
    local info4_3X7 = {label = label4_3X7, sx = 1, sy = 1}

    self:updateLabelSize(info1_3X7, 305)
    self:updateLabelSize(info2_3X7, 305)
    self:updateLabelSize(info3_3X7, 305)
    self:updateLabelSize(info4_3X7, 305)
end

function AquaQuestJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return AquaQuestJackPotBarView
