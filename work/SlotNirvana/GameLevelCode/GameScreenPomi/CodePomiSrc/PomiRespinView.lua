

local PomiRespinView = class("PomiRespinView", 
                                    util_require("Levels.RespinView"))

PomiRespinView.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
PomiRespinView.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
PomiRespinView.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
PomiRespinView.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
PomiRespinView.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function PomiRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

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
            self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
            machineNode:setVisible(nodeInfo.isVisible)
            if nodeInfo.isVisible then
                  print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end

            if nodeInfo and nodeInfo.Type then
                  if self:isFixSymbol(nodeInfo.Type) then
                        machineNode:runAnim("idle", true) 
                  end
            end

            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end


      self:updateShowSlotsRespinNode( false)

      self:readyMove()
end
function PomiRespinView:checkNodeIsShow(rowCount )
      local visible =  true
      local rsExtraData =  self.m_machine.m_runSpinResultData.p_rsExtraData
      if rsExtraData then
            local minRow = rsExtraData.rows
            if minRow then
                  if rowCount > minRow then
                        visible =  false
                  end
            end
      end

      return visible
end

function PomiRespinView:updateShowSlotsRespinNodeForRow(iRow)
      for k,v in pairs(self.m_respinNodes) do
            local node = v
            if node and node.p_rowIndex and node.p_rowIndex <= iRow then
                  if not node:isVisible() then
                        node:setVisible(true)
                        node.m_clipNode:setVisible(true)
                        util_setCascadeOpacityEnabledRescursion(node,true)
                        node:setOpacity(0)
                        util_playFadeInAction(node,0.3)    
                  end
                  
            end
      
      end
end

-- 是不是 respinBonus小块
function PomiRespinView:isFixSymbol(symbolType)
      if self.m_machine then
            if symbolType == self.m_machine.SYMBOL_FIX_SYMBOL or 
                  symbolType == self.m_machine.SYMBOL_FIX_MINI or 
                  symbolType == self.m_machine.SYMBOL_FIX_MINOR or 
                  symbolType == self.m_machine.SYMBOL_FIX_MAJOR or 
                  symbolType == self.m_machine.SYMBOL_FIX_GRAND or
                  symbolType == self.m_machine.SYMBOL_FIX_Reel_Up or
                  symbolType == self.m_machine.SYMBOL_FIX_Double_bet  then
                  return true
            end 
      end
      
      return false
end

-- 是不是 respinBonus小块
function PomiRespinView:isSpecialFixSymbol(symbolType)
      if self.m_machine then
            if symbolType == self.m_machine.SYMBOL_FIX_Reel_Up or
                  symbolType == self.m_machine.SYMBOL_FIX_Double_bet  then
                  return true
            end 
      end
      
      return false
end

function PomiRespinView:updateShowSlotsRespinNode( notInit)
    if self.m_machine == nil then
        return 
    end  

    for k,v in pairs(self.m_respinNodes) do
      local node = v
      if node and node.p_rowIndex then
            node:setVisible(self:checkNodeIsShow(node.p_rowIndex ))
            node.m_clipNode:setVisible(self:checkNodeIsShow(node.p_rowIndex ))
      end
      
    end

    if notInit then
      self.m_machine:chnangeRespinBg( )
    end

    
      
end

function PomiRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0
      
      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end

function PomiRespinView:runNodeEnd(endNode)
      
      if endNode and endNode.p_symbolType then
            if self:isFixSymbol(endNode.p_symbolType) then
                  endNode:runAnim("buling", false,function(  )
                       if not self:isSpecialFixSymbol(endNode.p_symbolType) then
                              endNode:runAnim("idle", true)     
                       end 
                        
                  end) 

                  if self.m_machine and (endNode.p_symbolType == self.m_machine.SYMBOL_FIX_Reel_Up or endNode.p_symbolType == self.m_machine.SYMBOL_FIX_Double_bet) then
                        gLobalSoundManager:playSound("PomiSounds/music_Pomi_Bonus_down_Special.mp3") 
                  else
                        gLobalSoundManager:playSound("PomiSounds/music_Pomi_Bonus_down_base.mp3") 
                  end
                  
            end
            
      end
      

            

end


function PomiRespinView:oneReelDown()
      gLobalSoundManager:playSound("PomiSounds/music_Pomi_Reel_Stop.mp3") 
end

---获取所有参与结算节点
function PomiRespinView:getAllCleaningNode()
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

function PomiRespinView:initMachine( machine)
      self.m_machine = machine

      
      
end
function PomiRespinView:changeNodeRunningData()
      for i=1,#self.m_respinNodes do
            self.m_respinNodes[i]:changeRunningData()
      end  
end

return PomiRespinView