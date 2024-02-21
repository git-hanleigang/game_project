

local ChilliFiestaRespinView = class("ChilliFiestaRespinView",
                                    util_require("Levels.RespinView"))



ChilliFiestaRespinView.SYMBOL_ChilliFiesta_ALL = 1105


-- 0 初始化时候  1 正常时候
ChilliFiestaRespinView.m_animaState = 1

ChilliFiestaRespinView.m_storeIcons = nil
local ANIMA_TAG = 20000


function ChilliFiestaRespinView:setMachine( machine )
      self.m_machine = machine
  end

function ChilliFiestaRespinView:setStoreIcons(storeIcons)
      self.m_storeIcons = storeIcons
end

function ChilliFiestaRespinView:setAnimaState(state)
      self.m_animaState = state
      if self.m_respinNodes then
            for i=1,#self.m_respinNodes do
                  self.m_respinNodes[i]:setAnimaState(state)
            end
      end

end

--repsinNode滚动完毕后 置换层级
function ChilliFiestaRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)
      if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP,endNode)
      end
end


function ChilliFiestaRespinView:getStoreIconsScore(iX, iY)
      for i=1,#self.m_storeIcons do
           local data = self.m_storeIcons[i]
           if data.iX == iX and data.iY == iY then
                 return data.score
           end
      end
end



function ChilliFiestaRespinView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)

      respinNode:setAnimaState(self.m_animaState)
      respinNode:setMachine( self.m_machine )

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
      else
              respinNode:setFirstSlotNode(symbolNode)
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

  end
--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
-- function ChilliFiestaRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun,)

--       self.m_machineRow = machineRow
--       self.m_machineColmn = machineColmn
--       self.m_startCallFunc = startCallFun
--       self.m_respinNodes = {}
--       self:setMachineType(machineColmn, machineRow)
--       self.m_machineElementData = machineElement
--       for i=1,#machineElement do
--             local nodeInfo = machineElement[i]
--             local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

--             local pos = self:convertToNodeSpace(nodeInfo.Pos)
--             machineNode:setPosition(pos)
--             self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
--             machineNode:setVisible(nodeInfo.isVisible)
--             if nodeInfo.isVisible then
--                   print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
--             end

--             local status = nodeInfo.status
--             self:createRespinNode(machineNode, status)
--       end

--       self:readyMove()
-- end

function ChilliFiestaRespinView:readyMove()
      -- self:addAnimaNode( )


      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0

      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end

-- function ChilliFiestaRespinView:addAnimaNode(  )

--       local childs = self:getChildren()
--       self.m_animaNameNode = {}
--       for i=1,#childs do
--             local node = childs[i]
--             local tag =  node:getTag()
--             local visible = node:isVisible()
--             if tag == self.REPIN_NODE_TAG  and visible then

--                   if node.p_symbolType < 1000 then
--                         local score =  self:getStoreIconsScore(node.p_rowIndex, node.p_cloumnIndex)
--                         local type = nil
--                         local animaName = "buling2"
--                         if score == 50 then
--                               type = 108
--                         elseif score == 100 then
--                               type = 107
--                         elseif score == 1000 then
--                               type = 106
--                         else
--                               type = 101
--                         end

--                         local animaNode = self.getSlotNodeBySymbolType(type,node.p_rowIndex,node.p_cloumnIndex )
--                         animaNode:runAnim(animaName, true)
--                         animaNode:setPosition(cc.p(node:getPositionX(), node:getPositionY()))
--                         self:addChild(animaNode, REEL_SYMBOL_ORDER.REEL_ORDER_3, ANIMA_TAG)

--                         self.m_animaNameNode[#self.m_animaNameNode + 1] = animaNode

--                         if type == 101 then
--                               local lineBet =  globalData.slotRunData:getCurTotalBet()
--                               local scoreTmp = score * lineBet
--                               scoreTmp = util_formatCoins(scoreTmp, 3)
--                               animaNode:getCcbProperty("score_lab"):setString(scoreTmp)
--                         end
--                   else
--                         node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4)
--                         node:runAnim("action10_actionframe1")

--                                     performWithDelay(node,function( ... )
--                                           node:runAnim("action10_actionframe1", false,function(  )
--                                                 node:runAnim("action10")
--                                           end)
--                               end ,1)
--                   end
--             end
--       end
-- end
function ChilliFiestaRespinView:runNodeEnd(endNode)
      if endNode and endNode.p_symbolType and self.m_machine:isFixSymbol(endNode.p_symbolType) then
            if endNode.p_symbolType ~= self.SYMBOL_ChilliFiesta_ALL then
                   gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_baseBonusBuling.mp3")
            else
                   gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_GoldBonusBuling.mp3")
            end
            endNode:runAnim("buling",false,function(  )
                  endNode:runAnim("idleframe",true)
            end)
      end


end
function ChilliFiestaRespinView:oneReelDown()
      -- body
      gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Reel_Stop.mp3")

end


---获取所有参与结算节点
function ChilliFiestaRespinView:getAllCleaningNode()
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
return ChilliFiestaRespinView