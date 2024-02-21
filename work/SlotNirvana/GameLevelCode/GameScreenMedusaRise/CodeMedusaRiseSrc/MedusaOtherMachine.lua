---
--xcyy
--2018年5月23日
--MedusaOtherMachine.lua

local BaseSlots = require "Levels.BaseSlots"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseFastMachine = require "Levels.BaseFastMachine"
local SlotParentData = require "data.slotsdata.SlotParentData"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local MedusaOtherMachine = class("MedusaOtherMachine", BaseFastMachine)

MedusaOtherMachine.SYMBOL_SCORE_10 = 9
MedusaOtherMachine.SYMBOL_SCORE_11 = 10
MedusaOtherMachine.SYMBOL_WILD2 = 102
MedusaOtherMachine.SYMBOL_WILD3 = 103

MedusaOtherMachine.FLY_SCATTER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1
MedusaOtherMachine.WILD_MOVE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2

local Main_Reels = 1
-- 构造函数
function MedusaOtherMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_pauseRef = 0
end

function MedusaOtherMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent

    --滚动节点缓存列表
    self.cacheNodeMap = {}
    self.m_reelRunAnima = {}
    --init
    self:initGame()
end

function MedusaOtherMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function MedusaOtherMachine:setScatterDownScound()
end
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function MedusaOtherMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MedusaRise"
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function MedusaOtherMachine:getNetWorkModuleName()
    return "MedusaRiseV2"
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function MedusaOtherMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_parent:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 解析关卡csv 数据 以及关卡所需要数据
--@param csvFileName string csv文件名字
--@param luaFileName string lua文件名字
function MedusaOtherMachine:parseMachineData(csvFileName)
    local luaFileName = self:getCSVLuaName()
    -- 解析csv data 结束后的处理
    self.m_csvRunData = gLobalResManager:getCSVDataByFileName_Run(csvFileName, luaFileName)

    if self.m_currentReelStripData == nil then
        self.m_currentReelStripData = self.m_csvRunData.reelDataNormal -- 默认是normal模式下的reel strip data
    end

    self.m_vecLineType = GameLineConfig:getInstance():getLineInfo(self.m_csvRunData, self.m_isAllLineType)
    self.m_lineTypeSize = #self.m_vecLineType

    --
    self.m_iReelColumnNum = #self.m_csvRunData.vecColumnCount
    self.m_iReelRowNum = math.max(unpack(self.m_csvRunData.vecColumnCount))

    self:checkUpdateColumnData()
end

--更新基础数据
--4.赋值区(LevelConfigData)
function MedusaOtherMachine:updateBaseConfig()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData

    --基础
    self.m_lineCount = self.m_configData.p_lineCount
    --关卡线数
    self.m_isAllLineType = self.m_configData.p_isAllLineType --是否为满线关卡
    self.m_iReelColumnNum = self.m_configData.p_columnNum --轮盘列数
    self.m_iReelRowNum = self.m_configData.p_rowNum --轮盘行数
    self.m_reelWidth = self.m_configData.p_reelWidth
    --轮盘宽度
    self.m_reelHeight = self.m_configData.p_reelHeight --轮盘高度

    --轮盘
    -- self:slotsReelRunData(self.m_configData.p_reelRunDatas,self.m_configData.p_bInclScatter
    -- ,self.m_configData.p_bInclBonus,self.m_configData.p_bPlayScatterAction
    -- ,self.m_configData.p_bPlayBonusAction)

    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol --标识哪一列会出现scatter
    self.m_validLineSymNum = self.m_configData.p_validLineSymNum --触发sf，bonus需要的数量
    self:setReelEffect(self.m_configData.p_reelEffectRes)
    --配置快滚效果资源名称
    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() or 3 --连线框播放时间

    --音乐
    self.m_ScatterTipMusicPath = self.m_configData.p_soundScatterTip --scatter提示音
    self.m_BonusTipMusicPath = self.m_configData.p_soundBonusTip --bonus提示音
    self:setReelDownSound(self.m_configData.p_soundReelDown)
    --下落音
    self:setReelRunSound(self.m_configData.p_reelRunSound)
    --快滚音效
    --类型
    self.m_enumWildType = self.m_configData.p_enumWildType --wild类型
    self.m_iRandomSmallSymbolTypeNum = self.m_configData.p_randomSmallSymbolNum --从0到9进行随机
    self.m_bigSymbolInfos = self.m_configData.p_bigSymbolTypeCounts --大信号类型
    self.m_iRandomScatter = true -- 是否随机scatter
    self.m_iRandomBonus = false -- 是否随机bonus
    self.m_iRandomWild = true -- 是否随机 wild
end

--
---
--
function MedusaOtherMachine:initMachine()
    self.m_moduleName = "MedusaRise" -- self:getModuleName()
    -- self.m_gameLineType = self:getGameLineType()

    self.m_machineModuleName = self.m_moduleName

    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("MedusaRise/GameScreenMedusaRise1.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")

    self:updateBaseConfig() -- 更新关卡config.csv的配置信息
    self:updateMachineData() -- 更新滚动轮子指向、 以及更新每列的ReelColumnData
    self:initSymbolCCbNames() -- 更新最基础的信号名字
    self:initMachineData() -- 在BaseSlotoManiaMachine类里面实现

    self:changeViewNodePos() -- 不同关卡适配
    self:drawReelArea() -- 绘制裁剪区域

    self:updateReelInfoWithMaxColumn()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )
end

function MedusaOtherMachine:initMachineData()
    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName .. "_Datas"

    self:setRunCsvData(self.m_csvRunData)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    self:checkHasBigSymbol()

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
            elseif winRate > 3 then
                soundIndex = 3
            end
            gLobalSoundManager:setBackgroundMusicVolume(0.4)
            local soundName = "MedusaRiseSounds/sound_MedusaRise_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId =
                gLobalSoundManager:playSound(
                soundName,
                false,
                function()
                    gLobalSoundManager:setBackgroundMusicVolume(1)
                    self.m_winSoundsId = nil
                end
            )
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

-- function MedusaOtherMachine:callSpinBtn()

--     --播放点击spin音效
--     gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_SPIN)

--     -- 去除掉 ， auto和 freespin的倒计时监听
--     if self.m_handerIdAutoSpin ~= nil then
--         scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
--         self.m_handerIdAutoSpin = nil
--     end

--     self:notifyClearBottomWinCoin()

--     local betCoin = self:getSpinCostCoins() or toLongNumber(0)
--     local totalCoin = globalData.userRunData.coinNum or 1

--     -- freespin时不做钱的计算
--     if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
--         self:operaUserOutCoins()
--     else
--         if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
--             self:getCurrSpinMode() ~= RESPIN_MODE
--          then
--             self:callSpinTakeOffBetCoin(betCoin)

--         else
--             self:takeSpinNextData()
--         end

--         --统计quest spin次数
--         self:staticsQuestSpinData()

--         self:spinBtnEnProc()

--         self:setGameSpinStage( GAME_MODE_ONE_RUN )

--         gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

--         globalData.userRate:pushSpinCount(1)
--         globalData.userRate:pushUsedCoins(betCoin)
--         globalData.rateUsData:addSpinCount()

--     end
--     -- 修改freespin count 的信息
--     self:checkChangeFsCount()

--     -- 修改 respin count 的信息
--     self:checkChangeReSpinCount()
-- end

function MedusaOtherMachine:addLastWinSomeEffect() -- add big win or mega win
    -- self.m_iOnceSpinLastWin = self.m_runSpinResultData.p_winAmount
    -- BaseFastMachine.addLastWinSomeEffect(self)
end

function MedusaOtherMachine:normalSpinBtnCall()
end

function MedusaOtherMachine:spinResultCallFun(param)
end

function MedusaOtherMachine:calculateLastWinCoin()
end

function MedusaOtherMachine:setCurrSpinMode(spinMode)
    self.m_currSpinMode = spinMode
end
function MedusaOtherMachine:getCurrSpinMode()
    return self.m_currSpinMode
end

function MedusaOtherMachine:setGameSpinStage(spinStage)
    self.m_currSpinStage = spinStage
end
function MedusaOtherMachine:getGameSpinStage()
    return self.m_currSpinStage
end

function MedusaOtherMachine:setLastWinCoin(winCoin)
    self.m_lastWinCoin = winCoin
end
function MedusaOtherMachine:getLastWinCoin()
    return self.m_lastWinCoin
end

function MedusaOtherMachine:setLocalGameJsonData(jsonData)
    self.m_localGameJsonData = jsonData
end
function MedusaOtherMachine:getLocalGameJsonData(jsonData)
    return self.m_localGameJsonData
end

function MedusaOtherMachine:setRunCsvData(csvData)
    self.m_runCsvData = csvData
end
function MedusaOtherMachine:getRunCsvData()
    return self.m_runCsvData
end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function MedusaOtherMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine:getPreLoadSlotNodes()
    -- loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_SYMBOL, count = 3}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FSMORE_1,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

function MedusaOtherMachine:addSelfEffect()
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.wildColumns ~= nil then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.WILD_MOVE_EFFECT -- 动画类型
    end

    for row = 1, self.m_iReelRowNum, 1 do
        for col = 1, self.m_iReelColumnNum, 1 do
            local symbolType = self.m_stcValidSymbolMatrix[row][col]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local node = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
                if node ~= nil then
                    local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                    if self.m_scatterPos == nil then
                        self.m_scatterPos = {}
                    end
                    self.m_scatterPos[#self.m_scatterPos + 1] = pos
                end
            end
        end
    end

    if self.m_scatterPos ~= nil and #self.m_scatterPos > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FLY_SCATTER_EFFECT -- 动画类型
    end
end

function MedusaOtherMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.WILD_MOVE_EFFECT then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:wildMoveAction(effectData)
    elseif effectData.p_selfEffectType == self.FLY_SCATTER_EFFECT then
        self:flyScatterAnim(effectData)
    end

    return true
end

function MedusaOtherMachine:wildMoveAction(effectData)
    local vecWildCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
    local delayTime = 0
    for key, value in pairs(vecWildCol) do
        local iCol = tonumber(key) + 1
        if value < self.m_iReelRowNum then
            delayTime = 0.6
            local direction = nil
            local rowIndex = nil
            for iRow = 1, self.m_iReelRowNum do
                local type = self.m_stcValidSymbolMatrix[iRow][iCol]
                if direction == nil then
                    if type == self.SYMBOL_WILD2 then
                        direction = "up"
                    else
                        direction = "down"
                    end
                else
                    if direction == "up" and type ~= self.SYMBOL_WILD2 then
                        rowIndex = iRow - 1
                        break
                    elseif direction == "down" and type == self.SYMBOL_WILD2 then
                        rowIndex = iRow
                        break
                    end
                end
            end

            local addWildNum = self.m_iReelRowNum - rowIndex
            if direction == "down" then
                addWildNum = rowIndex - 1
                rowIndex = self.m_iReelRowNum
            end
            local colIndex = iCol
            local reelColData = self.m_reelColDatas[colIndex]
            local parentData = self.m_slotParents[colIndex]
            local halfNodeH = reelColData.p_showGridH * 0.5
            for i = 1, addWildNum, 1 do
                if direction == "up" then
                    rowIndex = 1 - i
                else
                    rowIndex = rowIndex + 1
                end

                local symbolType = self.SYMBOL_WILD2
                local currNode = self:getReelChildByRowCol(rowIndex, colIndex)
                if currNode ~= nil then
                    currNode:setVisible(false)
                end
                local showOrder = self:getBounsScatterDataZorder(symbolType)
                local node = self:getCacheNode(colIndex, symbolType)
                if node == nil then
                    node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                    local slotParentBig = parentData.slotParentBig
                    if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                        slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                    else
                        parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                    end
                else
                    local tmpSymbolType = self:convertSymbolType(symbolType)
                    node:setVisible(true)
                    node:setLocalZOrder(showOrder - rowIndex)
                    node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                    local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                    node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                    self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
                end
                node.p_slotNodeH = reelColData.p_showGridH

                node.p_symbolType = symbolType
                node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

                node.p_reelDownRunAnima = parentData.reelDownAnima

                node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
                -- else
                --     if currNode.p_symbolType ~= symbolType then
                --         currNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                --     end
                -- end
            end

            self:foreachSlotParent(
                colIndex,
                function(index, realIndex, child)
                    local distance = reelColData.p_showGridH * addWildNum
                    if direction == "down" then
                        distance = -distance
                    end
                    -- child:setVisible(true)
                    local moveBy = cc.MoveBy:create(0.5, cc.p(0, distance))
                    child:runAction(moveBy)
                end
            )
        end
    end
    if delayTime > 0 then
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_move.mp3")
    end
    performWithDelay(
        self,
        function()
            self:addBigWild(
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
        end,
        delayTime
    )
end

function MedusaOtherMachine:addBigWild(func)
    local vecWildCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
    for key, value in pairs(vecWildCol) do
        local iCol = tonumber(key) + 1
        local colIndex = iCol
        local rowIndex = 1
        local reelColData = self.m_reelColDatas[colIndex]
        local parentData = self.m_slotParents[colIndex]
        local halfNodeH = reelColData.p_showGridH * 0.5

        local symbolType = self.SYMBOL_WILD3
        local showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
        local node = self:getCacheNode(colIndex, symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            local slotParentBig = parentData.slotParentBig
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            node:setLocalZOrder(showOrder - rowIndex)
            node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
        end
        node.p_slotNodeH = reelColData.p_showGridH

        node.p_symbolType = symbolType
        node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
        node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)

        local linePos = {}
        for i = 1, self.m_iReelRowNum, 1 do
            linePos[#linePos + 1] = {iX = i, iY = colIndex}
            -- self.m_stcValidSymbolMatrix[i][colIndex] = self.SYMBOL_WILD2
        end
        node.m_bInLine = true
        node:setLinePos(linePos)
        node:runAnim("actionframe")
        self.m_parent.m_vecBigWilds[#self.m_parent.m_vecBigWilds + 1] = node
    end
    gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_light.mp3")
    -- self.m_parent.m_stcValidSymbolMatrix = self.m_stcValidSymbolMatrix
    performWithDelay(
        self,
        function()
            if func ~= nil then
                func()
            end
        end,
        0.5
    )
end

function MedusaOtherMachine:flyScatterAnim(effectData)
    if self.m_scatterPos ~= nil and #self.m_scatterPos > 0 then
        local iCount = 0
        table.sort(
            self.m_scatterPos,
            function(a, b)
                return a.x > b.x
            end
        )
        for i = #self.m_scatterPos, 1, -1 do
            local pos = self.m_scatterPos[i] --self.m_clipParent:convertToNodeSpace(self.m_scatterPos[i])
            if self.m_parent.m_collectScatter:isVisible() == false then
                self.m_parent.m_collectScatter:setVisible(true)
                self.m_parent.m_collectScatter:showAnim()
            end
            performWithDelay(
                self,
                function()
                    local scatter, act = util_csbCreate("MedusaRise_scatter_collect.csb")
                    util_csbPlayForKey(
                        act,
                        "idleframe",
                        false,
                        function()
                            self.m_parent.m_collectScatter:showCollectAnim(self.m_runSpinResultData.p_selfMakeData.freeSpinTimes)
                            scatter:removeFromParent()
                        end
                    )
                    self.m_parent:addChild(scatter, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                    scatter:setPosition(pos)
                    gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_scatter_fly.mp3")
                    local endPos = self.m_parent.m_collectScatter:getEndPos()
                    -- endPos = self.m_clipParent:convertToNodeSpace(endPos)
                    local moveTo = cc.MoveTo:create(1, endPos)
                    scatter:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), moveTo))
                end,
                iCount
            )
            iCount = iCount + 1.5
            table.remove(self.m_scatterPos, i)
        end
        self.m_scatterPos = {}

        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            2 + iCount
        )
    end
end

function MedusaOtherMachine:getReelChildByRowCol(rowIndex, colIndex)
    local slotParentData = self.m_slotParents[colIndex]
    if slotParentData ~= nil then
        local slotParent = slotParentData.slotParent
        local slotParentBig = slotParentData.slotParentBig
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j = 1, #newChilds do
                childs[#childs + 1] = newChilds[j]
            end
        end
        for i = 1, #childs, 1 do
            local child = childs[i]
            if child.p_cloumnIndex == colIndex and child.p_rowIndex == rowIndex then
                return child
            end
        end
    end
end

function MedusaOtherMachine:onEnter()
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function MedusaOtherMachine:enterGamePlayMusic()
    -- do nothing
end
function MedusaOtherMachine:changeFreeSpinModeStatus()
    -- do nothing  mini 轮子不处理 freespin 的状态
end

function MedusaOtherMachine:checkNotifyUpdateWinCoin()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_winAmount, false})
end

function MedusaOtherMachine:slotReelDown()
    local vecWildCol = self.m_runSpinResultData.p_selfMakeData.wildColumns
    local delayTime = 0
    if vecWildCol ~= nil then
        for key, value in pairs(vecWildCol) do
            local iCol = tonumber(key) + 1
            if value < self.m_iReelRowNum then
                delayTime = 0.5
                for iRow = 1, self.m_iReelRowNum do
                    local type = self.m_stcValidSymbolMatrix[iRow][iCol]
                    if type == self.SYMBOL_WILD2 then
                        local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                        if node ~= nil then
                            node:runAnim("shake")
                        end
                    end
                end
            end
        end
    end

    -- local delayTime = 0
    -- for row = 1, self.m_iReelRowNum, 1 do
    --     for col = 1, self.m_iReelColumnNum, 1 do
    --         local symbolType = self.m_stcValidSymbolMatrix[row][col]
    --         if symbolType == self.SYMBOL_WILD2 then
    --             delayTime = 0.5
    --             local node = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
    --             if node ~= nil then
    --                 node:runAnim("shake")
    --             end
    --         end
    --     end
    -- end
    if delayTime > 0 then
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_shake.mp3")
    end
    performWithDelay(
        self,
        function()
            BaseFastMachine.slotReelDown(self)
        end,
        delayTime
    )
end

function MedusaOtherMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    node.p_rowIndex = row
    node.p_cloumnIndex = col
    node.p_symbolType = symbolType
    node.m_isLastSymbol = isLastSymbol or false

    if symbolType == self.SYMBOL_WILD2 or symbolType == self.SYMBOL_WILD3 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        --下帧调用 才可能取到 x y值
        if self.m_parent.m_bProduceSlots_InFreeSpin == true then
            if self.m_parent.m_runSpinResultData.p_selfMakeData.freeSpinType == 1 then
                node:setLineAnimName("actionframe3")
            else
                node:setLineAnimName("actionframe2")
            end
        else
            node:setLineAnimName("actionframe1")
        end
    end
end

---
-- 每个reel条滚动到底
function MedusaOtherMachine:slotOneReelDown(reelCol)
    BaseFastMachine.slotOneReelDown(self, reelCol)
    local haveSpecial = false
    for iRow = 1, self.m_iReelRowNum, 1 do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if symbolType == self.SYMBOL_WILD2 then
            haveSpecial = true
            break
        end
    end
    if haveSpecial == true then
        gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_wild_down.mp3")
    end
end

function MedusaOtherMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function MedusaOtherMachine:reelDownNotifyChangeSpinStatus()
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
end

function MedusaOtherMachine:playEffectNotifyChangeSpinStatus()
end

function MedusaOtherMachine:playEffectNotifyNextSpinCall()
    self.m_machineIsRun = false
    self.m_parent:playEffectNotifyNextSpinCall()
end

function MedusaOtherMachine:quicklyStopReel(colIndex)
    if self:isVisible() == true and self.m_machineIsRun == true then
        BaseFastMachine.quicklyStopReel(self, colIndex)
    end
end

function MedusaOtherMachine:addObservers()
    gLobalNoticManager:addObserver(self, self.quicklyStopReel, ViewEventType.QUICKLY_SPIN_EFFECT)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = self.m_pauseRef + 1
            Target:pauseMachine()
        end,
        ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = math.max(self.m_pauseRef - 1, 0)
            if self.m_pauseRef <= 0 then
                Target:resumeMachine()
            end
        end,
        ViewEventType.NOTIFY_RESUME_SLOTSMACHINE
    )
end

function MedusaOtherMachine:onExit()
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function MedusaOtherMachine:removeObservers()
    BaseFastMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function MedusaOtherMachine:beginMiniReel()
    self.m_machineIsRun = true
    BaseFastMachine.beginReel(self)
end

-- 消息返回更新数据
function MedusaOtherMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)

    self:updateNetWorkData()
end

function MedusaOtherMachine:enterLevel()
    BaseFastMachine.enterLevel(self)
end

function MedusaOtherMachine:enterLevelMiniSelf()
    BaseFastMachine.enterLevel(self)
end

function MedusaOtherMachine:dealSmallReelsSpinStates()
end

---
--设置bonus scatter 层级
function MedusaOtherMachine:getBounsScatterDataZorder(symbolType)
    return self.m_parent:getBounsScatterDataZorder(symbolType)
end

function MedusaOtherMachine:MachineRule_network_InterveneSymbolMap()
end

function MedusaOtherMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

--检测是否可以增加quest 完成事件
function MedusaOtherMachine:checkAddQuestDoneEffectType()
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function MedusaOtherMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function MedusaOtherMachine:clearCurMusicBg()
end

function MedusaOtherMachine:reelDownNotifyPlayGameEffect()
    self:playGameEffect()
end

function MedusaOtherMachine:initRandomSlotNodes()
    self:randomSlotNodes()
end

function MedusaOtherMachine:getNextReelIsLongRun(reelCol)
    return false
end

function MedusaOtherMachine:setReelLongRun(reelCol)
end

function MedusaOtherMachine:setReelRunInfo()
end

function MedusaOtherMachine:requestSpinResult()
end

function MedusaOtherMachine:showEffect_RespinOver(effectData)
    effectData.p_isPlay = true
    self:playGameEffect()
    return true
end

function MedusaOtherMachine:randomSlotNodes()
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end
            while true do
                if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex, symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                -- 添加到显示列表
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = showOrder

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
end

function MedusaOtherMachine:checkControlerReelType()
    return false
end
return MedusaOtherMachine
