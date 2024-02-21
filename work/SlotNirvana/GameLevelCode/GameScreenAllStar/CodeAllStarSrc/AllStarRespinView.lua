

local AllStarRespinView = class("AllStarRespinView", 
                              util_require("Levels.RespinView"))


-- 这一关没有滚出的grand（全满算grand）
AllStarRespinView.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

AllStarRespinView.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
AllStarRespinView.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
AllStarRespinView.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

-- 特殊bonus
AllStarRespinView.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 
AllStarRespinView.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  
AllStarRespinView.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 
AllStarRespinView.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15 

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}


function AllStarRespinView:setOutLineBonus(states )
      self.m_isInBonus = states
end

-- 是不是 respinBonus小块
function AllStarRespinView:isSpecialFixSymbol(symbolType)
      if symbolType == self.SYMBOL_MID_LOCK or 
          symbolType == self.SYMBOL_ADD_WILD or 
          symbolType == self.SYMBOL_TWO_LOCK or 
          symbolType == self.SYMBOL_Double_BET then
          return true
      end
      return false
end

function AllStarRespinView:createRespinNode(symbolNode, status)

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
      respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
      else
              respinNode:setFirstSlotNode(symbolNode)
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

      if self:isSpecialFixSymbol(symbolNode.p_symbolType) then

            if self.m_isInBonus then

            else
                  symbolNode:runAnim("idle", true)
            end
            

            
      end

  
  end

function AllStarRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0
      
      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end



function AllStarRespinView:runNodeEnd(endNode)

      local info = self:getEndTypeInfo(endNode.p_symbolType)

      local node = endNode

      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            
            gLobalSoundManager:playSound("AllStarSounds/music_AllStar_FixNode_down.mp3") 

            endNode:runAnim(info.runEndAnimaName, false)
            self:delayCallBack(0.5,function (  )
                  if not node then
                        return
                  end
                  local symbolType = node.p_symbolType
                  if self:isSpecialFixSymbol(node.p_symbolType) then
                        
                        if self.m_isInBonus then
                  
                        else
                              node:runAnim("idle", true)
                        end
                  end
                  if symbolType == self.SYMBOL_FIX_MINI or 
                   symbolType == self.SYMBOL_FIX_MINOR or 
                   symbolType == self.SYMBOL_FIX_MAJOR  then
                      node:runAnim("idleframe", true)
                  end
            end)


            if node.m_labUI then
                  -- node.m_labUI:runCsbAction("buling")
            end
      end  

end

function AllStarRespinView:oneReelDown()
      gLobalSoundManager:playSound("AllStarSounds/music_AllStar_reelStop.mp3")
end

---获取所有参与结算节点
function AllStarRespinView:getAllCleaningNode()
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

--延迟回调
function AllStarRespinView:delayCallBack(time, func)
      local waitNode = cc.Node:create()
      self:addChild(waitNode)
      performWithDelay(
          waitNode,
          function()
              waitNode:removeFromParent(true)
              waitNode = nil
              if type(func) == "function" then
                  func()
              end
          end,
          time
      )
      return waitNode
  end

return AllStarRespinView