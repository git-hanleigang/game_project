---
--xcyy
--2018年5月23日
--StarryAnniversaryJackPotBarFeatureView.lua
local StarryAnniversaryPublicConfig = require "StarryAnniversaryPublicConfig"
local StarryAnniversaryJackPotBarFeatureView = class("StarryAnniversaryJackPotBarFeatureView", util_require("base.BaseView"))

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

local jackpotNodeName = {"grand", "major", "minor", "mini"}
local jackpotNode = {}

function StarryAnniversaryJackPotBarFeatureView:initUI()
    self:createCsbNode("StarryAnniversary_feature_Jackpot.csb")

    for _index, _nodeName in ipairs(jackpotNodeName) do
        jackpotNode[_index] = util_createAnimation("StarryAnniversary_feature_Jackpot_".._nodeName..".csb")
        self:findChild("Node_".._nodeName):addChild(jackpotNode[_index])
        jackpotNode[_index]:runCsbAction("idle", true)
    end

    self:runCsbAction("idle", true)
end

function StarryAnniversaryJackPotBarFeatureView:initMachine(machine)
    self.m_machine = machine
end

function StarryAnniversaryJackPotBarFeatureView:onEnter()
    StarryAnniversaryJackPotBarFeatureView.super.onEnter(self)
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
function StarryAnniversaryJackPotBarFeatureView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(jackpotNode[1]:findChild(GrandName), 1, true)
    self:changeNode(jackpotNode[2]:findChild(MajorName), 2, true)
    self:changeNode(jackpotNode[3]:findChild(MinorName), 3)
    self:changeNode(jackpotNode[4]:findChild(MiniName), 4)

    self:updateSize()
end

function StarryAnniversaryJackPotBarFeatureView:updateSize()
    local label1 = jackpotNode[1]:findChild(GrandName)
    local label2 = jackpotNode[2]:findChild(MajorName)
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local label3 = jackpotNode[3]:findChild(MinorName)
    local info3 = {label = label3, sx = 1, sy = 1}
    local label4 = jackpotNode[4]:findChild(MiniName)
    local info4 = {label = label4, sx = 1, sy = 1}
    self:updateLabelSize(info1, 237)
    self:updateLabelSize(info2, 237)
    self:updateLabelSize(info3, 237)
    self:updateLabelSize(info4, 237)
end

function StarryAnniversaryJackPotBarFeatureView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

--[[
    中奖jackpot
]]
function StarryAnniversaryJackPotBarFeatureView:playWinJackpotEffect(_index)
    jackpotNode[JACKPOT_INDEX[string.lower(_index)]]:runCsbAction("actionframe", true)
end

--[[
    隐藏中奖jackpot
]]
function StarryAnniversaryJackPotBarFeatureView:hideWinJackpotEffect(_index)
    jackpotNode[JACKPOT_INDEX[string.lower(_index)]]:runCsbAction("idle", true)
end

return StarryAnniversaryJackPotBarFeatureView
