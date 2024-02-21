

local WingsOfPhoelinxRespinView = class("WingsOfPhoelinxRespinView", 
                                    util_require("Levels.RespinView"))

                                    -- 特殊bonus
      WingsOfPhoelinxRespinView.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1   --带钱bonus
      WingsOfPhoelinxRespinView.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2   --winBonus
      WingsOfPhoelinxRespinView.SYMBOL_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3   --X3Bonus
      WingsOfPhoelinxRespinView.SYMBOL_BONUS4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4   --X5Bonus


local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

WingsOfPhoelinxRespinView.otherNodeList = {}
WingsOfPhoelinxRespinView.ActNodeList = {}

function WingsOfPhoelinxRespinView:initUI(respinNodeName)
      WingsOfPhoelinxRespinView.super.initUI(self,respinNodeName)
      self.otherNodeList = {}
      self.ActNodeList = {}
end
-- 
-- 是不是 respinBonus小块
function WingsOfPhoelinxRespinView:isSpecialFixSymbol(symbolType)
      if symbolType == self.SYMBOL_BONUS1 or 
          symbolType == self.SYMBOL_BONUS2 or 
          symbolType == self.SYMBOL_BONUS4 or 
          symbolType == self.SYMBOL_BONUS3 then
          return true
      end
      return false
end

function WingsOfPhoelinxRespinView:runNodeEnd(endNode)
      
      if self:isSpecialFixSymbol(endNode.p_symbolType) then
            if endNode.p_symbolType == self.SYMBOL_BONUS3 or endNode.p_symbolType == self.SYMBOL_BONUS4 or endNode.p_symbolType == self.SYMBOL_BONUS2 then
                  table.insert( self.otherNodeList,endNode )
            end
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_bonus_down.mp3")
            if endNode.p_symbolType == self.SYMBOL_BONUS1 then
                  endNode:runAnim("buling",false,function(  )
                        if endNode.m_huanRao then
                              endNode.m_huanRao:removeFromParent()
                              endNode.m_huanRao = nil
                        end
                        endNode.m_huanRao = util_createAnimation("Socre_WingsOfPhoelinx_bonus_0_huanrao.csb")
                        endNode:getCcbProperty("huanrao"):addChild(endNode.m_huanRao)
                        local curFixNode = self:getActNode()    --获取到当前固定小块
                        if curFixNode then
                              local curFixNode2 = curFixNode.m_csbAct
                              local curFixNode3 = endNode.m_huanRao.m_csbAct
                              if curFixNode2 and curFixNode then
      
                                    local curFrame = curFixNode2:getCurrentFrame()         --获取固定小块的当前帧数
                                    local info = curFixNode3:getAnimationInfo("idle")   --获取到end小块的时间线信息
                                    local startIndex = 0
                                    local endIndex = 60
                                    curFixNode3:gotoFrameAndPlay(startIndex,endIndex,curFrame,true)
                              else
                                    endNode:runAnim("idleframe2",true)
                                    endNode.m_huanRao:runCsbAction("idle",true)
                              end 
                        end
                        
                  end)
            else
                  endNode:runAnim("buling")
            end
            
      end
end

function WingsOfPhoelinxRespinView:oneReelDown()
      gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_reelstop.mp3")
end

function WingsOfPhoelinxRespinView:checkIsEffectNode(iX, iY)
      for i=1,#self.m_machineElementData do
            local data = self.m_machineElementData[i]
            if data.ArrayPos.iX == iX and data.ArrayPos.iY == iY and data.bCleaning then
                  local respinNode = self:getRespinNode(iX, iY)
                  if respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.IDLE then
                        return true
                  end
            end
      end
      return false
end

--由于目前只会出现一个特殊小块，所以这么写，后续可以出现多个可以直接将self.otherNodeList返回
function WingsOfPhoelinxRespinView:getWildRespinNode( )
      local wildNode = nil

      for i=1,#self.otherNodeList do
            local node = self.otherNodeList[i]
            if node.p_symbolType == self.SYMBOL_BONUS3 then
                  wildNode =  node
            elseif node.p_symbolType == self.SYMBOL_BONUS4 then
                  wildNode =  node
            elseif node.p_symbolType == self.SYMBOL_BONUS2 then
                  wildNode =  node
            end
      end
      
      return wildNode
end

function WingsOfPhoelinxRespinView:restOtherList( )
      self.otherNodeList = {}
end

function WingsOfPhoelinxRespinView:createRespinNode(symbolNode, status)

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
      if symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
            if symbolNode.m_huanRao then
                  symbolNode.m_huanRao:removeFromParent()
                  symbolNode.m_huanRao = nil
            end
            symbolNode:runAnim("idleframe2", true)
            symbolNode.m_huanRao = util_createAnimation("Socre_WingsOfPhoelinx_bonus_0_huanrao.csb")
            symbolNode.m_huanRao:runCsbAction("idle",true)
            symbolNode:getCcbProperty("huanrao"):addChild(symbolNode.m_huanRao)
            if #self.ActNodeList == 0 then
                  table.insert( self.ActNodeList,symbolNode)
            end
            
      end
  
  end

function WingsOfPhoelinxRespinView:getActNode( )
      local symbol = self.ActNodeList[1]
      local huan = symbol.m_huanRao
      return huan
end

function WingsOfPhoelinxRespinView:resetActNodeList( )
      table.remove( self.ActNodeList, 1)
      self.ActNodeList = {}
end

function WingsOfPhoelinxRespinView:resetActNode( )
      local tempList = self:getAllCleaningNode()
      for i,v in ipairs(tempList) do
            if v.m_huanRao then
                  v.m_huanRao:removeFromParent()
                  v.m_huanRao = nil
            end
      end
end
---获取所有参与结算节点
function WingsOfPhoelinxRespinView:getAllCleaningNode()
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

return WingsOfPhoelinxRespinView