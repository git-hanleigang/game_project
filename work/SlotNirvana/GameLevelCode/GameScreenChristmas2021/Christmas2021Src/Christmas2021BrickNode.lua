---
--island
--2018年4月12日
--Christmas2021BrickNode.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"

local Christmas2021BrickNode = class("Christmas2021BrickNode",SpeicalReel)

Christmas2021BrickNode.m_runState = nil
Christmas2021BrickNode.m_runSpeed = nil
Christmas2021BrickNode.m_endRunData = nil

--Reel中的层级
local ZORDER = {
      CLIP_ORDER = 1000,
      RUN_CLIP_ORDER = 2000,
      SHOW_ORDER = 2000,
      UI_ORDER = 3000,
  }

--状态
-- local BEGIN_RUN_SPEED = 10    --开始时匀速
-- local BEGIN_RUN_TIME = 0.8    

-- local INCREMENT_SPEED = 10    --加速
-- local INCREMENT_TIME = 2
      
-- local MAX_SPEED = 300         
-- local MAX_SPEED_TIME = 1

-- local SLOW_SPEED = 30
-- local SLOW_TIME = 1
Christmas2021BrickNode.m_runActions = nil
Christmas2021BrickNode.m_runNowAction = nil
Christmas2021BrickNode.m_runDatafunc = nil

local INCREMENT_SPEED = 12         --速度增量 (像素/帧)
local DECELER_SPEED = -10         --速度减量 (像素/帧)

local BEGIN_SPEED = 150             --初速度
local BEGIN_SPEED_TIME = 1.5     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 2         --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 1.5       --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 3.5          --匀速时间
local MAX_SPEED = 1700
local MIN_SPEED = 400
local REVERSE_SPEED = 270


local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1     --加速
local DECELER_STATE = 2    --减速

-- 小块中奖音效
Christmas2021BrickNode.m_littleBitSounds = {}

function Christmas2021BrickNode:initUI(data)
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

--[[
    @desc: -初始化Reel结构 
    author:{author}
    time:2018-11-28 12:03:55
    @return:
    @parma:wildth 宽 height 高 getSlotNodeFunc 内存池取  pushSlotNodeFunc 内存池删
]]
function Christmas2021BrickNode:init(data,wildth ,height, getSlotNodeFunc, pushSlotNodeFunc)
      self.m_clipNode = cc.ClippingRectangleNode:create({x= - wildth / 2, y = 0, width = wildth, height = height})
      self.m_clipNode:setPositionY(-height / 2)
      self:addChild(self.m_clipNode,ZORDER.CLIP_ORDER)
      
      --滚动中提升symbol层级遮罩
      self.m_runclipNode = cc.ClippingRectangleNode:create({x= -wildth / 2, y = -height, width = wildth, height = height * 2})
      self.m_runclipNode:setAnchorPoint(cc.p(0.5, 0.5))
      self:addChild(self.m_runclipNode,ZORDER.RUN_CLIP_ORDER)
  
      self.m_reelWidth = wildth
      self.m_reelHeight = height
      -- body
      self.getSlotNodeBySymbolType = getSlotNodeFunc
      self.pushSlotNodeToPoolBySymobolType = pushSlotNodeFunc
end

function Christmas2021BrickNode:getNextMoveActions()
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
function Christmas2021BrickNode:getMoveActions()
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
function Christmas2021BrickNode:setDtMoveDis(dt)
      self:changeRunState(dt)

      self.m_dtMoveDis = -dt * self.m_runSpeed
end

--状态切换
Christmas2021BrickNode.m_timeCount = 0
Christmas2021BrickNode.m_countDownTime = BEGIN_ACC_DELAY_TIME

function Christmas2021BrickNode:getIsTimeDown(actionTime)
      if actionTime == nil then
            return false
      end

      if self.m_timeCount >= actionTime then
           return true
      end
      return false
end

function Christmas2021BrickNode:initRunDate(runData, getRunDatafunc)
      self.m_runDataList = getRunDatafunc
      self.m_runDatafunc = getRunDatafunc
      self.m_endRunData = runData
      self.m_dataListPoint = 1
end


function Christmas2021BrickNode:changeRunState(dt)
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

function Christmas2021BrickNode:getNextRunData()
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
function Christmas2021BrickNode:runResAction()
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

function Christmas2021BrickNode:getResAction()
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

function Christmas2021BrickNode:runReelDown()
      self:changeReelStatus(REEL_STATUS.IDLE)
      self.m_dataListPoint = 1
      if self.m_endCallBackFun ~= nil then
          self.m_endCallBackFun()
      end
  end

function Christmas2021BrickNode:onEnter()
end

function Christmas2021BrickNode:onExit()
end

return Christmas2021BrickNode