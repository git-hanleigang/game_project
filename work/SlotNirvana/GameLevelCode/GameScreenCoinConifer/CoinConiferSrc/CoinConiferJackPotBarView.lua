---
--xcyy
--2018年5月23日
--CoinConiferJackPotBarView.lua
local PublicConfig = require "CoinConiferPublicConfig"
local CoinConiferJackPotBarView = class("CoinConiferJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

function CoinConiferJackPotBarView:initUI()
    self:createCsbNode("CoinConifer_base_jackpotbar.csb")
    self:runCsbAction("idle",true)
end

function CoinConiferJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CoinConiferJackPotBarView:onEnter()
    CoinConiferJackPotBarView.super.onEnter(self)
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
function CoinConiferJackPotBarView:updateJackpotInfo()
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

function CoinConiferJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 0.6, sy = 0.6}
    local info2 = {label = label2, sx = 0.6, sy = 0.6}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.62, sy = 0.62}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 0.62, sy = 0.62}
    self:updateLabelSize(info1, 534)
    self:updateLabelSize(info2, 534)
    self:updateLabelSize(info3, 396)
    self:updateLabelSize(info4, 395)
end

function CoinConiferJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value, 12, nil, nil, true))
end

return CoinConiferJackPotBarView
