---
--xcyy
--2018年5月23日
--StarryAnniversaryJackPotBarBonusView.lua
local StarryAnniversaryPublicConfig = require "StarryAnniversaryPublicConfig"
local StarryAnniversaryJackPotBarBonusView = class("StarryAnniversaryJackPotBarBonusView", util_require("base.BaseView"))
StarryAnniversaryJackPotBarBonusView.m_playOtherIndex = 1
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
function StarryAnniversaryJackPotBarBonusView:initUI()
    self:createCsbNode("StarryAnniversary_bonus_Jackpot.csb")

    for _index, _nodeName in ipairs(jackpotNodeName) do
        jackpotNode[_index] = util_createAnimation("StarryAnniversary_base_jackpot_".._nodeName..".csb")
        self:findChild("Node_jackpot_".._nodeName):addChild(jackpotNode[_index])
        jackpotNode[_index]:runCsbAction("idle", true)
    end

    -- 延时节点
    self.m_effectNode = cc.Node:create()
    self:findChild("Node"):addChild(self.m_effectNode)
end

function StarryAnniversaryJackPotBarBonusView:initMachine(machine)
    self.m_machine = machine
end

function StarryAnniversaryJackPotBarBonusView:onEnter()
    StarryAnniversaryJackPotBarBonusView.super.onEnter(self)
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
function StarryAnniversaryJackPotBarBonusView:updateJackpotInfo()
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

function StarryAnniversaryJackPotBarBonusView:updateSize()
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

--[[
    获得平均bet
]]
function StarryAnniversaryJackPotBarBonusView:getAvgBet( )
    if self.m_machine.m_bonusInfo and self.m_machine.m_bonusInfo.avgBet then
        return tonumber(self.m_machine.m_bonusInfo.avgBet)
    end
    return nil
end

function StarryAnniversaryJackPotBarBonusView:changeNode(label, index, isJump)
    local value = self.m_machine.m_machine:BaseMania_updateJackpotScore(index, self:getAvgBet())
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

--[[
    重置轮播
]]
function StarryAnniversaryJackPotBarBonusView:resetPlayOtherJackpot()
    self.m_playOtherIndex = self.m_playOtherIndex - 1
    self.m_effectNode:stopAllActions()
    self:playOtherJackpot()
end

--[[
    轮播显示除grand之外 其他3个
]]
function StarryAnniversaryJackPotBarBonusView:playOtherJackpot()
    if not self.m_machine then
        return
    end

    for _index = 2, 4 do
        jackpotNode[_index]:setVisible(false)
    end
    self.m_playOtherIndex = self.m_playOtherIndex + 1
    local curJackpotNode = jackpotNode[self.m_playOtherIndex]
    curJackpotNode:setVisible(true)
    util_nodeFadeIn(curJackpotNode, 0.3, 180, 255, nil, nil)

    local lastJackpotNode
    if self.m_playOtherIndex ~= 2 then
        lastJackpotNode = jackpotNode[self.m_playOtherIndex-1]
    else
        lastJackpotNode = jackpotNode[4]
    end
    lastJackpotNode:setVisible(true)
    util_nodeFadeIn(lastJackpotNode, 0.3, 255, 180, nil, function()
        lastJackpotNode:setVisible(false)
    end)

    performWithDelay(
        self.m_effectNode,
        function()
            if self.m_playOtherIndex >= 4 then
                self.m_playOtherIndex = 1
            end
            self:playOtherJackpot()
        end,
        5
    )
end

function StarryAnniversaryJackPotBarBonusView:initJackpot( )
    self.m_playOtherIndex = 1
    self.m_effectNode:stopAllActions()
    self:playOtherJackpot()
end

--[[
    中奖jackpot
]]
function StarryAnniversaryJackPotBarBonusView:playWinJackpotEffect(_index)
    self.m_effectNode:stopAllActions()

    if JACKPOT_INDEX[string.lower(_index)] > 1 then
        for index = 2, 4 do
            jackpotNode[index]:setVisible(false)
            util_setChildNodeOpacity(jackpotNode[index], 255)
        end
        jackpotNode[JACKPOT_INDEX[string.lower(_index)]]:setVisible(true)
    end
    jackpotNode[JACKPOT_INDEX[string.lower(_index)]]:runCsbAction("actionframe", true)
end

--[[
    隐藏中奖jackpot
]]
function StarryAnniversaryJackPotBarBonusView:hideWinJackpotEffect(_index)
    jackpotNode[JACKPOT_INDEX[string.lower(_index)]]:runCsbAction("idle", true)
    self:resetPlayOtherJackpot()
end

return StarryAnniversaryJackPotBarBonusView
