---
--xcyy
--2018年5月23日
--PudgyPandaJackPotBarView.lua
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaJackPotBarView = class("PudgyPandaJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MegaName = "m_lb_mega"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function PudgyPandaJackPotBarView:initUI()
    self:createCsbNode("PudgyPanda_jackpot.csb")

    local jackpotNodeTbl = {"Node_GRAND", "Node_MEGA", "Node_MAJOR", "Node_MINOR", "Node_MINI"}

    self.m_totalCount = 5
    self.m_jackpotIdleAniTbl = {}

    for i=1, self.m_totalCount do
        self.m_jackpotIdleAniTbl[i] = util_createAnimation("PudgyPanda_jackpot_tx.csb")
        self:findChild(jackpotNodeTbl[i]):addChild(self.m_jackpotIdleAniTbl[i])
    end

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:setJackpotIdle(1)
end

function PudgyPandaJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function PudgyPandaJackPotBarView:onEnter()
    PudgyPandaJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- 播放jackpot-idle
function PudgyPandaJackPotBarView:setJackpotIdle(_curIndex)
    local curIndex = _curIndex
    if curIndex == 1 then
        for k, v in pairs(self.m_jackpotIdleAniTbl) do
            util_resetCsbAction(v.m_csbAct)
            v:runCsbAction("idle2", true)
        end
    end

    -- 间隔播放jackpot-idle
    if curIndex <= self.m_totalCount then
         local tblActionList = {}
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            util_resetCsbAction( self.m_jackpotIdleAniTbl[curIndex].m_csbAct)
            self.m_jackpotIdleAniTbl[curIndex]:runCsbAction("idle", true)
        end)
        -- 播到第40帧再开始播下一个
        tblActionList[#tblActionList+1] = cc.DelayTime:create(40/60)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:setJackpotIdle(curIndex+1)
        end)
        local seq = cc.Sequence:create(tblActionList)
        self.m_scWaitNode:runAction(seq)
    end
end

-- 触发jackpot
function PudgyPandaJackPotBarView:playTriggerJackpot(_jackpotIndex)
    local jackpotIndex = _jackpotIndex
    util_resetCsbAction( self.m_jackpotIdleAniTbl[jackpotIndex].m_csbAct)
    self.m_jackpotIdleAniTbl[jackpotIndex]:runCsbAction("actionframe", true)
end

-- 更新jackpot 数值信息
--
function PudgyPandaJackPotBarView:updateJackpotInfo()
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

function PudgyPandaJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.93, sy = 1}
    local info2 = {label = label2, sx = 0.93, sy = 1}
    local info3 = {label = label3, sx = 0.93, sy = 1}
    local info4 = {label = label4, sx = 0.93, sy = 1}
    local info5 = {label = label5, sx = 0.93, sy = 1}

    self:updateLabelSize(info1, 243)
    self:updateLabelSize(info2, 243)
    self:updateLabelSize(info3, 243)
    self:updateLabelSize(info4, 243)
    self:updateLabelSize(info5, 243)
end

function PudgyPandaJackPotBarView:changeNode(label, index, isJump)
    local curBet = globalData.slotRunData:getCurTotalBet()
    if self.m_machine.m_refreshJackpotBar and self.m_machine.m_curFreeType ~= self.m_machine.ENUM_FREE_TYPE.FAT_FORTUNE_FREE and self.m_machine.m_runSpinResultData.p_avgBet and self.m_machine.m_runSpinResultData.p_avgBet > 0 then
        curBet = self.m_machine.m_runSpinResultData.p_avgBet
    end
    local value=self.m_machine:BaseMania_updateJackpotScore(index,curBet)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return PudgyPandaJackPotBarView
