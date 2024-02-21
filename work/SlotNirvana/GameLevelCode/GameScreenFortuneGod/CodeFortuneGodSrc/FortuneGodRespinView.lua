

local FortuneGodRespinView = class("FortuneGodRespinView", util_require("Levels.RespinView"))


FortuneGodRespinView.SYMBOL_RS_SCORE_BLANK = 100

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 16
local symbolWidth = 132
local BASE_COL_INTERVAL = 3

local bottomIndex = {15,16,17,18,19}

function FortuneGodRespinView:initUI(respinNodeName)
      FortuneGodRespinView.super.initUI(self,respinNodeName)
      self.m_baseRunNum = BASE_RUN_NUM
      self.respinKuang = {}
      self.kuangIndex = 0
      self.showScaleIndex = 1
      -- self.isShowScale = false
      self.isHideKuang = false
end


function FortuneGodRespinView:oneReelDown()
      gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_reelStop.mp3")
end

function FortuneGodRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      --
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
                  -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end

            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end

      -- self:changeCLipNodePos()

      local tempList = self:getAllCleaningNode()
      for i=1,5 do
            local symbolNum = self:changeKuang(tempList,i)
            self:showSynthesis(i,symbolNum,false)
      end

      self:readyMove()
      
      
end

--修正位置
function FortuneGodRespinView:changeCLipNodePos( )
      self:changeClipRowNode(1,cc.p(0,0.5)) --修正位置
      self:changeClipRowNode(3,cc.p(0,-0.5)) --修正位置
      self:changeClipRowNode(4,cc.p(0,-2))
end

--初始化时，显示连接框
function FortuneGodRespinView:changeKuang(machineElement,col)
      local symbolNum = 0
      local kuangIndex = self.m_machine.m_iReelRowNum
      for i,v in ipairs(machineElement) do
            if v.p_cloumnIndex == col and v.p_rowIndex == kuangIndex then
                  kuangIndex = kuangIndex - 1
                  symbolNum = symbolNum + 1
            end  
      end
      return symbolNum
end

function FortuneGodRespinView:isHaveTopSymbol(col,row)
      for index =1,#self.m_machineElementData do
            local nodeInfo = self.m_machineElementData[index]
            if self.m_machine:isFixSymbol(nodeInfo.Type) and nodeInfo.ArrayPos.iX == row + 1 and nodeInfo.ArrayPos.iY == col then
                  return true
            end
      end
      return false
end

function FortuneGodRespinView:createRespinNode(symbolNode, status)

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
              respinNode.m_baseFirstNode = symbolNode
              util_changeNodeParent(self,symbolNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - symbolNode.p_rowIndex)
              symbolNode:setTag(self.REPIN_NODE_TAG)
      else
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
              respinNode:setFirstSlotNode(symbolNode)
      end
      
      
      if symbolNode.p_rowIndex == self.m_machine.m_iReelRowNum then
            local tempRespinNode = util_spineCreate("Socre_FortuneGod_Bonus",true,true)
            local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPositionX(), symbolNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            self:addChild(tempRespinNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - 100)
            tempRespinNode:setVisible(false)
            tempRespinNode.p_Col = symbolNode.p_cloumnIndex
            table.insert( self.respinKuang,tempRespinNode)
            tempRespinNode:setPosition(pos)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
      if self.m_machine:isFixSymbol(symbolNode.p_symbolType) and symbolNode.p_rowIndex == self.m_machine.m_iReelRowNum then
            symbolNode:runAnim("idleframe2")
            -- self:showSynthesis(symbolNode.p_cloumnIndex,1,false)
            --if self.m_machine:isFixSymbol(symbolNode.p_symbolType) and symbolNode.p_rowIndex == self.m_machine.m_iReelRowNum - 1 then
      else
            --判断上一行是否有小块
            if self:isHaveTopSymbol(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex) and symbolNode.p_rowIndex == self.m_machine.m_iReelRowNum - 1 then
                  symbolNode:runAnim("idleframe2")
            else
                  symbolNode:runAnim("idleframe")
            end
            
      end
end

function FortuneGodRespinView:clearRespinKuang( )
      for i,v in pairs(self.respinKuang) do
            v:removeFromParent()
      end
      self.respinKuang = {}
end

function FortuneGodRespinView:cleaRespinKuangForIndex(col)
      for i,v in pairs(self.respinKuang) do
            if v.p_Col == col then
                  v:removeFromParent()
                  self.respinKuang[i] = nil
            end
            
      end
end

function FortuneGodRespinView:showSynthesis(col,num,isShow)
      if num == 0 then
            return
      end
      local actName = self:getActForNum(num)
      for i,v in ipairs(self.respinKuang) do
            if i == col then
                  v:setVisible(true)
                  if isShow then
                        util_spinePlay(v,actName[1],false)
                        util_spineEndCallFunc(v,actName[1],function (  )
                              util_spinePlay(v,actName[2],false)
                        end)
                  else
                        util_spinePlay(v,actName[2],false)
                  end
            end
      end
end

function FortuneGodRespinView:getActForNum(num)
      if num == 2 then
            return {"hecheng1","hecheng1idle"}
      elseif num == 3 then
            return {"hecheng2","hecheng2idle"}
      elseif num == 4 then
            return {"hecheng3","hecheng3idle"}
      end
      return {"hechengidle","hechengidle"}
end

---获取所有参与结算节点
function FortuneGodRespinView:getAllCleaningNode()
      --从 从上到下 左到右排序
      local cleaningNodes = {}
      for index = 1,#self.m_respinNodes do
            local respinNode = self.m_respinNodes[index]
            if RESPIN_NODE_STATUS.LOCK == respinNode:getRespinNodeStatus()  then
                  cleaningNodes[#cleaningNodes + 1] = respinNode.m_baseFirstNode
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


function FortuneGodRespinView:changeLockSymbol(fixPos)
      local respinNode = self:getRespinNode(fixPos.iX,fixPos.iY)
      if respinNode and respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
            local blankType = self.SYMBOL_RS_SCORE_BLANK
            local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
            local node = respinNode.m_baseFirstNode
            if node then
                  node:changeCCBByName(ccbName, blankType)
                  node:changeSymbolImageByName( ccbName )
            end
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
            respinNode:setFirstSlotNode(node)

      end
      
end

function FortuneGodRespinView:changeBlankSymbol(type,pos,score)
      local fixPos = self.m_machine:getRowAndColByPos(pos)
      local respinNode = self:getRespinNode(fixPos.iX,fixPos.iY)
      if respinNode and respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.IDLE then
            local blankType = type
            local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
            local node = respinNode.m_baseFirstNode
            if node then
                  node:changeCCBByName(ccbName, blankType)
                  node:changeSymbolImageByName( ccbName )
                  self.m_machine:addLevelBonusSpine(node)
                  local symbol_node = node:checkLoadCCbNode()
                  local spineNode = symbol_node:getCsbAct()
                  if spineNode.m_csbNode then
                        local lbs = spineNode.m_csbNode:findChild("m_lb_coins")
                        if lbs and lbs.setString  then
                              lbs:setString(util_formatCoins(score, 3))
                        end
                  end
            end
            
            local Nodepos = util_convertToNodeSpace(node,self)
            util_changeNodeParent(self,node,REEL_SYMBOL_ORDER.REEL_ORDER_2 - node.p_rowIndex, self.REPIN_NODE_TAG)
            node:setPosition(Nodepos)
            --播移动反馈
            if self.m_machine:isTopSymbol(pos) then
                  node:runAnim("actionframe3_1",false,function (  )
                        node:runAnim("idleframe2")
                  end)
            else
                  node:runAnim("actionframe3_2",false,function (  )
                        node:runAnim("idleframe2")
                  end)
                  --播放撞击效果
                  self:getUpNodeByRowAndCol(fixPos.iX + 1,fixPos.iY)
            end
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
      end
      
end

function FortuneGodRespinView:getUpNodeByRowAndCol(row,col)
      local respinNode = self:getRespinNode(row,col) 
      local symbolNode = respinNode.m_baseFirstNode
      if symbolNode then
            symbolNode:runAnim("switch3",false,function (  )
                  symbolNode:runAnim("idleframe2")
            end)
      end
end

function FortuneGodRespinView:isShowSynthesis(endNode)
      local index = self.m_machine:getPosReelIdx(endNode.p_rowIndex,endNode.p_cloumnIndex)
      if index == 0 or index == 1 or index == 2 or index == 3 or index == 4 then
            return true        
      end
      return false
end

--repsinNode滚动完毕后 置换层级
function FortuneGodRespinView:respinNodeEndCallBack(endNode, status)
      FortuneGodRespinView.super.respinNodeEndCallBack(self,endNode, status)
      if self.m_machine:isFixSymbol(endNode.p_symbolType) and endNode.p_rowIndex == self.m_machine.m_iReelRowNum then
            endNode:runAnim("actionframe3_1",false,function (  )
                  endNode:runAnim("idleframe2")
                  if self.m_machine:isShowOneSynthesis(endNode.p_rowIndex,endNode.p_cloumnIndex) and self:isShowSynthesis(endNode) then
                        self:showSynthesis(endNode.p_cloumnIndex,1,false)
                  end
            end)
      end
      if self.isHideKuang then
            if self.m_machine:isFixSymbol(endNode.p_symbolType) and endNode.p_rowIndex == 1 and self.m_machine:isCurNodeForEndCol(endNode.p_cloumnIndex) then
                  self.m_machine:hideLinkRunForCol(endNode.p_cloumnIndex)
            end
      end
      -- if self.isShowScale then
      --       self:checkStartSacle(endNode)
      -- end

end

-- function FortuneGodRespinView:checkStartSacle(endNode)
--       local fixPos = self.m_machine:getRespinOneCol()
--       if endNode.p_cloumnIndex == fixPos.iY - 1 and endNode.p_rowIndex == 1 then
--             self.isShowScale = false
--             self.m_machine:hideLinkRun()
--             self:showScaleEffect()
--       end
-- end

function FortuneGodRespinView:noMoveSymbolShow(row,col)
      local allSymbol = self:getAllCleaningNode()
      for i,v in ipairs(allSymbol) do
            if v.p_rowIndex == row and v.p_cloumnIndex == col then
                  v:runAnim("actionframe3_2",false,function (  )
                        v:runAnim("idleframe2")
                  end)
            end
      end
end


function FortuneGodRespinView:sortNearEnd(ifNearEnd)
      table.sort( ifNearEnd, function (a, b)
            return a < b
      end )
end


function FortuneGodRespinView:runNodeEnd(endNode)
      FortuneGodRespinView.super.runNodeEnd(self,endNode)
      if self.m_machine:isFixSymbol(endNode.p_symbolType) then
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_bonus_down.mp3")
      end
end


function FortuneGodRespinView:startMove( )
      FortuneGodRespinView.super.startMove(self)
      local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {}
      local ifNearEnd = rsExtraData.ifNearEnd or {}
      if self.m_machine:isShowLinkRunSound() then
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_showLinkRun.mp3")
      end
      for i,v in ipairs(ifNearEnd) do
            self.m_machine:showLinkRun(v + 1)
      end
end

return FortuneGodRespinView