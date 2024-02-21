local BingoldKoiRespinView = class("BingoldKoiRespinView", util_require("Levels.RespinView"))

BingoldKoiRespinView.m_longRunSpeed = 4000
local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 15 --20
local BASE_ROW_ADD_NUM = 9 --2
local BASE_COL_INTERVAL = 6

local WIN_LINE_ZORDER = 5000

function BingoldKoiRespinView:ctor()
      BingoldKoiRespinView.super.ctor(self)
      self.m_scatterNodeList = {}
end

--组织滚动信息 开始滚动
function BingoldKoiRespinView:startMove()
      self.isQuickRun = false
      self.m_scatterNodeList = {}
      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0
      for i=1,#self.m_respinNodes do
            --锁定的小块需要先解除锁定
            if self.m_respinNodes[i]:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
                  self:changeRespinNodeLockStatus(self.m_respinNodes[i],false)
            end
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                  self.m_respinNodes[i]:startMove()
            end
      end
end

--node滚动停止
function BingoldKoiRespinView:respinNodeEndBeforeResCallBack(endNode)
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
      self:playSymbolNodeBuling(endNode)
      if endNode.p_rowIndex  == lastColNodeRow then
            self:oneReelDown(endNode.p_cloumnIndex)
      end
end

function BingoldKoiRespinView:playSymbolNodeBuling(endNode)
      if not endNode or not endNode.p_symbolType then
            return
      end
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            if info.type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and self.m_machine:getCurSymbolIsPlayBuLing(endNode) then
                  endNode:runAnim(info.runEndAnimaName, false, function()
                        endNode:runAnim("idleframe", true)
                  end)
                  self.m_scatterNodeList[#self.m_scatterNodeList+1] = endNode
            elseif info.type == self.m_machine.SYMBOL_BONUS then
                  endNode:runAnim(info.runEndAnimaName, false, function()
                        endNode:runAnim("idleframe", true)
                  end)
            end
      end
end

function BingoldKoiRespinView:quicklyStop()
      BingoldKoiRespinView.super.quicklyStop(self)
      self.isQuickRun = true
      gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Reel_QuickStop_Sound)
end

--
function BingoldKoiRespinView:runNodeEnd(endNode)
      if not endNode or not endNode.p_symbolType then
            return
      end
      --判断快停情况下，只播放一个scatter（如果scatter和bonus同时存在的情况下）
      local quickPlayBonus = true
      if self.isQuickRun and self.m_machine:getCurReelDataHaveScatter() then
            quickPlayBonus = false
      end
      if endNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and self.curColPlayScatterSound and self.m_machine:getCurSymbolIsPlayBuLing(endNode) then
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Scatter_buling)
            self.curColPlayScatterSound = nil
      end
      if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS and self.curColPlaySound then
            if self.isQuickRun then
                  if quickPlayBonus then
                        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Bonus_buling)
                  end
            else
                  gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Bonus_buling)
            end
            self.curColPlaySound = nil
      end
      -- local info = self:getEndTypeInfo(endNode.p_symbolType)
      -- if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
      --       endNode:runAnim(info.runEndAnimaName, false)
      -- end
end



function BingoldKoiRespinView:oneReelDown(iCol)
      self.curColPlaySound = iCol
      self.curColPlayScatterSound = iCol
      -- self:setLongRunState(iCol)
      if not self.isQuickRun then
            self.m_machine:slotLocalOneReelDown(iCol)
      end
end

--设置快滚状态
function BingoldKoiRespinView:setLongRunState(iCol)
      if iCol + 1 == self.m_machine.m_longRunStartReel then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{ SpinBtn_Type.BtnType_Stop, false })
      end
      if self.m_machine.m_longRunStartReel and iCol + 1 >= self.m_machine.m_longRunStartReel then
            for j = 1, #self.m_respinNodes do
                  local repsinNode = self.m_respinNodes[j]
                  if repsinNode.p_colIndex == iCol + 1 then
                        repsinNode:setRunSpeed(self.m_longRunSpeed)
                        self.m_machine:rsLongRunEffect(iCol + 1)
                        -- 开始快滚的时候 其他scatter 播放ialeframe2
                        self:playScatterSpine("idleframe3", iCol)
                  elseif repsinNode.p_colIndex <= iCol then
                        repsinNode:setRunSpeed(3500)
                  end
            end
            gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
            self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.Music_Reel_Quick_Sound)
          if iCol == self.m_machine.m_iReelColumnNum then
              gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
              self:playScatterSpine("idleframe", iCol)
              self.m_machine:hideLongRunEffect()
          end
      else
            if iCol == self.m_machine.m_iReelColumnNum then
                  self:playScatterSpine("idleframe", iCol)
            end
      end
  end

  function BingoldKoiRespinView:playScatterSpine(_spineName, _reelCol)
      performWithDelay(self.m_machine.m_scWaitNode,function()
            if #self.m_scatterNodeList > 0 then
                  for i=1, #self.m_scatterNodeList do
                        local scatterNode = self.m_scatterNodeList[i]
                        if not tolua.isnull(scatterNode) then
                              if _spineName == "idleframe3" and scatterNode.m_currAnimName ~= "idleframe3" then
                                    scatterNode:runAnim(_spineName, true)
                              elseif _spineName == "idleframe" and (scatterNode.m_currAnimName ~= "buling" or scatterNode.p_cloumnIndex == self.m_machine.m_iReelColumnNum) then
                                    scatterNode:runAnim(_spineName, true)
                                    local isTriggerFree = self.m_machine:curIsTriggerFreeGame()
                                    if not isTriggerFree then
                                          local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - scatterNode.p_rowIndex + self.m_machine:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                          zOrder = zOrder - (self.m_machine.m_iReelColumnNum - scatterNode.p_cloumnIndex)
                                          scatterNode:setLocalZOrder(zOrder-scatterNode.p_cloumnIndex)
                                    end
                              end
                        end
                  end
            end
      end, 0.1)
  end

  function BingoldKoiRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
      --每一行滚动个数
      local runLongList = {}
  
      for j = 1, #self.m_respinNodes do
          local repsinNode = self.m_respinNodes[j]
          local bFix = false
  
          -- 每格间隔 -> 每列间隔
          --正常滚动时 起始滚动长度 15 列递增 5,快滚时从开始快滚的那一列多滚动2.5秒
          local longRunTotalNum = 0
          local runLong = 0
          if runLongList[repsinNode.p_colIndex] then
              runLong = runLongList[repsinNode.p_colIndex]
          else
              if self.m_machine.m_longRunStartReel and repsinNode.p_colIndex >= self.m_machine.m_longRunStartReel then
                  local longNum = 2.5 * self.m_longRunSpeed / self.m_slotNodeHeight
                  local beforeLongNum = (repsinNode.p_colIndex - self.m_machine.m_longRunStartReel) * 2.5 *
                      2000 / self.m_slotNodeHeight
  
                  longRunTotalNum = math.floor(longNum + beforeLongNum) - 5
                  runLong = runLongList[self.m_machine.m_longRunStartReel - 1] + longRunTotalNum
              else
                  runLong = self.m_baseRunNum + (repsinNode.p_colIndex - 1) * BASE_ROW_ADD_NUM
              end
  
              runLongList[repsinNode.p_colIndex] = runLong
          end
  
          for i = 1, #storedNodeInfo do
              local runDatelong = runLong
              local stored = storedNodeInfo[i]
              if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                  repsinNode:setRunInfo(runDatelong, stored.type)
                  bFix = true
              end
          end
  
          for i = 1, #unStoredReels do
              local data = unStoredReels[i]
              local runDatelong = runLong
              if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                  repsinNode:setRunInfo(runDatelong, data.type)
              end
          end
      end
  end

---获取所有参与结算节点
function BingoldKoiRespinView:getAllCleaningNode()
    --从 从上到下 左到右排序
    local cleaningNodes = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
            cleaningNodes[#cleaningNodes + 1] = node
        end
    end

    --排序
    local sortNode = {}
    for iCol = 1, self.m_machineColmn do
        local sameRowNode = {}
        for i = 1, #cleaningNodes do
            local node = cleaningNodes[i]
            if node.p_cloumnIndex == iCol then
                sameRowNode[#sameRowNode + 1] = node
            end
        end
        table.sort(
            sameRowNode,
            function(a, b)
                return b.p_rowIndex < a.p_rowIndex
            end
        )

        for i = 1, #sameRowNode do
            sortNode[#sortNode + 1] = sameRowNode[i]
        end
    end
    cleaningNodes = sortNode
    return cleaningNodes
end

--repsinNode滚动完毕后 置换层级
function BingoldKoiRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex
            if endNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and (not self.isQuickRun or self.m_machine:curIsTriggerFreeGame()) then
                  zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex + self.m_machine:getBounsScatterDataZorder(endNode.p_symbolType)
            end
            -- util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
            util_changeNodeParent(self,endNode,zOrder)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function BingoldKoiRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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
                  -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end

            local status = nodeInfo.status
            if nodeInfo.ArrayPos.iX == 3 and nodeInfo.ArrayPos.iY == 3 then
                  status = RESPIN_NODE_STATUS.LOCK
            end
            self:createRespinNode(machineNode, status)
      end

      self:readyMove()
end

function BingoldKoiRespinView:createRespinNode(symbolNode, status)
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
            respinNode.m_baseFirstNode = symbolNode

            self:changeRespinNodeLockStatus(respinNode,true)
      else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end


--[[
    获取respinNode索引
]]
function BingoldKoiRespinView:getRespinNodeIndex(col, row)
      return self.m_machine.m_iReelRowNum - row + 1 + (col - 1) * self.m_machine.m_iReelRowNum
end

--[[
      根据行列获取respinNode
]]
function BingoldKoiRespinView:getRespinNodeByRowAndCol(col,row)
      local respinNodeIndex = self:getRespinNodeIndex(col,row)
      local respinNode = self.m_respinNodes[respinNodeIndex]
      return respinNode
end

--[[
    改变小块的锁定状态
]]
function BingoldKoiRespinView:changeRespinNodeLockStatus(respinNode, isLock,isWinLine)
      if isLock then
            if not respinNode.isLocked then
                 --锁定小块不能滚动
                  respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)

                  local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - respinNode.m_baseFirstNode.p_rowIndex + self.m_machine:getBounsScatterDataZorder(respinNode.m_baseFirstNode.p_symbolType)
                  
                  if isWinLine then
                        zOrder = zOrder + WIN_LINE_ZORDER
                  end
                  
                  --变更小块父节点
                  local pos = util_convertToNodeSpace(respinNode.m_baseFirstNode,self)
                  util_changeNodeParent(self,respinNode.m_baseFirstNode,zOrder)
                  respinNode.m_baseFirstNode:setPosition(pos)
                  respinNode.isLocked = true 
            end
            
      else
            if respinNode.p_colIndex == 3 and respinNode.p_rowIndex == 3 then
                  return
            end
            --解除小块的锁定状态
            respinNode:setFirstSlotNode(respinNode.m_baseFirstNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
            respinNode.isLocked = false
      end
end

return BingoldKoiRespinView
