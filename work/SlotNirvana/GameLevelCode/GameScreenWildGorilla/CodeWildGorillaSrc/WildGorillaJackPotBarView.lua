---
--xcyy
--2018年5月23日
--WildGorillaJackPotBarView.lua
-- FIX IOS 139
local WildGorillaJackPotBarView = class("WildGorillaJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_0"
local MajorName = "m_lb_coins_1"
local MinorName = "m_lb_coins_2"
local MiniName = "m_lb_coins_3"

function WildGorillaJackPotBarView:initUI()
    self:createCsbNode("WildGorilla_jackpot.csb")

    self:runCsbAction("idleframe",true)
end



function WildGorillaJackPotBarView:onExit()
end

function WildGorillaJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WildGorillaJackPotBarView:onEnter()
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
function WildGorillaJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3, true)
    self:changeNode(self:findChild(MiniName), 4, true)
    
    self:updateSize()
end

function WildGorillaJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local info1 = {label = label1, sx = 0.9, sy = 0.9}

    local label2 = self.m_csbOwner[MajorName]
    local info2 = {label = label2, sx = 0.65, sy = 0.65}

    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.45, sy = 0.45}

    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 0.45, sy = 0.45}

    self:updateLabelSize(info1, 580)
    self:updateLabelSize(info2, 550)
    self:updateLabelSize(info3, 520)
    self:updateLabelSize(info4, 520)
end

function WildGorillaJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

function WildGorillaJackPotBarView:toAction(actionName)
    self:runCsbAction(actionName)
end

return WildGorillaJackPotBarView
