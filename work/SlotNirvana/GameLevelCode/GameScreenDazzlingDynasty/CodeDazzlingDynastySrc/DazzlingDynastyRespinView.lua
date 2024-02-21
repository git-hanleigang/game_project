local CodeGameScreenDazzlingDynastyMachine = util_require("CodeGameScreenDazzlingDynastyMachine")
local RespinView = util_require("Levels.RespinView")
local DazzlingDynastyRespinView = class("DazzlingDynastyRespinView", RespinView)

DazzlingDynastyRespinView.m_lastTriggerInfo = nil

function DazzlingDynastyRespinView:setExtraInfo(machine)
    self.m_machine = machine
    self.bonusTopUI = machine.bonusTopUI
    self.bonusFreeSpinBar = machine.bonusFreeSpinBar
end

function DazzlingDynastyRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    RespinView.initRespinElement(self, machineElement, machineRow, machineColmn, startCallFun)
    
    self.m_lastTriggerInfo = {}
    --+1Spin的UI层级置换列表，在停止时放到最上面，滚动时还原
    self.addSpinNodeTransList = {}

    self:__setPlayBulingAnimCount(0)
    local machine = self.m_machine
    local respinTimes = machine.m_iRespinTimes
    if respinTimes ~= nil then
        -- respinTimes = respinTimes
    else
        respinTimes = machine.m_runSpinResultData.p_reSpinCurCount
    end
    self.respinTimes = respinTimes
    machine:changeReSpinUpdateUI(respinTimes)
    self:__setTopScoreUI()
    self:__startRandomSpecialAnim()
end

function DazzlingDynastyRespinView:__setTopScoreUI()
    local machine = self.m_machine
    local lockNodeList = self:getAllCleaningNode()
    local leftScore = 0
    local rightScore = 0
    local bonusSymbolLevel1Count = 0
    local totalBet = globalData.slotRunData:getCurTotalBet()
    for k,v in ipairs(lockNodeList) do
        local symbolType = v.p_symbolType
        if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1 or symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2 or
            symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 or symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or 
            symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
            local _,score = machine:getScoreInfoByPos(v.p_rowIndex, v.p_cloumnIndex)
            if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1 then
                leftScore = leftScore + score
                bonusSymbolLevel1Count = bonusSymbolLevel1Count + 1
            end
            rightScore = rightScore + score
        end
    end
    self.bonusSymbolLevel1Count = bonusSymbolLevel1Count
    local goldScore = rightScore / 60 * totalBet
    self.bonusTopUI:setTopScore(leftScore,rightScore,goldScore)
end

function DazzlingDynastyRespinView:__addTopRightScore(score)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local goldScore = score / 60 * totalBet
    self.bonusTopUI:addTopScore(nil,score,goldScore)
end

function DazzlingDynastyRespinView:readyMove()
    local machine = self.m_machine
    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_startCallFunc then
        self.m_startCallFunc()
    end
end

function DazzlingDynastyRespinView:__setPlayBulingAnimCount(count)
    self.bulingAnimCount = count
end

function DazzlingDynastyRespinView:getPlayBulingAnimCount()
    return self.bulingAnimCount
end

function DazzlingDynastyRespinView:__addPlayBulingAnimCount(count)
    self:__setPlayBulingAnimCount(self:getPlayBulingAnimCount() + count)
end

function DazzlingDynastyRespinView:startMove()
    local machine = self.m_machine
    if self.respinTimes ~= nil then
        machine:changeReSpinUpdateUI(self.respinTimes - 1)
        self.respinTimes = nil
    end
    self:__backToAddSpinParent()
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

function DazzlingDynastyRespinView:__backToAddSpinParent()
    local addSpinNodeTransList = self.addSpinNodeTransList
    while #addSpinNodeTransList > 0 do
        local info = addSpinNodeTransList[1]
        local endNode = info.node
        endNode:removeFromParent()
        info.parentNode:addChild(endNode,info.zOrder,info.tag)
        endNode:setPosition(info.position)
        table.remove(addSpinNodeTransList,1)
    end
end

--repsinNode滚动完毕后 置换层级
function DazzlingDynastyRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    local symbolType = endNode.p_symbolType
    local machine = self.m_machine
    if status == RESPIN_NODE_STATUS.LOCK or symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN then
        if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN then
            table.insert(self.addSpinNodeTransList,
            {
                node = endNode,
                parentNode = endNode:getParent(),
                zOrder = endNode:getLocalZOrder(),
                tag = endNode:getTag(),
                position = cc.p(endNode:getPosition())
            })
        end
        local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
        local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN then
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex + machine:formatAddSpinSymbol(symbolType))
        else
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex + endNode.p_cloumnIndex + machine:formatAddSpinSymbol(symbolType))
        end
        endNode:setTag(self.REPIN_NODE_TAG)
        endNode:setPosition(pos)
    end
    self:runNodeEnd(endNode)

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
       gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
    end
end

function DazzlingDynastyRespinView:runNodeEnd(endNode)
    local symbolType = endNode.p_symbolType
    if self:getTypeIsEndType(symbolType) or symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN then
        local rowIndex = endNode.p_rowIndex
        local colIndex = endNode.p_cloumnIndex
        local key = self.m_machine:getPosReelIdx(rowIndex,colIndex)
        self.m_lastTriggerInfo[key] = endNode
        self:__addPlayBulingAnimCount(1)
        endNode:runAnim(
        "buling",
        false,
        function()
            self:__addPlayBulingAnimCount(-1)
            if self:getPlayBulingAnimCount() == 0 then
                self:__safeResumeAcitonCor()
            end
        end)
        if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2 or symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 or symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or 
        symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
            gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Bonus_Down.mp3")
        elseif symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN then
            gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_addSpin_Down.mp3")
        end
    end    
end

function DazzlingDynastyRespinView:oneReelDown(colIndex)
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_ReelStop.mp3")
end

 --随机特定数量播放特殊信号的idleframe
function DazzlingDynastyRespinView:__startRandomSpecialAnim()
    scheduler.unschedulesByTargetName("DazzlingDynastyRespinView_respin_bonus_action")
    scheduler.performWithDelayGlobal(function()
        self:__playRandomSpecialNodeAction()
        self:__startRandomSpecialAnim()
    end, math.random(2,5), "DazzlingDynastyRespinView_respin_bonus_action")
end

function DazzlingDynastyRespinView:__playRandomSpecialNodeAction()
    local lastTriggerInfo = self.m_lastTriggerInfo
    local fixSymbolNodeList = self:getFixSlotsNode()
    local fixSymbolNodeKey = {}
    for k,v in ipairs(fixSymbolNodeList) do
        local lbScore = v:getCcbProperty("m_lb_score")
        if lbScore ~= nil and lbScore:isVisible() then
            table.insert(fixSymbolNodeKey,k)
        end
    end
    local randomCount = math.random(1,3)
    for i = 1,randomCount do
        local randIndex = math.random(1,#fixSymbolNodeKey)
        local randKey = fixSymbolNodeKey[randIndex]
        local symbolNode = fixSymbolNodeList[randKey]
        symbolNode:runAnim("idleframe")
        table.remove(fixSymbolNodeKey,randIndex)
    end
end

function DazzlingDynastyRespinView:handleTriggerResult(callBack)
    local machine = self.m_machine
    local bonusFreeSpinBar = self.bonusFreeSpinBar
    local machineRootParent = machine.m_root:getParent()
    local bonusFreeSpinBarPosX,bonusFreeSpinBarPosY = self.bonusFreeSpinBar:getParent():getPosition()
    local actionCor = coroutine.create(function()
        local lockNodeList = self:getAllCleaningNode()
        local lockNodeCount = #lockNodeList
        local bonusSymbolLevel1Count = self.bonusSymbolLevel1Count
        local isMulRate = bonusSymbolLevel1Count > 11
        local lastTriggerInfo = self.m_lastTriggerInfo
        local lastTriggerInfoList = self:__getSortLastTrigInfo()
        local addSpinAnimCount = 0
        --播放+1spin收集动画
        for k,v in ipairs(lastTriggerInfoList) do
            local key = v.key
            local value = v.value
            local valueSymbolType = value.p_symbolType
            if valueSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN or
                valueSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or
                valueSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
                addSpinAnimCount = addSpinAnimCount + 1
                local sprAddSpin = value:getCcbProperty("DazzlingDynasty_spin02_1")
                sprAddSpin:setVisible(valueSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN)
                local lockNodePos = value:getParent():convertToWorldSpace(cc.p(value:getPosition()))
                local lockNodePosX,lockNodePosY = lockNodePos.x,lockNodePos.y
                local sprAddSpinAnim = display.newSprite("#Symbol/DazzlingDynasty_spin02.png",lockNodePosX,lockNodePosY)
                machineRootParent:addChild(sprAddSpinAnim,REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
                local conPos = cc.p(lockNodePosX <= bonusFreeSpinBarPosX and lockNodePosX + 20 or lockNodePosX - 20,lockNodePosY - 100)
                local moveAct = cc.BezierTo:create(0.5,{conPos,conPos,cc.p(bonusFreeSpinBarPosX,bonusFreeSpinBarPosY)})
                sprAddSpinAnim:runAction(
                    cc.Spawn:create(
                    cc.CallFunc:create(function() 
                        if valueSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN  then
                            value:runAnim("actionframe",false,
                            function()
                                value:runAnim("idle2",true)
                            end)
                        end
                    end),
                    cc.ScaleTo:create(0.5,0.5),
                    cc.Sequence:create(moveAct,
                    cc.CallFunc:create(function(sender)
                        sender:removeFromParent()
                        addSpinAnimCount = addSpinAnimCount - 1
                        bonusFreeSpinBar:playCollectEffect()
                        machine:changeReSpinUpdateUI(machine.m_runSpinResultData.p_reSpinCurCount)
                        if addSpinAnimCount == 0 then
                            performWithDelay(self,handler(self,self.__safeResumeAcitonCor),1)
                        end
                    end)
                )))
                gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_collect_addSpin.mp3")
            end
        end
        if addSpinAnimCount > 0 then
            coroutine.yield()
        end

        --播放累加动画
        local totalCoin = 0
        for k,v in ipairs(lastTriggerInfoList) do
            local key = v.key
            local value = v.value
            local valueSymbolType = machine:formatAddSpinSymbol(value.p_symbolType)
            if valueSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2 or 
                valueSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 then
                local coin = 0
                local vPos = machine:getNodePosByColAndRow(value.p_rowIndex,value.p_cloumnIndex)
                local lbChangeNode = value:getCcbProperty("m_lb_score")
                for kk,vv in ipairs(lockNodeList) do
                    coin = self:__handleBonusAnimation(isMulRate,value,vv,vPos,lbChangeNode,coin)
                end
                if (valueSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3) and isMulRate then
                    coin = coin * (bonusSymbolLevel1Count - 9)
                    lbChangeNode:setString(coin)
                end
                totalCoin = totalCoin + coin
                
                performWithDelay(self,handler(self,self.__safeResumeAcitonCor),1)
                coroutine.yield()
            end
            lastTriggerInfo[key] = nil
        end
        self.actionCor = nil
        --矫正下数值
        if totalCoin > 0 then
            self:__addTopRightScore(totalCoin)
        end
        callBack()
    end)
    self.actionCor = actionCor
    if self:getPlayBulingAnimCount() == 0 then
        self:__safeResumeAcitonCor()
    end
end

function DazzlingDynastyRespinView:__safeResumeAcitonCor()
    util_resumeCoroutine(self.actionCor)
end

function DazzlingDynastyRespinView:__handleBonusAnimation(isMulRate,changeNode,lockNode,changeNodePos,lbChangeNode,coin)
    local machine = self.m_machine
    local changeNodeSymbolType = machine:formatAddSpinSymbol(changeNode.p_symbolType)
    local lockNodeSymbolType = machine:formatAddSpinSymbol(lockNode.p_symbolType)
    local lbLockNode = lockNode:getCcbProperty("m_lb_score")
    local flag = lockNodeSymbolType ~= CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 and lockNodeSymbolType < changeNodeSymbolType
    flag = flag or (changeNodeSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 and lockNodeSymbolType <= changeNodeSymbolType)
    if flag and changeNode ~= lockNode and lbLockNode:isVisible() then
        local moveActionNode = util_createView("GameScreenDazzlingDynasty.CodeDazzlingDynastySrc.DazzlingDynastyBonusScore")
        self:addChild(moveActionNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
        moveActionNode:setMachineInfo(machine)
        local lockNodePos = machine:getNodePosByColAndRow(lockNode.p_rowIndex,lockNode.p_cloumnIndex)
        moveActionNode:setPosition(lockNodePos)
        local _,score = machine:getScoreInfoByPos(lockNode.p_rowIndex, lockNode.p_cloumnIndex)
        coin = coin + score
        moveActionNode:playAnimation(lockNodeSymbolType,score,changeNodePos,
        function()
            lbChangeNode:setVisible(true)
            lbChangeNode:setString(coin)
            changeNode:runAnim("shouji2",false)
        end,nil)
        performWithDelay(self,handler(self,self.__safeResumeAcitonCor),0.5)
        if lockNodeSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1 then
            gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_collect_Bonus_Lv1.mp3")
        elseif lockNodeSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2 then
            gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_collect_Bonus_Lv2.mp3")
        elseif lockNodeSymbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 then
            gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_collect_Bonus_Lv3.mp3")
        end
        coroutine.yield()
    end
    return coin
end

function DazzlingDynastyRespinView:__getSortLastTrigInfo()
    local machine = self.m_machine
    local lastTriggerInfo = self.m_lastTriggerInfo
    local sortTriggerInfoList = {}
    for k,v in pairs(lastTriggerInfo) do
        table.insert(sortTriggerInfoList,{key = k,value = v})
    end
    table.sort(sortTriggerInfoList,function(a,b)
        local key1 = a.key
        local key2 = b.key
        local aNode = a.value
        local bNode = b.value
        local aSymbolType = machine:formatAddSpinSymbol(aNode.p_symbolType)
        local bSymbolType = machine:formatAddSpinSymbol(bNode.p_symbolType)
        local aRowIndex = aNode.p_rowIndex
        local bRowIndex = bNode.p_rowIndex
        local aColIndex = aNode.p_cloumnIndex
        local bColIndex = bNode.p_cloumnIndex
        if aSymbolType == bSymbolType then
            if aRowIndex == bRowIndex then
                return aColIndex < bColIndex
            else
                if aColIndex == bColIndex then
                    return aRowIndex > bRowIndex
                else
                    return aColIndex < bColIndex
                end
            end
        else
            return aSymbolType < bSymbolType
        end
    end)
    return sortTriggerInfoList
end

---获取所有参与结算节点
function DazzlingDynastyRespinView:getAllCleaningNode()
    --从 从上到下 左到右排序
    local cleaningNodes = {}
    local childs = self:getChildren()
    local machine = self.m_machine
    for k, v in ipairs(childs) do
        if v:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(v.p_rowIndex, v.p_cloumnIndex) then
            table.insert(cleaningNodes, v)
        end
    end
    --排序
    table.sort(cleaningNodes,function(a,b)
        local aRowIndex = a.p_rowIndex
        local bRowIndex = b.p_rowIndex
        local aColIndex = a.p_cloumnIndex
        local bColIndex = b.p_cloumnIndex
        local aSymbolType = machine:formatAddSpinSymbol(a.p_symbolType)
        local bSymbolType = machine:formatAddSpinSymbol(b.p_symbolType)
        if aSymbolType == bSymbolType then
            if aRowIndex == bRowIndex then
                return aColIndex < bColIndex
            else
                if aColIndex == bColIndex then
                    return aRowIndex > bRowIndex
                else
                    return aColIndex < bColIndex
                end
            end
        else
            return aSymbolType < bSymbolType
        end
    end)
    return cleaningNodes
end

function DazzlingDynastyRespinView:__getBonusSymbolCount(symbolType)
    local cleaningNodes = self:getAllCleaningNode()
    local count = 0
    for k,v in ipairs(cleaningNodes) do
        local vSymbolType = v.p_symbolType
        if vSymbolType == symbolType then
            count = count + 1
        end
    end
    return count
end

function DazzlingDynastyRespinView:onExit()
    scheduler.unschedulesByTargetName("DazzlingDynastyRespinView_respin_bonus_action")
    RespinView.onExit(self)
end

return DazzlingDynastyRespinView
