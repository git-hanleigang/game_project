--[[
Author: cxc
Date: 2022-03-23 17:45:16
LastEditTime: 2022-03-23 17:45:17
LastEditors: cxc
Description: 3日行为付费聚合活动   base 
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/views/WildChallengeActBaseTaskUI.lua
--]]
local WildChallengeActBaseTaskUI = class("WildChallengeActBaseTaskUI", BaseView)
local Config = require("activities.Activity_WildChallenge.config.WildChallengeConfig")

function WildChallengeActBaseTaskUI:initDatas()
    self.m_taskNodeList = {}
    self.m_actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getRunningData()
end

function WildChallengeActBaseTaskUI:initCsbNodes()
    self.m_nodeCat = self:findChild("node_cat")
    self.m_nodeUI = self:findChild("node_ui")
end

function WildChallengeActBaseTaskUI:getPhaseCodePath()
    return ""
end
function WildChallengeActBaseTaskUI:getEndCodePath()
    return ""
end

function WildChallengeActBaseTaskUI:initUI()
    WildChallengeActBaseTaskUI.super.initUI(self)

    -- 初始化阶段 节点UI
    self:initPhaseUI()

    -- 初始化 cat 节点UI
    -- self:initCatUI()
end

function WildChallengeActBaseTaskUI:updateUI()
    -- 更新数据
    self.m_actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getRunningData()
    local curOpenIdx = self.m_actData:getCurPhaseIdx()
    local phaseData = self.m_actData:getPhaseListDataByIdx(curOpenIdx)
    local taskNode = self.m_taskNodeList[curOpenIdx]
    if not taskNode then
        return
    end

    taskNode:updateData(phaseData, curOpenIdx)
    taskNode:initState()
end

-- 初始化 cat 节点UI
-- function WildChallengeActBaseTaskUI:initCatUI()
function WildChallengeActBaseTaskUI:initSpineUI()
    WildChallengeActBaseTaskUI.super.initSpineUI(self)
    
    local spineNode = util_spineCreate("Activity/spine/WC_cat", true, true, 1)
    self.m_nodeCat:addChild(spineNode)
    self.m_spineNode = spineNode

    local posW = self:getCurCatPositionW()
    local posL = self.m_nodeCat:convertToNodeSpaceAR(posW)
    self.m_spineNode:move(posL)

    self:playCatSpineIdle()
end

-- 播放猫 静态动画
function WildChallengeActBaseTaskUI:playCatSpineIdle()
    local actIdleName = "idle1"
    local curOpenIdx = self.m_actData:getCurPhaseIdx()
    if curOpenIdx > 1 then
        actIdleName = "idle2"
    end
    util_spinePlay(self.m_spineNode, actIdleName, true)
end

-- 初始化阶段 节点UI
function WildChallengeActBaseTaskUI:initPhaseUI()
    local curOpenIdx = self.m_actData:getCurPhaseIdx()
    local phaseDataList = self.m_actData:getPhaseListData()
    self.m_taskNodeList = {}
    for i=1, #phaseDataList do
        local data = phaseDataList[i]
        -- 普通阶段
        local parent = self:findChild("node_eyu" .. i)
        local path = self:getPhaseCodePath()
        if i == #phaseDataList then
            -- 最后大奖阶段
            parent = self:findChild("node_end")
            path = self:getEndCodePath()
        end 

        if parent then
            local view = util_createView(path, i, data, curOpenIdx)
            parent:addChild(view)
            table.insert(self.m_taskNodeList, i, view)
        end
        
    end
end

-- 获取当前猫的位置
function WildChallengeActBaseTaskUI:getCurCatPositionW(_bAni)
    local curOpenIdx = self.m_actData:getCurPhaseIdx()
    local taskNode = self.m_taskNodeList[curOpenIdx - 1]
    if not taskNode then
        return self.m_nodeCat:convertToWorldSpaceAR(cc.p(0, 0))
    end
    return taskNode:getCatNodePosW()
end

-- 获取当前开启任务的位置
function WildChallengeActBaseTaskUI:getCurTaskPosLX()
    local curOpenIdx = self.m_actData:getCurPhaseIdx()
    local phaseDataList = self.m_actData:getPhaseListData()
    local node = self:findChild("node_eyu" .. curOpenIdx)
    if curOpenIdx == #phaseDataList then
        node = self:findChild("node_end")
    end

    if not node then
        return 0
    end

    -- 节点位置 + 节点居中（-display.width * 0.5） + 内容偏移（250 鳄鱼不在0，0点）
    local posX = node:getPositionX() - display.width * 0.5 + 250 * (curOpenIdx - 1)
    return posX
end

-- 领取成功
function WildChallengeActBaseTaskUI:collectSuccessEvt(_delayTime, _cb)
    self.m_actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getRunningData()

    _delayTime = _delayTime or 0
    self:catJumpBegin(_delayTime, _cb)
    performWithDelay(self, handler(self, self.updatePhaseNode), _delayTime)
end

-- 播放猫跳的 动作
function WildChallengeActBaseTaskUI:catJumpBegin(_delayTime, _jumpOverCb)
    local phaseDataList = self.m_actData:getPhaseListData()
    local curOpenIdx = self.m_actData:getCurPhaseIdx()
    if curOpenIdx > #phaseDataList then
        -- 最后一个任务不跳
        if _jumpOverCb then
            _jumpOverCb()
        end
        return
    end

    local posW = self:getCurCatPositionW(true)
    local posL = self.m_nodeCat:convertToNodeSpaceAR(posW)
    local delayTime = cc.DelayTime:create(_delayTime)
    local startCB = cc.CallFunc:create(function()
        -- 播放 猫 跳到新任务动画
        self:playCatSpineJump(curOpenIdx)
    end)
    local delayTime2 = cc.DelayTime:create(0.26)
    local moveTo = cc.MoveTo:create(0.44, posL)
    local endCB = cc.CallFunc:create(function()
        if _jumpOverCb then
            _jumpOverCb()
        end
    end)
    self.m_spineNode:runAction(cc.Sequence:create(delayTime, startCB, delayTime2, moveTo, endCB))
end

-- 播放猫跳的spine动画
function WildChallengeActBaseTaskUI:playCatSpineJump(_curOpenIdx)
    local actJumpName = "jump1"
    if _curOpenIdx and _curOpenIdx > 1 then
        actJumpName = "jump2"
    end
    util_spinePlay(self.m_spineNode, actJumpName, false)
    util_spineEndCallFunc(self.m_spineNode, actJumpName, function()
        self:playCatSpineIdle()
    end)
end 

-- 领奖后 更新任务节点状态
function WildChallengeActBaseTaskUI:updatePhaseNode(_target, _bUnlock)
    local phaseDataList = self.m_actData:getPhaseListData()
    local curOpenIdx = self.m_actData:getCurPhaseIdx()
    for i = 1, #self.m_taskNodeList do
        local nodeObj = self.m_taskNodeList[i]
        local phaseData = phaseDataList[i]
        nodeObj:updateData(phaseData, curOpenIdx)
        if _bUnlock then
            if curOpenIdx == i then
                -- 解锁新任务 
                nodeObj:updateState(Config.TASK_STATE.UNLOCK)
                break
            end
        else
            if curOpenIdx - 1 == i then 
                -- 领取的该任务 放猫
                performWithDelay(self, function()
                    nodeObj:updateState(Config.TASK_STATE.GO_COLLECT)
                end, self:getTaskCollectDelayTime())
            elseif curOpenIdx - 2 == i then
                -- 上次的任务 变为 领取状态
                performWithDelay(self, function()
                    nodeObj:updateState(Config.TASK_STATE.GO_COLLECT)
                end, self:getTaskCompleteDelayTime())
            end
        end
        
    end
end

-- 检查当前开启的任务是否自动领取
function WildChallengeActBaseTaskUI:checkAutoCollect(_bForce)
    local curOpenIdx = self.m_actData:getCurPhaseIdx()
    local nodeObj = self.m_taskNodeList[curOpenIdx]
    local bCanAutoCollect = false
    if nodeObj then
        bCanAutoCollect = nodeObj:checkAutoCollect(_bForce)
    end

    return bCanAutoCollect
end

function WildChallengeActBaseTaskUI:getTaskCollectDelayTime()
    return 1
end

function WildChallengeActBaseTaskUI:getTaskCompleteDelayTime()
    return 0
end

return WildChallengeActBaseTaskUI