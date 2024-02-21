---
--xcyy
--2018年5月23日
--StarryAnniversaryJackPotBarView.lua
local StarryAnniversaryPublicConfig = require "StarryAnniversaryPublicConfig"
local StarryAnniversaryJackPotBarView = class("StarryAnniversaryJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

local jackpotNodeName = {"grand", "major", "minor", "mini"}
local jackpotNode = {}
function StarryAnniversaryJackPotBarView:initUI()
    self:createCsbNode("StarryAnniversary_base_Jackpot.csb")

    for _index, _nodeName in ipairs(jackpotNodeName) do
        jackpotNode[_index] = util_createAnimation("StarryAnniversary_base_jackpot_".._nodeName..".csb")
        self:findChild("Node_".._nodeName):addChild(jackpotNode[_index])
        jackpotNode[_index]:runCsbAction("idle", true)
    end

    local tipsNode = util_createAnimation("StarryAnniversary_base_Jackpot_text.csb")
    self:findChild("Node_text"):addChild(tipsNode)
    tipsNode:runCsbAction("idle", true)
end

function StarryAnniversaryJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function StarryAnniversaryJackPotBarView:onEnter()
    StarryAnniversaryJackPotBarView.super.onEnter(self)
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
function StarryAnniversaryJackPotBarView:updateJackpotInfo()
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

function StarryAnniversaryJackPotBarView:updateSize()
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

function StarryAnniversaryJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

return StarryAnniversaryJackPotBarView
