---
--xcyy
--2018年5月23日
--PalaceWishRespinView.lua
local PublicConfig = require "PalaceWishPublicConfig"
local PalaceWishRespinView = class("PalaceWishRespinView",util_require("Levels.RespinView"))

local BASE_COL_INTERVAL = 3

local VIEW_ZORDER = 
{
    NORMAL = 100,
    REPSINNODE = 1,
}

function PalaceWishRespinView:ctor()
    PalaceWishRespinView.super.ctor(self)
end

--重写
function PalaceWishRespinView:initUI(respinNodeName)
    PalaceWishRespinView.super.initUI(self, respinNodeName)

    self.m_quickRunSoundId = nil
    self.m_colEffect = {}
    self.m_bonusSoundArray = {false, false, false, false, false}
    self.m_bonusSoundQuickPlayed = false
    self.m_quickStopMark = false
    self.m_reelQuickPlayed = false

    -- self.m_quickRunAni = util_createAnimation("PalaceWish_respin_dange.csb")
    -- self.m_quickRunAni:runCsbAction("actionframe", true)
    -- self:addChild(self.m_quickRunAni,10000)
    -- self.m_quickRunAni:setVisible(false)
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function PalaceWishRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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
          local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

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

function PalaceWishRespinView:createRespinNode(symbolNode, status)

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
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

    if symbolNode and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
        symbolNode:runAnim("idleframe2", true)
    end

    respinNode:addTipNode(self.m_machine.m_respinQuickEffect,self.m_machine:getPosReelIdx(respinNode.p_rowIndex, respinNode.p_colIndex))
end

--repsinNode滚动完毕后 置换层级
function PalaceWishRespinView:respinNodeEndCallBack(endNode, status)
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

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)


        
        local unLockNodes = {}
        local isHaveColOnly3, respinNode3 = self:checkColStaticOnlyOne(3)
        local isHaveColOnly4, respinNode4 = self:checkColStaticOnlyOne(4)
        local isHaveColOnly5, respinNode5 = self:checkColStaticOnlyOne(5)

        for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                -- self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                unLockNodes[#unLockNodes + 1] = self.m_respinNodes[i]
            end

            
            if self.m_machine.m_runSpinResultData.p_reSpinCurCount > 0 then
                if isHaveColOnly3 and respinNode3 == self.m_respinNodes[i] then
                elseif isHaveColOnly4 and respinNode4 == self.m_respinNodes[i] then
                elseif isHaveColOnly5 and respinNode5 == self.m_respinNodes[i] then
                else
                    self.m_respinNodes[i]:hideTip()
                end
            else
                self.m_respinNodes[i]:hideTip()
            end
            

            
        end

        if #unLockNodes == 1 and self.m_machine.m_runSpinResultData.p_reSpinCurCount > 0 then
            unLockNodes[1]:showTip()
        end

    end
end

function PalaceWishRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
        endNode:runAnim(info.runEndAnimaName, false)

        
    end
    if endNode then
        if self.m_machine:isFixSymbol(endNode.p_symbolType) then

            self:playSound(endNode)
            endNode:runAnim("buling",false,function(  )
                endNode:runAnim("idleframe2",true)
            end)
        end
    end

    -- body
end


---获取所有参与结算节点
function PalaceWishRespinView:getAllCleaningNode()
    local cleaningNodes = {}
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        local symbolNode = respinNode.m_baseFirstNode
        if symbolNode and symbolNode.p_symbolType and self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
            cleaningNodes[#cleaningNodes + 1] = symbolNode
        end
        
    end
    return cleaningNodes
end

--列是否剩一个
function PalaceWishRespinView:checkColOnlyOne(colIndex)
    local unlockNum = 0
    local respinRetNode = nil
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        if respinNode then
            if respinNode.p_colIndex == colIndex then
                if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                    --未锁定 oneReelDown在设置锁定前 所以要判断下
                    if not respinNode.m_lastNode or self:getTypeIsEndType(respinNode.m_lastNode.p_symbolType) == false then
                        --idle
                        unlockNum = unlockNum + 1
                        respinRetNode = respinNode
                    else 
                        --lock
                    end
                else

                end
            end
        end
    end
    if unlockNum == 1 then
        return true, respinRetNode
    else
        return false
    end
end
--列是否剩一个 在设置完锁定值处调用
function PalaceWishRespinView:checkColStaticOnlyOne(colIndex)
    local unlockNum = 0
    local respinRetNode = nil
    for index = 1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[index]
        if respinNode then
            if respinNode.p_colIndex == colIndex then
                if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                    unlockNum = unlockNum + 1
                    respinRetNode = respinNode
                else

                end
            end
        end
    end
    if unlockNum == 1 then
        return true, respinRetNode
    else
        return false
    end
end

--检测列全满
function PalaceWishRespinView:checkReelFull( colIndex )
    -- local colLock = true
    -- for index = 1,#self.m_respinNodes do
    --     local respinNode = self.m_respinNodes[index]
    --     if respinNode then
    --         if respinNode.p_colIndex == colIndex then
    --             if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
    --                 --未锁定 oneReelDown在设置锁定前 所以要判断下
    --                 if respinNode.m_lastNode and (not respinNode.m_lastNode or self:getTypeIsEndType(respinNode.m_lastNode.p_symbolType) == false) then
    --                     --idle
    --                     colLock = false
    --                     break
    --                 else 
    --                     --lock
    --                 end
    --             else

    --             end
    --         end
    --     end
    -- end

    -- return colLock


    --改用网络数据
    if self.m_machine and self.m_machine.m_runSpinResultData then
        local selfData =  self.m_machine.m_runSpinResultData.p_selfMakeData or {}
        if selfData.jackpots then
            local isMinor = false
            local isMajor = false
            local isGrand = false
            for i=1,#selfData.jackpots do
                if selfData.jackpots[i] == "Minor" then
                    isMinor = true
                end
                if selfData.jackpots[i] == "Major" then
                    isMajor = true
                end
                if selfData.jackpots[i] == "Grand" then
                    isGrand = true
                end
            end
            if colIndex == 3 then
                if isMinor then
                    return true
                end
            elseif colIndex == 4 then
                if isMajor then
                    return true
                end
            elseif colIndex == 5 then
                if isGrand then
                    return true
                end
            end
        end
    end
    
    return false
end

--重写
function PalaceWishRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    local timesCnt = 0 --几次快滚的时间

    local quickCols = {0,0,0,0,0}
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            if repsinNode.m_isQuick then
                if quickCols[repsinNode.p_colIndex] then
                    quickCols[repsinNode.p_colIndex] = 1
                end
            end
        end
    end
    --获取之前的快滚列
    local getQuickRunColTimes = function(col)
        local quickColTimes = 0
        local unQuickColTimes = 0
        local beginQuick = false
        for i=1,#quickCols do
            if i < col then
                if quickCols[i] == 1 then
                    quickColTimes = quickColTimes + 1
                    beginQuick = true
                end
                if beginQuick and quickCols[i] == 0 then
                    unQuickColTimes = unQuickColTimes + 1
                end
            end
        end
        return quickColTimes,unQuickColTimes
    end
    for j=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[j]
            local bFix = false 
            local runLong = self.m_baseRunNum + (repsinNode.p_colIndex - 1) * BASE_COL_INTERVAL

            --改
            if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 0 then
                local speed = 2000
                local resTime = 0.76 --回弹时间
                local longRunTime = 2
                local quickRunInterval = math.ceil(longRunTime * speed * 3 / 140)
                local normalRunInterval = math.ceil(longRunTime * speed / 140)
                local hIntervalNormal = math.ceil(resTime * speed / 140) --间隔块

                local quickCols, unQuickCols = getQuickRunColTimes(repsinNode.p_colIndex)

                --回弹需要间隔的块数 同时只有一个快滚了 都按normal速度计算
                local resQuickH2 = quickCols * hIntervalNormal
                local normalInterval = quickCols * normalRunInterval
                -- local longH = quickCols*hInterval
                if repsinNode.m_isQuick then
                    runLong = runLong + normalInterval + quickRunInterval + resQuickH2
                else
                    runLong = runLong + normalInterval + resQuickH2
                end
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
function PalaceWishRespinView:startMove()

    self.m_bonusSoundArray = {false, false, false, false, false}
    self.m_bonusSoundQuickPlayed = false
    self.m_quickStopMark = false
    self.m_reelQuickPlayed = false

    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0

    local minRunCol = 5
    local unLockNodes = {}
    for i=1,#self.m_respinNodes do
          if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                self.m_respinNodes[i]:startMove()


                self.m_respinNodes[i]:changeRunSpeed(false)
                unLockNodes[#unLockNodes + 1] = self.m_respinNodes[i]

                if self.m_respinNodes[i].p_colIndex < minRunCol then
                    minRunCol = self.m_respinNodes[i].p_colIndex
                end
          end
    end

    local isPlayQuickSound = false
    if #unLockNodes == 1 then
        -- self.m_quickRunAni:setPosition(cc.p(unLockNodes[1]:getPosition()))

        
        if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 1 then

            unLockNodes[1]:showTip()
            unLockNodes[1]:changeRunQuick(true)
            if minRunCol == unLockNodes[1].p_colIndex then
                unLockNodes[1]:changeRunSpeed(true)
                isPlayQuickSound = true
                unLockNodes[1]:showTip("last")
            end
            
        else
            unLockNodes[1]:showTip()
        end

        
    else
        local isHaveColOnly3, respinNode3 = self:checkColStaticOnlyOne(3)
        local isHaveColOnly4, respinNode4 = self:checkColStaticOnlyOne(4)
        local isHaveColOnly5, respinNode5 = self:checkColStaticOnlyOne(5)
        for k,unlockNode in pairs(unLockNodes) do
            if isHaveColOnly3 and respinNode3 == unlockNode then
                if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 1 then
                    respinNode3:showTip()
                    respinNode3:changeRunQuick(true)
                    if minRunCol == respinNode3.p_colIndex then
                        respinNode3:changeRunSpeed(true)
                        isPlayQuickSound = true
                        respinNode3:showTip("last")
                    end
                    
                end
            elseif isHaveColOnly4 and respinNode4 == unlockNode then
                if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 1 then
                    respinNode4:showTip()
                    respinNode4:changeRunQuick(true)
                    if minRunCol == respinNode4.p_colIndex then
                        respinNode4:changeRunSpeed(true)
                        isPlayQuickSound = true
                        respinNode4:showTip("last")
                    end
                end
            elseif isHaveColOnly5 and respinNode5 == unlockNode then
                if self.m_machine.m_runSpinResultData.p_reSpinCurCount == 1 then
                    respinNode5:showTip()
                    respinNode5:changeRunQuick(true)
                    if minRunCol == respinNode5.p_colIndex then
                        respinNode5:changeRunSpeed(true)
                        isPlayQuickSound = true
                        respinNode5:showTip("last")
                    end
                end
            else
                unlockNode:hideTip()
            end
        end
    end
    if isPlayQuickSound then
        self:quickRunSound(true)
    end
end

function PalaceWishRespinView:oneReelDown(colIndex)
    --列是否全满
    if colIndex == 3 or colIndex == 4 or colIndex == 5 then
        if self.m_colEffect and self.m_colEffect[colIndex] == nil then
            local isFull, score = self:checkReelFull(colIndex)
            if isFull then
                self.m_machine:showRespinCollectColFullEffect( colIndex, true )
                self.m_machine:showJackpotRoofAnim( 6-colIndex, "actionframe", "actionframe" )
                self.m_colEffect[colIndex] = 1

                --去框
                for index = 1,#self.m_respinNodes do
                    local respinNode = self.m_respinNodes[index]
                    if respinNode then
                        if respinNode.p_colIndex == colIndex then
                            respinNode:hideTip()
                        end
                    end
                end
            end
        end

        --检测列差一个全满
        local isHaveOnlyOne, respinNode = self:checkColOnlyOne(colIndex)
        if isHaveOnlyOne and respinNode then
            respinNode:showTip()
        end
    end

    -- if colIndex == 5 then
        self:quickRunSound(false)
    -- end

    if self.m_quickStopMark then
        if self.m_reelQuickPlayed == false then
            self.m_reelQuickPlayed = true
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_reel_down_quick.mp3")
        end
    else
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_reel_down.mp3")
    end
    
    --快滚提速
    if colIndex >= 1 and colIndex < 5 and self.m_machine.m_runSpinResultData.p_reSpinCurCount == 0 then
        -- local unLockColNodes = {}
        local col = self:checkColHaveUnlockNode(colIndex)
        for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                if self.m_respinNodes[i].p_colIndex == col and self.m_respinNodes[i].m_isQuick then
                    self.m_respinNodes[i]:changeRunSpeed(true)
                    self:quickRunSound(true)
                    self.m_respinNodes[i]:showTip("last")
                end
            end
        end
    end
    
end
--后续列中哪列有 unlock
function PalaceWishRespinView:checkColHaveUnlockNode(col)
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

function PalaceWishRespinView:quickRunSound(_isShow)
    if _isShow then
          self.m_quickRunSoundId = gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_longRun.mp3")
    else
          if self.m_quickRunSoundId then
                gLobalSoundManager:stopAudio(self.m_quickRunSoundId)
                self.m_quickRunSoundId = nil
          end
    end
end

function PalaceWishRespinView:playSound(endNode)

      local col = endNode.p_cloumnIndex
      
      if col < 1 or col > 5 then
            return
      end

      if self.m_quickStopMark == true then
            if self.m_bonusSoundQuickPlayed == false then
                  self.m_bonusSoundQuickPlayed = true
                  gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_bonus_buling.mp3")
            end
      else
            if self.m_bonusSoundArray[col] == false then
                  self.m_bonusSoundArray[col] = true
                  gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_bonus_buling.mp3")
            end
      end
      
end

function PalaceWishRespinView:quicklyStop()
    self.m_quickStopMark = true
    PalaceWishRespinView.super.quicklyStop(self)
end

-- function PalaceWishRespinView:clearEffectData(  )
--     self.m_colEffect = {}
-- end

return PalaceWishRespinView