---
--xcyy
--2018年5月23日
--MayanMysteryJackPotBarView.lua
local MayanMysteryPublicConfig = require "MayanMysteryPublicConfig"
local MayanMysteryJackPotBarView = class("MayanMysteryJackPotBarView", util_require("base.BaseView"))

local EpicName = "m_lb_epic"
local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

function MayanMysteryJackPotBarView:initUI()
    self:createCsbNode("MayanMystery_base_jackpot.csb")

    self:runCsbAction("idle", true)
end

function MayanMysteryJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MayanMysteryJackPotBarView:onEnter()
    MayanMysteryJackPotBarView.super.onEnter(self)
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
function MayanMysteryJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(EpicName), 1, true)
    self:changeNode(self:findChild(GrandName), 2, true)
    self:changeNode(self:findChild(MajorName), 3, true)
    self:changeNode(self:findChild(MinorName), 4)
    self:changeNode(self:findChild(MiniName), 5)

    self:updateSize()
end

function MayanMysteryJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[EpicName]
    local label2 = self.m_csbOwner[GrandName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local info3 = {label = label3, sx = 1, sy = 1}
    local info4 = {label = label4, sx = 1, sy = 1}
    local info5 = {label = label5, sx = 1, sy = 1}

    self:updateLabelSize(info1, 272)
    self:updateLabelSize(info2, 226)
    self:updateLabelSize(info3, 208)
    self:updateLabelSize(info4, 185)
    self:updateLabelSize(info5, 180)
end

function MayanMysteryJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

return MayanMysteryJackPotBarView
