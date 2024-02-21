---
--xcyy
--2018年5月23日
--TurkeyDayJackPotBarView.lua
local PublicConfig = require "TurkeyDayPublicConfig"
local TurkeyDayJackPotBarView = class("TurkeyDayJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

function TurkeyDayJackPotBarView:initUI()
    self:createCsbNode("TurkeyDay_basefree_jackpot.csb")

    local jackpotNodeTbl = {"Node_idle_GRAND", "Node_idle_mega", "Node_idle_major", "Node_idle_minor", "Node_idle_mini"}
    self.m_totalCount = 5
    self.m_jackpotIdleSpineTbl = {}

    for i=1, self.m_totalCount do
        self.m_jackpotIdleSpineTbl[i] = util_spineCreate("TurkeyDay_base_jackpot",true,true)
        self:findChild(jackpotNodeTbl[i]):addChild(self.m_jackpotIdleSpineTbl[i])
    end

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:setJackpotIdle(1)
end

function TurkeyDayJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function TurkeyDayJackPotBarView:onEnter()
    TurkeyDayJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- 播放jackpot-idle
function TurkeyDayJackPotBarView:setJackpotIdle(_curIndex)
    local curIndex = _curIndex
    if curIndex == 1 then
        for k, v in pairs(self.m_jackpotIdleSpineTbl) do
            v:setVisible(false)
        end
    end

    local jackpotIdleNameTbl = {"idle_GRAND", "idle_mega", "idle_major", "idle_minor", "idle_mini"}
    -- 间隔播放jackpot-idle
    if curIndex <= self.m_totalCount then
         local tblActionList = {}
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_jackpotIdleSpineTbl[curIndex]:setVisible(true)
            util_spinePlay(self.m_jackpotIdleSpineTbl[curIndex], jackpotIdleNameTbl[curIndex], true)
        end)
        -- 播到第40帧再开始播下一个
        -- tblActionList[#tblActionList+1] = cc.DelayTime:create(40/60)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:setJackpotIdle(curIndex+1)
        end)
        local seq = cc.Sequence:create(tblActionList)
        self.m_scWaitNode:runAction(seq)
    end
end

-- 更新jackpot 数值信息
--
function TurkeyDayJackPotBarView:updateJackpotInfo()
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

function TurkeyDayJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.73, sy = 0.73}
    local info2 = {label = label2, sx = 0.73, sy = 0.73}
    local info3 = {label = label3, sx = 0.73, sy = 0.73}
    local info4 = {label = label4, sx = 0.73, sy = 0.73}
    local info5 = {label = label5, sx = 0.73, sy = 0.73}

    self:updateLabelSize(info1, 245)
    self:updateLabelSize(info2, 245)
    self:updateLabelSize(info3, 245)
    self:updateLabelSize(info4, 245)
    self:updateLabelSize(info5, 245)
end

function TurkeyDayJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value, 20, nil, nil, true))
end

return TurkeyDayJackPotBarView
