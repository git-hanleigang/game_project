---
--xcyy
--2018年5月23日
--LuxeVegasJackPotBarView.lua
local LuxeVegasPublicConfig = require "LuxeVegasPublicConfig"
local LuxeVegasJackPotBarView = class("LuxeVegasJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_GRAND"
local MegaName = "m_lb_coins_MEGA"
local MajorName = "m_lb_coins_MAJOR"
local MinorName = "m_lb_coins_MINOR"
local MiniName = "m_lb_coins_MINI" 

function LuxeVegasJackPotBarView:initUI()
    self:createCsbNode("LuxeVegas_Jackpot.csb")
    self:runCsbAction("idle", true)
end

function LuxeVegasJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function LuxeVegasJackPotBarView:onEnter()
    LuxeVegasJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- 更新jackpot 数值信息
--
function LuxeVegasJackPotBarView:updateJackpotInfo()
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

function LuxeVegasJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.93, sy = 1.0}
    local info2 = {label = label2, sx = 0.73, sy = 0.75}
    local info3 = {label = label3, sx = 0.73, sy = 0.75}
    local info4 = {label = label4, sx = 0.63, sy = 0.68}
    local info5 = {label = label5, sx = 0.63, sy = 0.68}
    
    self:updateLabelSize(info1, 378)
    self:updateLabelSize(info2, 378)
    self:updateLabelSize(info3, 378)
    self:updateLabelSize(info4, 378)
    self:updateLabelSize(info5, 378)
end

function LuxeVegasJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return LuxeVegasJackPotBarView
