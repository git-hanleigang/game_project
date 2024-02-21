---
--xcyy
--2018年5月23日
--AChristmasCarolJackPotBarView.lua
local PublicConfig = require "AChristmasCarolPublicConfig"
local AChristmasCarolJackPotBarView = class("AChristmasCarolJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

function AChristmasCarolJackPotBarView:initUI()
    self:createCsbNode("AChristmasCarol_JackpotBar.csb")
    self:runCsbAction("idle", true)
end

function AChristmasCarolJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function AChristmasCarolJackPotBarView:onEnter()
    AChristmasCarolJackPotBarView.super.onEnter(self)
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
function AChristmasCarolJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3)
    self:changeNode(self:findChild(MiniName), 4)

    self:updateSize()
end

function AChristmasCarolJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.75, sy = 0.75}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 0.75, sy = 0.75}
    self:updateLabelSize(info1, 316)
    self:updateLabelSize(info2, 316)
    self:updateLabelSize(info3, 316)
    self:updateLabelSize(info4, 316)
end

function AChristmasCarolJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 12, nil, nil, true))
end

return AChristmasCarolJackPotBarView
