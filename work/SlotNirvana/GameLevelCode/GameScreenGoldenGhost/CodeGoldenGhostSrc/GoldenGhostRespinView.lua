local CodeGameScreenGoldenGhostMachine = util_require("CodeGameScreenGoldenGhostMachine")
local RespinView = util_require("Levels.RespinView")
local GoldenGhostRespinView = class("GoldenGhostRespinView", RespinView)

GoldenGhostRespinView.m_lastTriggerInfo = nil
GoldenGhostRespinView.m_totalScore = 0
GoldenGhostRespinView.m_prelockNodeList = nil
GoldenGhostRespinView.m_totalLockScore = nil
GoldenGhostRespinView.collectTime = 20 / 60
GoldenGhostRespinView.collectTime2 = 10 / 60
--开始滚动时的轮盘信号
GoldenGhostRespinView.m_lastReels = {}

function GoldenGhostRespinView:onExit()
    scheduler.unschedulesByTargetName("GoldenGhostRespinView_respin_bonus_action")
    RespinView.onExit(self)
end

function GoldenGhostRespinView:readyMove()
    local machine = self.m_machine
    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_startCallFunc then
        self.m_startCallFunc()
    end
end


function GoldenGhostRespinView:startMove()
    local machine = self.m_machine
    self.m_lastReels = clone(self.m_machine.m_runSpinResultData.p_reels or {})
    if self.respinTimes ~= nil then
        machine:changeReSpinUpdateUI(self.respinTimes - 1)
        self.respinTimes = nil
    end
    self:backToAddSpinParent()
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

function GoldenGhostRespinView:setExtraInfo(machine)
    self.m_machine = machine
    self.bonusTopUI = machine.bonusTopUI
    -- self.bonusFreeSpinBar = machine.bonusFreeSpinBar
    self.bonusFreeSpinBar = machine.bonusRespinBar
    -- self:addFreeSpinLbAni()
end

-- function GoldenGhostRespinView:addFreeSpinLbAni( ... )
--     -- body
--     local freeSpinLb = self.bonusFreeSpinBar.findChild("m_lb_num_0")
--     local freeSpinLbPos = cc.p(freeSpinLb:getPosition())
--     self.freeSpinLbAni = util_createAnimation( "GoldenGhost_freespin_add.csb" )
--     self.freeSpinLbAni:setPosition(freeSpinLbPos)
--     freeSpinLb:getParent():addChild(self.freeSpinLbAni,freeSpinLb:getLocalZOrder() - 1)
-- end

function GoldenGhostRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    RespinView.initRespinElement(self, machineElement, machineRow, machineColmn, startCallFun)
    
    self.m_lastTriggerInfo = {}
    --+1Spin的UI层级置换列表，在停止时放到最上面，滚动时还原
    self.addSpinNodeTransList = {}

    self:setPlayBulingAnimCount(0)
    local machine = self.m_machine
    local respinTimes = machine.m_iRespinTimes
    if respinTimes ~= nil then
        -- respinTimes = respinTimes
    else
        respinTimes = machine.m_runSpinResultData.p_reSpinCurCount
    end
    self.respinTimes = respinTimes
    machine:changeReSpinUpdateUI(respinTimes)
    self:setTopScoreUI()
    -- self.m_prelockNodeList = self:getAllCleaningNode()
end

function GoldenGhostRespinView:setTopScoreUI()
    local machine = self.m_machine
    local lockNodeList = self:getAllCleaningNode()
    local leftScore = 0
    local rightScore = 0
    local bonusSymbolLevel1Count = 0
    local totalBet = globalData.slotRunData:getCurTotalBet()
    for k,v in ipairs(lockNodeList) do
        local symbolType = v.p_symbolType
        if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 or symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 or
            symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 or symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or 
            symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
            local score = machine:getScoreInfoByPos(v.p_rowIndex, v.p_cloumnIndex)
            if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
                leftScore = leftScore + score
                bonusSymbolLevel1Count = bonusSymbolLevel1Count + 1
            end
            rightScore = rightScore + score
        end
    end
    self.bonusSymbolLevel1Count = bonusSymbolLevel1Count
    -- local goldScore = rightScore * totalBet
    local goldScore = machine:getCoinsNumByScore(rightScore)
    self.bonusTopUI:setTopScore(leftScore,rightScore,goldScore)
end

function GoldenGhostRespinView:setPlayBulingAnimCount(count)
    self.bulingAnimCount = count
end

function GoldenGhostRespinView:addRightScore(score)
    self.bonusTopUI:addTopScore(nil,score,nil)
end

function GoldenGhostRespinView:addTopScore(score)
    -- local totalBet = globalData.slotRunData:getCurTotalBet()
    -- local goldScore = score * totalBet
    local goldScore = self.m_machine:getCoinsByScore(score)
    self.bonusTopUI:addTopScore(nil,score,goldScore)
end

function GoldenGhostRespinView:addPlayBulingAnimCount(count)
    self:setPlayBulingAnimCount(self:getPlayBulingAnimCount() + count)
end

function GoldenGhostRespinView:getPlayBulingAnimCount()
    return self.bulingAnimCount
end

function GoldenGhostRespinView:backToAddSpinParent()
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
function GoldenGhostRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    local symbolType = endNode.p_symbolType
    local machine = self.m_machine
    if status == RESPIN_NODE_STATUS.LOCK or symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN then
        if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN then
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

        if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN then
            local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + endNode.p_cloumnIndex + machine:formatAddSpinSymbol(symbolType)
            util_changeNodeParent(self,endNode,zOrder)
        else
            local zOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - endNode.p_rowIndex + endNode.p_cloumnIndex + machine:formatAddSpinSymbol(symbolType)
            util_changeNodeParent(self,endNode,zOrder)
        end
        endNode:setTag(self.REPIN_NODE_TAG)
        endNode:setPosition(pos)
    end
    self:runNodeEnd(endNode)
    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
       gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
    end
end

function GoldenGhostRespinView:runNodeEnd(endNode)
    local symbolType = endNode.p_symbolType

    if self:getTypeIsEndType(symbolType) or symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN then
        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig

        endNode:runAnim(
        "buling",
        false,
        function()
            endNode:runAnim("idleframe",true)
        end)
        if  symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 or  
            symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 then
            
            local count,lastPos = self:getSymbolCountAndLastPos(symbolType)
            if lastPos.iY == endNode.p_cloumnIndex and lastPos.iX == endNode.p_rowIndex then
                local soundName = count <= 1 and levelConfig.Sound_Buling_BonusGreen_One or levelConfig.Sound_Buling_BonusGreen_More
                gLobalSoundManager:playSound(soundName)
            end
            
        elseif  symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 or
                symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
            
            local count,lastPos = self:getSymbolCountAndLastPos(symbolType)
            if lastPos.iY == endNode.p_cloumnIndex and lastPos.iX == endNode.p_rowIndex then
                local soundName = count <= 1 and levelConfig.Sound_Buling_BonusYellow_One or levelConfig.Sound_Buling_BonusYellow_More
                gLobalSoundManager:playSound(soundName)
            end

        elseif symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN then
            gLobalSoundManager:playSound(levelConfig.Sound_Buling_AddSpinTimes)
        end

        local rowIndex = endNode.p_rowIndex
        local colIndex = endNode.p_cloumnIndex
        local key = self.m_machine:getPosReelIdx(rowIndex,colIndex)
        self.m_lastTriggerInfo[key] = endNode
    end    
end
--获取 新滚出的 一个信号的数量和最后一个该类型信号的位置
function GoldenGhostRespinView:getSymbolCountAndLastPos(_symbolType)
    local count,lastPos = 0,{iX = 1, iY = 1}
    local p_reels = self.m_machine.m_runSpinResultData.p_reels or {}
    for iLine,_lineData in ipairs(p_reels) do
        local iRow = #p_reels + 1 - iLine
        for iCol,symbolType in ipairs(_lineData) do
            if _symbolType == symbolType then
                --该位置上一次滚动停止，处于未锁定状态
                if self.m_lastReels[iLine] and self.m_lastReels[iLine][iCol] ~= symbolType then
                    count = count + 1

                    if iCol > lastPos.iY then
                        lastPos = {iX = iRow, iY = iCol}
                    elseif iCol == lastPos.iY and iRow < lastPos.iX then
                        lastPos = {iX = iRow, iY = iCol}
                    end
                end

            end
        end
    end
    

    return count,lastPos
end

function GoldenGhostRespinView:ctor()
    RespinView.ctor(self)
    self:initRespinVar()
    self.bonusTypeList = {
        CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1,
        CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2,
        CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3
    }

    self.bonusLv1List = {}
    self.aniList = {}
end

function GoldenGhostRespinView:initUI(respinNodeName)
    RespinView:initUI(respinNodeName)
end

function GoldenGhostRespinView:initRespinVar( ... )
    -- body
    self.curBonusLv3Node = nil
    self.curBonusNode = nil
    self.curBonusIndex = 1
    self.curBonusKey = nil
    self.callBack = nil
    self.m_totalScore = 0
    self.totalScoreLab = nil
    self.m_prelockNodeList = nil
    self.addSpinAniIndex = 1
    self.addSpinNode = nil
    self.isMulaAniing = false
    self.bonusLv1List = {}
    self.quickStopFlag = false
end

function GoldenGhostRespinView:playMulAni( callBack )
    -- body
    local machine = self.m_machine
    local machineRootParent = machine.m_root:getParent()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local bonusSymbolLevel1Count = self.bonusSymbolLevel1Count
    local centerPos = display.center
    local cleaningNodes = self:getAllCleaningNode()
    local aniCount = 0
    for k,v in ipairs(cleaningNodes) do
        local vSymbolType = v.p_symbolType
        if vSymbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
            local startPos = v:getParent():convertToWorldSpace(cc.p(v:getPosition()))
            local endPos = centerPos
            -- 创建粒子
            local flyNode = util_createAnimation( "GoldenGhost_bonus_tuowei.csb" )
            machineRootParent:addChild(flyNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
            flyNode:setPosition(startPos)
            local angle = util_getAngleByPos(startPos,endPos)
            flyNode:setRotation( - angle)
            local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
            flyNode:setScaleX(scaleSize / 518 )
            flyNode:runCsbAction("actionframe",true,function()
                flyNode:stopAllActions()
                flyNode:removeFromParent()
            end)
            table.insert(self.aniList,flyNode)
            performWithDelay(flyNode,function ()
                aniCount = aniCount + 1
                if aniCount == bonusSymbolLevel1Count then
                    local mulVal = bonusSymbolLevel1Count - 9
                    -- mulVal = 3
                    local chengbeiAni = util_createAnimation("GoldenGhost_bonus_chengbei.csb")
                    chengbeiAni:findChild("BitmapFontLabel_1"):setString("x"..mulVal)
                    chengbeiAni:setPosition(centerPos)
                    machineRootParent:addChild(chengbeiAni,REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
                    table.insert(self.aniList,chengbeiAni)

                    self.m_totalScore = self.m_totalScore * mulVal
                    chengbeiAni:runCsbAction("actionframe",false,function ( ... )
                        -- body
                        if self.curBonusLv3Node then
                            local curBonusLv3Node = self.curBonusLv3Node
                            local pos = machine:getNodePosByColAndRow(self.curBonusLv3Node.p_rowIndex,self.curBonusLv3Node.p_cloumnIndex)
                            pos = curBonusLv3Node:getParent():convertToWorldSpace(pos)
                            local actionList = {}

                            actionList[#actionList + 1] = cc.MoveTo:create(0.5,pos)
                            actionList[#actionList + 1] = cc.CallFunc:create(function ( sender )
                                sender:removeFromParent()
                                curBonusLv3Node:runAnim("actionframe_level3",false,function ( ... )
 
                                    local score = machine:getScoreInfoByPos(curBonusLv3Node.p_rowIndex, curBonusLv3Node.p_cloumnIndex)
                                    local coinsStr = machine:getCoinsByScore(score)

                                    self.totalScoreLab:setString(coinsStr)
                                    if callBack then callBack() end
                                end)
                            end)
                            local seq = cc.Sequence:create(actionList)
                            chengbeiAni:runAction(seq)
                        else
                            if callBack then callBack() end
                        end
                    end)
                end
            end,30/60)
        end
    end

end

function GoldenGhostRespinView:handleQuickStop( ... )
    local machine = self.m_machine
    for i,v in ipairs(self.aniList) do
        if v and not tolua.isnull(v) and v:getParent() then
            v:stopAllActions()
            v:removeFromParent()
        end
    end
    for k,v in pairs(self.m_lastTriggerInfo) do
        -- table.insert(sortTriggerInfoList,{key = k,value = v})
        local node = v
        local symbolType = v.p_symbolType
        if  symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 or 
            symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 or
            symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 or 
            symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or 
            symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
            local scoreLb = node:getCcbProperty("m_lb_score")
            local score = machine:getScoreInfoByPos(node.p_rowIndex, node.p_cloumnIndex)
            local curScore = tonumber(scoreLb:getString())
            if not curScore or curScore < score then
                util_performWithDelay(self,function ( ... )
                    scoreLb:setVisible(true)
                    local coinsStr = machine:getCoinsByScore(score)
                    scoreLb:setString(coinsStr)
                end,10/60)
                node:runAnim("actionframe_level1",false,function ( ... )
                    -- body
                    node:runAnim("idleframe",true)
                end)
            end
        end
    end
    self.m_lastTriggerInfo = {}
    self.aniList = {}
end

function GoldenGhostRespinView:quickStop( status )
    if status == ENUM_TOUCH_STATUS.RUN then
        if self.leftTimerAction then
            self.quickStopFlag = true
        end
    else
        self.quickStopFlag = true
    end

    return self.quickStopFlag
end

function GoldenGhostRespinView:update( ... )
    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
    -- body
    local machine = self.m_machine
    if not self.m_prelockNodeList then
        self.m_prelockNodeList = self:getAllCleaningNode()
    end
    local lockNodeList = self.m_prelockNodeList
    local lockNodeCount = #lockNodeList
    local bonusSymbolLevel1Count = self.bonusSymbolLevel1Count
    local isMulRate = bonusSymbolLevel1Count > 11
    local lastTriggerInfo = self.m_lastTriggerInfo
    local lastTriggerInfoList = self:getSortLastTrigInfo()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local bonusFreeSpinBar = self.bonusFreeSpinBar
    local machineRootParent = machine.m_root:getParent()

    --播放+1spin收集动画
    if self.addSpinAniIndex <= #lastTriggerInfoList then
        if not self.addSpinNode then
            local freeSpinLb = bonusFreeSpinBar:findChild("m_lb_num_0")
            local freeSpinLbPos = cc.p(freeSpinLb:getPosition())
            local bonusFreeSpinBarPos = freeSpinLb:getParent():convertToWorldSpace(freeSpinLbPos)
            local tab = lastTriggerInfoList[self.addSpinAniIndex]
            local addSpinNode = tab.value
            local valueSymbolType = addSpinNode.p_symbolType
            self.addSpinNode = addSpinNode
            local preZOrder = addSpinNode:getLocalZOrder()
            function playAni( addSpinNode )
                
                -- body
                local lockNodePos = addSpinNode:getParent():convertToWorldSpace(cc.p(addSpinNode:getPosition()))
                local lockNodePosX,lockNodePosY = lockNodePos.x,lockNodePos.y

                local moveActionNode = util_createAnimation("Socre_GoldenGhost_SpinPlus_0.csb")
                moveActionNode:runCsbAction("shouji")
                moveActionNode:setPosition(lockNodePos)

                gLobalViewManager.p_ViewLayer:addChild(moveActionNode,ViewZorder.ZORDER_SPECIAL)
                util_performWithDelay(self,function ( ... )
                    local actionList = {}
                    local moveAct = cc.MoveTo:create(30 / 60,cc.p(bonusFreeSpinBarPos.x,bonusFreeSpinBarPos.y))
                    actionList[#actionList + 1] = moveAct
                    actionList[#actionList + 1] = cc.CallFunc:create(function ( sender )
                        sender:removeFromParent()
                        if self.addSpinNode then
                            gLobalSoundManager:playSound(levelConfig.Sound_AddSpinTimes_Collect_End)
                            machine:addRespinTimes()
                            self.addSpinNode = nil
                            self.addSpinAniIndex = self.addSpinAniIndex + 1
                        end
                    end)
                    local seq = cc.Sequence:create(actionList)
                    moveActionNode:runAction(seq)
                    gLobalSoundManager:playSound(levelConfig.Sound_AddSpinTimes_Collect_Start)
                end,20 / 60)
            end

            if self.addSpinNode then
                if  valueSymbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN then
                        addSpinNode:setLocalZOrder(9999)
                        addSpinNode:runAnim("actionframe",false,function ( ... )
                        -- body
                            addSpinNode:runAnim("idleframe",true)
                            addSpinNode:setLocalZOrder(preZOrder)
                            playAni(addSpinNode)
                        end)
                elseif  valueSymbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or
                        valueSymbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
                        local addSpinSp = addSpinNode:getCcbProperty("spin_1")
                        addSpinNode:setLocalZOrder(9999)
                        addSpinNode:runAnim("shouji",false,function ( ... )
                            addSpinNode:runAnim("idleframe",true)
                        end)
                        util_performWithDelay(self,function ( ... )
                            addSpinNode:setLocalZOrder(preZOrder)
                            addSpinSp:setVisible(false)
                            playAni(addSpinNode)
                        end,self.collectTime)
                else
                    self.addSpinNode = nil
                    self.addSpinAniIndex = self.addSpinAniIndex + 1
                end
            end
        end
        return
    end

    if(#lastTriggerInfoList <= 0) or self.quickStopFlag then 
        self:stopLeftTimerAction()
        performWithDelay(self,function ()
            if self.quickStopFlag then
                self:handleQuickStop()
            end
            self:setTopScoreUI()
            if(self.callBack) then 
                self.callBack() 
            end
            self:initRespinVar()
        end,0.1)
        return
    end

    if self.curBonusIndex > lockNodeCount then
        function callBack()
            self.curBonusIndex = 1
            self.curBonusNode = nil
            self.curBonusLv3Node = nil
            table.remove(lastTriggerInfoList,1)
            if self.curBonusKey then
                lastTriggerInfo[self.curBonusKey] = nil
            end
            self.m_totalScore = 0
            self.isMulaAniing = false
        end
        if #self.bonusLv1List > 0 then return end
        local node = self.curBonusLv3Node
        local symbolType = node.p_symbolType
        local nodeSymbolType = machine:formatAddSpinSymbol(symbolType)
        -- isMulRate = true
        --  策划说概率太小，不添加拖尾合乘倍动效，直接写死
        isMulRate = false
        if  isMulRate and 
            nodeSymbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 then
            if  not self.isMulaAniing then
                self.isMulaAniing = true
                self:playMulAni(callBack)
            end
        else
            callBack()
        end
        return
    end

    if not self.curBonusLv3Node then
        local tab = lastTriggerInfoList[1]
        local key = tab.key
        self.curBonusKey = key
        local node = tab.value
        local symbolType = node.p_symbolType
        local nodeSymbolType = machine:formatAddSpinSymbol(symbolType)
        if  nodeSymbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 or 
            nodeSymbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 then
            self.curBonusLv3Node = node
            self.totalScoreLab = node:getCcbProperty("m_lb_score")
        else
            table.remove(lastTriggerInfoList,1)
            lastTriggerInfo[key] = nil
        end
    else
        local pos1 = util_convertToNodeSpace(self.totalScoreLab, self)
        -- local pos1 = machine:getNodePosByColAndRow(self.curBonusLv3Node.p_rowIndex,self.curBonusLv3Node.p_cloumnIndex)
        if not self.curBonusNode then
            local node2 = lockNodeList[self.curBonusIndex]
            local preZOrder = node2:getLocalZOrder()
            local node2ScoreLab = node2:getCcbProperty("m_lb_score")
            local symbolType = self.curBonusLv3Node.p_symbolType
            local nodeSymbolType = machine:formatAddSpinSymbol(symbolType)
            local symbolType2 = node2.p_symbolType
            local nodeSymbolType2 = machine:formatAddSpinSymbol(symbolType2)
            if  self.curBonusLv3Node == node2 or 
                not node2ScoreLab:isVisible() or 
                nodeSymbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 and 
                nodeSymbolType2 ~= CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
                self.curBonusIndex = self.curBonusIndex + 1
            else
                if  nodeSymbolType2 == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 or
                    nodeSymbolType2 == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 or 
                    nodeSymbolType2 == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 then
                    self.curBonusNode = node2
                    -- bonus收集 没有触发音效，只有飞行和结束音效 10.13
                    local aniIdx = table.indexof(self.bonusTypeList,nodeSymbolType2)
                    
                    -- 最低等级的延时修改为0
                    local collectTime = 0--10 / 60
                    if nodeSymbolType2 ~= CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
                        collectTime = self.collectTime
                    end
                    node2:setLocalZOrder(9999)

                    if nodeSymbolType2 == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 or 
                        nodeSymbolType2 == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 then

                        node2:runAnim("shouji",false,function ( ... )
                            node2:runAnim("idleframe",true)
                                -- if  nodeSymbolType2 == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
                                --     util_performWithDelay(self,function ( ... )
                                --         self.bonusLv1List[#self.bonusLv1List + 1] = node2
                                --         self.curBonusNode = nil
                                --         self.curBonusIndex = self.curBonusIndex + 1
                                --     end,0.1)
                                -- end
                        end)
                    end
                    
                    -- 可以在上一个还没播完的时候就开始播下一个 0.5s  
                    if  nodeSymbolType2 == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
                        util_performWithDelay(self,function ( ... )
                            self.bonusLv1List[#self.bonusLv1List + 1] = node2
                            self.curBonusNode = nil
                            self.curBonusIndex = self.curBonusIndex + 1
                        end,0.5)
                    end

                    util_performWithDelay(self,function ( ... )
                        node2:setLocalZOrder(preZOrder)
                        local pos2 = util_convertToNodeSpace(node2ScoreLab, self)
                        -- local pos2 = machine:getNodePosByColAndRow(node2.p_rowIndex,node2.p_cloumnIndex)
                        
                        local moveActionNode, effectLabelAct = util_csbCreate("GoldenGhost_coins.csb", true)
                        util_csbPauseForIndex(effectLabelAct, 30)
                        local function getScoreLabel(node)
                            local name = node:getName()
                            if name == "m_lb_coins" then
                                return node
                            else
                                for k, v in ipairs(node:getChildren()) do
                                    local n = getScoreLabel(v)
                                    if n ~= nil then
                                        return n
                                    end
                                end
                            end
                        end
                        local lab = getScoreLabel(moveActionNode)
                        local score = machine:getScoreInfoByPos(node2.p_rowIndex, node2.p_cloumnIndex)
                        -- lab:setString(util_formatCoins(totalBet * score,3))
                        local coinsStr = machine:getCoinsByScore(score)
                        lab:setString(coinsStr)
                        self:addChild(moveActionNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 50)
                        table.insert(self.aniList,moveActionNode)
                        -- gLobalViewManager.p_ViewLayer:addChild(moveActionNode,ViewZorder.ZORDER_SPECIAL)
                        moveActionNode:setPosition(pos2)
                        local actionList = {}
                        actionList[#actionList + 1] = cc.Spawn:create(cc.MoveTo:create(0.5, pos1),cc.ScaleTo:create(0.5,0.5))
                        actionList[#actionList + 1] = cc.CallFunc:create(function ( sender )
                            sender:removeFromParent()
                            if not self.curBonusLv3Node then return end
                            if self.totalScoreLab then
                                self.totalScoreLab:setString("")
                                self.totalScoreLab:setVisible(true)
                                self.m_totalScore = self.m_totalScore + score
                                -- local coinsStr = machine:getCoinsByScore(self.m_totalScore)
                                local curBonusLv3Node = self.curBonusLv3Node
                                local score = machine:getScoreInfoByPos(curBonusLv3Node.p_rowIndex, curBonusLv3Node.p_cloumnIndex)
                                if self.m_totalScore > score then
                                    self.m_totalScore = score
                                end
                                local coinsStr = machine:getCoinsByScore(self.m_totalScore)
                                self.totalScoreLab:setString(coinsStr)
                                gLobalSoundManager:playSound(levelConfig.Sound_Bonus_Collect_End)
                            end

                            local shoujiEndName = "shouji2" --string.format("actionframe_level%d", aniIdx)
                            self.curBonusLv3Node:runAnim(shoujiEndName,false,function ( ... )
                                -- body
                                if not self.curBonusLv3Node then return end
                                self.curBonusLv3Node:runAnim("idleframe",true)
                                if  nodeSymbolType2 == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
                                    table.remove(self.bonusLv1List,1)
                                else
                                    self.curBonusNode = nil
                                    self.curBonusIndex = self.curBonusIndex + 1
                                end
                            end)
                        end)
                        local seq = cc.Sequence:create(actionList)
                        moveActionNode:runAction(seq)
                        gLobalSoundManager:playSound(levelConfig.Sound_Bonus_Collect_Start)
                    end,collectTime)

                end
            end
        end
    end

end

function GoldenGhostRespinView:stopLeftTimerAction()
    if self.leftTimerAction ~= nil then
        self:stopAction(self.leftTimerAction)
        self.leftTimerAction = nil
    end
end

function GoldenGhostRespinView:handleTriggerResult(callBack)
    if not self.leftTimerAction then
        self.leftTimerAction = schedule(self,self.update,1/60)
    end
    local quickStopFlag = self.quickStopFlag
    self.callBack = callBack
end

function GoldenGhostRespinView:updatePreLockNodeList( ... )
    -- body
    self.m_prelockNodeList = self:getAllCleaningNode()
end

function GoldenGhostRespinView:getSortLastTrigInfo()
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
function GoldenGhostRespinView:getAllCleaningNode()
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

function GoldenGhostRespinView:getBonusSymbolCount(symbolType)
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

function GoldenGhostRespinView:oneReelDown(colIndex)
    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
    gLobalSoundManager:playSound(levelConfig.Sound_Reel_Stop)
end

return GoldenGhostRespinView
