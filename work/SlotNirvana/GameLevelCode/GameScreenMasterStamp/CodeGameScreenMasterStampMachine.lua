---
-- island li
-- 2019年1月26日
-- CodeGameScreenMasterStampMachine.lua
--
-- 玩法：
--
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseSlotoManiaMachine
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenMasterStampMachine = class("CodeGameScreenMasterStampMachine", BaseSlotoManiaMachine)

CodeGameScreenMasterStampMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMasterStampMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenMasterStampMachine.SYMBOL_SCORE_11 = 10
CodeGameScreenMasterStampMachine.SYMBOL_SCORE_12 = 11
CodeGameScreenMasterStampMachine.SYMBOL_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

CodeGameScreenMasterStampMachine.m_vecMiniWheel = {}

CodeGameScreenMasterStampMachine.PLAYSCENELOBBY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1

function CodeGameScreenMasterStampMachine:initGameStatusData(gameData)
    if gameData and gameData.spin and gameData.spin.selfData and gameData.spin.selfData.betCoins then
        globalData.slotRunData:setMasterStampBetCoins(gameData.spin.selfData.betCoins)
    end
    CodeGameScreenMasterStampMachine.super.initGameStatusData(self, gameData)
end

-- 构造函数
function CodeGameScreenMasterStampMachine:ctor()
    CodeGameScreenMasterStampMachine.super.ctor(self)
    globalData.slotRunData:setIsMasterStamp(true)
    self.m_spinMasterStampState = "init"
    self.m_wildMoveTime = 0
    self.m_FsDownTimes = 0
    self.m_spinStatesTimes = 0

    --init
    self:initGame()
end

function CodeGameScreenMasterStampMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMasterStampMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MasterStamp"
end

function CodeGameScreenMasterStampMachine:initCloumnSlotNodesByNetData()
    if true or self.m_initSpinData.p_reels == nil then
        self:initRandomSlotNodes()
    else
        CodeGameScreenMasterStampMachine.super.initCloumnSlotNodesByNetData(self)
    end
end

function CodeGameScreenMasterStampMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar
    self:findChild("sp_reel"):setVisible(false)
end

function CodeGameScreenMasterStampMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_FreeGameTime")
    self.m_baseFreeSpinBar = util_createView("MasterStampSrc.MasterStampFreespinBarView")
    if node_bar and self.m_baseFreeSpinBar then
        node_bar:addChild(self.m_baseFreeSpinBar)
    end
end

function CodeGameScreenMasterStampMachine:enterGamePlayMusic()
    -- gLobalSoundManager:playSound("MasterStampSounds/music_MasterStamp_enter.mp3")
end

function CodeGameScreenMasterStampMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    globalData.slotRunData:setIsMasterStamp(true)
    self:addObservers()

    self.m_vecMiniWheel = {}
    if self:checkTriggerOnEnterINFreeSpin() then
        print(">>>>>>>>>>>>>>>>>>>>>>>> freeSpin = ")
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local reel = self.m_runSpinResultData.p_selfMakeData.reelNum
        self:initFsMiniReels(reel)
        
    end
    CodeGameScreenMasterStampMachine.super.onEnter(self) -- 必须调用不予许删除
    --小轮盘赋值
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for i = 1, #self.m_vecMiniWheel do
            local miniMachine = self.m_vecMiniWheel[i]
            miniMachine:enterLevelMiniSelf()
            miniMachine:MachineRule_newInitGame()
        end
    end

end

function CodeGameScreenMasterStampMachine:checkTriggerOnEnterINFreeSpin()
    local isPlayGameEff = false

    if self.m_initSpinData then
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

        if isInFs == true then
            -- lxy 这我注释掉的可能有用
            if self.m_initSpinData.p_freeSpinsTotalCount ~= self.m_initSpinData.p_freeSpinsLeftCount then
                isPlayGameEff = true
            end
        end
    end

    return isPlayGameEff
end

function CodeGameScreenMasterStampMachine:addObservers()
    CodeGameScreenMasterStampMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_spinMasterStampState == "init" then
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

            local soundName = "MasterStampSounds/music_MasterStamp_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    gLobalNoticManager:addObserver(self, self.slotReelDownInFS, "MasterStampMiniDownInFS")
end

function CodeGameScreenMasterStampMachine:showEffect_NewWin(effectData, winType)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    CodeGameScreenMasterStampMachine.super.showEffect_NewWin(self, effectData, winType)
end

function CodeGameScreenMasterStampMachine:waitWithDelay(time, endFunc)
    if time <= 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            if endFunc then
                endFunc()
            end
            waitNode:removeFromParent()
        end,
        time
    )
end

function CodeGameScreenMasterStampMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMasterStampMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    globalData.slotRunData:setIsMasterStamp(false)
end

-- 插入棋盘
function CodeGameScreenMasterStampMachine:initFsMiniReels(reel)
    self.m_reelNum = reel
    self.m_gameBg:runCsbAction("freespin", true)
    self:runCsbAction("freespin_" .. reel, false)
    for i = 1, reel do
        -- 创建轮子
        local name = "Node_FG_Reel_" .. i
        local addNode = self.m_csbOwner[name]

        if addNode then
            local data = {}
            data.index = 3
            data.parent = self
            data.reelId = i
            data.unlock = i <= reel
            data.csbPath = "GameScreenMasterStamp_3x5"
            local miniMachine = util_createView("MasterStampSrc.MasterStampMiniMachine", data)
            addNode:addChild(miniMachine)
            if data.unlock then
                self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniMachine.m_touchSpinLayer)
            end
            table.insert(self.m_vecMiniWheel, miniMachine)
        end
    end
    -- 重新赋值一下
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    self:updateScaleMainLayer()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMasterStampMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_MasterStamp_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_MasterStamp_11"
    elseif symbolType == self.SYMBOL_SCORE_12 then
        return "Socre_MasterStamp_12"
    elseif symbolType == self.SYMBOL_FIX_BONUS then
        return "Socre_MasterStamp_FIx_Bonus"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMasterStampMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMasterStampMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_11, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_12, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_BONUS, count = 12}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenMasterStampMachine:MachineRule_initGame()
    self:resetMusicBg()
end

--
--单列滚动停止回调
--
function CodeGameScreenMasterStampMachine:slotOneReelDown(reelCol)
    CodeGameScreenMasterStampMachine.super.slotOneReelDown(self, reelCol)

    -- 落地音效播放函数-- 保证第二个参数的唯一性，防止多个小块或者快停落地音效重复播放
    -- self:playBulingSound(reelCol, "scatter", "MasterStampSounds/sound_MasterStamp_scatter_down.mp3")
end

--freespin下主轮调用父类停止函数
function CodeGameScreenMasterStampMachine:slotReelDownInFS()
    self.m_isReconnection = false
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    self:setGameSpinStage(STOP_RUN)
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

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

    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()
    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()
    self:checkNotifyUpdateWinCoin()
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMasterStampMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMasterStampMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenMasterStampMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("MasterStampSounds/music_MasterStamp_custom_enter_fs.mp3")
    if self.m_iFreeSpinTimes == 0 then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
    end
    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            self:createLittleReels(
                function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        0.1
    )
end

function CodeGameScreenMasterStampMachine:createLittleReels(func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local reels = selfdata.reelNum or 1
    self:initFsMiniReels(reels)
    --小轮盘赋值
    for i = 1, #self.m_vecMiniWheel do
        local miniMachine = self.m_vecMiniWheel[i]
        miniMachine:enterLevelMiniSelf()
    end
    if func then
        func()
    end
end

function CodeGameScreenMasterStampMachine:showFreeSpinOverView()
    -- gLobalSoundManager:playSound("MasterStampSounds/music_MasterStamp_over_fs.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:triggerFreeSpinOverCallFun()
        end
    )
    view:findChild("Button_1"):setTouchEnabled(false)
    performWithDelay(view,function()
        view:findChild("Button_1"):setTouchEnabled(true)
    end,20/30)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 651)
end

function CodeGameScreenMasterStampMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("MasterStampSrc.MasterStampBaseDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
    return view
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMasterStampMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self.m_isPlayMoveWildReelId = 1
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMasterStampMachine:addSelfEffect()
    -- 自定义动画创建方式
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMasterStampMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.PLAYSCENELOBBY_EFFECT then
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local totolWinNum = self.m_runSpinResultData.p_fsWinCoins
        local winRatio = totolWinNum / lTatolBetNum
        local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("MINZWin", "MINZWin_" .. winRatio)
        if view then
            view:setOverFunc(function()
                self:playSceneLobby()
            end)
        else
            self:playSceneLobby()
        end
    end
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMasterStampMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenMasterStampMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenMasterStampMachine.super.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenMasterStampMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    CodeGameScreenMasterStampMachine.super.slotReelDown(self)
end

function CodeGameScreenMasterStampMachine:beginReel()
    self.m_isReconnection = false
    self.m_isQuicklyStopReel = false

    self.m_spinMasterStampState = "spin"
    if self.m_bProduceSlots_InFreeSpin == true then
        if not globalData.slotRunData.freeSpinCount or globalData.slotRunData.freeSpinCount <= 0 then
            return
        end
        self.m_waitChangeReelTime = 0
        release_print("beginReel ... ")

        self:stopAllActions()
        self:requestSpinReusltData() -- 临时注释掉

        -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
        self.m_nScatterNumInOneSpin = 0
        self.m_nBonusNumInOneSpin = 0
        --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager.p_ViewLayer })
        local effectLen = #self.m_gameEffects
        for i = 1, effectLen, 1 do
            self.m_gameEffects[i] = nil
        end
        self:clearWinLineEffect()
        for i = 1, #self.m_vecMiniWheel do
            local mninReel = self.m_vecMiniWheel[i]
            if mninReel then
                mninReel:beginMiniReel()
            end
        end
    end
end

function CodeGameScreenMasterStampMachine:dealSmallReelsSpinStates()

end

function CodeGameScreenMasterStampMachine:spinResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "SPIN" then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if not spinData.result.selfData and not spinData.result.reels then
                    return
                end
            end
        end
    end
    self.m_FsDownTimes = 0
    self.m_spinStatesTimes = 0
    self.m_wildMoveTime = 0
    self:createSpinResultData(param)
    CodeGameScreenMasterStampMachine.super.spinResultCallFun(self, param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "SPIN" then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if spinData.result.freespin and spinData.result.selfData then
                    local resultDatas = spinData.result.selfData
                    for i = 1, #self.m_vecMiniWheel do
                        local mninReel = self.m_vecMiniWheel[i]
                        if i == 1 then
                            mninReel.m_serverWinCoins = spinData.result.winAmount
                        end
                        local dataName = "reels-" .. i
                        local miniReelsResultDatas = resultDatas[dataName]
                        if miniReelsResultDatas ~= nil then
                            miniReelsResultDatas.bet = spinData.result.bet
                            miniReelsResultDatas.action = spinData.result.action
                            miniReelsResultDatas.freespin = spinData.result.freespin
                            miniReelsResultDatas.freespin.freeSpinsTotalCount = 0
                            miniReelsResultDatas.freespin.freeSpinsLeftCount = 0
                            miniReelsResultDatas.payLineCount = spinData.result.payLineCount
                            miniReelsResultDatas.selfData = {}
                            miniReelsResultDatas.selfData.specialSignals = miniReelsResultDatas.specialSignals
                            mninReel:netWorkCallFun(miniReelsResultDatas)
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenMasterStampMachine:createSpinResultData(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "SPIN" then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if spinData.result.freespin and spinData.result.selfData then
                    local resultDatas = spinData.result.selfData
                    for i = 1, 4 do
                        local dataName = "reels-" .. i
                        local miniReelsResultDatas = resultDatas[dataName]
                        if miniReelsResultDatas ~= nil then
                            if i == 1 then
                                spinData.result.lines = miniReelsResultDatas.lines
                                spinData.result.nextReel = miniReelsResultDatas.nextReel
                                spinData.result.prevReel = miniReelsResultDatas.prevReel
                                spinData.result.reels = miniReelsResultDatas.reels
                            end
                            self.m_isPlayMoveWild = miniReelsResultDatas.specialSignals
                            if miniReelsResultDatas.specialSignals then
                                self.m_wildMoveTime = 1.4
                                self.m_isPlayMoveWildReelId = i
                            end
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenMasterStampMachine:updateResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
end

function CodeGameScreenMasterStampMachine:playEffectNotifyChangeSpinStatus()
    CodeGameScreenMasterStampMachine.super.playEffectNotifyChangeSpinStatus(self)
   
end

function CodeGameScreenMasterStampMachine:setFsAllRunDown(times)
    self.m_FsDownTimes =  self.m_FsDownTimes + times
    if self.m_FsDownTimes >= self.m_reelNum then
        gLobalNoticManager:postNotification("MasterStampMiniDownInFS")
    end
end

function CodeGameScreenMasterStampMachine:showEffect_LineFrame(effectData)
    self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:showLineFrame()
    else
        -- self:checkNotifyUpdateWinCoin()
    end

    if
        self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or
            self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN)
     then
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

-----------------------------------关闭左侧活动----------------------------

function CodeGameScreenMasterStampMachine:getBottomUINode()
    return "MasterStampSrc.MasterStampGameBottomNode"
end

function CodeGameScreenMasterStampMachine:triggerFreeSpinOverCallFun()
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
    -- self:hideFreeSpinBar()

    self:resetMusicBg()
    self:createSceneLobby()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function CodeGameScreenMasterStampMachine:createSceneLobby()
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.PLAYSCENELOBBY_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.PLAYSCENELOBBY_EFFECT -- 动画类型
end

function CodeGameScreenMasterStampMachine:playSceneLobby()
    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if minzMgr and minzMgr:getRunningData() then
        local levelInfo = minzMgr:getLastEnterLevelInfo()
        local data = minzMgr:getRunningData()
        local activeAlbum = data:getAlbumDataByActive()
        if activeAlbum then
            local uiView = minzMgr:showMainLayer()
            if not uiView then
                if levelInfo then
                    gLobalViewManager:gotoSlotsScene(levelInfo)
                else
                    gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
                end
            end
        else
            local isMinzLevel = minzMgr:isMinzLevel(levelInfo)
            if levelInfo and not isMinzLevel then
                gLobalViewManager:gotoSlotsScene(levelInfo)
            else
                gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
            end
        end
    else
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    end
end

-- 显示paytableview 界面
-- function CodeGameScreenMasterStampMachine:showPaytableView()
-- end

function CodeGameScreenMasterStampMachine:updateScaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    local size = cc.size(1082, 600)
    local winSize = display.size
    if self.m_reelNum == 2 then
        size = cc.size(1190, 292)
    end
    size.width = size.width * 1.1
    -- size.height = size.height * 1.1
    local height = winSize.height - uiBH - uiH
    local width = winSize.width
    local scale1 = width / size.width
    local scale2 = height / size.height
    local scale = math.min(scale1, scale2)
    scale = scale / self.m_machineRootScale
    self:findChild("Node_reels"):setScale(scale)
end

function CodeGameScreenMasterStampMachine:getGameTopNodeLuaPath()
    return "MasterStampSrc.MasterStampGameTopNode"
end

function CodeGameScreenMasterStampMachine:checkNotifyUpdateWinCoin()
    local isNotPlay = true
    for i = 1, #self.m_vecMiniWheel do
        local miniMachine = self.m_vecMiniWheel[i]
        local _winLines = miniMachine.m_reelResultLines
        if _winLines and #_winLines > 0 then
            isNotPlay = false
            break
        end
    end
    if isNotPlay then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    local freeWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    globalData.slotRunData.lastWinCoin = freeWinCoins
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenMasterStampMachine:setFsAllSpinStates(times)

    self.m_spinStatesTimes =  self.m_spinStatesTimes + times
    if self.m_spinStatesTimes >= self.m_reelNum then
        self.m_isPlayMoveWild = nil
        CodeGameScreenMasterStampMachine.super.dealSmallReelsSpinStates(self)
    end
end

return CodeGameScreenMasterStampMachine
