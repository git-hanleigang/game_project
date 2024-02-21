

local PomiRespinView = class("PomiRespinView",util_require("Levels.RespinView"))


PomiRespinView.SYMBOL_Pomi_Bonus = 494
PomiRespinView.SYMBOL_Pomi_GRAND = 4104
PomiRespinView.SYMBOL_Pomi_MAJOR = 4103
PomiRespinView.SYMBOL_Pomi_MINOR = 4102
PomiRespinView.SYMBOL_Pomi_MINI = 4101
PomiRespinView.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
PomiRespinView.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

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
            if symbolType == self.SYMBOL_Pomi_Bonus or 
                  symbolType == self.SYMBOL_Pomi_MINI or 
                  symbolType == self.SYMBOL_Pomi_MINOR or 
                  symbolType == self.SYMBOL_Pomi_MAJOR or 
                  symbolType == self.SYMBOL_Pomi_GRAND or
                  symbolType == self.SYMBOL_Pomi_Reel_Up or
                  symbolType == self.SYMBOL_Pomi_Double_bet  then
                  return true
            end 
      end
      
      return false
end

-- 是不是 respinBonus小块
function PomiRespinView:isSpecialFixSymbol(symbolType)
      if self.m_machine then
            if symbolType == self.SYMBOL_Pomi_Reel_Up or
                  symbolType == self.SYMBOL_Pomi_Double_bet  then
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

                  if self.m_machine and (endNode.p_symbolType == self.SYMBOL_Pomi_Reel_Up or endNode.p_symbolType == self.SYMBOL_Pomi_Double_bet) then
                        gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_Bonus_down_Special.mp3") 
                  else
                        gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_Bonus_down_base.mp3") 
                  end
                  
            end
            
      end
      

            

end


function PomiRespinView:oneReelDown()
      gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Reel_Stop.mp3")
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

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

function PomiRespinView:createRespinNode(symbolNode, status)

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

return PomiRespinView