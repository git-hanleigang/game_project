

local CharmsBoomRespinView = class("CharmsBoomRespinView", 
                                    util_require("Levels.RespinView"))

local VIEW_ZORDER = {
      NORMAL = 100,
      REPSINNODE = 1,
}

local BASE_COL_INTERVAL = 3

CharmsBoomRespinView.m_boomNodeEndList = {}

CharmsBoomRespinView.m_boomNodeBulingList = {}

function CharmsBoomRespinView:initUI(respinNodeName)
      self.m_respinNodeName = respinNodeName 
      self.m_baseRunNum = 5
end
function CharmsBoomRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0
      
      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end

function CharmsBoomRespinView:initMachine(machine)
      self.m_machine = machine

end

function CharmsBoomRespinView:runNodeEnd(endNode)
   

      if endNode.p_symbolType and math.abs( endNode.p_symbolType ) == self.m_machine.SYMBOL_FIX_SYMBOL_BOOM then
            
            
            gLobalSoundManager:playSound("CharmsSounds/music_Charms_Respin_Boom_Down.mp3")
            
            table.insert( self.m_boomNodeEndList, endNode)

            local index = self.m_machine:getPosReelIdx(endNode.p_rowIndex ,endNode.p_cloumnIndex)
            local pos =  self.m_machine:getTarSpPos(index )
            local Boom = util_spineCreate("Socre_Charms_Boom1", true, true) -- util_createAnimation("Socre_Charms_Boom1.csb") -- 
            self.m_machine:findChild("Node_2"):addChild(Boom,999999999)
            Boom:setPosition(cc.p(pos))
            util_spinePlay(Boom,"buling",false)
            util_spineEndCallFunc(Boom, "buling", function(  )
                  -- Boom:setVisible(false) 
            end)


            -- Boom:playAction("buling",false,function(  )
            --       Boom:setVisible(false) 
            -- end,30)
            table.insert( self.m_boomNodeBulingList, Boom)
            

            --endNode:runAnim("buling", false,function(  )
                  -- endNode:setVisible(false)
            --end)
            
      end
      

end

function CharmsBoomRespinView:oneReelDown()
      gLobalSoundManager:playSound("CharmsSounds/Charms_Reel_Stop.mp3")
end

---获取所有参与结算节点
function CharmsBoomRespinView:getAllCleaningNode()
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
function CharmsBoomRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

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
                  if nodeInfo.isVisible then
                        print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
                  end

                  local status = nodeInfo.status
                  self:createRespinNode(machineNode, status)
            -- end
            
      end

      self:readyMove()
end


function CharmsBoomRespinView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)
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
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
  
end

function CharmsBoomRespinView:setRunEndInfo(storedNodeInfo, unStoredReels,BoomStoredReels)
      for j=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[j]
            local bFix = false 
            local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
            
            repsinNode:setRunInfo(runLong, self.m_machine.SYMBOL_FIX_SYMBOL_NULL)
            
            -- 赋值炸弹的信号
            for i=1,#BoomStoredReels do
                  local data = BoomStoredReels[i]
                  if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                        repsinNode:setRunInfo(runLong, self.m_machine.SYMBOL_FIX_SYMBOL_BOOM)
                  end
            end
      end
end

--repsinNode滚动完毕后 置换层级
function CharmsBoomRespinView:respinNodeEndCallBack(endNode, status)
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

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
            self.m_machine:reSpinReelDown()
      end

end

function CharmsBoomRespinView:hideAllCurrNode( )
      
      if self.m_boomNodeEndList then
            if #self.m_boomNodeEndList > 0 then
                  for k,v in pairs(self.m_boomNodeEndList) do
                        v:setVisible(false)
                  end
            end

            self.m_boomNodeEndList = {}
      end
      
      if self.m_boomNodeBulingList and #self.m_boomNodeBulingList > 0 then
            for k,v in pairs(self.m_boomNodeBulingList) do
                  v:removeFromParent()
            end

            self.m_boomNodeBulingList = {}

      end
end

return CharmsBoomRespinView