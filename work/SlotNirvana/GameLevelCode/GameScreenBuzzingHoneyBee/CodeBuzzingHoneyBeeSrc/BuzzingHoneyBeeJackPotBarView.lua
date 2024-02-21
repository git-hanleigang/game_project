---
--xcyy
--2018年5月23日
--BuzzingHoneyBeeJackPotBarView.lua
--fixios0223
local BuzzingHoneyBeeJackPotBarView = class("BuzzingHoneyBeeJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins"

function BuzzingHoneyBeeJackPotBarView:initUI()
    self:createCsbNode("BuzzingHoneyBee_jackpotBar.csb")

    self:runCsbAction("idleframe",true)
end

function BuzzingHoneyBeeJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

function BuzzingHoneyBeeJackPotBarView:onExit()
end

function BuzzingHoneyBeeJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function BuzzingHoneyBeeJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)

    self:updateSize()
end

function BuzzingHoneyBeeJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]

    local info1 = {label = label1, sx = 1, sy = 1 }

    self:updateLabelSize(info1, 350)
end

function BuzzingHoneyBeeJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return BuzzingHoneyBeeJackPotBarView
