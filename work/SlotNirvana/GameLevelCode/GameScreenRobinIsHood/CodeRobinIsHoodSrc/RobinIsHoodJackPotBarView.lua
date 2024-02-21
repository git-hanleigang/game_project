---
--xcyy
--2018年5月23日
--RobinIsHoodJackPotBarView.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodJackPotBarView = class("RobinIsHoodJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

function RobinIsHoodJackPotBarView:initUI()
    self:createCsbNode("RobinIsHood_base_jackpotbar.csb")
    self:runCsbAction("idle",true)
end

function RobinIsHoodJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function RobinIsHoodJackPotBarView:onEnter()
    RobinIsHoodJackPotBarView.super.onEnter(self)
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
function RobinIsHoodJackPotBarView:updateJackpotInfo()
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

function RobinIsHoodJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local label3 = self.m_csbOwner[MinorName]
    local label4 = self.m_csbOwner[MiniName]
    

    local info1 = {label = label1, sx = 0.8, sy = 0.8}
    local info2 = {label = label2, sx = 0.8, sy = 0.8}
    local info3 = {label = label3, sx = 0.8, sy = 0.8}
    local info4 = {label = label4, sx = 0.8, sy = 0.8}
    self:updateLabelSize(info1, 397)
    self:updateLabelSize(info2, 397)
    self:updateLabelSize(info3, 339)
    self:updateLabelSize(info4, 339)
end

function RobinIsHoodJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return RobinIsHoodJackPotBarView
