---
--island
--2017年12月13日
--BaseMachineGameEffectGameEffectReelSlot.lua
--

local BaseSlots = require "Levels.BaseSlots"

local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"

local BaseMachineGameEffect = class("BaseMachineGameEffect", BaseSlots)

BaseMachineGameEffect.m_gameEffects = nil --  游戏内动画列表
BaseMachineGameEffect.m_isRunningEffect = nil -- 是否在运行effect

BaseMachineGameEffect.m_isShowSpecialNodeTip = nil -- 是否进行特殊元素的提示， bonus scatter 等

BaseMachineGameEffect.m_framePool = nil -- frame pool 管理

BaseMachineGameEffect.m_slotParents = nil --
BaseMachineGameEffect.m_clipParent = nil --                --轮盘的父节点
BaseMachineGameEffect.m_slotEffectLayer = nil
BaseMachineGameEffect.m_slotFrameLayer = nil --连线框层

BaseMachineGameEffect.m_LineEffectType = nil -- 线frame 元素等的effectType 类型
BaseMachineGameEffect.m_showLineHandlerID = nil --
BaseMachineGameEffect.ACTION_TAG_LINE_FRAME = nil

BaseMachineGameEffect.m_changeLineFrameTime = nil -- 切换win frame 的时间

BaseMachineGameEffect.m_BonusTipMusicPath = nil -- 触发bonus时 播放的音效
BaseMachineGameEffect.m_ScatterTipMusicPath = nil -- 触发Freespin时 播放的音效

BaseMachineGameEffect.m_freeSpinOverDelayTime = 7 --freespin结算是否有等待时间 默认都会等待
BaseMachineGameEffect.m_freeSpinOverCurrentTime = 0 --freespin结算是否有等待时间 默认都会等待

BaseMachineGameEffect.m_levelUpSaleFunc = nil --升级促销回调

BaseMachineGameEffect.m_levelUpTriggerIndex = nil
BaseMachineGameEffect.m_levelUpTriggerOverFunc = nil
BaseMachineGameEffect.m_levelUpTriggerLen = 5 -- 扩展LevelUp_Trigger_Push后，要改变数值

BaseMachineGameEffect.m_chooseRepin = nil --选择respin
BaseMachineGameEffect.m_chooseRepinGame = nil --选择respin
BaseMachineGameEffect.m_autoChooseRepin = nil --选择auto时拷贝使用
BaseMachineGameEffect.m_eachLineSlotNode = nil
BaseMachineGameEffect.m_autoSpinDelayTime = nil
BaseMachineGameEffect.m_bGetSymbolTime = nil

BaseMachineGameEffect.m_spinRestMusicBG = true
BaseMachineGameEffect.m_enterGameSoundId = nil
BaseMachineGameEffect.m_winSoundsId = nil
BaseMachineGameEffect.m_delayHandleId = nil
BaseMachineGameEffect.m_beInSpecialGameTrigger = false
BaseMachineGameEffect.m_stopUpdateCoinsSoundIndex = 10000

BaseMachineGameEffect.m_rewaedFSData = nil --免费送spin活动数据
BaseMachineGameEffect.m_reFsLastTime = 0
BaseMachineGameEffect.m_isOpenRewaedFreeSpin = nil -- 是否开启免费送spin活动，需要在格子关卡配置，这样事为了处理多轮子的情况，保证只有控制轮触发游戏事件
BaseMachineGameEffect.m_bProduceSlots_InRewaedFreeSpin = false --处于rewaedFreeSpin状态的标识

BaseMachineGameEffect.m_showLineFrameTime = nil --显示连线时的等待时间
BaseMachineGameEffect.m_lineWaitTime = 0.2 --显示连线时的等待时间
BaseMachineGameEffect.m_startSpinTime = nil
--轮盘开始转动时的时间
BaseMachineGameEffect.m_startSpinWaitTime = 0 --轮盘开始转动时等待的时间

local LevelUp_Trigger_Push = {
    LevelUpCouponTicket = 1, -- 等级里程碑优惠券
    LevelUpDropCards = 2,
    NewSeasonDropCards = 3, -- 为了防止策划同时配置了升级掉落和新手引导掉落，特将升级掉落放在前面
    NewPlayerUnlockLevel5 = 4, -- 新手玩家5级解锁新关卡， 在右侧弹出新关卡的小弹框
    NewPlayerUnlockLevelTip = 5, -- 新手玩家5级解锁新关卡， 在右侧弹出新关卡的小弹框
    NewPlayerUnlockLuckyChallenge = 6, --引导第二条任务线开放
    NewUserCardOpen = 7, -- 新手期集卡开启弹版，跟新手quest冲突了，延后到升15级时弹出
    -- 成长基金
    GrowthFundTip = 8,
}

-- 构造函数
function BaseMachineGameEffect:ctor()
    print("BaseMachineGameEffect:ctor")
    BaseSlots.ctor(self)

    self.m_gameEffects = {}

    self.m_isRunningEffect = false

    self.m_isShowSpecialNodeTip = true
    self.m_framePool = {}

    self.ACTION_TAG_LINE_FRAME = 20101
    self.m_LineEffectType = GameEffect.EFFECT_SHOW_ALL_LINE

    self.m_isOpenRewaedFreeSpin = false -- 是否开启免费送spin活动
    self.m_rewaedFSData = nil --免费送spin活动数据

    self.m_changeLineFrameTime = 2 -- 各个关卡自己配置， low symbol 两个周期

    self.m_autoSpinDelayTime = 2
    self.m_levelUpSaleFunc = nil
    self.m_spinRestMusicBG = false
    self.m_enterGameSoundId = nil
    self.m_winSoundsId = nil
    self.m_delayHandleId = nil
    self.m_beInSpecialGameTrigger = false
    self.m_stopUpdateCoinsSoundIndex = 10000
    self.m_bProduceSlots_InRewaedFreeSpin = false

    gLobalNoticManager:addObserver(
        self,
        function(self, func)
            --FBLink领奖
            globalPlatformManager:checkShowFacebookLinkReward()
        end,
        ViewEventType.NOTIFY_CHECK_FBLINK_REWARD
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            self.m_autoSpinDelayTime = params + 1
        end,
        ViewEventType.NOTIFY_AUTO_SPIN_DELAY_TIME
    )

    self.m_showLineFrameTime = nil
    --显示连线时的时间
    self.m_startSpinTime = nil
    --轮盘开始转动时的时间
end

function BaseMachineGameEffect:onEnter()
    BaseSlots.onEnter(self)
end

function BaseMachineGameEffect:onExit()
    BaseSlots.onExit(self)
    local gameEffects = self.m_gameEffects
    for i = #gameEffects, 1, -1 do
        table.remove(gameEffects, 1)
    end

    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
        self.m_showLineHandlerID = nil
    end

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())
    gLobalNoticManager:removeAllObservers(self)

    --在退出关卡场景时，保存下当前的缓存日志
    if self:checkControlerReelType() then
        local NetworkLog = util_require("network.NetworkLog")
        if NetworkLog ~= nil and NetworkLog.saveLogToFile ~= nil then
            NetworkLog.saveLogToFile()
        end
    end
end

---
-- 保存frame
--
function BaseMachineGameEffect:pushFrameToPool(node)
    if node == nil then
        return
    end
    --    node:reset()
    node:stopAllActions()
    self.m_framePool[#self.m_framePool + 1] = node
end

---
-- 获取frame
--
function BaseMachineGameEffect:getFrameWithPool(lineValue, symPosData)
    if self.m_configData.m_showLinesFadeTime then
        local node = nil
        if #self.m_framePool == 0 then
            node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(self.m_winFrameCCB, -1)
        else
            node = self.m_framePool[1]
            table.remove(self.m_framePool, 1)
        end
        
        self:showFadeEffectLineNode(node)
        return node
    else
        if #self.m_framePool == 0 then
            local node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(self.m_winFrameCCB, -1)
            -- node:runDefaultAnim()
            node:runAnim("actionframe", true)
            return node
        end
        local node = self.m_framePool[1]
        table.remove(self.m_framePool, 1)
        -- node:runDefaultAnim()
        node:runAnim("actionframe", true)
        return node
    end
end

-- 连线框渐隐渐现
function BaseMachineGameEffect:showFadeEffectLineNode(_lineNode)
    _lineNode:setOpacity(0)
    util_nodeFadeIn(_lineNode,self.m_configData.m_showLinesFadeTime,0,255)
    _lineNode:runAnim("actionframe", true)
end

---
--  检测当前游戏是否暂停，是否需要记录game resume callfun
--
function BaseMachineGameEffect:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        globalData.slotRunData.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end
--[[
    @desc:
    author:{author}
    time:2020-07-10 16:06:07
    @return:
]]
function BaseMachineGameEffect:checkOperaGameEffects()
    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = true
    end

    local effectLen = #self.m_gameEffects
    self.m_isRunningEffect = true
    local isRunning = false
    for i = 1, effectLen, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_isPlay ~= true then
            local effectType = effectData.p_effectType
            printInfo("xcyy :effectType %d", effectType)
            if effectType == GameEffect.EFFECT_SELF_EFFECT then
                isRunning = self:MachineRule_playSelfEffect(effectData)
            elseif effectType == GameEffect.EFFECT_LINE_FRAME then -- 显示线 显示全部线然后轮播
                isRunning = self:showEffect_LineFrame(effectData)
            elseif effectType == GameEffect.EFFECT_BIG_WIN_LIGHT then --大赢光效(关卡内实现)
                isRunning = self:showEffect_runBigWinLightAni(effectData)
            elseif effectType == GameEffect.EFFECT_BONUS then
                isRunning = self:showEffect_Bonus(effectData)
            elseif effectType == GameEffect.EFFECT_FREE_SPIN then
                isRunning = self:showEffect_FreeSpin(effectData)
            elseif effectType == GameEffect.EFFECT_FIVE_OF_KIND then
                isRunning = self:showEffect_FiveOfKind(effectData)
            elseif effectType == GameEffect.EFFECT_LEVELUP then
                isRunning = self:showEffect_LevelUp(effectData)
            elseif effectType == GameEffect.EFFECT_EPICWIN then
                isRunning = self:showEffect_EpicWin(effectData)
            elseif effectType == GameEffect.EFFECT_LEGENDARY then
                isRunning = self:showEffect_Legendary(effectData)
            elseif effectType == GameEffect.EFFECT_MEGAWIN then
                isRunning = self:showEffect_MegaWin(effectData)
            elseif effectType == GameEffect.EFFECT_NORMAL_WIN then
                isRunning = self:showEffect_NormalWin(effectData)
            elseif effectType == GameEffect.EFFECT_BIGWIN then
                isRunning = self:showEffect_BigWin(effectData)
            elseif effectType == GameEffect.EFFECT_FREE_SPIN_OVER then
                isRunning = self:showEffect_FreeSpinOver()
            elseif effectType == GameEffect.EFFECT_RESPIN then
                isRunning = self:showEffect_Respin(effectData)
            elseif effectType == GameEffect.EFFECT_RESPIN_OVER then
                isRunning = self:showEffect_RespinOver(effectData)
            elseif effectType == GameEffect.EFFECT_Unlock then
                isRunning = self:showEffect_Unlock(effectData)
            elseif effectType == GameEffect.EFFECT_PushSlot then
                isRunning = self:showEffect_PushSlot(effectData)
            elseif effectType == GameEffect.QUEST_COMPLETE_TIP then
                isRunning = self:showEffect_QuestComplete(effectData)
            elseif effectType == GameEffect.MISSION_LOCK_OPEN then
                isRunning = self:showEffect_OpenMissionLead(effectData)
            elseif effectType == GameEffect.EFFECT_NEWBIETASK_COMPLETE then
                isRunning = self:showEffect_NewbieTaskComplete(effectData)
            elseif effectType == GameEffect.EFFECT_DELAY_SHOW_BIGWIN then
                isRunning = self:showEffect_DelayShowBigWin(effectData)
            elseif effectType == GameEffect.EFFECT_QUEST_DONE then
                isRunning = self:showEffect_QuestCompleteNew(effectData)
            elseif effectType == GameEffect.EFFECT_REWARD_FS_START then
                isRunning = self:showEffect_RewaedFreeSpinStart(effectData)
            elseif effectType == GameEffect.EFFECT_REWARD_FS_OVER then
                isRunning = self:showEffect_RewaedFreeSpinOver(effectData)
            elseif effectType == GameEffect.EFFECT_COLLECT_SIGN then --收集角标
                isRunning = self:showEffect_collectSign(effectData)
            end
        else -- 移除掉已经播放过的动画
        end
        if isRunning == true then
            printInfo("xcyy running effect: %d", effectData.p_effectType)
            break
        end
    end

    return isRunning
end
----
-- 检测处理effect 结束后的逻辑
--
function BaseMachineGameEffect:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    self:playEffectNotifyChangeSpinStatus()

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end

---
-- 根据枚举的内容播放效果
--
function BaseMachineGameEffect:playGameEffect()
    local isGamePause = self:checkGameResumeCallFun()
    if isGamePause == false then
        return
    end

    local isRunning = self:checkOperaGameEffects()

    if isRunning == false then
        self:operaEffectOver()
    end
end

function BaseMachineGameEffect:isPlayOnly1()
    local isEnterOtherLevel = gLobalDataManager:getNumberByField("NewPlayerUnlockLevelTip_" .. globalData.userRunData.uid, 0)
    if globalData.slotRunData.machineData.p_levelName == "GameScreenCharms" and isEnterOtherLevel ~= 1 then
        return true
    end
    return false
end

function BaseMachineGameEffect:checkTryPayView()
    --非大弹版不弹
    if globalData.userRunData.levelNum % 5 ~= 0 then
        return
    end

    if not self.m_triggerFlationLevel then --检测是否膨胀
        return false
    end
    self.m_triggerFlationLevel = false
    if not globalData.constantData or not globalData.constantData.TEST_PAY_LEVEL or globalData.userRunData.levelNum < globalData.constantData.TEST_PAY_LEVEL then --等级不足
        return false
    end
    if not globalData.saleRunData:getAttemptData() then --已经购买过
        return false
    end
    if self.m_isShowFlationLevel then --首次膨胀已经展示过了
        if globalData.saleRunData:isOnceBuyAttemps() then -- 首次膨胀之后付过费 不弹
            return false
        end
    else
        local showState = gLobalDataManager:getNumberByField("TryPay_FlationLevel_Show", 0)
        if showState == 0 then
            self.m_isShowFlationLevel = true
            gLobalDataManager:setNumberByField("TryPay_FlationLevel_Show", 1)
        else
            if globalData.saleRunData:isOnceBuyAttemps() then -- 首次膨胀之后付过费 不弹
                return false
            end
        end
    end

    return true
end

function BaseMachineGameEffect:checkHotTodayView()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local nowTb = {}
    nowTb.year = tonumber(os.date("%Y", curTime))
    nowTb.month = tonumber(os.date("%m", curTime))
    nowTb.day = tonumber(os.date("%d", curTime))

    local key = "Hot_Today_" .. nowTb.year .. nowTb.month .. nowTb.day
    local curShowTime = gLobalDataManager:getNumberByField(key, 0)
    if curShowTime < 1 then
        self.m_isShowHotToday = true
        gLobalDataManager:setNumberByField(key, 1)
        return true
    end
    self.m_isShowHotToday = true
    return false
end

function BaseMachineGameEffect:resumeShowSystemUICor()
    util_resumeCoroutine(self.systemUICor)
end

function BaseMachineGameEffect:checkFireBaseLog()
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = globalData.slotRunData.lastWinCoin / lTatolBetNum
    if winRatio >= 200 then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.SpecialAward_200)
        end
    elseif winRatio >= 100 then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.SpecialAward_100)
        end
    elseif winRatio >= 50 then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.SpecialAward_50)
        end
    end

    -- cxc 2021-12-09 10:51:22 去掉spin_normal、spin_auto、spin_stop这几个firebase打点
    -- if globalData.slotRunData.isClickQucikStop then
    --     if globalFireBaseManager.sendFireBaseLogDirect then
    --         globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.spin_stop)
    --     end
    -- else
    --     if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
    --         if globalFireBaseManager.sendFireBaseLogDirect then
    --             globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.spin_auto)
    --         end
    --     else
    --         if globalFireBaseManager.sendFireBaseLogDirect then
    --             globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.spin_nomal)
    --         end
    --     end
    -- end
end

function BaseMachineGameEffect:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = self.m_iOnceSpinLastWin / totalBet
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

function BaseMachineGameEffect:playEffectNotifyNextSpinCall()
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
end

function BaseMachineGameEffect:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin =
                    scheduler.performWithDelayGlobal(
                    function(delay)
                        self:normalSpinBtnCall()
                    end,
                    0.5,
                    self:getModuleName()
                )
            end
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
end

function BaseMachineGameEffect:showFreeSpinOverAds()
    if globalData.adsRunData:isPlayAutoForPos(PushViewPosType.FreeSpin) then
        gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.FreeSpin)
        gLobalAdsControl:playAutoAds(PushViewPosType.FreeSpin)
    end
end
---
-- 通知某种类型动画播放完毕
--
function BaseMachineGameEffect:notifyGameEffectPlayComplete(param)
    local effectType = param
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectType == EFFECT_NONE or effectLen == 0 then
        return
    end

    if effectType == GameEffect.EFFECT_QUEST_DONE then
        return
    end

    --    printInfo("xcyy gameEffectPlayComplete: %d",effectType)

    for i = 1, effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            effectData.p_isPlay = true
            self:playGameEffect() -- 继续播放动画
            break
        end
    end
end

---
--
function BaseMachineGameEffect:clearLineAndFrame()
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
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function BaseMachineGameEffect:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            slotsNode:runLineAnim()
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function BaseMachineGameEffect:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            slotsNode:runIdleAnim()
        end
    end
end

---
-- 显示所有的连线框
--
function BaseMachineGameEffect:showAllFrame(winLines)
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

                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(cc.p(posX, posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end
---
-- 逐条线显示 线框和 Node 的actionframe
--
function BaseMachineGameEffect:showLineFrameByIndex(winLines, frameIndex)
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
            if self.m_configData.m_showLinesFadeTime then
                self:showFadeEffectLineNode(node)
            else
                node:runAnim("actionframe", true)
            end
        else
            if self.m_configData.m_showLinesFadeTime then
                self:showFadeEffectLineNode(node)
            else
                node:runAnim("actionframe", true)
            end
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
    end

    self:showEachLineSlotNodeLineAnim(frameIndex)
end

function BaseMachineGameEffect:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
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

function BaseMachineGameEffect:clearFrames_Fun()
    -- 回收之前的元素点
    local checkIndex = 1
    while true do
        local preNode = nil

        preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

        if preNode ~= nil then
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
        checkIndex = checkIndex + 1
    end
end

function BaseMachineGameEffect:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function BaseMachineGameEffect:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

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

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- end
        self:showAllFrame(winLines) -- 播放全部线框

        -- if #winLines > 1 then
        showLienFrameByIndex()
    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end

        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end

function BaseMachineGameEffect:getShowLineWaitTime()
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) 
        or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) 
        or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        return 0.5
    end
end

function BaseMachineGameEffect:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    local time = self:getShowLineWaitTime()
    if time then
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            0.5
        )
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end


    return true
end

function BaseMachineGameEffect:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
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
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                if slotNode == nil and slotParentBig then
                                    slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                end
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        end
                    end
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode == nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                end

                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end

                checkAddLineSlotNode(slotNode)

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = self:getFixSymbol(symPosData.iY, bigSymbolInfo.startRowIndex, SYMBOL_NODE_TAG)
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    end
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end
                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    local specialChilds = self:getAllSpecialNode()
    for specialIndex = 1, #specialChilds do
        local specialNode = specialChilds[specialIndex]
        checkAddLineSlotNode(specialNode)
    end
end

--[[
    显示大赢光效事件
]]
function BaseMachineGameEffect:showEffect_runBigWinLightAni(effectData)

    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local posY = 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    end
    
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1,
        animName   = "actionframe3",
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
function BaseMachineGameEffect:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local aniTime = 3
    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function BaseMachineGameEffect:getClipParentChildShowOrder(slotNode)
    return REEL_SYMBOL_ORDER.REEL_ORDER_3
end

function BaseMachineGameEffect:getMaskLayerSlotNodeZorder(_slotNode)
    return SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function BaseMachineGameEffect:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = self:getClipParentChildShowOrder(slotNode)
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    -- 切换图层
    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    util_changeNodeParent(self.m_clipParent, slotNode, self:getMaskLayerSlotNodeZorder(slotNode) + slotNode.p_showOrder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

---
--得到参与连线的固定小块
function BaseMachineGameEffect:getSpecialReelNode(matrixPos)
    -- 自定义特殊块加入连线动画
    for i = 1, #self.m_slotParents do
        local parentNode = self.m_slotParents[i].slotParent
        local childs = parentNode:getChildren()
        local slotParentBig = self.m_slotParents[i].slotParentBig
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j = 1, #newChilds do
                childs[#childs + 1] = newChilds[j]
            end
        end
        for index = 1, #childs do
            local slotNode = childs[index]
            if childs[index]:getTag() > SYMBOL_FIX_NODE_TAG then
                if slotNode:isInLinePos(matrixPos) then
                    return slotNode
                end
            end
        end
    end

    --如果为空则从 clipnode获取
    local childs = self.m_clipParent:getChildren()
    for index = 1, #childs do
        local slotNode = childs[index]
        if slotNode ~= nil and slotNode:getTag() > SYMBOL_FIX_NODE_TAG then
            if slotNode.p_layerTag ~= nil then
                if slotNode:isInLinePos(matrixPos) then
                    return slotNode
                end
            end
        end
    end
    return nil
end

function BaseMachineGameEffect:getAllSpecialNode()
    -- 自定义特殊块加入连线动画
    local allSpecialNode = {}

    for colIndex = 1, self.m_iReelColumnNum do
        local parentData = self.m_slotParents[colIndex]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j = 1, #newChilds do
                childs[#childs + 1] = newChilds[j]
            end
        end
        local childCount = #childs
        for i = 1, childCount, 1 do
            local slotsNode = childs[i]
            if slotsNode.m_bInLine == false and slotsNode:getTag() > SYMBOL_FIX_NODE_TAG and slotsNode:getTag() < SYMBOL_NODE_TAG then
                allSpecialNode[#allSpecialNode + 1] = slotsNode
            end
        end
    end

    --如果为空则从 clipnode获取
    local parentData = self.m_clipParent
    local childs = self.m_clipParent:getChildren()
    local childCount = #childs

    for i = 1, childCount, 1 do
        local slotsNode = childs[i]
        if slotsNode.p_layerTag ~= nil then
            if slotsNode.m_bInLine == false and slotsNode:getTag() > SYMBOL_FIX_NODE_TAG and slotsNode:getTag() < SYMBOL_NODE_TAG then
                allSpecialNode[#allSpecialNode + 1] = slotsNode
            end
        end
    end

    return allSpecialNode
end

function BaseMachineGameEffect:getFsTriggerSlotNode(parentData, symPosData)
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
    if slotNode == nil and slotParentBig then
        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
    end

    return slotNode
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function BaseMachineGameEffect:showBonusAndScatterLineTip(lineValue, callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=symPosData.iX})
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]
                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = self:getFsTriggerSlotNode(parentData, {iY= symPosData.iY,iX=bigSymbolInfo.startRowIndex})
                        break
                    end
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

function BaseMachineGameEffect:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(
        function()
            self:resetMaskLayerNodes()
            callFun()
        end,
        util_max(2, animTime),
        self:getModuleName()
    )
end

--获取播放连线动画时的层级
function BaseMachineGameEffect:getSlotNodeEffectZOrder(slotNode)
    return SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder
end

function BaseMachineGameEffect:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent(false)
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, self:getSlotNodeEffectZOrder(slotNode))
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runLineAnim()
    end
    return slotNode
end

--播放bonus tip music
function BaseMachineGameEffect:playBonusTipMusicEffect()
    if self.m_BonusTipMusicPath ~= nil then
        gLobalSoundManager:playSound(self.m_BonusTipMusicPath)
    end
end

---
-- 显示bonus 触发的小游戏
function BaseMachineGameEffect:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    self:levelDeviceVibrate(6, "bonus")
    
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

    return true
end

---
-- 根据Bonus Game 每关做的处理
--
function BaseMachineGameEffect:showBonusGameView(effectData)
    -- effectData.p_isPlay = true
    -- self:playGameEffect() -- 播放下一轮
end

-- ---
-- -- 取消掉赢钱线的效果
-- function BaseMachineGameEffect:clearWinLineEffect()

-- end

---
--
function BaseMachineGameEffect:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
    end
end
---
-- 显示free spin
function BaseMachineGameEffect:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

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

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    
    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
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
    return true
end

function BaseMachineGameEffect:showFreeSpinView(effectData)
end

function BaseMachineGameEffect:triggerFreeSpinCallFun()
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
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    self:resetMusicBg()
end

---
-- 播放各个关卡触发 free spin 的改变
function BaseMachineGameEffect:levelFreeSpinEffectChange()
end

---
-- 显示五个元素在同一条线效果
function BaseMachineGameEffect:showEffect_FiveOfKind(effectData)
    -- local fiveAnim = FiveOfKindAnima:create()  -- 不在播放five of kind 动画 2017-12-08 11:54:46
    local fiveAnim =
        util_createView(
        "views.fiveofkind.FiveOfKindLayer",
        function()
        end
    )
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(fiveAnim, "Push", DotUrlType.UrlName, true, DotEntrySite.SpinPush, DotEntryType.Game)
    end
    gLobalViewManager:showUI(fiveAnim, nil, false)
    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

---
-- 显示大赢动画
function BaseMachineGameEffect:showEffect_BigWin(effectData)
    -- 更新游戏内每日任务进度条 -- r
    self:showEffect_NewWin(effectData, SpineWinType.SpineWinType_BigWin)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_BigWin, self.m_llBigOrMegaNum)
    return true
end
function BaseMachineGameEffect:showEffect_DelayShowBigWin(effectData)
    -- performWithDelay(self,function()

    effectData.p_isPlay = true
    self:playGameEffect()

    -- end,1)

    return true
end
---
-- 显示一半赢钱动画  ,, megawin 暂时不适用了
function BaseMachineGameEffect:showEffect_MegaWin(effectData)
    -- 更新游戏内每日任务进度条 -- r
    self:showEffect_NewWin(effectData, SpineWinType.SpineWinType_MegaWin)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_MegaWin, self.m_llBigOrMegaNum)
    return true
end

function BaseMachineGameEffect:showEffect_EpicWin(effectData)
    -- 更新游戏内每日任务进度条 -- r
    self:showEffect_NewWin(effectData, SpineWinType.SpineWinType_EpicWin)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_EpicWin, self.m_llBigOrMegaNum)
    return true
end

function BaseMachineGameEffect:showEffect_Legendary(effectData)
    -- 更新游戏内每日任务进度条 -- r
    self:showEffect_NewWin(effectData, SpineWinType.SpineWinType_Legendary)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Legendary, self.m_llBigOrMegaNum)
    return true
end

function BaseMachineGameEffect:showEffect_NewWin(effectData, winType)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg", winType)
    bigMegaWin:initViewData(
        self.m_llBigOrMegaNum,
        winType,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_OVER_BIGWIN_EFFECT, {winType = winType})

            -- cxc 2023年11月30日15:02:44  spinWin 需要监测弹（评分，绑定fb, 打开推送）
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("SpinWin", "SpinWin_" .. winType)
            if view then
                view:setOverFunc(function()
                    if not tolua.isnull(self) then
                        if self.playGameEffect then
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end
                end)
            else
                effectData.p_isPlay = true
                self:playGameEffect()
            end

        end
    )
    gLobalViewManager:showUI(bigMegaWin)
end

---
-- 显示赢钱掉落金币动画
function BaseMachineGameEffect:showEffect_NormalWin(effectData)
    effectData.p_isPlay = true -- 临时写法
    self:playGameEffect()

    return true
end

---xx
-- 显示升级动画
function BaseMachineGameEffect:showEffect_LevelUp(effectData)
    if gLobalViewManager:isLobbyView() or gLobalViewManager:isLoadingView() then
        return
    end
    effectData.p_isPlay = true
    if self.m_upgradePreLevel == nil then
        self:playGameEffect()
        return true
    end
    local check = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_PIGBANK_DATA)
        local curLevel = globalData.userRunData.levelNum
        -- globalData.GameConfig:checkInFlationLevels(curLevel)
        if self:checkFirstSalePop(curLevel) then
            -- if curLevel >0 and curLevel%10==0 then
            self.m_triggerFlationLevel = true
            gLobalSendDataManager:getNetWorkFeature():sendQuerySaleConfig(
                function()
                    if globalData.saleRunData:checkBaicsSale() and globalData.slotRunData and globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_levelName then
                        local levelName = globalData.slotRunData.machineData.p_levelName
                        gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "levelUpPush")
                        if globalFireBaseManager.sendFireBaseLogDirect and (curLevel == 10 or curLevel == 20) then
                            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_NormalSale)
                        end

                        local bCanShowFirstSaleMulti = G_GetMgr(G_REF.FirstSaleMulti):isCanShowLayer()
                        local FirstSaleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
                        local RoutineSaleData = G_GetMgr(G_REF.RoutineSale):canShowMainLayer()

                        if bCanShowFirstSaleMulti then
                            G_GetMgr(G_REF.FirstSaleMulti):showMainLayer({pos = "Store"})
                        elseif FirstSaleData then
                            G_GetMgr(G_REF.FirstCommonSale):showMainLayer({pos = "Store"})
                        elseif RoutineSaleData then
                            G_GetMgr(G_REF.RoutineSale):showMainLayer({pos = "Store", levelUp = true})
                        else
                            G_GetMgr(G_REF.SpecialSale):showMainLayer({pos = "Store"})
                        end

                        self.m_levelUpSaleFunc = function()
                            if self.showEffect_LevelUpNew then
                                self:showEffect_LevelUpNew(effectData)
                            end
                        end
                    else
                        if self.showEffect_LevelUpNew then
                            self:showEffect_LevelUpNew(effectData)
                        end
                    end
                end
            )
        elseif gLobalPushViewControl:checkToDayFristLevelQuest() then
            gLobalPushViewControl:showLevelQuestView(
                function()
                    if self.showEffect_LevelUpNew then
                        self:showEffect_LevelUpNew(effectData)
                    end
                end
            )
        else
            self:showEffect_LevelUpNew(effectData)
        end
    end

    local curLevel = globalData.userRunData.levelNum
    gLobalNoticManager:postNotification(ViewEventType.SHOW_LEVEL_UP, {self.m_upgradePreLevel, self.m_lineCount})

    --升级飞金币结束调用
    local function flyOverFunc()
        --22级弹fb解锁  30级之后符合膨胀就弹
        local fbPush = (curLevel > 30 and globalData.GameConfig:checkInFlationLevels(curLevel))
        if (curLevel == 22 or fbPush) and gLobalSendDataManager:getIsFbLogin() == false then
            -- local view = util_createView("views.newbieTask.FBGuideLayer",check)
            -- gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
            --新手quest
            --新手quest
            if gLobalViewManager:isLobbyView() or gLobalViewManager:isLoadingView() then
                return
            end
            check()
        elseif globalData.userRunData.levelNum == globalData.constantData.OPENLEVEL_NEWUSERQUEST then
            -- if not globalDynamicDLControl:checkDownloading("Activity_QuestNewUser") then
            --     performWithDelay(
            --         gLobalViewManager:getViewLayer(),
            --         function()
            --             if gLobalViewManager:isLobbyView() or gLobalViewManager:isLoadingView() then
            --                 return
            --             end
            --             local questNewUserConfig = globalData.saleRunData.m_newUserQuestConfig
            --             if questNewUserConfig and questNewUserConfig:isOpen() then
            --                 --csc 2021-06-01 新手期ABTEST quest 优化弹板修改
            --                 local view = util_createView("newQuestCode.Quest.QuestNewUserOpenView", check)
            --                 if not view or globalData.GameConfig:checkUseNewNoviceFeatures() then
            --                     view = util_createView("newQuestCode.Quest.QuestNewUserLoginView", check)
            --                 end
            --                 gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            --             else
            --                 check()
            --             end
            --         end,
            --         0.5
            --     )
            -- else
            --     check()
            -- end
            -- local _layer = G_GetMgr(ACTIVITY_REF.Quest):showOpenLayer(check)
            -- if not _layer then
            --     check()
            -- end
            check()
        else
            --其他弹窗
            check()
        end
    end

    -- cxc 2021年06月25日15:22:57 A组等级弹板 恢复成以前的
    local bPopLevelUpLayer = false
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        -- cxc 2021-06-22 16:07:35  15级不弹出框
        bPopLevelUpLayer = curLevel % 5 == 0 and curLevel ~= 15
    else
        bPopLevelUpLayer = curLevel % 5 == 0 or curLevel == 2
    end

    -- csc 2021-10-25 新手期4.0优化 5.10级弹小面板
    if globalData.GameConfig:checkUseNewNoviceFeatures("Season_4") then
        if curLevel == 5 or curLevel == 10 then
            bPopLevelUpLayer = false
        end
    end

    if bPopLevelUpLayer then
        -- cxc 2023年12月02日14:36:14 升级弹板关闭后 监测弹运营引导弹板
        local checkOGPopLayer = function()
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Levelup", "Levelup_" .. globalData.userRunData.levelNum)
            if view then
                view:setOverFunc(flyOverFunc)
            else
                flyOverFunc()
            end
        end
        local levelUpLayer = util_createView("views.levelup.LevelUpLayer", checkOGPopLayer)
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(levelUpLayer, "Push", DotUrlType.UrlName, true, DotEntrySite.LevelUpPush, DotEntryType.Game)
        end
        levelUpLayer:initLevelUpData({self.m_upgradePreLevel, self.m_lineCount})
        local oldlevel = self.m_upgradePreLevel
        gLobalViewManager:showUI(levelUpLayer)
    elseif curLevel == 18 then
        --18级延时触发集卡
        performWithDelay(
            gLobalViewManager:getViewLayer(),
            function()
                if gLobalViewManager:isLobbyView() or gLobalViewManager:isLoadingView() then
                    return
                end
                flyOverFunc()
            end,
            1
        )
    else
        flyOverFunc()
    end
    self.m_upgradePreLevel = nil
    return true
end

function BaseMachineGameEffect:showEffect_LevelUpNew(effectData)
    --返回大厅或者loading中不再执行
    if gLobalViewManager:isLobbyView() or gLobalViewManager:isLoadingView() then
        return
    end
    self:doLevelUpTriggerLogic()
end

-- 升级后触发逻辑 start --------------------------------------------------------------------------------------
-- 设置回调
function BaseMachineGameEffect:setLevelUpTriggerLogicOverFunc(overFunc)
    if overFunc then
        self.m_levelUpTriggerOverFunc = overFunc
    end
end

-- 升级后触发的逻辑
function BaseMachineGameEffect:doLevelUpTriggerLogic()
    self.m_levelUpTriggerIndex = 0
    self:setLevelUpTriggerLogicOverFunc(
        function()
            self:playGameEffect()
        end
    )
    self:nextLevelUpTrigger()
end

function BaseMachineGameEffect:nextLevelUpTrigger()
    -- 升级后触发的所有逻辑都结束了
    if self.m_levelUpTriggerIndex >= self.m_levelUpTriggerLen then
        if self.m_levelUpTriggerOverFunc then
            self.m_levelUpTriggerOverFunc()
            self.m_levelUpTriggerOverFunc = nil
        end
        return
    end

    self.m_levelUpTriggerIndex = (self.m_levelUpTriggerIndex or 0) + 1
    if self.m_levelUpTriggerIndex == LevelUp_Trigger_Push.LevelUpCouponTicket then
        self:levelUpTriggerCouponTicket()
    elseif self.m_levelUpTriggerIndex == LevelUp_Trigger_Push.LevelUpDropCards then
        self:levelUpTriggerDropCards()
    elseif self.m_levelUpTriggerIndex == LevelUp_Trigger_Push.NewSeasonDropCards then
        self:levelUpTriggerCardNewSeason()
    elseif self.m_levelUpTriggerIndex == LevelUp_Trigger_Push.NewPlayerUnlockLevel5 then
        self:levelUp5Tip()
    elseif self.m_levelUpTriggerIndex == LevelUp_Trigger_Push.NewPlayerUnlockLevelTip then
        self:levelUpTriggerNewLevelTip()
    elseif self.m_levelUpTriggerIndex == LevelUp_Trigger_Push.NewPlayerUnlockLuckyChallenge then
        local luckyChallengeData = G_GetMgr(ACTIVITY_REF.LuckyChallenge):getRunningData()
        if globalData.userRunData.levelNum == globalData.constantData.CHALLENGE_OPEN_LEVEL and luckyChallengeData and luckyChallengeData:isAllOpen() then
            self:levelupTriggerLuckyChallenge()
        else
            self:nextLevelUpTrigger()
        end
    elseif self.m_levelUpTriggerIndex == LevelUp_Trigger_Push.NewUserCardOpen then
        local function callFunc()
            self:nextLevelUpTrigger()
        end
        if globalData.userRunData.levelNum == 15 then
            G_GetMgr(ACTIVITY_REF.CardOpenNewUser):showMainLayer(nil, callFunc)
        else
            callFunc()
        end
    elseif self.m_levelUpTriggerIndex == LevelUp_Trigger_Push.GrowthFundTip then
        local function callFunc()
            self:nextLevelUpTrigger()
        end
        -- 判断是否可以弹出成长基金
        local _mgr = G_GetMgr(G_REF.GrowthFund)
        if _mgr and _mgr:isTriggerAutoPopMainLayer() then
            if not _mgr:isUnlock() then
                gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "GrowthFund")
                gLobalSendDataManager:getLogFeature():sendOpenNewLevelLog("Open", {pn = "GrowthFund"})
            end
            local _layer = _mgr:showMainLayer()
            if _layer then
                _layer:setOverFunc(callFunc)
            end
        else
            callFunc()
        end
    else
        -- 扩展
    end
end

-- 升级后 赠送等级里程碑优惠券 触发弹框
function BaseMachineGameEffect:levelUpTriggerCouponTicket()
    local _mgr = G_GetMgr(G_REF.MSCRate)
    if _mgr and _mgr:checkMileStoneCouponLevelup() then
        _mgr:showMileStoneCouponLevelup(
            function()
                if self.nextLevelUpTrigger then
                    self:nextLevelUpTrigger()
                end
            end
        )
    else
        self:nextLevelUpTrigger()
    end
end

-- 升级后触发弹出新关卡
function BaseMachineGameEffect:levelUp5Tip()
    -- cxc 2021年06月23日16:09:54 不弹出这个板子了
    -- if not globalData.GameConfig:checkUseNewNoviceFeatures() and globalData.userRunData.levelNum == globalData.constantData.MOREGAME_TIPS_LEVEL and self:isPlayOnly1() then
    --     self.m_isShow5Tip = true

    --     local levelupView =
    --         util_createView(
    --         "views.gameviews.GuideLevelup5Tip",
    --         function()
    --             self:nextLevelUpTrigger()
    --         end
    --     )
    --     if levelupView ~= nil then
    --         -- 引导打点：MoreGame引导-1.触发引导
    --         gLobalSendDataManager:getLogGuide():setGuideParams(6, {isForce = false, isRepeat = false, guideId = nil})
    --         gLobalSendDataManager:getLogGuide():sendGuideLog(6, 1)

    --         if gLobalSendDataManager.getLogPopub then
    --             gLobalSendDataManager:getLogPopub():addNodeDot(levelupView, "Push", DotUrlType.UrlName, true, DotEntrySite.LevelUpPush, DotEntryType.Game)
    --         end

    --         gLobalViewManager:showUI(levelupView, ViewZorder.ZORDER_UI)

    --     end
    -- else
    --     self:nextLevelUpTrigger()
    -- end
    self:nextLevelUpTrigger()
end

-- 升级后触发卡牌掉落逻辑
function BaseMachineGameEffect:levelUpTriggerDropCards()
    if CardSysManager:needDropCards("Level Up") == true then
        -- 正常掉落
        CardSysManager:doDropCards(
            "Level Up",
            function()
                if self.nextLevelUpTrigger then
                    self:nextLevelUpTrigger()
                end
            end
        )
    else
        self:nextLevelUpTrigger()
    end
end

-- 触发新赛季引导 --
function BaseMachineGameEffect:levelUpTriggerCardNewSeason()
    if CardSysManager:needDropCards("New Player") == true and globalData.userRunData.levelNum == globalData.constantData.CARD_OPEN_LEVEL then
        -- CardSysManager:showDropCardGuide(
        --     function()
        --         -- 引导结束逻辑：
        --         -- 1. 点击X退出界面，引导结束并且掉落引导卡包
        --         CardSysManager:setInGuide(false)
        --         CardSysManager:doDropCards("New Player", function()
        --             if self.nextLevelUpTrigger then
        --                 self:nextLevelUpTrigger()
        --             end
        --         end)
        --     end,
        --     function()
        --         CardSysManager:doDropCards("New Player", function()
        --             if self.nextLevelUpTrigger then
        --                 self:nextLevelUpTrigger()
        --             end
        --         end)
        --         -- -- 引导结束逻辑：
        --         -- -- 2. 点击show进入集卡系统，在关闭集卡系统回到大厅时，结束引导并且掉落引导卡包
        --         -- CardSysManager:setAutoEnterCard(true)
        --         -- CardSysManager:setEnterCardFroceSeason(true)
        --         -- -- 直接退出关卡，所以不用走之后的触发逻辑了，如果之后有其他触发逻辑，请质问策划的垃圾需求！！！
        --         -- gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        --     end
        -- )
        -- 开启等级的掉落走引导逻辑

        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_CardOpen)
        end

        --没有资源不弹引导界面直接掉卡
        if not CardSysManager:isDownLoadCardRes() then
            CardSysManager:doDropCards(
                "New Player",
                function()
                    if self.nextLevelUpTrigger then
                        self:nextLevelUpTrigger()
                    end
                end
            )
            return
        end

        -- CardSysManager:setInGuide(true)
        -- 引导打点：Card引导-1.提示面板展示
        gLobalSendDataManager:getLogGuide():setGuideParams(8, {isForce = false, isRepeat = false})
        gLobalSendDataManager:getLogGuide():sendGuideLog(8, 1)

        CardSysManager:doDropCards(
            "New Player",
            function()
                if self.nextLevelUpTrigger then
                    self:nextLevelUpTrigger()
                end
            end
        )
    else
        self:nextLevelUpTrigger()
    end
end

function BaseMachineGameEffect:levelUpTriggerNewLevelTip()
    -- 同时判断, 同时触发下一个
    -- 当前关卡是否是樱桃关卡；玩家没有进入过其他关卡，当前等级是5级
    local isEnterOtherLevel = gLobalDataManager:getNumberByField("NewPlayerUnlockLevelTip_" .. globalData.userRunData.uid, 0)
    -- cxc 2021年06月23日16:09:54 不弹出这个板子了
    if
        not globalData.GameConfig:checkUseNewNoviceFeatures() and self.m_isShow5Tip and globalData.slotRunData.machineData.p_levelName == "GameScreenCharms" and isEnterOtherLevel ~= 1 and
            globalData.userRunData.levelNum == globalData.constantData.MOREGAME_TIPS_LEVEL
     then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEW_PLAYER_UNLOCK_LEVEL)
    end
    self:nextLevelUpTrigger()
end

-- 升级后触发逻辑 end --------------------------------------------------------------------------------------

---
-- 触发respin 玩法
--
function BaseMachineGameEffect:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    self:clearCurMusicBg()
    self:levelDeviceVibrate(6, "respin")
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1,
            self:getModuleName()
        )
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

function BaseMachineGameEffect:showRespinView(effectData)
end

function BaseMachineGameEffect:showEffect_RespinOver(effectData)
    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    self:removeRespinNode()
    self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function BaseMachineGameEffect:showEffect_Unlock(effectData)
    local oldlevel = self.m_unLockPreLevel
    local levels = globalData.slotRunData.p_machineOriDatas
    local levelName = nil
    local maxLevel = 0
    local index = 1
    for i = 1, #levels do
        if not levels[i].p_highBetFlag and levels[i].p_openLevel <= globalData.userRunData.levelNum and oldlevel and oldlevel < levels[i].p_openLevel and levels[i].p_openLevel > maxLevel then
            maxLevel = levels[i].p_openLevel
            levelName = levels[i].p_levelName
            index = i
            break
        end
    end

    -- 新手期abtest 4.0 新增条件 用户等级需要大于限制等级才能弹出关卡解锁
    -- csc 2021-11-29 11:55:34 取消掉4.0判断，保留等级判断
    local canPop = true
    if globalData.userRunData.levelNum < globalData.constantData.NOVICE_UNLOCK_NEW_LEVEL then
        canPop = false
    end

    if not levelName or not canPop then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end

    local unlock = util_createView("views.unlock.UnlockMachine", {levelName, index})
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(unlock, "Push", DotUrlType.UrlName, true, DotEntrySite.LevelUpPush, DotEntryType.Game)
    end
    gLobalViewManager:showUI(unlock, nil, false)
    effectData.p_isPlay = true
    self:playGameEffect()
    return true
end

function BaseMachineGameEffect:showEffect_PushSlot(effectData)
    local slotId = globalMachineController:getPushGameId()

    globalMachineController:clearPushGameId()
    -- 查找关卡信息
    local info = globalData.slotRunData:getLevelInfoById(slotId)
    if not info then
        return false
    end
    -- 创建推送提示
    local pushTip = util_createView("views.gameviews.SpinPushGameNode")
    if pushTip then
        pushTip:updateView(info)
        gLobalViewManager:showUI(pushTip, nil, false)
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end

    return false
end

--quest结束弹窗
function BaseMachineGameEffect:showEffect_QuestComplete(effectData)
    self:showQuestCompleteTip()
    return true
end

--服务器版新的quest 结束
function BaseMachineGameEffect:showEffect_QuestCompleteNew(effectData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_DONE_SHOW)
    effectData.p_isPlay = true
    self:playGameEffect()
    return true
end

--解锁每日任务
function BaseMachineGameEffect:showEffect_OpenMissionLead(effectData)
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_MISSION_LEAD,
        function()
            if effectData ~= nil then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end
    )
    return true
end

--完成新手任务
function BaseMachineGameEffect:showEffect_NewbieTaskComplete(effectData)
    local taskData = globalNewbieTaskManager:getCurrentTaskData()
    if taskData then
        if taskData.p_id == 1 then
            globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskFinish1, true)
        elseif taskData.p_id == 2 then
            globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskFinish2, true)
        elseif taskData.p_id == 3 then
            globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskFinish3, true)
        end
    end
    globalNewbieTaskManager:completeTask(
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    )
    return true
end

function BaseMachineGameEffect:questCompleteTipCallBack(effectData)
    if effectData ~= nil then
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function BaseMachineGameEffect:showRespinOverView(effectData)
    -- body
end

---
-- 触发respin 玩法结束
--
function BaseMachineGameEffect:triggerRespinComplete()
    local effectLen = #self.m_gameEffects

    for i = 1, effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == GameEffect.EFFECT_RESPIN then
            effectData.p_isPlay = true
            break
        end
    end
end

---
-- 显示free spin over 动画
function BaseMachineGameEffect:showEffect_FreeSpinOver()
    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")
    if #self.m_reelResultLines == 0 then
        self.m_freeSpinOverCurrentTime = 1
    end

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime > 0 then
        self.m_fsOverHandlerID =
            scheduler.scheduleGlobal(
            function()
                if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime > 0 then
                    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
                else
                    self:showEffect_newFreeSpinOver()
                end
            end,
            0.1
        )
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function BaseMachineGameEffect:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
    self:clearCurMusicBg()
    self:showFreeSpinOverView()
end

function BaseMachineGameEffect:showFreeSpinOverView()
end

function BaseMachineGameEffect:triggerFreeSpinOverCallFun()
    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    self:postFreeSpinOverTriggerBigWIn(_coins)
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()

    self:resetMusicBg()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function BaseMachineGameEffect:levelFreeSpinOverChangeEffect()
end

---
-- 添加游戏内动画 effect
-- @param effectType int 新添加的类型
-- @param effectData 自定义effect 所需要的参数
function BaseMachineGameEffect:addAnimationOrEffectType(effectType, data)
    local effectLen = #self.m_vecSymbolEffectType
    local insertPos = -1
    for i = 1, effectLen, 1 do
        local value = self.m_vecSymbolEffectType[i]
        if value == effectType then
            return
        end
    end

    self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = effectType
end
---
-- 检测是否有否中类型
function BaseMachineGameEffect:checkHasEffectType(effectType)
    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen, 1 do
        local value = self.m_vecSymbolEffectType[i]
        if value == effectType then
            return true
        end
    end

    return false
end

---
-- 检测是否存在某种类型， 并且删除
function BaseMachineGameEffect:removeEffectByType(effectType)
    if effectType == GameEffect.EFFECT_FREE_SPIN_OVER then
        if self.m_fsOverHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
            self.m_fsOverHandlerID = nil
        end
    end
    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen, 1 do
        local value = self.m_vecSymbolEffectType[i]
        if value == effectType then
            table.remove(self.m_vecSymbolEffectType, i)
            return true
        end
    end

    return false
end

---
--检测m_gameEffects播放effect表中是否有该类型
function BaseMachineGameEffect:checkHasGameEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType then
            return true
        end
    end

    return false
end

---
--删除m_gameEffects中的Effect动画
function BaseMachineGameEffect:removeGameEffectType(effectType)
    if effectType == GameEffect.EFFECT_FREE_SPIN_OVER then
        if self.m_fsOverHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
            self.m_fsOverHandlerID = nil
        end
    end
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType then
            table.remove(self.m_gameEffects, i)

            return true
        end
    end

    return false
end

---
-- 自定义添加self effect
--
function BaseMachineGameEffect:addSelfEffect()
end

---
-- 播放自定义效果
-- @param effectData GameEffectData 根据effectData 来决定播放具体动画， 这样区分开每个不同关卡的不同动画
--
function BaseMachineGameEffect:MachineRule_playSelfEffect(effectData)
    return false
end

function BaseMachineGameEffect:levelupTriggerLuckyChallenge()
    local guideLc =
        util_createView(
        "views.noviceGuide.LuckyChallengeGuideLayer",
        function()
            self:nextLevelUpTrigger()
        end
    )
    gLobalViewManager:showUI(guideLc, ViewZorder.ZORDER_UI)
end

-- 是否是控制轮
-- 有些活动只能在控制实现所以把mini轮与控制轮作区分
function BaseMachineGameEffect:checkControlerReelType()
    return true
end

-- 活动赠送免费spin次数

function BaseMachineGameEffect:checkAddRewaedStartFSEffect()
    local features = self.m_runSpinResultData.p_features or {}

    if not self.m_isOpenRewaedFreeSpin then
        return false
    elseif #features >= 2 then
        -- 特殊玩法触发那一次不添加
        return false
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if freeSpinsTotalCount and freeSpinsLeftCount then
            if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
                return true -- 最后一次free添加
            end
        end

        return false
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
        local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
        if reSpinsTotalCount and reSpinCurCount then
            if reSpinsTotalCount > 0 and reSpinCurCount == 0 then
                return true -- 最后一次respin添加
            end
        end

        return false
    end

    return true
end

function BaseMachineGameEffect:checkAddRewaedOverFSEffect()
    local features = self.m_runSpinResultData.p_features or {}

    if not self.m_isOpenRewaedFreeSpin then
        return false
    elseif #features >= 2 then
        -- 特殊玩法触发那一次不添加
        return false
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        if freeSpinsTotalCount and freeSpinsLeftCount then
            if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
                return true -- 最后一次free添加
            end
        end

        return false
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
        local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
        if reSpinsTotalCount and reSpinCurCount then
            if reSpinsTotalCount > 0 and reSpinCurCount == 0 then
                return true -- 最后一次respin添加
            end
        end

        return false
    end

    return true
end

function BaseMachineGameEffect:addRewaedFreeSpinStartEffect()
    if self:checkAddRewaedStartFSEffect() then
        if self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE then
            local data = self.m_rewaedFSData or {}
            local reFsLeftTimes = data.leftTimes or 0
            local reFsTotalTimes = data.times or 0
            if reFsTotalTimes > self.m_reFsLastTime and reFsLeftTimes > self.m_reFsLastTime then
                self:removeGameEffectType(GameEffect.EFFECT_REWARD_FS_START)

                local rewardEffect = GameEffectData.new()
                rewardEffect.p_effectType = GameEffect.EFFECT_REWARD_FS_START
                rewardEffect.p_effectOrder = GameEffect.EFFECT_REWARD_FS_START
                self.m_gameEffects[#self.m_gameEffects + 1] = rewardEffect
            end
        end
    end
end

function BaseMachineGameEffect:addRewaedFreeSpinOverEffect()
    if self:checkAddRewaedOverFSEffect() then
        if self.m_bProduceSlots_InRewaedFreeSpin then
            local data = self.m_rewaedFSData or {}
            local reFsLeftTimes = data.leftTimes or 0
            local reFsTotalTimes = data.times or 0
            if reFsTotalTimes > 0 and reFsLeftTimes == self.m_reFsLastTime then
                self:removeGameEffectType(GameEffect.EFFECT_REWARD_FS_OVER)

                local rewardEffect = GameEffectData.new()
                rewardEffect.p_effectType = GameEffect.EFFECT_REWARD_FS_OVER
                rewardEffect.p_effectOrder = GameEffect.EFFECT_REWARD_FS_OVER
                self.m_gameEffects[#self.m_gameEffects + 1] = rewardEffect
            end
        end
    end
end

function BaseMachineGameEffect:showEffect_RewaedFreeSpinStart(effectData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:setCurrSpinMode(REWAED_FREE_SPIN_MODE)
    self.m_bProduceSlots_InRewaedFreeSpin = true

    local params = {}
    params.func = function()
        -- 修改bet 为特殊赠送spin的bet
        local data = self.m_rewaedFSData or {}
        local betCoin = data.bet
        local betList = globalData.slotRunData.machineData:getMachineCurBetList()
        for i = 1, #betList do
            local bets = betList[i]
            if bets.p_totalBetValue >= betCoin then
                globalData.slotRunData.iLastBetIdx = bets.p_betId
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
                break
            end
        end

        effectData.p_isPlay = true
        self:playGameEffect() -- 继续播放动画
    end
    gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_START, params)

    return true
end

--[[
    收集角标
]]
function BaseMachineGameEffect:showEffect_collectSign(effectData)
    effectData.p_isPlay = true
    self:playGameEffect() -- 继续播放动画
    return true
end

function BaseMachineGameEffect:showEffect_RewaedFreeSpinOver(effectData)
    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    self.m_bProduceSlots_InRewaedFreeSpin = false

    local params = {}
    params.func = function()
        -- 切换当前bet为上一次的bet
        self:checkUpateDefaultBet()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

        effectData.p_isPlay = true
        self:playGameEffect() -- 继续播放动画
    end
    gLobalNoticManager:postNotification(ViewEventType.REWARD_FREE_SPIN_OVER, params)

    return true
end

function BaseMachineGameEffect:getWinEffect(_winAmonut)
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = _winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end
    return winEffect
end

function BaseMachineGameEffect:postFreeSpinOverTriggerBigWIn(_coins)
    local winEffect = self:getWinEffect(_coins)
    if winEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FREESPIN_OVER_BIGWIN, winEffect)
    end
end

function BaseMachineGameEffect:postReSpinOverTriggerBigWIn(_coins)
    local winEffect = self:getWinEffect(_coins)
    if winEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_OVER_BIGWIN, winEffect)
    end
end

function BaseMachineGameEffect:checkFirstSalePop(_curLevel)
    -- 如果没有首充,直接走原先的逻辑
    local canPop = globalData.GameConfig:checkInFlationLevels(_curLevel)
    local firstCommSaleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
    if firstCommSaleData then
        -- 有首充的情况下，检测一下当前等级是否有在限制区间内
        if globalData.constantData.NOVICE_FIRSTPAY_POPLEVEL and #globalData.constantData.NOVICE_FIRSTPAY_POPLEVEL > 0 then
            for i = 1, #globalData.constantData.NOVICE_FIRSTPAY_POPLEVEL do
                local levelList = globalData.constantData.NOVICE_FIRSTPAY_POPLEVEL[i]
                local levelLimit = tonumber(levelList[1])
                local levelPop = tonumber(levelList[2])
                if globalData.userRunData.levelNum >= levelLimit and globalData.userRunData.levelNum <= levelPop then
                    canPop = false
                    release_print("----csc checkFirstSalePop 当前玩家等级 符合限制条件 [" .. levelLimit .. "," .. levelPop .. "]")
                    if globalData.userRunData.levelNum == levelPop then
                        canPop = true
                    end
                    break
                end
            end
        end
    end

    return canPop
end

--[[
    触发玩法时的震动
    _sFeature : 'free' 'respin' 'bonus' ‘pickFeature‘ 'jackpot' 关卡内自己需要震动的玩法'

    一些关卡由于自身逻辑在三个玩法触发时不播震动, 重写这个接口即可。不用重写三个事件触发的底层接口
]]
function BaseMachineGameEffect:levelDeviceVibrate(_vibrateType, _sFeature)
    if not gLobalDataManager:getBoolByField("isDeviceVibrate",true) then
        return
    end
    local sMsg = "[BaseMachineGameEffect:levelDeviceVibrate] " .. _vibrateType .. " " .. _sFeature
    util_printLog(sMsg, true)
    globalPlatformManager:deviceVibrate(_vibrateType)
end

function BaseMachineGameEffect:addOneSelfEffect(_sEType, _sEORder)
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = _sEORder
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = _sEType
end

return BaseMachineGameEffect
