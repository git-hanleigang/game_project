---
--xcyy
--2018年5月23日
--CatchMonstersWheelJackPotBarView.lua
local PublicConfig = require "CatchMonstersPublicConfig"
local CatchMonstersWheelJackPotBarView = class("CatchMonstersWheelJackPotBarView", util_require("base.BaseView"))

local EpicName = "m_lb_epic"
local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"

function CatchMonstersWheelJackPotBarView:initUI()
    self:createCsbNode("CatchMonsters_JackpotBar_wheel.csb")
end

function CatchMonstersWheelJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CatchMonstersWheelJackPotBarView:onEnter()
    CatchMonstersWheelJackPotBarView.super.onEnter(self)
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
function CatchMonstersWheelJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(EpicName), 1, true)
    self:changeNode(self:findChild(GrandName), 2, true)
    self:changeNode(self:findChild(MajorName), 3)
    self:changeNode(self:findChild(MinorName), 4)

    self:updateSize()
end

function CatchMonstersWheelJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[EpicName]
    local label2 = self.m_csbOwner[GrandName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local label3 = self.m_csbOwner[MajorName]
    local info3 = {label = label3, sx = 1, sy = 1}
    local label4 = self.m_csbOwner[MinorName]
    local info4 = {label = label4, sx = 1, sy = 1}
    self:updateLabelSize(info1, 209)
    self:updateLabelSize(info2, 209)
    self:updateLabelSize(info3, 177)
    self:updateLabelSize(info4, 179)
end

function CatchMonstersWheelJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

return CatchMonstersWheelJackPotBarView
