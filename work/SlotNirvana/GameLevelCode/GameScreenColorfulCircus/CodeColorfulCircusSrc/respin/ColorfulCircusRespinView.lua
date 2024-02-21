

local ColorfulCircusRespinView = class("ColorfulCircusRespinView",
                                    util_require("Levels.RespinView"))

-- 0 初始化时候  1 正常时候
ColorfulCircusRespinView.m_animaState = 1

ColorfulCircusRespinView.m_storeIcons = nil

local ANIMA_TAG = 20000

ColorfulCircusRespinView.ActNodeList = {}

function ColorfulCircusRespinView:initUI(respinNodeName)
      ColorfulCircusRespinView.super.initUI(self,respinNodeName)

      self.m_bonusSoundArray = {false, false, false, false, false}
      self.m_bonusSoundQuickPlayed = false
      self.m_quickStopMark = false

      self:setBaseColInterVal(4)
end

function ColorfulCircusRespinView:setStoreIcons(storeIcons)
      self.m_storeIcons = storeIcons
end

function ColorfulCircusRespinView:setAnimaState(state)
      self.m_animaState = state
      if self.m_respinNodes then
            for i=1,#self.m_respinNodes do
                  self.m_respinNodes[i]:setAnimaState(state)
            end
      end

end


function ColorfulCircusRespinView:getStoreIconsScore(iX, iY)
      for i=1,#self.m_storeIcons do
           local data = self.m_storeIcons[i]
           if data.iX == iX and data.iY == iY then
                 return data.score
           end
      end
end

function ColorfulCircusRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
      
      ColorfulCircusRespinView.super.initRespinElement(self,machineElement, machineRow, machineColmn, startCallFun)
      self:changeClipRowNode(1,cc.p(0,3)) --修正位置
      self:changeClipRowNode(2,cc.p(0,1.5))

end

function ColorfulCircusRespinView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)
      respinNode:setMachine(self.m_machine)
      respinNode:setAnimaState(self.m_animaState)
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

      self:addChild(respinNode,1)

      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
      respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)

              --改
              symbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self.m_machine:getPosReelIdx(respinNode.p_rowIndex, respinNode.p_colIndex))
      else
              respinNode:setFirstSlotNode(symbolNode)
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
      if self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
            -- if symbolNode.p_symbolType == 107 then
                  -- symbolNode:runAnim("idleframe3", true)
            -- else
                  symbolNode:runAnim("idleframe2", true)
            -- end
      end
  end

function ColorfulCircusRespinView:readyMove()


      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end

function ColorfulCircusRespinView:runNodeEnd(endNode)
      if endNode then
            if self.m_machine:isFixSymbol(endNode.p_symbolType) then

                  self:playSound(endNode)
                  endNode:runAnim("buling",false,function(  )
                        endNode:runAnim("idleframe2",true)
                  end)
            end
      end
end
function ColorfulCircusRespinView:oneReelDown(colIndex)
      self.m_machine:playRespinReelStopSound(colIndex)
end


---获取所有参与结算节点
function ColorfulCircusRespinView:getAllCleaningNode()
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

--重写
--repsinNode滚动完毕后 置换层级
function ColorfulCircusRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)) --改
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end


      --判断是否是该列最后一个格子滚动结束
      -- local lastColNodeRow = endNode.p_rowIndex 
      -- for i=1,#self.m_respinNodes do
      --       local respinNode = self.m_respinNodes[i]
      --       if respinNode.p_colIndex == endNode.p_cloumnIndex and respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
      --             if respinNode.p_rowIndex < lastColNodeRow  then
      --                   lastColNodeRow = respinNode.p_rowIndex 
      --             end
      --       end
      -- end
      -- if endNode.p_rowIndex  == lastColNodeRow then
            -- self:playOneReelDownSound(endNode.p_cloumnIndex, endNode)
      -- end
end

--每列 res down 后播声音
-- function ColorfulCircusRespinView:playOneReelDownSound( col, endNode)
--       if not self.m_respinNodes then
--             return
--       end
--       self.m_machine
-- end

function ColorfulCircusRespinView:playSound(endNode)

      local col = endNode.p_cloumnIndex
      
      if col < 1 or col > 5 then
            return
      end

      self.m_machine:playRespinBulingSound(col, endNode)
      
end

return ColorfulCircusRespinView