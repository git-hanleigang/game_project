---
-- island li
-- 2019年1月26日
-- CodeGameScreenChameleonRichesMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "ChameleonRichesPublicConfig"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local BaseDialog = util_require("Levels.BaseDialog")
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenChameleonRichesMachine = class("CodeGameScreenChameleonRichesMachine", BaseReelMachine)

CodeGameScreenChameleonRichesMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
-- CodeGameScreenChameleonRichesMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE

CodeGameScreenChameleonRichesMachine.SYMBOL_BONUS       = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 自定义的小块类型
CodeGameScreenChameleonRichesMachine.SYMBOL_SCATTER_1   = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 -- 自定义的小块类型   计数 scatter
CodeGameScreenChameleonRichesMachine.SYMBOL_SCATTER_2   = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3 -- 自定义的小块类型   wild scatter
CodeGameScreenChameleonRichesMachine.SYMBOL_WILD_2      = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4 -- 自定义的小块类型   wild 替换盘上时显示用


-- 自定义动画的标识
CodeGameScreenChameleonRichesMachine.UPDATE_UP_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --刷新上方奖励
CodeGameScreenChameleonRichesMachine.GET_UP_REWARD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --获得上方奖励
CodeGameScreenChameleonRichesMachine.UPDATE_LOCK_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --刷新固定的wild图标
local LOCK_SYMBOL_ZORDER    =   1000    --固定图标基础层级


-- 构造函数
function CodeGameScreenChameleonRichesMachine:ctor()
    CodeGameScreenChameleonRichesMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeChameleonRichesSrc.ChameleonRichesSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("ChameleonRichesLongRunControl",self) 

    self.m_lockScatterSymbols = {}  --固定的scatter图标
    self.m_lockWildSymbols = {}  --固定的wild图标
    self.m_scatterWildSymbols = {}

    --上一次spin上方虫子的数据
    self.m_preBugsData = nil
    self.m_tempBugs = {}

    self.m_isLongRun = false

    --音效用索引
    self.m_sound_index_1 = 1
    self.m_sound_index_2 = 1

    --上方赢钱数
    self.m_upWinCoins = 0
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    --init
    self:initGame()
end

function CodeGameScreenChameleonRichesMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 检测上次feature 数据
--
function CodeGameScreenChameleonRichesMachine:checkNetDataFeatures()
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

            if self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
                -- 添加freespin effect
                local freeSpinEffect = GameEffectData.new()
                freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
                freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
                self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

                self.m_isRunningEffect = true
            end
            

            if self.checkControlerReelType and self:checkControlerReelType() then
                globalMachineController.m_isEffectPlaying = true
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

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

function CodeGameScreenChameleonRichesMachine:initGameStatusData(gameData)
    CodeGameScreenChameleonRichesMachine.super.initGameStatusData(self, gameData)

    self.m_initMultiData = gameData.gameConfig.extra.initMulti
    self.m_betData = gameData.gameConfig.extra.betData or {}
    self.m_costGems = gameData.gameConfig.extra.gems
    self.m_addFreeCounts = gameData.gameConfig.extra.gemFreespins
end

--[[
    获取当前bet数据
]]
function CodeGameScreenChameleonRichesMachine:getCurBetData()
    local lineBet = globalData.slotRunData:getCurTotalBet()
    if self.m_betData[tostring(lineBet)] then
        return clone(self.m_betData[tostring(lineBet)])
    else
        local upReel = {}
        for index = 1,self.m_iReelColumnNum do
            upReel[index] = self.m_initMultiData[index] * lineBet
        end

        return {
            upReel = upReel
        }
    end
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenChameleonRichesMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ChameleonRiches"  
end


function CodeGameScreenChameleonRichesMachine:getBottomUINode()
    return "CodeChameleonRichesSrc.ChameleonRichesBottomNode"
end

--[[
    变更背景类型
]]
function CodeGameScreenChameleonRichesMachine:changeBgType(bgType)
    if bgType == "base" then
        self.m_gameBg:findChild("base"):setVisible(true)
        self.m_gameBg:findChild("free"):setVisible(false)
        self:findChild("Node_Base"):setVisible(true)
        self:findChild("Node_Free"):setVisible(false)
        self:runCsbAction("base")
    else 
        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("free"):setVisible(true)
        self:findChild("Node_Base"):setVisible(false)
        self:findChild("Node_Free"):setVisible(true)
        self:runCsbAction("free")
    end
end


function CodeGameScreenChameleonRichesMachine:initUI()

    --特效层
    self.m_effectNode = self:findChild("Node_Effect")

    self.m_effectNode2 = self:findChild("Node_Effect2")

    --固定图标层
    self.m_lockSymbolNode = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_lockSymbolNode)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_winTipsNode = self:findChild("Node_WinsTips")
    local pos = util_convertToNodeSpace(self.m_winTipsNode,self.m_lockSymbolNode)
    util_changeNodeParent(self.m_lockSymbolNode,self.m_winTipsNode,LOCK_SYMBOL_ZORDER + 500)
    self.m_winTipsNode:setPosition(pos)

    -- 创建view节点方式
    -- self.m_ChameleonRichesView = util_createView("CodeChameleonRichesSrc.ChameleonRichesView")
    -- self:findChild("xxxx"):addChild(self.m_ChameleonRichesView)

    self:changeBottomBigWinLabUi("ChameleonRiches_totalwin_shuzi.csb")

    self:changeCoinWinEffectUI(self:getModuleName(), "ChameleonRiches_totalwin.csb")
   
end

--[[
    初始化spine动画
]]
function CodeGameScreenChameleonRichesMachine:initSpineUI()
    self.m_bugItems = {}
    for iCol = 1,5 do
        local winTip = util_createAnimation("ChameleonRiches_WinsTips.csb")
        self:findChild("win_"..(iCol - 1)):addChild(winTip)
        for index = 1,5 do
            winTip:findChild("win"..index):setVisible(index == iCol)
        end

        local item = util_createView("CodeChameleonRichesSrc.ChameleonRichesBugItem",{machine = self})
        self:findChild("bug_"..(iCol - 1)):addChild(item)
        self.m_bugItems[iCol] = item
    end
end


function CodeGameScreenChameleonRichesMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_ChameleonRiches_enter_game)
    end)
end

function CodeGameScreenChameleonRichesMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenChameleonRichesMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    --刷新虫子身上的金币显示
    self:updateBugCoins()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBgType("free")
        self:showFreeSpinUI()
        self:updateLockWild()
    else
        self:changeBgType("base")
        --刷新固定的scatter图标
        self:updateLockScatter()

        if not self:checkTriggerBonus() then
            local enterTip = util_createView("CodeChameleonRichesSrc.ChameleonRichesEnterGameTipView")
            gLobalViewManager:showUI(enterTip)
        end
        
    end

end

---
-- 检测上次feature 数据
--
function CodeGameScreenChameleonRichesMachine:checkNetDataFeatures()
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

            local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)

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
    检测是否触发bonus
]]
function CodeGameScreenChameleonRichesMachine:checkTriggerBonus()
    local features = self.m_runSpinResultData.p_features
    if features then
        for index = 1,#features do
            if features[index] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                return true
            end
        end
    end
    
    return false
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenChameleonRichesMachine:checkTriggerINFreeSpin()
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

    local isInFs = false
    if
        hasFreepinFeature == false and self.m_initSpinData.p_freeSpinsTotalCount ~= nil and self.m_initSpinData.p_freeSpinsTotalCount > 0 and
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or (hasReSpinFeature == true or hasBonusFeature == true))
     then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    --触发了bonus但是剩余free次数不为0,则为触发时购买次数,此时不算free状态
    if hasBonusFeature and self.m_initSpinData.p_freeSpinsLeftCount > 0 then
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

function CodeGameScreenChameleonRichesMachine:addObservers()
    CodeGameScreenChameleonRichesMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            for index = 1,#self.m_tempBugs do
                self.m_tempBugs[index]:stopAllActions()
                self.m_tempBugs[index]:removeFromParent()
            end
            self.m_tempBugs = {}
            self.m_preBugsData = nil
            
            self:updateBugCoins()
            self:updateLockScatter()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        -- bonus玩法不播音效
        if params[self.m_stopUpdateCoinsSoundIndex] or params[5] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "free"
        else
            bgmType = "base"
        end

        local soundName = "sound_ChameleonRiches_"..bgmType.."_winline_"..soundIndex
        self.m_winSoundsId = gLobalSoundManager:playSound(PublicConfig.SoundConfig[soundName])
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenChameleonRichesMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    self:clearAllLockSymbols()
    util_resetChildReferenceCount(self.m_lockSymbolNode)
    self.m_lockSymbolNode:removeAllChildren()
    CodeGameScreenChameleonRichesMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
--设置bonus scatter 层级
function CodeGameScreenChameleonRichesMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
    elseif self:isScatterSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD_2 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_WILD then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_WILD - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenChameleonRichesMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BONUS then
        return "Socre_ChameleonRiches_Bonus"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_ChameleonRiches_Scatter"
    elseif symbolType == self.SYMBOL_SCATTER_1 then
        return "Socre_ChameleonRiches_Scatter_2"
    elseif symbolType == self.SYMBOL_SCATTER_2 then
        return "Socre_ChameleonRiches_Scatter_3"
    elseif symbolType == self.SYMBOL_WILD_2 then
        return "Socre_ChameleonRiches_Wild_2"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenChameleonRichesMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenChameleonRichesMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenChameleonRichesMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 

end

--[[
    刷新虫子上的金币显示
]]
function CodeGameScreenChameleonRichesMachine:updateBugCoins(curUpReelData)
    local curBetData = self:getCurBetData()

    local upReelData = curBetData.upReel
    if curUpReelData then
        upReelData = curUpReelData
    end
    for iCol = 1,self.m_iReelColumnNum do
        local coins = upReelData[iCol] or 0
        local bugItem = self.m_bugItems[iCol]
        bugItem:setCoins(coins)
        bugItem:runIdleAni()
    end
end

--[[
    刷新虫子上的金币为上一次spin的数据
]]
function CodeGameScreenChameleonRichesMachine:updatePreBugCoins()

    if not self.m_preBugsData then
        return
    end

    local upReelData = self.m_preBugsData.upReel
    for iCol = 1,self.m_iReelColumnNum do
        local coins = upReelData[iCol] or 0
        local bugItem = self.m_bugItems[iCol]
        bugItem:setCoins(coins)
        bugItem:runIdleAni()
    end
end

function CodeGameScreenChameleonRichesMachine:isScatterSymbol(symbolType)
    if symbolType == self.SYMBOL_SCATTER_1 or 
        symbolType == self.SYMBOL_SCATTER_2 or
        symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            return true
    end
    return false
end

function CodeGameScreenChameleonRichesMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return true
    end
    return false
end

-----------------------------------固定图标相关----------------------------------------------------------------------
--[[
    刷新固定Scatter图标
]]
function CodeGameScreenChameleonRichesMachine:updateLockScatter()
    local curBetData = self:getCurBetData()
    if not curBetData.stickSc then
        self:clearAllLockSymbols()
        return
    end

    local lockList = curBetData.stickSc
    --先移除多余的图标
    for index,lockNode in pairs(self.m_lockScatterSymbols) do
        local isRemove = true
        for key,data in pairs(lockList) do
            if index == data[1] then
                isRemove = false
                break
            end
        end

        if isRemove then
            --将锁定小块下边的图标变为普通图标
            local symbolNode = self:getSymbolByPosIndex(index)
            if symbolNode and self:isScatterSymbol(symbolNode.p_symbolType) then
                local symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
                self:changeSymbolType(symbolNode,symbolType)
            end
            lockNode:removeFromParent()
            self.m_lockScatterSymbols[index] = nil
        end
    end

    for key,data in ipairs(lockList) do
        local posIndex = data[1]
        local times = data[2]

        local lockNode
        if not self.m_lockScatterSymbols[posIndex] then
            lockNode = util_spineCreate("Socre_ChameleonRiches_Scatter_2",true,true) 
            util_spinePlay(lockNode,"idleframe2",true)
            self.m_lockSymbolNode:addChild(lockNode,LOCK_SYMBOL_ZORDER + posIndex)
            local csbNode = util_createAnimation("Socre_ChameleonRiches_Scatter2_shuzi.csb")
            lockNode:addChild(csbNode)
            lockNode.m_csbNode = csbNode
            csbNode:runCsbAction("idleframe",true)

            local nodePos = util_getOneGameReelsTarSpPos(self, posIndex)
            local worldPos = self.m_clipParent:convertToWorldSpace(nodePos)
            local pos = self.m_lockSymbolNode:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
            lockNode:setPosition(pos)
            self.m_lockScatterSymbols[posIndex] = lockNode
        else
            lockNode = self.m_lockScatterSymbols[posIndex]
        end

        for index = 1,3 do
            lockNode.m_csbNode:findChild("time_"..index):setVisible(times == index)
        end

        lockNode.m_posIndex = posIndex
        lockNode.m_times = times
    end
end

--[[
    根据索引刷新固定图标(播完落地后调用)
]]
function CodeGameScreenChameleonRichesMachine:updateLockScatterByPosIndex(posIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.betData then
        return
    end
    local betData = selfData.betData
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local curBetData = betData[tostring(lineBet)]
    if not curBetData or not curBetData.stickSc or self.m_lockScatterSymbols[posIndex] then
        return
    end

    local lockList = curBetData.stickSc
    for key,data in ipairs(lockList) do
        if data[1] == posIndex then
            local times = data[2]
            local lockNode = util_spineCreate("Socre_ChameleonRiches_Scatter_2",true,true) 
            util_spinePlay(lockNode,"buling")
            util_spineEndCallFunc(lockNode,"buling",function()
                util_spinePlay(lockNode,"idleframe2",true)
            end)
            self.m_lockSymbolNode:addChild(lockNode,LOCK_SYMBOL_ZORDER + posIndex)
            local csbNode = util_createAnimation("Socre_ChameleonRiches_Scatter2_shuzi.csb")
            lockNode:addChild(csbNode)
            lockNode.m_csbNode = csbNode
            csbNode:runCsbAction("buling",false,function()
                csbNode:runCsbAction("idleframe",true)
            end)

            local nodePos = util_getOneGameReelsTarSpPos(self, posIndex)
            local worldPos = self.m_clipParent:convertToWorldSpace(nodePos)
            local pos = self.m_lockSymbolNode:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
            lockNode:setPosition(pos)
            self.m_lockScatterSymbols[posIndex] = lockNode

            for index = 1,3 do
                lockNode.m_csbNode:findChild("time_"..index):setVisible(times == index)
            end

            lockNode.m_posIndex = posIndex
            lockNode.m_times = times
            break
        end
    end
end

--[[
    刷新固定图标的剩余次数
]]
function CodeGameScreenChameleonRichesMachine:updateLockScatterTimes()
    for key,lockNode in pairs(self.m_lockScatterSymbols) do
        if lockNode then
            lockNode.m_times = lockNode.m_times - 1
            local times = lockNode.m_times
            
            --次数为0的跟着滚走
            if lockNode.m_times < 1 then
                local symbolNode = self:getSymbolByPosIndex(lockNode.m_posIndex)
                if symbolNode then
                    self:changeSymbolType(symbolNode,self.SYMBOL_SCATTER_1)
                end
                lockNode:removeFromParent()
                self.m_lockScatterSymbols[key] = nil
            else
                lockNode.m_csbNode:runCsbAction("switch",false,function()
                    lockNode.m_csbNode:runCsbAction("idleframe",true)
                end)
                --刷新次数
                for index = 1,3 do
                    lockNode.m_csbNode:findChild("time_"..index):setVisible(times == index)
                end
            end
        end
    end
end

--[[
    刷新固定Wild图标
]]
function CodeGameScreenChameleonRichesMachine:updateLockWild()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if not fsExtraData or not fsExtraData.stickWild then
        self:clearAllLockSymbols()
        return
    end

    local lockList = clone(fsExtraData.stickWild)

    if self:checkTriggerFree() and self:getCurrSpinMode() == FREE_SPIN_MODE and fsExtraData.newStickWild then
        local newStickWild = fsExtraData.newStickWild
        for iNew = 1,#newStickWild do
            for index = #lockList,1,-1 do
                if newStickWild[iNew] == lockList[index] then
                    table.remove(lockList,index)
                    break
                end
            end
        end
    end
    

    

    for key,posIndex in ipairs(lockList) do

        local lockNode
        if not self.m_lockWildSymbols[posIndex] then
            lockNode = util_spineCreate("Socre_ChameleonRiches_Wild_2",true,true)
            util_spinePlay(lockNode,"idleframe2",true)
            self.m_lockSymbolNode:addChild(lockNode,LOCK_SYMBOL_ZORDER + posIndex)
            local nodePos = util_getOneGameReelsTarSpPos(self, posIndex)
            local worldPos = self.m_clipParent:convertToWorldSpace(nodePos)
            local pos = self.m_lockSymbolNode:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
            lockNode:setPosition(pos)
            self.m_lockWildSymbols[posIndex] = lockNode
        else
            lockNode = self.m_lockWildSymbols[posIndex]
        end

        lockNode.m_posIndex = posIndex
    end
end

--[[
    将固定的scatter转变为固定的wild
]]
function CodeGameScreenChameleonRichesMachine:changeLockScatterToWild(func)
    
    local delayTime = 0
    for posIndex,lockNode in pairs(self.m_lockScatterSymbols) do
        local nodePos = util_getOneGameReelsTarSpPos(self, posIndex)
        local worldPos = self.m_clipParent:convertToWorldSpace(nodePos)
        local pos = self.m_lockSymbolNode:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        lockNode:setPosition(pos)
        util_spinePlay(lockNode,"switch")
        util_spineEndCallFunc(lockNode,"switch",function()
            local lockWild = util_spineCreate("Socre_ChameleonRiches_Wild_2",true,true)
            self.m_lockSymbolNode:addChild(lockWild,LOCK_SYMBOL_ZORDER + posIndex)
            local pos = cc.p(lockNode:getPosition())
            lockWild:setPosition(pos)
            self.m_lockWildSymbols[posIndex] = lockWild
            lockWild.m_posIndex = posIndex
            util_spinePlay(lockWild,"idleframe2",true)
            
            --移除固定的scatter
            lockNode:setVisible(false)
            self:delayCallBack(0.1,function()
                lockNode:removeFromParent()
                self.m_lockScatterSymbols[posIndex] = nil
            end)
        end)
        lockNode.m_csbNode:runCsbAction("actionframe")

        local aniTime = lockNode:getAnimationDurationTime("switch")
        if aniTime > delayTime then
            delayTime = aniTime
        end
    end

    if delayTime > 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_lock_wild)
    end

    self:delayCallBack(delayTime,func)
end

--[[
    添加新的固定wild图标
]]
function CodeGameScreenChameleonRichesMachine:addNewLockWild(func)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData and fsExtraData.newStickWild and next(fsExtraData.newStickWild) then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_lock_wild)
        local delayTime = 0
        for i,posIndex in ipairs(fsExtraData.newStickWild) do
            local symbolNode = self.m_scatterWildSymbols[tostring(posIndex)]
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCATTER_2 then
                --创建一个临时的spine
                local tempNode = util_spineCreate("Socre_ChameleonRiches_Scatter_3",true,true)
                self.m_lockSymbolNode:addChild(tempNode,LOCK_SYMBOL_ZORDER + posIndex)
                local pos = util_convertToNodeSpace(symbolNode,self.m_lockSymbolNode)
                tempNode:setPosition(pos)

                --创建固定的wild
                local lockWild = util_spineCreate("Socre_ChameleonRiches_Wild_2",true,true)
                self.m_lockSymbolNode:addChild(lockWild,LOCK_SYMBOL_ZORDER + posIndex)
                lockWild:setPosition(pos)
                self.m_lockWildSymbols[posIndex] = lockWild
                lockWild.m_posIndex = posIndex
                lockWild:setVisible(false)


                util_spinePlay(tempNode,"switch")
                util_spineEndCallFunc(tempNode,"switch",function()
                    tempNode:setVisible(false)
                    self:delayCallBack(0.1,function()
                        tempNode:removeFromParent()
                    end)

                    lockWild:setVisible(true)
                    util_spinePlay(lockWild,"idleframe2",true)
                end)

                delayTime = symbolNode:getAniamDurationByName("switch")
                self:changeSymbolType(symbolNode,self.SYMBOL_WILD_2)
                
            end
        end


        self:delayCallBack(delayTime,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    else
        self:updateLockWild()
        -- self:changeSymbolToWild()

        if type(func) == "function" then
            func()
        end
    end
end

--[[
    将信号转变为wild信号
]]
function CodeGameScreenChameleonRichesMachine:changeSymbolToWild()
    for posIndex,lockNode in pairs(self.m_lockWildSymbols) do
        local symbolNode = self:getSymbolByPosIndex(posIndex)
        if symbolNode and symbolNode.p_symbolType ~= self.SYMBOL_WILD_2 then
            self:changeSymbolType(symbolNode,self.SYMBOL_WILD_2)
            self:changeSymbolToClipParent(symbolNode)
        end
    end
end

--[[
    设置固定的wild是否可见
]]
function CodeGameScreenChameleonRichesMachine:setLockWildShow(isShow)
    for posIndex,lockNode in pairs(self.m_lockWildSymbols) do
        if lockNode:isVisible() ~= isShow then
            lockNode:setVisible(isShow)
            if isShow then
                util_spinePlay(lockNode,"idleframe2",true)
            end
        end
        
    end
end

--[[
    清理所有固定的小块
]]
function CodeGameScreenChameleonRichesMachine:clearAllLockSymbols()
    for k,lockNode in pairs(self.m_lockScatterSymbols) do
        lockNode:removeFromParent()
    end

    for k,lockNode in pairs(self.m_lockWildSymbols) do
        lockNode:removeFromParent()
    end
    self.m_lockScatterSymbols = {}
    self.m_lockWildSymbols = {}
    
end

------------------------------------固定图标相关 end---------------------------------------------------------------------
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenChameleonRichesMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenChameleonRichesMachine:beginReel()
    self.m_upWinCoins = 0
    self.m_isLongRun = false
    self.m_symbolExpectCtr.m_isPlayExpectAni = false

    self:showBlackLayer()
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:updateLockScatterTimes()
        self.m_scatterWildSymbols = {}
        CodeGameScreenChameleonRichesMachine.super.beginReel(self)
    else
        self:clearWinLineEffect()
        self:setLockWildShow(true)
        self:beginReelAfterChangeLockWild()
        self.m_scatterWildSymbols = {}
    end
    
    
end

function CodeGameScreenChameleonRichesMachine:beginReelAfterChangeLockWild()
    self:resetReelDataAfterReel()
    self:checkChangeBaseParent()

    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local endCount = 0
    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        local moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
        for iCol = 1,#self.m_baseReelNodes do
            local reelNode = self.m_baseReelNodes[iCol]
            local parentData = self.m_slotParents[iCol]
            parentData.moveSpeed = moveSpeed
            reelNode:changeReelMoveSpeed(moveSpeed)
        end
        reelNode:resetReelDatas()
        reelNode:startMove(function()
            endCount = endCount + 1
            if endCount >= #self.m_baseReelNodes then
                self:addNewLockWild(function()
                    self:requestSpinReusltData()
                end)
            end
        end)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenChameleonRichesMachine:slotOneReelDown(reelCol)    
    self.m_isLongRun = CodeGameScreenChameleonRichesMachine.super.slotOneReelDown(self,reelCol)
    
    if reelCol < self.m_iReelColumnNum then
        self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
    end
    
    
end

function CodeGameScreenChameleonRichesMachine:dealSmallReelsSpinStates()
    if not self.b_gameTipFlag and not self.m_isLongRun then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    end
    
end

--[[
    通知刷新赢钱
]]
function CodeGameScreenChameleonRichesMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop,nil,self.m_upWinCoins})
end

--[[
    滚轮停止
]]
function CodeGameScreenChameleonRichesMachine:slotReelDown( )
    self:hideBlackLayer()

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local betData = selfData.betData
    if betData[tostring(lineBet)] then
        self.m_betData[tostring(lineBet)] = betData[tostring(lineBet)]
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeSymbolToWild()
        
        self.m_symbolExpectCtr:MachineOneReelDownCall(self.m_iReelColumnNum)
        CodeGameScreenChameleonRichesMachine.super.slotReelDown(self)
        
    else
        local delayTime = 0
        if next(self.m_scatterWildSymbols) then
            if self:getGameSpinStage( ) == QUICK_RUN then
                delayTime = 0.5
            else
                for posIndex,symbolNode in pairs(self.m_scatterWildSymbols) do
                    if symbolNode.p_cloumnIndex == self.m_iReelColumnNum then
                        delayTime = 0.5
                        break
                    end
                end
            end
            
        end
        if delayTime > 0 then
            self:delayCallBack(0.5,function()
                self.m_symbolExpectCtr:MachineOneReelDownCall(self.m_iReelColumnNum)
                CodeGameScreenChameleonRichesMachine.super.slotReelDown(self)
            end)
        else
            self.m_symbolExpectCtr:MachineOneReelDownCall(self.m_iReelColumnNum)
            CodeGameScreenChameleonRichesMachine.super.slotReelDown(self)
        end
    end

    
    

end

---------------------------------------------------------------------------

--[[
    显示大赢光效事件
]]
function CodeGameScreenChameleonRichesMachine:showEffect_runBigWinLightAni(effectData)

    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1,
        animName   = "actionframe_bigwin",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()

        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenChameleonRichesMachine:showBigWinLight(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_big_win_light)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local spine = util_spineCreate("ChameleonRiches_bigwin",true,true)
    rootNode:addChild(spine)
    spine:setPosition(pos)

    util_spinePlay(spine,"actionframe_bigwin")
    util_spineEndCallFunc(spine,"actionframe_bigwin",function()
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
    end)

    local light = util_spineCreate("ChameleonRiches_bigwin_2",true,true)
    self:findChild("Node_bigwin_bg"):addChild(light)
    local aniName = "actionframe_bigwin"
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        aniName = "actionframe_bigwin2"
    end

    util_spinePlay(light,aniName)
    util_spineEndCallFunc(light,aniName,function()
        light:setVisible(false)
        self:delayCallBack(0.1,function()
            light:removeFromParent()
        end)
    end)

    local aniTime = spine:getAnimationDurationTime("actionframe_bigwin")
    util_shakeNode(rootNode,5,10,aniTime)

    

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenChameleonRichesMachine:addSelfEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local winLines = self.m_runSpinResultData.p_winLines

    if selfData and selfData.bonusLines and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.GET_UP_REWARD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.GET_UP_REWARD_EFFECT -- 动画类型
    end

    if not self:checkTriggerFree() and self:getCurrSpinMode() ~= FREE_SPIN_MODE and ((winLines and #winLines > 0) or (selfData and selfData.bonusLines)) then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_BIG_WIN_LIGHT + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.UPDATE_UP_EFFECT -- 动画类型

        for index = 1,#self.m_tempBugs do
            self.m_tempBugs[index]:stopAllActions()
            self.m_tempBugs[index]:removeFromParent()
        end
        self.m_tempBugs = {}
        
        self:updatePreBugCoins()
    end
end

--[[
    检测是否触发free
]]
function CodeGameScreenChameleonRichesMachine:checkTriggerFree()
    local features = self.m_runSpinResultData.p_features or {}
    if features then
        for index = 1, #features do 
            local featureId = features[index]
            if featureId == SLOTO_FEATURE.FEATURE_FREESPIN or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                return true
            end
        end
    end

    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenChameleonRichesMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.UPDATE_UP_EFFECT then

        self:runSwitchBugsAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    elseif effectData.p_selfEffectType == self.GET_UP_REWARD_EFFECT then
        self:getUpReward(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    -- elseif effectData.p_selfEffectType == self.UPDATE_LOCK_WILD_EFFECT then
    --     self:delayCallBack(0.5,function()
    --         self:addNewLockWild(function()
    --             effectData.p_isPlay = true
    --             self:playGameEffect()
    --         end)
    --     end)
        
    end

    return true
end



--[[
    创建一个虫子
]]
function CodeGameScreenChameleonRichesMachine:createBugItems(coins)
    local item = util_createView("CodeChameleonRichesSrc.ChameleonRichesBugItem",{machine = self})
    item:setCoins(coins)
    item:runIdleAni()

    return item
end

--[[
    切换虫子
]]
function CodeGameScreenChameleonRichesMachine:runSwitchBugsAni(func)
    

    local curBetData = self:getCurBetData()
    local upReelData = curBetData.upReel

    self.m_preBugsData = curBetData

    local coins = upReelData[1]
    
    local tempItem = self:createBugItems(coins)
    self:findChild("bug_0"):addChild(tempItem)

    self.m_tempBugs[#self.m_tempBugs + 1] = tempItem

    local delayTime = tempItem:runStartAni()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_bug_switch)
    
    for index = 1,#self.m_bugItems do
        local bugItem = self.m_bugItems[index]
        local aniTime = bugItem:runSwitchAni(index) 
        -- if aniTime > delayTime then
        --     delayTime = aniTime
        -- end
    end

    performWithDelay(tempItem,function()
        tempItem:setVisible(false)
        self:updateBugCoins(curBetData.upReel)
    end,delayTime)

    if type(func) == "function" then
        func()
    end
end

--[[
    获取上方bonus奖励
]]
function CodeGameScreenChameleonRichesMachine:getUpReward(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.bonusLines then

        if type(func) == "function" then
            func()
        end
        
        return
    end
    local list = selfData.bonusLines
    

    self:delayCallBack(35 / 30,function()

        local blackMask = util_createAnimation("ChameleonRiches_mask.csb")
        self.m_effectNode2:addChild(blackMask)
        blackMask:runCsbAction("start")

        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_bonus_trigger)
        
        if math.random(1,10) <= 3 then
            if self.m_sound_index_1 == 1 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_ah)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_yay)
            end
            
            self.m_sound_index_1  = self.m_sound_index_1 + 1
            if self.m_sound_index_1 > 2 then
                self.m_sound_index_1 = 1
            end
        end

        self:getNextUpReward(list,1,function()

            blackMask:runCsbAction("over",false,function()
                blackMask:removeFromParent()
            end)

            self:delayCallBack(1,func)
        end)
    end)
    
end

--[[
    获取下一个奖励
]]
function CodeGameScreenChameleonRichesMachine:getNextUpReward(list,index,func)
    if index > #list then
        

        if not self:checkHasBigWin() then
            self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
        end
        self:delayCallBack(42 / 30,function()
        
            if math.random(1,10) <= 3 then
                if self.m_sound_index_2 == 1 then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_tasty)
                else
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_there_you_go)
                end
                
                self.m_sound_index_2  = self.m_sound_index_2 + 1
                if self.m_sound_index_2 > 2 then
                    self.m_sound_index_2 = 1
                end
            end

            self:playCoinWinEffectUI()
            globalData.slotRunData.lastWinCoin = 0
            local isUpdateTop = false
            if self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines == 0 then
                isUpdateTop = true
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_upWinCoins, isUpdateTop})

            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_collect_bonus_feed_back)
            local winLabel = util_createAnimation("ChameleonRiches_totalwin_shuzi2.csb")
            self.m_bottomUI.coinWinNode:addChild(winLabel)

            local lbl_coins = winLabel:findChild("m_lb_coins")
            lbl_coins:setString("+"..util_getFromatMoneyStr(self.m_upWinCoins))
            self:updateLabelSize({label=lbl_coins,sx=1,sy=1},1000)    
            winLabel:runCsbAction("actionframe",false,function()
                winLabel:removeFromParent()
            end)

            if type(func) == "function" then
                func()
            end
        end)
        
        return
    end

    local data = list[index]
    self.m_upWinCoins = self.m_upWinCoins + data.amount

    local colIndex = data.col + 1
    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS then
            
            symbolNode:changeParentToOtherNode(self.m_effectNode)
            local bugItem = self.m_bugItems[colIndex]
            bugItem:setVisible(false)

            --创建一个临时的
            local tempItem = self:createBugItems(bugItem.m_coins)
            self.m_effectNode2:addChild(tempItem)
            tempItem:setPosition(util_convertToNodeSpace(self:findChild("bug_"..(colIndex - 1)),self.m_effectNode2))
            tempItem:runCollectIdle()

            local aniName = "shouji"
            local row = self.m_iReelRowNum - iRow + 1
            aniName = aniName..row
            if bugItem.m_isBigWin then
                aniName = aniName.."_y"
            else
                aniName = aniName.."_r"
            end

            --切换虫子
            self:delayCallBack(34 / 30,function()
                bugItem:setVisible(true)
                bugItem:runStartAni()
                tempItem:removeFromParent()
                
            end)

            symbolNode:runAnim(aniName,false,function()
                

                symbolNode:changeParentToOtherNode(self.m_clipParent)
                local idleName = "idleframe2"
                if bugItem.m_isBigWin then
                    idleName = idleName.."_y"
                else
                    idleName = idleName.."_r"
                end
                symbolNode:runAnim(idleName,true)

                
            end)

            self:getNextUpReward(list,index + 1,func)
            return
        end
    end

end

function CodeGameScreenChameleonRichesMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
    if startIndex == nil then
        startIndex = 1
    end
    if endIndex == nil then
        endIndex = #winLines
    end

    if bChangeToMask == nil then
        bChangeToMask = true
    end

    local function checkAddLineSlotNode(slotNode)
        if slotNode ~= nil then
            local isHasNode = false
            for checkIndex = 1, #self.m_lineSlotNodes do
                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end
            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex = startIndex, endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then
            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i = 1, frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local iCol = symPosData.iY
                local iRow = symPosData.iX

                local reelNode = self.m_baseReelNodes[symPosData.iY]
                local isInLong,longInfo = false,nil
                if reelNode then
                    isInLong,longInfo = reelNode:checkIsInLongByInfo(iRow)
                    if isInLong and longInfo then
                        iRow = longInfo.startIndex
                    end
                end


                local slotNode = self:getSymbolInLineNode(iCol,iRow)
                if not slotNode then
                    slotNode = self:getFixSymbol(iCol,iRow)
                end

                if not slotNode then
                    slotNode = self.m_scatterWildSymbols[tostring(self:getPosReelIdx(iRow, iCol))]
                end

                checkAddLineSlotNode(slotNode)

                if slotNode and slotNode.p_symbolType then
                    if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                        self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                    end
    
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] =slotNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end
end

function CodeGameScreenChameleonRichesMachine:showLineFrame()
    self:setLockWildShow(false)
    
    CodeGameScreenChameleonRichesMachine.super.showLineFrame(self)
end

function CodeGameScreenChameleonRichesMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenChameleonRichesMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenChameleonRichesMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_scatter_trigger_free)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_scatter_trigger)
        end
    end
end

-- 不用系统音效
function CodeGameScreenChameleonRichesMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenChameleonRichesMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


--新滚动使用
function CodeGameScreenChameleonRichesMachine:updateReelGridNode(symbolNode)
    if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCATTER_1 then
        local csbNode = self:getLblCsbOnBonusSymbol(symbolNode,"Socre_ChameleonRiches_Scatter2_shuzi.csb")
        for index = 1,3 do
            csbNode:findChild("time_"..index):setVisible(index == 3)
        end
    elseif symbolNode and symbolNode.p_symbolType == self.SYMBOL_WILD_2 or symbolNode.p_symbolType == self.SYMBOL_BONUS  then
        symbolNode:runAnim("idleframe2",true)
    end
end

--[[
    获取小块spine槽点上绑定的csb节点
    csbName csb文件名称
    bindNodeName 槽点名称
]]
function CodeGameScreenChameleonRichesMachine:getLblCsbOnBonusSymbol(symbolNode,csbName)
    if tolua.isnull(symbolNode) then
        return
    end
    
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and tolua.isnull(spine.m_bindCsbNode) then

        local label = util_createAnimation(csbName)
        spine:addChild(label)
        spine.m_bindCsbNode = label
    end

    return spine.m_bindCsbNode,spine
end

----------------------------新增接口插入位---------------------------------------------
function CodeGameScreenChameleonRichesMachine:showEffect_Bonus(effectData)
    

    self:clearWinLineEffect()

    --在调用showView之前需重置界面显示
    local endFunc = function(freeData,isBuy)
        self:checkAddFSCount(freeData,isBuy,function()
            effectData.p_isPlay = true
            self:playGameEffect() 
        end)  
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData

    local params = {
        isFirst = selfData.isFirst or false,
        fsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount,
        fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount,
        winCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30),
        costGems = self.m_costGems,
        addFreeCounts = self.m_addFreeCounts,
        machine = self
    }

    

    local showView = function()
        local bonusGameView = util_createView("CodeChameleonRichesSrc.ChameleonRichesBonusGame",params)
        gLobalViewManager:showUI(bonusGameView)
        bonusGameView:findChild(self.m_machineRootScale)
        bonusGameView:resetView(nil,endFunc)
        bonusGameView:showView()
    end

    if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        self:clearCurMusicBg()
        self:levelDeviceVibrate(6, "free")
        self:runScatterTriggerAni(function()
            showView()
        end)
    else
        showView()
    end

    return true
end

--[[
    @desc: 如果触发了 freespin 时，将本次触发的bigwin 和 mega win 去掉
    time:2019-01-22 15:31:18
    @return:
]]
function CodeGameScreenChameleonRichesMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        if self.m_bProduceSlots_InFreeSpin == false then
            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
            self.m_bIsBigWin = false
        end
    end

    -- 如果处于 freespin 中 那么大赢都不触发
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_bIsBigWin = false
    end
end

--[[
    检测添加free事件
]]
function CodeGameScreenChameleonRichesMachine:checkAddFSCount(freeData,isBuy,func)
    --检测是否有free结束事件
    if freeData.freeSpinsLeftCount == 0 then --结束时没有购买
        self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
        self:changeSceneToBase(function()
            self:hideFreeSpinUI()
            
        end,function()
            if type(func) == "function" then
                func()
            end
            self:triggerFreeSpinOverCallFun()
        end)
        
        return
    end

    -- 保留freespin 数量信息
    self:updateFreeCount(freeData.freeSpinsLeftCount,freeData.freeSpinsTotalCount)

    if freeData.freeSpinsLeftCount == freeData.freeSpinsTotalCount then
        if isBuy then
            self:updateFreeCount(freeData.freeSpinsLeftCount - 1,freeData.freeSpinsTotalCount - 1)
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_change_scene_to_free)
        self:setCurrSpinMode(FREE_SPIN_MODE)
        self:resetMusicBg() 
        self:changeSceneToFree(function()
            self:showFreeSpinUI()
            self:triggerFreeSpinCallFun()
        end,function()
            if isBuy then
                self:updateFreeCount(freeData.freeSpinsLeftCount,freeData.freeSpinsTotalCount)
                gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            end
            self:changeLockScatterToWild(function()
                
                if type(func) == "function" then
                    func()
                end
            end)
        end)
    else
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:delayCallBack(50 / 60,func)
    end
    
end

--[[
    刷新free次数数据
]]
function CodeGameScreenChameleonRichesMachine:updateFreeCount(leftCount,totalCount)
    globalData.slotRunData.freeSpinCount = leftCount
    globalData.slotRunData.totalFreeSpinCount = totalCount
    self.m_runSpinResultData.p_freeSpinsLeftCount = leftCount
    self.m_runSpinResultData.p_freeSpinsTotalCount = totalCount

    self.m_iFreeSpinTimes = leftCount
end

--[[
    过场动画
]]
function CodeGameScreenChameleonRichesMachine:changeSceneToBase(keyFunc,endFunc)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_change_scene_to_base)
    self:changeSceneToFree(keyFunc,endFunc)
end

--[[
    过场动画
]]
function CodeGameScreenChameleonRichesMachine:changeSceneToFree(keyFunc,endFunc)
    
    local spine = util_spineCreate("ChameleonRiches_guochang",true,true)
    self:findChild("root"):addChild(spine)
    util_spinePlay(spine,"actionframe_guochang")
    self:delayCallBack(40 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)
    util_spineEndCallFunc(spine,"actionframe_guochang",function()
        if type(endFunc) == "function" then
            endFunc()
        end
        spine:setVisible(false)
        self:delayCallBack(0.1,function()
            spine:removeFromParent()
        end)
    end)
end


function CodeGameScreenChameleonRichesMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeChameleonRichesSrc.ChameleonRichesFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_FreeGameBar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenChameleonRichesMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenChameleonRichesMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end

--[[
    显示freeSpin相关UI
]]
function CodeGameScreenChameleonRichesMachine:showFreeSpinUI()
    self:showFreeSpinBar()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

    self:changeBgType("free")

    self:findChild("Node_bonus"):setVisible(false)
    self.m_winTipsNode:setVisible(false)

    for posIndex,lockNode in pairs(self.m_lockScatterSymbols) do
        local nodePos = util_getOneGameReelsTarSpPos(self, posIndex)
        local worldPos = self.m_clipParent:convertToWorldSpace(nodePos)
        local pos = self.m_lockSymbolNode:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        lockNode:setPosition(pos)
    end
end

--[[
    隐藏free相关UI
]]
function CodeGameScreenChameleonRichesMachine:hideFreeSpinUI()
    self:hideFreeSpinBar()

    self:changeBgType("base")
    self:findChild("Node_bonus"):setVisible(true)
    self.m_winTipsNode:setVisible(true)
    self:updateBugCoins()

    self.m_preBugsData = nil

    self:clearAllLockSymbols()
    self:updateLockScatter()
end

function CodeGameScreenChameleonRichesMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("ChameleonRichesSounds/music_ChameleonRiches_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)

            local spine = util_spineCreate("ChameleonRiches_tanbanstart",true,true)
            view:findChild("Node_spine"):addChild(spine)
            util_spinePlay(self.m_spine,"start")
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_change_scene_to_free)
                self:setCurrSpinMode(FREE_SPIN_MODE)
                self:resetMusicBg()
                self:changeSceneToFree(function()
                    self:showFreeSpinUI()
                    
                end,function()
                    self:changeLockScatterToWild(function()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()   
                    end)
                end)
                    
            end)

            local spine = util_spineCreate("ChameleonRiches_tanbanstart",true,true)
            view:findChild("Node_spine"):addChild(spine)
            util_spinePlay(self.m_spine,"start")
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenChameleonRichesMachine:showFreeSpinStart(num, func, isAuto)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_show_free_start)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local autoType = nil
    if isAuto then
        autoType = BaseDialog.AUTO_TYPE_NOMAL
    end

    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, autoType)

    view:findChild("Button_1"):setTouchEnabled(false)
    self:delayCallBack(1,function()
        if not tolua.isnull(view) then
            view:findChild("Button_1"):setTouchEnabled(true)
        end
        
    end)

    local spine = util_spineCreate("ChameleonRiches_tanbanstart",true,true)
    view:findChild("Node_spine"):addChild(spine)
    util_spinePlay(spine,"start")

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_btn_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_hide_free_start)
        
    end)

    return view

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenChameleonRichesMachine:showFreeSpinMore(num, func, isAuto)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_free_more)
    local function newFunc()
        self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:delayCallBack(50 / 60,func)
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num

    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)

    local spine = util_spineCreate("ChameleonRiches_tanbanstart",true,true)
    view:findChild("Node_spine"):addChild(spine)
    util_spinePlay(spine,"start")

    return view
end

---
--判断改变freespin的状态
function CodeGameScreenChameleonRichesMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self:checkTriggerFsOver() then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
            end
        end
    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
        end
    end
end

function CodeGameScreenChameleonRichesMachine:checkTriggerFsOver()
    local features = self.m_runSpinResultData.p_features
    for index = 1,#features do
        if features[index] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            return false
        end
    end
    if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        return true
    end
    return false
end

function CodeGameScreenChameleonRichesMachine:showFreeSpinOverView(effectData)
    gLobalSoundManager:playSound("ChameleonRichesSounds/sound_ChameleonRiches_show_free_over.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    local view = self:showFreeSpinOver(
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()

            self:changeSceneToBase(function()
                self:hideFreeSpinUI()
            
            end,function()
                self:triggerFreeSpinOverCallFun()
            end)
            
        end
    )

    view:findChild("Button_1"):setTouchEnabled(false)
    self:delayCallBack(1,function()
        if not tolua.isnull(view) then
            view:findChild("Button_1"):setTouchEnabled(true)
        end
    end)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_btn_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_hide_free_over)
        
    end)
    
end

function CodeGameScreenChameleonRichesMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()

    if globalData.slotRunData.lastWinCoin > 0 then
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},700)    

        local spine = util_spineCreate("ChameleonRiches_tanbanstart",true,true)
        view:findChild("Node_spine"):addChild(spine)
        util_spinePlay(spine,"start")

        return view
    else
        local view = self:showDialog("FreeSpinOver_NoWin", ownerlist, func)
        return view
    end

    
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenChameleonRichesMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()


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

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    local waitTime = 0
    
    self:runScatterTriggerAni(function()
        self:showFreeSpinView(effectData)
    end)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

function CodeGameScreenChameleonRichesMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    if self:checkTriggerFree() or self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        self:delayCallBack(0.5,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true
end

--[[
    scatter触发动画
]]
function CodeGameScreenChameleonRichesMachine:runScatterTriggerAni(func)
    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()

    self:delayCallBack(0.5,function()
        local delayTime = 0
        
        for index = 1,self.m_iReelColumnNum * self.m_iReelRowNum do
            local symbolNode = self:getSymbolByPosIndex(index - 1)
            if symbolNode and self:isScatterSymbol(symbolNode.p_symbolType) then
                
                if symbolNode.p_symbolType ~= self.SYMBOL_SCATTER_2  then
                    symbolNode:changeParentToOtherNode(self.m_lockSymbolNode,LOCK_SYMBOL_ZORDER + index + 1000)
                    symbolNode:runAnim("actionframe",false,function()
                        if symbolNode.p_symbolType ~= self.SYMBOL_SCATTER_2 then
                            self:putSymbolBackToPreParent(symbolNode)
                        end
                    end)
                elseif not self.m_scatterWildSymbols[tostring(index - 1)] then
                    
                    self.m_scatterWildSymbols[tostring(index - 1)] = symbolNode
                end
                
                local duration = symbolNode:getAniamDurationByName("actionframe")
                if duration > delayTime then
                    delayTime = duration
                end
            end
        end

        for index,symbolNode in pairs(self.m_scatterWildSymbols) do
            symbolNode:changeParentToOtherNode(self.m_lockSymbolNode)
            symbolNode:setLocalZOrder(LOCK_SYMBOL_ZORDER + tonumber(index) + 1000)
            symbolNode:runAnim("actionframe2",false,function()
                symbolNode:setLocalZOrder(LOCK_SYMBOL_ZORDER + tonumber(index))
            end)
            
            local duration = symbolNode:getAniamDurationByName("actionframe2")
            if duration > delayTime then
                delayTime = duration
            end
        end             
        

        for index,lockNode in pairs(self.m_lockScatterSymbols) do
            lockNode:setLocalZOrder(LOCK_SYMBOL_ZORDER + tonumber(index) + 1000)
            util_spinePlay(lockNode,"actionframe")
            util_spineEndCallFunc(lockNode,"actionframe",function()
                lockNode:setLocalZOrder(LOCK_SYMBOL_ZORDER + tonumber(index))
            end)
            local duration = lockNode:getAnimationDurationTime("actionframe")
            if duration > delayTime then
                delayTime = duration
            end
        end

        self:delayCallBack(delayTime + 0.5,func)
    end)

    
end

function CodeGameScreenChameleonRichesMachine:symbolBulingEndCallBack(_slotNode)
    if tolua.isnull(_slotNode) then
        return
    end
    local symbolType = _slotNode.p_symbolType

    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 

    if symbolType == self.SYMBOL_SCATTER_1 then
        local posIndex = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
        local randType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
        self:changeSymbolType(_slotNode,randType)

        
        self.m_scatterWildSymbols[tostring(posIndex)] = nil
        _slotNode:setVisible(true)
    end
end

--[[
    检测播放落地动画
]]
function CodeGameScreenChameleonRichesMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                --提层
                if symbolCfg[1] then
                    local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                    if symbolNode.p_symbolType == self.SYMBOL_SCATTER_1 then
                        self:changeSymbolToClipParent(symbolNode)
                        --刷新锁定的小块
                        self:updateLockScatterByPosIndex(self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex))
                        symbolNode:setVisible(false)

                        local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, colIndex)
                        self.m_scatterWildSymbols[tostring(posIndex)] = symbolNode
                    elseif symbolNode.p_symbolType == self.SYMBOL_SCATTER_2 then
                        curPos = util_convertToNodeSpace(symbolNode, self.m_lockSymbolNode)
                        local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, colIndex)
                        symbolNode:changeParentToOtherNode(self.m_lockSymbolNode,LOCK_SYMBOL_ZORDER + posIndex)
                        self.m_scatterWildSymbols[tostring(posIndex)] = symbolNode
                    else
                        self:changeSymbolToClipParent(symbolNode)
                    end
                    
                    -- util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                    -- symbolNode:setPositionY(curPos.y)

                    --回弹
                    local actList = {}
                    local moveTime = self.m_configData.p_reelResTime
                    local dis = self.m_configData.p_reelResDis
                    local pos = cc.p(curPos)
                    local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                    local action2 = cc.MoveTo:create(moveTime / 2,pos)
                    actList = {action1,action2}
                    symbolNode:runAction(cc.Sequence:create(actList))
                end

                if self:checkSymbolBulingAnimPlay(symbolNode) then
                    --2.播落地动画
                    symbolNode:runAnim(
                        symbolCfg[2],
                        false,
                        function()
                            self:symbolBulingEndCallBack(symbolNode)
                        end
                    )

                    --bonus落地音效
                    if self:isFixSymbol(symbolNode.p_symbolType) then
                        self:checkPlayBonusDownSound(colIndex)
                    end
                    --scatter落地音效
                    if self:isScatterSymbol(symbolNode.p_symbolType) then
                        self:checkPlayScatterDownSound(colIndex,symbolNode.p_symbolType)
                
                    end
                end
            end
            
        end
    end
end

--[[
    播放bonus落地音效
]]
function CodeGameScreenChameleonRichesMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_bonus_down)
end

--[[
    检测播放scatter落地音效
]]
function CodeGameScreenChameleonRichesMachine:checkPlayScatterDownSound(colIndex,symbolType)
    if not self.m_scatter_down[colIndex] then
        --播放bonus
        self:playScatterDownSound(colIndex,symbolType)
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_scatter_down[iCol] = true
        end
    else
        self.m_scatter_down[colIndex] = true
    end
end


--[[
    播放scatter落地音效
]]
function CodeGameScreenChameleonRichesMachine:playScatterDownSound(colIndex,symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_scatter_down_1)
    elseif symbolType == self.SYMBOL_SCATTER_1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_scatter_down_2)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_scatter_down_3)
    end
    
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenChameleonRichesMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if self:isScatterSymbol(_slotNode.p_symbolType) then
                return true
            elseif self:isFixSymbol(_slotNode.p_symbolType) then
                return true
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end


function CodeGameScreenChameleonRichesMachine:setReelRunInfo()
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    local longRunConfigs = {}
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["anyNumAnyWhere"] ,["symbolType"] = {90,95,96}} )
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {200},["musRunInfos"] = {["startCol"] = 1,["endCol"]=3}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态

    if self.b_gameTipFlag then
        return
    end
    for col=1,self.m_iReelColumnNum do
        local reelRunData = self.m_reelRunInfo[col]
        local runLen = reelRunData:getReelRunLen()

        local reelNode = self.m_baseReelNodes[col]
        reelNode:setRunLen(runLen)
    end
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenChameleonRichesMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenChameleonRichesMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenChameleonRichesMachine:isPlayExpect(reelCol)
    if reelCol <= self.m_iReelColumnNum then
        local bHaveLongRun = false
        for i = 1, reelCol do
            local reelRunData = self.m_reelRunInfo[i]
            if reelRunData:getNextReelLongRun() == true then
                bHaveLongRun = true
                break
            end
        end
        if bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() then
            return true
        end
    end
    return false    
end

function CodeGameScreenChameleonRichesMachine:getFeatureGameTipChance()
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 then
        -- 出现预告动画概率默认为40%
        local isNotice = (math.random(1, 100) <= 40) 
        return true
    end

    
    return false
end


--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenChameleonRichesMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance() then

        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
        
    else
        if type(_func) == "function" then
            _func()
        end
    end    
end

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenChameleonRichesMachine:playFeatureNoticeAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_notice_win)
    --动效执行时间
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("Node_yugao")
    

    self.b_gameTipFlag = true
    --创建对应格式的spine
    local spineAni = util_spineCreate("ChameleonRiches_guochang",true,true)
    if parentNode and not tolua.isnull(spineAni) then
        parentNode:addChild(spineAni)
        util_spinePlay(spineAni,"actionframe_yugao")
        util_spineEndCallFunc(spineAni,"actionframe_yugao",function()
            spineAni:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            self:delayCallBack(0.1,function()
                spineAni:removeFromParent()
            end)
            
        end)
    end
    
    aniTime = spineAni:getAnimationDurationTime("actionframe_yugao")

    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    --预告中奖时间比滚动时间短,直接返回即可
    if aniTime <= delayTime then
        if type(func) == "function" then
            func()
        end
    else
        self:delayCallBack(aniTime - delayTime,function()
            if type(func) == "function" then
                func()
            end
        end)
    end
end

function CodeGameScreenChameleonRichesMachine:scaleMainLayer()
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
    if ratio > 768 / 920 then  --920以下
        mainScale = 0.80
    elseif ratio <= 768 / 920 and ratio > 768 / 1152 then --920
        mainScale = 0.80
    elseif ratio <= 768 / 1152 and ratio > 768 / 1228 then --1152
        mainScale = 0.96
        mainPosY  = mainPosY - 10
    elseif ratio <= 768 / 1228 and ratio > 768 / 1370 then --1228
        mainScale = 0.99
        mainPosY  = mainPosY - 10
    else --1370以上
        mainScale = 0.98
        mainPosY  = mainPosY - 10
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

return CodeGameScreenChameleonRichesMachine






