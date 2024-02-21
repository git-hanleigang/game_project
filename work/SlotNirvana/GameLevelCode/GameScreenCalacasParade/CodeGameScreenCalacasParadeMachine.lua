--[[
    玩法:
        base:
            bonus连线:
                触发: 前四列出任意数量bonus1 第五列出特殊bonus2
                表现: 依次收集结算
            花车玩法:
                触发: 前四列出任意数量bonus2 第五列出任意特殊bonus
                表现: 可断线
            烟花玩法:
                触发: 前四列任意出普通bonus 第五列出特殊bonus1
                表现: 3选1直到出局 可断线
        free:
            触发: 3sc
            表现: 给1次免费且必出特殊玩法(花车/烟花)的spin

]]
local PublicConfig = require "CalacasParadePublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCalacasParadeMachine = class("CodeGameScreenCalacasParadeMachine", BaseNewReelMachine)

-- fireworks
CodeGameScreenCalacasParadeMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCalacasParadeMachine.SYMBOL_L6            = 9

CodeGameScreenCalacasParadeMachine.SYMBOL_BonusCoins    = 93  --bonus-金币
CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket   = 94  --bonus-车票-服务器
CodeGameScreenCalacasParadeMachine.SYMBOL_SpecialBonus1 = 95  --bonus-特殊1
CodeGameScreenCalacasParadeMachine.SYMBOL_SpecialBonus2 = 96  --bonus-特殊2

CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket_1   = 101  --bonus-车票-本地图标-绿
CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket_2   = 102  --bonus-车票-本地图标-蓝
CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket_3   = 103  --bonus-车票-本地图标-紫
CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket_4   = 104  --bonus-车票-本地图标-红

CodeGameScreenCalacasParadeMachine.SYMBOL_H1_Dark   = 200  --H1-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_H2_Dark   = 201  --H2-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_H3_Dark   = 202  --H3-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_H4_Dark   = 203  --H4-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_L1_Dark   = 204  --L1-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_L2_Dark   = 205  --L2-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_L3_Dark   = 206  --L3-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_L4_Dark   = 207  --L4-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_L5_Dark   = 208  --L5-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_L6_Dark   = 209  --L6-压暗
CodeGameScreenCalacasParadeMachine.SYMBOL_Wild_Dark = 292  --Wild-压暗


CodeGameScreenCalacasParadeMachine.EFFECT_BonusLine  = GameEffect.EFFECT_SELF_EFFECT - 50   --bonus收集(连线前)
CodeGameScreenCalacasParadeMachine.EFFECT_Car        = GameEffect.EFFECT_BONUS + 1          --花车玩法(连线后)
CodeGameScreenCalacasParadeMachine.EFFECT_Fireworks  = GameEffect.EFFECT_BONUS + 2          --烟花玩法(连线后)

--彩金配置
CodeGameScreenCalacasParadeMachine.ServerJackpotType = {
    Grand  = "Grand",
    Major  = "Major",
    Minor  = "Minor",
    Mini   = "Mini",
}
CodeGameScreenCalacasParadeMachine.JackpotTypeToIndex = {
    [CodeGameScreenCalacasParadeMachine.ServerJackpotType.Grand] = 1,
    [CodeGameScreenCalacasParadeMachine.ServerJackpotType.Major] = 2,
    [CodeGameScreenCalacasParadeMachine.ServerJackpotType.Minor] = 3,
    [CodeGameScreenCalacasParadeMachine.ServerJackpotType.Mini]  = 4,
}
CodeGameScreenCalacasParadeMachine.JackpotIndexToType = {
    CodeGameScreenCalacasParadeMachine.ServerJackpotType.Grand,
    CodeGameScreenCalacasParadeMachine.ServerJackpotType.Major,
    CodeGameScreenCalacasParadeMachine.ServerJackpotType.Minor,
    CodeGameScreenCalacasParadeMachine.ServerJackpotType.Mini,
}

-- 构造函数
function CodeGameScreenCalacasParadeMachine:ctor()
    CodeGameScreenCalacasParadeMachine.super.ctor(self)

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true

    self.m_spinAddBottomCoins = 0
    self.m_scatterBulingCount = 0

    --init
    self:initGame()
end

function CodeGameScreenCalacasParadeMachine:initGame()
    local csvPath = "CalacasParadeConfig.csv"
    local luaPath = "LevelCalacasParadeCSVData.lua"
    self.m_configData = gLobalResManager:getCSVLevelConfigData(csvPath, luaPath)
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCalacasParadeMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CalacasParade"  
end

function CodeGameScreenCalacasParadeMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --效果层-低
    self.m_effectNodeDown = cc.Node:create()
    self:addChild(self.m_effectNodeDown, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_effectNodeDown:setScale(self.m_machineRootScale)
    --效果层-高
    self.m_effectNodeUp = cc.Node:create()
    self:addChild(self.m_effectNodeUp, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNodeUp:setScale(self.m_machineRootScale)
    
    --彩金栏
    self.m_jackpotBar = util_createView("CalacasParadeSrc.CalacasParadeJackPotBar", self)
    self:findChild("Node_jackpotbar"):addChild(self.m_jackpotBar)

    -- 棋盘上提示
    self.m_reelTips = util_createView("CalacasParadeSrc.CalacasParadeReelTips", self)
    self:findChild("Node_des"):addChild(self.m_reelTips)

    -- 关卡转场
    self.m_transferAnim = util_createView("CalacasParadeSrc.CalacasParadeTransfer", self)
    self:findChild("Node_guochang"):addChild(self.m_transferAnim)

    -- 预告中奖
    self.m_yugaoAnim = util_createView("CalacasParadeSrc.CalacasParadeYuGao", self)

    -- 图标期待
    self.m_symbolExpectCtr = util_createView("CalacasParadeSrc.CalacasParadeExpect", self)

    -- 快滚效果
    self.m_reelRunAnim = util_createView("CalacasParadeSrc.CalacasParadeReelRunEffect", self)

    -- 底栏反馈
    self:changeCoinWinEffectUI(self:getModuleName(), "CalacasParade_totalwin.csb")
    
    -- 遮罩
    self.m_maskCtr = util_createView("CalacasParadeSrc.CalacasParadeMask", self)

    --底栏大赢文本适配
    if self.m_bottomUI.m_bigWinLabInfo then
        self.m_bottomUI.m_bigWinLabInfo.width = 600
        self.m_bottomUI:setBigWinLabInfo(self.m_bottomUI.m_bigWinLabInfo)
    end
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenCalacasParadeMachine:initSpineUI()
    --关卡背景-base
    self.m_spineBg = util_spineCreate("GameScreenCalacasParadeBg",true,true)
    self.m_gameBg:findChild("base"):addChild(self.m_spineBg)
    --关卡背景-free-高层
    self.m_freeSpineBg = util_spineCreate("GameScreenCalacasParadeBg",true,true)
    self.m_gameBg:findChild("free"):addChild(self.m_freeSpineBg)
    self.m_freeSpineBg:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_gameBg, true)

    -- 关卡角色
    self.m_roleAnim = util_createView("CalacasParadeSrc.CalacasParadeRole", self) 
    self:findChild("Node_base_hc"):addChild(self.m_roleAnim)

    self:changeReelBg("base")
end


function CodeGameScreenCalacasParadeMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.sound_CalacasParade_EnterLevel)
    end)
end

function CodeGameScreenCalacasParadeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCalacasParadeMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    if self:isTriggerReconnectEffect() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        --刷新车票金币
        if self:isTriggerEFFECT_Fireworks() and not self:isTriggerEFFECT_Car() then
            self:reconnectUpDateTicketReward()
        end
    end
    self.m_roleAnim:playBaseLoopIdle(self.m_roleAnim.m_curIndex)
end

function CodeGameScreenCalacasParadeMachine:addObservers()
    CodeGameScreenCalacasParadeMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then return end

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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig[string.format("sound_CalacasParade_BaseLineFrame_%d", soundIndex)]
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig[string.format("sound_CalacasParade_freeLineFrame_%d", soundIndex)]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenCalacasParadeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCalacasParadeMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCalacasParadeMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_L6 then
        return "Socre_CalacasParade_10"
    end
    
    if symbolType == self.SYMBOL_H1_Dark then
        return "Socre_CalacasParade_9_2"
    end
    if symbolType == self.SYMBOL_H2_Dark then
        return "Socre_CalacasParade_8_2"
    end
    if symbolType == self.SYMBOL_H3_Dark then
        return "Socre_CalacasParade_7_2"
    end
    if symbolType == self.SYMBOL_H4_Dark then
        return "Socre_CalacasParade_6_2"
    end
    if symbolType == self.SYMBOL_L1_Dark then
        return "Socre_CalacasParade_5_2"
    end
    if symbolType == self.SYMBOL_L2_Dark then
        return "Socre_CalacasParade_4_2"
    end
    if symbolType == self.SYMBOL_L3_Dark then
        return "Socre_CalacasParade_3_2"
    end
    if symbolType == self.SYMBOL_L4_Dark then
        return "Socre_CalacasParade_2_2"
    end
    if symbolType == self.SYMBOL_L5_Dark then
        return "Socre_CalacasParade_1_2"
    end
    if symbolType == self.SYMBOL_L6_Dark then
        return "Socre_CalacasParade_10_2"
    end
    if symbolType == self.SYMBOL_Wild_Dark then
        return "Socre_CalacasParade_WILD_2"
    end
    
    

    if symbolType == self.SYMBOL_BonusCoins then
        return "Socre_CalacasParade_Bouns1"
    end
    if symbolType == self.SYMBOL_BonusTicket then
        return "Socre_CalacasParade_Blank"
    end
    if symbolType == self.SYMBOL_BonusTicket_1 then
        return "Socre_CalacasParade_Bouns5"
    end
    if symbolType == self.SYMBOL_BonusTicket_2 then
        return "Socre_CalacasParade_Bouns4"
    end
    if symbolType == self.SYMBOL_BonusTicket_3 then
        return "Socre_CalacasParade_Bouns3"
    end
    if symbolType == self.SYMBOL_BonusTicket_4 then
        return "Socre_CalacasParade_Bouns2"
    end
    if symbolType == self.SYMBOL_SpecialBonus1 then
        return "Socre_CalacasParade_Bouns6"
    end
    if symbolType == self.SYMBOL_SpecialBonus2 then
        return "Socre_CalacasParade_Bouns7"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCalacasParadeMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCalacasParadeMachine.super.getPreLoadSlotNodes(self)
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_L6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SpecialBonus1,count =  1}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SpecialBonus2,count =  1}
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCalacasParadeMachine:initGameStatusData(gameData)
    if gameData.gameConfig and gameData.gameConfig.extra then
        local extra = gameData.gameConfig.extra
        if nil ~= extra then
        end
    end
    -- 替换断线玩法的数据
    if gameData.spin then
        self:changeCalacasParadeReels_ticket(gameData.spin)
        if gameData.spin.selfData and (gameData.feature and gameData.feature.selfData) then
            --花车
            if gameData.feature.selfData.isCar then
                gameData.spin.selfData.isCar = true
                gameData.spin.selfData.carExtra = gameData.feature.selfData.carExtra
            else
                gameData.spin.selfData.isCar = false
            end
            --花车-车票金币
            if gameData.feature.selfData.tocketCoinsData then
                gameData.spin.selfData.tocketCoinsData = gameData.feature.selfData.tocketCoinsData
            end

            --烟花
            if gameData.feature.selfData.isFirework then
                gameData.spin.selfData.isFirework = true
                gameData.spin.selfData.fireworkExtra = gameData.feature.selfData.fireworkExtra
            else
                gameData.spin.selfData.isFirework = false
            end
        end
    end
    CodeGameScreenCalacasParadeMachine.super.initGameStatusData(self, gameData)
end
function CodeGameScreenCalacasParadeMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin then
    end
    if self:isTriggerEFFECT_Car() then
        self:addOneSelfEffect(self.EFFECT_Car)
    elseif self:isTriggerEFFECT_Fireworks() then
        self:addOneSelfEffect(self.EFFECT_Fireworks)
    end
end
--断线-检测是否执行事件
function CodeGameScreenCalacasParadeMachine:checkInitSpinWithEnterLevel()
    local isTriggerEffect,isPlayGameEffect = CodeGameScreenCalacasParadeMachine.super.checkInitSpinWithEnterLevel(self)
    if not isPlayGameEffect then
        if self:isTriggerReconnectEffect() then
            isPlayGameEffect = true
        end
    end
    return isTriggerEffect,isPlayGameEffect
end
--断线-检测是否恢复棋盘
function CodeGameScreenCalacasParadeMachine:checkHasFeature()
    local hasFeature = CodeGameScreenCalacasParadeMachine.super.checkHasFeature(self)
    if not hasFeature then
        if self:isTriggerReconnectEffect() then
            hasFeature = true
        end
    end
    return hasFeature
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCalacasParadeMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()

    self.m_spinAddBottomCoins = 0
    self.m_scatterBulingCount = 0
    self.m_symbolExpectCtr:MachineSpinBtnCall()
    self:spinRemoveSpecialBonusBulingAnim()
    
    return false -- 用作延时点击spin调用
end

-- 不用系统音效
function CodeGameScreenCalacasParadeMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
--单列滚动停止回调
function CodeGameScreenCalacasParadeMachine:slotOneReelDown(reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
    self.m_reelRunAnim:stopReelRunAnim()
    if reelCol == self.m_iReelColumnNum then
        if not self:isTriggerEFFECT_BonusLine() then
            self:reelDownUpDateBaseDarkSymbol(function()end)
        end
    end
    CodeGameScreenCalacasParadeMachine.super.slotOneReelDown(self,reelCol)
end
--重写-快滚效果
function CodeGameScreenCalacasParadeMachine:creatReelRunAnimation(_iCol)
    local bSpecial = true
    if bSpecial then
        local bBonus = self:isTriggerBonusReelRun()
        self.m_reelRunAnim:playReelRunAnim(_iCol, bBonus)
    else
        CodeGameScreenCalacasParadeMachine.super.creatReelRunAnimation(self, _iCol)
    end
end
--滚轮停止
function CodeGameScreenCalacasParadeMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    -- self:reelDownUpDateBaseDarkSymbol(function()
        CodeGameScreenCalacasParadeMachine.super.slotReelDown(self)
    -- end)
end
--重写-bonus玩法不停止背景
function CodeGameScreenCalacasParadeMachine:checktriggerSpecialGame()
    local bTrigger = CodeGameScreenCalacasParadeMachine.super.checktriggerSpecialGame(self)
    if not bTrigger then
        if self:isTriggerReconnectEffect() then
            bTrigger = true
        end
    end
    return bTrigger
end

--重写-落地动画-检测播放
function CodeGameScreenCalacasParadeMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    CodeGameScreenCalacasParadeMachine.super.playSymbolBulingAnim(self, slotNodeList, speedActionTable)
    for k, _symbol in pairs(slotNodeList) do
        if self:checkSymbolBulingAnimPlay(_symbol) then
            self:playCalacasParadeSpecialBonusBulingAnim(_symbol)
        end
        
    end
end
function CodeGameScreenCalacasParadeMachine:playCalacasParadeSpecialBonusBulingAnim(_symbol)
    local bBonus2 = self:isCalacasParadeBonus2(_symbol.p_symbolType)
    local bSpecialBonus1 = 1 == self:getCalacasParadeSpecialBonusIndex(_symbol.p_symbolType)
    local bSpecialBonus2 = 2 == self:getCalacasParadeSpecialBonusIndex(_symbol.p_symbolType)
    if not bBonus2 and not bSpecialBonus1 and not bSpecialBonus2 then
        return
    end
    local bulingName = "buling"
    if bSpecialBonus2 then
        bulingName = "buling2"
    elseif bBonus2 then
        bulingName = "buling3"
    end
    local parent  = self:findChild("Node_Bonus7Buling")
    local posNode = self:findChild( string.format("sp_reel_%d", _symbol.p_cloumnIndex-1) ) 
    local csb = util_createAnimation("Socre_CalacasParade_Bouns6_bg.csb")
    parent:addChild(csb)
    csb:setPosition( util_convertToNodeSpace(posNode, parent) )
    local spineParent = csb:findChild("Node_spine")
    --底板
    -- local spineBg = util_spineCreate("Socre_CalacasParade_Bouns6_2", true, true)
    -- spineParent:addChild(spineBg, 10)
    -- util_spinePlay(spineBg, "idle", false)
    -- --扩散
    local spine = util_spineCreate("Socre_CalacasParade_Bouns6_2", true, true)
    spineParent:addChild(spine, 100)
    spine:setPosition( util_convertToNodeSpace(_symbol, spineParent) )
    util_spinePlay(spine, bulingName, false)
end
--落地效果消失
function CodeGameScreenCalacasParadeMachine:spinRemoveSpecialBonusBulingAnim()
    local parent = self:findChild("Node_Bonus7Buling")
    parent:removeAllChildren()
end

--重写-落地音效-播放
function CodeGameScreenCalacasParadeMachine:playSymbolBulingSound(slotNodeList)
    CodeGameScreenCalacasParadeMachine.super.playSymbolBulingSound(self, slotNodeList)
    for k, _slotNode in pairs(slotNodeList) do
        if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and self:checkSymbolBulingSoundPlay(_slotNode) then
            if self:getGameSpinStage() == QUICK_RUN then
                self.m_scatterBulingCount = self:getSymbolCountByCol(_slotNode.p_symbolType, self.m_iReelColumnNum)
                if 2 == self.m_scatterBulingCount then
                    self.m_scatterBulingCount = 1
                end
            else
                self.m_scatterBulingCount = math.min(3, self.m_scatterBulingCount+1)
            end
            local soundPath = PublicConfig[string.format("sound_CalacasParade_Scatter_buling_%d", self.m_scatterBulingCount)]
            if soundPath then
                local iCol = _slotNode.p_cloumnIndex
                self:playBulingSymbolSounds(iCol, soundPath, nil)
            end
        end
    end
end
--重写-落地动画-落地回调
function CodeGameScreenCalacasParadeMachine:symbolBulingEndCallBack(_symbol)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_symbol)
end

---------------------------------------------------------------------------

--------------------添加动画
-- 添加关卡中触发的玩法
function CodeGameScreenCalacasParadeMachine:addOneSelfEffect(_sEType)
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = _sEType
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = _sEType 
end
function CodeGameScreenCalacasParadeMachine:addSelfEffect()
    if self:isTriggerEFFECT_BonusLine() then
        self:addOneSelfEffect(self.EFFECT_BonusLine)
    end
    if self:isTriggerEFFECT_Car() then
        self:addOneSelfEffect(self.EFFECT_Car)
    elseif self:isTriggerEFFECT_Fireworks() then
        self:addOneSelfEffect(self.EFFECT_Fireworks)
    end
end
--播放玩法动画
function CodeGameScreenCalacasParadeMachine:MachineRule_playSelfEffect(effectData)
    -- self.m_roleAnim:stopNextBaseLoopIdle()
    if effectData.p_selfEffectType == self.EFFECT_BonusLine then
        self:levelPerformWithDelay(self, 0.5, function()
            self:playEFFECT_BonusLine(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_Car then
        self:levelPerformWithDelay(self, 0.5, function()
            self:playEFFECT_Car(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_Fireworks then
        self:levelPerformWithDelay(self, 0.5, function()
            self:playEFFECT_Fireworks(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end
    return true
end
function CodeGameScreenCalacasParadeMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenCalacasParadeMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    -- self.m_roleAnim:restoreNextBaseLoopIdle()
end

--bonus连线
function CodeGameScreenCalacasParadeMachine:isTriggerEFFECT_BonusLine()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    return selfData.isBonus1
end
--bonus连线-获取总赢钱
function CodeGameScreenCalacasParadeMachine:getBonusLineWinCoins()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus1WinCoins = selfData.bonus1Pay or 0
    return bonus1WinCoins
end

function CodeGameScreenCalacasParadeMachine:playEFFECT_BonusLine(_fun)
    local bonus1WinCoins = self:getBonusLineWinCoins()
    self:playBonusLineTrigger(function()
        local symbolList = self:getReelSymbolList({}, self.SYMBOL_BonusCoins, true)
        self:playBonusLineByList(1, symbolList, function()
            self:addBonusOverBigWinEffect(bonus1WinCoins, self.EFFECT_BonusLine)
            self:reelDownUpDateBaseDarkSymbol(function()
                _fun()
            end)
        end)
    end)
end
--bonus连线-图标触发
function CodeGameScreenCalacasParadeMachine:playBonusLineTrigger(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_Bonus_prepareCollect)
    local symbolList = self:getReelSymbolList({}, self.SYMBOL_BonusCoins, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_SpecialBonus2, true)
    for i,v in ipairs(symbolList) do
        local symbol = symbolList[i]
        symbol:runAnim("actionframe", false, function()
            self.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
        end)
    end
    self:levelPerformWithDelay(self, 60/30+0.5, _fun)
end
--bonus连线-依次收集
function CodeGameScreenCalacasParadeMachine:playBonusLineByList(_index, _list, _fun)
    local symbol = _list[_index]
    if not symbol then
        return _fun()
    end

    local animNode = symbol:getCCBNode()
    local bindCsb  = animNode.m_bindCsb
    local bLast = not _list[_index+1]
    local shoujiName = "shouji2"
    symbol:runAnim(shoujiName, false, function()
        symbol:runAnim("darkidle", false)
        bindCsb:runCsbAction("darkidle", false)
    end)
    --时间线第5帧时数字飞出 0-15帧
    self:levelPerformWithDelay(self, 6/30, function()
        --临时效果
        local parent   = self.m_effectNodeUp
        local csb = self:createSpineSymbolBindCsb(self.SYMBOL_BonusCoins)
        parent:addChild(csb)
        csb:setPosition(util_convertToNodeSpace(bindCsb, parent))
        csb:setScale(bindCsb:getScale())
        local reelPos = self:getPosReelIdx(symbol.p_rowIndex, symbol.p_cloumnIndex)
        local bonusData = self:getReelBonusRewardData(reelPos)
        self:upDateBonusBindCsb(csb, bonusData)
        --动作
        local actList = {}
        local flyTime = 30/60
        local endPos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), parent)
        table.insert(actList, cc.EaseIn:create(cc.MoveTo:create(flyTime, endPos), 2))
        table.insert(actList, cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_Bonus_collectFeedback)
            self:playBottomWinCoinsSpine()
            self:updateBottomUICoins(bonusData[2], false, true, false)
            if bLast then
                local lastDelay = self.m_bottomUI:getCoinsShowTimes( bonusData[2] )
                self:levelPerformWithDelay(self,lastDelay, function()
                    self:playBonusLineByList(_index+1, _list, _fun)
                end)
            end
        end))
        table.insert(actList, cc.RemoveSelf:create())
        csb:runCsbAction("shouji", false)
        csb:runAction(cc.Sequence:create(actList))
        --时间线开始 9/30帧时 开始下一个飞行
        if not bLast then
            self:levelPerformWithDelay(self, 3/30+0.2, function()
                self:playBonusLineByList(_index+1, _list, _fun)
            end)
        end
    end)
end

--是否触发断线玩法(花车 烟花)
function CodeGameScreenCalacasParadeMachine:isTriggerReconnectEffect()
    return self:isTriggerEFFECT_Car() or self:isTriggerEFFECT_Fireworks()
end

--花车玩法
function CodeGameScreenCalacasParadeMachine:isTriggerEFFECT_Car()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.isCar and selfData.carExtra and selfData.carExtra.currentTicket < selfData.carExtra.TotalTicket then
        return true
    end
    return false
end
function CodeGameScreenCalacasParadeMachine:playEFFECT_Car(_fun)
    self:playParadeTriggerAnim(function()
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_gc)
        self.m_transferAnim:playParadeTransferAnim(
            function()
                --清空底栏
                if not self.m_bProduceSlots_InFreeSpin then
                    self.m_bottomUI:resetWinLabel()
                    self.m_bottomUI:checkClearWinLabel()
                    self.m_spinAddBottomCoins = 0
                end
                self:changeReelBg("bonus")
                self:findChild("Node_reel"):setVisible(false)
                self.m_roleAnim:setVisible(false)
                self:createCarGameView(_fun)
            end,
            function()
                --切换背景音乐
                self:resetMusicBg(true, PublicConfig.music_CalacasParade_parade)
                self:levelPerformWithDelay(self, 0.5, function()
                    self:showCarGameStartView(function()
                        self.m_carGameView:startGame()
                    end)
                end)
            end
        )
    end)
end
--花车玩法-图标触发
function CodeGameScreenCalacasParadeMachine:playParadeTriggerAnim(_fun)
    self:clearWinLineEffect()
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_trigger)
    local symbolList = self:getReelSymbolList({}, self.SYMBOL_BonusTicket_1, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_2, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_3, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_4, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_SpecialBonus1, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_SpecialBonus2, true)
    for i,v in ipairs(symbolList) do
        local symbol =  symbolList[i]
        local order = self:getBounsScatterDataZorder(symbol.p_symbolType) + symbol.p_cloumnIndex*10 - symbol.p_rowIndex
        self:changeSymbolReelOrder(symbol, true, order*2)
        symbol:runAnim("actionframe", false, function()
            self:changeSymbolReelOrder(symbol, true, order)
            self.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
        end)
        self:playSpecialBonus1Actionframe(symbol)
    end
    self:levelPerformWithDelay(self, 60/30, _fun)
end
--花车玩法-开始弹板
function CodeGameScreenCalacasParadeMachine:showCarGameStartView(_fun)
    local view = self:createFeatureStartDialog("FireworkFeatureStart", _fun)
    view:findChild("title_car"):setVisible(true)
end
--花车玩法-玩法界面
function CodeGameScreenCalacasParadeMachine:createCarGameView(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local ticketList = {}
    for i,_bonus2Index in ipairs(selfData.carExtra.carList) do
        ticketList[_bonus2Index] = ticketList[_bonus2Index] and ticketList[_bonus2Index]+1 or 1
    end
    local viewData = {}
    viewData.machine    = self
    viewData.carExtra   = selfData.carExtra
    viewData.ticketList = ticketList
    viewData.fnOver = function(_coins)
        self:playCarGameOver(_coins, _fun)
    end
    self.m_carGameView = util_createView("CalacasParadeSrc.CalacasParadeCarGameView", viewData)
    self:findChild("Node_hc"):addChild(self.m_carGameView)
end
--彩金弹板
function CodeGameScreenCalacasParadeMachine:showJackpotView(_jpIndex, _jpCoins, _fun)
    gLobalSoundManager:playSound(PublicConfig[string.format("sound_CalacasParade_JackpotView_%d", _jpIndex)])
    local viewData = {}
    viewData.machine   = self
    viewData.index     = _jpIndex
    viewData.coins     = _jpCoins
    if 1 == _jpIndex then
        viewData.csbName   =  "CalacasParade/JackpotWinView_grand.csb"
    else
        viewData.csbName   =  "CalacasParade/JackpotWinView.csb"
    end
    local view = util_createView("CalacasParadeSrc.CalacasParadeJackPotView", viewData)
    view:setOverAniRunFunc(function()
        _fun()
    end)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end
--花车玩法-结算界面
function CodeGameScreenCalacasParadeMachine:playCarGameOver(_coins, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGame_overGc)
    self.m_transferAnim:playParadeTransferAnim(
        function()
            --切换spin模式的: 背景 音乐
            local bgModel = "base"
            local bgMusic = PublicConfig.music_CalacasParade_base
            if self.m_bProduceSlots_InFreeSpin then
                bgModel = "free"
                bgMusic = PublicConfig.music_CalacasParade_free
            end
            self:changeReelBg(bgModel)
            self:resetMusicBg(true, bgMusic)

            self:findChild("Node_reel"):setVisible(true)
            self.m_roleAnim:setVisible(true)

            self:findChild("Node_hc"):removeAllChildren()
        end,
        function()
            self:levelPerformWithDelay(self, 1, function()
                self:playTicketSymbolCoinsStart(_coins, _fun)
            end)
        end
    )
end
--花车玩法-车票图标-金币出现
function CodeGameScreenCalacasParadeMachine:playTicketSymbolCoinsStart(_coins, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_Bonus2_coinsStart)
    --车票刷新金额
    local symbolList = self:getReelSymbolList({}, self.SYMBOL_BonusCoins, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_1, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_2, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_3, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_4, true)
    local startAnimName = "start"
    local startTime = 0
    local parent = self.m_effectNodeUp
    -- { {位置, 图标, 额外csb}, }
    local collectList = {}
    for i,_symbol in ipairs(symbolList) do
        local reelPos = self:getPosReelIdx(_symbol.p_rowIndex, _symbol.p_cloumnIndex)
        collectList[i] = {reelPos, _symbol}
        if self:isCalacasParadeBonus2(_symbol.p_symbolType) then
            local coins = self:getBonus2Coins(reelPos)
            local animNode = _symbol:getCCBNode()
            local bindCsb  = animNode.m_bindCsb
            self:upDateTicketReward(_symbol, coins)
            bindCsb:runCsbAction(startAnimName, false)
            startTime = util_csbGetAnimTimes(bindCsb.m_csbAct, startAnimName)
        end
    end
    self:levelPerformWithDelay(self, startTime, function()
        --区分后面是否还有烟花玩法
        local bFireworks = self:isTriggerEFFECT_Fireworks()
        if not bFireworks then
            --直接收集结算
            self:playTicketSymbolCollectTrigger(symbolList, function()
                self:playTicketSymbolCoinsCollect(1, collectList, function()
                    local bonus1Coins = self:getBonusLineWinCoins()
                    self:addBonusOverBigWinEffect(_coins+bonus1Coins, self.EFFECT_Car)
                    _fun()
                end)
            end)
        else
            self:addOneSelfEffect(self.EFFECT_Fireworks)
            --不收集
            _fun()
        end
    end)
end
--花车玩法-车票图标-收集前触发
function CodeGameScreenCalacasParadeMachine:playTicketSymbolCollectTrigger(_symbolList, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_Bonus_prepareCollect)
    for i,v in ipairs(_symbolList) do
        local symbol   = _symbolList[i]
        local idleName =  self.SYMBOL_BonusCoins == symbol.p_symbolType and "idleframe2" or "idleframe4"
        symbol:runAnim("actionframe", false, function()
            symbol:runAnim(idleName, true)
        end)
    end
    self:levelPerformWithDelay(self, 60/30+0.5, _fun)
end
--花车玩法-车票图标-金币收集
function CodeGameScreenCalacasParadeMachine:playTicketSymbolCoinsCollect(_index, _list, _fun)
    local data = _list[_index]
    if not data then
        return _fun()
    end

    local bLast = not _list[_index+1]
    local reelPos  = data[1]
    local symbol   = data[2]
    local bBonus1  = self:isCalacasParadeBonus1(symbol.p_symbolType)
    local coins = 0
    --临时csb
    local parent = self.m_effectNodeUp
    local flyCsb = self:createSpineSymbolBindCsb(symbol.p_symbolType)
    parent:addChild(flyCsb)
    flyCsb:setVisible(false)
    local animNode = symbol:getCCBNode()
    local bindCsb  = animNode.m_bindCsb
    flyCsb:setPosition(util_convertToNodeSpace(bindCsb, parent))
    flyCsb:setScale(bindCsb:getScale())
    if bBonus1 then
        local bonusData = self:getReelBonusRewardData(reelPos)
        self:upDateBonusBindCsb(flyCsb, bonusData)
        coins = bonusData[2]
    else
        coins = self:getBonus2Coins(reelPos)
        self:upDateTicketBindCsb(flyCsb, coins)
    end

    local shoujiName = bBonus1 and "shouji2" or "shouji"
    local actList = {}
    local flyWaitTime = 6/30
    table.insert(actList, cc.DelayTime:create(flyWaitTime))
    table.insert(actList, cc.CallFunc:create(function()
        flyCsb:setVisible(true)
    end))
    local flyTime = 9/30
    local endPos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), parent)
    table.insert(actList, cc.EaseIn:create(cc.MoveTo:create(flyTime, endPos), 2))
    table.insert(actList, cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_Bonus_collectFeedback)
        self:playBottomWinCoinsSpine()
        self:updateBottomUICoins(coins, false, true, false)
        if bLast then
            self:levelPerformWithDelay(self, self.m_bottomUI:getCoinsShowTimes(coins), function()
                self:playTicketSymbolCoinsCollect(_index+1, _list, _fun)
            end)
        end
    end))
    table.insert(actList, cc.RemoveSelf:create())
    symbol:runAnim(shoujiName, false, function()
        symbol:runAnim("darkidle", false)
        bindCsb:runCsbAction("darkidle", false)
    end)
    flyCsb:runCsbAction("shouji", false)
    flyCsb:runAction(cc.Sequence:create(actList))
    --根据下一个收集是否存在 区分间隔 飞行后的3/30帧
    if not bLast then
        self:levelPerformWithDelay(self, flyWaitTime+3/30+0.2, function()
            self:playTicketSymbolCoinsCollect(_index+1, _list, _fun)
        end)
    end
end
--花车玩法-车票图标-断线重连时刷新车票的金币
function CodeGameScreenCalacasParadeMachine:reconnectUpDateTicketReward()
    self:baseReelForeach(function(_symbol, _iCol, _iRow)
        if self:isCalacasParadeBonus2(_symbol.p_symbolType) then
            local reelPos = self:getPosReelIdx(_symbol.p_rowIndex, _symbol.p_cloumnIndex)
            local coins   = self:getBonus2Coins(reelPos)
            self:upDateTicketReward(_symbol, coins)
        end
    end)
end

-- fireworks
function CodeGameScreenCalacasParadeMachine:isTriggerEFFECT_Fireworks()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.isFirework and selfData.fireworkExtra and not selfData.fireworkExtra.enfFlag then
        return true
    end
    return false
end
function CodeGameScreenCalacasParadeMachine:playEFFECT_Fireworks(_fun)
    self:playFireworksTriggerAnim(function()
        self.m_maskCtr:playLevelMaskStart(0, function()
            self:playFireworksCollect(function()
                self:showFireworkFeatureStart(function()
                    _fun()
                end)
            end)
        end)
    end)
end
--fireworks-图标触发
function CodeGameScreenCalacasParadeMachine:playFireworksTriggerAnim(_fun)
    self:clearWinLineEffect()
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_trigger)
    local symbolList = self:getReelSymbolList({}, self.SYMBOL_BonusCoins, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_1, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_2, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_3, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_BonusTicket_4, false)
    self:getReelSymbolList(symbolList, self.SYMBOL_SpecialBonus1, true)

    local parent = self:findChild("Node_yh_symbol")
    local fnPlayAnim = function(_symbol, _bReset)
        _symbol:runAnim("actionframe", false, function()
            if _bReset then
                local order = self:getBounsScatterDataZorder(_symbol.p_symbolType) + _symbol.p_cloumnIndex*10 - _symbol.p_rowIndex
                self:changeSymbolReelOrder(_symbol, true, order)
            end
            self.m_symbolExpectCtr:playSymbolIdleAnim(_symbol)
        end)
        self:playSpecialBonus1Actionframe(_symbol)
    end
    for i,symbol in ipairs(symbolList) do
        local order = self:getBounsScatterDataZorder(symbol.p_symbolType) + symbol.p_cloumnIndex*10 - symbol.p_rowIndex
        self:changeSymbolReelOrder(symbol, true, order*2)
        fnPlayAnim(symbol, true)
        local bBonus1 = self:isCalacasParadeBonus1(symbol.p_symbolType)
        local bBonus2 = self:isCalacasParadeBonus2(symbol.p_symbolType)
        local tempSymbol = util_createView("CalacasParadeSrc.CalacasParadeTempSymbol", {
            iCol=symbol.p_cloumnIndex, 
            iRow=symbol.p_rowIndex, 
            machine=self
        })
        parent:addChild(tempSymbol)
        tempSymbol:changeSymbolCcb(symbol.p_symbolType)
        tempSymbol:setPosition(util_convertToNodeSpace(symbol, parent))
        if bBonus1 or bBonus2 then
            self:addSpineSymbolCsbNode(tempSymbol)
            if bBonus1 then
                self:upDateReelBonusReward(tempSymbol)
            elseif bBonus2 then
                self:upDateReelTicketReward(tempSymbol, true)
            end
        end
        tempSymbol:setVisible(false)
        fnPlayAnim(tempSymbol)
    end
    self:levelPerformWithDelay(self, 60/30+0.5, function()
        local symbolList = parent:getChildren()
        for i,_symbol in ipairs(symbolList) do
            _symbol:setVisible(true)
        end
        _fun()
    end)
end
--fireworks-图标收集
function CodeGameScreenCalacasParadeMachine:playFireworksCollect(_fun)
    -- 收集弹板
    self.m_fireworksCollectView = util_createView("CalacasParadeSrc.CalacasParadeFireworksCollectView", self)
    self:findChild("Node_yh_tanban"):addChild(self.m_fireworksCollectView)
    self.m_fireworksCollectView:setVisible(false)

    self:levelPerformWithDelay(self, 0.5, function()
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksCollectView_start)
        self.m_fireworksCollectView:playStartAnim(function()
            local parent     = self:findChild("Node_yh_symbol")
            local symbolList = {}
            for i,_child in ipairs(parent:getChildren()) do
                local symbolType = _child.m_symbolType
                local bBonus1 = self:isCalacasParadeBonus1(symbolType)
                local bBonus2 = self:isCalacasParadeBonus2(symbolType)
                if bBonus1 or bBonus2 then
                    table.insert(symbolList, _child)
                end
            end
            self:playFireworksCollectByList(1, symbolList, function()
                self:levelPerformWithDelay(self, 1, _fun)
            end)
        end)
    end)
end
--fireworks-图标收集-递归
function CodeGameScreenCalacasParadeMachine:playFireworksCollectByList(_index, _list, _fun)
    local symbol = _list[_index]
    if not symbol then
        return _fun()
    end

    local bLast      = not _list[_index+1]
    local symbolType = symbol.m_symbolType
    local bBonus1 = self:isCalacasParadeBonus1(symbolType)
    local reelPos = self:getPosReelIdx(symbol.p_rowIndex, symbol.p_cloumnIndex)
    local coins = 0
    local parent   = self.m_effectNodeUp
    local flyCsb = self:createSpineSymbolBindCsb(symbolType)
    parent:addChild(flyCsb)
    flyCsb:setVisible(false)
    local animNode = symbol:getCCBNode()
    local bindCsb  = animNode.m_bindCsb
    flyCsb:setPosition(util_convertToNodeSpace(bindCsb, parent))
    flyCsb:setScale(bindCsb:getScale())
    if bBonus1 then
        local bonusData = self:getReelBonusRewardData(reelPos)
        coins = bonusData[2]
        self:upDateBonusBindCsb(flyCsb, bonusData)
    else
        coins = self:getBonus2Coins(reelPos)
        self:upDateTicketBindCsb(flyCsb, coins)
    end

    symbol:runAnim("shouji", false, function()
        self.m_symbolExpectCtr:playSymbolIdleAnim(symbol)
    end)
    --时间线第5帧时数字飞出 0-15帧
    self:levelPerformWithDelay(self, 6/30, function()
        flyCsb:setVisible(true)
        --动作
        local actList = {}
        local flyTime = 9/30
        local endPos = util_convertToNodeSpace(self.m_fireworksCollectView:getCollectEndNode(), parent)
        table.insert(actList, cc.EaseIn:create(cc.MoveTo:create(flyTime, endPos), 2))
        table.insert(actList, cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksCollectView_collectFeedback)
            self.m_fireworksCollectView:playCollectAnim(coins, function()
                if bLast then
                    self:playFireworksCollectByList(_index+1, _list, _fun)
                end
            end)
        end))
        table.insert(actList, cc.RemoveSelf:create())
        flyCsb:runCsbAction("shouji", false)
        flyCsb:runAction(cc.Sequence:create(actList))
        if not bLast then
            self:levelPerformWithDelay(self, 3/30+0.2, function()
                self:playFireworksCollectByList(_index+1, _list, _fun)
            end)
        end
    end)
end
--fireworks-图标收集
function CodeGameScreenCalacasParadeMachine:showFireworkFeatureStart(_fun)
    local fnViewOver = function()
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_gc)
        self.m_transferAnim:playFireworksTransferAnim(
            function()
                self:createFireworksGameView(_fun)
                --删除高层图标
                self:findChild("Node_yh_symbol"):removeAllChildren()
                self.m_maskCtr:playLevelMaskOver()
                --清空底栏
                if not self.m_bProduceSlots_InFreeSpin then
                    self.m_bottomUI:resetWinLabel()
                    self.m_bottomUI:checkClearWinLabel()
                    self.m_spinAddBottomCoins = 0
                end
            end,
            function()
                --切换背景音乐
                self:resetMusicBg(true, PublicConfig.music_CalacasParade_fireworks)
                self.m_fireworksGameView:startGame()
            end
        )
    end
    local view = self:createFeatureStartDialog("FireworkFeatureStart", fnViewOver)
    view:findChild("title_firework"):setVisible(true)
    -- 弹板挂点-收集栏
    util_changeNodeParent(view:findChild("Node_yh_tanban2"), self.m_fireworksCollectView)
    self.m_fireworksCollectView:playSwitchAnim()
end

function CodeGameScreenCalacasParadeMachine:createFeatureStartDialog(_csbName, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGameStartView_start)
    local view = self:showDialog(_csbName, nil, _fun, true)
    view:findChild("root"):setScale(self.m_machineRootScale)
    -- 弹板挂点-烟花
    local yanhuaSpine = util_spineCreate("CalacasParade_yanhua", true, true)
    view:findChild("Node_yanhua"):addChild(yanhuaSpine)
    util_spinePlay(yanhuaSpine, "tanban_idle1", true)
    --音效
    view.m_btnTouchSound = PublicConfig.sound_CalacasParade_CommonClick
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_CarGameStartView_over)
    end)
    return view
end

--fireworks-界面创建
function CodeGameScreenCalacasParadeMachine:createFireworksGameView(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local viewData = {}
    viewData.machine   = self
    viewData.fireworkExtra = selfData.fireworkExtra
    viewData.fnOver = function(_coins)
        self:showFireworksGameOverView(_coins, function()
            self:updateBottomUICoins(_coins, false, true, false)
            self:addBonusOverBigWinEffect(_coins, self.EFFECT_Fireworks)
            _fun()
        end)
    end
    self.m_fireworksGameView = util_createView("CalacasParadeSrc.CalacasParadeFireworksGameView", viewData)
    self:findChild("Node_yh"):addChild(self.m_fireworksGameView)
    --底栏可见性
    self.m_bottomUI:setVisible(false)
end
--fireworks-结算弹板
function CodeGameScreenCalacasParadeMachine:showFireworksGameOverView(_coins, _fun)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksOverView_start)
    local fnOver = function()
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksGame_overGc)
        self.m_transferAnim:playFireworksTransferAnim(
            function()
                --切换spin模式的: 背景 音乐
                local bgModel = "base"
                local bgMusic = PublicConfig.music_CalacasParade_base
                if self.m_bProduceSlots_InFreeSpin then
                    bgModel = "free"
                    bgMusic = PublicConfig.music_CalacasParade_free
                end
                self:changeReelBg(bgModel)
                self:resetMusicBg(true, bgMusic)
                --底栏可见性
                self.m_bottomUI:setVisible(true)

                self:findChild("Node_yh"):removeAllChildren()
                self.m_fireworksGameView = nil
            end,
            function()
                _fun(_coins)
            end
        )
    end

    local strCoins = util_formatCoins(_coins, 30)
    local view = self:showDialog("FeatureOver", {m_lb_coins=strCoins}, fnOver)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:updateLabelSize({label=view:findChild("m_lb_coins"), sx = 1, sy = 1}, 720)
    -- 弹板挂点-烟花
    local yanhuaSpine = util_spineCreate("CalacasParade_yanhua", true, true)
    view:findChild("Node_yanhua"):addChild(yanhuaSpine)
    util_spinePlay(yanhuaSpine, "tanban_idle1", true)
    --音效
    view.m_btnTouchSound = PublicConfig.sound_CalacasParade_CommonClick
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FireworksOverView_over)
    end)
end


--free
function CodeGameScreenCalacasParadeMachine:showFreeSpinView(effectData)
    self:levelPerformWithDelay(self, 0.5, function()
        self:playFreeTriggerSymbolAnim(function()
            self:showCalacasParadeFreeSpinStart(function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end) 
end
--free-图标触发
function CodeGameScreenCalacasParadeMachine:playFreeTriggerSymbolAnim(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_Scatter_trigger)
    local animName = "actionframe"
    local delayTime = 60/30
    self:baseReelForeach(function(_symbol, _iCol, _iRow)
        if TAG_SYMBOL_TYPE.SYMBOL_SCATTER == _symbol.p_symbolType then
            if self.m_clipParent ~= _symbol:getParent() then
                util_setSymbolToClipReel(self, _symbol.p_cloumnIndex, _symbol.p_rowIndex, _symbol.p_symbolType, 0)
            end
            _symbol:runAnim(animName, false)
        end
    end)
    delayTime = delayTime + 0.5
    self:levelPerformWithDelay(self, delayTime, _fun)
end
--free-Start
function CodeGameScreenCalacasParadeMachine:showCalacasParadeFreeSpinStart(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FreeStart_start)
    local view = self:showFreeSpinStart(
        self.m_iFreeSpinTimes,
        function()
            _fun()
        end
    )
    --背光
    local freeStartSpine = util_spineCreate("FreeGameStart_2", true, true)
    view:findChild("Node_spine"):addChild(freeStartSpine)
    util_spinePlay(freeStartSpine, "start", false)
    -- util_spineEndCallFunc(freeStartSpine,  "start", function() 
    -- end)
    -- 弹板挂点-烟花
    local yanhuaSpine = util_spineCreate("CalacasParade_yanhua", true, true)
    view:findChild("Node_yanhua"):addChild(yanhuaSpine)
    util_spinePlay(yanhuaSpine, "tanban_idle1", true)
    --音效
    view.m_btnTouchSound = PublicConfig.sound_CalacasParade_CommonClick
    view:setBtnClickFunc(function()
        self:upDateFreeModelUi(false)
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_FreeStart_over)
    end)
end
function CodeGameScreenCalacasParadeMachine:upDateFreeModelUi(_bReconnect)
    self:changeReelBg("free")
end
function CodeGameScreenCalacasParadeMachine:showFreeSpinOverView()
    self:changeReelBg("base")
    self:triggerFreeSpinOverCallFun()
end


function CodeGameScreenCalacasParadeMachine:checkRemoveBigMegaEffect()
    CodeGameScreenCalacasParadeMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenCalacasParadeMachine:getShowLineWaitTime()
    local time = CodeGameScreenCalacasParadeMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------

--重写-预告中奖
function CodeGameScreenCalacasParadeMachine:showFeatureGameTip(_fun)
    local delayTime = 0
    local triggerType = self.m_yugaoAnim:isTriggerYuGao()
    if "" ~= triggerType then
        self.b_gameTipFlag = true
        delayTime = self.m_yugaoAnim:playYuGaoAnim(triggerType)
    end
    self:levelPerformWithDelay(self, delayTime+0.5, _fun)
end
--重写-大赢
function CodeGameScreenCalacasParadeMachine:showEffect_NewWin(effectData, winType)
    self:playLevelBigWinAnim(function()
        --停止连线音效
        self:stopLinesWinSound()
        CodeGameScreenCalacasParadeMachine.super.showEffect_NewWin(self, effectData, winType)
    end)
end
function CodeGameScreenCalacasParadeMachine:playLevelBigWinAnim(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_BigWin)
    if math.random(1,10) <= 3 then
        gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_BigWin_2)
    end
    if not self.m_bigWinSpine1 then
        local nodeWinCoinEffect = self.m_bottomUI:getCoinWinNode()
        local parent1 = self.m_effectNodeDown
        self.m_bigWinSpine1 = util_spineCreate("CalacasParade_bigwin", true, true)
        parent1:addChild(self.m_bigWinSpine1, 10)
        local pos1 = util_convertToNodeSpace(nodeWinCoinEffect, parent1)
        local nodePos1 = parent1:convertToNodeSpace(cc.p(display.width/2, display.height/2))
        self.m_bigWinSpine1:setPosition(nodePos1.x, pos1.y)
    else
        self.m_bigWinSpine1:setVisible(true)
    end

    local animName = "actionframe_bigwin"
    local animTime = self.m_bigWinSpine1:getAnimationDurationTime(animName)
    self:levelPerformWithDelay(self, animTime, function()
        self.m_bigWinSpine1:setVisible(false)
        _fun()
    end)
    util_spinePlay(self.m_bigWinSpine1, animName, false)

    --赢钱数字
    local info = {
        overCoins = self.m_llBigOrMegaNum,
        animName = "actionframe3",
        jumpTime = 0.5,
    }
    self:playBottomBigWinLabAnim(info)
    --震动
    util_shakeNode(self:findChild("Node_reel"), 4, 4, animTime)
end
--重写-重新计算快滚
function CodeGameScreenCalacasParadeMachine:MachineRule_ResetReelRunData()
    self:checkAddFreeReelRunData()
    self:checkAddBonusReelRunData()
    local bBonus = self:isTriggerFreeReelRun() or self:isTriggerBonusReelRun()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall(bBonus)
    CodeGameScreenCalacasParadeMachine.super.MachineRule_ResetReelRunData(self)
end
-- --重写-首列快滚时规避stop按钮点击状态的恢复
-- function CodeGameScreenCalacasParadeMachine:dealSmallReelsSpinStates()
--     if self:isTriggerFreeReelRun() then
--         return
--     end
--     CodeGameScreenCalacasParadeMachine.super.dealSmallReelsSpinStates(self)
-- end
--重写-禁止恢复stop按钮状态
function CodeGameScreenCalacasParadeMachine:getOperaNetWorkStopBtnResetStatus()
    local bReset = CodeGameScreenCalacasParadeMachine.super.getOperaNetWorkStopBtnResetStatus(self)
    --首列快滚
    if bReset and self:isTriggerFreeReelRun() then
        bReset = false
    end
    return bReset
end
--快滚-free模式检测
function CodeGameScreenCalacasParadeMachine:isTriggerFreeReelRun()
    return self:getCurrSpinMode() == FREE_SPIN_MODE
end
function CodeGameScreenCalacasParadeMachine:checkAddFreeReelRunData()
    if not self:isTriggerFreeReelRun() then
        return
    end
    --前4列快滚
    for iCol=1,self.m_iReelColumnNum do
        local reelRunData = self.m_reelRunInfo[iCol]
        local columnData  = self.m_reelColDatas[iCol]
        local colHeight   = columnData.p_slotColumnHeight
        -- local bReelLongRun     = iCol < self.m_iReelColumnNum
        local bReelLongRun     = iCol <= self.m_iReelColumnNum
        local bNextReelLongRun = iCol < (self.m_iReelColumnNum-1)
        local runLen = 0

        reelRunData:setReelLongRun(bReelLongRun)
        reelRunData:setNextReelLongRun(bNextReelLongRun)

        if bReelLongRun then
            if 1 == iCol then
                local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight
                runLen = 0 + math.floor( reelCount ) * columnData.p_showGridCount
                self:creatReelRunAnimation(iCol)
                self:triggerLongRunChangeBtnStates()
            else
                runLen = self:getLongRunLen(iCol, 0)
            end
        else
            local lastReelRunData = self.m_reelRunInfo[self.m_iReelColumnNum-1]
            local lastRunLen      = lastReelRunData:getReelRunLen()
            runLen = lastReelRunData:getReelRunLen() + (reelRunData.initInfo.reelRunLen - lastReelRunData.initInfo.reelRunLen)
        end

        if next(self.m_reelSlotsList) then
            local columnSlotsList = self.m_reelSlotsList[iCol]
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            local iRow = columnData.p_showGridCount
            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then break end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        end
        reelRunData:setReelRunLen(runLen)
        --后面列停止加速移动
        local parentData = self.m_slotParents[iCol]
        parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
    end
end

--快滚-bonus检测
function CodeGameScreenCalacasParadeMachine:isTriggerBonusReelRun()
    if self:getSymbolCountByCol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, self.m_iReelColumnNum-1) >= 2 then
        return false
    end
    if self:isTriggerFreeReelRun() then
        return false
    end
    local reel = self.m_runSpinResultData.p_reels
    for _lineIndex,_lineData in ipairs(reel) do
        for iCol,_symbolType in ipairs(_lineData) do
            -- if self:isCalacasParadeBonus1(_symbolType) then
            --     return true
            -- end
            if self:isCalacasParadeBonus2(_symbolType) then
                return true
            end
        end
    end
    return false
end
--快滚-bonus检测并修改数据
function CodeGameScreenCalacasParadeMachine:checkAddBonusReelRunData()
    if not self:isTriggerBonusReelRun() then
        return
    end
    -- 最后一列
    local reelReunCol = self.m_iReelColumnNum
    local reelRunData  = self.m_reelRunInfo[reelReunCol]
    local columnData   = self.m_reelColDatas[reelReunCol]
    local colHeight    = columnData.p_slotColumnHeight

    local lastReelRunData = self.m_reelRunInfo[reelReunCol - 1]
    lastReelRunData:setNextReelLongRun(true)
    reelRunData:setReelLongRun(true)
    local runLen = self:getLongRunLen(reelReunCol, 0)
    reelRunData:setReelRunLen(runLen)
end




--重写-假滚替换
function CodeGameScreenCalacasParadeMachine:checkUpdateReelDatas(parentData)
    local reelDatas    = CodeGameScreenCalacasParadeMachine.super.checkUpdateReelDatas(self, parentData)
    self:changeCalacasParadeReelDatas_ticket(parentData)
    self:changeCalacasParadeReelDatas_free(parentData)
    return parentData.reelDatas
end

--车票图标-假滚替换
function CodeGameScreenCalacasParadeMachine:changeCalacasParadeReelDatas_ticket(parentData)
    local newReelDatas = {}
    for i,_symbolType in ipairs(parentData.reelDatas) do
        local newSymbolType = _symbolType
        --车票随机
        if _symbolType == self.SYMBOL_BonusTicket then
            newSymbolType = self:getBonus2RandomType()
        end
        newReelDatas[#newReelDatas + 1] = newSymbolType
    end
    --替换整个假滚列表
    parentData.reelDatas = newReelDatas
end
--车票图标-轮盘替换
function CodeGameScreenCalacasParadeMachine:changeCalacasParadeReels_ticket(_result)
    --修改车票的表现类型
    for _lineIndex,_lineData in ipairs(_result.reels) do
        for _iCol,_symbolType in ipairs(_lineData) do
            if _symbolType == self.SYMBOL_BonusTicket then
                local iRow = self.m_iReelRowNum + 1 - _lineIndex
                local reelPos = self:getPosReelIdx(iRow, _iCol)
                _lineData[_iCol] = self:getBonus2Type(reelPos, _result.selfData.tocketData)
            end
        end
    end
end


--free模式压暗图标-假滚替换
function CodeGameScreenCalacasParadeMachine:changeCalacasParadeReelDatas_free(parentData)
    -- 无论base还是free
    -- if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
    --     return
    -- end
    local newReelDatas = {}
    for i,_symbolType in ipairs(parentData.reelDatas) do
        --低级图标压暗
        newReelDatas[#newReelDatas + 1] = self:getSymbolDarkType(_symbolType) or _symbolType
    end
    --替换整个假滚列表
    parentData.reelDatas = newReelDatas
end
--free模式压暗图标-轮盘替换
function CodeGameScreenCalacasParadeMachine:changeCalacasParadeReels_free(_result)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        return
    end
    for _lineIndex,_lineData in ipairs(_result.reels) do
        for _iCol,_symbolType in ipairs(_lineData) do
            _lineData[_iCol] = self:getSymbolDarkType(_symbolType) or _symbolType
        end
    end
end
--free模式压暗图标-类型转换
function CodeGameScreenCalacasParadeMachine:getSymbolDarkType(_symbolType)
    if TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 <= _symbolType and _symbolType <= self.SYMBOL_L6 then
        return self.SYMBOL_H1_Dark + _symbolType - TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
    end
    if TAG_SYMBOL_TYPE.SYMBOL_WILD == _symbolType then
        return self.SYMBOL_Wild_Dark
    end
    return nil
end
--free模式压暗图标- 压暗->高亮
function CodeGameScreenCalacasParadeMachine:getDarkSymbolLightType(_darkSymbolType)
    if self.SYMBOL_Wild_Dark == _darkSymbolType then
        return  TAG_SYMBOL_TYPE.SYMBOL_WILD
    end
    if self.SYMBOL_H1_Dark <= _darkSymbolType and _darkSymbolType <= self.SYMBOL_L6_Dark then
        return TAG_SYMBOL_TYPE.SYMBOL_SCORE_9  + _darkSymbolType - self.SYMBOL_H1_Dark
    end
    return nil
end



--重写-刷新滚轴小块
function CodeGameScreenCalacasParadeMachine:updateReelGridNode(_symbol)
    self:addSpineSymbolCsbNode(_symbol)
    self:upDateReelBonusReward(_symbol)
    self:upDateReelTicketReward(_symbol)
    self:upDateSpecialBonusRollIdle(_symbol)
    self:reelRunUpDateBaseDarkSymbol(_symbol)
end
--spine图标绑定csb
CodeGameScreenCalacasParadeMachine.SpineSymbolBindCfg = {
    [CodeGameScreenCalacasParadeMachine.SYMBOL_BonusCoins] = {csbName = "CalacasParade_Bouns1_shuzi.csb", boneName = "shuzi"},
    [CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket_1] = {csbName = "CalacasParade_Bouns2_shuzi.csb", boneName = "shuzi"},
    [CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket_2] = {csbName = "CalacasParade_Bouns2_shuzi.csb", boneName = "shuzi"},
    [CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket_3] = {csbName = "CalacasParade_Bouns2_shuzi.csb", boneName = "shuzi"},
    [CodeGameScreenCalacasParadeMachine.SYMBOL_BonusTicket_4] = {csbName = "CalacasParade_Bouns2_shuzi.csb", boneName = "shuzi"},
}
function CodeGameScreenCalacasParadeMachine:addSpineSymbolCsbNode(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    local symbolCfg  = self.SpineSymbolBindCfg[symbolType]
    if not symbolCfg then
        return
    end

    --绑定一个Node 每次池子取出刷新时 清理挂点
    local animNode = _symbol:checkLoadCCbNode()
    if not animNode.m_bindNode then
        local spineNode = animNode.m_spineNode or (_symbol.m_symbolType and animNode) 
        animNode.m_bindNode = cc.Node:create()
        util_spinePushBindNode(spineNode, symbolCfg.boneName, animNode.m_bindNode)
    else
        animNode.m_bindNode:removeAllChildren()
    end
    -- csb需要播放时间线时 必须重新创建
    animNode.m_bindCsb = self:createSpineSymbolBindCsb(symbolType)
    animNode.m_bindNode:addChild(animNode.m_bindCsb)
end
function CodeGameScreenCalacasParadeMachine:createSpineSymbolBindCsb(_symbolType)
    local symbolCfg  = self.SpineSymbolBindCfg[_symbolType]
    local csb = util_createAnimation(symbolCfg.csbName)
    csb:runCsbAction("idleframe", false)
    return csb
end
--bonus1
function CodeGameScreenCalacasParadeMachine:isCalacasParadeBonus1(_symbolType)
    return _symbolType == self.SYMBOL_BonusCoins
end
--bonus1-刷新棋盘上的图标
function CodeGameScreenCalacasParadeMachine:upDateReelBonusReward(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    if not self:isCalacasParadeBonus1(symbolType) then
        return
    end
    local bonusData = nil
    -- local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    --假滚
    if not _symbol.m_isLastSymbol or _symbol.p_rowIndex > self.m_iReelRowNum then
        bonusData = self:getRandomBonusRewardData()
    --停轮
    else
        local reelPos = self:getPosReelIdx(_symbol.p_rowIndex, _symbol.p_cloumnIndex)
        bonusData = self:getReelBonusRewardData(reelPos)
    end
    self:upDateBonusReward(_symbol, bonusData)
end
--bonus1-随机数据
function CodeGameScreenCalacasParadeMachine:getRandomBonusRewardData()
    local curBet      = globalData.slotRunData:getCurTotalBet()
    local coinsMultip = self.m_configData:getBonus1SymbolRandomMulti()
    local coins       = curBet * coinsMultip

    local bonusData = {}
    bonusData[1] = -1
    bonusData[2] = coins
    return bonusData
end
--bonus1-服务器数据
function CodeGameScreenCalacasParadeMachine:getReelBonusRewardData(_reelPos)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local storedIcons = selfData.bonus1Coins or {}
    for i,_bonusData in ipairs(storedIcons) do
        if _reelPos == _bonusData[1] then
            return clone(_bonusData) 
        end
    end
    --^^^等报错接口上线后 这个地方加个判空抛送日志
    local sMsg = string.format("[CodeGameScreenCalacasParadeMachine:getReelBonusRewardData] error %d", _reelPos)
    print(sMsg)
    release_print(sMsg)
    local bonusData = {}
    bonusData[1] = -1
    bonusData[2] = 0
    return bonusData
end
--bonus1-高低倍
function CodeGameScreenCalacasParadeMachine:isHeightBonus1Coins(_coins)
    local curBet  = globalData.slotRunData:getCurTotalBet()
    local bHeight =  _coins/curBet >= 5
    return bHeight
end

--bonus1-根据数据刷新图标
function CodeGameScreenCalacasParadeMachine:upDateBonusReward(_symbol, _bonusData)
    local animNode = _symbol:getCCBNode()
    local slotCsb  = animNode.m_bindCsb
    self:upDateBonusBindCsb(slotCsb, _bonusData)
end
--bonus1-根据数据刷新绑定csb
function CodeGameScreenCalacasParadeMachine:upDateBonusBindCsb(_bindCsb, _bonusData)
    local coins   = _bonusData[2]
    local bHeight = self:isHeightBonus1Coins(coins)
    local labCoins1 = _bindCsb:findChild("m_lb_coins_1")
    local labCoins2 = _bindCsb:findChild("m_lb_coins_2")
    labCoins1:setVisible(not bHeight)
    labCoins2:setVisible(bHeight)
    if coins <= 0 then
        labCoins1:setString("")
        labCoins2:setString("")
    else
        local sCoins = util_formatCoins(coins, 3)
        if not bHeight then
            labCoins1:setString(sCoins)
            self:updateLabelSize({label=labCoins1,  sx=1, sy=1}, 161)
        else
            labCoins2:setString(sCoins)
            self:updateLabelSize({label=labCoins2,  sx=1, sy=1}, 161)
        end
    end
end
--bonus2
function CodeGameScreenCalacasParadeMachine:isCalacasParadeBonus2(_symbolType)
    local bonus2Index = self:getCalacasParadeBonus2Index(_symbolType)
    return nil ~= bonus2Index
end
--bonus2-信号转索引
function CodeGameScreenCalacasParadeMachine:getCalacasParadeBonus2Index(_symbolType)
    if self.SYMBOL_BonusTicket_1 <= _symbolType and _symbolType <= self.SYMBOL_BonusTicket_4 then
        return _symbolType + 1 - self.SYMBOL_BonusTicket_1
    end
    return nil
end
--bonus2-索引转信号
function CodeGameScreenCalacasParadeMachine:getCalacasParadeBonus2SymbolType(_bonus2Index)
    return self.SYMBOL_BonusTicket_1 + _bonus2Index - 1
end

--bonus2-随机数据
function CodeGameScreenCalacasParadeMachine:getBonus2RandomType()
    local symbolType = math.random(self.SYMBOL_BonusTicket_1, self.SYMBOL_BonusTicket_4)
    return symbolType
end
--bonus2-服务器数据
function CodeGameScreenCalacasParadeMachine:getBonus2Type(_reelPos, _dataList)
    local dataList = _dataList
    if not dataList then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        dataList = selfData.tocketData or {}
    end
    for i,_data in ipairs(dataList) do
        if _reelPos == _data[1] then
            return self:getCalacasParadeBonus2SymbolType(_data[2])
        end
    end

    --^^^判空日志
    local sMsg = string.format("[CodeGameScreenCalacasParadeMachine:getBonus2Type] error %d", _reelPos)
    print(sMsg)
    release_print(sMsg)

    local symbolType = self:getBonus2RandomType()
    return symbolType
end
--bonus2-服务器数据-金额
function CodeGameScreenCalacasParadeMachine:getBonus2Coins(_reelPos)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local dataList = selfData.tocketCoinsData or {}
    for i,_data in ipairs(dataList) do
        if _reelPos == _data[1] then
            return self:getCalacasParadeBonus2SymbolType(_data[2])
        end
    end

    return 0
end
--bonus2-刷新棋盘图标
function CodeGameScreenCalacasParadeMachine:upDateReelTicketReward(_symbol, _bUpDate)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    if not self:isCalacasParadeBonus2(symbolType) then
        return
    end

    local coins = 0
    --假滚
    if not _symbol.m_isLastSymbol or _symbol.p_rowIndex > self.m_iReelRowNum then
    --停轮 并且使用服务器数据
    elseif _bUpDate then
        local reelPos = self:getPosReelIdx(_symbol.p_rowIndex, _symbol.p_cloumnIndex)
        coins = self:getBonus2Coins(reelPos)
    end
    self:upDateTicketReward(_symbol, coins)
end
--bonus2-刷新图标
function CodeGameScreenCalacasParadeMachine:upDateTicketReward(_symbol, _coins)
    local animNode = _symbol:getCCBNode()
    local bindCsb  = animNode.m_bindCsb
    self:upDateTicketBindCsb(bindCsb, _coins)
end
--bonus2-刷新csb
function CodeGameScreenCalacasParadeMachine:upDateTicketBindCsb(_bindCsb, _coins)
    local labCoins1 = _bindCsb:findChild("m_lb_coins_1")
    local labCoins2 = _bindCsb:findChild("m_lb_coins_2")
    if _coins <= 0 then
        labCoins1:setString("")
        labCoins2:setString("")
    else
        local bHeight = self:isHeightBonus1Coins(_coins)
        local labCoins = bHeight and labCoins2 or labCoins1
        labCoins1:setVisible(not bHeight)
        labCoins2:setVisible(bHeight)
        local sCoins = util_formatCoins(_coins, 3)
        labCoins:setString(sCoins)
        self:updateLabelSize({label=labCoins,  sx=1, sy=1}, 166)
    end
end


--specialBonus
function CodeGameScreenCalacasParadeMachine:isCalacasParadeSpecialBonus(_symbolType)
    local index = self:getCalacasParadeSpecialBonusIndex(_symbolType)
    return nil ~= index
end
--specialBonus-索引
function CodeGameScreenCalacasParadeMachine:getCalacasParadeSpecialBonusIndex(_symbolType)
    if self.SYMBOL_SpecialBonus1 <= _symbolType and _symbolType <= self.SYMBOL_SpecialBonus2 then
        return _symbolType + 1 - self.SYMBOL_SpecialBonus1
    end
    return nil
end
--specialBonus-滚动静帧
function CodeGameScreenCalacasParadeMachine:upDateSpecialBonusRollIdle(_symbol)
    local symbolType = _symbol.p_symbolType
    if not self:isCalacasParadeSpecialBonus(symbolType) then
        return
    end
    --修改滚动图标层级
    local symbolOrder = self:getBounsScatterDataZorder(_symbol.p_symbolType)
    local showOrder = symbolOrder - _symbol.p_rowIndex
    _symbol.p_showOrder = showOrder
    _symbol.m_showOrder = showOrder
    _symbol:setLocalZOrder(showOrder)
    _symbol:runAnim("idleframe3", false)
end
--specialBonus-触发时的背景烟花
function CodeGameScreenCalacasParadeMachine:playSpecialBonus1Actionframe(_symbol)
    local symbolType = _symbol.p_symbolType or _symbol.m_symbolType
    if 1 ~= self:getCalacasParadeSpecialBonusIndex(symbolType) then
        return
    end
    local spine = util_spineCreate("CalacasParade_yanhua", true, true)
    _symbol:addChild(spine, -1)
    util_spinePlay(spine, "actionframe", false)
    util_spineEndCallFunc(spine,  "actionframe", function()
        spine:setVisible(false)
        performWithDelay(self,function()
            spine:removeFromParent()
        end,0)
    end)
end
--压暗图标-base假滚落地结束前全部使用压暗
function CodeGameScreenCalacasParadeMachine:reelRunUpDateBaseDarkSymbol(_symbol)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return
    end
    if IDLE == globalData.slotRunData.gameSpinStage then
        return
    end
    local symbolType    = _symbol.p_symbolType
    local newSymbolType = self:getSymbolDarkType(symbolType)
    if nil == newSymbolType then
        return
    end
    self:changeCalacasParadeSymbolType(_symbol, newSymbolType)
end
--压暗图标-base假滚落地结束时硬切变亮
function CodeGameScreenCalacasParadeMachine:reelDownUpDateBaseDarkSymbol(_fun)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return _fun()
    end
    -- local parent   = self.m_effectNodeDown
    local fadeTime = 0.2 
    self:baseReelForeach(function(_symbol, _iCol, _iRow)
        local symbolType = _symbol.p_symbolType
        local lightType  = self:getDarkSymbolLightType(symbolType)
        if lightType then
            self:changeCalacasParadeSymbolType(_symbol, lightType)
            local parent = _symbol
            --临时图标淡出
            local tempSymbol = util_createView("CalacasParadeSrc.CalacasParadeTempSymbol", {machine=self})
            parent:addChild(tempSymbol, 100)
            tempSymbol:changeSymbolCcb(symbolType)
            tempSymbol:setPosition(util_convertToNodeSpace(_symbol, parent))
            util_setCascadeOpacityEnabledRescursion(tempSymbol, true)
            local actList = {}
            table.insert(actList, cc.FadeOut:create(fadeTime))
            table.insert(actList, cc.RemoveSelf:create())
            tempSymbol:runAction(cc.Sequence:create(actList))
        end
    end)
    self:levelPerformWithDelay(self, fadeTime, _fun)
end


--重写-初始化棋盘的图标层级
function CodeGameScreenCalacasParadeMachine:initGridList()
    CodeGameScreenCalacasParadeMachine.super.initGridList(self)
    if not self:checkHasFeature() then
        self:baseReelForeach(function(_symbol, _iCol, _iRow)
            local symbolType = _symbol.p_symbolType
            if self:isCalacasParadeClipParentSymbol(symbolType) then
                self:changeSymbolReelOrder(_symbol, true, 0)
            end
        end)
    end
end
--重写-数据返回
function CodeGameScreenCalacasParadeMachine:operaSpinResultData(param)
    if param[1] == true then
        local result = param[2].result
        if result.reels then
            self:changeCalacasParadeReels_ticket(result)
            self:changeCalacasParadeReels_free(result)
        end
    end
    CodeGameScreenCalacasParadeMachine.super.operaSpinResultData(self,param)
end
--重写-取消五连
function CodeGameScreenCalacasParadeMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenCalacasParadeMachine.super.lineLogicWinLines(self)
    return false
end


--重写-关卡适配
function CodeGameScreenCalacasParadeMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    local mainHeight = display.height - uiH - uiBH
    local mainPosY   = 8
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
    if globalData.slotRunData.isPortrait == true then
        if display.height <= DESIGN_SIZE.height then
            -- 1.78
            if display.height / display.width >= 1370/768 then
            --1.59
            elseif display.height / display.width >= 1228/768 then
                local a1 = 1228/768
                local a2 = 1370/768
                local a3 = display.height/display.width
                local b1 = 1.25
                local b2 = 1
                local b3 = b1 + ((a3-a1) / (a2-a1)) * (b2-b1)
                mainScale = mainScale * b3
                mainPosY = mainPosY - 5
            --1.5
            elseif display.height / display.width >= 1152/768 then
                mainScale = mainScale * 1.25
                mainPosY = mainPosY - 5
            --1.19
            elseif display.height / display.width >= 920/768 then
                mainScale = mainScale * 1.35
                mainPosY = mainPosY + 15
            end
            mainScale = math.min(1, mainScale)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale  = mainScale
            self.m_machineNode:setPositionY(mainPosY)
        end
    end
end



--工具-根据模式切换背景卷轴
function CodeGameScreenCalacasParadeMachine:changeReelBg(_model)
    local bBase      = "base"   == _model
    local bFree      = "free"   == _model
    local bBonus     = "bonus"  == _model
    
    --卷轴
    if bBase or bFree then
        self:findChild("Node_base_reel"):setVisible(bBase)
        self:findChild("Node_free_reel"):setVisible(bFree)
    end
    --背景
    local bgAnimName = ""
    if bBase then
        bgAnimName = "idleframe1"
    elseif bFree then
        bgAnimName = "idleframe2"
    elseif bBonus then
        bgAnimName = "idleframe3"
    end

    self.m_freeSpineBg:setVisible(bFree)
    if bFree then
        self.m_gameBg:runCsbAction("switch", false)
        util_spinePlay(self.m_freeSpineBg, bgAnimName, true)
    elseif "" ~= bgAnimName then
        self.m_gameBg:runCsbAction("idle", false)
        util_spinePlay(self.m_spineBg, bgAnimName, true)
    end
end
--工具-关卡延时
function CodeGameScreenCalacasParadeMachine:levelPerformWithDelay(_parent, _time, _fun)
    if _time <= 0 then
        return _fun()
    end
    local waitNode = cc.Node:create()
    _parent:addChild(waitNode)
    performWithDelay(waitNode,function()
        _fun()
        waitNode:removeFromParent()
    end, _time)
    return waitNode
end
--工具-获取图标在第N列前的总数
function CodeGameScreenCalacasParadeMachine:getSymbolCountByCol(_symbolType, _iCol)
    local count = 0
    local reel = self.m_runSpinResultData.p_reels
    for _lineIndex,_lineData in ipairs(reel) do
        for iCol,_symbol in ipairs(_lineData) do
            if iCol <= _iCol and _symbol == _symbolType then
                count = count + 1
            end
        end
    end
    return count
end
--工具-循环棋盘图标
function CodeGameScreenCalacasParadeMachine:baseReelForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                fun(node, iCol, iRow)
            end
        end
    end
end
--工具-获取图标列表
function CodeGameScreenCalacasParadeMachine:getReelSymbolList(_symbolList, _symbolType, _bSort)
    self:baseReelForeach(function(_symbol, _iCol, _iRow)
        if _symbol.p_symbolType == _symbolType then
            table.insert(_symbolList, _symbol)
        end
    end)
    if _bSort then
        table.sort(_symbolList, function(_symbolA, _symbolB)
            if _symbolA.p_cloumnIndex ~= _symbolB.p_cloumnIndex then
                return _symbolA.p_cloumnIndex < _symbolB.p_cloumnIndex
            end
            if _symbolA.p_rowIndex ~= _symbolB.p_rowIndex then
                return _symbolA.p_rowIndex > _symbolB.p_rowIndex
            end
            return false
        end)
    end
    return _symbolList
end
--工具-变更小块信号值
function CodeGameScreenCalacasParadeMachine:changeCalacasParadeSymbolType(_symbol, _symbolType)
    if _symbol.p_symbolType == _symbolType then
        return false
    end
    if _symbol.p_symbolImage then
        _symbol.p_symbolImage:removeFromParent()
        _symbol.p_symbolImage = nil
    end
    local ccbName = self:getSymbolCCBNameByType(self,_symbolType)
    _symbol:changeCCBByName(ccbName, _symbolType)
    _symbol.p_showOrder  = self:getBounsScatterDataZorder(_symbolType)
    _symbol.m_showOrder  = _symbol.p_showOrder
    _symbol.p_symbolType = _symbolType
    _symbol:runAnim("idleframe", false)
    --重置一些附加表现
    return true
end
--工具-刷新图标层级
function CodeGameScreenCalacasParadeMachine:changeSymbolReelOrder(_symbol, _bTop, _order)
    _symbol:stopAllActions()
    local symbolType = _symbol.p_symbolType
    if nil == _bTop then
        _bTop = self:isCalacasParadeClipParentSymbol(symbolType)
    end
    local iCol       = _symbol.p_cloumnIndex
    local iRow       = _symbol.p_rowIndex
    if _bTop then
        _order = _order or 0
        --不在棋盘的图标先恢复到棋盘上
        self:changeBaseParent(_symbol)
        util_setSymbolToClipReel(self, iCol, iRow, _symbol.p_symbolType, _order)
        --连线坐标
        local linePos = {}
        linePos[#linePos + 1] = {iX = iRow, iY = iCol}
        _symbol.m_bInLine = true
        _symbol:setLinePos(linePos)
    else
        _order = _order or self:getBounsScatterDataZorder(symbolType)
        _symbol.p_layerTag  = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        _symbol.m_showOrder = _order
        _symbol.p_showOrder = _order
        local slotParent = self.m_slotParents[iCol].slotParent
        local nodePos  = util_convertToNodeSpace(_symbol, slotParent)
        util_changeNodeParent(slotParent, _symbol, _symbol.m_showOrder)
        _symbol:setTag(_symbol.p_cloumnIndex * SYMBOL_NODE_TAG + _symbol.p_rowIndex)
        _symbol:setPosition(nodePos)
    end
end
--提层图标
function CodeGameScreenCalacasParadeMachine:isCalacasParadeClipParentSymbol(_symbolType)
    local bTop = _symbolType >= self.SYMBOL_BonusCoins and _symbolType <= self.SYMBOL_BonusTicket_4
    return bTop
end

--工具-底栏反馈
function CodeGameScreenCalacasParadeMachine:playBottomWinCoinsSpine()
    local animName = "actionframe"
    if not self.m_bottomWinCoinSpine then
        local parent = self.m_bottomUI:getCoinWinNode()
        self.m_bottomWinCoinSpine =  util_spineCreate("CalacasParade_totalwin", true, true)
        parent:addChild(self.m_bottomWinCoinSpine)
        util_spineMix(self.m_bottomWinCoinSpine, animName, animName, 0.2)
    end
    self.m_bottomWinCoinSpine:stopAllActions()
    self.m_bottomWinCoinSpine:setVisible(true)
    local animTime = self.m_bottomWinCoinSpine:getAnimationDurationTime(animName)
    util_spinePlay(self.m_bottomWinCoinSpine, animName, false)
    performWithDelay(self.m_bottomWinCoinSpine,function()
        self.m_bottomWinCoinSpine:setVisible(false)
    end, animTime)
end
--工具-更新底栏金币(保证调用在连线事件前)
function CodeGameScreenCalacasParadeMachine:updateBottomUICoins(_addCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    if nil == isNotifyUpdateTop then
        local bLine = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
        local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
        isNotifyUpdateTop = not bLine and not bFree
    end

    local params = {}
    params[1] = _addCoins
    params[2] = isNotifyUpdateTop
    params[3] = _bJump
    params[4] = 0
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound

    local lastCoins     = self:getLastWinCoin()
    local spinWinCoins  = self.m_runSpinResultData.p_winAmount or 0
    self.m_spinAddBottomCoins = math.min(spinWinCoins, self.m_spinAddBottomCoins + _addCoins)
    local tempLastCoins = lastCoins - spinWinCoins + self.m_spinAddBottomCoins

    self:setLastWinCoin(tempLastCoins)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    self:setLastWinCoin(lastCoins)
end
--工具-特殊玩法结束检测添加大赢
function CodeGameScreenCalacasParadeMachine:addBonusOverBigWinEffect(_bonusWinCoins, _effectType)
    if nil == _bonusWinCoins then
        local spinWinCoins  = self.m_runSpinResultData.p_winAmount or 0
        local lineWinCoins  = self:getClientWinCoins()
        _bonusWinCoins      = spinWinCoins - lineWinCoins
    end

    local bLine  = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
    local bBonus = _effectType >= GameEffect.EFFECT_BONUS
    local leftCount  = globalData.slotRunData.freeSpinCount
    local totalCount = globalData.slotRunData.totalFreeSpinCount
    local bFree      = self:getCurrSpinMode() == FREE_SPIN_MODE
    local bLastFree  = self.m_bProduceSlots_InFreeSpin and leftCount ~= totalCount and 0 == leftCount
    --检查添加大赢
    if not bLastFree and (not bLine or bBonus) then
        self.m_iOnceSpinLastWin = _bonusWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{_bonusWinCoins, _effectType})
        self:sortGameEffects()
    else
    end
    --刷新顶栏
    if not bFree and (not bLine or bBonus) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end
    --刷新连线赢钱值
    if bLine then
        local lineWinCoins  = self:getClientWinCoins()
        self.m_iOnceSpinLastWin = lineWinCoins
    end
end

return CodeGameScreenCalacasParadeMachine