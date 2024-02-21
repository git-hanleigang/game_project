---
--xcyy
--2018年5月23日
--MagikMirrorJackPotBarView.lua
local MagikMirrorPublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorJackPotBarView = class("MagikMirrorJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MimorName = "m_lb_minor"
local MiniName = "m_lb_mini"
MagikMirrorJackPotBarView.m_AverageBet = nil

function MagikMirrorJackPotBarView:initUI()
    self:createCsbNode("MagikMirror_jackpot.csb")
    self.m_AverageBet = nil
    self:showJackpotBarIdle()
end

function MagikMirrorJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MagikMirrorJackPotBarView:onEnter()
    MagikMirrorJackPotBarView.super.onEnter(self)
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
function MagikMirrorJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MimorName), 3, true)
    self:changeNode(self:findChild(MiniName), 4, true)

    self:updateSize()
end

function MagikMirrorJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local label3 = self.m_csbOwner[MimorName]
    local label4 = self.m_csbOwner[MiniName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local info3 = {label = label3, sx = 1, sy = 1}
    local info4 = {label = label4, sx = 1, sy = 1}
    self:updateLabelSize(info1, 281)
    self:updateLabelSize(info2, 281)
    self:updateLabelSize(info3, 281)
    self:updateLabelSize(info4, 281)
end

function MagikMirrorJackPotBarView:setAverageBet(bet)
    self.m_AverageBet = bet
end

function MagikMirrorJackPotBarView:changeNode(label, index, isJump)
    local bet = nil
    if self.m_AverageBet then
        bet = self.m_AverageBet 
    end
    local value = self.m_machine:BaseMania_updateJackpotScore(index,bet)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

function MagikMirrorJackPotBarView:showJackpotBarIdle()
    self:runCsbAction("idle",true)
end

function MagikMirrorJackPotBarView:showJackpotUnLock()
    
end

function MagikMirrorJackPotBarView:showJackpotLock()
    
end

return MagikMirrorJackPotBarView
