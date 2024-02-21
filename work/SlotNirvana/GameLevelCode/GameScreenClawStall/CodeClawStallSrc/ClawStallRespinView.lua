
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallRespinView = class("ClawStallRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--组织滚动信息 开始滚动
function ClawStallRespinView:startMove()
      self.m_bonusDown = {}
      self.m_isReelDownSoundPlayed = false
      ClawStallRespinView.super.startMove(self)
end

--repsinNode滚动完毕后 置换层级
function ClawStallRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            local zOrder = self.m_machine:getBounsScatterDataZorder(endNode.p_symbolType)
            util_changeNodeParent(self,endNode,zOrder - endNode.p_rowIndex + endNode.p_cloumnIndex * 10)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

-- 
function ClawStallRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            if endNode and endNode.p_symbolType then
                  endNode:runAnim(info.runEndAnimaName, false,function()
                        endNode:runAnim("idleframe",true)
                  end)

                  if not self.m_bonusDown[endNode.p_cloumnIndex] then
                        self.m_bonusDown[endNode.p_cloumnIndex] = true
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_bonus_down)
                  end   
                  if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
                        for iCol = 1,self.m_machine.m_iReelColumnNum do
                              self.m_bonusDown[iCol] = true
                        end
                  end 
            end
      end
end

function ClawStallRespinView:oneReelDown()
      if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
            if not self.m_isReelDownSoundPlayed then
                  self.m_isReelDownSoundPlayed = true
                  gLobalSoundManager:playSound("ClawStallSounds/sound_ClawStall_reel_down_quick.mp3")
            end
      else
            gLobalSoundManager:playSound("ClawStallSounds/sound_ClawStall_reel_down.mp3")
      end
      
end

---获取所有参与结算节点
function ClawStallRespinView:getAllCleaningNode()
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
      -- local sortNode = {}
      -- for iCol = 1 , self.m_machineColmn do
            
      --       local sameRowNode = {}
      --       for i = 1, #cleaningNodes do
      --             local  node = cleaningNodes[i]
      --             if node.p_cloumnIndex == iCol then
      --                   sameRowNode[#sameRowNode + 1] = node
      --             end   
      --       end 
      --       table.sort( sameRowNode, function(a, b)
      --             return b.p_rowIndex  <  a.p_rowIndex
      --       end)

      --       for i=1,#sameRowNode do
      --             sortNode[#sortNode + 1] = sameRowNode[i]
      --       end
      -- end
      -- cleaningNodes = sortNode

      util_bubbleSort(cleaningNodes,function(a,b)
            if a.m_score  <  b.m_score then
                  return true
            elseif a.m_score == b.m_score and a.p_symbolType < b.p_symbolType then
                  return true
            elseif a.m_score == b.m_score and a.p_symbolType == b.p_symbolType and a.p_cloumnIndex < b.p_cloumnIndex then
                  return true
            elseif a.m_score == b.m_score and a.p_symbolType == b.p_symbolType and a.p_cloumnIndex == b.p_cloumnIndex and a.p_rowIndex  >  b.p_rowIndex then
                  return true
            end
            return false
      end)
      -- table.sort( cleaningNodes, function(a, b)
      --       return a.m_score  <  b.m_score
      -- end)
      return cleaningNodes
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function ClawStallRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
      self.m_machineElementData = machineElement
      for i=1,#machineElement do
            local nodeInfo = machineElement[i]
            local symbolType = nodeInfo.Type
            if not self.m_machine:isBonusType(symbolType) then
                  symbolType  = self.m_machine.SYMBOL_SCORE_EMPTY
            end
            local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)
            if self.m_machine:isBonusType(symbolType) then
                  machineNode:runAnim("idleframe",true)
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
end

function ClawStallRespinView:createRespinNode(symbolNode, status)
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
            respinNode.m_baseFirstNode = symbolNode
            self:changeRespinNodeLockStatus(respinNode,true)
      else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end


--[[
    获取respinNode索引
]]
function ClawStallRespinView:getRespinNodeIndex(col, row)
      return self.m_machine.m_iReelRowNum - row + 1 + (col - 1) * self.m_machine.m_iReelRowNum
end

--[[
      根据行列获取respinNode
]]
function ClawStallRespinView:getRespinNodeByRowAndCol(col,row)
      local respinNodeIndex = self:getRespinNodeIndex(col,row)
      local respinNode = self.m_respinNodes[respinNodeIndex]
      return respinNode
end

--[[
    改变小块的锁定状态
]]
function ClawStallRespinView:changeRespinNodeLockStatus(respinNode, isLock,isWinLine)
      if isLock then
            if not respinNode.isLocked then
                 --锁定小块不能滚动
                  respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
                  local zOrder = self.m_machine:getBounsScatterDataZorder(respinNode.m_baseFirstNode.p_symbolType) - respinNode.p_rowIndex + respinNode.p_colIndex * 10
                  
                  --变更小块父节点
                  local pos = util_convertToNodeSpace(respinNode.m_baseFirstNode,self)
                  util_changeNodeParent(self,respinNode.m_baseFirstNode,zOrder)
                  respinNode.m_baseFirstNode:setPosition(pos)
                  respinNode.isLocked = true 
            end
            
      else
            if respinNode.p_colIndex == 3 and respinNode.p_rowIndex == 3 then
                  return
            end
            --解除小块的锁定状态
            respinNode:setFirstSlotNode(respinNode.m_baseFirstNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
            respinNode.isLocked = false
      end
end

--[[
      添加分割线
]]
function ClawStallRespinView:addBorderLine( )
      local line = util_createAnimation("ClawStall_Respin_RespinJiange.csb")
      self:addChild(line,VIEW_ZORDER.REPSINNODE + 20)
      line:setPosition(util_convertToNodeSpace(self.m_machine:findChild("Node_RespinJiange"),self))
end

return ClawStallRespinView