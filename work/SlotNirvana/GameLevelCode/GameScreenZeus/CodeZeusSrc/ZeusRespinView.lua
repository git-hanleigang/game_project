

local ZeusRespinView = class("ZeusRespinView", 
                                    util_require("Levels.RespinView"))

local VIEW_ZORDER = 
      {
            NORMAL = 100,
            REPSINNODE = 1,
      }

function ZeusRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0
      
      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end

function ZeusRespinView:runNodeEnd(endNode)

      if endNode  then

            if self.m_machine:isFixSymbol(endNode.p_symbolType) then
                  gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Bonus_Down.mp3") 
                  -- endNode:runAnim("buling",false,function(  )
                  endNode:runAnim("actionframe1",true)
                  -- end)
            end
            
      end

      
      
      

end

function ZeusRespinView:oneReelDown()

      local reelStopName = "ZeusSounds/music_Zeus_Reels_Stop_1.mp3"
      gLobalSoundManager:playSound(reelStopName)
end

---获取所有参与结算节点
function ZeusRespinView:getAllCleaningNode()
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


function ZeusRespinView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)
      respinNode:setMachine(self.m_machine)
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
      
      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
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


      if symbolNode.p_symbolType == self.m_machine.SYMBOL_ROCK_SYMBOL then
            local index = self.m_machine:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
            self.m_machine:changeRockSymbolImg( index,symbolNode )
      end

      if symbolNode.p_symbolType == self.m_machine.SYMBOL_MIDRUN_SYMBOL then
            
            -- if symbolNode.m_specialRunUI then
            --       symbolNode.m_specialRunUI.m_FeatureNode:beginMove()
            -- end

      end
      
  
end

--repsinNode滚动完毕后 置换层级
function ZeusRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
            if endNode.p_symbolType == self.m_machine.SYMBOL_MIDRUN_SYMBOL then
            
                  if endNode.m_specialRunUI then

                        endNode.m_specialRunUI:removeFeatureNode( )
                        endNode.m_specialRunUI:removeFromParent()
                        endNode.m_specialRunUI = nil
                  end

                  if endNode and endNode.getCcbProperty then
                        endNode.m_specialRunUI = util_createView("CodeZeusSrc.ZeusRespinRunView",self.m_machine)
                        endNode:getCcbProperty("Node_Coin_zi"):addChild(endNode.m_specialRunUI)
                  end

                  
            end

            if endNode.p_symbolType == self.m_machine.SYMBOL_ROCK_SYMBOL then
                  local index = self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
                  self.m_machine:changeRockSymbolImg( index,endNode )
            end

      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

return ZeusRespinView