

local CharmsRespinView = class("CharmsRespinView", 
                                    util_require("Levels.RespinView"))

local VIEW_ZORDER = {
      NORMAL = 100,
      REPSINNODE = 1,
}

function CharmsRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0

      performWithDelay(self,function()
            for k = 1, #fixNode do        
                  local childNode = fixNode[k]
                  childNode:runAnim("idleframe2",true)                  
            end 
        
        
              performWithDelay(self,function()
                    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                    if self.m_startCallFunc then
                          self.m_startCallFunc()
                    end
        
              end,0.1)
      end,0.1)

      

end

function CharmsRespinView:initMachine(machine)
      self.m_machine = machine

end

function CharmsRespinView:runNodeEnd(endNode)
   
      if endNode then
            local info = self.m_machine:isFixSymbol(endNode.p_symbolType)
            if self.m_machine:isFixSymbol(endNode.p_symbolType) then
                  endNode:runAnim("buling2", false,function(  )
                        endNode:runAnim("idleframe2", true)
                  end)
                  gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_Respin_Bonus_Down.mp3")
                  
            end   
      end
      

end

function CharmsRespinView:oneReelDown()
      gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Reel_Stop.mp3")
end

---获取所有参与结算节点
function CharmsRespinView:getAllCleaningNode()
      --从 从上到下 左到右排序
      local cleaningNodes = {}
      local childs = self:getChildren()

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

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function CharmsRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
      self.m_machineElementData = machineElement
      for i=1,#machineElement do

            local nodeInfo = machineElement[i]
            -- if nodeInfo.status ~= self.m_machine.CHARMS_RESPIN_NODE_STATUS.NUllLOCK then
                  local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

                  local pos = self:convertToNodeSpace(nodeInfo.Pos)
                  machineNode:setPosition(pos)
                  self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
                  machineNode:setVisible(nodeInfo.isVisible)
                  machineNode.Type = nodeInfo.Type
                  if nodeInfo.isVisible then
                        print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
                  end
                  
                  local status = nodeInfo.status
                  self:createRespinNode(machineNode, status)
            -- end
            
      end

      self:readyMove()
end


function CharmsRespinView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)
      respinNode:initMachine(self.m_machine)
      respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
      respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
      respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
      respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)
      
      respinNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
      respinNode:setReelDownCallBack(function(symbolType, status)
        if self.respinNodeEndCallBack ~= nil then
              self:respinNodeEndCallBack(symbolType, status)
        end
      end, function(symbolType)
        if self.respinNodeEndBeforeResCallBack ~= nil then
              self:respinNodeEndBeforeResCallBack(symbolType)
        end
      end)
  
      self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
      
      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex))
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
      respinNode.p_symbolType = symbolNode.p_symbolType
      respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
           
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
      else
              respinNode:setFirstSlotNode(symbolNode)
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end

      
      if self.m_machine:isFixSymbol(symbolNode.Type) then
            print("=============bofang")
                  symbolNode:runAnim("idleframe2", true)   
      end
      
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

--repsinNode滚动完毕后 置换层级
function CharmsRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      -- if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
      --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      -- end
end


return CharmsRespinView