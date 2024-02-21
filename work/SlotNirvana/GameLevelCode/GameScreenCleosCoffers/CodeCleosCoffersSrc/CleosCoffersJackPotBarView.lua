---
--xcyy
--2018年5月23日
--CleosCoffersJackPotBarView.lua
local PublicConfig = require "CleosCoffersPublicConfig"
local CleosCoffersJackPotBarView = class("CleosCoffersJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MegaName = "m_lb_mega"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

function CleosCoffersJackPotBarView:initUI()
    self:createCsbNode("CleosCoffers_jackpotbar.csb")
    self:runIdleAni()
end

function CleosCoffersJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CleosCoffersJackPotBarView:runIdleAni()
    self:runCsbAction("idle",true)
end

function CleosCoffersJackPotBarView:onEnter()
    CleosCoffersJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- 更新jackpot 数值信息
--
function CleosCoffersJackPotBarView:updateJackpotInfo()
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

function CleosCoffersJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.58, sy = 0.58}
    local info2 = {label = label2, sx = 0.58, sy = 0.58}
    local info3 = {label = label3, sx = 0.58, sy = 0.58}
    local info4 = {label = label4, sx = 0.58, sy = 0.58}
    local info5 = {label = label5, sx = 0.58, sy = 0.58}

    self:updateLabelSize(info1, 440)
    self:updateLabelSize(info2, 360)
    self:updateLabelSize(info3, 360)
    self:updateLabelSize(info4, 360)
    self:updateLabelSize(info5, 360)
end

function CleosCoffersJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 12, nil, nil, true))
end

return CleosCoffersJackPotBarView
