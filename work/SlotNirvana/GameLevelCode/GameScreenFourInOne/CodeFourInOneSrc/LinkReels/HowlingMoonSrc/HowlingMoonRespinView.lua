

local HowlingMoonView = class("HowlingMoonView", 
                                    util_require("Levels.RespinView"))
HowlingMoonView.m_updateFeatureNodeFun = nil          
local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}                          



--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function HowlingMoonView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE,{
            clipOffsetSize = cc.size(0,-4),
            clipOffsetPos = cc.p(0,3)
      })
      -- self:changeClipBaseNode(cc.p(0,-3)) --修正位置
      -- self:changeClipRowNode(7,cc.p(0,-1)) --修正位置
      -- self:changeClipRowNode(8,cc.p(0,-1)) --修正位置
      self.m_machineElementData = machineElement
      for i=1,#machineElement do
            local nodeInfo = machineElement[i]
            if nodeInfo.Type then
                  if nodeInfo.Type == 94 then
                       print("...")
                  end
                  local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type,nodeInfo.ArrayPos.iX,  nodeInfo.ArrayPos.iY,  true)

                  local pos = self:convertToNodeSpace(nodeInfo.Pos)
                  machineNode:setPosition(pos)
                  self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
                  machineNode:setVisible(nodeInfo.isVisible)
                  
                  if nodeInfo.isVisible then
                        print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
                  end
                  local status = nodeInfo.status
                  self:createRespinNode(machineNode, status)
            end
            
      end

      self:readyMove()
end
      
function HowlingMoonView:setUpdateCallFun(updateCallFun)
      self.m_updateFeatureNodeFun = updateCallFun
end

function HowlingMoonView:readyMove()

      
      
      performWithDelay(self,function()
            local fixNode =  self:getFixSlotsNode()
            for k = 1, #fixNode do        
                  local childNode = fixNode[k]:getLastNode()
                  childNode:runAnim("actionframe",true)  
            end 
      end, 0.5)


      performWithDelay(self,function()
            self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_startCallFunc then
                  self.m_startCallFunc()
            end

      end, 1.5)
end

function HowlingMoonView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil  then      
              
            endNode:runAnim("buling",false,function(  )
                  endNode:runAnim("actionframe",true)

                  if self.m_updateFeatureNodeFun ~= nil then
                        self.m_updateFeatureNodeFun()
                  end
            end)   

            self:createOneActionSymbol(endNode,"buling")
            
      end    
end

function HowlingMoonView:createRsOverOneActionSymbol(endNode,actionName,actParent )

      if not endNode or not endNode.m_lastNode or not endNode.m_lastNode.m_ccbName  then
            return
      end
      
      local ccbName = endNode.m_lastNode.m_ccbName

      local fatherNode = endNode

      local unlockedLines = self.m_machine.m_runSpinResultData.p_rsExtraData.unlockedLines -- 服务器已经解锁的个数
      if endNode.p_rowIndex <= unlockedLines then
            endNode:setVisible(true)
            
            local node= util_createAnimation(ccbName..".csb")
            local func = function(  )
                  if fatherNode then
                        fatherNode:setVisible(true)
                  end
                  if node then
                        node:removeFromParent()
                  end
                  
            end
            node:playAction(actionName,true,func)  

            if actParent then
                  local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
                  local pos = actParent:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                  actParent:addChild(node , SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - endNode.p_rowIndex)
                  node:setPosition(pos)
            else
                  local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
                  local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                  self:addChild(node , REEL_SYMBOL_ORDER.REEL_ORDER_1 - endNode.p_rowIndex)
                  node:setPosition(pos) 
            end
           

            self:setSpecialShowActionNodeScore(fatherNode,node,true)

      end
end

function HowlingMoonView:createOneActionSymbol(endNode,actionName)
      if not endNode or not endNode.m_ccbName  then
            return
      end
      
      local fatherNode = endNode

      local unlockedLines = self.m_machine.m_runSpinResultData.p_rsExtraData.unlockedLines -- 服务器已经解锁的个数
      if endNode.p_rowIndex <= unlockedLines then
            endNode:setVisible(true)
            local node= util_createAnimation(endNode.m_ccbName..".csb")
            local func = function(  )
                  if fatherNode then
                        fatherNode:setVisible(true)
                  end
                  if node then
                        node:removeFromParent()
                  end
                  
            end
            node:playAction(actionName,true,func)  

            local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            self:addChild(node , REEL_SYMBOL_ORDER.REEL_ORDER_1 - endNode.p_rowIndex)
            node:setPosition(pos)

            self:setSpecialShowActionNodeScore(fatherNode,node)

      end
end

-- 设置respin分数
function HowlingMoonView:setSpecialShowActionNodeScore(fathernode,node,rsOver)
      local symbolNode = fathernode
      local iCol = symbolNode.p_cloumnIndex or symbolNode.p_colIndex
      local iRow = symbolNode.p_rowIndex
  
      local rowCount = 0
        if iCol ~= nil then
            local columnData = self.m_machine.m_reelColDatas[iCol]
            rowCount = columnData.p_showGridCount
        end
    
    
        if iRow ~= nil and iRow <= rowCount and iCol ~= nil and (symbolNode.m_isLastSymbol == true  or rsOver )  then 
            --获取分数
                    local score = self.m_machine:getReSpinSymbolScore(self.m_machine:getPosReelIdx(iRow, iCol))
                    local coinsNum = self.m_machine:getReSpinSymbolScore(self.m_machine:getPosReelIdx(iRow, iCol))
                    if score then
                        local index = 0
                        if type(score) ~= "string" then
                            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
                            score = score * lineBet
                            score = util_formatCoins(score, 3)
                            node:findChild("m_lb_score"):setString(score)

                            node:findChild("m_lb_score1"):setString(score)

                            if node:findChild("m_lb_score") and node:findChild("m_lb_score1") then
                              node:findChild("m_lb_score"):setVisible(false)
                              node:findChild("m_lb_score1"):setVisible(false)
                                if coinsNum >= 8 then
                                    node:findChild("m_lb_score1"):setVisible(true)
                                else
                                    node:findChild("m_lb_score"):setVisible(true)
                                end
                            end

                        end
                    end
            --   symbolNode:runAnim("buling")F
    
        else
            local score =  self.m_machine:randomDownRespinSymbolScore(symbolNode.p_symbolType)
            if type(score) ~= "string" then
                local lineBet = self:BaseMania_getLineBet() * self.m_machine.m_lineCount
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                node:getChildByName("m_lb_score"):setString(score)
            end
            --   symbolNode:runAnim("buling")
        end
end
--node滚动停止
function HowlingMoonView:respinNodeEndBeforeResCallBack(endNode)
      --判断是否是该列最后一个格子滚动结束
      local lastColNodeRow = endNode.p_rowIndex 
      for i=1,#self.m_respinNodes do
            local respinNode = self.m_respinNodes[i]
            if respinNode.p_colIndex == endNode.p_cloumnIndex and respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  if respinNode.p_rowIndex < lastColNodeRow  then
                        lastColNodeRow = respinNode.p_rowIndex 
                  end
            end
      end
      if endNode.p_rowIndex  == lastColNodeRow then
            self:oneReelDown(endNode.p_cloumnIndex)
      end
end

-- 根据服务器数据获得有效固定信号
function HowlingMoonView:getUsefulFixSlotsNode( )
      local UsefulNode =  {}
      local unlockedLines = self.m_machine.m_runSpinResultData.p_rsExtraData.unlockedLines -- 服务器已经解锁的个数


      for i=1,#self.m_respinNodes do
            local respinNode = self.m_respinNodes[i]
            if respinNode.p_rowIndex <= unlockedLines and respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
                  table.insert( UsefulNode,  respinNode )  
            end
      end

     
     return UsefulNode
     
end
function HowlingMoonView:oneReelDown(cloumn)
      

      local lcokNode = self:getUsefulFixSlotsNode( )
      print("lcokNode  数量 ================#lcokNode "..#lcokNode.."cloumn  "..cloumn)
      local lightNum = 0
      local unlockedLines = self.m_machine.m_runSpinResultData.p_rsExtraData.unlockedLines -- 服务器已经解锁的个数
      local lockedSymbols = #lcokNode -- self.m_machine.m_runSpinResultData.p_rsExtraData.totalRewardSignals -- 服务器已经锁住的信号数

      local lightNum = lockedSymbols

      performWithDelay(self,function( )
            if lightNum >= 8 and lightNum <= 11 then
                  self.m_machine:unlockedOneNode(1)
            elseif lightNum >=12 and lightNum <= 15 then
                  self.m_machine:unlockedOneNode(1)
                  self.m_machine:unlockedOneNode(2)
            elseif lightNum >=16 and lightNum <= 19 then
                  self.m_machine:unlockedOneNode(1)
                  self.m_machine:unlockedOneNode(2)
                  self.m_machine:unlockedOneNode(3)
            elseif lightNum >=20 and lightNum <= 40 then
                  self.m_machine:unlockedOneNode(1)
                  self.m_machine:unlockedOneNode(2)
                  self.m_machine:unlockedOneNode(3)
                  self.m_machine:unlockedOneNode(4)
            end
            for k,v in pairs(self.m_machine.m_lockNodeArray) do
                  v:updateLockLeftNum( self.m_machine.m_lockNumArray[k] - lightNum )
            end
      end,0.5 + 0.05 * cloumn )
      
      gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Reel_Stop.mp3")

      
end


---获取所有参与结算节点
function HowlingMoonView:getAllCleaningNode()
      --从 从上到下 左到右排序
      local cleaningNodes = {}
      local childs = self:getChildren()

      for i=1,#childs do
            local node = childs[i]
            if node.getLastNode and node:getLastNode():getTag() == self.REPIN_NODE_TAG  and self:getPartCleaningNode(node.p_rowIndex, node.p_colIndex) then
                  local unlockedLines = self.m_machine.m_runSpinResultData.p_rsExtraData.unlockedLines -- 服务器已经解锁的个数
                  if node.p_rowIndex <= unlockedLines then
                        cleaningNodes[#cleaningNodes + 1] =  node
                  end
                  
            end
      end


      --排序
      local sortNode = {}
      for iCol = 1 , self.m_machineColmn do
            
            local sameRowNode = {}
            for i = 1, #cleaningNodes do
                  local  node = cleaningNodes[i]
                  if node.p_colIndex == iCol then
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

function HowlingMoonView:initMachine(machine)
      self.m_machine = machine
end


--repsinNode滚动完毕后 置换层级
function HowlingMoonView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            -- local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            -- local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            -- endNode:removeFromParent()
            -- self:addChild(endNode , REEL_SYMBOL_ORDER.REEL_ORDER_1 - endNode.p_rowIndex, self.REPIN_NODE_TAG)
            -- endNode:setPosition(pos)
            endNode:setTag(self.REPIN_NODE_TAG)
            local unlockedLines = self.m_machine.m_runSpinResultData.p_rsExtraData.unlockedLines -- 服务器已经解锁的个数
            if endNode.p_rowIndex <= unlockedLines then
                   gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_spin_light_down.mp3")
            end

            
 

        
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

function HowlingMoonView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)
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
  
      self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
      
      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),200)
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
  
      respinNode:initConfigData()

      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
              respinNode:setLightFirstSlotNode(symbolNode)
              self:setLightScore(symbolNode)
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
      else
              respinNode:setFirstSlotNode(symbolNode)
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
  
end

function HowlingMoonView:setLightScore( reelNode )
      --下帧调用 才可能取到 x y值
      local callFun = cc.CallFunc:create(handler(self.m_machine, self.m_machine.setSpecialNodeScore), {reelNode})
      reelNode:runAction(callFun)
end

function HowlingMoonView:getRespinEndNode(iX, iY)
      local childs = self:getChildren()

      for i=1,#childs do
            local node = childs[i]
            if node.getLastNode and node:getLastNode():getTag() == self.REPIN_NODE_TAG and node.p_rowIndex == iX  and node.p_colIndex == iY then
                  return node
            end
      end
      print("RESPINNODE NOT END!!!")
      return nil
end

--获取所有最终停止信号
function HowlingMoonView:getAllEndSlotsNode()
      local endSlotNode = {}
      local childs = self:getChildren()

      for i=1,#childs do
            local node = childs[i]
            if node.getLastNode and node:getLastNode():getTag() == self.REPIN_NODE_TAG  then
                  endSlotNode[#endSlotNode + 1] =  node:getLastNode()
            end
      end
      for i=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[i]
            if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  endSlotNode[#endSlotNode + 1] =  repsinNode:getLastNode()
            end
      end
      return endSlotNode
end

--获取所有固定信号
function HowlingMoonView:getFixSlotsNode()
      local fixSlotNode = {}
      local childs = self:getChildren()

      for i=1,#childs do
            local node = childs[i]
            if node.getLastNode and node:getLastNode():getTag() == self.REPIN_NODE_TAG  then
                  fixSlotNode[#fixSlotNode + 1] =  node
            end
      end
      return fixSlotNode
end

--组织滚动信息 开始滚动 
function HowlingMoonView:startMove()
       gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/sound_HowlingMoon_reel_run_rs.mp3")
      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0
      for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                  self.m_respinNodes[i]:startMove()
            end
      end
end
return HowlingMoonView