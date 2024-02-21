

local PussRespinView = class("PussRespinView", 
                                    util_require("Levels.RespinView"))

PussRespinView.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

PussRespinView.m_respinNodeList =  {             4,
                                              8, 9,
                                          12,13,14,
                                       16,17,18,19,
                                    20,21,22,23,24,
                                    25,26,27,28,29,
                                    30,31,32,33,34}
PussRespinView.m_respinNodeNum = 7
PussRespinView.m_respinShowNodePos = {}

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

local nodeX  = 0

function PussRespinView:setRespinShowNodePosList( )
      local posPool = {}
      for i=1,#self.m_respinNodeList  do
            table.insert( posPool, self.m_respinNodeList[i] )
      end

      for i=1,(#self.m_respinNodeList - self.m_respinNodeNum) do
            table.remove( posPool, math.random( 1, #posPool) )  
      end

      self.m_respinShowNodePos = posPool
      
end


function PussRespinView:respinNodeIsShow( iRow,iCol )
      local index = self:getRespinPosReelIdx(iRow, iCol)

      for i=1,#self.m_respinShowNodePos do
            local pos = self.m_respinShowNodePos[i]
            if index == pos then
               return true   
            end
            
      end

      return false
end

function PussRespinView:getRespinPosReelIdx(iRow, iCol)
      local index = (7 - iRow) * 5 + (iCol - 1)
      return index
  end

function PussRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0

      for i=1,#fixNode do
            local node = fixNode[i]

            if node and node.p_rowIndex and node.p_cloumnIndex then
                  performWithDelay(self,function(  )
                        node:runAnim("idleframe1",true) 
                  end,0.3*i)
                        
            end
            
      end
      
      
      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end

--还原层级和坐标 暂不使用
function PussRespinView:resetPussLayersZorder()
      for i=1,5 do
            local name = "layerOut_"..i
            self[name]:setClippingEnabled(true)
            self[name]:setLocalZOrder(i)
      end
end


function PussRespinView:runNodeEnd(endNode)

      if endNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            local name = "layerOut_"..endNode.p_cloumnIndex
            self[name]:setClippingEnabled(false)
            self[name]:setLocalZOrder(6)
            gLobalSoundManager:playSound("PussSounds/music_Puss_Bonus_Down.mp3")
            
            endNode:runAnim("buling",false,function(  )
                  self[name]:setClippingEnabled(true)
                  if endNode and endNode.p_rowIndex and endNode.p_cloumnIndex then
                        self[name]:setLocalZOrder(endNode.p_cloumnIndex)
                        -- if self:respinNodeIsShow( endNode.p_rowIndex,endNode.p_cloumnIndex ) then
                              endNode:runAnim("idleframe1",true) 
                        -- end 
                  end
              end)
      end
      

end

function PussRespinView:oneReelDown(icol)
      gLobalSoundManager:playSound("PussSounds/Puss_Reels_Stop.mp3")

      if  icol == 5 then -- 最后一列滚动停止
            if self.m_machine then
                  self.m_machine:showJackPotTip( )
            end  
      end
      
       
      
end

--获取所有固定信号
function PussRespinView:getFixSlotsNode()
      local fixSlotNode = {}
      -- local childs = self:getChildren()

      local childs = {}
      for i=1,5 do
            local name = "layerOut_"..i
            local child = self[name]:getChildren() 
            for k,v in pairs(child) do
                  table.insert( childs, v)
            end
      end

      for i=1,#childs do
            local node = childs[i]
            if node:getTag() == self.REPIN_NODE_TAG  then
                  fixSlotNode[#fixSlotNode + 1] =  node
            end
      end
      return fixSlotNode
end

function PussRespinView:getRespinEndNode(iX, iY)
      -- local childs = self:getFixSlotsNode()

      local childs = {}
      for i=1,5 do
            local name = "layerOut_"..i
            local child = self[name]:getChildren() 
            for k,v in pairs(child) do
                  table.insert( childs, v)
            end
      end

      for i=1,#childs do
            local node = childs[i]

            if node.p_rowIndex == iX  and node.p_cloumnIndex == iY then
                  return node
            end
      end
      print("RESPINNODE NOT END!!!")
      return nil
end

--获取所有最终停止信号
function PussRespinView:getAllEndSlotsNode()
      local endSlotNode = {}
      -- local childs = self:getChildren()

      local childs = {}
      for i=1,5 do
            local name = "layerOut_"..i
            local child = self[name]:getChildren() 
            for k,v in pairs(child) do
                  table.insert( childs, v)
            end
      end

      for i=1,#childs do
            local node = childs[i]
            if node:getTag() == self.REPIN_NODE_TAG  then
                  endSlotNode[#endSlotNode + 1] =  node
            end
      end
      for i=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[i]
            if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  endSlotNode[#endSlotNode + 1] =  repsinNode:getLastNode()
            end
      end
      return endSlotNode
end

---获取所有参与结算节点
function PussRespinView:getAllCleaningNode()
      --从 从上到下 左到右排序
      local cleaningNodes = {}
      local childs = {}
      for i=1,5 do
            local name = "layerOut_"..i
            local child = self[name]:getChildren() 
            for k,v in pairs(child) do
                  table.insert( childs, v)
            end
      end
      

      for i=1,#childs do
            local node = childs[i]
            if node:getTag() == self.REPIN_NODE_TAG  and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
                  cleaningNodes[#cleaningNodes + 1] =  node
            end
      end


      --排序
      local sortNode = {}
      for iCol = 1 , self.m_machineColmn do
            
            local sameRowNode = {}
            for i = 1, #cleaningNodes do
                  local  node = cleaningNodes[i]
                  if node.p_cloumnIndex == iCol then
                        sameRowNode[#sameRowNode + 1] = node
                  end   
            end 
            table.sort( sameRowNode, function(a, b)
                  return b.p_rowIndex  <  a.p_rowIndex
            end)

            for i=1,#sameRowNode do
                  sortNode[#sortNode + 1] = sameRowNode[i]
            end
      end
      cleaningNodes = sortNode
      return cleaningNodes
end

function PussRespinView:initPanel( machine )

      for i=1,5 do
            local name = "layerOut_"..i
            self[name] = ccui.Layout:create()
            self:addChild(self[name],i)
            self[name]:setContentSize(270,machine.m_respinLayerMaxSize[i])
          
            self[name]:setAnchorPoint(0.5,0)
            self[name]:setClippingEnabled(true)
            local pos = cc.p(machine:findChild("sp_reel_" .. (i -1)):getPosition())  
            local worldPos = machine:findChild("sp_reel_" .. (i -1)):getParent():convertToWorldSpace(cc.p(pos))
            local posRespinView = cc.p(self:convertToNodeSpace(worldPos)) 
            self[name]:setPositionX(posRespinView.x)
      end
      
      
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function PussRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

      self:setRespinShowNodePosList( )

      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      -- self:initClipNodes(machineElement,RESPIN_CLIPTYPE.SINGLE)
      self.m_machineElementData = machineElement
      for i=1,#machineElement do
            local nodeInfo = machineElement[i]

            if nodeInfo.Type ~= -1 then
                  local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)
                  
                  local name = "layerOut_"..machineNode.p_cloumnIndex

                  local pos = self[name]:convertToNodeSpace(nodeInfo.Pos)
                  machineNode:setPosition(pos.x,pos.y)
                  self[name]:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
                  machineNode:setVisible(nodeInfo.isVisible)
                  if nodeInfo.isVisible then
                        print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
                  end

                  local status = nodeInfo.status
                  self:createRespinNode(machineNode, status)
            end
            
      end

      self:readyMove()
end

--repsinNode滚动完毕后 置换层级
function PussRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then

            local name = "layerOut_"..endNode.p_cloumnIndex

            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self[name]:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self[name],endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos.x,pos.y)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

function PussRespinView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)
      respinNode:setMachine(self.m_machine)
      respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
      respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
      respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
      respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)
      
      local name = "layerOut_"..symbolNode.p_cloumnIndex

      local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPositionX(), symbolNode:getPositionY()))
      local pos = self[name]:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
      respinNode:setPosition(cc.p(pos.x,pos.y))
      respinNode:setReelDownCallBack(function(symbolType, status)
        if self.respinNodeEndCallBack ~= nil then
              self:respinNodeEndCallBack(symbolType, status)
        end
      end, function(symbolType)
        if self.respinNodeEndBeforeResCallBack ~= nil then
              self:respinNodeEndBeforeResCallBack(symbolType)
        end
      end)
  
      self[name]:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
      
      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex))
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
      respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
      else
              respinNode:setFirstSlotNode(symbolNode)
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
  
  end

return PussRespinView