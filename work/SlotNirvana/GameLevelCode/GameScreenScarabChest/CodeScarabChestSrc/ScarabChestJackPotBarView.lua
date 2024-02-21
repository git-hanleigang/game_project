---
--xcyy
--2018年5月23日
--ScarabChestJackPotBarView.lua
local PublicConfig = require "ScarabChestPublicConfig"
local ScarabChestJackPotBarView = class("ScarabChestJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"

function ScarabChestJackPotBarView:initUI()
    self:createCsbNode("ScarabChest_Jackpot.csb")
    self:setIdle()

    self.m_collectJackpotNode = {}
    self.m_collectJackpotNode[1] = self:findChild("Node_Collect_Grand")
    self.m_collectJackpotNode[2] = self:findChild("Node_Collect_Major")
    self.m_collectJackpotNode[3] = self:findChild("Node_Collect_Minor")

    self.m_totalCount = 3
    self.m_collectJackpotTbl = {}
    local tempGrandNodeTbl = {}
    local tempMajorNodeTbl = {}
    local tempMinorNodeTbl = {}
    for i=1, 3 do
        self.m_collectJackpotNode[i]:setVisible(false)
        tempGrandNodeTbl[i] = util_createAnimation("ScarabChest_Jackpot_Cell.csb")
        self:findChild("collect_grand_"..i):addChild(tempGrandNodeTbl[i])
        tempGrandNodeTbl[i]:findChild("grand"):setVisible(true)
        tempGrandNodeTbl[i]:findChild("major"):setVisible(false)
        tempGrandNodeTbl[i]:findChild("minor"):setVisible(false)

        tempMajorNodeTbl[i] = util_createAnimation("ScarabChest_Jackpot_Cell.csb")
        self:findChild("collect_major_"..i):addChild(tempMajorNodeTbl[i])
        tempMajorNodeTbl[i]:findChild("grand"):setVisible(false)
        tempMajorNodeTbl[i]:findChild("major"):setVisible(true)
        tempMajorNodeTbl[i]:findChild("minor"):setVisible(false)

        tempMinorNodeTbl[i] = util_createAnimation("ScarabChest_Jackpot_Cell.csb")
        self:findChild("collect_minor_"..i):addChild(tempMinorNodeTbl[i])
        tempMinorNodeTbl[i]:findChild("grand"):setVisible(false)
        tempMinorNodeTbl[i]:findChild("major"):setVisible(false)
        tempMinorNodeTbl[i]:findChild("minor"):setVisible(true)
    end

    table.insert(self.m_collectJackpotTbl, tempGrandNodeTbl)
    table.insert(self.m_collectJackpotTbl, tempMajorNodeTbl)
    table.insert(self.m_collectJackpotTbl, tempMinorNodeTbl)

    -- 当前收集的进度
    self.m_curCollectProcess = {0, 0, 0}
end

function ScarabChestJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ScarabChestJackPotBarView:setIdle()
    self:runCsbAction("idle", true)
end

-- jackpot收集状态
function ScarabChestJackPotBarView:resetShowJackpotState(_jackpotState)
    local jackpotState = _jackpotState
    for i=1, self.m_totalCount do
        self.m_collectJackpotNode[i]:setVisible(jackpotState)
        for j=1, self.m_totalCount do
            self.m_collectJackpotTbl[i][j]:runCsbAction("idle", true)
        end
    end
end

-- free里收集节点
-- 三类jackpot的收集进度，依次为grand，major，minor
function ScarabChestJackPotBarView:initShowCollectNode(_jackpotList)
    local jackpotList = _jackpotList

    -- 显示当前的收集
    for k, curJackpotProcess in pairs(jackpotList) do
        self.m_curCollectProcess[k] = curJackpotProcess
        for i=1, self.m_totalCount do
            if i <= curJackpotProcess then
                self.m_collectJackpotTbl[k][i]:runCsbAction("idle1", true)
                if i == 2 then
                    self:lastCollectTrigger(k)
                end
            end
        end
    end
end

-- 收集jackpot动画
-- jackpotType 1:grand 2:major 3:minor
function ScarabChestJackPotBarView:collectCurJackpotNode(_jackpotType)
    local jackpotType = _jackpotType
    self.m_curCollectProcess[jackpotType] = self.m_curCollectProcess[jackpotType] + 1
    if self.m_curCollectProcess[jackpotType] >= self.m_totalCount then
        self.m_curCollectProcess[jackpotType] = self.m_totalCount
    end
    local curProcess = self.m_curCollectProcess[jackpotType]
    if curProcess <= self.m_totalCount then
        local collectNode = self.m_collectJackpotTbl[jackpotType][curProcess]
        if collectNode then
            collectNode:runCsbAction("actionframe", false, function()
                collectNode:runCsbAction("idle1", true)
                if curProcess == 2 then
                    self:lastCollectTrigger(jackpotType)
                elseif curProcess == 3 then
                    -- self:playTriggerAction(jackpotType)
                end
            end)
        end
    end
end

-- 待触发（剩最后一个）
function ScarabChestJackPotBarView:lastCollectTrigger(_jackpotType)
    local jackpotType = _jackpotType
    local collectNode = self.m_collectJackpotTbl[jackpotType][self.m_totalCount]
    if collectNode then
        util_resetCsbAction(self.m_csbAct)
        collectNode:runCsbAction("idle2", true)
    end
end

-- 获取当前次收集次是否集满
function ScarabChestJackPotBarView:getCurIsJackpot(_jackpotType)
    local jackpotType = _jackpotType
    if self.m_curCollectProcess[jackpotType] == self.m_totalCount - 1 then
        return true
    end
    return false
end

--[[
    获取下一个未激活的节点
]]
function ScarabChestJackPotBarView:getNextNode(_jackpotType)
    local jackpotType = _jackpotType
    local curProcess = self.m_curCollectProcess[jackpotType]
    local node = self.m_collectJackpotTbl[jackpotType][curProcess + 1]
    if not node then
        node = self.m_collectJackpotTbl[jackpotType][#self.m_collectJackpotTbl]
    end
    return node
end

-- jackpot结束
function ScarabChestJackPotBarView:playJackpotOverAni(_jackpotType)
    local jackpotType = _jackpotType
    self.m_curCollectProcess[jackpotType] = 0
    for i=1, self.m_totalCount do
        local collectNode = self.m_collectJackpotTbl[jackpotType][i]
        collectNode:runCsbAction("over", false, function()
            collectNode:runCsbAction("idle", true)
        end)
    end
end

-- 触发
function ScarabChestJackPotBarView:playTriggerAction(_jackpotType)
    local jackpotType = _jackpotType
    self.m_curCollectProcess[jackpotType] = 0
    util_resetCsbAction(self.m_csbAct)
    local triggerActName = {"Node_Trigger_Grand", "Node_Trigger_Major", "Node_Trigger_Minor"}
    for k, v in pairs(triggerActName) do
        if jackpotType == k then
            self:findChild(v):setVisible(true)
        else
            self:findChild(v):setVisible(false)
        end
    end
    local actName = "actionframe"..jackpotType
    self:runCsbAction(actName, true)
end

function ScarabChestJackPotBarView:onEnter()
    ScarabChestJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- 更新jackpot 数值信息
--
function ScarabChestJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3)

    self:updateSize()
end

function ScarabChestJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 0.9, sy = 1}
    local info2 = {label = label2, sx = 0.65, sy = 0.7}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.65, sy = 0.7}
    self:updateLabelSize(info1, 479)
    self:updateLabelSize(info2, 479)
    self:updateLabelSize(info3, 479)
end

function ScarabChestJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return ScarabChestJackPotBarView
