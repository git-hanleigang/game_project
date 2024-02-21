---
--xcyy
--2018年5月23日
--JungleJauntJackPotBarBaseView.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntJackPotBarBaseView = class("JungleJauntJackPotBarBaseView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

function JungleJauntJackPotBarBaseView:initUI()
    self:createCsbNode("JungleJaunt_basefree_jackpot.csb")

    self:runCsbAction("idle",true)

    self.m_grandLock = util_createAnimation("JungleJaunt_jackpot_grand_suo.csb")
    self:findChild("grand_suo"):addChild(self.m_grandLock)
    self.m_grandLock:setVisible(false)
    self.m_grandLock:runCsbAction("idle",true)
    self.m_grandLock:addClick(self.m_grandLock:findChild("click"))
    self.m_grandLock.clickFunc = function(target,sender)
        local name = sender:getName()
        local tag = sender:getTag()
        if name == "click" then
            self.m_machine:unlockHigherBet()
        end
    end
end

function JungleJauntJackPotBarBaseView:initMachine(machine)
    self.m_machine = machine
end

function JungleJauntJackPotBarBaseView:addObservers()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            
            self.m_grandLock:runCsbAction("idle",true)
            self.m_grandLock:findChild("Node_D"):stopAllActions()
            self.m_grandLock:findChild("m_lb_coins"):setString(util_formatCoinsLN(self.m_machine.m_betGear,3))
            self.m_grandLock:setVisible(true)
        end,
        PBC.ObserversConfig.GrandJpLock
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_grandLock:runCsbAction("switch")
            self.m_grandLock:findChild("Particle_1"):resetSystem()
            local time = util_csbGetAnimTimes(self.m_grandLock.m_csbAct, "switch", 60)
            performWithDelay(self.m_grandLock:findChild("Node_D"),function()
                self.m_grandLock:setVisible(false) 
            end,time + 1.5)
        end,
        PBC.ObserversConfig.GrandJpUnLock
    )
end

function JungleJauntJackPotBarBaseView:onEnter()
    self.super.onEnter(self)
    self:addObservers()
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
function JungleJauntJackPotBarBaseView:updateJackpotInfo()
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

function JungleJauntJackPotBarBaseView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 0.82, sy = 0.82}
    local info3 = {label = label3, sx = 0.82, sy = 0.82}
    local info4 = {label = label4, sx = 0.82, sy = 0.82}
    local info5 = {label = label5, sx = 0.82, sy = 0.82}

    self:updateLabelSize(info1, 332)
    self:updateLabelSize(info2, 332)
    self:updateLabelSize(info3, 332)
    self:updateLabelSize(info4, 332)
    self:updateLabelSize(info5, 332)
end

function JungleJauntJackPotBarBaseView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value, 12, nil, nil, true))
end



return JungleJauntJackPotBarBaseView
