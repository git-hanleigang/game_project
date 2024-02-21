--[[
玩法:  
    base:
        随机捕鱼: 废弃
            滚动随机延时发射一枚炮弹。
        固定图标玩法:
            scatter、specialBonus只能出现在2,4列。出现后图标锁定,棋盘上所有reel进行respin（respin要花钱）[实际上和reSpin模式没关系]。
            直到再出现一个同种图标触发玩法或respin3次仍未触发玩法，则respin结束。
            scatter 同时存在2，4列 触发 free。
            specialBonus 同时存在2，4列 触发 bonus。
        收集bonus的bet玩法:
            specialBonus 收集满指定数量触发superBonus玩法。使用激光捕鱼。
    free:
        第三列滚出95信号时，玩家选择使用其中1列的炮台发射圆形炮弹。
    bonus:
        圆形炮弹每个等级给定发射次数。
    superBonus:
        激光炮弹每个等级给定发射次数。
]]
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCastFishingMachine = class("CodeGameScreenCastFishingMachine", BaseNewReelMachine)
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"
local CastFishingSceneConfig = require "CodeCastFishingSrc.CastFishingFish.CastFishingSceneConfig"
local CastFishingMusicConfig = require "CodeCastFishingSrc.CastFishingMusicConfig"


CodeGameScreenCastFishingMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCastFishingMachine.SYMBOL_SpecialBonus = 94    -- base下触发bonus
CodeGameScreenCastFishingMachine.SYMBOL_Bonus = 95           -- free下触发捕鱼 

CodeGameScreenCastFishingMachine.EFFECT_CollectBonus = GameEffect.EFFECT_SELF_EFFECT - 60    --收集bonus
CodeGameScreenCastFishingMachine.EFFECT_LockSymbol   = GameEffect.EFFECT_SELF_EFFECT - 50    --固定图标
CodeGameScreenCastFishingMachine.EFFECT_FreeBattery  = GameEffect.EFFECT_SELF_EFFECT - 40    --free开炮捕鱼

-- 构造函数
function CodeGameScreenCastFishingMachine:ctor()
    CodeGameScreenCastFishingMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

    self.m_mag = CastFishingManager:getInstance()
    self.m_mag:initMachine(self)
    
    -- 收集完成时使用的bet值
    self.m_collectAvgBet = nil
    -- 收集进度
    self.m_collectData   = {}

    -- base捕鱼的数据包
    self.m_baseFishingData = nil
    -- free捕鱼的数据包
    self.m_freeFishingData = nil
    -- bonus捕鱼的数据包
    self.m_bonusFishingData = nil
    
    -- free断线重连不播触发动画
    self.m_freeReconnection = false

    -- 快滚数据
    self.m_reelRunColData = {}

    -- jackpot转盘缩放
    self.m_jackpotWheelScale = 1

    --init
    self:initGame()
end

function CodeGameScreenCastFishingMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

-- 这个字段和csv中的level_idx对应
function CodeGameScreenCastFishingMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CastFishing"  
end

function CodeGameScreenCastFishingMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    -- 奖池
    self.m_jackpotBar = util_createView("CodeCastFishingSrc.CastFishingJackPotBarView", self)
    self:findChild("Node_Jackpot"):addChild(self.m_jackpotBar)

    -- base鱼池
    self.m_baseFishView = util_createView("CodeCastFishingSrc.CastFishingFree.CastFishingFreeFishView", {
        self,
        "CastFishing_baseFishView.csb",
        CastFishingManager.StrMode.Base
    })
    self:findChild("Node_baseFishView"):addChild(self.m_baseFishView)
    -- base进度条
    self.m_collectBar = util_createView("CodeCastFishingSrc.CastFishingCollectBar", self)
    self:findChild("Node_jindutiao"):addChild(self.m_collectBar)
    -- 提示按钮
    self.m_tip = util_createView("CodeCastFishingSrc.CastFishingTips", {self, self:findChild("Node_tipView")})
    self:findChild("Node_tipBtn"):addChild(self.m_tip)
    -- 2 4 列锁定图标
    self.m_lockSymbolMag = util_createView("CodeCastFishingSrc.CastFishingLockSymbolMag", {
        self,
        self:findChild("Node_lockSymbol"),
        self:findChild("lay_lockReel"),
        self:findChild("Node_kuang_1"),
        self:findChild("Node_kuang_2"),
    })
    self.m_lockSymbolMag:setLockSymbolVisible(false)

    -- free鱼池
    self.m_freeFishView = util_createView("CodeCastFishingSrc.CastFishingFree.CastFishingFreeFishView", {
        self,
        "CastFishing_freeFishView.csb",
        CastFishingManager.StrMode.Free
    })
    self:findChild("Node_freeFishView"):addChild(self.m_freeFishView)
    self.m_freeFishView:setVisible(false)
    -- free次数栏
    self.m_freeBar = util_createView("CodeCastFishingSrc.CastFishingFree.CastFishingFreespinBarView", self)
    self:findChild("Node_FGspin"):addChild(self.m_freeBar)
    self.m_freeBar:setVisible(false)
    -- free炮台
    self.m_freeBatteryList = util_createView("CodeCastFishingSrc.CastFishingFree.CastFishingFreeBatteryList", {self})
    self:findChild("Node_freePao"):addChild(self.m_freeBatteryList)
    self.m_freeBatteryList:setVisible(false)

    --bonus鱼池
    self.m_bonusFishView = util_createView("CodeCastFishingSrc.CastFishingBonus.CastFishingBonusFishView", {
        self,
        "CastFishing_bonusFishView.csb",
        CastFishingManager.StrMode.Bonus
    })
    self:findChild("Node_bonusFishView"):addChild(self.m_bonusFishView)
    self.m_bonusFishView:setVisible(false)

    -- 捕中wild反馈
    self.m_wildFankuiCsb = util_createAnimation("CastFishing_wildfankui.csb")
    self:findChild("Node_wildFanKui"):addChild(self.m_wildFankuiCsb)
    self.m_wildFankuiCsb:setVisible(false)
    
    -- spine背景
    local bgParent = self:findChild("bg")
    self.m_bgSpine = util_spineCreate("GameScreenCastFishingBg",true,true)
    bgParent:addChild(self.m_bgSpine, GAME_LAYER_ORDER.LAYER_ORDER_BG - 1)
    util_spinePlay(self.m_bgSpine, "idleframe", true)

    -- 点击反馈
    self.m_clickEffect = util_createView("CodeCastFishingSrc.CastFishingClickEffect")
    self:findChild("Node_clickEffect"):addChild(self.m_clickEffect)
    
    -- 3个过场spine
    self.m_guochangSpine = {}
    for spineIndex=1,3 do
        local spineName = string.format("CastFishingGC%d", spineIndex)
        local guochangSpine = util_spineCreate(spineName, true, true)
        self:addChild(guochangSpine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
        guochangSpine:setPosition(display.width/2,display.height/2)
        guochangSpine:setVisible(false)
        table.insert(self.m_guochangSpine, guochangSpine)
    end
    -- 墨汁
    self.m_mozhiSpine = util_spineCreate("Socre_CastFishing_9_mozhi", true, true)
    self:addChild(self.m_mozhiSpine, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_mozhiSpine:setPosition(display.width/2,display.height/2)
    self.m_mozhiSpine:setVisible(false)
    --文字说明
    self.m_enterTips = util_createView("CodeCastFishingSrc.CastFishingEnterTips")
    self:addChild(self.m_enterTips, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_enterTips:setPosition(display.width/2, display.height/2)
    self.m_enterTips:setVisible(false)

    --底栏反馈
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "CastFishing_jiesuanfankui.csb")

    self:changeBgReel(true, false)
end


function CodeGameScreenCastFishingMachine:enterGamePlayMusic(  )
    self:playEnterGameSound(CastFishingMusicConfig.sound_CastFishing_enterLevel)
end

function CodeGameScreenCastFishingMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_mag:addObservers()

    CodeGameScreenCastFishingMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:enterLevelUpDateCollectBar()
    local bFreeBattery = self:isTriggerFreeBattery()
    local bBonusBattery = self:isTriggerBonusGame()
    -- jackpot切换
    if not bBonusBattery then
        self.m_jackpotBar:upDateOpacity()
    end
    
    if not self.m_bProduceSlots_InFreeSpin and not bBonusBattery then
        -- 启动base鱼池计时器
        self.m_baseFishView:startUpDateTick()
        -- 固定图标玩法
        self:changeBetUpDateLockSymbol()
        -- 进入关卡弹出提示
        self.m_tip:playStartAnim()
        self.m_enterTips:playStartAnim()
    end
    -- 触发free、bonus 那次spin断线时恢复棋盘上的固定图标
    if (self.m_bProduceSlots_InFreeSpin and globalData.slotRunData.freeSpinCount == globalData.slotRunData.totalFreeSpinCount) or bBonusBattery then
        local selfData   = self.m_runSpinResultData.p_selfMakeData or {}
        local respinData = selfData.respinData or {}
        local sBetKey = string.format("%d", globalData.slotRunData:getCurTotalBet())
        local lockData = respinData[sBetKey]
        if nil ~= lockData then
            local iPos        = lockData.loc
            local fixPos      = self:getRowAndColByPos(iPos) 
            self.m_lockSymbolMag:upDateOnePos(fixPos.iY, fixPos.iX)
            self:lockSymbolReplaceNode(lockData, false)
        end
    end
    -- 捕鱼重连屏蔽spinBtn
    if bFreeBattery or bBonusBattery then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    end
end

function CodeGameScreenCastFishingMachine:addObservers()
    CodeGameScreenCastFishingMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
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
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end
        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = CastFishingMusicConfig[string.format("sound_CastFishing_lastWinFree_%d", soundIndex)]
        else
            soundName = CastFishingMusicConfig[string.format("sound_CastFishing_lastWinBase_%d", soundIndex)]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
    --bet数值切换
    gLobalNoticManager:addObserver(self,function(self,params)
        self:changeBetUpDateLockSymbol()
    end,ViewEventType.NOTIFY_BET_CHANGE)
    --消息返回
    gLobalNoticManager:addObserver(self,function(self,params)
        if params.isFreeFishing and nil ~= self.m_freeFishingData then
            self:playEffect_FreeBatteryOver(params)
            return
        end

        if params.isBonusFishing and nil ~= self.m_bonusFishingData then
            self:playEffect_BonusBatteryOver(params)
            return
        end
    end,"CastFishingMachine_resultCallFun")
    -- bonus子弹离场事件
    gLobalNoticManager:addObserver(self,function(self,params)
        self:bonusBulletOverCallBack(params)
    end,"CastFishingMachine_bonusBulletOverCallBack")
end

function CodeGameScreenCastFishingMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_mag:removeInstance()

    CodeGameScreenCastFishingMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCastFishingMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_Bonus then
        return "Socre_CastFishing_upshot2"
    end
    if symbolType == self.SYMBOL_SpecialBonus then
        return "Socre_CastFishing_upshot1"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCastFishingMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCastFishingMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Bonus,count =  2}
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SpecialBonus,count =  2}


    return loadNode
end
--[[
    一些界面控件的使用
]]
-- 过场 _fun:切换展示 _fun2:结束回调
function CodeGameScreenCastFishingMachine:playGuoChangAnim(_fun,_fun2)
    for i,_spine in ipairs(self.m_guochangSpine) do
        _spine:setVisible(true)
        util_spinePlay(_spine, "actionframe", false)
    end

    self:levelPerformWithDelay(self, 60/30 , function()
        if _fun then
            _fun()
        end
    end)
    self:levelPerformWithDelay(self, 141/30 , function()
        for i,_spine in ipairs(self.m_guochangSpine) do
            _spine:setVisible(false)
        end
        if _fun2 then
            _fun2()
        end
    end)
end
-- 棋盘背景
function CodeGameScreenCastFishingMachine:changeBgReel(_bBase, _bPlayAnim)
    local baseReel = self:findChild("Node_reel_base")
    local baseBg = self.m_gameBg:findChild("Node_base")
    local freeReel = self:findChild("Node_reel_free")
    local baseBg = self.m_gameBg:findChild("Node_free")

    if _bPlayAnim then
        baseReel:setVisible(_bBase)
        freeReel:setVisible(not _bBase)
    else
        baseReel:setVisible(_bBase)
        freeReel:setVisible(not _bBase)
    end
end
-- 进度条
function CodeGameScreenCastFishingMachine:enterLevelUpDateCollectBar()
    local cur = 0
    local max = 50
    if nil ~= self.m_collectData then
        cur = self.m_collectData.collect
        max = self.m_collectData.request
    end
    self:updateCollectBar(cur, max, false, nil)
end

function CodeGameScreenCastFishingMachine:updateCollectBar(_cur, _max, _playAnim, _fun)
    local progressValue = math.floor(_cur / _max * 100)
    self.m_collectBar:changeProgress(progressValue, _playAnim, _fun)
end
-- jackpotBar
function CodeGameScreenCastFishingMachine:BaseMania_updateJackpotScore(index, totalBet)
    if not totalBet then
        totalBet = self:getCastFishingCurBet()
    end

    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools or not jackpotPools[index] then
        return 0
    end
    local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index], true, totalBet)
    return totalScore
end
-- 特殊bonus玩法要使用平均bet
function CodeGameScreenCastFishingMachine:getCastFishingCurBet()
    local curBet = globalData.slotRunData:getCurTotalBet()
    if nil ~= self.m_collectAvgBet then
        curBet = self.m_collectAvgBet
    end
    return curBet
end
-- 锁定图标
function CodeGameScreenCastFishingMachine:playLockSymbolActionFrameAnim(_symbolType, _fun)
    self:stopLinesWinSound()

    local bPlay = false
    self:baseReelSlotsNodeForeach(function(node, iCol, iRow)
        if 2==iCol or 4==iCol then
            if _symbolType == node.p_symbolType then
                if not bPlay then
                    bPlay = true
                    node:runAnim("actionframe2", false,function()
                        _fun()
                    end)
                else
                    node:runAnim("actionframe2", false)
                end
            end
        end
    end)
    if not bPlay then
        _fun()
    end
end
--触发连线时将固定图标覆盖到棋盘上
function CodeGameScreenCastFishingMachine:showEffect_LineFrame(effectData)
    if self.m_lockSymbolMag:isLockSymbolVisible() then
        self.m_lockSymbolMag:lineFrameHideLockSymbol()
        local lockData    = self.m_lockSymbolMag.m_lockSymbolData
        self:lockSymbolReplaceNode(lockData, true)
    end
    
    CodeGameScreenCastFishingMachine.super.showEffect_LineFrame(self, effectData)
    -- 触发bonus断掉轮播
    if self:isTriggerBonusGame() then
        if self.m_showLineHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_showLineHandlerID)
            self.m_showLineHandlerID = nil
        end
    end

    return true
end
function CodeGameScreenCastFishingMachine:lockSymbolReplaceNode(_lockData, _toClipReel)
    local iPos        = _lockData.loc
    local isScatter   = "sc" == _lockData.kind
    local symbolType  = isScatter and TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self.SYMBOL_SpecialBonus
    local fixPos      = self:getRowAndColByPos(iPos) 
    local slotsNode   = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
    local lockSymbol  = self.m_lockSymbolMag:getLockSymbol(fixPos.iY, fixPos.iX)
    if _toClipReel then
        -- 替换的图标都提层
        util_setSymbolToClipReel(self,slotsNode.p_cloumnIndex, slotsNode.p_rowIndex, slotsNode.p_sumbolType, 0)
        -- 连线坐标
        local linePos = {}
        linePos[#linePos + 1] = {iX = slotsNode.p_rowIndex, iY = slotsNode.p_cloumnIndex}
        slotsNode.m_bInLine = true
        slotsNode:setLinePos(linePos)
    end
    -- 轮盘小块的坐标向固定图标看齐
    local nodePos     = util_convertToNodeSpace(lockSymbol, slotsNode:getParent())
    slotsNode:setPosition(nodePos)

    self:changeCastFishingSlotsNodeType(slotsNode, symbolType)
    slotsNode:runIdleAnim()
end

-- 断线重连 
function CodeGameScreenCastFishingMachine:initGameStatusData(gameData)
    if gameData.gameConfig.extra ~= nil then
        local extra = gameData.gameConfig.extra
        self.m_collectData = clone(extra.collectData)
        
        self.m_mag:setFishSceneData(extra)
        self.m_mag:setBulletAttr(extra)
        self.m_mag:setSceneFishAttr(extra)
        self.m_mag.m_bShowShape = DEBUG == 2 and 1 == extra.bShowShape
    end
    -- 优先使用BONUS的 selfData,bonusExtra 数据 防止重复触发捕鱼
    if nil ~= gameData.feature then
        local feature = gameData.feature
        local spin    = gameData.spin

        spin.selfData = clone(feature.selfData)
        spin.bonus = clone(feature.bonus)
    end

    CodeGameScreenCastFishingMachine.super.initGameStatusData(self,gameData)
end
function CodeGameScreenCastFishingMachine:MachineRule_initGame()

    if self.m_bProduceSlots_InFreeSpin then
        self.m_freeReconnection = true

        local collectLeftCount  = globalData.slotRunData.freeSpinCount
        local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
        if collectLeftCount ~= collectTotalCount then
            self:changeBgReel(false, false)
            self.m_freeBar:changeFreeSpinByCount()
            self.m_freeBar:setVisible(true)
            self.m_freeBar:playStartAnim()
            self.m_tip:setVisible(false)
            self.m_baseFishView:setVisible(false)
            self.m_baseFishView:stopUpDateTick()
            self.m_freeFishView:setVisible(true)
            self.m_freeFishView:setCreateFishState(true)
            self.m_freeFishView:startUpDateTick()
            self.m_clickEffect:setVisible(false)
        end
        -- free捕鱼
        if self:isTriggerFreeBattery() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_FreeBattery
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_FreeBattery 
        end
    end

    -- bonus
    if self:isTriggerBonusGame() then
        self:saveBonusGameData(true)
    end
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCastFishingMachine:MachineRule_SpinBtnCall()
    self:stopLinesWinSound()
    self:setMaxMusicBGVolume()
    self.m_tip:playOverAnim()
    self.m_enterTips:playOverAnim()
    -- 锁定图标和锁定框在滚动前处理展示
    self:spinBtnUpDateLockSymbol()
    self.m_lockSymbolMag:spinBtnClickCallBack()
    self:setCastFishingReelRunData()

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCastFishingMachine:addSelfEffect()

    if self:isTriggerCollectBonus() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_CollectBonus
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_CollectBonus 
    end

    if self:isTriggerLockSymbol() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_LockSymbol
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_LockSymbol 
    end

    if self:isTriggerFreeBattery() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_FreeBattery
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_FreeBattery 
    end

    if self:isTriggerBonusGame() then
        self:saveBonusGameData(false)
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCastFishingMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_LockSymbol then
        self:playEffect_LockSymbol(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    elseif effectData.p_selfEffectType == self.EFFECT_FreeBattery then
        self:playEffect_FreeBattery(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_CollectBonus then
        -- 不触发玩法时收集不能阻挡spin
        if self:isTriggerBonusGame() then
            self:playEffect_CollectBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        else
            self:playEffect_CollectBonus(nil)
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    
    return true
end

function CodeGameScreenCastFishingMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenCastFishingMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end
function CodeGameScreenCastFishingMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenCastFishingMachine.super.slotReelDown(self)
end

function CodeGameScreenCastFishingMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    收集bonus图标
]]
function CodeGameScreenCastFishingMachine:isTriggerCollectBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local newCollect = selfData.collectData
    local bTrigger = nil ~= newCollect and (self.m_collectData.collect ~= newCollect.collect)

    return bTrigger
end
function CodeGameScreenCastFishingMachine:playEffect_CollectBonus(_fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local newCollect = selfData.collectData
    self.m_collectData = newCollect

    local iPos = self.m_collectData.currCollect[1]
    local fixPos = self:getRowAndColByPos(iPos)
    local slotsNode  = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    local lockNode   = self.m_lockSymbolMag:getLockSymbol(fixPos.iY , fixPos.iX)
    local startPos   = util_convertToNodeSpace(slotsNode, self)
    local endWordPos = self.m_collectBar:getCollectEndPos()
    local endPos     = self:convertToNodeSpace(endWordPos)
    -- 拖尾飞行
    local flyAnim = util_createAnimation("CastFishing_shoujilizi.csb")
    local order = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1
    self:addChild(flyAnim, order)
    util_setCascadeOpacityEnabledRescursion(flyAnim, true)
    flyAnim:setPosition(startPos)
    local particle = flyAnim:findChild("Particle_1")
    particle:setPositionType(0)
    particle:setDuration(-1)
    particle:stopSystem()
    particle:resetSystem()
    
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_collectBar_fly)
    local actMove = cc.MoveTo:create(0.25, endPos)
    local actFun      = cc.CallFunc:create(function()
        particle:stopSystem()
        util_setCascadeOpacityEnabledRescursion(particle, true)
        particle:runAction(cc.FadeOut:create(0.5))

        -- 刷新进度
        local cur = newCollect.collect
        local max = newCollect.request
        if cur == 0 and #newCollect.currCollect > 0 then
            cur = max
        end
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_collectBar_fankui)
        self:updateCollectBar(cur, max, true, _fun)
    end)

    slotsNode:runAnim("shouji", false)
    if lockNode:isVisible() then
        lockNode:runAnim("shouji", false)
    end
    flyAnim:runCsbAction("fly", false)
    flyAnim:runAction(cc.Sequence:create(
        actMove,
        actFun,
        cc.DelayTime:create(0.5),
        cc.RemoveSelf:create()
    ))
end

--[[
    固定图标玩法
]]
function CodeGameScreenCastFishingMachine:isTriggerLockSymbol()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if selfData.respinData then
        local sBetKey = string.format("%d", globalData.slotRunData:getCurTotalBet())
        local curBetReSpinData = self.m_lockSymbolMag:getLockSymbolData()
        local newBetReSpinData = selfData.respinData[sBetKey]
        local bTrigger = nil ~= newBetReSpinData and (nil == curBetReSpinData or curBetReSpinData.leftTimes ~= newBetReSpinData.leftTimes)
        return bTrigger
    end

    return false
end
function CodeGameScreenCastFishingMachine:playEffect_LockSymbol(_fun)
    local data = {
        bHide         = true,
        bPlayAnim     = true,
        nextFun       = _fun,
        bBonusBattery = self:isTriggerBonusGame(),
    }
    self:upDataLockSymbol(data)
end
function CodeGameScreenCastFishingMachine:changeBetUpDateLockSymbol()
    -- spin消息竟然也会有这个通知 并且bet没有发生变化
    local newBetValue = globalData.slotRunData:getCurTotalBet()
    if self.m_curBetValue ~= newBetValue then
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        local data = {
            bHide         = false,
            bPlayAnim     = false,
            nextFun       = nil,
            bBonusBattery = false,
        }
        self:upDataLockSymbol(data)
    end
    self.m_curBetValue = newBetValue
end
function CodeGameScreenCastFishingMachine:spinBtnUpDateLockSymbol()
    local data = {
        bHide         = false,
        bPlayAnim     = true,
        nextFun       = nil,
        bBonusBattery = false,
    }
    self:upDataLockSymbol(data)
end
function CodeGameScreenCastFishingMachine:bonusOverUpDateLockSymbol(_bSpecial)
    local data = {
        bHide         = false,
        bPlayAnim     = false,
        nextFun       = nil,
    }
    -- 触发普通bonus玩法时必定清空次数 (用触发标记规避读取selfData的数据)
    -- 特殊bonus则保留固定图标次数     (可以正常读取selfData数据)
    data.bBonusBattery = not _bSpecial
    
    self:upDataLockSymbol(data)
end
-- 刷新固定图标位置 @_bHide : 只触发隐藏
function CodeGameScreenCastFishingMachine:upDataLockSymbol(_data)
    --[[
        data = {
            bHide         = false,   是否只检测隐藏
            bPlayAnim     = false,   是否播放动效
            nextFun       = nil,     下一步
            bBonusBattery = false,   是否触发了bonus
        }
    ]]
    local newBetReSpinData = nil
    local selfData   = self.m_runSpinResultData.p_selfMakeData or {}
    local respinData = selfData.respinData or {}
    local sBetKey = string.format("%d", globalData.slotRunData:getCurTotalBet())
    newBetReSpinData = respinData[sBetKey]
    self.m_lockSymbolMag:setLockSymbolData(newBetReSpinData)

    local bVisible        = nil ~= newBetReSpinData and newBetReSpinData.leftTimes > 0
    local bFreeGameEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    local bBonusBattery   = _data.bBonusBattery

    -- 当前有剩余次数并且没有触发玩法
    if bVisible and (not bFreeGameEffect and not bBonusBattery) then
        -- 只能触发隐藏时不修改展示
        if not _data.bHide then
            self.m_lockSymbolMag:showLockSymbol(_data.bPlayAnim, _data.nextFun)
        else
            if nil ~= _data.nextFun then
                _data.nextFun()
            end
        end
    -- 当前应该隐藏并且正在展示
    else
        local isVisible = self.m_lockSymbolMag:isLockSymbolVisible()
        --隐藏固定图标
        if isVisible then
            -- 固定次数在这一次spin中用尽 或者 触发了玩法，将固定图标替换到棋盘上
            local bReplace = nil ~= newBetReSpinData
            if bReplace then
                local lockData = newBetReSpinData
                self:lockSymbolReplaceNode(lockData, true)
            end
            self.m_lockSymbolMag:hideLockSymbol(_data.bPlayAnim, _data.nextFun)
        else
            if nil ~= _data.nextFun then
                _data.nextFun()
            end
        end
    end
end

--[[
    FreeSpin相关
]]
-- 显示free spin
function CodeGameScreenCastFishingMachine:showEffect_FreeSpin(effectData)
    local delayTime = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) and 1.1 or 0
    self:levelPerformWithDelay(self, delayTime, function()
        self.m_beInSpecialGameTrigger = true
        -- 取消掉赢钱线的显示
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearWinLineEffect()
        -- !!!不使用连线列表
        local lineLen = #self.m_reelResultLines
        local scatterLineValue = nil
        -- for i = 1, lineLen do
        --     local lineValue = self.m_reelResultLines[i]
        --     if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        --         scatterLineValue = lineValue
        --         table.remove(self.m_reelResultLines, i)
        --         break
        --     end
        -- end

        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end
        end
        if scatterLineValue ~= nil then
            --
            self:showBonusAndScatterLineTip(
                scatterLineValue,
                function()
                    self:showFreeSpinView(effectData)
                end
            )
            scatterLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        else
            self:showFreeSpinView(effectData)
        end
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end)
    
    return true
end

function CodeGameScreenCastFishingMachine:showFreeSpinView(effectData)
    -- !!!不会有freeMore
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,true)
    else
        local fnNext = function()
            -- 弹板
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeStartView_start)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self.m_baseFishView:changeFishObjStateAnimName({
                    bALl     = true,
                    state    = "move",
                    animName = "idle2",
                    play     = true,
                })
                self.m_baseFishView:changeFishObjSpeed({
                    bALl         = true,
                    configMultip = self.m_baseFishView.SceneConfig.FishLeaveMultip
                })
                self.m_baseFishView:setCreateFishState(false)
                gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeGuoChang)
                --过场
                self:playGuoChangAnim(
                    function()
                        -- 切换展示
                        self:changeBgReel(false, true)
                        self.m_freeBar:changeFreeSpinByCount()
                        self.m_freeBar:setVisible(true)
                        self.m_freeBar:playStartAnim()
                        self.m_tip:setVisible(false)
                        self.m_baseFishView:setVisible(false)
                        self.m_baseFishView:stopUpDateTick()
                        self.m_freeFishView:setVisible(true)
                        self.m_freeFishView:setCreateFishState(true)
                        self.m_freeFishView:startUpDateTick()
                        self.m_clickEffect:setVisible(false)
                        util_spinePlay(self.m_bgSpine, "idleframe2", true)
                    end,
                    function()
                        self:triggerFreeSpinCallFun()

                        effectData.p_isPlay = true
                        self:playGameEffect()    
                    end
                )
            end)
            view:setBtnClickFunc(function()
                gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeStartView_over)
            end)
        end

        -- 锁定图标播触发
        if not self.m_freeReconnection then
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_ScatterTip)
            self:playLockSymbolActionFrameAnim(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, fnNext)
        else
            fnNext()
        end
        self.m_freeReconnection = false
    end
end

function CodeGameScreenCastFishingMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeOverView_start)
    -- 鱼群退场
    self.m_freeFishView:changeFishObjStateAnimName({
        bALl     = true,
        state    = "move",
        animName = "idle2",
        play     = true,
    })
    self.m_freeFishView:changeFishObjSpeed({
        bALl         = true,
        configMultip = self.m_baseFishView.SceneConfig.FishLeaveMultip
    })
    self.m_freeFishView:setCreateFishState(false)

    local bottomWinCoins = self:getnCastFishingCurBottomWinCoins()
    local strCoins = util_formatCoins(self.m_runSpinResultData.p_fsWinCoins, 50)
    local view = self:showFreeSpinOver( 
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeOverGuoChang)
            self:playGuoChangAnim(
                function()
                    -- 切换展示
                    self:changeBgReel(true, false)
                    self.m_freeBar:playOverAnim(function()
                        self.m_freeBar:setVisible(false)
                    end)
                    self.m_tip:setVisible(true)
                    self.m_baseFishView:setCreateFishState(true)
                    self.m_baseFishView:setVisible(true)
                    self.m_baseFishView:startUpDateTick()
                    
                    self.m_freeFishView:endFreeGamePushAllFishObj()
                    self.m_freeFishView:setVisible(false)
                    self.m_freeFishView:stopUpDateTick()
                    self.m_clickEffect:setVisible(true)
                    util_spinePlay(self.m_bgSpine, "idleframe", true)  
                end,
                function()
                    self:triggerFreeSpinOverCallFun()
                end
            )
        end
    )
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_freeOverView_over)
    end)
    view:updateLabelSize({label=view:findChild("m_lb_coins"),sx=0.82,sy=0.97}, 773)
    view:updateLabelSize({label=view:findChild("m_lb_num"),sx=1.6,sy=1.85}, 42)
end

--[[
    free中开炮的玩法
]]
function CodeGameScreenCastFishingMachine:isTriggerFreeBattery()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    if fsExtraData.isWaitingFree then
        return true
    end
    
    return false
end
function CodeGameScreenCastFishingMachine:playEffect_FreeBattery(_fun)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local fishingResult = fsExtraData.bonusType

    --启动free捕鱼，返回一个碰到的鱼列表
    local startData = {
        fishingResult,
        function(_fishObjList)
            local fishObj     = _fishObjList[1]

            --有了子弹结果存一下数据发送请求
            self.m_freeFishingData = {}
            self.m_freeFishingData.fishObjList = _fishObjList
            self.m_freeFishingData.bNext = true
            self.m_freeFishingData.nextFun = function()
                self.m_freeFishingData = nil
                self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
                _fun()
            end
            -- 炮台退场
            self.m_freeBatteryList:setVisible(false)
            -- 金币鱼直接飞结果衔接后面的表现流程
            if nil ~= fishObj then
                if fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Coins then
                    self.m_freeFishingData.bNext = false
                    local multip = fishObj.m_data.multip
                    local serverData = {}
                    serverData.selfData = {}
                    serverData.selfData.fishWins = multip * globalData.slotRunData:getCurTotalBet()
                    self:playFishingAnim_coins(self.m_freeFishingData, serverData, function()
                        if not self.m_freeFishingData.bNext then
                            self.m_freeFishingData.bNext = true
                        else
                            self.m_freeFishingData.nextFun()
                        end
                    end)
                -- wild鱼 
                elseif fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Wild then
                    self.m_freeFishingData.bNext = false
                    local selfData = self.m_runSpinResultData.p_selfMakeData
                    local serverData = {}
                    serverData.selfData = {}
                    serverData.selfData.wildLocs = selfData.wildLocs
                    self:playFishingAnim_wild(self.m_freeFishingData, serverData, function()
                        if not self.m_freeFishingData.bNext then
                            self.m_freeFishingData.bNext = true
                        else
                            self.m_freeFishingData.nextFun()
                        end
                    end)
                end
            else
            --jackpot鱼 等服务器数据
            end

            self.m_mag:sendFreeFishingResult(_fishObjList)
        end
    }

    -- 轮盘图标播触发
    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_BonusTip)
    for iRow=1,self.m_iReelRowNum do
        local symbol =  self:getFixSymbol(3, iRow)
        if self.SYMBOL_Bonus == symbol.p_symbolType then
            if self.m_clipParent ~= symbol:getParent() then
                --断线重连时提层
                util_setSymbolToClipReel(self,symbol.p_cloumnIndex, symbol.p_rowIndex, symbol.p_sumbolType, 0)
                -- 连线坐标
                local linePos = {}
                linePos[#linePos + 1] = {iX = symbol.p_rowIndex, iY = symbol.p_cloumnIndex}
                symbol.m_bInLine = true
                symbol:setLinePos(linePos)
            end
            symbol:runAnim("actionframe2", false)
        end
    end
    self:levelPerformWithDelay(self, 60/30, function()
        self.m_freeBatteryList:setVisible(true)
        self.m_freeBatteryList:startGame(startData)
    end)
end
function CodeGameScreenCastFishingMachine:playEffect_FreeBatteryOver(_params)
    -- 重置连线数据
    self:resetCastFishingLineData(_params)
    -- 重置大赢事件
    self:resetCastFishingFreeFishingBigWin(_params)
    -- 重置fs总赢钱
    self.m_runSpinResultData.p_fsWinCoins = _params.fsWinCoins

    -- 区分 金币鱼、wild鱼、jackpt鱼 流程
    local fishObjList = self.m_freeFishingData.fishObjList
    local fishObj     = fishObjList[1]

    if (nil ~= fishObj) and 
        (fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Coins or  
        fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Wild) then 

        if not self.m_freeFishingData.bNext then
            self.m_freeFishingData.bNext = true
        else
            self.m_freeFishingData.nextFun()
        end
    else
        self:playBatteryOverAnim(fishObjList, self.m_freeFishingData, _params, self.m_freeFishingData.nextFun)
    end
end
function CodeGameScreenCastFishingMachine:playBatteryOverAnim(_fishObjList, _fishingData, _serverData, _fun)
    local selfData = _serverData.selfData
    -- 分配一下
    if selfData.fishKind == CastFishingSceneConfig.FishKindType.Coins then
        self:playFishingAnim_coins(_fishingData, _serverData, _fun)
    elseif selfData.fishKind == CastFishingSceneConfig.FishKindType.Wild then
        self:playFishingAnim_wild(_fishingData, _serverData, _fun)
    elseif selfData.fishKind == CastFishingSceneConfig.FishKindType.Jackpot then
        self:playFishingAnim_jackpot(1, _fishingData, _serverData, _fun)
    --没中
    else
        _fun()
    end
end
function CodeGameScreenCastFishingMachine:hideFishObjList(_fishObjList)
    for i,_fishObj in ipairs(_fishObjList) do
        _fishObj:setVisible(false)
        -- 有些事件会修改透明度
        _fishObj.m_fishParent:setVisible(true)
        _fishObj.m_fishParent:setOpacity(255)
    end
end
function CodeGameScreenCastFishingMachine:playFishingAnim_coins(_fishingData, _serverData, _fun)
    local selfData     = _serverData.selfData
    local fishWinCoins = selfData.fishWins
    local bBonus       = _fishingData.bBonus
    local bLaser       = _fishingData.bLaser
    local fishObjList  = _fishingData.fishObjList
    local collectAnimName = bLaser and "shouji2" or "shouji"
    
    local nextFun = function()
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_coinFish_fly)

        for i,_fishObj in ipairs(fishObjList) do
            local bPlay = 1 == i
            local startPos = util_convertToNodeSpace(_fishObj.m_coinsLab, self)
            local endPos   = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self)
            local flyAnim  = util_createAnimation("CastFishing_jine.csb")
            local order = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1
            self:addChild(flyAnim, order)
            flyAnim:setScale(self.m_machineRootScale)
            flyAnim:setPosition(startPos)
            local str = _fishObj.m_coinsLab:getString()
            local labCoins = flyAnim:findChild("m_lb_coins")
            labCoins:setString(str)
            local particle = flyAnim:findChild("Particle_1")
            particle:setPositionType(0)
            particle:setDuration(-1)
            particle:stopSystem()
            particle:resetSystem()
            _fishObj:changeRewardShow(false)
        
            -- 金钱收集
            local distance = math.sqrt( math.pow((endPos.x - startPos.x), 2) + math.pow((endPos.y - startPos.y), 2))
            local radius = distance/2
            local flyAngle = util_getAngleByPos(startPos, endPos)
            local offsetAngle = endPos.x > startPos.x and 135 or -135
            local pos1 = cc.p((startPos.x + endPos.x)/2, startPos.y + 100)
            local pos2 = cc.p((pos1.x + endPos.x)/2 , (pos1.y + endPos.y)/2)
            local actBezierTo = cc.BezierTo:create(30/60, {pos1, pos2, endPos})
            flyAnim:runCsbAction(collectAnimName,false)
            flyAnim:runAction(cc.Sequence:create(
                actBezierTo,
                cc.CallFunc:create(function()
                    labCoins:setVisible(false)
                    particle:stopSystem()
                    util_setCascadeOpacityEnabledRescursion(particle, true)
                    particle:runAction(cc.FadeOut:create(0.5))
                    if bPlay then
                        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_coinFish_flyEnd)
                        self:playCoinWinEffectUI()
                        local bottomWinCoin = self:getnCastFishingCurBottomWinCoins()
                        local lineWinCoins      = self:getClientWinCoins()
                        self.m_iOnceSpinLastWin = lineWinCoins
                        self:setLastWinCoin(bottomWinCoin + fishWinCoins)
                        self:updateBottomUICoins(0, fishWinCoins, nil, true, false)

                        local showTime = bBonus and 0 or self.m_bottomUI:getCoinsShowTimes(fishWinCoins)
                        self:levelPerformWithDelay(self, showTime, function()
                            self:hideFishObjList(fishObjList)
                            if _fun then
                                _fun()
                            end
                        end)
                    end
                end),
                -- 粒子延时消失
                cc.DelayTime:create(0.5),
                cc.RemoveSelf:create()
            ))
        end
    end

    if bLaser then
        for i,_fishObj in ipairs(fishObjList) do
            local bPlay = 1 == i
            _fishObj:playLaserCollectFadeOut(nil, function()
                if bPlay then 
                    nextFun()
                end
            end)
        end
    else
        nextFun()
    end
end
function CodeGameScreenCastFishingMachine:playFishingAnim_wild(_fishingData, _serverData, _fun)
    local fishObjList = _fishingData.fishObjList
    local fishObj     = fishObjList[1]
    local oldParent   = fishObj:getParent()
    local startPos    = util_convertToNodeSpace(fishObj, self)
    local targetNode  = self:getFixSymbol(3, 2)
    local endPos      = util_convertToNodeSpace(targetNode, fishObj:getParent())

    gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_wildFish_fly)
    fishObj:playStateAnim_collect(nil)
    local actList = {}
    --飞行
    -- 收集第 3~21 帧播放飞行
    table.insert(actList, cc.DelayTime:create(3/30))
    table.insert(actList, cc.MoveTo:create(18/30, endPos))
    -- wild出现
    table.insert(actList, cc.CallFunc:create(function()
        fishObj:changeRewardShow(false)
        local selfData = _serverData.selfData
        local lockData = selfData.wildLocs
        for i,_wildPos in ipairs(lockData) do
            local fixPos = self:getRowAndColByPos(_wildPos)
            local slotsNode = self:getFixSymbol(fixPos.iY, fixPos.iX)
            self:changeCastFishingSlotsNodeType(slotsNode, TAG_SYMBOL_TYPE.SYMBOL_WILD)
            slotsNode:runAnim("start")
        end
    end))
    -- 棋盘反馈
    local wildAnimTime = util_csbGetAnimTimes(self.m_wildFankuiCsb.m_csbAct, "fankui")
    table.insert(actList, cc.CallFunc:create(function()
        self.m_wildFankuiCsb:setVisible(true)
        self.m_wildFankuiCsb:runCsbAction("fankui", false, function()
            self.m_wildFankuiCsb:setVisible(false)
        end)
    end))
    table.insert(actList, cc.DelayTime:create(wildAnimTime))
    -- 下一步
    table.insert(actList, cc.CallFunc:create(function()
        self:hideFishObjList(fishObjList)
        _fun()
    end))

    fishObj:runAction(cc.Sequence:create(actList))
end
function CodeGameScreenCastFishingMachine:resetCastFishingLineData(_serverData)
    local bLineEffect = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME)
    self:clearWinLinesData()
    self.m_runSpinResultData:parseWinLines(_serverData, self.m_lineDataPool)
    self:checkAndClearVecLines()
    self:lineLogicWinLines()
    self:insterReelResultLines()
    -- 没有连线事件 添加事件
    if not bLineEffect then
        self:addLineEffect()
        self:sortGameEffects()
    end
    local lineWinCoins      = self:getClientWinCoins() 
    self.m_iOnceSpinLastWin = lineWinCoins
end
function CodeGameScreenCastFishingMachine:resetCastFishingFreeFishingBigWin(_serverData)
    local selfData     = _serverData.selfData
    local lineWinCoins = self:getClientWinCoins()
    local fishWinCoins = selfData.fishWins
    local winCoins     = lineWinCoins + fishWinCoins
    -- 移除所有大赢事件
    local bigWinEffectList = {
        GameEffect.EFFECT_EPICWIN,
        GameEffect.EFFECT_MEGAWIN,
        GameEffect.EFFECT_BIGWIN,
    }
    for i,_effectType in ipairs(bigWinEffectList) do
        self:removeGameEffectType(_effectType)
    end
    -- 重新计算大赢事件 参考: BaseMachine:addLastWinSomeEffect()
    local bigWinEffect = self:getWinEffect(winCoins)
    if nil ~= bigWinEffect then
        self.m_llBigOrMegaNum = winCoins
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)

        local rewardEffect = GameEffectData.new()
        rewardEffect.p_effectType  = bigWinEffect
        rewardEffect.p_effectOrder = bigWinEffect
        self.m_gameEffects[#self.m_gameEffects + 1] = rewardEffect
        self:sortGameEffects()
    end
end
function CodeGameScreenCastFishingMachine:clearWinLinesData()
    local runSpinResultData = self.m_runSpinResultData
    if runSpinResultData.p_winLines ~= nil then
        for i = #runSpinResultData.p_winLines, 1, -1 do
            local lineData = runSpinResultData.p_winLines[i]
            if self.m_lineDataPool ~= nil then
                self.m_lineDataPool[#self.m_lineDataPool + 1] = lineData
            end
            runSpinResultData.p_winLines[i] = nil
        end
    end
end
function CodeGameScreenCastFishingMachine:playFishingAnim_jackpot(_animIndex, _fishingData, _serverData, _fun)
    local fishObjList = _fishingData.fishObjList
    local selfData    = _serverData.selfData
    local jackpotList = selfData.jackpotLines
    local jackpotData = jackpotList[_animIndex]
    if not jackpotData then
        self:hideFishObjList(fishObjList)
        self:playJackpotMusic(false)
        _fun()
        return
    end
    if 1 == _animIndex then
        self:playJackpotMusic(true)
    end
    
    local winCoins = jackpotData.amount
    local jpIndexList = {
        grand = 1,
        mega = 2,
        major = 3,
        minor = 4,
        mini = 5,
    }
    local jpIndex  = jpIndexList[jackpotData.jackpot]
    self.m_iOnceSpinLastWin = self:getClientWinCoins() + winCoins
    local fishObj = fishObjList[_animIndex]
    local bLaser = _fishingData.bLaser
    local collectAnimName = bLaser and "shouji4" or "shouji"

    -- 等一轮收集时间线结束时
    fishObj:registerSpineAnimCallBack(fishObj:getStateAnimName_collect(), function()
        -- 鱼的收集反馈
        fishObj:setStateAnimName_collect(collectAnimName)
        fishObj:playStateAnim_collect(nil)
        -- 墨汁
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_mozhiGuoChang)
        self.m_mozhiSpine:setVisible(true)
        util_spinePlay(self.m_mozhiSpine, "mozhi2", false)
        util_spineEndCallFunc(self.m_mozhiSpine, "mozhi2", function()
            self.m_mozhiSpine:setVisible(false)
        end) 
        -- 墨汁第帧覆盖全屏
        self:levelPerformWithDelay(self, 24/30, function()
            -- jackpot转盘
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_jackpotWheel_start)
            local viewData = {}
            viewData.jackpotData = jackpotData
            viewData.overFun = function()
                self:showJackpotView(winCoins, jpIndex, function()
                    self:playFishingAnim_jackpot(_animIndex+1, _fishingData, _serverData, _fun)
                end)
            end
            local wheelView = util_createView("CodeCastFishingSrc.CastFishingWheel.CastFishingWheelView", viewData)
            self:addChild(wheelView, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 5)
            wheelView:setPosition(display.width/2,display.height/2)
            wheelView:setScale(self.m_machineRootScale)
            -- gLobalViewManager:showUI(wheelView, ViewZorder.ZORDER_UI)
        end)
        -- 清理自身附带的其他对象列表
        fishObj:clearFishNetObjList()
    end)
end
function CodeGameScreenCastFishingMachine:playJackpotMusic(_bStart)
    local musicPath = ""
    if _bStart then
        musicPath = "CastFishingSounds/music_CastFishing_jackpot.mp3"
    else
        if nil ~= self.m_bonusGameData then
            local musicName = self.m_bonusGameData.bSpecial and "music_CastFishing_bonus" or "music_CastFishing_specialBonus"
            musicPath = string.format("CastFishingSounds/%s.mp3", musicName)
        else
            musicPath = "CastFishingSounds/music_CastFishing_free.mp3"
        end
    end
    self:resetMusicBg(nil, musicPath)                    
end

-- 展示jackpot弹板
function CodeGameScreenCastFishingMachine:showJackpotView(_coins, _jackpotIndex, _fun)
    local soundList = {
        [1] = CastFishingMusicConfig.sound_CastFishing_jackpot_grand,
        [2] = CastFishingMusicConfig.sound_CastFishing_jackpot_mega,
        [3] = CastFishingMusicConfig.sound_CastFishing_jackpot_major,
        [4] = CastFishingMusicConfig.sound_CastFishing_jackpot_minor,
        [5] = CastFishingMusicConfig.sound_CastFishing_jackpot_mini,
    }
    local soundName = soundList[_jackpotIndex]
    gLobalSoundManager:playSound(soundName)

    local curMode = self:getCurrSpinMode()
    local data = {
        machine      = self,
        coins        = _coins,
        jackpotIndex = _jackpotIndex,
    }
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(_coins, _jackpotIndex)
    local jackPotWinView = util_createView("CodeCastFishingSrc.CastFishingJackPotView", data)
    jackPotWinView:setOverAniRunFunc(_fun)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData()

    local bottomWinCoin = self:getnCastFishingCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + _coins)
    self:updateBottomUICoins(0, _coins, nil, true, false)
end
-- free最后一次触发捕鱼后立刻断线重连处理
--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenCastFishingMachine:checkTriggerINFreeSpin()
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
    --!!! 触发了free捕鱼
    local bFreeBattery = self:isTriggerFreeBattery()


    local isInFs = false
    if
        hasFreepinFeature == false and self.m_initSpinData.p_freeSpinsTotalCount ~= nil and self.m_initSpinData.p_freeSpinsTotalCount > 0 and
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or (hasReSpinFeature == true or hasBonusFeature == true or bFreeBattery == true))
     then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
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

--[[
    bonus捕鱼
]]
function CodeGameScreenCastFishingMachine:isTriggerBonusGame()
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    local bTrigger = "OPEN" == bonusStatus
    return bTrigger
end
function CodeGameScreenCastFishingMachine:initFeatureInfo(spinData, featureData)
    if self:isTriggerBonusGame() then
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS

        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    end
end

-- 展示jackpot弹板
function CodeGameScreenCastFishingMachine:showBonusStartView(_bSpecial,_fun)
    local csbName = _bSpecial and "SuperUpshotStart" or "UpshotStart"
    local view = self:showDialog(csbName, nil, _fun)
    view:setBtnClickFunc(function()
        if _bSpecial then
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonusStartView_over)
        else
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_commonBonusStartView_over)
        end
    end)
end
function CodeGameScreenCastFishingMachine:showBonusOverView(_winCoins, _fun)
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(_winCoins, 50) 
    local view = self:showDialog("SuperUpshotUpshotOver", ownerlist, _fun)
    view:updateLabelSize({label=view:findChild("m_lb_coins"),sx=0.82,sy=0.97}, 773)

end
---
-- 显示bonus 触发的小游戏
function CodeGameScreenCastFishingMachine:showEffect_Bonus(effectData)
    local delayTime = self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) and 1.1 or 0
    self:levelPerformWithDelay(self, delayTime, function()
        self.m_beInSpecialGameTrigger = true
        if globalData.slotRunData.currLevelEnter == FROM_QUEST then
            self.m_questView:hideQuestView()
        end
        --停止连线
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearFrames_Fun()
        -- !!!不使用连线数据
        -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
        local lineLen = #self.m_reelResultLines
        local bonusLineValue = nil
        -- for i = 1, lineLen do
        --     local lineValue = self.m_reelResultLines[i]
        --     if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
        --         bonusLineValue = lineValue
        --         table.remove(self.m_reelResultLines, i)
        --         break
        --     end
        -- end
        -- 停止播放背景音乐
        self:clearCurMusicBg()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        -- 播放bonus 元素不显示连线
        if bonusLineValue ~= nil then
            self:showBonusAndScatterLineTip(
                bonusLineValue,
                function()
                    self:showBonusGameView(effectData)
                end
            )
            bonusLineValue:clean()
            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
    
            -- 播放提示时播放音效
            self:playBonusTipMusicEffect()
        else
            self:showBonusGameView(effectData)
        end

        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
    end)

    return true
end

function CodeGameScreenCastFishingMachine:showBonusGameView(effectData)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local bonusGameData = self:getBonusGameData()
    self.m_bonusFishView:setBonusGameData(bonusGameData)

    local nextFun = function()
        -- 开始弹板
        if bonusGameData.bSpecial then
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonusStartView)
        else
            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_commonBonusStartView)
        end
        self:showBonusStartView(bonusGameData.bSpecial, function()
            self.m_baseFishView:changeFishObjStateAnimName({
                bALl     = true,
                state    = "move",
                animName = "idle2",
                play     = true,
            })
            self.m_baseFishView:changeFishObjSpeed({
                bALl         = true,
                configMultip = self.m_baseFishView.SceneConfig.FishLeaveMultip
            })
            self.m_baseFishView:setCreateFishState(false)

            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonusGuoChang)
            --过场
            self:playGuoChangAnim(
                function()
                    -- 切换展示
                    if bonusGameData.bSpecial then
                        self.m_collectAvgBet = bonusGameData.specialAvgBet
                        self.m_bottomUI:showAverageBet()
                        self:updateCollectBar(0, 50, false, nil)
                    end
                    self.m_bottomUI:resetWinLabel()
                    self.m_bottomUI:checkClearWinLabel()
                    self:setLastWinCoin(bonusGameData.bonusWinCoins)
                    self:updateBottomUICoins(0, bonusGameData.bonusWinCoins, false, false, false)
                    self.m_tip:setVisible(false)
                    self:findChild("qipan"):setVisible(false)
                    self.m_baseFishView:setVisible(false)
                    self.m_baseFishView:stopUpDateTick()
                    self.m_jackpotBar:enterBonusHideJackpotBar()
                    self.m_clickEffect:setVisible(false)
                    self.m_bonusFishView.m_batteryList:upDateBatteryType()
                    self.m_bonusFishView.m_batteryList:playGrayIdleAnim()
                    self.m_bonusFishView:setVisible(true)
                    
                end,
                function()
                    local musicName = bonusGameData.bSpecial and "music_CastFishing_bonus" or "music_CastFishing_specialBonus"
                    local musicPath = string.format("CastFishingSounds/%s.mp3", musicName)
                    self:resetMusicBg(nil, musicPath)
                    self.m_bonusFishView:startBonusGame(function(_winCoins)
                        -- 刷新赢钱检测大赢 和顶部玩家金币
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{_winCoins, GameEffect.EFFECT_BONUS})
                        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{_winCoins,false,false,true})
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                        -- 鱼群退场
                        self.m_bonusFishView:changeFishObjStateAnimName({
                            lessIndex = self.m_bonusFishView.SceneConfig.MaxPool + 1,
                            state     = "move",
                            animName  = "idle2",
                            play      = true,
                        })
                        self.m_bonusFishView:changeFishObjSpeed({
                            lessIndex = self.m_bonusFishView.SceneConfig.MaxPool + 1,
                            configMultip = self.m_bonusFishView.SceneConfig.FishLeaveMultip
                        })

                        -- 停掉背景音乐
                        self:clearCurMusicBg()
                        -- 结束弹板
                        if bonusGameData.bSpecial then
                            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonusOverView)
                        else
                            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_commonBonusOverView)
                        end
                        self:showBonusOverView(_winCoins,function()
                            --过场
                            gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_superBonusOverGuoChang)
                            self:playGuoChangAnim(
                                function()
                                    -- 切换展示
                                    self.m_collectAvgBet = nil
                                    if bonusGameData.bSpecial then
                                        self.m_bottomUI:hideAverageBet()
                                    end
                                    self.m_tip:setVisible(true)
                                    self:findChild("qipan"):setVisible(true)
                                    self.m_baseFishView:setCreateFishState(true)
                                    self.m_baseFishView:setVisible(true)
                                    self.m_baseFishView:startUpDateTick()
                                    self.m_jackpotBar:leaveBonusShowJackpotBar()
                                    self.m_clickEffect:setVisible(true)
                                    self:bonusOverUpDateLockSymbol(bonusGameData.bSpecial)
                                    self.m_bonusFishView:endBonusGamePushAllFishObj()
                                    self.m_bonusFishView:stopUpDateTick()
                                    self.m_bonusFishView:setVisible(false)
                                end,
                                function()
                                    self:resetMusicBg()
                                    self.m_bonusGameData = nil

                                    effectData.p_isPlay= true
                                    self:playGameEffect()
                                end
                            )
                        end)
                        
                    end)  
                end
            )
        end)
    end

    -- 锁定图标播触发 super和断线不播
    if not bonusGameData.bSpecial and not bonusGameData.bReconnect then
        gLobalSoundManager:playSound(CastFishingMusicConfig.sound_CastFishing_commonBonusTip)
        self:playLockSymbolActionFrameAnim(self.SYMBOL_SpecialBonus, nextFun)
    else
        nextFun()
    end
end
function CodeGameScreenCastFishingMachine:saveBonusGameData(_bReconnect)
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra

    self.m_bonusGameData = {}
    
    self.m_bonusGameData.bSpecial   = "normal" ~= bonusExtra.kind
    self.m_bonusGameData.specialAvgBet   = bonusExtra.avgBet or 0
    
    self.m_bonusGameData.bReconnect = _bReconnect

    self.m_bonusGameData.bonusWinCoins = self.m_runSpinResultData.p_bonusWinCoins or 0
    self.m_bonusGameData.fishingResult = bonusExtra.bonusType
    self.m_bonusGameData.leftTimes     = clone(bonusExtra.leftTimes)
end
function CodeGameScreenCastFishingMachine:changeBonusGameData(_serverData)
    local bonusExtra = _serverData.bonus.extra
    self.m_bonusGameData.bonusWinCoins = _serverData.bonus.bsWinCoins
    self.m_bonusGameData.fishingResult = bonusExtra.bonusType
    self.m_bonusGameData.leftTimes     = clone(bonusExtra.leftTimes)
end

function CodeGameScreenCastFishingMachine:getBonusGameData()
    return self.m_bonusGameData
end
-- bonus子弹离场回调
function CodeGameScreenCastFishingMachine:bonusBulletOverCallBack(_params)
    local fishObjList = _params.fishObjList
    local fishObj     = fishObjList[1]
    local isCoinsFish = nil ~= fishObj and fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Coins
    --有了子弹结果存一下数据发送请求
    self.m_bonusFishingData = _params
    self.m_bonusFishingData.bNext = not isCoinsFish
    local nextFun = self.m_bonusFishingData.nextFun
    self.m_bonusFishingData.nextFun = nil
    self.m_bonusFishingData.nextFun = function()
        self.m_bonusFishingData = nil
        nextFun()
    end
    
    
    -- 金币鱼直接飞结果衔接后面的表现流程
    if isCoinsFish then
        local serverData = {}
        serverData.selfData = {}
        serverData.selfData.fishWins = 0
        for i,_fishObj in ipairs(fishObjList) do
            local multip   = _fishObj.m_data.multip
            local winCoins = multip * self:getCastFishingCurBet()
            serverData.selfData.fishWins = serverData.selfData.fishWins + winCoins
        end
        self:playFishingAnim_coins(self.m_bonusFishingData, serverData, function()
            if not self.m_bonusFishingData.bNext then
                self.m_bonusFishingData.bNext = true
            else
                self.m_bonusFishingData.nextFun()
            end
        end)
    -- wild鱼 和 jackpot鱼 等服务器数据
    else
    end

    self.m_mag:sendBonusFishingResult(_params.fishObjList)
end
function CodeGameScreenCastFishingMachine:playEffect_BonusBatteryOver(_serverData)
    -- 重置数据
    self:changeBonusGameData(_serverData)
    -- 覆盖本地的固定图标数据
    local selfData   = self.m_runSpinResultData.p_selfMakeData or {}
    if nil ~= selfData.respinData and nil ~= _serverData.selfData.respinData then
        selfData.respinData = _serverData.selfData.respinData
    end

    -- 区分金币鱼和其他鱼的流程
    local fishObjList = self.m_bonusFishingData.fishObjList
    local fishObj     = fishObjList[1]
    local isCoinsFish = nil ~= fishObj and fishObj.m_config.level == CastFishingSceneConfig.FishLevelType.Coins
    if isCoinsFish then 
        if not self.m_bonusFishingData.bNext then
            self.m_bonusFishingData.bNext = true
        else
            self.m_bonusFishingData.nextFun()
        end
    else
        self:playBatteryOverAnim(fishObjList, self.m_bonusFishingData, _serverData, self.m_bonusFishingData.nextFun)
    end
end

--[[
    一些工具
]]
function CodeGameScreenCastFishingMachine:changeCastFishingSlotsNodeType(_slotsNode, _symbolType)
    local ccbName = self:getSymbolCCBNameByType(self, _symbolType)
    _slotsNode:changeCCBByName(ccbName, _symbolType)
    _slotsNode:changeSymbolImageByName(ccbName)

    local order   = self:getBounsScatterDataZorder(_symbolType)
    _slotsNode.p_showOrder = order
    _slotsNode.m_showOrder = order
    _slotsNode:setLocalZOrder(order)
end
-- 循环处理轮盘小块
function CodeGameScreenCastFishingMachine:baseReelSlotsNodeForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if isJumpFun then
                return
            end
        end
    end
end
-- 延时
function CodeGameScreenCastFishingMachine:levelPerformWithDelay(_parent, _time, _fun)
    if _time <= 0 then
        _fun()
        return
    end

    local waitNode = cc.Node:create()
    _parent:addChild(waitNode)
    performWithDelay(waitNode,function()

        _fun()

        waitNode:removeFromParent()
    end, _time)

    return waitNode
end
--BottomUI接口
function CodeGameScreenCastFishingMachine:getnCastFishingCurBottomWinCoins()
    local winCoin = 0

    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
        if "" == sCoins then
            return winCoin
        end
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end
function CodeGameScreenCastFishingMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--[[
    快滚
]]
function CodeGameScreenCastFishingMachine:setCastFishingReelRunData()
    local colList = {2, 4} 
    self.m_reelRunColData = {}
    -- 当前场上2,4列是否有固定图标
    if self.m_lockSymbolMag:isLockSymbolVisible() then
        local lockData = self.m_lockSymbolMag:getLockSymbolData()
        local lockPos  = lockData.loc
        local fixPos   = self:getRowAndColByPos(lockPos)
        local reelRunCol  = colList[1] == fixPos.iY and colList[2] or colList[1]
        local bScatter = "sc" == lockData.kind
        self.m_reelRunColData.reelRunCol = reelRunCol
        self.m_reelRunColData.bScatter = bScatter
        self.m_lockSymbolMag:showReelRunAnim(reelRunCol, bScatter)
    end
end
-- 关卡重写方法
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCastFishingMachine:MachineRule_ResetReelRunData()
    local reelRunCol = self.m_reelRunColData.reelRunCol
    -- 当前场上2,4列是否有固定图标
    if nil ~= reelRunCol then
        -- for iCol=reelRunCol,self.m_iReelColumnNum do
        --     local reelRunData = self.m_reelRunInfo[iCol]
        --     local columnData = self.m_reelColDatas[iCol]
        --     local colHeight = columnData.p_slotColumnHeight
        --     local lastRunData = self.m_reelRunInfo[iCol - 1]
        --     local lastRunLen = lastRunData:getReelRunLen()
        --     local runLen = 0

        --     if iCol == reelRunCol then
        --         local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight
        --         runLen = lastRunLen + math.floor( reelCount ) * columnData.p_showGridCount
        --         reelRunData:setReelRunLen(runLen)
        --     else
        --         local reelCount = (0.2 * self.m_configData.p_reelLongRunSpeed) / colHeight
        --         runLen = lastRunLen + math.floor( reelCount ) * columnData.p_showGridCount
        --         reelRunData:setReelRunLen(runLen)
        --     end

        --     -- runLen = self:getLongRunLen(iCol, nil)
        --     -- reelRunData:setReelRunLen(runLen)
        --     -- print("[CodeGameScreenCastFishingMachine:MachineRule_ResetReelRunData] runLen=", runLen)
        -- end
    -- 没有固定图标时 就算本次滚动第2列出现了一个固定图标,第4列也不会出现第2个固定图标。(数值)
    end

end
--
-- 单列滚动停止回调
--
function CodeGameScreenCastFishingMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCastFishingMachine.super.slotOneReelDown(self,reelCol) 

    -- 停止图标期待动画 和 滚动效果
    local bQuickStop = true == self.m_isNewReelQuickStop
    self.m_lockSymbolMag:hideReelRunAnim(reelCol, bQuickStop)
    local bStopExpect = self.m_reelRunColData.reelRunCol == reelCol
    if bStopExpect then
        self.m_lockSymbolMag:stopSymbolExpectAnim()
    end
end

-- 落地动画
function CodeGameScreenCastFishingMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
function CodeGameScreenCastFishingMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            local isVisible = self.m_lockSymbolMag:getLockSymbolVisibleByPos(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex)
            return not isVisible
        end
    end

    return false
end
function CodeGameScreenCastFishingMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    CodeGameScreenCastFishingMachine.super.playSymbolBulingAnim(self, slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    for i,_slotNode in ipairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            if self:checkSymbolBulingAnimPlay(_slotNode) then
                self.m_lockSymbolMag:playSymbolBulingAnim(_slotNode, speedActionTable)
            end
        end
    end
end
function CodeGameScreenCastFishingMachine:symbolBulingEndCallBack(_slotNode)
    local symbolType = _slotNode.p_symbolType
    if symbolType == self.SYMBOL_SpecialBonus or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        _slotNode:runIdleAnim()
        self.m_lockSymbolMag:playSymbolIdleAnim(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, symbolType)
    end
end

-- 捕鱼的赢钱不计算总赢钱等待时间，只计算连线赢钱的等待
function CodeGameScreenCastFishingMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    -- !!!
    local lastLineWinCoins = self:getClientWinCoins()
    local winRate = lastLineWinCoins / totalBet
    -- local winRate = self.m_iOnceSpinLastWin / totalBet
    local showTime = 0
    if self.m_iOnceSpinLastWin > 0 then
        if winRate <= 1 then
            showTime = 1
        elseif winRate > 1 and winRate <= 3 then
            showTime = 1.5
        elseif winRate > 3 and winRate <= 6 then
            showTime = 2.5
        elseif winRate > 6 then
            showTime = 3
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            showTime = 1
        end
    end

    return showTime
end

---
--设置bonus scatter 层级
function CodeGameScreenCastFishingMachine:getBounsScatterDataZorder(symbolType )
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    local order = CodeGameScreenCastFishingMachine.super.getBounsScatterDataZorder(self, symbolType)
    
    if symbolType == self.SYMBOL_Bonus then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_SpecialBonus  then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end

    return order
end

function CodeGameScreenCastFishingMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY   = 0

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
        if display.height < DESIGN_SIZE.height then
            -- 1.78
            if display.height / display.width > 1370/768 then
            --1.59
            elseif display.height / display.width >= 1228/768 then
                mainScale = mainScale * 1.05
                mainPosY  = -5
            --1.5
            elseif display.height / display.width >= 960/640 then
                mainScale = mainScale * 1.07
            --1.33
            elseif display.height / display.width >= 1024/768 then
                mainScale = mainScale * 1.12
                mainPosY  = 10
            end

            mainScale = math.min(1, mainScale)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale  = mainScale
            self.m_machineNode:setPositionY(mainPosY)
        end
    end
end

return CodeGameScreenCastFishingMachine






