---
--island
--2018年4月12日
--GoldenBrickNode.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"
local GoldenBrickNode = class("GoldenBrickNode",SpeicalReel)

GoldenBrickNode.m_runState = nil
GoldenBrickNode.m_runSpeed = nil
GoldenBrickNode.m_endRunData = nil

--状态
-- local BEGIN_RUN_SPEED = 10    --开始时匀速
-- local BEGIN_RUN_TIME = 0.8    

-- local INCREMENT_SPEED = 10    --加速
-- local INCREMENT_TIME = 2
      
-- local MAX_SPEED = 300         
-- local MAX_SPEED_TIME = 1

-- local SLOW_SPEED = 30
-- local SLOW_TIME = 1
GoldenBrickNode.m_runActions = nil
GoldenBrickNode.m_runNowAction = nil
GoldenBrickNode.m_runDatafunc = nil

local INCREMENT_SPEED = 12         --速度增量 (像素/帧)
local DECELER_SPEED = -10         --速度减量 (像素/帧)

local BEGIN_SPEED = 400             --初速度
local BEGIN_SPEED_TIME = 0.5     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 2         --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 1.5       --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 2.5          --匀速时间
local MAX_SPEED = 1700
local MIN_SPEED = 400
local REVERSE_SPEED = 270


local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1     --加速
local DECELER_STATE = 2    --减速

-- 小块中奖音效
GoldenBrickNode.m_littleBitSounds = {}

function GoldenBrickNode:initUI(data)
      SpeicalReel.initUI(self, data)

      if data > 288 then
            INCREMENT_SPEED = 18
            DECELER_SPEED = -15
            BEGIN_SPEED = 255
            MIN_SPEED = 600
            REVERSE_SPEED = 400
      end
      self.m_runState = UNIFORM_STATE
      self.m_runSpeed = BEGIN_SPEED

      self:setRunningParam(BEGIN_SPEED)
  
      self.m_runActions = self:getMoveActions()
      self.m_runNowAction = self:getNextMoveActions()
end

function GoldenBrickNode:getNextMoveActions()
      if self.m_runActions ~= nil and #self.m_runActions > 0 then
            local action = self.m_runActions[1]
            table.remove( self.m_runActions, 1)
            if #self.m_runActions == 0 then
                  self.m_runDataList = self.m_endRunData
                  self.m_dataListPoint = 1
            end
            return action
      end
      assert(false,"没有速度 序列了")
end

--设置滚动序列
function GoldenBrickNode:getMoveActions()
      local runActions = {}
      local actionUniform1 = {time = BEGIN_SPEED_TIME, status = UNIFORM_STATE}
      local actionAcc = {time = ACC_SPEED_TIMES, addSpeed = INCREMENT_SPEED, maxSpeed = MAX_SPEED , status = ACC_STATE}
      local actionUniform2 = {time = HIGH_SPEED_TIME, status = UNIFORM_STATE}
      local actionDeceler = {time = DECELER_SPEED_TIMES, decelerSpeed = DECELER_SPEED, minSpeed = MIN_SPEED ,status = DECELER_STATE}
      local actionUniform3 = {status = UNIFORM_STATE}
      runActions[#runActions + 1] = actionUniform1
      runActions[#runActions + 1] = actionAcc
      runActions[#runActions + 1] = actionUniform2
      runActions[#runActions + 1] = actionDeceler
      runActions[#runActions + 1] = actionUniform3
      return runActions
end

--重写每帧走的距离
function GoldenBrickNode:setDtMoveDis(dt)
      self:changeRunState(dt)

      self.m_dtMoveDis = -dt * self.m_runSpeed
end

--状态切换
GoldenBrickNode.m_timeCount = 0
GoldenBrickNode.m_countDownTime = BEGIN_ACC_DELAY_TIME

function GoldenBrickNode:getIsTimeDown(actionTime)
      if actionTime == nil then
            return false
      end

      if self.m_timeCount >= actionTime then
           return true
      end
      return false
end

function GoldenBrickNode:initRunDate(runData, getRunDatafunc)
      self.m_runDataList = getRunDatafunc
      self.m_runDatafunc = getRunDatafunc
      self.m_endRunData = runData
      self.m_dataListPoint = 1
end


function GoldenBrickNode:changeRunState(dt)
      self.m_timeCount = self.m_timeCount + dt

      local runState = self.m_runNowAction.status
      local actionTime = self.m_runNowAction.time
      if runState == UNIFORM_STATE or runState == HIGHT_STATE then
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

function GoldenBrickNode:getNextRunData()
      if type(self.m_runDataList) == "function" then
            local runData = self.m_runDataList()
            if #self.m_runActions == 1 then
                  while self.m_endRunData[1].SymbolType.num == runData.SymbolType.num do
                        runData = self.m_runDataList()
                  end
            end
            return runData
      else
          local nowPoint = self.m_dataListPoint
          self.m_dataListPoint = self.m_dataListPoint + 1
          local nextData = nil
          if nowPoint <= #self.m_runDataList  then
              nextData = self.m_runDataList[nowPoint]
          end
          return nextData
      end
end

--重写回弹 最终信号上面创建一个假的
function GoldenBrickNode:runResAction()
      local runData = self.m_runDatafunc()
      
      while self.m_endRunData[1].SymbolType.num == runData.SymbolType.num do
            runData = self.m_runDatafunc()
      end
      local node = self.getSlotNodeBySymbolType(runData.SymbolType)
      node.Height = runData.Height

      self.m_clipNode:addChild(node, runData.Zorder) 
      self:setRunCreateNodePos(node)
      self:pushToSymbolList(node)

      SpeicalReel.runResAction(self)
end

function GoldenBrickNode:getResAction()
      local timeDown = 0
      local speedActionTable = {}
      local dis = self.RES_DIS 
      local speedStart = REVERSE_SPEED
      local preSpeed = speedStart/ 118
      for i= 1, 5 do
          speedStart = speedStart - preSpeed * (11 - i) * 2
          local moveDis = dis / 5
          local time = moveDis / speedStart
          timeDown = timeDown + time
          local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
          speedActionTable[#speedActionTable + 1] = moveBy
      end
      local delay = cc.DelayTime:create(0.1)
      timeDown = timeDown + 0.1
      speedActionTable[#speedActionTable + 1] = delay
      local moveBy = cc.MoveBy:create(0.2, cc.p(0, -self.RES_DIS))
      speedActionTable[#speedActionTable + 1] = moveBy:reverse()
      timeDown = timeDown + 0.2
      
      return speedActionTable, timeDown
  end

function GoldenBrickNode:runReelDown()
      self:changeReelStatus(REEL_STATUS.IDLE)
      self.m_dataListPoint = 1
      if self.m_endCallBackFun ~= nil then
          self.m_endCallBackFun()
      end
end

function GoldenBrickNode:onExit()
      self.m_clipNode:removeAllChildren()
end

return GoldenBrickNode