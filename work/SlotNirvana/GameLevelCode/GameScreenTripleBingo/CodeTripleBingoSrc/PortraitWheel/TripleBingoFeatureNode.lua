---
--island
--2018年4月12日
--TripleBingoFeatureNode.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"
local TripleBingoFeatureNode = class("TripleBingoFeatureNode", SpeicalReel)

--Reel中的层级
local ZORDER = {
    CLIP_ORDER = 1000,
    RUN_CLIP_ORDER = 2000,
    SHOW_ORDER = 2000,
    UI_ORDER = 3000
}

TripleBingoFeatureNode.m_runState = nil
TripleBingoFeatureNode.m_runSpeed = nil
TripleBingoFeatureNode.m_endRunData = nil
TripleBingoFeatureNode.m_allRunSymbols = nil

--状态
TripleBingoFeatureNode.m_runActions = nil
TripleBingoFeatureNode.m_runNowAction = nil

local INCREMENT_SPEED = 50 --速度增量 (像素/帧)
local DECELER_SPEED = -30 --速度减量 (像素/帧)

local BEGIN_SPEED = 250 --初速度
local BEGIN_SPEED_TIME = 0 --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 1 --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 3 --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 3 --匀速时间
local MAX_SPEED = 2500
local MIN_SPEED = 350

local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1 --加速
local DECELER_STATE = 2 --减速
local HIGH_STATE = 3 --高速

TripleBingoFeatureNode.DECELER_SYMBOL_NUM = 12

TripleBingoFeatureNode.m_endCallBackFun = nil

TripleBingoFeatureNode.m_reelHeight = nil

--状态切换
TripleBingoFeatureNode.m_timeCount = 0

TripleBingoFeatureNode.m_randomDataFunc = nil

TripleBingoFeatureNode.distance = 0

function TripleBingoFeatureNode:initUI()
    SpeicalReel.initUI(self)
    self.m_runState = UNIFORM_STATE
    self.m_runSpeed = BEGIN_SPEED
    self:setRunningParam(BEGIN_SPEED)
    self:initAction()

    self.m_allRunSymbols = {}
end


function TripleBingoFeatureNode:initAction()
    self.m_runActions = self:getMoveActions()
    self.m_runNowAction = self:getNextMoveActions()
    self.m_timeCount = 0
    self.m_dataListPoint = 1
end

--[[
    @desc: --初始化时盘面信号  
    author:{author}
    time:2018-11-28 14:34:29
    @return:
]]
function TripleBingoFeatureNode:initFirstSymbolBySymbols(initDataList)
    for i = 1, #initDataList do
        local data = initDataList[i]
        local node = self.getSlotNodeBySymbolType(data.SymbolType,data)
        node.Height = data.Height
        node.isEndNode = data.Last
        self.m_clipNode:addChild(node)
        self:setRunCreateNodePos(node)
        self:pushToSymbolList(node)
    end
end

function TripleBingoFeatureNode:getDisToReelLowBoundary(node)
    local nodePosY = node:getPositionY()
    local dis = nodePosY - self.m_reelHeight / 2
    return dis
end

function TripleBingoFeatureNode:getNextRunData()
    local nextData = nil
    if self.m_allRunSymbols and #self.m_allRunSymbols > 0 then
        nextData = self.m_allRunSymbols[1]
        table.remove(self.m_allRunSymbols, 1)
    end

    return nextData
end

function TripleBingoFeatureNode:createNextNode(_isEnd)
    if self:getLastSymbolTopY() >= self.m_reelHeight and not _isEnd then
        --最后一个Node > 上边界 创建新的node  反之创建
        return
    end

    local nextNodeData = self:getNextRunData()
    if nextNodeData == nil then
        nextNodeData = self.m_randomDataFunc()
    end

    local node = self.getSlotNodeBySymbolType(nextNodeData.SymbolType,nextNodeData)
    node.Height = nextNodeData.Height
    node.isEndNode = nextNodeData.Last

    self.m_clipNode:addChild(node, nextNodeData.Zorder, nextNodeData.SymbolType)
    self:setRunCreateNodePos(node)
    self:pushToSymbolList(node)

    if nextNodeData.Last and self.m_endDis == nil then
        --创建出EndNode 计算出还需多长距离停止移动
        self.m_endDis = self:getDisToReelLowBoundary(node)
    end

    --是否超过上边界 没有的话需要继续创建
    if self:getNodeTopY(node) <= self.m_reelHeight then
        self:createNextNode()
    end
end

function TripleBingoFeatureNode:getNextMoveActions()
    if self.m_runActions ~= nil and #self.m_runActions > 0 then
        local action = self.m_runActions[1]
        table.remove(self.m_runActions, 1)
        return action
    end
    assert(false, "没有速度 序列了")
end

--设置滚动序列
function TripleBingoFeatureNode:getMoveActions()
    local runActions = {}
    local actionUniform1 = {time = BEGIN_SPEED_TIME, status = UNIFORM_STATE}
    local actionAcc = {time = ACC_SPEED_TIMES, addSpeed = INCREMENT_SPEED, maxSpeed = MAX_SPEED, status = ACC_STATE}
    local actionUniform2 = {time = HIGH_SPEED_TIME, status = HIGH_STATE}
    local actionDeceler = {time = DECELER_SPEED_TIMES, decelerSpeed = DECELER_SPEED, minSpeed = MIN_SPEED, status = DECELER_STATE}
    local actionUniform3 = {status = UNIFORM_STATE}
    runActions[#runActions + 1] = actionUniform1
    runActions[#runActions + 1] = actionAcc
    runActions[#runActions + 1] = actionUniform2
    runActions[#runActions + 1] = actionDeceler
    runActions[#runActions + 1] = actionUniform3
    return runActions
end

--重写每帧走的距离
function TripleBingoFeatureNode:setDtMoveDis(dt)
    self:changeRunState(dt)

    self.m_dtMoveDis = -dt * self.m_runSpeed

    self.distance = self.distance + self.m_dtMoveDis
end

function TripleBingoFeatureNode:getIsTimeDown(actionTime)
    if actionTime == nil then
        return false
    end

    if self.m_timeCount >= actionTime then
        return true
    end
    return false
end

function TripleBingoFeatureNode:initRunDate(runData, getRunDatafunc)
    self.m_randomDataFunc = getRunDatafunc
    self.m_runDataList = getRunDatafunc
    self.m_endRunData = runData
    self.m_dataListPoint = 1
end

function TripleBingoFeatureNode:setAllRunSymbols(allSymbols)
    self.m_allRunSymbols = allSymbols
end

function TripleBingoFeatureNode:setEndDate(endData)
    self.m_endRunData = endData
end

function TripleBingoFeatureNode:beginMove()
    if self:getReelStatus() ~= REEL_STATUS.IDLE then
        return
    end
    self:changeReelStatus(REEL_STATUS.RUNNING)
    local bEndMove = false
    self.m_endNode = nil
    self.m_endDis = nil

    self:onUpdate(
        function(dt)
            if globalData.slotRunData.gameRunPause then
                return
            end
            if bEndMove then
                self:createNextNode(true)
  
                self:unscheduleUpdate()
                self:runResAction()
                return
            end

            self:createNextNode()
            self:setDtMoveDis(1/60)
            if self.m_endDis ~= nil then
                --判断是否结束
                local endDis = self.m_endDis + self.m_dtMoveDis
                if endDis <= 0 then
                    self.m_dtMoveDis = -self.m_endDis
                    bEndMove = true
                else
                    self.m_endDis = endDis
                end
            end

            self:removeBelowReelSymbol()
            self:updateSymbolPosY()
        end
    )
end

function TripleBingoFeatureNode:changeRunState(dt)
    self.m_timeCount = self.m_timeCount + dt

    local runState = self.m_runNowAction.status
    local actionTime = self.m_runNowAction.time
    if runState == UNIFORM_STATE then
        if self:getIsTimeDown(actionTime) then
            self.m_runNowAction = self:getNextMoveActions()
            self.m_timeCount = 0
        end
    elseif runState == HIGH_STATE then
        if self:getIsTimeDown(actionTime) then
            self.m_runNowAction = self:getNextMoveActions()
            self.m_timeCount = 0
        end
    elseif runState == ACC_STATE then
        local addSpeed = self.m_runNowAction.addSpeed
        local maxSpeed = self.m_runNowAction.maxSpeed
        if self:getIsTimeDown(actionTime) then
            self.m_runNowAction = self:getNextMoveActions()
            self.m_timeCount = 0
        else
            if self.m_runSpeed < maxSpeed then
                self.m_runSpeed = self.m_runSpeed + addSpeed
            else
                self.m_runSpeed = maxSpeed
            end
        end
    elseif runState == DECELER_STATE then
        local decelerSpeed = self.m_runNowAction.decelerSpeed
        local minSpeed = self.m_runNowAction.minSpeed
        if self.m_runSpeed > minSpeed then
            self.m_runSpeed = self.m_runSpeed + decelerSpeed
        else
            self.m_runSpeed = minSpeed
            if self:getIsTimeDown(actionTime) then
                self.m_runNowAction = self:getNextMoveActions()
                self.m_runSpeed = self.m_runSpeed + decelerSpeed
                self.m_timeCount = 0
            end
        end
    end
end

function TripleBingoFeatureNode:getResAction()
    local timeDown = 0
    local speedActionTable = {}
    local dis = self.RES_DIS
    local speedStart = self.m_runSpeed
    local preSpeed = speedStart / 118
    for i = 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = moveDis / speedStart
        timeDown = timeDown + time
        local moveBy = cc.MoveBy:create(time, cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end

    local moveBy = cc.MoveBy:create(0.1, cc.p(0, -dis))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1

    return speedActionTable, timeDown
end

function TripleBingoFeatureNode:runResAction()
    local downDelayTime = 0
    for index = 1, #self.m_symbolNodeList do
        local node = self.m_symbolNodeList[index]
        local actionTable, downTime = self:getResAction()
        node:runAction(cc.Sequence:create(actionTable))
        if downDelayTime < downTime then
            downDelayTime = downTime
        end
    end

    performWithDelay(
        self,
        function()
            --滚动完毕
            self:runReelDown()
            self.m_endCallBackFun()
        end,
        downDelayTime
    )
end

function TripleBingoFeatureNode:playRunEndAnima()
    for i = 1, #self.m_symbolNodeList do
        local node = self.m_symbolNodeList[i]
        --      node:setVisible(false)

        if node.isEndNode then
        else
        end
    end
end

function TripleBingoFeatureNode:playRunEndAnimaIde()
    for i = 1, #self.m_symbolNodeList do
        local node = self.m_symbolNodeList[i]
        node:runAnim("idleframe")
    end
end

function TripleBingoFeatureNode:setEndCallBackFun(func)
    self.m_endCallBackFun = func
end

return TripleBingoFeatureNode
