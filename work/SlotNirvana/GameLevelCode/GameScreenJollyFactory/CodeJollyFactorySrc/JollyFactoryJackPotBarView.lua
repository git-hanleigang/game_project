---
--xcyy
--2018年5月23日
--JollyFactoryJackPotBarView.lua
local PublicConfig = require "JollyFactoryPublicConfig"
local JollyFactoryJackPotBarView = class("JollyFactoryJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}

function JollyFactoryJackPotBarView:initUI()
    self:createCsbNode("JollyFactory_JackPotBar.csb")

    self.m_hitLights = {}
    for index = 1,4 do
        local hitLight = util_createAnimation("JollyFactory_JackPotBar_tx.csb")
        self:findChild("Node_tx"..index):addChild(hitLight)
        hitLight:setVisible(false)
        self.m_hitLights[index] = hitLight
    end
end

function JollyFactoryJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function JollyFactoryJackPotBarView:onEnter()
    JollyFactoryJackPotBarView.super.onEnter(self)
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
function JollyFactoryJackPotBarView:updateJackpotInfo()
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

function JollyFactoryJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 1, sy = 1}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 1, sy = 1}
    self:updateLabelSize(info1, 320)
    self:updateLabelSize(info2, 320)
    self:updateLabelSize(info3, 275)
    self:updateLabelSize(info4, 275)
end

function JollyFactoryJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value, 12, nil, nil, true))
end

--[[
    显示中奖光效
]]
function JollyFactoryJackPotBarView:showHitLight(jackpotType)
    local jackpotIndex = JACKPOT_INDEX[string.lower(jackpotType)]
    local light = self.m_hitLights[jackpotIndex]
    light:setVisible(true)
    light:runCsbAction("actionframe",true)
end

--[[
    隐藏中奖光效
]]
function JollyFactoryJackPotBarView:hideLights()
    for index = 1,#self.m_hitLights do
        self.m_hitLights[index]:setVisible(false)
    end
end

return JollyFactoryJackPotBarView
