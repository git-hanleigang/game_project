

local JackpotOfBeerRespinView = class("JackpotOfBeerRespinView", 
                                    util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}
-- 
JackpotOfBeerRespinView.m_spinEndNode = {}
function JackpotOfBeerRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            endNode:runAnim(info.runEndAnimaName, false)
            table.insert(self.m_spinEndNode, endNode)
      end

      self:removeLight(endNode)

end

function JackpotOfBeerRespinView:oneReelDown()
      gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_reelStop.mp3")
end

---获取所有参与结算节点
function JackpotOfBeerRespinView:getAllCleaningNode()
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

function JackpotOfBeerRespinView:onExit()
      self.m_spinEndNode = {}
end

  --[[
      快滚特效
]]
function JackpotOfBeerRespinView:runQuickEffect()
      self.m_machine.m_lightEffectNode:removeAllChildren(true)
      self.m_single_lights = {}
      for index=1,#self.m_qucikRespinNode do
          local quickRunInfo = self.m_qucikRespinNode[index]
          if not quickRunInfo.isEnd then
              if self.m_quickSoundId then
                  gLobalSoundManager:stopAudio(self.m_quickSoundId)
                  self.m_quickSoundId = nil
              end
            --   self.m_quickSoundId = gLobalSoundManager:playSound("JackpotOfBeerSounds/sound_JackpotOfBeer_respin_quick_run.mp3")
              local light_effect = util_createAnimation("WinFrameJackpotOfBeer_run_link.csb")
              light_effect:runCsbAction("actionframe",true)  --普通滚动状态
              self.m_machine.m_lightEffectNode:addChild(light_effect)
              self.m_single_lights[quickRunInfo.key] = light_effect
              light_effect:setPosition(util_convertToNodeSpace(quickRunInfo.node,self.m_machine.m_lightEffectNode))
            --   break;
          end
      end
  end

  --[[
    移除快滚框
]]
function JackpotOfBeerRespinView:removeLight(respinNode)
      local nodeTag = self.m_machine:getNodeTag(respinNode.p_cloumnIndex,respinNode.p_rowIndex,SYMBOL_NODE_TAG)
      if respinNode.p_symbolType == self.m_machine.SYMBOL_BONUS_LINK then
          --落地音效
          gLobalSoundManager:playSound("JackpotOfBeerSounds/sound_JackpotOfBeer_EmptyCup_Down.mp3")
      end
      for index=1,#self.m_qucikRespinNode do
          local quickRunInfo = self.m_qucikRespinNode[index]
          if quickRunInfo.key == nodeTag then
              if self.m_single_lights[nodeTag] then
                  self.m_single_lights[nodeTag]:removeFromParent(true)
              end
          end
      end
      
  end

  --组织滚动信息 开始滚动
function JackpotOfBeerRespinView:startMove()
      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0
      
      for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                  self.m_respinNodes[i]:startMove()
            end
      end

      self.m_qucikRespinNode = {}
      for j=1,#self.m_respinNodes do
          local repsinNode = self.m_respinNodes[j]
      --     --bonus数量
          local bonus_count = 0
          if self.m_machine.m_runSpinResultData.p_storedIcons then
              bonus_count = #self.m_machine.m_runSpinResultData.p_storedIcons
          end

          if bonus_count >= 13 then
              --存储快滚的小块
            if repsinNode.m_runLastNodeType == self.m_machine.SYMBOL_RS_SCORE_BLANK then
                  self.m_qucikRespinNode[#self.m_qucikRespinNode + 1] = {
                        key = self.m_machine:getNodeTag(repsinNode.p_colIndex,repsinNode.p_rowIndex,SYMBOL_NODE_TAG),
                        node = repsinNode
                  }
            end
          end
      end
  
      self:runQuickEffect()

end

function JackpotOfBeerRespinView:createRespinNode(symbolNode, status)

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
  
      --快滚小块光效
      self.m_single_lights = {}
      --快滚小块信息
      self.m_qucikRespinNode = {}
  
end


function JackpotOfBeerRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)

      local specailRun = false

      local bonus_count = 0
      if self.m_machine.m_runSpinResultData.p_storedIcons then
            bonus_count = #self.m_machine.m_runSpinResultData.p_storedIcons
      end

      if bonus_count >= 13 then
            specailRun = true
      end

      for j = 1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[j]
            local bFix = false
            local coldiff = 10
            local runLong = self:getBaseRunNum() + (repsinNode.p_colIndex- 1) * coldiff
            for i = 1, #storedNodeInfo do
                  local stored = storedNodeInfo[i]
                  if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                        repsinNode:setRunInfo(runLong, stored.type, specailRun , true)
                        bFix = true
                  end
            end
            
            for i=1,#unStoredReels do
                  local data = unStoredReels[i]
                  local isstore = false
                  if self.m_machine:isFixSymbol(data.type) then
                        isstore = true
                  end
                  if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then  
                        repsinNode:setRunInfo(runLong, data.type, specailRun, isstore)
                  end
            end
      end
end

return JackpotOfBeerRespinView