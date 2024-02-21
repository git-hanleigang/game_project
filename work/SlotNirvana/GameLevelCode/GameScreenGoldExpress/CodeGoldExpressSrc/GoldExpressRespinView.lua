

local GoldExpressRespinView = class("GoldExpressRespinView", 
                                    util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 10,
}
GoldExpressRespinView.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
GoldExpressRespinView.m_bHaveNewFixNode = false
GoldExpressRespinView.m_vecExpressSound = {false, false, false, false, false}

function GoldExpressRespinView:setOneReelDownCallback(func)
      self.m_oneReelDownCallback = func
end

function GoldExpressRespinView:setReconnect(isReconnect)
      self.m_bIsReconnect = isReconnect
end

function GoldExpressRespinView:readyMove()
      performWithDelay(self, function()
            local delayTime = 4
            if self.m_bIsReconnect == true then
                  delayTime = 0.8
                  self.m_bIsReconnect = false
            else
                  performWithDelay(self,function()
                        local fixNode =  self:getFixSlotsNode()
                        for k = 1, #fixNode do        
                              local childNode = fixNode[k]
                              childNode:runAnim("actionframe",false, function()
                                    childNode:runAnim("idle",true)  
                              end)  
                        end 
                  end, 0)
            end
            
      
            performWithDelay(self,function()
                  self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                  if self.m_startCallFunc then
                        self.m_startCallFunc()
                  end
      
            end, delayTime)
      end, 0.5)
      
end

function GoldExpressRespinView:runNodeEnd(endNode)

      if endNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
          if self.m_vecExpressSound[endNode.p_cloumnIndex] == false then
              gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_bonus_down_"..endNode.p_cloumnIndex..".mp3")
              self.m_vecExpressSound[endNode.p_cloumnIndex] = true
          end
          
           endNode:runAnim("buling2",false, function()
                  endNode:runAnim("idle",true)  
            end)
            if self.m_oneReelDownCallback ~= nil then
                  performWithDelay(self, function()
                        self.m_oneReelDownCallback()
                  end, 1/3)
            end 
      end
      
end

function GoldExpressRespinView:oneReelDown(iCol)
      --gLobalSoundManager:playSound("GoldExpressSounds/music_GoldExpress_reel_stop.mp3")
      self.m_vecExpressSound = {false, false, false, false, false}
end

---获取所有参与结算节点
function GoldExpressRespinView:getAllCleaningNode()
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

function GoldExpressRespinView:createRespinNode(symbolNode, status)

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
  
      self:addChild(respinNode, VIEW_ZORDER.REPSINNODE - symbolNode.p_rowIndex)
      
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
      respinNode:setLocalZOrder(VIEW_ZORDER.REPSINNODE - symbolNode.p_rowIndex)
  
  end

return GoldExpressRespinView