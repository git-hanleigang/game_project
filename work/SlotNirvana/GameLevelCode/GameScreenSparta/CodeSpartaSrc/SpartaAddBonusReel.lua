---
--island
--2018年4月12日
--SpartaAddBonusReel.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"
local SpartaAddBonusReel = class("SpartaAddBonusReel",SpeicalReel)
local RUN_TAG = 
{
    SYMBOL_TAG = 1,               --滚动信号tag 
    SPEICAL_TAG = 10000,          --特殊元素如遮罩层等等 不参与滚动
}
SpartaAddBonusReel.m_runState = nil
SpartaAddBonusReel.m_runSpeed = nil
SpartaAddBonusReel.m_endRunData = nil
SpartaAddBonusReel.m_allRunSymbols = nil

SpartaAddBonusReel.m_runActions = nil
SpartaAddBonusReel.m_runNowAction = nil

local BONUS_SYMBOL    = 94
local INCREMENT_SPEED = 20        --速度增量 (像素/帧)
local DECELER_SPEED   = -20         --速度减量 (像素/帧)

local BEGIN_SPEED      = 800    --初速度
local BEGIN_SPEED_TIME = 0      --x秒后开始加速 (秒)
local ACC_SPEED_TIMES  = 3      --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 3   --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 3       --匀速时间
local MAX_SPEED       = 800
local MIN_SPEED       = 800
local ANCHOR_POINT_Y  = 0.5

local UNIFORM_STATE = 0 --匀速
local ACC_STATE     = 1 --加速
local DECELER_STATE = 2 --减速
local HIGH_STATE    = 3 --高速

local DECELER_SYMBOL_NUM = 12
local SYMBOL_HEIGHT = 110

SpartaAddBonusReel.m_endCallBackFun = nil
SpartaAddBonusReel.m_PlayAddBonusFlyEffectCallBackFun = nil
SpartaAddBonusReel.m_reelHeight = nil

--状态切换
SpartaAddBonusReel.m_timeCount = 0
SpartaAddBonusReel.m_countDownTime = BEGIN_ACC_DELAY_TIME

SpartaAddBonusReel.m_randomDataFunc = nil

SpartaAddBonusReel.distance = 0

function SpartaAddBonusReel:initUI()
      SpeicalReel.initUI(self)      
      self.m_runState = UNIFORM_STATE
      self.m_runSpeed = BEGIN_SPEED
      self:setRunningParam(BEGIN_SPEED)
      self:initAction()
end

function SpartaAddBonusReel:initAction()
        
      self.m_runActions = self:getMoveActions()
      self.m_runNowAction = self:getNextMoveActions()
      self.m_dataListPoint = 1
end

function SpartaAddBonusReel:initFirstSymbolBySymbols(initDataList, reelHeight)
      self.m_reelHeight = reelHeight
      
      for i=1, #initDataList do
            local data = initDataList[i]
            local node = self.getSlotNodeBySymbolType(data.SymbolType)
            node.Height = data.Height
            self.m_clipNode:addChild(node, data.Zorder, data.SymbolType) 
            local posY = 0
            if i == 1 then
                posY = node.Height*0.5
            else 
                posY = (i-1)*node.Height + node.Height*0.5
            end
            node:setPosition(cc.p(0, posY ))
            self:pushToSymbolList(node)
      end
end

function SpartaAddBonusReel:getDisToReelLowBoundary(node)
      local nodePosY = node:getPositionY()
      local dis = nodePosY - node.Height/2
      return dis
  end



function SpartaAddBonusReel:getNextRunData()

     local  nextData = self.m_allRunSymbols[1]
      table.remove(self.m_allRunSymbols, 1)
      return nextData
  end
  
  
function SpartaAddBonusReel:createNextNode()
      if self:getLastSymbolTopY() <= 55 then
            return 
      end
      -- print("createNextNode ===getLastSymbolTopY=== " .. self:getLastSymbolTopY()) 
      local nextNodeData = self:getNextRunData()
      if nextNodeData == nil then
          nextNodeData = self.m_randomDataFunc()
      end
  
      local node = self.getSlotNodeBySymbolType(nextNodeData.SymbolType)

      node.Height = nextNodeData.Height
      node.isEndNode = nextNodeData.Last

      self.m_clipNode:addChild(node, nextNodeData.Zorder, nextNodeData.SymbolType) 
      self:setRunCreateNodePos(node)
      self:pushToSymbolList(node)
      if nextNodeData.SymbolType == BONUS_SYMBOL then
            node:setVisible(false)
            node:setTag(BONUS_SYMBOL)
            self.m_PlayAddBonusFlyEffectCallBackFun()
      end
      if nextNodeData.Last and self.m_endDis == nil then
          --创建出EndNode 计算出还需多长距离停止移动
          self.m_endDis = self:getDisToReelLowBoundary(node)-8
      end
      -- gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_wheel_run.mp3")
      --是否超过上边界 没有的话需要继续创建
      if self:getNodeTopY(node) >= self.m_reelHeight then
          self:createNextNode()
      end
end 
function SpartaAddBonusReel:getNodeTopY(node)
      local nodePosY = node:getPositionY()
      local topY = node.Height * ANCHOR_POINT_Y + nodePosY
      return topY
  end
function SpartaAddBonusReel:getNextMoveActions()
      if self.m_runActions ~= nil and #self.m_runActions > 0 then
            local action = self.m_runActions[1]
            table.remove( self.m_runActions, 1)
            return action
      end
      assert(false,"没有速度 序列了")
end

--设置滚动序列
function SpartaAddBonusReel:getMoveActions()
      local runActions = {}
      local actionUniform1 = {time = BEGIN_SPEED_TIME, status = UNIFORM_STATE}
      local actionAcc = {time = ACC_SPEED_TIMES, addSpeed = INCREMENT_SPEED, maxSpeed = MAX_SPEED , status = ACC_STATE}
      local actionUniform2 = {time = HIGH_SPEED_TIME, status = HIGH_STATE}
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
function SpartaAddBonusReel:setDtMoveDis(dt)
      self:changeRunState(dt)
      self.m_dtMoveDis = dt * self.m_runSpeed
      self.distance = self.distance + self.m_dtMoveDis
end

function SpartaAddBonusReel:getIsTimeDown(actionTime)
      if actionTime == nil then
            return false
      end

      if self.m_timeCount >= actionTime then
           return true
      end
      return false
end

function SpartaAddBonusReel:initRunDate(runData, getRunDatafunc)
      self.m_randomDataFunc = getRunDatafunc
      self.m_runDataList = getRunDatafunc
      self.m_endRunData = runData
      self.m_dataListPoint = 1
end

function SpartaAddBonusReel:setAllRunSymbols( allSymbols )
      self.m_allRunSymbols = allSymbols
end

function SpartaAddBonusReel:setEndDate(endData)
      self.m_endRunData = endData
end

function SpartaAddBonusReel:beginMove()
           
      if self:getReelStatus() ~= REEL_STATUS.IDLE then
          return 
      end
      self:changeReelStatus(REEL_STATUS.RUNNING)
      local bEndMove = false
      self.m_endNode = nil
      self.m_endDis = nil
  
      self:onUpdate(function(dt)
          if globalData.slotRunData.gameRunPause then
              return
          end
          if bEndMove then
              self:createNextNode()
              self:unscheduleUpdate()
              self:runResAction()
              return
          end        
          self:checkBonusPos()
          self:createNextNode()
          self:setDtMoveDis(dt)
          if self.m_endDis ~= nil then
              --判断是否结束
              local endDis = self.m_endDis + self.m_dtMoveDis
              if endDis <= 0 then
                  self.m_dtMoveDis = self.m_endDis
                  bEndMove = true
              else
                  self.m_endDis = endDis
              end
          end
  
          self:removeBelowReelSymbol()
          self:updateSymbolPosY()
      end)
end

function SpartaAddBonusReel:updateSymbolPosY()
      local childs = self.m_clipNode:getChildren()
      for i=1,#childs do
    
          local node = childs[i]
          if node:getTag() < RUN_TAG.SPEICAL_TAG then
              local nowPosY = node:getPositionY()
              node:setPositionY(nowPosY + self.m_dtMoveDis)
          end
      end
end

function SpartaAddBonusReel:setRunCreateNodePos(newNode)
      local topY = self:getLastSymbolTopY()
      local newPosY = - newNode.Height * ANCHOR_POINT_Y
      newNode:setPosition(cc.p(0, newPosY))
end

function SpartaAddBonusReel:getLastSymbolTopY( )
      local lastNode = self:getLastSymbolNode()
      local topY = 0
      
      if lastNode == nil then
          return topY, lastNode
      end
  
      local lastNodePosY = lastNode:getPositionY()
      local topY = lastNodePosY -- lastNodePosY - lastNode.Height * (1 - ANCHOR_POINT_Y)
      return topY, lastNode
end
  --- 返回最后一个信号
function SpartaAddBonusReel:getLastSymbolNode()
      if #self.m_symbolNodeList == 0 then
          return nil
      end
      return  self.m_symbolNodeList[#self.m_symbolNodeList]
end

function SpartaAddBonusReel:checkBonusPos()
      local childs = self.m_clipNode:getChildren()
      for i=1,#childs do
            local node = childs[i]
            local Tag = node:getTag()
            if Tag == BONUS_SYMBOL then
                  local nowPosY = node:getPositionY()
                  if nowPosY >= self.m_reelHeight/2+100 then
                        node:setVisible(true)
                  end
            end
      end
end

function SpartaAddBonusReel:changeRunState(dt)
      self.m_timeCount = self.m_timeCount + dt

      local runState = self.m_runNowAction.status
      local actionTime = self.m_runNowAction.time
      if runState == UNIFORM_STATE  then
            if self:getIsTimeDown(actionTime) then
                  self.m_runNowAction = self:getNextMoveActions()
                  self.m_timeCount = 0
            end
      elseif runState == HIGH_STATE then
            if self:getIsTimeDown(actionTime) and #self.m_allRunSymbols <= DECELER_SYMBOL_NUM then
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


function SpartaAddBonusReel:runResAction()

      self:runReelDown()
      self.m_endCallBackFun()

end

function SpartaAddBonusReel:playRunEndAnima()
      for i=1,# self.m_symbolNodeList do
            local node =  self.m_symbolNodeList[i]
            node:runAnim("idleframe")
      end
end

function SpartaAddBonusReel:setEndCallBackFun(func)
      self.m_endCallBackFun = func
end

function SpartaAddBonusReel:setPlayAddBonusFlyEffectCallBackFun(func)
      self.m_PlayAddBonusFlyEffectCallBackFun = func
end



return SpartaAddBonusReel