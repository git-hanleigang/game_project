local BunnysLockRespinView = class("BunnysLockRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 16

local BASE_COL_INTERVAL = 2

local MID_ZORDER = 20000     --中间格子层级

local WIN_LINE_ZORDER = 5000

function BunnysLockRespinView:ctor()
      BunnysLockRespinView.super.ctor(self)
      self.m_scatterCount = 0
      self.m_bonusCount = 0
      self.m_scatterNodes = {}

      self.m_scatterDown = {}
      self.m_bonusDown = {}
end

--
function BunnysLockRespinView:runNodeEnd(endNode)
      if not endNode or not endNode.p_symbolType then
            return
      end
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            endNode:runAnim(info.runEndAnimaName, false)
            if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS then
                  local csbNode = endNode:getCCBNode()
                  if csbNode and csbNode.m_spine then
                        util_spinePlay(csbNode.m_spine,"buling")
                  end
            end
      end
end

--node滚动停止
function BunnysLockRespinView:respinNodeEndBeforeResCallBack(endNode)
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
      elseif endNode.p_cloumnIndex == 3 and endNode.p_rowIndex == 2 then
            self:oneReelDown()
      end
end

function BunnysLockRespinView:oneReelDown()
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_reel_stop.mp3")
end

---获取所有参与结算节点
function BunnysLockRespinView:getAllCleaningNode()
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

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function BunnysLockRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      -- self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
      self.m_machineElementData = machineElement

      local hasFeature = self.m_machine:checkHasFeature()

      for i=1,#machineElement do
            local nodeInfo = machineElement[i]
            local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, hasFeature)

            local pos = self:convertToNodeSpace(nodeInfo.Pos)
            machineNode:setPosition(pos)
            self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
            machineNode:setVisible(true)
            if nodeInfo.isVisible then
                  -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end

            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end

      self:readyMove()
end


--repsinNode滚动完毕后 置换层级
function BunnysLockRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            if endNode then
                  local respinNode = self:getRespinNodeByRowAndCol(endNode.p_cloumnIndex,endNode.p_rowIndex)
                  respinNode.m_baseFirstNode = endNode
                  self:changeRespinNodeLockStatus(respinNode,true)
            end
      end
      self:runNodeEnd(endNode)

      if endNode and endNode.p_symbolType then
            
            if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS then
                  self.m_bonusCount = self.m_bonusCount + 1
                  if not self.m_scatterDown[endNode.p_cloumnIndex] then
                        self.m_scatterDown[endNode.p_cloumnIndex] = true
                        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_bonus_down.mp3")
                  end
            elseif endNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                  self.m_scatterCount = self.m_scatterCount + 1
                  self.m_scatterNodes[#self.m_scatterNodes + 1] = endNode
                  if not self.m_bonusDown[endNode.p_cloumnIndex] then
                        self.m_bonusDown[endNode.p_cloumnIndex] = true
                        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_scatter_down.mp3")
                  end
            elseif endNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                  gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_bonus1_down.mp3")
            end     
            if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
                  for iCol = 1,self.m_machine.m_iReelColumnNum do
                        self.m_scatterDown[iCol] = true
                        self.m_bonusDown[iCol] = true
                  end
            end       
      end

      if (self.m_scatterCount >= 2) and 
            self.m_isQuickRun and not self.m_quickRun:isVisible() and
            self:getouchStatus() ~= ENUM_TOUCH_STATUS.QUICK_STOP and 
            globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                  
            self.m_respinNodes[8]:changeRunSpeed(true)
            self.m_quickRun:setVisible(true)
            self.m_quickRun_bg:setVisible(true)
            self.m_sound_quick_id = gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_quick_run.mp3")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            if self.m_scatterCount >= 2 then
                  for k,scatterNode in pairs(self.m_scatterNodes) do
                        scatterNode:runAnim("idleframe1",true)
                  end 
            end
            
            
      end

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
            
            self.m_scatterDown = {}
            self.m_bonusDown = {}
            
            self.m_isQuickRun = false
            self.m_scatterCount = 0
            self.m_bonusCount = 0
            self.m_respinNodes[8]:changeRunSpeed(false)
            self.m_quickRun:setVisible(false)
            self.m_quickRun_bg:setVisible(false)

            if self:getouchStatus() ~= ENUM_TOUCH_STATUS.QUICK_STOP  then
                  --中间的格子如果是bonus,播落地音效
                  if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS then
                        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_bonus_down.mp3")
                  end
            end

            if self.m_sound_quick_id then
                  gLobalSoundManager:stopAudio(self.m_sound_quick_id)
                  self.m_sound_quick_id = nil
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            local reels = self.m_machine.m_runSpinResultData.p_reels

            --检测最大落地动画时间
            local delayTime = 0
            for iRow = 1,self.m_machine.m_iReelRowNum do
                  for iCol = 1,self.m_machine.m_iReelColumnNum do
                        if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                              delayTime = 21 / 30
                        elseif reels[iRow][iCol] == self.m_machine.SYMBOL_BONUS and delayTime < 0.5 then
                              delayTime = 0.5
                        end
                  end
            end
            --快停或者中间图标为特殊图标,等待落地播完
            if (self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP or 
                  reels[2][3] == TAG_SYMBOL_TYPE.SYMBOL_BONUS or 
                  reels[2][3] == self.m_machine.SYMBOL_BONUS) and delayTime > 0 then
                  self.m_machine:delayCallBack(delayTime,function()
                        for k,scatterNode in pairs(self.m_scatterNodes) do
                              scatterNode:runAnim("idleframe",true)
                        end
                        self.m_scatterNodes = {}
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
                  end)
            else
                  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
                  for k,scatterNode in pairs(self.m_scatterNodes) do
                        scatterNode:runAnim("idleframe",true)
                  end
            end
            
      end
end

function BunnysLockRespinView:createRespinNode(symbolNode, status)
      local respinNode = util_createView(self.m_respinNodeName)
      respinNode:setMachine(self.m_machine)
      respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
      if symbolNode.p_rowIndex == 2 then
            if symbolNode.p_cloumnIndex == 3 then
                  --设置随机数组
                  respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_mid_reel)
            elseif symbolNode.p_cloumnIndex == 2 or symbolNode.p_cloumnIndex == 4 then
                  --设置随机数组
                  respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_side_reel)
            else
                  --设置随机数组
                  respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_normal_reel)
            end
      else
            --设置随机数组
            respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_normal_reel)
      end
      
      --设置尺寸
      respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
      respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)

      respinNode:setPosition(cc.p(symbolNode:getPositionX(), symbolNode:getPositionY()))
      respinNode:setReelDownCallBack(
            function(symbolType, status)
                  if self.respinNodeEndCallBack ~= nil then
                        self:respinNodeEndCallBack(symbolType, status)
                  end
            end,
            function(symbolType)
                  if self.respinNodeEndBeforeResCallBack ~= nil then
                        self:respinNodeEndBeforeResCallBack(symbolType)
                  end
            end
      )
      respinNode:initClipNode(nil, 130)
      
      --最中间的小块需要缩放
      if symbolNode.p_cloumnIndex == 3 and symbolNode.p_rowIndex == 2 then
            local lock_bg = util_createAnimation("BunysLock_tubiaosuodingkuang.csb")
            self:addChild(lock_bg,MID_ZORDER)
            lock_bg:setPosition(util_convertToNodeSpace(self.m_machine:findChild("node_lock"),self))
            self.m_lockBg = lock_bg
            lock_bg:runCsbAction("idleframe",true)
            local sp_reel = lock_bg:findChild("sp_reel_5")
            sp_reel:addChild(respinNode)
            local reelSize = sp_reel:getContentSize()
            respinNode:setPosition(cc.p(reelSize.width / 2,reelSize.height / 2))
            respinNode:setScale(reelSize.height / self.m_slotNodeHeight)

            --快滚背景
            self.m_quickRun_bg = util_createAnimation("WinFrameBunnysLock_run_bg.csb")
            lock_bg:findChild("node_quick_bg"):addChild(self.m_quickRun_bg)
            self.m_quickRun_bg:runCsbAction("run",true)
            self.m_quickRun_bg:setVisible(false)

            self.m_quickRun = util_createAnimation("WinFrameBunnysLock_run.csb")
            lock_bg:findChild("node_quick"):addChild(self.m_quickRun)
            self.m_quickRun:runCsbAction("run",true)
            self.m_quickRun:setVisible(false)
      else
            self:addChild(respinNode, VIEW_ZORDER.REPSINNODE)
      end

      
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
      -- respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then

            respinNode.m_baseFirstNode = symbolNode

            self:changeRespinNodeLockStatus(respinNode,true)
      else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

function BunnysLockRespinView:changeEndType()
      for iCol = 1,self.m_machine.m_iReelColumnNum do
            for iRow = 1,self.m_machine.m_iReelRowNum do
                  local respinNode = self:getRespinNodeByRowAndCol(iCol,2)
                  if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
                        if iRow == 2 and (iCol == 2 or iCol == 4) then
                              --设置随机数组
                              respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_side_reel_free)
                        elseif iRow == 2 and iCol ~= 3 then
                              --设置随机数组
                              respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_normal_reel_free)
                        end
                  else
                        if iRow == 2 and (iCol == 2 or iCol == 4) then
                              --设置随机数组
                              respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_side_reel)
                        elseif iRow == 2 and iCol ~= 3 then
                              --设置随机数组
                              respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_normal_reel)
                        end
                  end
                  
            end
      end
end

function BunnysLockRespinView:changeMidEndType(isSpecial)
      local midRespinNode = self.m_respinNodes[8]
      if isSpecial then
            midRespinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_mid_reel_special)
      else
            midRespinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_machine.m_configData.m_mid_reel)
      end
end

--[[
    改变小块的锁定状态
]]
function BunnysLockRespinView:changeRespinNodeLockStatus(respinNode, isLock,isWinLine)
      if isLock then
            if not respinNode.isLocked then
                 --锁定小块不能滚动
                  respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)

                  local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - respinNode.m_baseFirstNode.p_rowIndex + self.m_machine:getBounsScatterDataZorder(respinNode.m_baseFirstNode.p_symbolType)
                  if respinNode.p_colIndex == 3 and respinNode.p_rowIndex == 2 then
                        zOrder = MID_ZORDER + self.m_machine:getBounsScatterDataZorder(respinNode.m_baseFirstNode.p_symbolType)
                  end
                  if isWinLine then
                        zOrder = zOrder + WIN_LINE_ZORDER
                  end
                  
                  --变更小块父节点
                  local pos =  util_convertToNodeSpace(respinNode.m_baseFirstNode,self)
                  util_changeNodeParent(self,respinNode.m_baseFirstNode,zOrder)
                  respinNode.m_baseFirstNode:setPosition(pos)
                  respinNode.m_baseFirstNode:setScale(respinNode:getScale())
                  if self.m_machine:getCurrSpinMode() ~= FREE_SPIN_MODE then
                        if respinNode.m_baseFirstNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                              respinNode.m_baseFirstNode:runAnim("idleframe0",true) 
                        else
                              respinNode.m_baseFirstNode:runAnim("idleframe",true) 
                        end
                  else
                        respinNode.m_baseFirstNode:runAnim("idleframe",true) 
                  end
                  
                  respinNode.isLocked = true 
            end
            
      else
            --特殊小块放回时需要一个渐变动画
            local symbolType = respinNode.m_baseFirstNode.p_symbolType
            local csbName = self.m_machine:getSymbolCCBNameByType(self.m_machine,symbolType)
            local tempSymbol
            if symbolType == self.m_machine.SYMBOL_BONUS then
                  tempSymbol = util_createAnimation(csbName..".csb")
                  local sp = util_createSprite("Symbol/Socre_BunnysLock_bonus2.png")
                  sp:setScale(0.5)
                  local label = tempSymbol:findChild("BitmapFontLabel_1")
                  label:setString(respinNode.m_baseFirstNode.m_score)
                  tempSymbol:findChild("spine"):addChild(sp)
                  tempSymbol:setScale(respinNode:getScale())

            elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                  local path = self.m_machine.m_configData[csbName][1]
                  tempSymbol = display.newSprite(path)
                  tempSymbol:setScale(0.5 * respinNode:getScale())

                  respinNode.m_baseFirstNode:initSlotNodeByCCBName(csbName,symbolType)
                  local ccbNode = respinNode.m_baseFirstNode:getCCBNode()
                  if ccbNode ~= nil then
                        ccbNode:removeFromParent()
                        -- 放回到池里面去
                        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
                              globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,symbolType)
                        end
                  end
            end

            if tempSymbol then
                  self:addChild(tempSymbol,respinNode.m_baseFirstNode:getLocalZOrder())
                  util_setCascadeOpacityEnabledRescursion(tempSymbol,true)
                  -- tempSymbol:setScale(respinNode:getScale())
                  tempSymbol:setPosition(cc.p(respinNode.m_baseFirstNode:getPosition()) )
                  tempSymbol:runAction(cc.Sequence:create({
                        cc.FadeOut:create(self.m_machine.m_changeScatterTime),
                        cc.RemoveSelf:create(true)
                  }))
            end
            
            --解除小块的锁定状态
            respinNode.m_baseFirstNode:setScale(1)
            respinNode:setFirstSlotNode(respinNode.m_baseFirstNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
            respinNode.isLocked = false

      end
end

--[[
    获取respinNode
]]
function BunnysLockRespinView:getRespinNodeIndex(col, row)
      return self.m_machine.m_iReelRowNum - row + 1 + (col - 1) * self.m_machine.m_iReelRowNum
end

--[[
      根据行列获取respinNode
]]
function BunnysLockRespinView:getRespinNodeByRowAndCol(col,row)
      local respinNodeIndex = self:getRespinNodeIndex(col,row)
      local respinNode = self.m_respinNodes[respinNodeIndex]
      return respinNode
end

function BunnysLockRespinView:isNeedQuickRun()
      local reels = self.m_machine.m_runSpinResultData.p_reels
      if reels[2][2] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and reels[2][4] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and not self.m_machine.m_isNotice then
            return true
      end

      -- local storedIcons = self.m_machine.m_runSpinResultData.p_storedIcons
      -- if #storedIcons > 5 or (#storedIcons == 5 and reels[2][3] ~= self.m_machine.SYMBOL_BONUS) then
      --       return true
      -- end

      return false  
end

function BunnysLockRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
      for j=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[j]
            local bFix = false 
            local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
            if j == 8 then  --最中间的格子最后停
                  runLong = self.m_baseRunNum + self.m_machine.m_iReelColumnNum * BASE_COL_INTERVAL
                  local reels = self.m_machine.m_runSpinResultData.p_reels
                  if self:isNeedQuickRun() then
                        self.m_isQuickRun = true
                        runLong = runLong * 2
                  end
            end
            
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

      self.m_machine:delayCallBack(0.5,function()
            for index = 1,#self.m_respinNodes do
                  local respinNode = self.m_respinNodes[index]
                  respinNode:setUseMystery(false)
            end
      end)
end

return BunnysLockRespinView
