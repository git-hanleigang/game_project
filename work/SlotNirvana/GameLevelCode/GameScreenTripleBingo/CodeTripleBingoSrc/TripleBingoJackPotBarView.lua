---
--xcyy
--2018年5月23日
--TripleBingoJackPotBarView.lua
local TripleBingoPublicConfig = require "TripleBingoPublicConfig"
local TripleBingoJackPotBarView = class("TripleBingoJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins"
local MajorName = "m_lb_coins_1"
local MinorName = "m_lb_coins_2"
local MiniName = "m_lb_coins_3"

function TripleBingoJackPotBarView:initUI()
    self:createCsbNode("TripleBingo_jackpot.csb")
    self:initLightAnim()
end

function TripleBingoJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function TripleBingoJackPotBarView:onEnter()
    TripleBingoJackPotBarView.super.onEnter(self)
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
function TripleBingoJackPotBarView:updateJackpotInfo()
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

function TripleBingoJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local label3 = self.m_csbOwner[MinorName]
    local label4 = self.m_csbOwner[MiniName]
    local info1 = {label = label1, sx = 0.9, sy = 0.9}
    local info2 = {label = label2, sx = 0.9, sy = 0.9}
    local info3 = {label = label3, sx = 0.9, sy = 0.9}
    local info4 = {label = label4, sx = 0.9, sy = 0.9}
    self:updateLabelSize(info1, 209)
    self:updateLabelSize(info2, 194)
    self:updateLabelSize(info3, 170)
    self:updateLabelSize(info4, 170)
end

function TripleBingoJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:getTripleBingoJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

function TripleBingoJackPotBarView:initLightAnim()
    self.m_lightAnimList = {}
    for _index=1,4 do
        local lightAnim = util_spineCreate("TripleBingo_jackpot_sg", true, true)
        local parent = self:findChild(string.format("Node_sg%d", _index))
        parent:addChild(lightAnim)
        local animName = string.format("idle%d", _index)
        util_spinePlay(lightAnim, animName, true)
        self.m_lightAnimList[_index] = lightAnim
    end
end
return TripleBingoJackPotBarView
