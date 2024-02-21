---
-- island
-- 2018年4月23日
-- CodeGameScreenFivePandeMachine.lua
--
-- 玩法：
--

local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"--
local GameEffectData = require "data.slotsdata.GameEffectData"

local CodeGameScreenFivePandeMachine = class("CodeGameScreenFivePandeMachine", BaseSlotoManiaMachine)
--定义成员变量

--定义关卡特有的信号类型 以下为参考， 从TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1开始
--GameScreenQgodMachine.SYMBOL_TYPE_FLY_GOLD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenFivePandeMachine.SYMBOL_SCORE_10 = 9

CodeGameScreenFivePandeMachine.SYMBOL_FIVEPANDE_SCATTER2 = 141
CodeGameScreenFivePandeMachine.SYMBOL_SUPER_WILF = 142
CodeGameScreenFivePandeMachine.SYMBOL_FIVEPANDE_WILD = 97
CodeGameScreenFivePandeMachine.SYMBOL_COINS = 105
CodeGameScreenFivePandeMachine.SYMBOL_COINS_ACTION = 99

CodeGameScreenFivePandeMachine.SYMBOL_MYSTER_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 38 -- 131
CodeGameScreenFivePandeMachine.SYMBOL_MYSTER_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 39 -- 132

CodeGameScreenFivePandeMachine.SYMBOL_MYSTERY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94

CodeGameScreenFivePandeMachine.EFFECT_TYPE_COLLECT = 102
CodeGameScreenFivePandeMachine.EFFECT_TYPE_COLLECT_BONUS = 103
CodeGameScreenFivePandeMachine.EFFECT_TYPE_SCATTER_CHANGE_WILD = 104

CodeGameScreenFivePandeMachine.m_bTiggerFs = false
CodeGameScreenFivePandeMachine.m_bTiggerBonus = false
CodeGameScreenFivePandeMachine.m_bProduceSlots_InBnous = false
CodeGameScreenFivePandeMachine.m_bProduceSlots_BnousOver = false

-- 假滚 Myster
CodeGameScreenFivePandeMachine.m_bProduceSlots_RunSymbol_1 = 1
CodeGameScreenFivePandeMachine.m_bProduceSlots_RunSymbol_2 = 3

CodeGameScreenFivePandeMachine.SYMBOL_MYSTER_1_GEAR = nil -- 假滚 mystery1 权重
CodeGameScreenFivePandeMachine.SYMBOL_MYSTER_2_GEAR = nil -- 假滚 mystery2 权重
CodeGameScreenFivePandeMachine.m_clickBet = nil

CodeGameScreenFivePandeMachine.m_BnousGear = nil -- bnous中的档位
-- 构造函数
function CodeGameScreenFivePandeMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_ShowBonus = false
    self.m_spinRestMusicBG = true
    --init
    self.m_mysterList = {}
    for i = 1, 6 do
        self.m_mysterList[i] = -1
    end

    self:initGame()
end

function CodeGameScreenFivePandeMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FivePandeConfig.csv", "LevelFivePandeConfig.lua")

    self.m_changeLineFrameTime = 2

    self.SYMBOL_MYSTER_1_GEAR = {5, 15, 5, 15, 5, 15, 10, 6, 10, 6, 3, 0, 2} -- 假滚 mystery1 权重
    self.SYMBOL_MYSTER_2_GEAR = {15, 5, 15, 5, 15, 5, 6, 10, 6, 10, 2, 0, 3} -- 假滚 mystery2 权重
    self.SYMBOL_MYSTER_NAME = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 90, 105, 92, 141}
    self:randomMyster()


    --初始化基本数据
    self:initMachine(self.m_moduleName)
    self.m_collectList = {}
    self.m_changeWildList = {}
    self.m_curFeatureID = nil
    --生成第一次数据
    --    self:produceSlots()
end

function CodeGameScreenFivePandeMachine:scaleMainLayer()

    self.super.scaleMainLayer(self)

    if display.width/display.height <= 920/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 1.035)
        self.m_machineRootScale = self.m_machineRootScale * 1.035
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 30 )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX()  )
    elseif display.width/display.height <= 1152/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 1.04)
        self.m_machineRootScale = self.m_machineRootScale * 1.04
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 55 )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX()  )
    elseif display.width/display.height <= 1228/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 1.03)
        self.m_machineRootScale = self.m_machineRootScale * 1.03
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 55 )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX()  )
    elseif display.width/display.height > 1228/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 0.96)
        self.m_machineRootScale = self.m_machineRootScale * 0.96
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 55 )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX()  )
    end

end
----------------------------- LocalGame数据生成处理 ----------------------

--判断idx 是否相邻
function CodeGameScreenFivePandeMachine:getIdxIsAdjacent(idx1, idx2)
    if (idx1 == 5 and idx2 == 6) or (idx1 == 6 and idx2 == 5) or (idx1 == 11 and idx2 == 12) or (idx1 == 12 and idx2 == 11) or (idx1 == 17 and idx2 == 18) or (idx1 == 18 and idx2 == 17) then
        return false
    end
    if math.abs(idx1 - idx2) == 1 then
        return true
    end
    if math.abs(idx1 - idx2) == 6 then
        return true
    end
end

function CodeGameScreenFivePandeMachine:getReverseIdxTabel(tableTemp)
    if type(tableTemp) ~= "table" then
        assert(false, "传入参数错误")
    end
    local reverseTable = {}
    for i = 1, #tableTemp do
        local idx = tableTemp[i]
        reverseTable[idx] = i
    end
    return reverseTable
end

--随机出一个相邻的坐标
function CodeGameScreenFivePandeMachine:getRandomPos(adjacentPoss, excludePoss)
    local adjacentReverseIdxs = {}
    for i = 1, #adjacentPoss do
        local pos = adjacentPoss[i]
        local idx = self:getPosReelIdx(pos.iX, pos.iY)
        adjacentReverseIdxs[idx] = i
    end
    -- getRowAndColByPos
    local allAjacentIdxs = {}

    local extraPosIdxRevserse = {}
    local excludePossT = excludePoss
    if excludePossT == nil then
        excludePossT = {}
    end

    if self.m_bProduceSlots_InFreeSpin then
        extraPosIdxRevserse = self:getReverseIdxTabel(excludePossT)
    end

    for i = 0, 23 do
        if extraPosIdxRevserse[i] == nil then
            for j = 1, #adjacentPoss do
                local pos = adjacentPoss[j]
                local idx = self:getPosReelIdx(pos.iX, pos.iY)
                if adjacentReverseIdxs[i] == nil and self:getIdxIsAdjacent(i, idx) and self:getReverseIdxTabel(allAjacentIdxs)[i] == nil then
                    allAjacentIdxs[#allAjacentIdxs + 1] = i
                end
            end
        end
    end

    if #allAjacentIdxs == 0 then
        return nil
    end

    local randomIdx = xcyy.SlotsUtil:getArc4Random() % #allAjacentIdxs + 1
    local idx = allAjacentIdxs[randomIdx]
    return self:getRowAndColByPos(idx)
end

------------------------------------------------------------------------

function CodeGameScreenFivePandeMachine:initUI()
    self.m_collectView = util_createView("CodeFivePandeSrc.FivePandeCollectView", self)
    self.m_csbOwner["node_top"]:addChild(self.m_collectView)
    local collectData = self:BaseMania_getCollectData()
    self.m_collectView:initViewData(collectData.p_collectCoinsPool, collectData.p_collectLeftCount, collectData.p_collectTotalCount)

    self.m_betChoiceIcon = util_createView("CodeFivePandeSrc.FivePandeHighLowBetIcon", self)
    self:findChild("Node_highLowBet"):addChild(self.m_betChoiceIcon)
    self:findChild("Node_highLowBet"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100000)
    local enterData = self.m_runSpinResultData
    self:runCsbAction("idle")
    self.m_gameBg:runCsbAction("nomal")

    self.m_tipView = util_createView("CodeFivePandeSrc.FivePandeGameTipClickView")
    self:findChild("Node_TipView"):addChild(self.m_tipView)
    self:findChild("Node_TipView"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

    self:findChild("Node_BonusGame"):setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_EFFECT + 1000)

    self:initFreeSpinBar()
    util_setPositionPercent(self.m_csbNode, 0.44)
    local ratio = display.width / display.height
    if ratio <= 1.34 then
        util_setPositionPercent(self.m_csbNode, 0.47)
    end

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 1
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 3
                soundTime = 2
            elseif winRate > 6 then
                soundIndex = 3
                soundTime = 2
            end

            local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
                print("freespin最后一次 无论是否大赢都播放赢钱音效")
            else
                if winRate >= self.m_HugeWinLimitRate then
                    return
                elseif winRate >= self.m_MegaWinLimitRate then
                    return
                elseif winRate >= self.m_BigWinLimitRate then
                    return
                end
            end
            self.m_winSoundsId = globalMachineController:playBgmAndResume("FivePandeSounds/music_Chinese_last_win_" .. soundIndex .. ".mp3",
                                                    soundTime,0.4,1)
            performWithDelay(self,
                function()
                    self.m_winSoundsId = nil 
                end,soundTime)

        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenFivePandeMachine:isNormalStates()
    local isshow = true
    if self.m_bProduceSlots_InFreeSpin then
        isshow = false
    end

    if self.m_ShowBonus then
        isshow = false
    end

    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == 1 then
        isshow = false
    end

    return isshow
end

function CodeGameScreenFivePandeMachine:initFreeSpinBar()
    -- if globalData.slotRunData.isPortrait == false then
    --     local node_bar = self.m_bottomUI:findChild("node_bar")
    --     self.m_baseFreeSpinBar = util_createView("Levels.FreeSpinBar")
    --     node_bar:addChild(self.m_baseFreeSpinBar)
    --     util_setCsbVisible(self.m_baseFreeSpinBar, false)
    --     --self.m_baseFreeSpinBar:setPosition(18, 0)
    -- end
end

function CodeGameScreenFivePandeMachine:updateCollect(time)
    local collectData = self:BaseMania_getCollectData()
    self.m_collectView:updateCollect(collectData.p_collectCoinsPool, collectData.p_collectLeftCount, collectData.p_collectTotalCount, time)
end

function CodeGameScreenFivePandeMachine:BaseMania_initCollectDataList()
    local CollectData = require "data.slotsdata.CollectData"
    --收集数组
    self.m_collectDataList = {}
    --默认总数
    local pools = {200, 20}
    for i = 1, 2 do
        self.m_collectDataList[i] = CollectData.new()
        self.m_collectDataList[i].p_collectTotalCount = pools[i]
        self.m_collectDataList[i].p_collectLeftCount = 0
        self.m_collectDataList[i].p_collectCoinsPool = 0
        self.m_collectDataList[i].p_collectChangeCount = 0
    end
end

function CodeGameScreenFivePandeMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" then
        self:BaseMania_completeCollectBonus()
        self:updateCollect()
        self:playGameEffect()
        return
    end

    self.m_ShowBonus = true
    local view = util_createView("CodeFivePandeSrc.FivePandeBonusGame")
    local collectData = self:BaseMania_getCollectData()
    view:resetView(
        collectData,
        featureData,
        function()
            -- self:BaseMania_completeCollectBonus()
            -- self:updateCollect()
            gLobalSoundManager:stopBgMusic()
            self:resetMusicBg(true)
            self.m_ShowBonus = false
            self:playGameEffect()
        end,
        self
    )

    -- self:findChild("Node_BonusGame"):addChild(view)
    view:setPosition(display.width / 2, display.height / 2)
    gLobalViewManager:showUI(view)
end

function CodeGameScreenFivePandeMachine:showBonusGame(data, func)
    self.m_ShowBonus = true

    local currFunc = function()
        self.m_ShowBonus = false
        if func then
            func()
        end
    end

    local view = util_createView("CodeFivePandeSrc.FivePandeBonusGame")
    if self.m_isLocalData then
        view:enableLocalData(self)
    end
    view:initViewData(data, currFunc, self)
    view:setPosition(display.width / 2, display.height / 2)
    gLobalViewManager:showUI(view)
    -- self:findChild("Node_BonusGame"):addChild(view)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFivePandeMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FivePande"
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFivePandeMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine:getPreLoadSlotNodes()
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    -- 例子：loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_FLY_GOLD,count =  2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIVEPANDE_SCATTER2, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIVEPANDE_WILD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_COINS, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_COINS_ACTION, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MYSTER_1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MYSTER_2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MYSTERY, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SUPER_WILF, count = 2}
    return loadNode
end

function CodeGameScreenFivePandeMachine:randomMyster()
    local index1 = self:getProMysterIndex(self.SYMBOL_MYSTER_1_GEAR)
    self.m_bProduceSlots_RunSymbol_1 = self.SYMBOL_MYSTER_NAME[index1]
    print("假滚随机 ：" .. self.m_bProduceSlots_RunSymbol_1)

    local index2 = self:getProMysterIndex(self.SYMBOL_MYSTER_2_GEAR)
    self.m_bProduceSlots_RunSymbol_2 = self.SYMBOL_MYSTER_NAME[index2]
    print("假滚随机 ：" .. self.m_bProduceSlots_RunSymbol_2)

    self.m_configData:setMysterSymbol(self.m_bProduceSlots_RunSymbol_1, self.m_bProduceSlots_RunSymbol_2)
end

function CodeGameScreenFivePandeMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil
    if symbolType == self.SYMBOL_SCORE_10 then
        ccbName = "Socre_FivePande_10"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        ccbName = "Socre_FivePande_Scatter1"
    elseif symbolType == self.SYMBOL_FIVEPANDE_SCATTER2 then
        ccbName = "Socre_FivePande_Scatter"
    elseif symbolType == self.SYMBOL_FIVEPANDE_WILD then
        ccbName = "Socre_FivePande_Wild3"
    elseif symbolType == self.SYMBOL_COINS then
        ccbName = "Socre_FivePande_coins"
    elseif symbolType == self.SYMBOL_COINS_ACTION then
        ccbName = "FivePande/Socre_FivePande_coinsactionframe"
    elseif symbolType == self.SYMBOL_SUPER_WILF then
        -- 假滚信号
        ccbName = "Socre_FivePande_Wild2"
    elseif symbolType == self.SYMBOL_MYSTER_1 then
        ccbName = "Socre_FivePande_9"
    elseif symbolType == self.SYMBOL_MYSTER_2 then
        ccbName = "Socre_FivePande_8"
    elseif symbolType == self.SYMBOL_MYSTERY then
        ccbName = "Socre_FivePande_7"
    end

    return ccbName
end

function CodeGameScreenFivePandeMachine:getSlotNodeBySymbolType(symbolType)

    local reelNode = BaseSlotoManiaMachine.getSlotNodeBySymbolType(self,symbolType)

    if symbolType == self.SYMBOL_COINS then
        local txtCoin = reelNode:getCcbProperty("m_lb_coin")
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local betValue = totalBet * 0.01
        if txtCoin then
            txtCoin:setString("$" .. util_formatCoins(betValue, 3))
        end
    end
    return reelNode
end

--小块
function CodeGameScreenFivePandeMachine:getBaseReelGridNode()
    return "CodeFivePandeSrc.FivePandeSlotsNode"
end

function CodeGameScreenFivePandeMachine:updateReelGridNode(node)
    if node and node.p_symbolType == self.SYMBOL_COINS then
        local txtCoin = node:getCcbProperty("m_lb_coin")
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local betValue = totalBet * 0.01
        if txtCoin then
            txtCoin:setString("$" .. util_formatCoins(betValue, 3))
        end
    end
end
----------------------------- 玩法处理 -----------------------------------

---
-- 数据生成之后
-- 改变轮盘ui块生成列表 (可以作用于贴长条等 特殊显示逻辑中)
function CodeGameScreenFivePandeMachine:MachineRule_InterveneReelList()
    -- m_reelDownAnima
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFivePandeMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFivePandeMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_actNode:stopAllActions()
    if self.m_tipView.m_CurrStates ~= self.m_tipView.Over then
        self.m_tipView.m_CurrStates = self.m_tipView.Over
        self.m_tipView:findChild("Panel_1"):setVisible(false)
        self.m_tipView:runCsbAction("shuomingover")
    end

    self:randomMyster()
    self:removeChangeReelDataHandler()
    self:randomMysterList()

    return false
end

---
-- 轮盘停止时调用
-- 改变轮盘滚动后的数据等
function CodeGameScreenFivePandeMachine:MachineRule_stopReelChangeData()
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFivePandeMachine:addSelfEffect()
    self.m_collectList = nil

    self:removeGameEffectType(GameEffect.EFFECT_BONUS)
    self:removeEffectByType(GameEffect.EFFECT_BONUS)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow)
            if node then
                if node.p_symbolType == self.SYMBOL_COINS then
                    if not self.m_collectList then
                        self.m_collectList = {}
                    end
                    self.m_collectList[#self.m_collectList + 1] = node
                    node:runAnim("actionframe")
                end
            end
        end
    end

    if self.m_collectList and #self.m_collectList > 0 then
        local addCount = #self.m_collectList
        --收集金币
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT
        --判断是否触发玩法 触发了需要干预下次滚轴生成
        --self.m_bContralProduct = true
        --    end

        --是否触发收集小游戏
        if self:BaseMania_isTriggerCollectBonus() then -- true or
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT_BONUS
        end
    end
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local  selfData = self.m_runSpinResultData.p_selfMakeData
        local isHaveScatter2 = false
        if selfData and selfData.newGold then
            for k,v in pairs(selfData.newGold) do
                isHaveScatter2 = true
                break
            end
        end
        if isHaveScatter2 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_SCATTER_CHANGE_WILD
        end
    end
end

function CodeGameScreenFivePandeMachine:showEffect_Bonus(effectData)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    --  local data = self:BaseMania_getCollectData()
    -- 停掉背景音乐
    self:clearCurMusicBg()
    self:showBonusGame(
        self.m_collectDataList,
        function()
            -- self:BaseMania_completeCollectBonus()
            -- self:updateCollect()
            gLobalSoundManager:stopBgMusic()
            self:resetMusicBg(true)
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    )
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
    return true
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFivePandeMachine:MachineRule_playSelfEffect(effectData)
    local isCollectGame = nil
    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        if self.m_collectList and #self.m_collectList > 0 then
            self:flyCoins(self.m_collectList)

            local isTrigger = self:BaseMania_isTriggerCollectBonus()

            scheduler.performWithDelayGlobal(
                function()
                    local isTrigger_1 = self:BaseMania_isTriggerCollectBonus()

                    if isTrigger_1 then
                        self:runCsbAction("add")
                    else
                        self.m_collectView:showAddAnim()
                    end
                end,
                1,
                self:getModuleName()
            )

            self:updateCollect(1.1)

            --是否触发收集小游戏
            local waitTimes = 0

            if isTrigger then
                waitTimes = 1.5
            end

            performWithDelay(
                self,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                waitTimes
            )

            self.m_collectList = nil
        end
    end

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT_BONUS then
        -- local data = self:BaseMania_getCollectData()

        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        
        gLobalSoundManager:playSound("FivePandeSounds/sound_FivePande_Trigger_Collect.mp3")

        self.m_collectView:runCsbAction(
            "jiman",
            false,
            function()
                self.m_collectView:runCsbAction("idleframe", true)
            end
        )
        -- 停掉背景音乐
        self:clearCurMusicBg()
        scheduler.performWithDelayGlobal(
            function()
                self:showBonusGame(
                    self.m_collectDataList,
                    function()
                        -- self:BaseMania_completeCollectBonus()
                        -- self:updateCollect()
                        gLobalSoundManager:stopBgMusic()
                        self:resetMusicBg(true)
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            end,
            3.5,
            self:getModuleName()
        )
    end

    if effectData.p_selfEffectType == self.EFFECT_TYPE_SCATTER_CHANGE_WILD then
        self:goldenScatterChangeWild(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end

    return true
end

function CodeGameScreenFivePandeMachine:goldenScatterChangeWild(func)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                if targSp.p_symbolType == self.SYMBOL_FIVEPANDE_SCATTER2 then
                    -- 播放转化音效
                    gLobalSoundManager:playSound("FivePandeSounds/sound_despicablewolf_change_wild.mp3")
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_FIVEPANDE_WILD), self.SYMBOL_FIVEPANDE_WILD)
                    targSp:runAnim("actionframe")
                    targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000)
                    scheduler.performWithDelayGlobal(
                        function()
                            targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SUPER_WILF), self.SYMBOL_SUPER_WILF)
                            targSp:spriteChangeImage(targSp.p_symbolImage, "Symbol/FivePande_wildbig_0.png")
                            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                            local zorder = self:getBounsScatterDataZorder(self.SYMBOL_SUPER_WILF) - iRow
                            targSp:setLocalZOrder(zorder)
                            targSp:setTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))

                            local slotParent = targSp:getParent()
                            local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                            local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                            targSp:removeFromParent()
                            self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + targSp.m_showOrder, targSp:getTag())
                            targSp:setPosition(cc.p(pos.x, pos.y))

                            local linePos = {}
                            linePos[#linePos + 1] = {iX = iRow, iY = iCol}
                            targSp.m_bInLine = true
                            targSp:setLinePos(linePos)
                        end,
                        2.07,
                        self:getModuleName()
                    )
                end
            end
        end
    end
    scheduler.performWithDelayGlobal(
        function()
            if func then
                func()
            end
        end,
        2.2,
        self:getModuleName()
    )
end

function CodeGameScreenFivePandeMachine:showFreeSpinView(effectData)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    local function scatterAnim(...)
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                if self.m_runSpinResultData.p_reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self.m_runSpinResultData.p_reels[iRow][iCol] == self.SYMBOL_FIVEPANDE_SCATTER2 then
                    local posRow = self.m_iReelRowNum - iRow + 1

                    if self:getMaxContinuityBonusCol() >= iCol then
                        local targSp = self:getFixSymbol(iCol, posRow, SYMBOL_NODE_TAG)
                        if targSp ~= nil then
                            local slotParent = targSp:getParent()
                            local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                            local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_4 - posRow -- + ((self.m_iReelRowNum -  iCol) * 10 + posRow  )
                            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                            util_changeNodeParent(self.m_clipParent,targSp,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE  + targSp.m_showOrder)
                            targSp:setPosition(cc.p(pos.x, pos.y))
                            targSp:runAnim("actionframe")
                        end
                    end
                end
            end
        end

        self:playScatterTipMusicEffect()
    end

    local function showView()
        gLobalSoundManager:playSound("FivePandeSounds/sound_despicablewolf_enter_fs.mp3")
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local view = self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    self:changeFivePandeWild(
                        function()
                            self.m_curFeatureID = 0
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end,
                true
            )
            self:addCrazeBuff(view:findChild("Node_2"), "freespinMore")

        else
            local view = self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self:triggerFreeSpinCallFun()

                    self:changeFivePandeWild(
                        function()
                            self.m_curFeatureID = 0
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end
            )
            self:addCrazeBuff(view:findChild("Node_2"),"freespin")
                -- local gameCrazeControlPath = "Activity/GameCrazeControl"
                -- if util_IsFileExist(gameCrazeControlPath .. ".lua") or util_IsFileExist(gameCrazeControlPath .. ".luac") then
                --     local GameCrazeControl = require "Activity.GameCrazeControl"
                --     local GameCrazeControl = require "Activity.GameCrazeControl"
                --     local buffNode = GameCrazeControl:getInstance():pubGetFsBuffAnima()
                --     bg:addChild(buffNode)
                -- end

        end
    end

    scheduler.performWithDelayGlobal(scatterAnim, 0.1, self:getModuleName())
    scheduler.performWithDelayGlobal(showView, 3, self:getModuleName())
end

function CodeGameScreenFivePandeMachine:changeFivePandeWild(func)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node and node.updateLayerTag then
                if node.p_symbolType ~= self.SYMBOL_SUPER_WILF then
                    node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                end
            end
        end
    end

    local isChange = false

    local goldPos = self.m_runSpinResultData.p_selfMakeData.gold
    for k, v in pairs(goldPos) do
        local pos = tonumber(k)
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if targSp then
            if targSp.p_symbolType == self.SYMBOL_FIVEPANDE_SCATTER2 then
                -- 播放转化音效
                gLobalSoundManager:playSound("FivePandeSounds/sound_despicablewolf_change_wild.mp3")

                targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_FIVEPANDE_WILD), self.SYMBOL_FIVEPANDE_WILD)
                targSp:runAnim("actionframe")
                targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000)
                isChange = true
                scheduler.performWithDelayGlobal(
                    function()
                        targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SUPER_WILF), self.SYMBOL_SUPER_WILF)
                        targSp:spriteChangeImage(targSp.p_symbolImage, "Symbol/FivePande_wildbig_0.png")
                        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                        targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                        local linePos = {}
                        linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                        targSp.m_bInLine = true
                        targSp:setLinePos(linePos)
                        if func then
                            func()
                            func = nil
                        end
                    end,
                    2.07,
                    self:getModuleName()
                )
            end
        end
    end
    if not isChange then
        if func then
            func()
        end
    end
end

function CodeGameScreenFivePandeMachine:addCrazeBuff(addNode,type)
    if self.m_gameCrazeBuff then
        local node = addNode:getChildByName("GameCrazeBuff")
        if not node then
            local GameCrazeControl = util_getRequireFile("Activity/GameCrazeControl")
            if GameCrazeControl then
                local buffNode = nil
                if type == "freespin" or type == "freespinMore" or type == "freespinOver" then
                   buffNode = GameCrazeControl:getInstance():pubGetFsBuffAnima()
                else
                    buffNode = GameCrazeControl:getInstance():pubGetFsBarBuffAnima()
                end
                buffNode:setName("GameCrazeBuff")
                addNode:addChild(buffNode)
            end
        else
            node:setVisible(true)
        end
    else
        local buffNode = addNode:getChildByName("GameCrazeBuff")
        if buffNode then
            buffNode:removeFromParent()
        end
    end
end

--remove buff
function CodeGameScreenFivePandeMachine:removeCrazeBuff(addNode,buffNodeName)

    local node = addNode:getChildByName(buffNodeName)
    if node then
        if not self.m_gameCrazeBuff then
            node:removeFromParent()
        else
            node:setVisible(false)
        end
    end

end
---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenFivePandeMachine:levelFreeSpinEffectChange()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_STATUS, true)
    self:findChild("node_top"):setVisible(false)
    self:addCrazeBuff(self:findChild("Node_7"), "freespinBar")
    self:runCsbAction("changefs")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "changefs")
    self.m_collectView:showGray()
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenFivePandeMachine:levelFreeSpinOverChangeEffect(content)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node and node.updateLayerTag then
                node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            end
        end
    end


    self:findChild("node_top"):setVisible(true)

    self:removeCrazeBuff(self:findChild("Node_7"),"GameCrazeBuff")

    self:runCsbAction("change")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "change")
    self.m_collectView:hideGray()
end


function CodeGameScreenFivePandeMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("FivePandeSounds/sound_despicablewolf_bonus_win.mp3")
    local view =
        self:showFreeSpinOver(
        globalData.slotRunData.lastWinCoin,
        globalData.slotRunData.totalFreeSpinCount,
        function()
            self:triggerFreeSpinOverCallFun()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_STATUS, false)
        end
    )
    self:addCrazeBuff(view:findChild("Node_2"), "freespinOver")
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node}, 700)
end

function CodeGameScreenFivePandeMachine:removeFlynode(node)
    node:setVisible(true)
    node:removeFromParent()
    local symbolType = node.p_symbolType
    self:pushSlotNodeToPoolBySymobolType(symbolType, node)
end

--收集玩法
function CodeGameScreenFivePandeMachine:flyCoins(list)
    local endPos = self.m_collectView:getCollectPos()
    local bezTime = 1
    gLobalSoundManager:playSound("FivePandeSounds/sound_despicablewolf_bonus.mp3")
    local isShowCollect = false

    for k, node in pairs(list) do
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local coins = self:getSlotNodeBySymbolType(self.SYMBOL_COINS_ACTION)
        self:addChild(coins, 99999)
        coins:runAnim("actionframe")
        coins:setPosition(newStartPos)

        local bez = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        coins:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.5),
                bez,
                cc.CallFunc:create(
                    function()
                        if isShowCollect == false then
                            isShowCollect = true
                        end

                        self:removeFlynode(coins)
                        coins = nil
                    end
                )
            )
        )
    end
end

---------------------------------------------------------------------------
function CodeGameScreenFivePandeMachine:MachineRule_initGame(spinData)
end

function CodeGameScreenFivePandeMachine:initSuperWildSlotNodesByNetData()
    if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        return
    end

    local goldPos = self.m_runSpinResultData.p_selfMakeData.gold
    for k, v in pairs(goldPos) do
        local pos = tonumber(k)
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if targSp then
            targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000)
            targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SUPER_WILF), self.SYMBOL_SUPER_WILF)
            targSp:spriteChangeImage(targSp.p_symbolImage, "#Symbol/FivePande_wildbig_0.png")
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
        end
    end
end
---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenFivePandeMachine:initCloumnSlotNodesByNetData()
    BaseSlotoManiaMachine.initCloumnSlotNodesByNetData(self)

    self:initSuperWildSlotNodesByNetData()
end

function CodeGameScreenFivePandeMachine:initCollectInfo(spinData, lastBetId, isTriggerCollect)
    self:updateCollect()
end

function CodeGameScreenFivePandeMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            self:playEnterGameSound("FivePandeSounds/music_despicablewolf_welcome.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    -- self:resetMusicBg()
                    -- self:setMinMusicBGVolume()
                end,
                2,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenFivePandeMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self:upateBetLevel()

    performWithDelay(
        self,
        function()
            self:showChoiceBetView()
        end,
        0.2
    )

    if self:isNormalStates() then
        self.m_tipView.m_CurrStates = self.m_tipView.Start
        self.m_tipView:runCsbAction("shuomingstart")
        performWithDelay(
            self.m_actNode,
            function()
                self.m_tipView:findChild("Panel_1"):setVisible(true)

                performWithDelay(
                    self.m_actNode,
                    function()
                        if self.m_tipView.m_CurrStates ~= self.m_tipView.Over then
                            self.m_tipView.m_CurrStates = self.m_tipView.Over
                            self.m_tipView:findChild("Panel_1"):setVisible(false)
                            self.m_tipView:runCsbAction("shuomingover", false)
                        end
                    end,
                    3
                )
            end,
            0.5
        )
    end
end
--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenFivePandeMachine:upateBetLevel()
    local minBet = self:getMinBet()

    self:updateHighLowBetLock(minBet)
end

function CodeGameScreenFivePandeMachine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenFivePandeMachine:getMinBet()
    local minBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end
function CodeGameScreenFivePandeMachine:updateHighLowBetIcon(minBet)
end
function CodeGameScreenFivePandeMachine:updateHighLowBetLock(minBet)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1
            self.m_clickBet = true
            self.m_betChoiceIcon:runCsbAction(
                "over",
                false,
                function()
                    if self.m_clickBet then
                        self.m_betChoiceIcon:setVisible(false)
                    end
                end
            )
        else
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0
            self.m_clickBet = false
            self.m_betChoiceIcon:setVisible(true)
            self.m_betChoiceIcon:runCsbAction(
                "start",
                false,
                function()
                end
            )
        end
    end
end
function CodeGameScreenFivePandeMachine:unlockHigherBet()
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end
    -- self.m_betChoiceIcon.m_Button_1:setBright(false)
    -- self.m_betChoiceIcon.m_Button_1:setTouchEnabled(false)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end
function CodeGameScreenFivePandeMachine:showChoiceBetView()
    if self:isNormalStates() then
        if self.m_betLevel == 0 then
            self.highLowBetView = util_createView("CodeFivePandeSrc.FivePandeHighLowBetView", self)
            gLobalViewManager:showUI(self.highLowBetView)
        end
    end
end
function CodeGameScreenFivePandeMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upateBetLevel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )

    gLobalNoticManager:addObserver(
        self,
        function(params, num) -- 改变 freespin count显示
            self:changeFreeSpinByCountOutLine(params, num)
        end,
        ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM
    )

    -- 如果需要改变父类事件监听函数，则在此处修改(具体哪些监听看父类的addObservers)
end

function CodeGameScreenFivePandeMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    self:removeChangeReelDataHandler()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenFivePandeMachine:removeObservers()
    BaseSlotoManiaMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

---
--特殊删除盘面添加特殊元素
function CodeGameScreenFivePandeMachine:clearChildList()
end

function CodeGameScreenFivePandeMachine:getMaxContinuityBonusCol()
    local maxColIndex = 0

    local isContinuity = true

    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0

        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_FIVEPANDE_SCATTER2 then
                bonusNum = bonusNum + 1
                if isContinuity then
                    maxColIndex = iCol
                end
            end
        end
        if bonusNum == 0 then
            isContinuity = false
            break
        end
    end

    return maxColIndex
end

--改变下落音效
function CodeGameScreenFivePandeMachine:changeReelDownAnima(parentData)
    if parentData.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or parentData.symbolType == self.SYMBOL_FIVEPANDE_SCATTER2 then
        if self:getMaxContinuityBonusCol() >= parentData.cloumnIndex  then
            parentData.reelDownAnima = "buling"
            parentData.reelDownAnimaSound = "Sounds/bonus_scatter_1.mp3"
        end
        parentData.order = REEL_SYMBOL_ORDER.REEL_ORDER_3 + (( self.m_iReelRowNum - parentData.rowIndex )*10 + parentData.cloumnIndex)
    end
end

-- --设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenFivePandeMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i = 1, self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum >= 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 2 then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[1] then
        if nodeNum >= 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum > 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

--设置bonus scatter 信息
function CodeGameScreenFivePandeMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column] -- 快滚信息
    local runLen = reelRunData:getReelRunLen() -- 本列滚动长度
    local allSpecicalSymbolNum = specialSymbolNum -- bonus或者scatter的数量（上一轮，判断后得到的）
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType) -- 获得是否进行长滚逻辑和播放长滚动画（true为进行或播放）

    local soundType = runStatus.DUANG
    local nextReelLong = false

    -- scatter 列数限制 self.m_ScatterShowCol 为空则默认为 五列全参与长滚 在：getRunStatus判断
    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    -- for 这里的代码块只是为了添加scatter或者bonus快滚停止时 的音效和动画
    for row = 1, iRow do
        local targetSymbolType = self:getSymbolTypeForNetData(column,row,runLen)
        if targetSymbolType == symbolType or targetSymbolType == self.SYMBOL_FIVEPANDE_SCATTER2 then

            local bPlaySymbolAnima = bPlayAni

            allSpecicalSymbolNum = allSpecicalSymbolNum + 1

            if bRun == true then
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)
            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效

                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return allSpecicalSymbolNum, bRunLong
end


function CodeGameScreenFivePandeMachine:setReelRunInfo( )
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0

    local addLens = false

    for col = 1, iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        if bRunLong == true then --如果上一列长滚
            longRunIndex = longRunIndex + 1 -- 长滚统计加1

            local runLen = self:getLongRunLen(col, longRunIndex) -- 获得本列的长滚动长度
            local preRunLen = reelRunData:getReelRunLen() -- 获得本列普通滚动长度
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen) -- 设置本列滚动长度为快滚长度
        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 8)
                self:setLastReelSymbolList()
            end
        end

        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)
        -- bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
        local maxCol = self:getMaxContinuityBonusCol()
        --if  col > maxCol then
        self.m_reelRunInfo[col]:setNextReelLongRun(false)
        bRunLong = false
        --elseif maxCol == col  then
        -- if bRunLong then
        --     addLens = true
        -- end
        --end
    end --end  for col=1,iColumn do
end

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenFivePandeMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFivePandeMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCoins = self.m_runSpinResultData.p_collectNetData[1].collectCoinsPool
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        self:BaseMania_updateCollect(addCount, addCoins, 1, totalCount)
    end
end
function CodeGameScreenFivePandeMachine:getNetWorkModuleName()
    return "PandaRichesV2"
end

function CodeGameScreenFivePandeMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    -- 添加jackpotCoins当前值 , 用来服务器计算赢钱  , 从最大到最小
    local jackpotCoins = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
    -- for i=1,20 do

    --     local jackpotCoin = self:BaseMania_getJackpotScore(i,betCoin)
    --     if jackpotCoin == 0 then
    --         break
    --     else
    --         jackpotCoins[i] = jackpotCoin
    --     end

    -- end

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = nil,
        jackpot = self.m_jackpotList,
        jackpotCoins = jackpotCoins,
        betLevel = self:getBetLevel()
    }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

--是否触发收集小游戏
function CodeGameScreenFivePandeMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end

--更新收集数据 addCount增加的数量  addCoins增加的奖金
function CodeGameScreenFivePandeMachine:BaseMania_updateCollect(addCount, addCoins, index, totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectCoinsPool = addCoins
        self.m_collectDataList[index].p_collectChangeCount = 0
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

--收集完成重置收集进度
function CodeGameScreenFivePandeMachine:BaseMania_completeCollectBonus(index, totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectTotalCount = totalCount or 200
        self.m_collectDataList[index].p_collectLeftCount = totalCount or 200
        self.m_collectDataList[index].p_collectCoinsPool = 0
        self.m_collectDataList[index].p_collectChangeCount = 0
    end
end

function CodeGameScreenFivePandeMachine:getProMysterIndex(array)
    -- self.SYMBOL_MYSTER_1_GEAR = { 5,15, 5,15, 5,15,10, 6,10, 6,3,3,2}  -- 假滚 mystery1 权重
    -- self.SYMBOL_MYSTER_2_GEAR = {15, 5,15, 5,15, 5, 6,10, 6,10,2,3,3}  -- 假滚 mystery2 权重
    -- self.SYMBOL_MYSTER_NAME =   { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,"Scatter1","coins","Wild","Scatter2"}  -- 假滚 mystery2 权重
    local index = 1
    local Gear = 0
    local tableGear = {}
    for k, v in pairs(array) do
        Gear = Gear + v
        table.insert(tableGear, Gear)
    end

    local randomNum = math.random(1, Gear)

    for kk, vv in pairs(tableGear) do
        if randomNum <= vv then
            return kk
        end
    end

    return index
end

---
--设置bonus scatter 层级
function CodeGameScreenFivePandeMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_FIVEPANDE_SCATTER2 or symbolType == self.SYMBOL_FIVEPANDE_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.SYMBOL_COINS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
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

---
-- 显示五个元素在同一条线效果
function CodeGameScreenFivePandeMachine:showEffect_FiveOfKind(effectData)
    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

---
-- 重连更新freespin 剩余次数
--
function CodeGameScreenFivePandeMachine:changeFreeSpinByCountOutLine(params, changeNum)
    if changeNum and type(changeNum) == "number" then
        if globalData.slotRunData.totalFreeSpinCount == changeNum then
            return
        end
        local leftFsCount = globalData.slotRunData.freeSpinCount - changeNum
        local totalFsCount = globalData.slotRunData.totalFreeSpinCount
        self:updateFreespinCount(leftFsCount, totalFsCount)
    end
end

---
-- 更新freespin 剩余次数
--
function CodeGameScreenFivePandeMachine:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

function CodeGameScreenFivePandeMachine:updateFreespinCount(leftCount, totalCount)
    -- self.m_csbOwner["m_lb_num"]:setString("FREE SPINS: "..leftCount)
    self.m_csbOwner["BitmapFontLabel_4_0"]:setString(totalCount - leftCount)
    self.m_csbOwner["BitmapFontLabel_4"]:setString(totalCount)
end

function CodeGameScreenFivePandeMachine:checkShowTipView()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return
    end

    if self.m_tipView.m_CurrStates == self.m_tipView.start then
        return
    end

    if not self:isNormalStates() then
        return
    end

    self.m_tipView:stopAllActions()

    self.m_tipView.m_CurrStates = self.m_tipView.Start
    self.m_tipView:runCsbAction("shuomingstart")
    performWithDelay(
        self.m_actNode,
        function()
            self.m_tipView:findChild("Panel_1"):setVisible(true)
        end,
        0.5
    )
end

function CodeGameScreenFivePandeMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsLeftCount then
                if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                    delayTime = 0.5
                end
            end
        end

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
end

function CodeGameScreenFivePandeMachine:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenFivePandeMachine:checktriggerSpecialGame()
    local istrigger = false

    local features = self.m_runSpinResultData.p_features

    if features then
        if #features > 1 then
            istrigger = true
            if features[2] == 5 then
                if not self.m_ShowBonus then
                    istrigger = false
                end
            end
        end
    end

    return istrigger
end

function CodeGameScreenFivePandeMachine:isShowChooseBetOnEnter()
    return self.m_bProduceSlots_InFreeSpin ~= true and self.m_betLevel == 0
end

--消息返回
function CodeGameScreenFivePandeMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end


    if spinData.action == "SPIN" then
        release_print("消息返回胡来了")
        print(cjson.encode(spinData))

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        self:setNetMysteryType()

        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

function CodeGameScreenFivePandeMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end

--使用现在获取的数据
function CodeGameScreenFivePandeMachine:setNetMysteryType()
    self.m_changeReelDataId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_bNetSymbolType = true
            local bRunLong = false
            for i = 1, #self.m_mysterList do
                local symbolInfo = self:getColIsSameSymbol(i)
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
        0.5,
        "changeReelData"
    )
end

function CodeGameScreenFivePandeMachine:changeSlotReelDatas(_col, _bRunLong)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData, _bRunLong)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenFivePandeMachine:checkUpdateReelDatas(parentData, _bRunLong)
    local reelDatas = nil

    -- if _bRunLong == true then
    --     reelDatas = self.m_configData:getRunLongDatasByColumnIndex(parentData.cloumnIndex)
    -- else
    --     reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    -- end

    reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

--随机信号
function CodeGameScreenFivePandeMachine:getReelSymbolType(parentData)
    local cloumnIndex = parentData.cloumnIndex
    if self.m_bNetSymbolType == true then
        if self.m_mysterList[cloumnIndex] ~= -1 then
            return self.m_mysterList[cloumnIndex]
        end
    end
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    return symbolType
end

function CodeGameScreenFivePandeMachine:getColIsSameSymbol(_iCol)
    local reelsData = self.m_runSpinResultData.p_reels
    if reelsData and next(reelsData) then
        local symbolInfo = {}
        local tempType
        local symbolType = nil
        for iRow = 1, self.m_iReelRowNum do
            tempType = reelsData[iRow][_iCol]
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

function CodeGameScreenFivePandeMachine:randomMysterList()
    self.m_bNetSymbolType = false
    for i = 1, #self.m_mysterList do
        local symbolInfo = self:getColIsSameSymbol(i)
        self.m_mysterList[i] = symbolInfo.symbolType
    end

    self.m_configData:setMysterSymbolList(self.m_mysterList)
end

return CodeGameScreenFivePandeMachine
