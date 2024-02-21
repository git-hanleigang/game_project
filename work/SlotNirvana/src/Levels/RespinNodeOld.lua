-----
---
---
-----
local RespinNodeOld = class("RespinNodeOld",util_require("Levels.BaseRespin"))

local NODE_TAG = 10

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20

RespinNodeOld.m_clipNode = nil
RespinNodeOld.m_DownCallback = nil
RespinNodeOld.m_DownBeforeResCallback = nil

RespinNodeOld.m_moveSpeed = nil
RespinNodeOld.m_resDis = nil

RespinNodeOld.p_rowIndex = nil
RespinNodeOld.p_colIndex = nil

RespinNodeOld.m_isGetNetData = nil
RespinNodeOld.m_runNodeNum = nil
RespinNodeOld.m_lastNode = nil
RespinNodeOld.m_runLastNodeType = nil

RespinNodeOld.m_RespinNodeStatus = nil
RespinNodeOld.m_runningDataIndex = nil
RespinNodeOld.m_runningData = nil

function RespinNodeOld:initUI()
      self.m_RespinNodeStatus = RESPIN_NODE_STATUS.IDLE
      self.m_runningDataIndex = nil
      self.m_moveSpeed = MOVE_SPEED
      self.m_resDis = RES_DIS
end

function RespinNodeOld:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalFreeSpinRespinCloumnByColumnIndex(self.p_rowIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

function RespinNodeOld:initConfigData()
    self:initRunningData()
end

function RespinNodeOld:initClipNode()
    local nodeHeight = self.m_slotReelHeight / self.m_machineRow
    self.m_clipNode= cc.ClippingRectangleNode:create({x= -math.ceil( self.m_slotNodeWidth / 2 ) , y= - nodeHeight / 2, width = self.m_slotNodeWidth, height = nodeHeight + 1 })
    self:addChild(self.m_clipNode)
    
    local colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 130))
    colorLayer:setPosition(-self.m_slotNodeWidth , -self.m_slotNodeHeight )
    self.m_clipNode:addChild(colorLayer, SHOW_ZORDER.SHADE_LAYER_ORDER)
end

function RespinNodeOld:setRespinNodeStatus(status)
    self.m_RespinNodeStatus = status
end

function RespinNodeOld:getRespinNodeStatus()
    return self.m_RespinNodeStatus
end

--放入首节点
function RespinNodeOld:setFirstSlotNode(node)
      local wordPos = node:getParent():convertToWorldSpace(cc.p(node:getPositionX(),node:getPositionY()))

      node:retain()
      node:removeFromParent(false)
      node:setPosition(cc.p(0, 0))
      node:setTag(NODE_TAG) 
      self.m_clipNode:addChild(node)
      node:release()   
      self.m_lastNode = node

      node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
end

--获取当前格子中所有小块 以及 固定的小块
function RespinNodeOld:getSlotNode()
      local allNode = {}
      local childs = self.m_clipNode:getChildren()
      local lastNode = nil
      for index=1, #childs do
          if childs[index]:getTag() == NODE_TAG then
  
              if lastNode == nil then
                  lastNode = childs[index]
              else 
                  if lastNode:getPositionY() < childs[index]:getPositionY() then
                      lastNode = childs[index]
                  end
              end
  
              allNode[#allNode + 1] = childs[index]
          end
      end
      return allNode ,lastNode
end

function RespinNodeOld:randomRuningSymbolType()
      local nodeType = nil
      
      if  xcyy.SlotsUtil:getArc4Random() % 30 == 1 and self.m_runNodeNum ~= 0 then
          nodeType = self:getRandomEndType()
          if nodeType == nil then
            nodeType = self:randomSymbolRandomType()
          end
      else 
          nodeType = self:randomSymbolRandomType()
      end
      return nodeType
end

--根据配置随机
function RespinNodeOld:getRunningSymbolTypeByConfig()
    local type = self.m_runningData[self.m_runningDataIndex]
    if self.m_runningDataIndex >= #self.m_runningData then
        self.m_runningDataIndex = 1
    else
        self.m_runningDataIndex = self.m_runningDataIndex + 1
    end
    return type
end

--创建下个小块
function RespinNodeOld:createNextNode(createNum, moveDis)
      if createNum == 0 then
          return nil
      end
  
      if self.m_isGetNetData == true then
          self.m_runNodeNum = self.m_runNodeNum - 1
      end
  
      --创建下一个
      local nodeType = nil
  
      if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
          nodeType = self.m_runLastNodeType
      else 

         if self.m_runningData == nil then
            nodeType = self:randomRuningSymbolType()
         else
            nodeType = self:getRunningSymbolTypeByConfig()
         end

      end
  
      local node = self.getSlotNodeBySymbolType(nodeType)
      
      if self.m_runNodeNum == 0 then
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, true)
            self.m_lastNode = node
     else
        node = self.getSlotNodeBySymbolType(nodeType)
      end
      
      node.p_symbolType = nodeType
      
      if self:getTypeIsEndType(node.p_symbolType ) == false then
          node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
      else
          node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
      end
      self:playCreateSlotsNodeAnima(node)
      node:setTag(NODE_TAG) 
  
      local posY = self.m_slotNodeHeight - moveDis % self.m_slotNodeHeight
      
      node:setPosition(cc.p(0, posY))
      self.m_clipNode:addChild(node)
      return node
end 

--创建slotsnode 播放动画
function RespinNodeOld:playCreateSlotsNodeAnima(node)
end

function RespinNodeOld:getMoveDis(dt)
    return  -dt * self.m_moveSpeed
end

function RespinNodeOld:startMove()
      self.m_isGetNetData = false
      self.m_runNodeNum = 1
      self.m_lastNode = nil
      local moveDis = self.m_slotNodeHeight
      local allCreateNum = self.m_runNodeNum
      self:setRespinNodeStatus(RESPIN_NODE_STATUS.RUNNING)

      self:onUpdate(function(dt)
                    
            if globalData.slotRunData.gameRunPause then
                return
            end
       
          if self:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.RUNNING then
              self:unscheduleUpdate()
              self:runResAction()
              return
          end

          local lastMoveDis = moveDis
          local delayMoveDis = self:getMoveDis(dt)
          
          if self.m_lastNode and self.m_lastNode:getPositionY() + delayMoveDis < 0 then
              delayMoveDis = -self.m_lastNode:getPositionY() 
          end
          
          moveDis = moveDis - delayMoveDis
  
          local allNode, lastNode = self:getSlotNode()
          
          local addPosY = delayMoveDis
         
          local createNum = math.ceil(moveDis / self.m_slotNodeHeight) - math.ceil(lastMoveDis / self.m_slotNodeHeight)
          -- printInfo("xcyy :startMove  %d %f  %f",createNum, addPosY, delayTime) 
          if createNum >= 2 then
              moveDis = moveDis - self.m_slotNodeHeight * (createNum - 1)
              addPosY = addPosY + self.m_slotNodeHeight * (createNum - 1)
              createNum = 1
          end
          createNum = self:changeCreateNodeNum(createNum)

          self:createNextNode(createNum, moveDis)
         
            for index=1, #allNode do
                local symbolNode = allNode[index]
                self:removeBelowBoundryNode(symbolNode)

                local posY =  allNode[index]:getPositionY() + addPosY
                allNode[index]:setPosition(cc.p(0, posY))
            end
  
          --判断是否是最后一个
          if self.m_lastNode ~= nil and self.m_runNodeNum <= 0  and self.m_lastNode:getPositionY() <= 0  then

             if self:getTypeIsEndType(self.m_lastNode.p_symbolType) == false then
                self:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
             else 
                self:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
             end
          end
      end)
end

function RespinNodeOld:removeBelowBoundryNode(node)
    if node:getPositionY()  <= -self.m_slotNodeHeight then
        --                printInfo("xcyy : %d",allNode[index].p_symbolType)
        node:removeFromParent(false)
        self.pushSlotNodeToPoolBySymobolType(node)  
    end
end

function RespinNodeOld:changeCreateNodeNum(createNum)
    
    return createNum
end

function RespinNodeOld:getLastNode()
   return self.m_lastNode
end

function RespinNodeOld:quicklyStop()
      if self.m_runNodeNum >= 1 then
          self.m_runNodeNum = 1
      end
end

function RespinNodeOld:setRunSpeed(speed)
    self.m_moveSpeed = speed
end

function RespinNodeOld:getRunSpeed()
    return self.m_moveSpeed
end

--获取回弹action
function RespinNodeOld:getResAction()
      local timeDown = 0
      local speedActionTable = {}
      local dis =  self.m_resDis + self.m_lastNode:getPositionY()
      local speedStart = self.m_moveSpeed
      local preSpeed = speedStart/ 118
      for i= 1, 10 do
          speedStart = speedStart - preSpeed * (11 - i) * 2
          local moveDis = dis / 10
          local time = moveDis / speedStart
          timeDown = timeDown + time
          local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
          speedActionTable[#speedActionTable + 1] = moveBy
      end

      local moveBy = cc.MoveBy:create(0.1,cc.p(0, - self.m_resDis))
      speedActionTable[#speedActionTable + 1] = moveBy:reverse()
      timeDown = timeDown + 0.1
      
      return speedActionTable, timeDown
  end
  
  --回弹action
function RespinNodeOld:runResAction()
  
      local allNode, lastNode = self:getSlotNode()
      
      if  self.m_DownBeforeResCallback ~= nil then
        self.m_DownBeforeResCallback(self.m_lastNode)
      end

      local downDelayTime = 0
      for index = 1, #allNode do
          local node = allNode[index]
          local actionTable ,downTime = self:getResAction()
          node:runAction(cc.Sequence:create(actionTable))
          if downDelayTime <  downTime then
              downDelayTime = downTime
          end
      end 
  
      performWithDelay(self,function()

        local allNode, lastNode = self:getSlotNode()
        for index = 1, #allNode do
            local node = allNode[index]
            if node ~= self.m_lastNode then
                node:removeFromParent(false)
                self.pushSlotNodeToPoolBySymobolType(node)  
            end
        end 

        if  self.m_DownCallback ~= nil then
            self.m_DownCallback(self.m_lastNode, self.m_RespinNodeStatus)
        end
    end,downDelayTime)
  
  end

function RespinNodeOld:setReelDownCallBack(cb, cb1)
   self.m_DownCallback = cb
   self.m_DownBeforeResCallback = cb1
end

function RespinNodeOld:getNodeRunning()
    
   if self.m_RespinNodeStatus == RESPIN_NODE_STATUS.RUNNING then
      return true
   end
   return false
end

function RespinNodeOld:setRunInfo(runNodeLen, lastNodeType)
    self.m_isGetNetData = true
    self.m_runNodeNum = runNodeLen
    self.m_runLastNodeType = lastNodeType
end

function RespinNodeOld:onEnter()
    if gLobalViewManager:isViewPause() then
        return 
    end
end

function RespinNodeOld:onExit()
    if gLobalViewManager:isViewPause() then
        return 
    end
    local allNode, lastNode = self:getSlotNode()
    for index = 1, #allNode do
        local node = allNode[index]
        node:removeFromParent(false)
        self.pushSlotNodeToPoolBySymobolType(node)
    end
end



return RespinNodeOld