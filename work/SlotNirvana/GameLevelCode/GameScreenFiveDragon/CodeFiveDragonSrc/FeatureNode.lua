---
--island
--2018年4月12日
--FeatureNode.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"
local FeatureNode = class("FeatureNode",SpeicalReel)

FeatureNode.m_runState = nil
FeatureNode.m_runSpeed = nil
FeatureNode.m_endRunData = nil

--状态
-- local BEGIN_RUN_SPEED = 10    --开始时匀速
-- local BEGIN_RUN_TIME = 0.8    

-- local INCREMENT_SPEED = 10    --加速
-- local INCREMENT_TIME = 2
      
-- local MAX_SPEED = 300         
-- local MAX_SPEED_TIME = 1

-- local SLOW_SPEED = 30
-- local SLOW_TIME = 1
FeatureNode.m_runActions = nil
FeatureNode.m_runNowAction = nil

local INCREMENT_SPEED = 12         --速度增量 (像素/帧)
local DECELER_SPEED = -10         --速度减量 (像素/帧)

local BEGIN_SPEED = 150             --初速度
local BEGIN_SPEED_TIME = 1.5     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 2         --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 3.5       --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 0          --匀速时间
local MAX_SPEED = 1700
local MIN_SPEED = 130


local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1     --加速
local DECELER_STATE = 2    --减速

FeatureNode.m_endCallBackFun = nil
FeatureNode.m_endValue = nil
-- 小块中奖音效
FeatureNode.m_littleBitSounds = {}

function FeatureNode:initUI(data)
      SpeicalReel.initUI(self, data)
      self.m_endValue = data

      self.m_runState = UNIFORM_STATE
      self.m_runSpeed = BEGIN_SPEED

      for i = 1, 3 do
            self.m_littleBitSounds[#self.m_littleBitSounds + 1] = "FiveDragonSounds/music_FiveDragon_LittleBit_" .. i .. ".mp3"
        end
      
      local resourceFilename="FiveDragon_Feature_Node.csb"
      self:createCsbNode(resourceFilename)
      self:setRunningParam(BEGIN_SPEED)

      self.endSp = self:findChild("sp_num")
      local spStr = "effect/FiveDragon_shuzi_".. data ..".png"
      -- self.endSp:setTexture(spStr)
      self.endSp:setSpriteFrame(spStr)
      
      self.m_runActions = self:getMoveActions()
      self.m_runNowAction = self:getNextMoveActions()
end

function FeatureNode:getNextMoveActions()
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
function FeatureNode:getMoveActions()
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
function FeatureNode:setDtMoveDis(dt)
      self:changeRunState(dt)

      self.m_dtMoveDis = -dt * self.m_runSpeed
end

--状态切换
FeatureNode.m_timeCount = 0
FeatureNode.m_countDownTime = BEGIN_ACC_DELAY_TIME

function FeatureNode:getIsTimeDown(actionTime)
      if actionTime == nil then
            return false
      end

      if self.m_timeCount >= actionTime then
           return true
      end
      return false
end

function FeatureNode:initRunDate(runData, getRunDatafunc)
      self.m_runDataList = getRunDatafunc
      self.m_endRunData = runData
      self.m_dataListPoint = 1
end


function FeatureNode:changeRunState(dt)
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


-- function FeatureNode:createCsbNode(filePath)
--       self.m_baseFilePath=filePath
--       self.m_csbNode,self.m_csbAct=util_csbCreate(self.m_baseFilePath)
--       self:addChild(self.m_csbNode)
-- end  

function FeatureNode:getResultAnimaName()
      local animaName = nil
      if self.m_endValue == 1 or self.m_endValue == 2 then
            
            animaName = "Settlement3"
            gLobalSoundManager:playSound(self.m_littleBitSounds[1]) 
      elseif self.m_endValue == 3 or self.m_endValue == 4 or self.m_endValue == 5 or self.m_endValue == 6 then
            animaName = "Settlement2"
            gLobalSoundManager:playSound(self.m_littleBitSounds[2]) 
      elseif self.m_endValue == 7 or self.m_endValue == 8 or self.m_endValue == 9 or self.m_endValue == 10 then
            animaName = "Settlement1"
            gLobalSoundManager:playSound(self.m_littleBitSounds[3]) 
      end
      return animaName
end

function FeatureNode:runResAction()
      self:runReelDown()
      --播放动画
      self.m_clipNode:setVisible(false)
      self:setLocalZOrder(2)
      self:runCsbAction(self:getResultAnimaName(),false, function (  )
            self:setLocalZOrder(1)
      end)
      if self.m_endCallBackFun ~= nil then
            self.m_endCallBackFun()
      end
end

function FeatureNode:setEndCallBackFun(func)
      self.m_endCallBackFun = func
end

function FeatureNode:onExit()
      self.m_clipNode:removeAllChildren()
end

return FeatureNode