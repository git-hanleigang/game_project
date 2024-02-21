--接水管中的老虎机
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseSlots = require "Levels.BaseSlots"

local ActivityBaseMachine = class("ActivityBaseMachine", BaseSlotoManiaMachine)

function ActivityBaseMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
end

function ActivityBaseMachine:initMachineData()
    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName .. "_Datas"

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    self:checkHasBigSymbol()
end

function ActivityBaseMachine:dealSmallReelsSpinStates()
    --重置按钮状态，暂时不调用
end

--绘制多个裁切区域
function ActivityBaseMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)
        local high = reelSize.height / 4
        reelSize.height = reelSize.height + high

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        else
            clipNode =
                cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() -- cc.LayerColor:create(cc.c4f(r,g,b,200))  --

        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY - high * 0.5)
        clipNode:setTag(CLIP_NODE_TAG + i)

        -- slotParentNode:setVisible(false)

        local parentData = SlotParentData:new()

        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)
    end
end

---
-- 获取最高的那一列
--
function ActivityBaseMachine:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0

    local iColNum = self.m_iReelColumnNum
    --    local maxHeightColumnIndex = iColNum
    for iCol = 1, iColNum, 1 do
        -- local colNodeName = "reel_unit"..(iCol - 1)
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))

        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(reelNode:getPositionX(), reelNode:getPositionY())
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = reelSize.height

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height
            self.m_fReelWidth = reelSize.width
        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / 4

    for iCol = 1, iColNum, 1 do
        -- self.m_reelColDatas[iCol].p_slotColumnPosY = self.m_reelColDatas[iCol].p_slotColumnPosY - 0.5 * self.m_SlotNodeH
        self.m_reelColDatas[iCol].p_slotColumnHeight = self.m_reelColDatas[iCol].p_slotColumnHeight + self.m_SlotNodeH
    end

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = self.m_iReelRowNum -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

function ActivityBaseMachine:checkRestSlotNodePos()
    -- 还原reel parent 信息
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local posx, posy = slotParent:getPosition()
        slotParent:setPosition(0, 0) -- 还原位置信息

        local childs = slotParent:getChildren()
        --        printInfo("xcyy  剩余 child count %d", #childs)

        local lastType = nil
        local preRow = 0
        local maxLastNodePosY = nil
        local minLastNodePosY = nil

        local moveDis = nil
        for nodeIndex = 1, #childs do
            local childNode = childs[nodeIndex]
            if childNode.m_isLastSymbol == true then
                local childPosY = childNode:getPositionY()
                if maxLastNodePosY == nil then
                    maxLastNodePosY = childPosY
                elseif maxLastNodePosY < childPosY then
                    maxLastNodePosY = childPosY
                end

                if minLastNodePosY == nil then
                    minLastNodePosY = childPosY
                elseif minLastNodePosY > childPosY then
                    minLastNodePosY = childPosY
                end
                local columnData = self.m_reelColDatas[childNode.p_cloumnIndex]
                local nodeH = columnData.p_showGridH

                childNode:setPositionY((nodeH * childNode.p_rowIndex - nodeH * 0.5))

                if moveDis == nil then
                    moveDis = childPosY - childNode:getPositionY()
                end
            else
                --do nothing
            end

            childNode.m_isLastSymbol = false
        end

        -- printInfo(" xcyy %d  %d  ", parentData.cloumnIndex,parentData.symbolType)
        parentData:reset()
    end
end
function ActivityBaseMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

function ActivityBaseMachine:operaNetWorkData()
    local lastNodeIsBigSymbol = false
    local maxDiff = 0
    for i = 1, #self.m_slotParents do
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent

        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH
        -- print(i .. "列，不考虑补偿计算的移动距离 " ..  moveL)
        local childs = slotParent:getChildren()
        local preY = 0
        local isLastBigSymbol = false

        -- printInfo(" updateNetWork %d ,, col=%d " , #childs , i)

        for childIndex = 1, #childs do
            local child = childs[childIndex]
            local isVisible = child:isVisible()
            local childY = child:getPositionY()
            local topY = nil
            local nodeH = child.p_slotNodeH or 144
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
                isLastBigSymbol = true
            else
                topY = childY + nodeH * 0.5
                isLastBigSymbol = false
            end

            if topY < preY and isLastBigSymbol == false then
                isLastBigSymbol = false
            end

            preY = util_max(preY, topY)
        end
        if isLastBigSymbol == true then
            lastNodeIsBigSymbol = true
        end
        local parentY = slotParent:getPositionY()
        -- 按照逻辑处理来说， 各列的moveDiff非长条模式是相同的，长条模式需要将剩余的补齐
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
        if #childs == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            moveDiff = 0
        end
        moveL = moveL + moveDiff

        parentData.moveDistance = parentY - moveL
        parentData.moveL = moveL
        parentData.moveDiff = moveDiff
        parentData.preY = preY

        maxDiff = util_max(maxDiff, math.abs(moveDiff))

        -- self:createSlotNextNode(parentData)
    end

    -- 检测假数据滚动时最后一个格子是否为 bigSymbol，
    -- 如果是那么其他列补齐到与最大bigsymbol同样的高度
    if lastNodeIsBigSymbol == true then
        for i = 1, #self.m_slotParents do
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            local columnData = self.m_reelColDatas[i]
            local halfH = columnData.p_showGridH * 0.5

            if #slotParent:getChildren() == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
                parentData.moveDiff = maxDiff
            end

            local parentY = slotParent:getPositionY()
            local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH

            moveL = moveL + maxDiff

            -- 补齐到长条高度
            local diffDis = maxDiff - math.abs(parentData.moveDiff)

            if diffDis > 0 then
                local nodeCount = math.floor(diffDis / columnData.p_showGridH)

                for addIndex = 1, nodeCount do
                    if self:getNormalSymbol(parentData.cloumnIndex) == nil then
                        local a = 1
                    end
                    local symbolType = self:getNormalSymbol(parentData.cloumnIndex)
                    local node = self:getSlotNodeWithPosAndType(symbolType, 1, 1, false)
                    node.p_slotNodeH = columnData.p_showGridH
                    local posY = parentData.preY + (addIndex - 1) * columnData.p_showGridH + columnData.p_showGridH * 0.5
                    node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                    node:setPositionY(posY)

                    slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                end
            end

            parentData.moveDistance = parentY - moveL

            parentData.moveL = moveL
            parentData.moveDiff = nil
            self:createSlotNextNode(parentData)
        end
    else
        for i = 1, #self.m_slotParents do
            local parentData = self.m_slotParents[i]
            self:createSlotNextNode(parentData)
        end
    end

    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

function ActivityBaseMachine:getCurrSpinMode()
    return NORMAL_SPIN_MODE
end

function ActivityBaseMachine:setCurrSpinMode(spinMode)
end

function ActivityBaseMachine:setGameSpinStage(spinStage)
    self.m_gameSpinStage = spinStage
end
function ActivityBaseMachine:getGameSpinStage()
    return self.m_gameSpinStage
end

function ActivityBaseMachine:MachineRule_checkTriggerFeatures()
end

function ActivityBaseMachine:callSpinTakeOffBetCoin(betCoin)
end

function ActivityBaseMachine:addLastWinSomeEffect()
end

function ActivityBaseMachine:checkNetDataCloumnStatus()
    local featureDatas = self.m_initSpinData.p_features
    local hasFreepinFeature = false
    local hasBonusGame = false
    if featureDatas ~= nil then
        for i = 1, #featureDatas do
            local featureId = featureDatas[i]
            if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then
                -- 表明触发了更多 freespin
                if self.m_initSpinData.p_freeSpinsTotalCount > self.m_initSpinData.p_freeSpinsLeftCount then
                    self:triggerFreeSpinCallFun()
                end
                self.m_bProduceSlots_InFreeSpin = true
                hasFreepinFeature = true
                local params = {self:getLastWinCoin(), false, false}
                params[self.m_stopUpdateCoinsSoundIndex] = true
                break
            end
            if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                hasBonusGame = true
            end
        end
    end
    local isPlayGameEff = false

    -- 判断是否继续触发respin玩法  ，， 由于freespin 和 respin 是不会同时触发的，所以分开处理
    isPlayGameEff = self:checkTriggerInReSpin() or hasBonusGame


    return isPlayGameEff
end

function ActivityBaseMachine:checkTriggerInReSpin()
    return false
end

function ActivityBaseMachine:checkTriggerINFreeSpin()
    return false
end

---
-- 检测上次feature 数据
--
function ActivityBaseMachine:checkNetDataFeatures()
    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- respin 玩法一并通过respinCount 来进行判断处理
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true

            if self.checkControlerReelType and self:checkControlerReelType() then
                globalMachineController.m_isEffectPlaying = true  --有疑问
            end


            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]

                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1

                        local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                            for addPosIndex = 1, #lineData.p_iconPos do
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
                            end

                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                end

                if checkEnd == true then
                    break
                end
            end

        -- self:sortGameEffects( )
        -- self:playGameEffect()
        end
    end
end

function ActivityBaseMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i = 1, featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的，
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                    -- 添加 BonusEffect
                    self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end
            end
        end
    end
end

function ActivityBaseMachine:enterQuestTipCallBack()
    self:enterLevel()
    --5秒后播放 收起动画
    self.m_questView:delayHideDescribe(3)
end

function ActivityBaseMachine:initHasFeature()
    self:checkUpateDefaultBet()

    self:initCloumnSlotNodesByNetData()
end

function ActivityBaseMachine:initNoneFeature()
    if globalData.GameConfig:checkSelectBet() then
        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questConfig and questConfig.m_IsQuestLogin then
            --quest进入也使用服务器bet
        else
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest() then
                --quest进入也使用服务器bet
            else
                self.m_initBetId = -1
            end
        end
    end

    self:checkUpateDefaultBet()

    self:initRandomSlotNodes()
end

---
-- 检测处理respin  和 special reel的逻辑
--
function ActivityBaseMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
                self:getRandomList()

                self:stopRespinRun()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)

                --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
            end
        else
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
        return true
    end
    return false
end

----
--- 处理spin 成功消息
--
function ActivityBaseMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "spinResult"
    end
    if spinData.action == "SPIN" then

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        --gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

--[[
    @desc: 处理用户的spin赢钱信息
    time:2020-07-10 17:50:08
]]
function ActivityBaseMachine:operaWinCoinsWithSpinResult(param)
    local spinData = param[2]
    local userMoneyInfo = param[3]
    self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果

    if spinData.result.freespin.freeSpinsTotalCount == 0 then
        self:setLastWinCoin(spinData.result.winAmount)
    else
        self:setLastWinCoin(spinData.result.freespin.fsWinCoins)
    end
end

----
--- 处理spin 失败消息
--
function ActivityBaseMachine:checkOpearSpinFaild(param)
    --给与弹板玩家提示。。
    local errorInfo = {}
    if param[2] then
        errorInfo.errorCode = param[2]
    end

    if param[3] then
        errorInfo.errorMsg = param[3]
    end

    gLobalViewManager:showReConnect(true, nil, errorInfo)
    -- 发消息恢复，界面上显示的钱
    -- self.m_spinResultCoin = 0
    self.m_spinNextLevel = 0
    self.m_spinNextProVal = 0
end

---
-- 点击spin 按钮开始执行老虎机逻辑
--
function ActivityBaseMachine:normalSpinBtnCall()

    print("触发了 normalspin")
    local time1 = xcyy.SlotsUtil:getMilliSeconds()

    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local isContinue = true
    if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then
        if self.m_showLineFrameTime ~= nil then
            local waitTime = time1 - self.m_showLineFrameTime
            if waitTime < (self.m_lineWaitTime * 1000) then
                isContinue = false --时间不到，spin无效
            end
        end
    end

    if not isContinue then
        return
    end

    if self.m_isWaitingNetworkData == true then -- 真实数据未返回，所以不处理点击
        return
    end

    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    local time2 = xcyy.SlotsUtil:getMilliSeconds()
    release_print("normalSpinBtnCall 消耗时间1 .. " .. (time2 - time1))

    if self:getGameSpinStage() == WAIT_RUN then
        return
    end

    self:firstSpinRestMusicBG()

    local isWaitCall = self:MachineRule_SpinBtnCall()
    if isWaitCall == false then
        self:callSpinBtn()
    else
        self:setGameSpinStage(WAIT_RUN)
    end

    local timeend = xcyy.SlotsUtil:getMilliSeconds()

    release_print("normalSpinBtnCall 消耗时间4 .. " .. (timeend - time1) .. " =========== ")
end

---
-- 初始化上次游戏状态数据
--
function ActivityBaseMachine:initGameStatusData(gameData)
    if gameData.gameConfig ~= nil and gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    -- spin
    -- feature
    -- sequenceId
    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    local spin = gameData.spin
    -- spin = nil
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local jackpot = gameData.jackpot
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum ---gameData.totalWinCoins
    self.m_freeSpinOffSetCoins = 0
    --gameData.totalWinCoins
    self:setLastWinCoin(totalWinCoins)

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin, self.m_lineDataPool, self.m_symbolCompares, feature)
        self.m_initSpinData = self.m_runSpinResultData
    end
    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                -- if feature.bonus.status == "CLOSED" and feature.bonus.content ~= nil then
                --     local bet = feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1]
                --     feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1] = - bet
                -- end
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status
            end
        end
        self.m_initFeatureData:parseFeatureData(feature)
    -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "init"
        --gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME, params)
    end

    if collect and type(collect) == "table" and #collect > 0 then
        for i = 1, #collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end
    if jackpot and type(jackpot) == "table" and #jackpot > 0 then
        self.m_jackpotList = jackpot
    end
    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    if gameData.gameConfig ~= nil and gameData.gameConfig.bonusReels ~= nil then
        self.m_runSpinResultData["p_bonusReels"] = gameData.gameConfig.bonusReels
    end

    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    self.m_gameCrazeBuff = gameData.gameCrazyBuff or false

    if self.m_videoPokeMgr then
       -- videoPoker 数据解析
        if gameData.gameConfig.extra then
            self.m_videoPokeMgr.m_runData:parseData( gameData.gameConfig.extra ) 
        end
    end
    
    

    self:initMachineGame()
end

---
-- 老虎机滚动结束调用
function ActivityBaseMachine:slotReelDown()
    self:setGameSpinStage(STOP_RUN)
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- if DEBUG == 2 then
    --     for i = 1, #self.m_slotParents do
    --         local parentData = self.m_slotParents[i]
    --         local slotParent = parentData.slotParent
    --         local childs = slotParent:getChildren()
    --         for j=1,#childs do
    --             local child = childs[j]
    --             release_print(" ---- 剩余格子  row = %d , col = %d , type = %d , pos = %f , %d" ,
    --             child.p_rowIndex,child.p_cloumnIndex,child.p_symbolType,child:getPositionY(),child.m_isLastSymbol )
    --         end

    --     end
    -- end

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    self:checkRestSlotNodePos()

    -- 判断是否是长条模式，处理长条只显示一部分的遮罩问题
    -- self:operaBigSymbolMask(true)
    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()

    -- if DEBUG == 2 then
    --     for i = 1, #self.m_slotParents do
    --         local parentData = self.m_slotParents[i]
    --         local slotParent = parentData.slotParent
    --         local childs = slotParent:getChildren()
    --         for j=1,#childs do
    --             local child = childs[j]
    --             release_print(" ---- 剩余格子  row = %d , col = %d , type = %d , pos = %f , %d" ,
    --             child.p_rowIndex,child.p_cloumnIndex,child.p_symbolType,child:getPositionY(),child.m_isLastSymbol )
    --         end

    --     end
    -- end

    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()

    if self.m_videoPokeMgr then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local iconPos = selfdata.iconLocs
        local isFullCollect = selfdata.isFullCollect
        self.m_videoPokeMgr:playVideoPokerIconFly(iconPos, isFullCollect, self)
    end
end
--滚动结束 子类继承
function ActivityBaseMachine:reelDownNotifyChangeSpinStatus()
end

function ActivityBaseMachine:triggerLongRunChangeBtnStates()
end

function ActivityBaseMachine:staticsQuestSpinData()
end

function ActivityBaseMachine:addFsTimes(addTimes)
end

function ActivityBaseMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        coins = self.m_serverWinCoins or 0

        --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        --globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

---判断结算
function ActivityBaseMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})

    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        self:reSpinEndAction()

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    --继续
    self:runNextReSpinReel()
end

function ActivityBaseMachine:resetFreespinTimes(newFreespinTimes)
end

--关卡内活动下载完成监听
function ActivityBaseMachine:checkUpdateActivityEntryNode()
end

function ActivityBaseMachine:clearActSignData()
end

function ActivityBaseMachine:clearActLimitSignData()
end

---
--保留本轮数据
function ActivityBaseMachine:keepCurrentSpinData()
    self:insterReelResultLines()

    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen do
        local value = self.m_vecSymbolEffectType[i]
        local effectData = GameEffectData.new()
        effectData.p_effectType = value
        --                                effectData.p_effectData = data
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

function ActivityBaseMachine:callSpinTakeOffBetCoin(betCoin)
end

--增加新手任务进度
function ActivityBaseMachine:ActivityBaseMachine()
end

function ActivityBaseMachine:notifyClearBottomWinCoin()
end

--没钱弹广告，这个暂时不弹，有需求在加
function ActivityBaseMachine:showLuckyVedio()
end

--[[
    @desc: 处理用户没钱的逻辑
    time:2020-07-21 20:30:01
    @return:
]]
function ActivityBaseMachine:operaUserOutCoins()
    --金币不足，暂时不做任何处理
end

function ActivityBaseMachine:checkChangeFsCount()
end

function ActivityBaseMachine:checkChangeReSpinCount()
end

function ActivityBaseMachine:getFreeSpinCount()
    return 0
end

--开始滚动
function ActivityBaseMachine:startReSpinRun()
end

--触发respin
function ActivityBaseMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end

function ActivityBaseMachine:onExit()

    self:removeObservers()

    self:clearActSignData()
    self:clearActLimitSignData()
    self:clearFrameNodes()
    self:clearSlotNodes()
    -- gLobalSoundManager:stopBackgroudMusic()
    -- 卸载金边
    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]

        if not tolua.isnull(reelNode) then
            if reelNode:getParent() ~= nil then
                reelNode:removeFromParent()
            end
            reelNode:release()
        end

        if not tolua.isnull(reelAct) then
            reelAct:release()
        end
        self.m_reelRunAnima[i] = nil
    end
    if self.m_reelRunAnimaBG ~= nil then
        for i, v in pairs(self.m_reelRunAnimaBG) do
            local reelNode = v[1]
            local reelAct = v[2]

            if not tolua.isnull(reelNode) then
                if reelNode:getParent() ~= nil then
                    reelNode:removeFromParent()
                end
                reelNode:release()
            end

            if not tolua.isnull(reelAct) then
                reelAct:release()
            end
            self.m_reelRunAnimaBG[i] = nil
        end
    end

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:unscheduleUpdate()
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end

    if self.m_respinNodeInfo ~= nil and #self.m_respinNodeInfo > 0 then
        for k = 1, #self.m_respinNodeInfo do
            local node = self.m_respinNodeInfo[k].node
            if not tolua.isnull(node) then
                node:removeFromParent()
            end
        end
    end
    self.m_respinNodeInfo = {}
    

    self:removeSoundHandler()

    self:clearLayerChildReferenceCount()

    self:clearLevelsCodeCache()
end

---
-- 清空掉产生的数据
--
function ActivityBaseMachine:clearSlotoData()

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then
        for i = #self.m_lineDataPool, 1, -1 do
            self.m_lineDataPool[i] = nil
        end
    end
end

--freespin中更新右上角赢钱
function ActivityBaseMachine:updateNotifyFsTopCoins(addCoins)
    if addCoins then
        self.m_freeSpinOffSetCoins = self.m_freeSpinOffSetCoins + addCoins
    end
    local coins = self.m_freeSpinStartCoins + self.m_freeSpinOffSetCoins
end

return ActivityBaseMachine
