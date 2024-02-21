---
--xcyy
--2018年5月23日
--GhostCaptainJackPotBarView.lua
local PublicConfig = require "GhostCaptainPublicConfig"
local GhostCaptainJackPotBarView = class("GhostCaptainJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_1"
local MajorName = "m_lb_coins_2"
local MinorName = "m_lb_coins_3"
local MiniName = "m_lb_coins_4"

function GhostCaptainJackPotBarView:initUI()
    self:createCsbNode("GhostCaptain_jackpotbar.csb")

    self.m_saoGuangSpine = util_spineCreate("GhostCaptain_jackpot",true,true)
    self:findChild("Node_idle"):addChild(self.m_saoGuangSpine)
    util_spinePlay(self.m_saoGuangSpine, "idle", true)
end

function GhostCaptainJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function GhostCaptainJackPotBarView:onEnter()
    GhostCaptainJackPotBarView.super.onEnter(self)
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
function GhostCaptainJackPotBarView:updateJackpotInfo()
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

function GhostCaptainJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 0.9, sy = 1}
    local info2 = {label = label2, sx = 0.9, sy = 1}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.9, sy = 1}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 0.9, sy = 1}
    self:updateLabelSize(info1, 268)
    self:updateLabelSize(info2, 268)
    self:updateLabelSize(info3, 268)
    self:updateLabelSize(info4, 268)
end

function GhostCaptainJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

return GhostCaptainJackPotBarView
