---
--xcyy
--2018年5月23日
--GeminiJourneyJackPotBarView.lua
local GeminiJourneyPublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyJackPotBarView = class("GeminiJourneyJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_GRAND"
local MegaName = "m_lb_coins_MEGA"
local MajorName = "m_lb_coins_MAJOR"
local MinorName = "m_lb_coins_MINOR"
local MiniName = "m_lb_coins_MINI" 

function GeminiJourneyJackPotBarView:initUI()
    self:createCsbNode("GeminiJourney_Jackpots.csb")
    self:setIdleAni()
end

function GeminiJourneyJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 触发动画
function GeminiJourneyJackPotBarView:playTriggerJackpotAni(_jackpotIndex)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", true)
    local jackpotIndex = _jackpotIndex
    local effectNameTbl = {"sp_trigger_grand", "sp_trigger_mega", "sp_trigger_major", "sp_trigger_minor", "sp_trigger_mini"}
    for index, effectName in pairs(effectNameTbl) do
        if jackpotIndex == index then
            self:findChild(effectName):setVisible(true)
        else
            self:findChild(effectName):setVisible(false)
        end
    end
end

function GeminiJourneyJackPotBarView:setIdleAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idleframe", true)
end

function GeminiJourneyJackPotBarView:onEnter()
    GeminiJourneyJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- 更新jackpot 数值信息
--
function GeminiJourneyJackPotBarView:updateJackpotInfo()
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

function GeminiJourneyJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 1.0, sy = 1.0}
    local info2 = {label = label2, sx = 1.0, sy = 1.0}
    local info3 = {label = label3, sx = 1.0, sy = 1.0}
    local info4 = {label = label4, sx = 1.0, sy = 1.0}
    local info5 = {label = label5, sx = 1.0, sy = 1.0}
    
    self:updateLabelSize(info1, 223)
    self:updateLabelSize(info2, 189)
    self:updateLabelSize(info3, 189)
    self:updateLabelSize(info4, 189)
    self:updateLabelSize(info5, 189)
end

function GeminiJourneyJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return GeminiJourneyJackPotBarView
