local BaseMiniMachine = require "Levels.BaseMiniMachine"
local BaseSlots = require "Levels.BaseSlots"
local SlotParentData = require "data.slotsdata.SlotParentData"
local GameEffectData = require "data.slotsdata.GameEffectData"

local EasterMiniMachine = class("EasterMiniMachine", BaseMiniMachine)

EasterMiniMachine.SYMBOL_SCORE_10 = 9
EasterMiniMachine.SYMBOL_SCATTER_GOLD = 97 -- 金色Scatter
EasterMiniMachine.SYMBOL_SCATTER_WILD = 98 -- Scatter变成的wild

EasterMiniMachine.SYMBOL_SCATTER_TURN_WILD = 108 -- scatter 变成wild的过程

EasterMiniMachine.BONUS_FS_WILD_LOCK_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
EasterMiniMachine.BONUS_FS_ADD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 自定义动画的标识

-- Socre_Easter_Wild_copy --

local Main_Reels = 1

-- 构造函数
function EasterMiniMachine:ctor()
    BaseMiniMachine.ctor(self)
end

function EasterMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent
    self.m_maxReelIndex = data.maxReelIndex

    self.m_lockWildList = {}
    self.m_oldlockWildList = {}
    self.m_scatterPlayArray = {}

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
    --假滚滚动存储类型
    self.m_mysterList = {}
    for i = 1, self.m_iReelColumnNum do
        self.m_mysterList[i] = -1
    end
end

function EasterMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function EasterMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Easter"
end

function EasterMiniMachine:getMachineConfigName()
    local str = "Mini"
    return self.m_moduleName .. str .. "Config" .. ".csv"
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function EasterMiniMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = "EasterSounds/sound_Easter_scatter_ground.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

---
-- 读取配置文件数据
--
function EasterMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelEasterConfig.lua")
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function EasterMiniMachine:initMachineCSB()
    -- self.m_winFrameCCB = "WinFrame" .. self.m_moduleName
    self.m_winFrameCCB = "WinFrameEaster"
    self:createCsbNode("EasterFs.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    self.m_node_effect = cc.Node:create()
    self.m_root:addChild(self.m_node_effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
end

function EasterMiniMachine:initMachine()
    self.m_moduleName = "Easter" -- self:getModuleName()

    BaseMiniMachine.initMachine(self)
end

function EasterMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function EasterMiniMachine:addObservers()
    BaseMiniMachine.addObservers(self)
end

function EasterMiniMachine:onExit()
    BaseMiniMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    self:removeChangeReelDataHandler()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function EasterMiniMachine:removeObservers()
    BaseMiniMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function EasterMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)
    return ccbName
end

function EasterMiniMachine:restLockWildZOrder()
    for i = #self.m_oldlockWildList, 1, -1 do
        local wild = self.m_oldlockWildList[i]
        local zorder = self.SYMBOL_SCATTER_WILD - wild.p_rowIndex
        print("restLockWildZOrder == wild.p_rowIndex " .. wild.p_rowIndex .. "   Zoder ===" .. zorder)
        wild:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + zorder)
    end
end

---
-- 根据类型获取对应节点
--
function EasterMiniMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    reelNode:setMachine(self)
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

function EasterMiniMachine:getBaseReelGridNode()
    return "CodeEasterSrc.EasterSlotFastNode"
end

-- 处理特殊关卡 遮罩层级
function EasterMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    local maxzorder = 0
    local zorder = 0

    for i = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder > maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

function EasterMiniMachine:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end

        return false
    end

    return true
end

function EasterMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function EasterMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function EasterMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function EasterMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function EasterMiniMachine:clearCurMusicBg()
end

function EasterMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function EasterMiniMachine:playEffectNotifyChangeSpinStatus()
    if self.m_parent then
        self.m_parent:FSReelShowSpinNotify(self.m_maxReelIndex)
    end
end

function EasterMiniMachine:slotReelDown()
    EasterMiniMachine.super.slotReelDown(self)
    self:showLockWild()
end

function EasterMiniMachine:reelDownNotifyPlayGameEffect()
    if self.m_parent then
        self.m_parent:FSReelDownNotify(self.m_maxReelIndex)
    end
end

----------------------------- 玩法处理 -----------------------------------

function EasterMiniMachine:beginMiniReel()
    self.m_addSounds = {}
    BaseMiniMachine.beginReel(self)
    local haveGoldScatter = self.m_parent:getHaveGoldScatter()
    if haveGoldScatter then
        self:setWaitChangeReelTime(33 / 30)
    end
    self:randomMystery()
    self:restLockWildZOrder()
end

function EasterMiniMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    self:produceSlots()
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData() -- end
end

function EasterMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

-- 消息返回更新数据
function EasterMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self:updateNetWorkData()
    self:setNetMysteryType()
end

function EasterMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function EasterMiniMachine:quicklyStopReel(colIndex)
    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        BaseMiniMachine.quicklyStopReel(self, colIndex)
    end
end

---
-- 清空掉产生的数据
--
function EasterMiniMachine:clearSlotoData()
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

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

-------------------------------------------------------------------------

-- 显示free spin
function EasterMiniMachine:showSelfEffect_FreeSpin(isTurn, func)
    -- self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    -- self:clearWinLineEffect()

    -- 停掉背景音乐
    self:clearCurMusicBg()

    if isTurn then
        local lineLen = #self.m_reelResultLines
        local scatterLineValue = nil
        for i = 1, lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                scatterLineValue = lineValue
                table.remove(self.m_reelResultLines, i)
                break
            end
        end

        if scatterLineValue ~= nil then
            --
            self:showBonusAndScatterLineTip(
                scatterLineValue,
                function()
                    -- self:visibleMaskLayer(true,true)
                    gLobalSoundManager:stopAllAuido() -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move

                    if func then
                        func()
                    end
                end
            )
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        else
            if func then
                func()
            end
        end
    else
        if func then
            func()
        end
    end

    return true
end

function EasterMiniMachine:addSelfEffect()
    if self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE then
        local feature = self.m_parent.m_runSpinResultData.p_features
        if feature and #feature > 1 and feature[2] == 1 then
            --加次数
            local selfAddEffect = GameEffectData.new()
            selfAddEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfAddEffect.p_effectOrder = self.BONUS_FS_ADD_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfAddEffect
            selfAddEffect.p_selfEffectType = self.BONUS_FS_ADD_EFFECT -- 动画类型
        end
    end
end

function EasterMiniMachine:restSelfGameEffects(restType)
    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects, 1 do
            local effectData = self.m_gameEffects[i]

            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_selfEffectType

                if effectType == restType then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    return
                end
            end
        end
    end
end

function EasterMiniMachine:getHaveGoldScatter()
    local reels = self.m_runSpinResultData.p_reels
    for i = 1, self.m_iReelColumnNum, 1 do
        for j = 1, #reels, 1 do
            if reels[j][i] == self.SYMBOL_SCATTER_GOLD then
                return true
            end
        end
    end
    return false
end

function EasterMiniMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.BONUS_FS_ADD_EFFECT then
        local endPos = util_getConvertNodePos(self.m_parent.m_freespinSpinbar, self.m_parent.m_node_effect)

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local symbol = self:getFixSymbol(iCol, iRow)
                local csb_addTime = symbol:getChildByTag(self.SYMBOL_SCATTER_GOLD + 1000)
                if csb_addTime then
                    csb_addTime:setVisible(true)
                    local pos = util_getConvertNodePos(symbol, self.m_parent.m_node_effect)

                    util_changeNodeParent(self.m_parent.m_node_effect, csb_addTime, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                    csb_addTime:setPosition(pos)
                    csb_addTime:runCsbAction("actionframe")
                    csb_addTime:findChild("Particle_1"):setPositionType(0)
                    csb_addTime:findChild("Particle_2"):setPositionType(0)
                    performWithDelay(
                        csb_addTime,
                        function()
                            local actionList = {
                                cc.MoveTo:create(22 / 60, endPos),
                                cc.RemoveSelf:create(true)
                            }
                            local seq = cc.Sequence:create(actionList)
                            csb_addTime:runAction(seq)
                        end,
                        22 / 60
                    )
                end
            end
        end
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                waitNode:removeFromParent(true)
                gLobalSoundManager:playSound("EasterSounds/sound_Easter_add_fs_times.mp3")
                self.m_parent.m_freespinSpinbar:changeTimeAni()
                self.m_parent.m_freespinSpinbar:changeFreeSpinByCount()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            44 / 60
        )
    -- elseif effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT then
    end

    return true
end

function EasterMiniMachine:removeAllReelsNode(notCreate)
    self:stopAllActions()
    self:clearWinLineEffect()

    -- 新滚动移除所有小块
    self:removeAllGridNodes()

    for i = #self.m_oldlockWildList, 1, -1 do
        local wild = self.m_oldlockWildList[i]
        if wild and wild.updateLayerTag then
            wild:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        wild:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(wild.p_symbolType, wild)
        table.remove(self.m_oldlockWildList, i)
    end

    self.m_oldlockWildList = {}

    self:randomSlotNodes()
end

--增加提示节点
function EasterMiniMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}

    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            -- 多个scatter的处理
            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_SCATTER_GOLD then
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            end
        end
    end -- end for i=1,#nodes

    return tipSlotNoes
end

function EasterMiniMachine:initRandomSlotNodes()
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()
end

---
-- 检测上次feature 数据
--
function EasterMiniMachine:checkNetDataFeatures()
    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            -- self:sortGameEffects( )
            -- self:playGameEffect()
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1, #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex]

                    local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GOLD then
                        checkEnd = true
                        local lineInfo = self:getReelLineInfo()
                        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER

                        for addPosIndex = 1, #lineData.p_iconPos do
                            local posData = lineData.p_iconPos[addPosIndex]
                            local rowColData = self:getRowAndColByPos(posData)
                            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
                        end

                        lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                        self.m_reelResultLines = {}
                        self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                        break
                    end
                end
                if checkEnd == true then
                    break
                end
            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- respin 玩法一并通过respinCount 来进行判断处理
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
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
                if checkEnd == true then
                    break
                end
            end

        -- self:sortGameEffects( )
        -- self:playGameEffect()
        end
    end
end

function EasterMiniMachine:lineLogicEffectType(winLineData, lineInfo, iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData, lineInfo)

    if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or enumSymbolType == self.SYMBOL_SCATTER_GOLD then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

--[[
    @desc: 对比 winline 里面的所有线， 将相同的线 进行合并，
    这个主要用来处理， winLines 里面会存在两条一样的触发 fs的线，其中一条线winAmount为0，另一条
    有值， 这中情况主要使用与
    time:2018-08-16 19:30:23
    @return:  只保留一份 scatter 赢钱的线，如果存在允许scatter 赢钱的话
]]
function EasterMiniMachine:compareScatterWinLines(winLines)
    local scatterLines = {}
    local winAmountIndex = -1
    for i = 1, #winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.p_iconPos
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        for posIndex = 1, #iconsPos do
            local posData = iconsPos[posIndex]

            local rowColData = self:getRowAndColByPos(posData)

            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or enumSymbolType == self.SYMBOL_SCATTER_GOLD then
            scatterLines[#scatterLines + 1] = {i, winLineData.p_amount}
            if winLineData.p_amount > 0 then
                winAmountIndex = i
            end
        end
    end

    if #scatterLines > 0 and winAmountIndex > 0 then
        for i = #scatterLines, 1, -1 do
            local lineData = scatterLines[i]
            if lineData[2] == 0 then
                table.remove(winLines, lineData[1])
            end
        end
    end
end

function EasterMiniMachine:ChangeScatterNode()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

            if targSp then
                local symbolType = targSp.p_symbolType

                if symbolType == self.SYMBOL_SCATTER_GOLD or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- Scatter变成的wild then
                    symbolType = self.SYMBOL_SCORE_10
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                    targSp:changeSymbolImage(self:getSymbolCCBNameByType(self, symbolType))
                    targSp:setLocalZOrder(self:getBounsScatterDataZorder(symbolType))
                    targSp:runAnim("idleframe")
                end
            end
        end
    end
end

-- 小轮盘玩法处理
function EasterMiniMachine:CreateSlotNodeByData()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getReelParentChildNode(iCol, iRow)
            local symbolType = self.m_parent:getSpinResultReelsType(iCol, iRow)
            local isChange = true

            if targSp and isChange then
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                targSp:changeSymbolImage(self:getSymbolCCBNameByType(self, symbolType))
                targSp:setLocalZOrder(self:getBounsScatterDataZorder(symbolType) - targSp.p_rowIndex)
                targSp:runAnim("idleframe")
            end
        end
    end
end

-- 锁定玩法处理
-- 金色scatter 固定玩法
function EasterMiniMachine:initFsLockWild(wildPosList)
    if wildPosList and #wildPosList > 0 then
        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX)

            if targSp then
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCATTER_WILD), self.SYMBOL_SCATTER_WILD)

                targSp:changeSymbolImage(self:getSymbolCCBNameByType(self, self.SYMBOL_SCATTER_WILD))

                targSp:runAnim("idleframe")

                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

                local linePos = {}
                linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                targSp.m_bInLine = true
                targSp:setLinePos(linePos)
                targSp:setLocalZOrder(self:getBounsScatterDataZorder(self.SYMBOL_SCATTER_WILD) - fixPos.iX)

                targSp = self:setSymbolToClipReel(targSp.p_cloumnIndex, targSp.p_rowIndex, targSp.p_symbolType)

                table.insert(self.m_oldlockWildList, targSp)
            end
        end
    end

    self:restLockWildZOrder()
end

function EasterMiniMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        local linePos = {}
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = true
        targSp:setLinePos(linePos)
    end
    return targSp
end

function EasterMiniMachine:addFreespinTimesByScatter(func)
    local extraTimes = self.m_runSpinResultData.p_selfMakeData.extraTimes
    if extraTimes then
        for k, v in pairs(extraTimes) do
            local pos = tonumber(k)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp = self:getReelParentChildNode(fixPos.iY, fixPos.iX)

            if targSp then
            -- local layer = cc.LayerColor:create(cc.c4f(155, 25, 125, 255))
            -- layer:setContentSize(150, 150)
            -- local worldPos = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPosition()))
            -- local localPos = self:convertToNodeSpace(worldPos)
            -- layer:setPosition(localPos)
            -- self:addChild(layer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

            -- performWithDelay(
            --     layer,
            --     function()
            --         -- layer:removeFromParent()
            --         -- layer:setVisible(true)
            --     end,
            --     2
            -- )
            end
        end

        performWithDelay(
            self,
            function()
                if func then
                    func()
                end
            end,
            2
        )
    else
        if func then
            func()
        end
    end
end

function EasterMiniMachine:GoldScatterTurnLockWild(wildPosList, func, aniName)
    -- self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- -- 取消掉赢钱线的显示
    -- self:clearWinLineEffect()

    if wildPosList and #wildPosList > 0 then
        local posX = 0

        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX)

            local wild = self:getSlotNodeWithPosAndType(self.SYMBOL_SCATTER_WILD, fixPos.iX, fixPos.iY)
            self.m_clipParent:addChild(wild, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + REEL_SYMBOL_ORDER.REEL_ORDER_3, SYMBOL_NODE_TAG)
            local endPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
            wild:setPosition(endPos)
            wild:runAnim("idleframe")
            wild.p_slotNodeH = self.m_SlotNodeH

            wild.m_symbolTag = SYMBOL_FIX_NODE_TAG
            wild.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            wild:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_FIX_NODE_TAG))
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            wild.m_bInLine = true
            wild:setLinePos(linePos)
            wild:setLocalZOrder(self:getBounsScatterDataZorder(self.SYMBOL_SCATTER_WILD) - fixPos.iX)

            table.insert(self.m_oldlockWildList, wild)
            if aniName == "buling" then
                wild:setVisible(false)
            end

            if aniName == "switch" then
                if targSp then
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCATTER_WILD), self.SYMBOL_SCATTER_WILD)
                    targSp:changeSymbolImage(self:getSymbolCCBNameByType(self, self.SYMBOL_SCATTER_WILD))
                    targSp:runAnim("idleframe")
                end

                local temp_ani = util_spineCreate("Socre_Easter_Scatter_Wild", true, true)
                util_spinePlay(temp_ani, "scatter_wild")
                self.m_node_effect:addChild(temp_ani)
                local pos = util_getConvertNodePos(wild, self.m_node_effect)
                temp_ani:setPosition(pos)
            end
        end
    end

    if aniName == "switch" then
        gLobalSoundManager:playSound("EasterSounds/sound_Easter_scatter_change_wild.mp3")
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            self.m_node_effect:removeAllChildren(true)
            if type(func) == "function" then
                func()
            end
        end,
        1.5
    )

    self:restLockWildZOrder()
end

function EasterMiniMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

function EasterMiniMachine:showLockWild()
    for i, v in ipairs(self.m_oldlockWildList) do
        local wild = self.m_oldlockWildList[i]
        wild:setVisible(true)
    end
end

function EasterMiniMachine:setClipNodeEnable(_enabled)
    if self.m_onceClipNode then
        self.m_onceClipNode:setClippingEnabled(_enabled)
    end
    --超框的先隐藏
    for i = 1, 5 do
        local symbolNodeList, start, over = self.m_reels[i].m_gridList:getList()
        local gridNode = symbolNodeList[over]
        if gridNode then
            gridNode:setVisible(_enabled)
        end
    end
end

function EasterMiniMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end

function EasterMiniMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(
        function()
            local nodeLen = #self.m_lineSlotNodes
            for lineNodeIndex = nodeLen, 1, -1 do
                local lineNode = self.m_lineSlotNodes[lineNodeIndex]
                -- node = lineNode
                if lineNode ~= nil then -- TODO 打的补丁， 临时这样
                    local preParent = lineNode.p_preParent
                    if preParent ~= nil then
                        lineNode:runIdleAnim()
                    end
                end
            end

            self:resetMaskLayerNodes()
            callFun()
        end,
        util_max(67 / 30, animTime),
        self:getModuleName()
    )
end

function EasterMiniMachine:specialSymbolActionTreatment(node)
    -- if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or node.p_symbolType == self.SYMBOL_SCATTER_GOLD) then
    --     node:runAnim("buling")
    -- end
end

function EasterMiniMachine:removeScatterLines()
    local lineLen = #self.m_reelResultLines

    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolType == self.SYMBOL_SCATTER_GOLD or lineValue.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            table.remove(self.m_reelResultLines, i)
            break
        end
    end
end

function EasterMiniMachine:showLineFrame()
    self:removeScatterLines()

    local winLines = self.m_reelResultLines

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                -- self:clearFrames_Fun()

                if frameIndex > #winLines then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                self:playInLineNodesIdle()

                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    self:showAllFrame(winLines)
    if #winLines > 1 then
        showLienFrameByIndex()
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function EasterMiniMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")

        return
    end

    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end
        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe", true)
        else
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
    end

    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function EasterMiniMachine:getResNodeSymbolType(parentData)
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType
end

function EasterMiniMachine:slotOneReelDown(reelCol)
    EasterMiniMachine.super.slotOneReelDown(self, reelCol)
    local scatterNum = 0
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if targSp and (targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or targSp.p_symbolType == self.SYMBOL_SCATTER_GOLD) then
            scatterNum = scatterNum + 1
            targSp:runAnim(
                "buling",
                false,
                function()
                    if not tolua.isnull(targSp) then
                        local csb_addTimes = targSp:getChildByTag(self.SYMBOL_SCATTER_GOLD + 1000)
                        if csb_addTimes then
                            csb_addTimes:setVisible(true)
                            csb_addTimes:runCsbAction("start")
                        end
                    end
                end
            )
        end
    end
    if scatterNum > 0 then

        local soundPath =  "EasterSounds/sound_Easter_scatter_ground.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
end

function EasterMiniMachine:getAddTimes(_iCol, _iRow)
    local extraTimes = self.m_runSpinResultData.p_selfMakeData.extraTimes
    if extraTimes then
        for k, v in pairs(extraTimes) do
            local pos = tonumber(k)
            local fixPos = self:getRowAndColByPos(pos)
            if _iCol == fixPos.iY and _iRow == fixPos.iX then
                return v
            end
        end
    end
end

function EasterMiniMachine:getAddFsNumCsb(_num)
    local csb_addTimes = util_createAnimation("FreeGame_jiacishu.csb")

    if _num == 1 then
        csb_addTimes:findChild("Easter_ui_cishu3_3"):setVisible(false)
        csb_addTimes:findChild("Easter_ui_cishu2_2"):setVisible(false)
        csb_addTimes:findChild("Easter_ui_cishu1_1"):setVisible(true)
    elseif _num == 2 then
        csb_addTimes:findChild("Easter_ui_cishu3_3"):setVisible(false)
        csb_addTimes:findChild("Easter_ui_cishu1_1"):setVisible(false)
        csb_addTimes:findChild("Easter_ui_cishu2_2"):setVisible(true)
    elseif _num == 3 then
        csb_addTimes:findChild("Easter_ui_cishu3_3"):setVisible(true)
        csb_addTimes:findChild("Easter_ui_cishu2_2"):setVisible(false)
        csb_addTimes:findChild("Easter_ui_cishu1_1"):setVisible(false)
    end

    return csb_addTimes
end

--新滚动使用
function EasterMiniMachine:updateReelGridNode(symblNode)
    local symbolType = symblNode.p_symbolType
    symblNode:removeChildByTag(self.SYMBOL_SCATTER_GOLD + 1000)
    if symblNode.m_isLastSymbol == true and (symbolType == self.SYMBOL_SCATTER_GOLD or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER) and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:setSpecialNodeCsb(symblNode)
    end
end

function EasterMiniMachine:setSpecialNodeCsb(sender)
    local symbolNode = sender
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local addNum = self:getAddTimes(iCol, iRow)
    local csb_addTimes = self:getAddFsNumCsb(addNum)
    sender:addChild(csb_addTimes, 100)
    csb_addTimes:setTag(self.SYMBOL_SCATTER_GOLD + 1000)

    csb_addTimes:setVisible(false)
end
--切换假滚类型
function EasterMiniMachine:randomMystery()
    self.m_bNetSymbolType = false
    for i = 1, #self.m_mysterList do
        local symbolInfo = self:getColIsSameSymbol(i, false)
        local symbolType = symbolInfo.symbolType
        self.m_mysterList[i] = symbolType
        if symbolInfo.symbolType ~= -1 then
            local symbolNodeList, start, over = self.m_reels[i].m_gridList:getList()
            local gridNode = symbolNodeList[over]
            --由于最上面未显示的类型不确定 在假滚的过程中导致突然插入不同类型 在这里切换一下类型
            if gridNode then
                gridNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                if gridNode.p_symbolImage ~= nil then
                    gridNode:runIdleAnim()
                end
            end
        end
    end

    self.m_configData:setMysterSymbol(self.m_mysterList)
end
--移除定时器
function EasterMiniMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end
--使用现在获取的数据 来表现假滚 如果一列全相同 则滚动相同信号 一列不同及有快滚则播放配置的假滚数据
function EasterMiniMachine:setNetMysteryType()
    self.m_changeReelDataId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_bNetSymbolType = true
            local bRunLong = false
            for i = 1, #self.m_mysterList do
                local symbolInfo = self:getColIsSameSymbol(i, true)
                self.m_mysterList[i] = symbolInfo.symbolType
                local reelRunData = self.m_reelRunInfo[i]
                if bRunLong then
                    self.m_mysterList[i] = -1
                end
                if self.m_mysterList[i] == -1 then
                    self:changeSlotReelDatas(i, bRunLong)
                end
                if reelRunData:getNextReelLongRun() == true then
                    bRunLong = true
                end
            end
        end,
        0.3,
        "changeReelData"
    )
end

--判断一列是否是相同的信号块 _iCol 列数， _bNetdata 使用服务器的数据 为true，由于信号块切换过类型使用当前显示的信号块类型为false
function EasterMiniMachine:getColIsSameSymbol(_iCol, _bNetdata)
    local reelsData = self.m_runSpinResultData.p_reels
    if reelsData and next(reelsData) then
        local symbolInfo = {}
        local tempType
        local symbolType = nil
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(_iCol, iRow, SYMBOL_NODE_TAG)
            if _bNetdata then
                tempType = reelsData[iRow][_iCol]
            else
                if slotNode and slotNode.p_symbolType then
                    tempType = slotNode.p_symbolType
                end
            end

            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType ~= tempType then
                symbolInfo.symbolType = -1
                symbolInfo.bSame = false
                return symbolInfo
            end
        end
        symbolInfo.symbolType = tempType
        symbolInfo.bSame = true
        return symbolInfo
    else
        local symbolInfo = {}
        symbolInfo.symbolType = -1
        symbolInfo.bSame = false
        return symbolInfo
    end
end

--使用配置的假滚数据
function EasterMiniMachine:changeSlotReelDatas(_col, _bRunLong)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData, _bRunLong)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end

--设置bonus scatter 层级
function EasterMiniMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GOLD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_SCATTER_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end

    return order
end
--添加金边
function EasterMiniMachine:creatReelRunAnimation(col)
 
end

function EasterMiniMachine:setReelRunInfo( )

end

return EasterMiniMachine
