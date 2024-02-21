

local WestRangerRespinView = class("WestRangerRespinView", 
                                    util_require("Levels.RespinView"))


local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}
-- 

function WestRangerRespinView:initUI(respinNodeName)
      WestRangerRespinView.super.initUI(self,respinNodeName)
end

function WestRangerRespinView:runNodeEnd(endNode)

      if endNode then
            local info = self:getEndTypeInfo(endNode.p_symbolType)
            if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
                  self.m_machine.m_machine:setRespinNodeZOrder( self.m_machine.m_machineIndex, endNode, true)
                  endNode:runAnim(info.runEndAnimaName, false,function() 
                        self.m_machine.m_machine:setRespinNodeZOrder(self.m_machine.m_machineIndex, endNode, false)
                  end)
                  local endNodeData = {}
                  endNodeData.row = endNode.p_rowIndex
                  endNodeData.clo = endNode.p_cloumnIndex
                  table.insert(self.m_machine.cacheNodeMap, endNodeData) 
                  
                  if not self.m_machine.m_machine.m_isPlayRespinGoldSiverSound then
                        self.m_machine.m_machine.m_isPlayRespinGoldSiverSound = true
                        if endNode.p_symbolType == 94 then
                              gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_silverBonusReelDown.mp3")
                        elseif endNode.p_symbolType == 95 then
                              gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_goldBonusReelDown.mp3")
                        end
                  end
                  
            end
      end
      -- body
end

function WestRangerRespinView:oneReelDown()
      --gLobalSoundManager:playSound("WestRangerSounds/music_WestRanger_reel_stop.mp3")
end

---获取所有参与结算节点
function WestRangerRespinView:getAllCleaningNode()
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
function WestRangerRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            endNode:removeFromParent()
            self:addChild(endNode , REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex, self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)
      if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
            self.m_machine:reSpinReelDown()
      end
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function WestRangerRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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
            if machineNode.p_symbolType == self.m_machine.SYMBOL_BONUS1 or machineNode.p_symbolType == self.m_machine.SYMBOL_BONUS2 then
                  self.m_machine:setSpecialNodeScore(machineNode)
            end

            local pos = self:convertToNodeSpace(nodeInfo.Pos)
            machineNode:setPosition(pos)
            self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
            machineNode:setVisible(nodeInfo.isVisible)
            if nodeInfo.isVisible then
                  -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end

            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end

      self:readyMove()

      self:changeClipRowNode(1,cc.p(0,2)) --修正位置
      self:changeClipRowNode(2,cc.p(0,1))
end

function WestRangerRespinView:createRespinNode(symbolNode, status)

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
      if symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS1 or symbolNode.p_symbolType == self.m_machine.SYMBOL_BONUS2 then
            symbolNode:runAnim("idleframe", false)
            local symbol_node = symbolNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            if spineNode.m_csbNodeSaoGuang then
                  -- spineNode.m_csbNodeSaoGuang:runCsbAction("saoguang",true)
                  spineNode.m_csbNodeSaoGuang:setVisible(false)
                  spineNode.m_csbNodeSaoGuang:removeFromParent()
                  spineNode.m_csbNodeSaoGuang = nil
            end

      end
end

return WestRangerRespinView