

local FarmRespinView = class("FarmRespinView", 
                                    util_require("Levels.RespinView"))


FarmRespinView.SYMBOL_FIX_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE   
FarmRespinView.SYMBOL_FIX_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
FarmRespinView.SYMBOL_FIX_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 -- 金色瓜

FarmRespinView.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5
FarmRespinView.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4
FarmRespinView.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3

function FarmRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0
      
      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function FarmRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
      self.m_machineElementData = machineElement
      for i=1,#machineElement do
            local nodeInfo = machineElement[i]
            local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

            local pos = self:convertToNodeSpace(nodeInfo.Pos)
            machineNode:setPosition(pos)

            local posIndex = self.m_machine:getPosReelIdx(machineNode.p_rowIndex, machineNode.p_cloumnIndex)
            self:addChild(machineNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + posIndex, self.REPIN_NODE_TAG)

            machineNode:setVisible(nodeInfo.isVisible)
            if nodeInfo.isVisible then
                  print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end

            if machineNode.m_Corn then
                  machineNode.m_Corn:stopAllActions()
                  machineNode.m_Corn:removeFromParent()
                  machineNode.m_Corn = nil
            end 
            

            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end

      self:readyMove()
end

function FarmRespinView:runNodeEnd(endNode)


      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then

            if endNode.p_symbolType and endNode.p_symbolType == self.SYMBOL_FIX_BONUS_2 then
                  gLobalSoundManager:playSound("FarmSounds/music_Farm_GoldfixBonusDown.mp3")
            else
                  gLobalSoundManager:playSound("FarmSounds/music_Farm_fixBonusDown.mp3")
            end
            

            

            endNode:runAnim(info.runEndAnimaName, false,function(  )
                  endNode:runAnim("idleframe",true)
            end)
      end
      

end

function FarmRespinView:oneReelDown()
      gLobalSoundManager:playSound("FarmSounds/music_Farm_reelstop.mp3")
end

---获取所有参与结算节点
function FarmRespinView:getAllCleaningNode()
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


--repsinNode滚动完毕后 置换层级
function FarmRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            local posIndex = self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + posIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

return FarmRespinView