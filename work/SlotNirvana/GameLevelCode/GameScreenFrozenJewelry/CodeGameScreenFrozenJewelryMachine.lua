---
-- island li
-- 2019年1月26日
-- CodeGameScreenFrozenJewelryMachine.lua
--
-- 玩法：
--
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local BaseDialog = util_require("Levels.BaseDialog")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local CodeGameScreenFrozenJewelryMachine = class("CodeGameScreenFrozenJewelryMachine", BaseNewReelMachine)

CodeGameScreenFrozenJewelryMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFrozenJewelryMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 -- 自定义的小块类型
CodeGameScreenFrozenJewelryMachine.Socre_FrozenJewelry_MYSTERY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

CodeGameScreenFrozenJewelryMachine.BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenFrozenJewelryMachine.COLLECT_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenFrozenJewelryMachine.SELECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 自定义动画的标识
CodeGameScreenFrozenJewelryMachine.TRIGGER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- 自定义动画的标识
CodeGameScreenFrozenJewelryMachine.REFRESH_FS_MULTIPLE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 -- 自定义动画的标识

local FEATURE_SELECT = 7 --选择玩法

--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

local BTN_CLICK_SOUND = "FrozenJewelrySounds/sound_FrozenJewelry_btn_click.mp3"

-- 构造函数
function CodeGameScreenFrozenJewelryMachine:ctor()
    CodeGameScreenFrozenJewelryMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

    self.m_isDoubleReel = false

    self.m_isTriggerAni = false

    self.m_curChoose = -1
    --是否改变freespin类型
    self.m_isChangeFreeType = false
    self.m_isShowSelectView = false
    self.m_isShowFreeSpinView = false
    --init
    self:initGame()

    self.m_longRunCol = {}

    self.m_scatterNodes = {}

    self.m_reelDownByCol = {}
end

function CodeGameScreenFrozenJewelryMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFrozenJewelryMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FrozenJewelry"
end

function CodeGameScreenFrozenJewelryMachine:getBottomUINode()
    return "CodeFrozenJewelrySrc.FrozenJewelryBottomNode"
end

--小块
function CodeGameScreenFrozenJewelryMachine:getBaseReelGridNode()
    return "CodeFrozenJewelrySrc.FrozenJewelrySlotsNode"
end

function CodeGameScreenFrozenJewelryMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg

    self.m_gameBg2 = util_createAnimation("FrozenJewelry/FrozenJewelry_Bg_tx.csb")
    self.m_gameBg:findChild("ef_jiguang"):addChild(self.m_gameBg2)
    self.m_gameBg2:runCsbAction("idleframe", true)

    --切换光效
    local switchLight = util_createAnimation("FrozenJewelry_qiehuan_gx.csb")
    self.m_gameBg:findChild("qihuan_gx"):addChild(switchLight)
    self.m_switchLight = switchLight
    switchLight:setVisible(false)
    -- self:showBaseMachineView(false)
    -- switchLight:runCsbAction()
end

--[[
    切换背景动画(中线不满16次)
]]
function CodeGameScreenFrozenJewelryMachine:changeBgAni(bgType)
    if bgType == "base_free" then
        self.m_gameBg:runCsbAction(
            "base_free",
            false,
            function()
                self:changeBgAni("free_idle")
            end
        )
    elseif bgType == "free_base" then
        self.m_gameBg:runCsbAction(
            "free_base",
            false,
            function()
                self:changeBgAni("base_idle")
            end
        )
    elseif bgType == "base_bonus" then
        self.m_gameBg:runCsbAction(
            "base_bonus",
            false,
            function()
                self:changeBgAni("bonus_idle")
            end
        )
    elseif bgType == "bonus_base" then
        self.m_gameBg:runCsbAction(
            "bonus_base",
            false,
            function()
                self:changeBgAni("base_idle")
            end
        )
    elseif bgType == "free_bouns" then
        self.m_gameBg:runCsbAction(
            "free_bouns",
            false,
            function()
                self:changeBgAni("bonus_idle")
            end
        )
    elseif bgType == "bouns_free" then
        self.m_gameBg:runCsbAction(
            "bouns_free",
            false,
            function()
                self:changeBgAni("free_idle")
            end
        )
    elseif bgType == "free_choose" then
        self.m_gameBg:runCsbAction(
            "free_choose",
            false,
            function()
                self:changeBgAni("idle_choose")
            end
        )
    elseif bgType == "bonus_idle" then
        self.m_gameBg:runCsbAction("idle_bonus", true)
    elseif bgType == "base_idle" then
        self.m_gameBg:runCsbAction("idle_base", true)

        self:setMachineType(bgType)
    elseif bgType == "choose_idle" then
        self.m_gameBg:runCsbAction("idle_choose", true)
    elseif bgType == "free_idle" then
        self.m_gameBg:runCsbAction("idle_free", true)
        self:setMachineType(bgType)
    end
end

--[[
    设置轮盘样式
]]
function CodeGameScreenFrozenJewelryMachine:setMachineType(bgType)
    if bgType == "base_idle" then
        self:findChild("Frame_Base"):setVisible(true)
        self:findChild("Frame_Free"):setVisible(false)
        self:findChild("reel_bg_base"):setVisible(true)
        self:findChild("reel_bg_free"):setVisible(false)
        self.m_collectBox:setVisible(true)
        self:initCollectBox()
    elseif bgType == "free_idle" then
        self:findChild("Frame_Base"):setVisible(false)
        self:findChild("Frame_Free"):setVisible(true)
        self:findChild("reel_bg_base"):setVisible(false)
        self:findChild("reel_bg_free"):setVisible(true)
        self.m_collectBox:setVisible(false)
        self:findChild("Node_2"):setVisible(false)
    end
end

---
-- 检测上次feature 数据
--
function CodeGameScreenFrozenJewelryMachine:checkNetDataFeatures()
    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN and self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then -- 有freespin
            -- self:sortGameEffects( )
            -- self:playGameEffect()
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true

            if self.checkControlerReelType and self:checkControlerReelType() then
                globalMachineController.m_isEffectPlaying = true
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]

                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1

                        local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
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
                end
                if checkEnd == true then
                    break
                end
            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
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

            if self.checkControlerReelType and self:checkControlerReelType() then
                globalMachineController.m_isEffectPlaying = true
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

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

--[[
    @desc: 断线重连时处理 是否有feature 
    time:2019-01-04 17:19:32
    @return:
]]
function CodeGameScreenFrozenJewelryMachine:checkHasFeature()
    local hasFeature = false
    local features

    if self.m_initSpinData ~= nil and self.m_initSpinData.p_features ~= nil and #self.m_initSpinData.p_features > 0 then
        features = self.m_initSpinData.p_features
    end

    if self.m_initFeatureData then
        features = self.m_initFeatureData.p_data.features
    end

    if features then
        for i = 1, #features do
            local featureID = features[i]
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN or featureID == SLOTO_FEATURE.FEATURE_RESPIN or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == FEATURE_SELECT then
                hasFeature = true
            end
        end
    end

    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        hasFeature = true
    end

    return hasFeature
end

-- function CodeGameScreenFrozenJewelryMachine:initGameStatusData(gameData)
--     CodeGameScreenFrozenJewelryMachine.super.initGameStatusData(self, gameData)

--     self.m_level_change_reel = 6
-- end

function CodeGameScreenFrozenJewelryMachine:playSpineAni(spine, key, loop, func)
    util_spinePlay(spine, key, loop)
    util_spineEndCallFunc(spine, key, func)
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenFrozenJewelryMachine:initGameStatusData(gameData)
    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
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
        self.m_initSpinData.p_features = self.m_initFeatureData.p_data.features
        self.m_initSpinData.p_freeSpinsLeftCount = self.m_initFeatureData.p_data.freespin.freeSpinsLeftCount
        self.m_initSpinData.p_freeSpinNewCount = self.m_initFeatureData.p_data.freespin.freeSpinNewCount
        self.m_initSpinData.p_freeSpinsTotalCount = self.m_initFeatureData.p_data.freespin.freeSpinsTotalCount
    -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "init"
        gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME, params)
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

    self:initMachineGame()
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenFrozenJewelryMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    local featureID = self.m_runSpinResultData.p_features[2]

    local isInFs = false
    if
        hasFreepinFeature == false and self.m_initSpinData.p_freeSpinsTotalCount ~= nil and self.m_initSpinData.p_freeSpinsTotalCount > 0 and
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or (hasReSpinFeature == true or hasBonusFeature == true))
     then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end
    if featureID == FEATURE_SELECT then
        isInFs = false
    end

    if isInFs == true then
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:setCurrSpinMode(FREE_SPIN_MODE)

        if self:checkTriggerFsOver() then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end

        -- 发送事件显示赢钱总数量
        local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenFrozenJewelryMachine:checkInitSlotsWithEnterLevel()
    local isTriggerCollect = false
    local featureID = self.m_initSpinData.p_features[2]

    if self.m_initFeatureData then
        featureID = self.m_initFeatureData.p_data.features[2]
        self.m_iFreeSpinTimes = self.m_initFeatureData.p_data.freespin.freeSpinsLeftCount
        globalData.slotRunData.freeSpinCount = self.m_initFeatureData.p_data.freespin.freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_initFeatureData.p_data.freespin.freeSpinsTotalCount
    end
    if self.m_initFeatureData ~= nil or (featureID and featureID == FEATURE_SELECT) then
        isTriggerCollect = true
        -- 只处理纯粹feature 的类型， 如果有featureData 表明已经处于进行中了， 则直接弹出小游戏或者其他面板显示对应进度
        -- 如果上次退出时，处于feature中那么初始化各个关卡的feature 内容，
        self:initFeatureInfo(self.m_initSpinData, self.m_initFeatureData)
    end

    self:MachineRule_initGame(self.m_initSpinData)

    --初始化收集数据
    if self.m_collectDataList ~= nil then
        self:initCollectInfo(self.m_initSpinData, self.m_initBetId, isTriggerCollect)
    end

    if self.m_jackpotList ~= nil then
        self:initJackpotInfo(self.m_jackpotList, self.m_initBetId)
    end
end

function CodeGameScreenFrozenJewelryMachine:initFeatureInfo(spinData, featureData)
    self:addSelectEffect(true)
end

function CodeGameScreenFrozenJewelryMachine:initFreeSpinBar()
    local node_bar = self:findChild("Free_Bar")
    self.m_baseFreeSpinBar = util_createView("CodeFrozenJewelrySrc.FrozenJewelryFreespinBarView", {machine = self})
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)

    self.m_freeSpinMultiple = util_createView("CodeFrozenJewelrySrc.FrozenJewelryFreeSpinMultipeBar", {machine = self})
    self:findChild("Free_Multiplier"):addChild(self.m_freeSpinMultiple)
    util_setCsbVisible(self.m_freeSpinMultiple, false)
end

function CodeGameScreenFrozenJewelryMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_freeSpinMultiple:setVisible(true)
    self.m_jackpot_bar:setVisible(false)
    self.m_baseFreeSpinBar:showBar()

    self.m_baseFreeSpinBar:changeFreeSpinByCount()

    if self.m_curChoose ~= 2 then
        self.m_freeSpinMultiple:refreshMutiple(2, false)
    end
end

function CodeGameScreenFrozenJewelryMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    util_setCsbVisible(self.m_freeSpinMultiple, false)
    self.m_jackpot_bar:setVisible(true)
    self.m_freeSpinMultiple:idleAni1()
end

--[[
    显示主轮盘
]]
function CodeGameScreenFrozenJewelryMachine:showBaseMachineView(isShow)
    self:findChild("Node_1"):setVisible(isShow)
end

function CodeGameScreenFrozenJewelryMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_FrozenJewelryView = util_createView("CodeFrozenJewelrySrc.FrozenJewelryView")
    -- self:findChild("xxxx"):addChild(self.m_FrozenJewelryView)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    --scatter落地层
    self.m_node_scatter = cc.Node:create()
    self.m_clipParent:addChild(self.m_node_scatter, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 200)

    --jackpot
    self.m_jackpot_bar = util_createView("CodeFrozenJewelrySrc.FrozenJewelryJackPotBarView")
    self:findChild("Jackpot"):addChild(self.m_jackpot_bar)
    self.m_jackpot_bar:initMachine(self)

    --金框
    self.m_csb_lock = util_createAnimation("FrozenJewelry_Lock.csb")
    self.m_clipParent:addChild(self.m_csb_lock, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 3000)
    self.m_csb_lock:setPosition(util_convertToNodeSpace(self:findChild("Lock"), self.m_clipParent))

    --收集进度宝箱
    self.m_collectBox = util_createView("CodeFrozenJewelrySrc.FrozenJewelryCollectBar")
    self:findChild("Box"):addChild(self.m_collectBox)

    --bonus界面
    self.m_bonusView = util_createView("CodeFrozenJewelrySrc.FrozenJewelryBonusView", {machine = self})
    self:findChild("root"):addChild(self.m_bonusView)
    self.m_bonusView:setPosition(cc.p(-display.width / 2, -display.height / 2))
    self.m_bonusView:setVisible(false)

    --mode按钮
    self.m_modeItem = util_createView("CodeFrozenJewelrySrc.FrozenJewelryModeItem", {machine = self})
    self:findChild("Mode"):addChild(self.m_modeItem)

    --修改free类型按钮
    self.m_changeFreeItem = util_createView("CodeFrozenJewelrySrc.FrozenJewelryChangeFreeTypeItem", {machine = self})
    self:findChild("Free_Button"):addChild(self.m_changeFreeItem)
    self.m_changeFreeItem:hideItem()

    --预告中奖
    self.m_noticeAni = util_createAnimation("FrozenJewelry_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_noticeAni)
    self.m_noticeAni:setVisible(false)

    self:changeBgAni("base_idle")
end

function CodeGameScreenFrozenJewelryMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            self:playEnterGameSound("FrozenJewelrySounds/sound_FrozenJewelry_enter_game.mp3")
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenFrozenJewelryMachine:getMinBet()
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据(数值配高低bet列表)
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

function CodeGameScreenFrozenJewelryMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    local featureID
    local fsWinCoins = 0
    if self.m_runSpinResultData and self.m_runSpinResultData.p_features then
        featureID = self.m_runSpinResultData.p_features[2]
        fsWinCoins = self.m_runSpinResultData.p_fsWinCoins
    end
    if self.m_initFeatureData then
        featureID = self.m_initFeatureData.p_data.features[2]
    end

    if self.m_initSpinData and self.m_initSpinData.p_fsExtraData then
        local kind = self.m_initSpinData.p_fsExtraData.kind
        local leftCount = self.m_initSpinData.p_freeSpinsLeftCount
        if self.m_initFeatureData then
            kind = self.m_initFeatureData.p_data.freespin.extra.kind
        end

        if leftCount and leftCount > 0 then
            if kind and kind == "superfree" then
                self.m_curChoose = 2
            elseif kind and kind == "free" then
                self.m_curChoose = 1
            end

            if fsWinCoins > 0 then
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoins))
            end
        else
            self.m_curChoose = -1
        end
    end

    CodeGameScreenFrozenJewelryMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self:checkChangeReel(true)

    self:initCollectBox()

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and (not featureID) then
        local explainView =
            util_createView(
            "CodeFrozenJewelrySrc.FrozenJewelryExplainView",
            {
                func = function()
                    local isFirstIn = gLobalDataManager:getNumberByField("FrozenJewelryFirstIn", 0)
                    if isFirstIn ~= 1 then
                        self:showModeView()
                    end
                    gLobalDataManager:setNumberByField("FrozenJewelryFirstIn", 1, true)
                end
            }
        )
        gLobalViewManager:showUI(explainView)
        explainView:findChild("root"):setScale(self.m_machineRootScale)
    -- explainView:setPosition(cc.p(display.center.x,display.center.y))
    end

    if self.m_isInitReelByData then
        for iCol = 1, self.m_iReelColumnNum do
            local rowNum = 3
            if self.m_isDoubleReel and iCol == 3 then
                rowNum = 6
            end
            for iRow = 1, rowNum do
                local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if symbolNode then
                    symbolNode:changeParentToOtherNode(self.m_node_scatter)
                    self.m_scatterNodes[#self.m_scatterNodes + 1] = symbolNode
                end
            end
        end
    end
end

--[[
    初始化收集进度
]]
function CodeGameScreenFrozenJewelryMachine:initCollectBox()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local boxLevel = 1
    if selfData then
        boxLevel = selfData.wildlevel or 1
    end

    if boxLevel > 1 then
        self:findChild("Node_2"):setVisible(true)
    end

    local aniName = {"idle", "idle1", "idle2"}
    self:runCsbAction(aniName[boxLevel], true)
    self.m_collectBox:setStatus(boxLevel)
end

--[[
    更新收集进度
]]
function CodeGameScreenFrozenJewelryMachine:updateCollectBox(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end
    local boxLevel = selfData.wildlevel or 1
    if selfData and selfData.jackpot then
        --飞粒子动画
        self:collectWildSymbol(
            function()
                self.m_collectBox:collectAni(
                    3,
                    function()
                        if type(func) == "function" then
                            func()
                        end
                    end
                )
            end
        )
    else
        self:collectWildSymbol(
            function()
                self.m_collectBox:collectAni(
                    boxLevel,
                    function()
                    end
                )
            end
        )
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    检测是否需要更改轮盘
]]
function CodeGameScreenFrozenJewelryMachine:checkChangeReel(isInit)
    local minBet = self:getMinBet()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    --传给服务器用的字段,告诉服务器当前是高bet还是低bet
    self.m_iBetLevel = (totalBet >= minBet) and 1 or 0
    local curSpinMode = self:getCurrSpinMode()
    if totalBet >= minBet and not self.m_isDoubleReel then
        if not isInit then
            gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_refresh_reel_high_bet.mp3")
        end

        self.m_configData.p_reelRunDatas = {16, 19, 51, 25, 28}
        self.m_isDoubleReel = true

        self:resetMidReels(self.m_iReelRowNum)

        self.m_csb_lock:setVisible(true)
        self.m_csb_lock:stopAllActions()
        self.m_csb_lock:runCsbAction("actionframe")

        self.m_modeItem:setVisible(false)
    elseif totalBet < minBet and self.m_isDoubleReel then
        if not isInit then
            gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_refresh_reel_low_bet.mp3")
        end

        self.m_configData.p_reelRunDatas = {16, 19, 25, 25, 28}
        self.m_isDoubleReel = false
        self:resetMidReels(self.m_iReelRowNum / 2)

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self.m_modeItem:setVisible(true)
        end
        self.m_csb_lock:stopAllActions()
        self.m_csb_lock:runCsbAction(
            "actionframe1",
            false,
            function()
            end
        )

        performWithDelay(
            self.m_csb_lock,
            function()
                self.m_csb_lock:setVisible(false)
            end,
            util_csbGetAnimTimes(self.m_csb_lock.m_csbAct, "actionframe1")
        )
    end
end

function CodeGameScreenFrozenJewelryMachine:addObservers()
    CodeGameScreenFrozenJewelryMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:checkChangeReel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
                return
            end

            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                --freespin最后一次spin不会播大赢,需单独处理
                local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
                if fsLeftCount <= 0 then
                    self.m_bIsBigWin = false
                end
            end

            if self.m_bIsBigWin then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local winRatio = winCoin / lTatolBetNum
            local soundIndex = 1
            local soundTime = 2
            if winRatio > 0 then
                if winRatio <= 1 then
                    soundIndex = 1
                elseif winRatio > 1 and winRatio <= 3 then
                    soundIndex = 2
                else
                    soundIndex = 3

                    if not self.m_isTriggerAni then
                        local randIndex = math.random(1, 2)
                        if randIndex == 1 then
                            gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_wincoins_brilliant.mp3")
                        else
                            gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_wincoins_gorgeous.mp3")
                        end
                    end
                end
            end

            local soundTime = soundIndex
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = ""
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                soundName = "FrozenJewelrySounds/sound_FrozenJewelry_free_win_sound_" .. soundIndex .. ".mp3"
            else
                soundName = "FrozenJewelrySounds/sound_FrozenJewelry_win_sound_" .. soundIndex .. ".mp3"
            end
            self.m_winSoundsId, self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName, soundTime, 1, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenFrozenJewelryMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenFrozenJewelryMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFrozenJewelryMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.Socre_FrozenJewelry_MYSTERY then
        symbolType = self:getMysteryType(symbolType)
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_FrozenJewelry_10"
    end

    return nil
end

function CodeGameScreenFrozenJewelryMachine:getMysteryType(symbolType)
    if symbolType == self.Socre_FrozenJewelry_MYSTERY then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.change_num then
            symbolType = selfData.change_num
        else
            symbolType = 90
        end
    end
    return symbolType
end

function CodeGameScreenFrozenJewelryMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print(debug.traceback())
        release_print("sever传回的数据：  " .. (globalData.slotRunData.severGameJsonData or "isnil"))
        release_print(
            "error_userInfo_ udid=" ..
                (globalData.userRunData.userUdid or "isnil") .. " machineName=" .. (globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. (globalData.seqId or "")
        )
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:" .. ccbName)
        return nil
    end

    symbolType = self:getMysteryType(symbolType)

    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType, spineSymbolData[3])
            node:initSpineInfo(spineSymbolData[1], spineSymbolData[2])
            node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        node:runDefaultAnim()

        -- print("从尺子里面拿 SlotsAnimNode")

        return node
    end
end

---
-- 从参考的假数据中获取数据
--
function CodeGameScreenFrozenJewelryMachine:getRandomReelType(colIndex, reelDatas)
    if reelDatas == nil or #reelDatas == 0 then
        return self:getNormalSymbol(colIndex)
    end
    local reelLen = #reelDatas

    if self.m_randomSymbolSwitch then
        -- 根据滚轮真实假滚数据初始化轮子信号小块
        if self.m_randomSymbolIndex == nil then
            self.m_randomSymbolIndex = util_random(1, reelLen)
        end
        self.m_randomSymbolIndex = self.m_randomSymbolIndex + 1
        if self.m_randomSymbolIndex > reelLen then
            self.m_randomSymbolIndex = 1
        end

        local symbolType = reelDatas[self.m_randomSymbolIndex]
        symbolType = self:getMysteryType(symbolType)
        return symbolType
    else
        while true do
            local symbolType = reelDatas[util_random(1, reelLen)]
            symbolType = self:getMysteryType(symbolType)
            return symbolType
        end
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFrozenJewelryMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenFrozenJewelryMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenFrozenJewelryMachine:MachineRule_initGame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_modeItem:setVisible(false)
        self:changeBgAni("free_idle")

        if self.m_runSpinResultData.p_freeSpinsLeftCount > 16 and self.m_curChoose == 1 then
            self.m_changeFreeItem:showItem()
        else
            self.m_changeFreeItem:hideItem()
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenFrozenJewelryMachine:slotOneReelDown(reelCol)
    CodeGameScreenFrozenJewelryMachine.super.slotOneReelDown(self, reelCol)

    if not globalData.slotRunData.isClickQucikStop then
        self.m_reelDownByCol[reelCol] = true
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        --收集wild图标
        self:collectWildSymbolByCol(reelCol)
    end
end

--[[
    按列收集wild图标(落地时收集)
]]
function CodeGameScreenFrozenJewelryMachine:collectWildSymbolByCol(col)
    local rowNum = self.m_iReelRowNum / 2
    if col == 3 and self.m_isDoubleReel then
        rowNum = self.m_iReelRowNum
    end

    local hasWildSymbol = false
    for iRow = 1, rowNum do
        local symbol = self:getFixSymbol(col, iRow, SYMBOL_NODE_TAG)
        if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            self:flyParticleAni(symbol, self:findChild("Jackpot"))
            hasWildSymbol = true
        end
    end
    if hasWildSymbol then
        if not globalData.slotRunData.isClickQucikStop then
            gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_wild_fly.mp3")
        end

        local aniName = {"idle", "idle1", "idle2"}
        self:delayCallBack(
            20 / 60,
            function()
                if not globalData.slotRunData.isClickQucikStop then
                    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_wild_fly_feed_back.mp3")
                end

                local selfData = self.m_runSpinResultData.p_selfMakeData
                if selfData then
                    local boxLevel = selfData.wildlevel or 1
                    if selfData.jackpot then
                        self.m_collectBox:collectAni(3)
                        self:runCsbAction(aniName[3], true)
                    else
                        self.m_collectBox:collectAni(boxLevel)
                        self:runCsbAction(aniName[boxLevel], true)
                    end
                end
            end
        )
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFrozenJewelryMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFrozenJewelryMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

----------- FreeSpin相关
---
-- 显示free spin
function CodeGameScreenFrozenJewelryMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    self:showFreeSpinView(effectData)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

-- FreeSpinstart
function CodeGameScreenFrozenJewelryMachine:showFreeSpinView(effectData)
    self.m_isShowFreeSpinView = true
    -- gLobalSoundManager:playSound("FrozenJewelrySounds/music_FrozenJewelry_custom_enter_fs.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    if self.m_runSpinResultData.p_freeSpinsLeftCount > 16 then
                        self.m_changeFreeItem:showItem()
                        self.m_changeFreeItem:autoShowTip()
                    else
                        self.m_changeFreeItem:hideItem()
                    end

                    self.m_baseFreeSpinBar:pointLightAni()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self.m_isChangeFreeType = false
            --不满16次,普通freespin
            if self.m_curChoose == -1 then
                self:changeBgAni("base_free")
                self:delayCallBack(
                    30 / 60,
                    function()
                        self:showFreeSpinBar()
                    end
                )
            end

            self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    if self.m_curChoose == -1 then
                        self.m_curChoose = 1
                    end

                    if self.m_curChoose == 1 and self.m_runSpinResultData.p_freeSpinsLeftCount > 16 then
                        self.m_changeFreeItem:showItem()
                        self.m_changeFreeItem:autoShowTip()
                    else
                        self.m_changeFreeItem:hideItem()
                    end
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()

                    self:removeSoundHandler()
                    self:setMaxMusicBGVolume()
                    self:resetMusicBg()
                end
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    self:delayCallBack(
        0.5,
        function()
            showFSView()
        end
    )
end

function CodeGameScreenFrozenJewelryMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
    -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    self:resetMusicBg()
end

function CodeGameScreenFrozenJewelryMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    -- 切换图层
    slotNode:changeParentToOtherNode(self.m_node_scatter, self:getSlotNodeEffectZOrder(slotNode))

    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if slotNode ~= nil then
        slotNode:runTriggerAni()
    end
    return slotNode
end

function CodeGameScreenFrozenJewelryMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local csbName = BaseDialog.DIALOG_TYPE_FREESPIN_MORE
    if self.m_curChoose == 2 then
        csbName = "SuperFreeSpinMore"
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_super_free_more.mp3")
    else
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_free_more.mp3")
    end

    if isAuto then
        return self:showDialog(csbName, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(csbName, ownerlist, newFunc)
    end
end

function CodeGameScreenFrozenJewelryMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local csbName = BaseDialog.DIALOG_TYPE_FREESPIN_START
    if self.m_curChoose == 2 then
        csbName = "SuperFreeSpinStart"
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_super_free_start.mp3")
    else
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_free_start.mp3")
    end
    local view
    if isAuto then
        view = self:showDialog(csbName, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(csbName, ownerlist, func)
    end
    view.m_btnTouchSound = BTN_CLICK_SOUND
    return view

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenFrozenJewelryMachine:showFreeSpinOverView()
    --清理背景音乐
    self:clearCurMusicBg()
    -- gLobalSoundManager:playSound("FrozenJewelrySounds/music_FrozenJewelry_over_fs.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)

    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self.m_curChoose = -1
            self:triggerFreeSpinOverCallFun()
        end
    )
    self:delayCallBack(60 / 60,function()

        self.m_curChoose = -1

        self:changeBgAni("free_base")

        local minBet = self:getMinBet()
        local totalBet = globalData.slotRunData:getCurTotalBet()
        if totalBet < minBet then
            self.m_modeItem:setVisible(true)
        end
    end)

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 820)
end

function CodeGameScreenFrozenJewelryMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = coins

    local csbName = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    if self.m_curChoose == 2 then
        csbName = "SuperFreeSpinOver"
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_super_free_win.mp3")
    else
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_free_win.mp3")
    end

    local view = self:showDialog(csbName, ownerlist, func)
    view.m_btnTouchSound = BTN_CLICK_SOUND

    local node = view:findChild("m_lb_num")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 90)
    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFrozenJewelryMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()

    self.m_longRunCol = {}

    self.m_reelDownByCol = {}

    self.m_isNotice = false

    self.m_isTriggerAni = false

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenFrozenJewelryMachine:spinBtnEnProc()
    self.m_isInitReelByData = false
    self:putBackScatterNode()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount <= 16 then
        self.m_changeFreeItem:hideItem()
    end
    -- self.m_changeFreeItem:hideTip()
    CodeGameScreenFrozenJewelryMachine.super.spinBtnEnProc(self)
end

function CodeGameScreenFrozenJewelryMachine:beginReel()
    CodeGameScreenFrozenJewelryMachine.super.beginReel(self)
    self.m_isChangeFreeType = false
    self.m_isShowSelectView = false
    self.m_isShowFreeSpinView = false
end

--[[
    将scatter放回原层级
]]
function CodeGameScreenFrozenJewelryMachine:putBackScatterNode()
    --scatter图标放回原层级
    for i, symbolNode in pairs(self.m_scatterNodes) do
        symbolNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        symbolNode:putBackToPreParent()
    end
    self.m_scatterNodes = {}
end

function CodeGameScreenFrozenJewelryMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    self.m_isWaitingNetworkData = false

    -- 出现预告动画概率40%
    local isNotice = (math.random(1, 100) <= 40)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        isNotice = false
    end

    local func = function()
        self:produceSlots()
        self:operaNetWorkData()
        if self.m_isNotice then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local selfData = self.m_runSpinResultData.p_selfMakeData
            if self.m_curChoose == 2 then
                self.m_freeSpinMultiple:refreshMutiple(selfData.multi, true)
            else
                self.m_freeSpinMultiple:refreshMutiple(2, false)
            end
        end
    end

    local features = self.m_runSpinResultData.p_features or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if (#features >= 2 and features[2] > 0) or (selfData and selfData.jackpot) then
        if isNotice then
            self.m_isNotice = isNotice
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self:playNoticeAni()
            self:delayCallBack(
                1,
                function()
                    func() -- end
                end
            )
        else
            func() -- end
        end
    else
        func() -- end
    end
end

function CodeGameScreenFrozenJewelryMachine:playNoticeAni(func)
    self.m_noticeAni:setVisible(true)
    self.m_noticeAni:findChild("Particle_1"):resetSystem()
    self.m_noticeAni:findChild("Particle_2"):resetSystem()
    self.m_noticeAni:runCsbAction(
        "actionframe",
        false,
        function()
            if type(func) == "function" then
                func()
            end
        end
    )

    local randIndex = math.random(1, 2)
    local soundFile = "FrozenJewelrySounds/sound_FrozenJewelry_notice_" .. randIndex .. ".mp3"
    gLobalSoundManager:playSound(soundFile)
end

--------------------添加动画
--[[
    添加选择玩法
]]
function CodeGameScreenFrozenJewelryMachine:addSelectEffect(isInit)
    local featureID = self.m_runSpinResultData.p_features[2]
    if isInit then
        if self.m_initFeatureData then
            featureID = self.m_initFeatureData.p_data.features[2]
        end
    end

    --选择玩法
    if featureID and featureID == FEATURE_SELECT then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SELECT_EFFECT -- 动画类型

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end

    if featureID and (featureID == FEATURE_SELECT or featureID == SLOTO_FEATURE.FEATURE_FREESPIN) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.TRIGGER_EFFECT -- 动画类型
        self.m_isTriggerAni = true
    end
end

--[[
    点击更改free类型按钮
]]
function CodeGameScreenFrozenJewelryMachine:clickChangeFreeType()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE or self.m_curChoose > 1 or self.m_isChangeFreeType or self.m_isShowFreeSpinView then
        return
    end
    --停止自动spin
    if self.m_handerIdAutoSpin then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
    end

    self.m_isChangeFreeType = true
    if self.m_isRunningEffect then
        self:checkAddSelectEffect()
    elseif self:getGameSpinStage() == IDLE then
        self:checkAddSelectEffect()
        self:playGameEffect()
    end
end

function CodeGameScreenFrozenJewelryMachine:checkAddSelectEffect()
    local isHaveEffect = false
    for i, effectData in ipairs(self.m_gameEffects) do
        if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT and effectData.p_selfEffectType == self.SELECT_EFFECT then
            isHaveEffect = true
            break
        end
    end

    if not isHaveEffect then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN + 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SELECT_EFFECT -- 动画类型

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
end
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFrozenJewelryMachine:addSelfEffect()
    --选择玩法
    self:addSelectEffect()

    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_curChoose == 1 and self.m_isChangeFreeType then
        self:checkAddSelectEffect()
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end

    --收集玩法
    if selfData.wild and next(selfData.wild) then
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = self.COLLECT_WILD_EFFECT
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.COLLECT_WILD_EFFECT -- 动画类型
    end

    --收集完成触发jackpot玩法
    if selfData and selfData.jackpot then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUS_EFFECT -- 动画类型
        selfEffect.m_data = selfData.jackpot
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFrozenJewelryMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_WILD_EFFECT then
        self:updateCollectBox(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    elseif effectData.p_selfEffectType == self.SELECT_EFFECT then
        self:showSelectView(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    elseif effectData.p_selfEffectType == self.BONUS_EFFECT then
        self:delayCallBack(
            20 / 60,
            function()
                self:changeSceneAni_Bonus(
                    function()
                        self:showBonusView(
                            effectData.m_data,
                            function()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        )
                    end
                )
            end
        )
    elseif effectData.p_selfEffectType == self.REFRESH_FS_MULTIPLE_EFFECT then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self.m_freeSpinMultiple:refreshMutiple(
            selfData.multi,
            true,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    elseif effectData.p_selfEffectType == self.TRIGGER_EFFECT then
        self:playTriggerAni(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end

    return true
end

--[[
    播放触发动画
]]
function CodeGameScreenFrozenJewelryMachine:playTriggerAni(func)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:findChild("Node_2"):setVisible(false)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_vecGetLineInfo
    local scatterLineValue = {}
    for i = lineLen, 1, -1 do
        local lineValue = self.m_vecGetLineInfo[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue[#scatterLineValue + 1] = lineValue
        end
    end

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "free")
    end
    if #scatterLineValue > 0 then
        for k, lineValue in pairs(scatterLineValue) do
            self:showBonusAndScatterLineTip(
                lineValue,
                function()
                end
            )
        end

        self:delayCallBack(
            90 / 30,
            function()
                self:resetMaskLayerNodes()
                if type(func) == "function" then
                    func()
                end
            end
        )

        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        if type(func) == "function" then
            func()
        end
    end
end

function CodeGameScreenFrozenJewelryMachine:playScatterTipMusicEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_scatter_trigger_without_voice.mp3")
    else
        if self.m_ScatterTipMusicPath ~= nil then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        end
    end
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenFrozenJewelryMachine:showBonusAndScatterLineTip(lineValue, callFun)
    self.m_modeItem:setVisible(false)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode == nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end
            end
        end

        if not slotNode then
            for i, node in pairs(self.m_scatterNodes) do
                if node.p_cloumnIndex == symPosData.iY and node.p_rowIndex == symPosData.iX then
                    slotNode = node
                    table.remove(self.m_scatterNodes, i, 1)
                    break
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

function CodeGameScreenFrozenJewelryMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                lineNode:putBackToPreParent()
                lineNode:runIdleAnim()
            end
        end
    end
end

function CodeGameScreenFrozenJewelryMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- -- 延迟回调播放 界面提示 bonus  freespin
    -- scheduler.performWithDelayGlobal(
    --     function()
    --         self:resetMaskLayerNodes()
    --         callFun()
    --     end,
    --     util_max(2, animTime),
    --     self:getModuleName()
    -- )
end

--[[
    收集wild
]]
function CodeGameScreenFrozenJewelryMachine:collectWildSymbol(func)
    for iCol = 1, self.m_iReelColumnNum do
        local rowNum = self.m_iReelRowNum / 2
        if iCol == 3 and self.m_isDoubleReel then
            rowNum = self.m_iReelRowNum
        end
        for iRow = 1, rowNum do
            local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                self:flyParticleAni(symbol, self:findChild("Jackpot"))
            end
        end
    end

    self:delayCallBack(20 / 60, func)
end

--[[
    飞粒子动画
]]
function CodeGameScreenFrozenJewelryMachine:flyParticleAni(startNode, endNode, func)
    --粒子
    local particle = util_createAnimation("FrozenJewelry_Pick_tw.csb")
    for index = 1, 3 do
        local tempParticle = particle:findChild("Particle_" .. index)
        if tempParticle then
            tempParticle:setPositionType(0)
        end
    end

    local startPos = util_convertToNodeSpace(startNode, self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode, self.m_effectNode)

    self.m_effectNode:addChild(particle, 1000)
    particle:setPosition(startPos)

    local seq =
        cc.Sequence:create(
        {
            cc.MoveTo:create(20 / 60, endPos),
            cc.CallFunc:create(
                function()
                    for index = 1, 3 do
                        local tempParticle = particle:findChild("Particle_" .. index)
                        if tempParticle then
                            tempParticle:stopSystem()
                        end
                    end
                    if type(func) == "function" then
                        func()
                    end
                end
            ),
            cc.DelayTime:create(1),
            cc.RemoveSelf:create(true)
        }
    )

    particle:runAction(seq)
end

--[[
    过场动画
]]
function CodeGameScreenFrozenJewelryMachine:changeSceneAni_Bonus(func)
    --清理背景音乐
    self:clearCurMusicBg()
    self:findChild("Node_2"):setVisible(false)
    util_changeNodeParent(self:findChild("root"), self.m_collectBox, 1000)
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_bonus_trigger.mp3")

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    self.m_collectBox:changeSceneAni(
        function()
            util_changeNodeParent(self:findChild("Box"), self.m_collectBox)
            self:initCollectBox()
        end,
        function()
            self:showBaseMachineView(false)
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self:changeBgAni("free_bouns")
            else
                self:changeBgAni("base_bonus")
            end

            if type(func) == "function" then
                func()
            end
        end
    )
end

--[[
    显示bonus界面
]]
function CodeGameScreenFrozenJewelryMachine:showBonusView(data, func)
    -- self:removeSoundHandler()
    self:setMaxMusicBGVolume()
    self:resetMusicBg(true, "FrozenJewelrySounds/music_FrozenJewelry_bonus_game.mp3")

    self.m_bonusView:showView(
        data,
        function()
            self:delayCallBack(
                45 / 60,
                function()
                    self:showBaseMachineView(true)

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self:changeBgAni("bouns_free")
                    else
                        self:changeBgAni("bonus_base")
                    end
                end
            )
            local isHaveBigWin = self:checkHasBigWin()
            if not isHaveBigWin then
                self:checkFeatureOverTriggerBigWin(data.winValue, GameEffect.EFFECT_BONUS)
            end
            self:showJackpotWinView(
                function()
                    --
                    if not isHaveBigWin then
                        gLobalNoticManager:postNotification(
                            ViewEventType.NOTIFY_UPDATE_WINCOIN,
                            {
                                data.winValue,
                                true,
                                true
                            }
                        )
                    end

                    if type(func) == "function" then
                        func()
                    end
                end
            )
        end
    )
end

function CodeGameScreenFrozenJewelryMachine:showJackpotWinView(func)
    --清理背景音乐
    self:clearCurMusicBg()
    local jackpot = self.m_runSpinResultData.p_selfMakeData.jackpot
    local view =
        util_createView(
        "CodeFrozenJewelrySrc.FrozenJewelryJackpotWinView",
        {
            machine  = self,
            viewType = jackpot.winJackpot[1],
            winCoin  = jackpot.winValue,
            func     = func
        }
    )

    gLobalViewManager:showUI(view)
end

function CodeGameScreenFrozenJewelryMachine:checkHasFreeEffect()
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == GameEffect.EFFECT_FREE_SPIN and not self.m_gameEffects[i].p_isPlay then
            return true
        end
    end

    return false
end

function CodeGameScreenFrozenJewelryMachine:showSelectView(func)
    self:clearWinLineEffect()
    local endFunc = function(choose, featureData)
        local reels = clone(self.m_runSpinResultData.p_reels)
        local selfData = clone(self.m_runSpinResultData.p_selfMakeData)
        self.m_runSpinResultData:parseResultData(featureData.p_data, self.m_lineDataPool)
        self.m_runSpinResultData.p_reels = reels
        self.m_runSpinResultData.p_selfMakeData = selfData
        if choose <= 2 then
            self.m_curChoose = choose
            if not self:checkHasFreeEffect() then
                -- 添加freespin effect
                local freeSpinEffect = GameEffectData.new()
                freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
                freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
                self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            end

            if type(func) == "function" then
                func()
            end
        else
            self.m_iFreeSpinTimes = 0
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0
            self:showMysteryPrize(featureData.p_data.winAmount, func)
            self.m_curChoose = -1
        end
    end

    --scatter图标放回原层级
    self:putBackScatterNode()

    --清理背景音乐
    self:clearCurMusicBg()
    self.m_modeItem:setVisible(false)
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_change_scene_select.mp3")
    local view =
        util_createView(
        "CodeFrozenJewelrySrc.FrozenJewelrySelectView",
        {
            machine = self,
            callBack = endFunc,
            startFunc = function(choose)
                if choose <= 2 then
                    local selfData = self.m_runSpinResultData.p_selfMakeData
                    local temp = (choose == 1) and 1 or 4
                    if choose == 1 then
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
                        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                    else
                        self.m_iFreeSpinTimes = selfData.superleftcount or math.floor(self.m_runSpinResultData.p_freeSpinsLeftCount / 4)
                        globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
                        globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes
                    end

                    self:showBaseMachineView(true)

                    self:setCurrSpinMode(NORMAL_SPIN_MODE)

                    --显示修改free类型按钮
                    if self.m_runSpinResultData.p_freeSpinsLeftCount > 16 and choose == 1 then
                        self.m_changeFreeItem:showItem()
                    else
                        self.m_changeFreeItem:hideItem()
                    end
                end

                self.m_isShowSelectView = false

                self.m_gameBg:runCsbAction(
                    "actionframe" .. choose,
                    false,
                    function()
                        util_changeNodeParent(self:findChild("root"), self:findChild("Node_1"))
                        self:findChild("Node_1"):setLocalZOrder(50)
                        self:findChild("Node_2"):setLocalZOrder(100)
                    end
                )

                self:delayCallBack(
                    112 / 60,
                    function()
                        if choose <= 2 then
                            self.m_curChoose = choose
                            self:setMachineType("free_idle")
                            self:showFreeSpinBar()
                        else
                            self.m_bottomUI:updateWinCount("")
                            self:setMachineType("base_idle")
                            self:findChild("Node_2"):setVisible(false)
                        end
                    end
                )
            end
        }
    )

    self.m_gameBg:findChild("choose"):addChild(view)
    view:setPosition(cc.p(-display.center.x, -display.center.y))
    util_changeNodeParent(self.m_gameBg:findChild("Node_2"), self:findChild("Node_1"))

    self.m_isShowSelectView = true

    local aniName = self.m_isChangeFreeType and "free_choose" or "base_choose"
    self.m_gameBg:runCsbAction(
        aniName,
        false,
        function()
            self:showBaseMachineView(false)
            self:changeBgAni("choose_idle")
        end
    )

    self.m_switchLight:setVisible(true)
    self.m_switchLight:runCsbAction(
        "start",
        false,
        function()
            self.m_switchLight:setVisible(false)
        end
    )
end

function CodeGameScreenFrozenJewelryMachine:showModeView()
    local view =
        util_createView(
        "CodeFrozenJewelrySrc.FrozenJewelryModeView",
        {
            machine = self,
            minBet = self:getMinBet(),
            callBack = function(choose)
                self.m_modeItem:resetStatus()
                if choose == "high" then
                    self.m_bottomUI:changeBetCoinNumToHight()
                    self.m_modeItem:setVisible(false)
                end
            end
        }
    )

    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalViewManager:showUI(view)
end

-- 显示paytableview 界面
function CodeGameScreenFrozenJewelryMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    if view then
        view:setOverFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                gLobalViewManager:viewResume(
                    function()
                        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
                    end
                )
            end
        )
        view:findChild("root"):setScale(self.m_machineRootScale)
    end
end

function CodeGameScreenFrozenJewelryMachine:showMysteryPrize(coins, func)
    self:checkFeatureOverTriggerBigWin(coins, GameEffect.EFFECT_BONUS)
    local view =
        util_createView(
        "CodeFrozenJewelrySrc.FrozenJewelryMysteryView",
        {
            winCoin = coins,
            machine = self,
            func = function()
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(
                    ViewEventType.NOTIFY_UPDATE_WINCOIN,
                    {
                        coins,
                        true,
                        true
                    }
                )
                local minBet = self:getMinBet()
                local totalBet = globalData.slotRunData:getCurTotalBet()
                if totalBet < minBet then
                    self.m_modeItem:setVisible(true)
                end
                self:showBaseMachineView(true)
                self:changeBgAni("free_base")
                self:hideFreeSpinBar()
                self.m_changeFreeItem:hideItem()
                self:setCurrSpinMode(NORMAL_SPIN_MODE)
                if type(func) == "function" then
                    func()
                end
            end
        }
    )

    gLobalViewManager:showUI(view)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFrozenJewelryMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end


function CodeGameScreenFrozenJewelryMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    CodeGameScreenFrozenJewelryMachine.super.slotReelDown(self)

    --free下不做收集
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return
    end

    --检测是否有wild
    local hasWildSymbol = false
    for iCol = 1, self.m_iReelColumnNum do
        local rowNum = self.m_iReelRowNum / 2
        if iCol == 3 and self.m_isDoubleReel then
            rowNum = self.m_iReelRowNum
        end

        --只检测还没停止的列
        if not self.m_reelDownByCol[iCol] then
            for iRow = 1, rowNum do
                local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    hasWildSymbol = true
                    break
                end
            end

            if hasWildSymbol then
                break
            end
        end
    end

    --是否播放收集音效
    if globalData.slotRunData.isClickQucikStop and hasWildSymbol then
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_wild_fly.mp3")
        self:delayCallBack(
            20 / 60,
            function()
                gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_wild_fly_feed_back.mp3")
            end
        )
    end
end

function CodeGameScreenFrozenJewelryMachine:quicklyStopReel(colIndex)
    self:operaQuicklyStopReel()
end

function CodeGameScreenFrozenJewelryMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    刷新小块
]]
function CodeGameScreenFrozenJewelryMachine:updateReelGridNode(node)
    node.m_machine = self
    -- node:runAnim(node:getIdleAnimName())
    if node.p_cloumnIndex == 3 and self.m_isDoubleReel then
        node:changeSymbolImageByName(self:getSymbolCCBNameByType(self, node.p_symbolType), node.p_symbolType)
    end
end

function CodeGameScreenFrozenJewelryMachine:getSymbolTypeForNetData(iCol, iRow, iLen)
    if not self.m_stcValidSymbolMatrix[iRow] then
        return 0
    end
    return self.m_stcValidSymbolMatrix[iRow][iCol]
end

---
-- 获取最高的那一列
--
function CodeGameScreenFrozenJewelryMachine:updateReelInfoWithMaxColumn()
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
        self.m_reelColDatas[iCol].p_slotColumnHeight = (iCol ~= 3) and reelSize.height or reelSize.height * 2

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height * 2
            self.m_fReelWidth = reelSize.width
        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / self.m_iReelRowNum

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = math.floor(columnData.p_slotColumnHeight / self.m_SlotNodeH + 0.5) -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end

    self:initReelControl()
end

--[[
    重置轮盘
]]
function CodeGameScreenFrozenJewelryMachine:resetMidReels(rowNum)
    self:putBackScatterNode()
    self:clearWinLineEffect()
    -- 计算每列的行数
    local isSpecialReel = false
    local columnData = self.m_reelColDatas[3]
    columnData.p_showGridH = self.m_SlotNodeH
    columnData.p_showGridCount = rowNum

    local parentData = self.m_slotParents[3]
    parentData.rowNum = rowNum

    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end

    self.m_reels[3]:clearCacheGrids()

    self:initMidReelControl()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )

    local parentData = self.m_slotParents[3]
    parentData.rowNum = rowNum

    self.m_reels[3].m_iRowNum = rowNum
    self.m_reels[3].m_gridCount = rowNum + 1

    self:resetMidColSymbol()
end

--[[
    重置中间列
]]
function CodeGameScreenFrozenJewelryMachine:resetMidColSymbol()
    local colIndex = 3
    local columnData = self.m_reelColDatas[colIndex]
    local halfNodeH = columnData.p_showGridH * 0.5
    local rowCount = columnData.p_showGridCount
    local parentData = self.m_slotParents[colIndex]
    local p_reels = self.m_runSpinResultData.p_reels
    for rowIndex = 1, rowCount do
        local tempIndex = rowIndex
        if rowCount == 3 then
            tempIndex = rowIndex + 3
        end
        local symbolType
        if p_reels and #p_reels > 0 and p_reels[tempIndex] then
            symbolType = p_reels[tempIndex][colIndex]
        else
            symbolType = self:getNormalSymbol(colIndex)
        end

        local changeRowIndex = rowCount - rowIndex + 1
        local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, false)
        node.p_slotNodeH = columnData.p_showGridH

        node.p_symbolType = symbolType
        node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - changeRowIndex

        if not node:getParent() then
            local slotParentBig = parentData.slotParentBig
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
            else
                parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
            end
        else
            node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
            node:setLocalZOrder(node.p_showOrder)
            node:setVisible(true)
        end
        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    end
    self:initGridList()
end

--初始化格子列表（放在关卡初始化轮盘之后）
function CodeGameScreenFrozenJewelryMachine:initGridList(isFirstNoramlReel)
    self.m_initGridNode = nil
    for i = 1, #self.m_reels do
        local gridList = {}
        local rowNum = self.m_reels[i].m_iRowNum
        if i == 3 and self.m_isDoubleReel then
            rowNum = rowNum + 1
        end
        for j = 1, rowNum do
            if isFirstNoramlReel then
                local symbolNode = self:getReelParentChildNode(i, j)
                if not symbolNode then
                    symbolNode = self:getFixSymbol(i, j)
                end
                gridList[j] = symbolNode
            else
                gridList[j] = self:getFixSymbol(i, j)
            end
        end
        self.m_reels[i]:initGridList(gridList)
    end
    self:initCacheGrids()
end

function CodeGameScreenFrozenJewelryMachine:initMidReelControl()
    local ReelControl = util_require(self:getBaseReelControl())
    local parentData = self.m_slotParents[3]
    parentData.reelWidth = self.m_fReelWidth
    parentData.reelHeight = self.m_fReelHeigth / 2
    parentData.slotNodeW = self.m_fReelWidth
    parentData.slotNodeH = parentData.reelHeight / parentData.rowNum
    local reel = ReelControl:create()
    --设置格子lua类名
    reel:setScheduleName(self:getBaseReelSchedule())
    reel:setGridNodeName(self:getBaseReelGridNode())
    --关卡slotNode重写需要用到
    reel:setMachine(self)
    --初始化
    reel:initData(
        parentData,
        self.m_configData,
        self.m_reelColDatas[3],
        handler(self, self.createNextGrideData),
        handler(self, self.reelSchedulerCheckColumnReelDown),
        handler(self, self.updateReelGridNode)
    )
    self.m_reels[3] = reel
end

--[[
    延迟回调
]]
function CodeGameScreenFrozenJewelryMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

function CodeGameScreenFrozenJewelryMachine:getLongRunLen(col, index)
    local len = 0
    local scatterShowCol = self.m_ScatterShowCol
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if scatterShowCol ~= nil then
        local isNeedLongRun = true
        for iCol = 1, col - 1 do
            if not self.m_longRunCol[iCol] then
                isNeedLongRun = false
            end
        end
        if self.m_longRunCol[1] and self.m_longRunCol[2] then
            if col == 4 and self.m_isDoubleReel then
                lastColLens = lastColLens / 2
            end
        end
        if isNeedLongRun and self:getInScatterShowCol(col) then
            local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
            len = lastColLens + math.floor(reelCount) * columnData.p_showGridCount --速度x时间 / 列高
            if col == 3 and self.m_isDoubleReel then
                len = len * 2
            end
        else
            local diffLen = self.m_reelRunInfo[2]:getReelRunLen() - self.m_reelRunInfo[1]:getReelRunLen()
            len = lastColLens + diffLen
            self.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end
    if len == 0 then
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        len = lastColLens + math.floor(reelCount) * columnData.p_showGridCount --速度x时间 / 列高
    end
    return len
end

function CodeGameScreenFrozenJewelryMachine:setReelRunInfo()
    local reels = self.m_runSpinResultData.p_reels
    for iCol = 1, self.m_iReelColumnNum do
        local startRowIndex = 4
        if iCol == 3 and self.m_isDoubleReel then
            startRowIndex = 1
        end

        self.m_longRunCol[iCol] = false
        for iRow = startRowIndex, self.m_iReelRowNum do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self.m_longRunCol[iCol] = true
                break
            end
        end
    end

    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col = 1, iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)

            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenFrozenJewelryMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column, row, runLen) == symbolType then
            local bPlaySymbolAnima = bPlayAni

            allSpecicalSymbolNum = allSpecicalSymbolNum + 1

            if bRun == true then
                local soungName = nil
                if nextReelLong then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                end

                if column > 1 and not nextReelLong then
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

    if self.m_isNotice then
        bRun = false
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenFrozenJewelryMachine:getRunStatus(col, nodeNum, showCol)
    if col < 2 then
        return runStatus.NORUN, false
    end

    local isNeedLongRun = true
    for iCol = 1, col do
        if not self.m_longRunCol[iCol] then
            isNeedLongRun = false
        end
    end

    if isNeedLongRun then
        return runStatus.DUANG, true
    else
        return runStatus.NORUN, false
    end
end

---
--添加金边
function CodeGameScreenFrozenJewelryMachine:creatReelRunAnimation(col)
    if self.m_slotParents[col].isResActionDone then
        return
    end
    printInfo("xcyy : col %d", col)
    for iCol = 1, col - 1 do
        if not self.m_longRunCol[iCol] then
            return
        end
    end
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

---
-- 显示所有的连线框
--
function CodeGameScreenFrozenJewelryMachine:showAllFrame(winLines)
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
            -- end
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen()

                local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
                local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY

                if symPosData.iY == 3 and self.m_isDoubleReel then
                    posY = columnData.p_showGridH * symPosData.iX * 0.5 - columnData.p_showGridH * 0.5 * 0.5 + columnData.p_slotColumnPosY
                end
                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(cc.p(posX, posY))
                node:getCcbProperty("Sprite_1"):setVisible(not (symPosData.iY == 3 and self.m_isDoubleReel))
                node:getCcbProperty("Sprite_1_0"):setVisible(symPosData.iY == 3 and self.m_isDoubleReel)

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenFrozenJewelryMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
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
        if symPosData.iY == 3 and self.m_isDoubleReel then
            posY = columnData.p_showGridH * symPosData.iX * 0.5 - columnData.p_showGridH * 0.5 * 0.5 + columnData.p_slotColumnPosY
        end
        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))
        node:getCcbProperty("Sprite_1"):setVisible(not (symPosData.iY == 3 and self.m_isDoubleReel))
        node:getCcbProperty("Sprite_1_0"):setVisible(symPosData.iY == 3 and self.m_isDoubleReel)

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
            node:runAnim("actionframe", true)
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
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenFrozenJewelryMachine:setScatterDownScound()
    for index = 1, 5 do
        local soundPath = "FrozenJewelrySounds/sound_FrozenJewelry_scatter_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

--播放提示动画
function CodeGameScreenFrozenJewelryMachine:playReelDownTipNode(slotNode)
    self:playScatterBonusSound(slotNode)
    if slotNode.p_cloumnIndex == 3 and self.m_isDoubleReel then
        slotNode:runAnim("buling2")
    else
        slotNode:runAnim("buling")
    end

    local getNodePosByColAndRow = function(row, col)
        local reelNode = self:findChild("sp_reel_" .. (col - 1))

        local posX, posY = reelNode:getPosition()
        if slotNode.p_cloumnIndex == 3 and self.m_isDoubleReel then
            posX = posX + self.m_SlotNodeW * 0.5
            posY = posY + (row - 0.5) * self.m_SlotNodeH / 2
        else
            posX = posX + self.m_SlotNodeW * 0.5
            posY = posY + (row - 0.5) * self.m_SlotNodeH
        end
        return cc.p(posX, posY)
    end

    local pos = getNodePosByColAndRow(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
    local worldPos = self.m_clipParent:convertToWorldSpace(pos)
    local nodePos = self.m_node_scatter:convertToNodeSpace(worldPos)

    slotNode:changeParentToOtherNode(self.m_node_scatter)
    self.m_scatterNodes[#self.m_scatterNodes + 1] = slotNode
    slotNode:setPosition(nodePos)
    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
    self:specialSymbolActionTreatment(slotNode)
end

--增加提示节点
function CodeGameScreenFrozenJewelryMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)

            if self:checkSymbolTypePlayTipAnima(slotNode.p_symbolType) then
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            end
        end
    end
    return tipSlotNoes
end

--[[
    初始轮盘
]]
function CodeGameScreenFrozenJewelryMachine:initRandomSlotNodes()
    if type(self.m_configData.isHaveInitReel) == "function" and self.m_configData:isHaveInitReel() then
        self.m_isInitReelByData = true
        self:initSlotNodes()
    else
        if self.m_currentReelStripData == nil then
            self:randomSlotNodes()
        else
            self:randomSlotNodesByReel()
        end
    end
end

--[[
    根据配置初始轮盘
]]
function CodeGameScreenFrozenJewelryMachine:initSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local initDatas = self.m_configData:getInitReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        local startIndex = 1
        --大信号数量
        local bigSymbolCount = 0
        for rowIndex = 1, rowCount do
            local symbolType = initDatas[startIndex]

            --记录信号值(切换bet用)
            if not self.m_runSpinResultData.p_reels[rowIndex] then
                self.m_runSpinResultData.p_reels[rowIndex] = {}
            end
            self.m_runSpinResultData.p_reels[rowIndex][colIndex] = symbolType
            startIndex = startIndex + 1
            if startIndex > #initDatas then
                startIndex = 1
            end

            --判断是否是否属于需要隐藏
            local isNeedHide = false
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                bigSymbolCount = bigSymbolCount + 1
                if bigSymbolCount > 1 then
                    isNeedHide = true
                    symbolType = 0
                end

                if bigSymbolCount == self.m_bigSymbolInfos[symbolType] then
                    bigSymbolCount = 0
                end
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if isNeedHide then
                node:setVisible(false)
            end

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function CodeGameScreenFrozenJewelryMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            --记录信号值(切换bet用)
            if not self.m_runSpinResultData.p_reels[rowIndex] then
                self.m_runSpinResultData.p_reels[rowIndex] = {}
            end
            self.m_runSpinResultData.p_reels[rowIndex][colIndex] = symbolType

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            --            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function CodeGameScreenFrozenJewelryMachine:randomSlotNodesByReel()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType)

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            --记录信号值(切换bet用)
            if not self.m_runSpinResultData.p_reels[rowIndex] then
                self.m_runSpinResultData.p_reels[rowIndex] = {}
            end
            self.m_runSpinResultData.p_reels[rowIndex][colIndex] = symbolType

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
function CodeGameScreenFrozenJewelryMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]

        local rowCount, rowNum, rowIndex = self:getinitSlotRowDatatByNetData(columnData)

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            if rowCount == 3 then
                rowDatas = self.m_initSpinData.p_reels[rowIndex + 3]
            end
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType)

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH
            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end
            node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            -- node:runIdleAnim()
            rowIndex = rowIndex - 1
        end -- end while
    end
    self:initGridList()
end

--[[
    @desc: 根据symbolType
    time:2019-03-20 15:12:12
    --@symbolType:
	--@row:
    --@col:
    --@isLastSymbol:
    @return:
]]
function CodeGameScreenFrozenJewelryMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    if isLastSymbol == nil then
        isLastSymbol = false
    end
    local symblNode = self:getSlotNodeBySymbolType(symbolType)
    symblNode.p_cloumnIndex = col
    symblNode.p_rowIndex = row
    symblNode.m_isLastSymbol = isLastSymbol

    if col == 3 and self.m_isDoubleReel then
        symblNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
    end

    self:updateReelGridNode(symblNode)
    return symblNode
end

--获得单列控制类
function CodeGameScreenFrozenJewelryMachine:getBaseReelControl()
    return "CodeFrozenJewelrySrc.FrozenJewelryReelControl"
end

--滚动
function CodeGameScreenFrozenJewelryMachine:getBaseReelSchedule()
    return "CodeFrozenJewelrySrc.FrozenJewelryReelSchedule"
end

function CodeGameScreenFrozenJewelryMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    local winSize = cc.Director:getInstance():getWinSize()
    self.m_isSpecialView = true
    if ratio >= 768 / 1024 then
        -- mainPosY = mainPosY - 20
        mainScale = 0.78
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        mainScale = 0.82
    elseif ratio < 640 / 960 and ratio >= 768 / 1230 then
        mainScale = 0.92
        mainPosY = mainPosY - 10
    else
        self.m_isSpecialView = false
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

function CodeGameScreenFrozenJewelryMachine:playEffectNotifyNextSpinCall()
    if self.m_isChangeFreeType then
        return
    end
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

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

    if self.m_currentMusicId == nil then
        self:resetMusicBg()
    end
    self:setMaxMusicBGVolume()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

----
--- 处理spin 成功消息
--
function CodeGameScreenFrozenJewelryMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
        local params = {}
        params.rewaedFSData = self.m_rewaedFSData
        params.states = "spinResult"
        gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_CHANGE_TIME, params)
    end
    if spinData.action == "SPIN" and not self.m_isShowSelectView then
        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

return CodeGameScreenFrozenJewelryMachine
