---
--island
--2018年4月12日
--MonsterPartyWheelRunNode.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"
local MonsterPartyWheelRunNode = class("MonsterPartyWheelRunNode",SpeicalReel)

--Reel中的层级
local ZORDER = {
      CLIP_ORDER = 1000,
      RUN_CLIP_ORDER = 2000,
      SHOW_ORDER = 2000,
      UI_ORDER = 3000,
  }

MonsterPartyWheelRunNode.m_runState = nil
MonsterPartyWheelRunNode.m_runSpeed = nil
MonsterPartyWheelRunNode.m_endRunData = nil
MonsterPartyWheelRunNode.m_allRunSymbols = nil

--状态
MonsterPartyWheelRunNode.m_runActions = nil
MonsterPartyWheelRunNode.m_runNowAction = nil

local INCREMENT_SPEED = 10         --速度增量 (像素/帧)
local DECELER_SPEED = -20         --速度减量 (像素/帧)

local BEGIN_SPEED = 80             --初速度
local BEGIN_SPEED_TIME = 0     --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 2         --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 1      --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 1          --匀速时间
local MAX_SPEED = 1800
local MIN_SPEED = 500


local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1     --加速
local DECELER_STATE = 2    --减速
local HIGH_STATE = 3    --高速

local DECELER_SYMBOL_NUM = 15

MonsterPartyWheelRunNode.m_endCallBackFun = nil

MonsterPartyWheelRunNode.m_reelHeight = nil

--状态切换
MonsterPartyWheelRunNode.m_timeCount = 0
MonsterPartyWheelRunNode.m_countDownTime = BEGIN_ACC_DELAY_TIME

MonsterPartyWheelRunNode.m_randomDataFunc = nil

MonsterPartyWheelRunNode.distance = 0

function MonsterPartyWheelRunNode:initUI(wheelView)
      SpeicalReel.initUI(self)      
      self.m_runState = UNIFORM_STATE
      self.m_runSpeed = BEGIN_SPEED

      self.m_isAnit = wheelView.m_isAnit

      
      if self.m_isAnit then
            wheelView:findChild("wheel"):setRotation(180)
      end

      self:setRunningParam(BEGIN_SPEED)
      self:initAction()

      self.m_allRunSymbols = {}
end

--[[
    @desc: -初始化Reel结构 
    author:{author}
    time:2018-11-28 12:03:55
    @return:
    @parma:wildth 宽 height 高 getSlotNodeFunc 内存池取  pushSlotNodeFunc 内存池删
]]
function MonsterPartyWheelRunNode:init(wildth ,height, getSlotNodeFunc, pushSlotNodeFunc)
      self.m_clipNode = cc.Node:create() -- cc.ClippingRectangleNode:create({x= - wildth / 2, y = 0, width = wildth, height = height})
      self:addChild(self.m_clipNode,ZORDER.CLIP_ORDER)
      self.m_clipNode:setPositionX( wildth / 2)
  
      -- local colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 130),wildth * 10 , height* 10 )
      -- colorLayer:setPosition(-wildth * 2 , -height * 2)
      -- self.m_clipNode:addChild(colorLayer, 1, RUN_TAG.SPEICAL_TAG)
      
      -- --滚动中提升symbol层级遮罩
      -- self.m_runclipNode = cc.ClippingRectangleNode:create({x= -wildth / 2, y = -height, width = wildth, height = height * 2})
      -- self.m_runclipNode:setAnchorPoint(cc.p(0.5, 0.5))
      -- self:addChild(self.m_runclipNode,ZORDER.RUN_CLIP_ORDER)
  
      self.m_reelWidth = wildth
      self.m_reelHeight = height
      -- body
      self.getSlotNodeBySymbolType = getSlotNodeFunc
      self.pushSlotNodeToPoolBySymobolType = pushSlotNodeFunc
  end

function MonsterPartyWheelRunNode:initAction()
        
      self.m_runActions = self:getMoveActions()
      self.m_runNowAction = self:getNextMoveActions()
      self.m_dataListPoint = 1
end

-- function MonsterPartyWheelRunNode:initFirstSymbolBySymbols(initDataList, reelHeight)
--       self.m_reelHeight = reelHeight
--       local bottomHeight = -reelHeight / 2

--       local middle =  math.ceil(#initDataList / 2)
--       for i=1, #initDataList do
--             local data = initDataList[i]
  
--             local node = self.getSlotNodeBySymbolType(data.SymbolType)
--             node.Height = data.Height
--             node.score = data.jpScore
--             self.m_clipNode:addChild(node, data.Zorder, data.SymbolType) 
            
--             local lab = util_getChildByName(node, "m_lb_score")
--             if lab ~= nil then
--                   lab:setString(util_coinsLimitLen(node.score, 3))
--             end

--             local lab1 = util_getChildByName(node, "m_lb_score_0")
--             if lab1 ~= nil then
--                   lab1:setString(util_coinsLimitLen(node.score, 3))
--             end

--             local posY = 0

--             if i == 1 then
--                 posY = self.m_reelHeight * 0.5 - (middle - i) * node.Height
--             else 
--                 local topY = self:getLastSymbolTopY()
--                 posY = topY + node.Height * self:getAnchorPointY()
--             end
  
--             node:setPosition(cc.p(0, posY ))
    
--             self:pushToSymbolList(node)
--       end
-- end

function MonsterPartyWheelRunNode:getDisToReelLowBoundary(node)
      local nodePosY = node:getPositionY()
      local dis = nodePosY - self.m_reelHeight / 2
      return dis
  end



function MonsterPartyWheelRunNode:getNextRunData()


     local  nextData = nil
     if self.m_allRunSymbols and #self.m_allRunSymbols > 0 then
            nextData = self.m_allRunSymbols[1]
            table.remove(self.m_allRunSymbols, 1)
     end
      
      return nextData
  end
  
  
function MonsterPartyWheelRunNode:createNextNode()
      if self:getLastSymbolTopY() >= self.m_reelHeight then
            --最后一个Node > 上边界 创建新的node  反之创建
            return 
      end
    
      
      

      local nextNodeData = self:getNextRunData()
      if nextNodeData == nil then
          nextNodeData = self.m_randomDataFunc()
      end
  
      local node = self.getSlotNodeBySymbolType(nextNodeData.SymbolType)
      if nextNodeData.jpScore ~= nil then
            node.score = nextNodeData.jpScore
            local lab = util_getChildByName(node, "m_lb_score")
            if lab ~= nil then
                  lab:setString(util_coinsLimitLen(node.score, 3))
            end

            local lab1 = util_getChildByName(node, "m_lb_score_0")
            if lab1 ~= nil then
                  lab1:setString(util_coinsLimitLen(node.score, 3))
            end
      end
      node.Height = nextNodeData.Height
      node.isEndNode = nextNodeData.Last

      self.m_clipNode:addChild(node, nextNodeData.Zorder, nextNodeData.SymbolType) 
      self:setRunCreateNodePos(node)
      self:pushToSymbolList(node)

      if self.m_isAnit then
            node:setRotation(180)
      end
  
      if nextNodeData.Last and self.m_endDis == nil then
          --创建出EndNode 计算出还需多长距离停止移动
          self.m_endDis = self:getDisToReelLowBoundary(node)
      end


      if self.m_isPlaySound then
            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_Wheel_zhuanDong.mp3")
      end
     
      
      --是否超过上边界 没有的话需要继续创建
      if self:getNodeTopY(node) <= self.m_reelHeight then
          self:createNextNode()
      end
end 
  

function MonsterPartyWheelRunNode:getNextMoveActions()
      if self.m_runActions ~= nil and #self.m_runActions > 0 then
            local action = self.m_runActions[1]
            table.remove( self.m_runActions, 1)
            return action
      end
      assert(false,"没有速度 序列了")
end

--设置滚动序列
function MonsterPartyWheelRunNode:getMoveActions()
      local runActions = {}
      local actionUniform1 = {time = BEGIN_SPEED_TIME, status = UNIFORM_STATE}
      local actionAcc = {time = ACC_SPEED_TIMES, addSpeed = INCREMENT_SPEED, maxSpeed = MAX_SPEED , status = ACC_STATE}
      local actionUniform2 = {time = HIGH_SPEED_TIME,maxSpeed = MAX_SPEED, status = HIGH_STATE}
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
function MonsterPartyWheelRunNode:setDtMoveDis(dt)

      if self.isBeginRun then
            self:changeRunState(dt) 
      end

      self.m_dtMoveDis = -dt * self.m_runSpeed

      self.distance = self.distance + self.m_dtMoveDis


      
end

function MonsterPartyWheelRunNode:getIsTimeDown(actionTime)
      if actionTime == nil then
            return false
      end

      if self.m_timeCount >= actionTime then
           return true
      end
      return false
end

function MonsterPartyWheelRunNode:initRunDate(runData, getRunDatafunc)
      self.m_randomDataFunc = getRunDatafunc
      self.m_runDataList = getRunDatafunc
      self.m_endRunData = runData
      self.m_dataListPoint = 1
end

function MonsterPartyWheelRunNode:setAllRunSymbols( allSymbols )
      self.m_allRunSymbols = allSymbols
end

function MonsterPartyWheelRunNode:setEndDate(endData)
      self.m_endRunData = endData
end

function MonsterPartyWheelRunNode:beginMove()

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

          self:createNextNode()
          self:setDtMoveDis(dt)
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
      end)
  end

function MonsterPartyWheelRunNode:changeRunState(dt)
      self.m_timeCount = self.m_timeCount + dt

      local runState = self.m_runNowAction.status
      local actionTime = self.m_runNowAction.time
      if runState == UNIFORM_STATE  then
            if self:getIsTimeDown(actionTime) then
                  self.m_runNowAction = self:getNextMoveActions()
                  self.m_timeCount = 0
            end
      elseif runState == HIGH_STATE then

            self.m_runSpeed = MAX_SPEED

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


-- function MonsterPartyWheelRunNode:createCsbNode(filePath)
--       self.m_baseFilePath=filePath
--       self.m_csbNode,self.m_csbAct=util_csbCreate(self.m_baseFilePath)
--       self:addChild(self.m_csbNode)
-- end  


function MonsterPartyWheelRunNode:getResAction()
      local timeDown = 0
      local speedActionTable = {}
      local dis = 15 
      local speedStart = self.m_runSpeed
      local preSpeed = speedStart/ 118
      for i= 1, 10 do
          speedStart = speedStart - preSpeed * (11 - i) * 2
          local moveDis = dis / 10
          local time = moveDis / speedStart
          timeDown = timeDown + time
          local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
          speedActionTable[#speedActionTable + 1] = moveBy
      end
  
      local moveBy = cc.MoveBy:create(0.1,cc.p(0, -15 ))
      speedActionTable[#speedActionTable + 1] = moveBy:reverse()
      timeDown = timeDown + 0.1
      
      return speedActionTable, timeDown
  end


function MonsterPartyWheelRunNode:runResAction()
      local downDelayTime = 0
      for index = 1, #self.m_symbolNodeList do
          local node = self.m_symbolNodeList[index]
          local actionTable , downTime = self:getResAction()
          node:runAction(cc.Sequence:create(actionTable))
          if downDelayTime <  downTime then
              downDelayTime = downTime
          end
      end 
  
      performWithDelay(self,function()
         --滚动完毕
         self:runReelDown()
         self.m_endCallBackFun()
      end,downDelayTime)
  end

function MonsterPartyWheelRunNode:playRunEndAnima()
      for i=1,# self.m_symbolNodeList do
           local node =  self.m_symbolNodeList[i]
      --      node:setVisible(false)

           if node.isEndNode then
                  node:setLocalZOrder(10000)
                  -- node:runAnim("actionframe", true, nil, 20)
           else
                  -- node:runAnim("actionframe1")

           end
      end

end

function MonsterPartyWheelRunNode:playRunEndAnimaIde()
      for i=1,# self.m_symbolNodeList do
            local node =  self.m_symbolNodeList[i]
            -- node:runAnim("idleframe")
      end
end

function MonsterPartyWheelRunNode:setEndCallBackFun(func)
      self.m_endCallBackFun = func
end


--[[
    @desc: --初始化时盘面信号  
    author:{author}
    time:2018-11-28 14:34:29
    @return:
]]
function MonsterPartyWheelRunNode:initFirstSymbol(node)
      local wordPos = node:getParent():convertToWorldSpace(cc.p(node:getPositionX(),node:getPositionY()))
  
      local tag =  node:getTag()
      local zorder = node:getZorder()
      node:retain()
      node:removeFromParent()
  
      local lastSymbolNode = self:getLastSymbolNode()
  
      node:setPosition(cc.p(0, 0))
  
      self.m_clipNode:addChild(node, zorder, tag)
      node:release()   
      node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)

      if self.m_isAnit then
            node:setRotation(180)
      end
      
      self:pushToSymbolList(node)
end

--[[
    @desc: --初始化时盘面信号  
    author:{author}
    time:2018-11-28 14:34:29
    @return:
]]
function MonsterPartyWheelRunNode:initFirstSymbolBySymbols(initDataList)
      for i=1, #initDataList do
            local data = initDataList[i]
      
            local node = self.getSlotNodeBySymbolType(data.SymbolType)
            node.Height = data.Height
            
            self.m_clipNode:addChild(node, data.Zorder) 
            self:setRunCreateNodePos(node)
            self:pushToSymbolList(node)

            if self.m_isAnit then
                  node:setRotation(180)
            end

      end
  end

return MonsterPartyWheelRunNode