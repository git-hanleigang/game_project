
local DragonParadeRespinView = class("DragonParadeRespinView",util_require("Levels.RespinView"))

local BASE_COL_INTERVAL = 3

local VIEW_ZORDER = 
{
    NORMAL = 100,
    REPSINNODE = 1,
}

function DragonParadeRespinView:ctor()
    DragonParadeRespinView.super.ctor(self)
end

--重写
function DragonParadeRespinView:initUI(respinNodeName)
    DragonParadeRespinView.super.initUI(self, respinNodeName)

    self.m_quickRunSoundId = nil
    self.m_colEffect = {}
    self.m_bonusSoundArray = {false, false, false, false, false}
    self.m_bonusSoundQuickPlayed = false
    self.m_quickStopMark = false
    self.m_reelQuickPlayed = false

    self.m_quickRunNode = nil
    self.m_quick_soundid = nil

end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function DragonParadeRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun, _isLastReel)
    self.m_machineRow = machineRow 
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    self:setMachineType(machineColmn, machineRow)
    self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
    self.m_machineElementData = machineElement

    self.m_machine.m_respinQuickEffect:removeAllChildren()
    for i=1,#machineElement do
          local nodeInfo = machineElement[i]
          local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true, _isLastReel)

          --重进更新score
          if nodeInfo.Type == 95 or nodeInfo.Type == 96 then
            local posIdx = self.m_machine:getPosReelIdx(nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY)
            if _isLastReel then
                posIdx = posIdx + 15
            end
            local score = self.m_machine:getStoreIconsBonusScore(posIdx)
            machineNode.m_score = score
            local scoreStr = self.m_machine:formatCoins(score, 3)
            self.m_machine:bonusShowScore(machineNode, scoreStr)
          end
          
          --

          local pos = self:convertToNodeSpace(nodeInfo.Pos)
          machineNode:setPosition(pos)
          local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - machineNode.p_rowIndex + machineNode.p_cloumnIndex * 10
          self:addChild(machineNode, zOrder, self.REPIN_NODE_TAG)
          machineNode:setVisible(nodeInfo.isVisible)

          local status = nodeInfo.status
          self:createRespinNode(machineNode, status)
    end

    self:readyMove()
end

function DragonParadeRespinView:createRespinNode(symbolNode, status)

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
    
    --初始化裁切层
    respinNode:initClipNode()
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        respinNode.m_baseFirstNode = symbolNode

        --改
        symbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self.m_machine:getPosReelIdx(respinNode.p_rowIndex, respinNode.p_colIndex))
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

    if symbolNode and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
        -- symbolNode:runAnim("idleframe2", true)
    end

    respinNode:addTipNode(self,self.m_machine:getPosReelIdx(respinNode.p_rowIndex, respinNode.p_colIndex) + 3000)
end

--repsinNode滚动完毕后 置换层级
function DragonParadeRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    if status == RESPIN_NODE_STATUS.LOCK then
        local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
        local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        -- util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
        util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)) --改
        endNode:setTag(self.REPIN_NODE_TAG)
        endNode:setPosition(pos)
    end
    self:runNodeEnd(endNode)

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
        local unLockNodes = {}
        for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                -- self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                unLockNodes[#unLockNodes + 1] = self.m_respinNodes[i]
            end

            self.m_respinNodes[i]:hideTip()
            
        end

        if self.m_quick_soundid then
            gLobalSoundManager:stopAudio(self.m_quick_soundid)
            self.m_quick_soundid = nil
        end

        if #unLockNodes == 1 and self.m_machine.m_runSpinResultData.p_reSpinCurCount > 0 then
            unLockNodes[1]:showTip()

            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_quickrun_edge_appear.mp3")
        end


        --把machine respindown放后面
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)


    end
end

function DragonParadeRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
        endNode:runAnim(info.runEndAnimaName, false)

        
    end
    if endNode then
        if self.m_machine:isFixSymbol(endNode.p_symbolType) then

            self:playSound(endNode)
            endNode:runAnim("buling2",false,function(  )
                endNode:runAnim("idleframe2",true)
            end)
        end
    end

    -- body
end


---获取所有参与结算节点
function DragonParadeRespinView:getAllCleaningNode()
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
            cleaningNodes[#cleaningNodes + 1] = symbolNode
        end
        
    end
    table.sort(cleaningNodes, function(a, b)
        if a.p_cloumnIndex == b.p_cloumnIndex then
            return a.p_rowIndex > b.p_rowIndex
        else
            return a.p_cloumnIndex < b.p_cloumnIndex
        end
    end)
    
    return cleaningNodes
end

function DragonParadeRespinView:getOneCleaningNode(posIdx)
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode

        local pos = self.m_machine:getPosReelIdx(respinNode.p_rowIndex, respinNode.p_colIndex)
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) and posIdx == pos then
            return symbolNode
        end
        
    end
    return nil
end

function DragonParadeRespinView:getInitLockNode()
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == 94 then
            cleaningNodes[#cleaningNodes + 1] = symbolNode
        end
        
    end

    table.sort(cleaningNodes, function(a, b)
        if a.p_cloumnIndex == b.p_cloumnIndex then
            return a.p_rowIndex > b.p_rowIndex
        else
            return a.p_cloumnIndex < b.p_cloumnIndex
        end
    end)

    return cleaningNodes
end

--列新增的锁定小块 仅限于在oneslotdown里调用
function DragonParadeRespinView:getColOnlyNewAddNum(colIndex)
    local newlockNum = 0

    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        if respinNode then
            if respinNode.p_colIndex == colIndex then
                if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                    --未锁定 oneReelDown在设置锁定前 所以要判断下
                    if not respinNode.m_lastNode or self:getTypeIsEndType(respinNode.m_lastNode.p_symbolType) == false then
                        --idle
                    else 
                        --lock
                        newlockNum = newlockNum + 1
                    end
                else

                end
            end
        end
    end
    return newlockNum
end

--重写
function DragonParadeRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    -- local timesCnt = 0 --几次快滚的时间

    -- local quickCols = {0,0,0,0,0}
    -- for j=1,#self.m_respinNodes do
    --     local repsinNode = self.m_respinNodes[j]
    --     if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
    --         if repsinNode.m_isQuick then
    --             if quickCols[repsinNode.p_colIndex] then
    --                 quickCols[repsinNode.p_colIndex] = 1
    --             end
    --         end
    --     end
    -- end
    --获取之前的快滚列
    -- local getQuickRunColTimes = function(col)
    --     local quickColTimes = 0
    --     local unQuickColTimes = 0
    --     local beginQuick = false
    --     for i=1,#quickCols do
    --         if i < col then
    --             if quickCols[i] == 1 then
    --                 quickColTimes = quickColTimes + 1
    --                 beginQuick = true
    --             end
    --             if beginQuick and quickCols[i] == 0 then
    --                 unQuickColTimes = unQuickColTimes + 1
    --             end
    --         end
    --     end
    --     return quickColTimes,unQuickColTimes
    -- end
    for j=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[j]
            local bFix = false 
            local runLong = self.m_baseRunNum + (repsinNode.p_colIndex - 1) * BASE_COL_INTERVAL

            --改
            -- if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 0 then
            --     local speed = 2000
            --     local resTime = 0.76 --回弹时间
            --     local longRunTime = 2
            --     local quickRunInterval = math.ceil(longRunTime * speed * 3 / 140)
            --     local normalRunInterval = math.ceil(longRunTime * speed / 140)
            --     local hIntervalNormal = math.ceil(resTime * speed / 140) --间隔块

            --     local quickCols, unQuickCols = getQuickRunColTimes(repsinNode.p_colIndex)

            --     --回弹需要间隔的块数 同时只有一个快滚了 都按normal速度计算
            --     local resQuickH2 = quickCols * hIntervalNormal
            --     local normalInterval = quickCols * normalRunInterval
            --     -- local longH = quickCols*hInterval
            --     if repsinNode.m_isQuick then
            --         runLong = runLong + normalInterval + quickRunInterval + resQuickH2
            --     else
            --         runLong = runLong + normalInterval + resQuickH2
            --     end
            -- end
            if repsinNode.m_isQuick then
                local longRunTime = 2
                local speed = 1500
                local quickRunInterval = math.ceil(longRunTime * speed * 3 / 140)
                runLong = runLong + quickRunInterval
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


--组织滚动信息 开始滚动
function DragonParadeRespinView:startMove()

    self.m_bonusSoundArray = {false, false, false, false, false}
    self.m_bonusSoundQuickPlayed = false
    self.m_quickStopMark = false
    self.m_reelQuickPlayed = false

    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0

    self.m_quickRunNode = nil

    -- local minRunCol = 5
    local unLockNodes = {}
    for i=1,#self.m_respinNodes do
          if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                self.m_respinNodes[i]:startMove()


                self.m_respinNodes[i]:changeRunQuick(false)
                self.m_respinNodes[i]:changeRunSpeed(false)
                unLockNodes[#unLockNodes + 1] = self.m_respinNodes[i]

          end
    end

    local isPlayQuickSound = false
    if #unLockNodes == 1 then

        unLockNodes[1]:showTip()
        unLockNodes[1]:changeRunQuick(true)
        unLockNodes[1]:changeRunSpeed(true)
        isPlayQuickSound = true

        self.m_quickRunNode = unLockNodes[1]

        self.m_quick_soundid = gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_quickrun_edge_run.mp3")
    else

        for k,unlockNode in pairs(unLockNodes) do
            unlockNode:hideTip()
        end
    end
    if isPlayQuickSound then
        self:quickRunSound(true)
    end
end

function DragonParadeRespinView:getQuickRunNode(  )
    return self.m_quickRunNode
end

function DragonParadeRespinView:oneReelDown(colIndex)

    --更新新增数量
    local newFixedNum = self:getColOnlyNewAddNum(colIndex)
    self.m_machine:respinOneReelDown( colIndex, newFixedNum )

    -- self:quickRunSound(false)

    if self.m_quickStopMark then
        if self.m_reelQuickPlayed == false then
            self.m_reelQuickPlayed = true
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_reel_down_quick.mp3")
        end
    else
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_reel_down.mp3")
    end

end
--后续列中哪列有 unlock
function DragonParadeRespinView:checkColHaveUnlockNode(col)
    local minCol = 5
    for i=1,#self.m_respinNodes do
        if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            if self.m_respinNodes[i].p_colIndex > col then
                if self.m_respinNodes[i].p_colIndex < minCol then
                    minCol = self.m_respinNodes[i].p_colIndex
                end
            end
        end
    end
    return minCol
end

function DragonParadeRespinView:quickRunSound(_isShow)
    -- if _isShow then
    --       self.m_quickRunSoundId = gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_longRun.mp3")
    -- else
    --       if self.m_quickRunSoundId then
    --             gLobalSoundManager:stopAudio(self.m_quickRunSoundId)
    --             self.m_quickRunSoundId = nil
    --       end
    -- end
end

function DragonParadeRespinView:playSound(endNode)

      local col = endNode.p_cloumnIndex
      
      if col < 1 or col > 5 then
            return
      end

      if self.m_quickStopMark == true then
            if self.m_bonusSoundQuickPlayed == false then
                  self.m_bonusSoundQuickPlayed = true
                  gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_bonus_bulling.mp3")
            end
      else
            if self.m_bonusSoundArray[col] == false then
                  self.m_bonusSoundArray[col] = true
                  gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_bonus_bulling.mp3")
            end
      end
      
end

function DragonParadeRespinView:quicklyStop()
    self.m_quickStopMark = true
    DragonParadeRespinView.super.quicklyStop(self)
end

--隐藏快滚框
function DragonParadeRespinView:hideAllTip(  )
    for i=1,#self.m_respinNodes do
        if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            self.m_respinNodes[i]:hideTip()
        end
    end
end

return DragonParadeRespinView