---
--xcyy
--2018年5月23日
--ToroLocoReSpinJackPotBarView.lua
local ToroLocoPublicConfig = require "ToroLocoPublicConfig"
local ToroLocoReSpinJackPotBarView = class("ToroLocoReSpinJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

local JACKPOT_INDEX = {
    Grand = 1,
    Major = 2,
    Minor = 3,
    Mini = 4
}

function ToroLocoReSpinJackPotBarView:initUI()
    self:createCsbNode("JackPotBarToroLoco_Respin.csb")

    self:runCsbAction("auto", true)
    -- 锁定动画
    self.m_jackpotLockSpine = util_spineCreate("ToroLoco_jackpot_lock", true, true)
    self:findChild("Node_suoding"):addChild(self.m_jackpotLockSpine)

    -- 添加光
    self.m_darkNode = util_createAnimation("JackPotBarToroLoco_Respin_0.csb")
    self:findChild("Node_1"):addChild(self.m_darkNode)
    self.m_darkNode:runCsbAction("idle", true)

    self.m_winEffectNode = {}
    for index = 1, 2 do
        self.m_winEffectNode[index] = util_createAnimation("JackPotBarToroLoco_tx.csb")
        self:findChild("Node_tx"..index):addChild(self.m_winEffectNode[index])
        self.m_winEffectNode[index]:setVisible(false)
    end
end

function ToroLocoReSpinJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ToroLocoReSpinJackPotBarView:onEnter()
    ToroLocoReSpinJackPotBarView.super.onEnter(self)
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
function ToroLocoReSpinJackPotBarView:updateJackpotInfo()
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

function ToroLocoReSpinJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 0.97, sy = 0.97}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.97, sy = 0.97}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 0.97, sy = 0.97}
    self:updateLabelSize(info1, 300)
    self:updateLabelSize(info2, 203)
    self:updateLabelSize(info3, 203)
    self:updateLabelSize(info4, 203)
end

function ToroLocoReSpinJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

--[[
    锁定grand
]]
function ToroLocoReSpinJackPotBarView:lockGrand()
    self.m_jackpotLockSpine:setVisible(true)
    util_spinePlay(self.m_jackpotLockSpine, "darkidle2", true)

    self.m_darkNode:runCsbAction("darkidle", true)
end

--[[
    解锁grand
]]
function ToroLocoReSpinJackPotBarView:unLockGrand()
    self.m_jackpotLockSpine:setVisible(false)
    self.m_darkNode:runCsbAction("idle", true)
end

--[[
    播放中奖效果
]]
function ToroLocoReSpinJackPotBarView:playWinEffect(_indexType)
    local jackpotIndex = JACKPOT_INDEX[_indexType]
    if jackpotIndex == 1 then
        self.m_winEffectNode[jackpotIndex]:setVisible(true)
        self.m_winEffectNode[jackpotIndex]:runCsbAction("actionframe", true)
    else
        self.m_winEffectNode[2]:setVisible(true)
        self.m_winEffectNode[2]:runCsbAction("actionframe2", true)
        self:runCsbAction("idle"..(jackpotIndex-1), true)
    end
end

--[[
    隐藏中奖效果
]]
function ToroLocoReSpinJackPotBarView:hideWinEffect(_indexType)
    local jackpotIndex = JACKPOT_INDEX[_indexType]
    if jackpotIndex == 1 then
        self.m_winEffectNode[jackpotIndex]:setVisible(false)
    else
        self.m_winEffectNode[2]:setVisible(false)
        self:runCsbAction("auto", true)
    end
end

return ToroLocoReSpinJackPotBarView
