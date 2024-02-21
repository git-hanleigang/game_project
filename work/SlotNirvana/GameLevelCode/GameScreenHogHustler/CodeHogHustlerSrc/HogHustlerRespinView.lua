

local HogHustlerRespinView = class("HogHustlerRespinView", 
                                    util_require("Levels.RespinView"))

local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3

--重写
function HogHustlerRespinView:initUI(respinNodeName)
      HogHustlerRespinView.super.initUI(self, respinNodeName)

      self.m_bonusSoundArray = {false, false, false, false, false}
      self.m_bonusSoundQuickPlayed = false
      self.m_quickStopMark = false

      self.m_quickRunSoundId = nil

      self.m_quickRunAni = util_createAnimation("Socre_HogHustler_Bonus_run.csb")
      self.m_quickRunAni:runCsbAction("run", true)
      self:addChild(self.m_quickRunAni,10000)
      self.m_quickRunAni:setVisible(false)

      

      self.m_respinXian = util_createAnimation("HogHustler_respinxian.csb")
      self:addChild(self.m_respinXian, 100)
end

--重写
function HogHustlerRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            endNode:runAnim("buling", false, function()
                  endNode:runAnim("idleframe2", true)
                  if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 0 then
                        -- self.m_quickRunAni:setVisible(false)
                        self:quickRunAnim(false)
                  end
            end)
            self.m_machine:bonusPlayScore(endNode, "buling", false, function()
                  self.m_machine:bonusPlayScore(endNode, "idleframe", true)
            end)
            self:playSound(endNode)
      else
            if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 0 then
                  -- self.m_quickRunAni:setVisible(false)
                  self:quickRunAnim(false)
            end
      end
      
end

function HogHustlerRespinView:playSound(endNode)

      local col = endNode.p_cloumnIndex
      
      if col < 1 or col > 5 then
            return
      end

      if self.m_quickStopMark == false then
            if self.m_bonusSoundQuickPlayed == false then
                  self.m_bonusSoundQuickPlayed = true
                  gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_bonus_buling)
            end
      else
            if self.m_bonusSoundArray[col] == false then
                  self.m_bonusSoundArray[col] = true
                  gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_bonus_buling)
            end
      end
      
end

function HogHustlerRespinView:quicklyStop()
      HogHustlerRespinView.super.quicklyStop(self)
end

--重写
function HogHustlerRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      -- self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)


      self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE,{
            clipOffsetSize = cc.size(1, 2),
            clipOffsetPos = cc.p(0, 1)
      })
      -- self:changeClipBaseNode(cc.p(0,0)) --修正位置

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

            if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(machineNode.p_symbolType) == true then
                  machineNode:runAnim("idleframe2", true)
                  self.m_machine:bonusPlayScore(machineNode, "idleframe", true)
            end

            if machineNode.m_Coin then
                  machineNode.m_Coin:stopAllActions()
                  machineNode.m_Coin:removeFromParent()
                  machineNode.m_Coin = nil
            end

            self:createRespinNode(machineNode, status)
      end

      self:readyMove()
end

function HogHustlerRespinView:createRespinNode(symbolNode, status)

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
              --改
              symbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self.m_machine:getPosReelIdx(respinNode.p_rowIndex, respinNode.p_colIndex))
      else
              respinNode:setFirstSlotNode(symbolNode)
              respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
  end

function HogHustlerRespinView:oneReelDown()
      --gLobalSoundManager:playSound("levelsTempleSounds/music_levelsTemple_reel_stop.mp3")
      gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_reel_stop_normal)
end

---获取所有参与结算节点
function HogHustlerRespinView:getAllCleaningNode()
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

--结束的时候
function HogHustlerRespinView:playRespinOverAnim()
    local chipList = self:getAllCleaningNode()
    -- gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_respin_over_bonusSaoGuang.mp3")

    for i,vNode in ipairs(chipList) do
        vNode:runAnim("idleframe", true)
        self.m_machine:bonusPlayScore(vNode, "idleframe", true)
    end
end

--重写
function HogHustlerRespinView:startMove()
      self.m_bonusSoundArray = {false, false, false, false, false}
      self.m_bonusSoundQuickPlayed = false
      self.m_quickStopMark = false

      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0

      local unLockNodes = {}
      for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                  self.m_respinNodes[i]:startMove()

                  self.m_respinNodes[i]:setRunReduce(false)
                  self.m_respinNodes[i]:changeRunSpeed(false)
                  unLockNodes[#unLockNodes + 1] = self.m_respinNodes[i]
            end
      end

      if #unLockNodes == 1 then
            self.m_quickRunAni:setPosition(cc.p(unLockNodes[1]:getPosition()))
            -- self.m_quickRunAni:setVisible(true)
            self:quickRunAnim(true)

            unLockNodes[1]:changeRunSpeed(true)
            unLockNodes[1]:setRunReduce(true)
            --     self.m_soundId = gLobalSoundManager:playSound()

      else
            -- self.m_quickRunAni:setVisible(false)
            self:quickRunAnim(false)
      end

      -- if self.m_machine.m_runSpinResultData and self.m_machine.m_runSpinResultData.p_reSpinCurCount and self.m_machine.m_runSpinResultData.p_reSpinCurCount == 1 then
      --       if #unLockNodes == 1 then
      --             unLockNodes[1]:setRunReduce(true)
      --       elseif #unLockNodes > 1 and #unLockNodes < 4 then
      --             unLockNodes[#unLockNodes]:setRunReduce(true)
      --       elseif #unLockNodes >= 4 then
      --             for i=#unLockNodes, #unLockNodes - 2, -1 do
      --                   unLockNodes[i]:setRunReduce(true)
      --             end
      --       end
      -- end
      
end

--快滚动画
function HogHustlerRespinView:quickRunAnim(_isShow)
      self.m_quickRunAni:setVisible(_isShow)
      if _isShow then
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_quickeffect_begin)
            self.m_quickRunSoundId = gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_quick_run)
      else
            if self.m_quickRunSoundId then
                  gLobalSoundManager:stopAudio(self.m_quickRunSoundId)
                  self.m_quickRunSoundId = nil
            end
      end
end

--重写
function HogHustlerRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
      for j=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[j]
            local bFix = false 
            local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL

            --改
            if repsinNode.m_isQuick then
                  runLong = runLong * 3
            end

            if not repsinNode.m_isQuick and repsinNode.m_isReduceRun then
                  runLong = runLong * 2
            end
            --改

            for i=1, #storedNodeInfo do
                  local stored = storedNodeInfo[i]
                  if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                        repsinNode:setRunInfo(runLong, stored.type)
                        bFix = true
                  end
            end
            
            for i=1,#unStoredReels do
                  local data = unStoredReels[i]
                  if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                        repsinNode:setRunInfo(runLong, data.type)
                  end
            end
      end
end

--重写
--repsinNode滚动完毕后 置换层级
function HogHustlerRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex))
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

return HogHustlerRespinView