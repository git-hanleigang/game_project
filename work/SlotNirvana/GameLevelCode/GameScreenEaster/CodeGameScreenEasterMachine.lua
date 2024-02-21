---
-- island li
-- 2019年1月26日
-- CodeGameScreenEasterMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlots = require "Levels.BaseSlots"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local CodeGameScreenEasterMachine = class("CodeGameScreenEasterMachine", BaseFastMachine)

CodeGameScreenEasterMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenEasterMachine.BONUS_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- base下 收集wild 没有进度 只有不同状态 是否触发收集玩法 与收集数量无关
CodeGameScreenEasterMachine.BONUS_FS_WILD_LOCK_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 两个轮盘 金色scatter图标会转换成wild固定并复制到另一个轮盘
CodeGameScreenEasterMachine.BONUS_FS_ADD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --freespin下 scatter图标出现 会额外增加1-3次freegame次数

CodeGameScreenEasterMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenEasterMachine.SYMBOL_SCATTER_GOLD = 97 -- 金色Scatter
CodeGameScreenEasterMachine.SYMBOL_SCATTER_WILD = 98 -- Scatter变成的wild

CodeGameScreenEasterMachine.SYMBOL_SCATTER_TURN_WILD = 108 -- scatter 变成wild的过程

CodeGameScreenEasterMachine.m_ReelDownMaxCount = 2

-- 构造函数
function CodeGameScreenEasterMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

    -- 小块，连线框，基础baseDialog弹板csb 根据实际帧率设置
    self.m_slotsAnimNodeFps = 60
    self.m_lineFrameNodeFps = 60
    self.m_baseDialogViewFps = 60

    self.m_FSLittleReelsDownIndex = 0 -- FS停止计数
    self.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数
    self.m_miniFsReelTop = nil -- freespin 小轮子
    self.m_miniFsReelDown = nil -- freespin 小轮子
    self.m_lanzi = nil
    self.m_collectList = {}
    self.m_collectEffectData = nil
    -- 篮子状态
    self.m_phase = 1
    self.m_reconnect = false

    self.m_rabbit_status = 1
    -- 篮子升级
    self.m_upgrade = false
    --init
    self:initGame()

    --假滚滚动存储类型
    self.m_mysterList = {}
    for i = 1, self.m_iReelColumnNum do
        self.m_mysterList[i] = -1
    end
    self.m_bInBonus = false
end

function CodeGameScreenEasterMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("EasterConfig.csv", "LevelEasterConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenEasterMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Easter"
end

-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenEasterMachine:getNetWorkModuleName()
    return "Easter"
end

function CodeGameScreenEasterMachine:initUI()
    self.m_reelRunSound = "EasterSounds/sound_Easter_fast_run.mp3"
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    self.m_jackPotNode = util_createView("CodeEasterSrc.EasterJackPotBarView")
    self:findChild("Jackpotbar"):addChild(self.m_jackPotNode)
    self.m_jackPotNode:runCsbAction("idle", true)
    self.m_jackPotNode:initMachine(self)

    self.m_freespinSpinbar = util_createView("CodeEasterSrc.EasterFreespinBarView")
    self:findChild("FreeGameTip"):addChild(self.m_freespinSpinbar)
    self.m_freespinSpinbar:setVisible(false)
    self.m_baseFreeSpinBar = self.m_freespinSpinbar

    --特效层
    self.m_node_effect = cc.Node:create()
    self:findChild("root"):addChild(self.m_node_effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    --todo
    self.m_miniFsReelTop = self:createrOneReel(2, "Node_top")
    self.m_miniFsReelDown = self:createrOneReel(1, "Node_down")
    self.m_miniFsReelDown:findChild("Particle_1"):setVisible(false)
    self.m_miniFsReelDown:findChild("Particle_1_0"):setVisible(false)
    self.m_miniFsReelDown:findChild("Particle_3"):setVisible(false)
    self:findChild("Node_freespin"):setVisible(false)

    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniFsReelTop.m_touchSpinLayer)
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniFsReelDown.m_touchSpinLayer)
    end
    

    --todo
    self.m_rabbit = util_spineCreate("Easter_idle", true, true)
    self:findChild("lanzi"):addChild(self.m_rabbit, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)

    self.m_rabbit2 = util_spineCreate("Easter_idle2", true, true)
    self:findChild("lanzi_0"):addChild(self.m_rabbit2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    self.m_rabbit2:setVisible(false)

    self:changeRabbit()

    self.m_lanzi = util_spineCreate("Easter_idle_lanzi", true, true)
    self:findChild("lanzi"):addChild(self.m_lanzi, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    util_spinePlay(self.m_lanzi, "lanziidle1", true)

    self.m_guoChangRabbit = util_spineCreate("Easter_freeguochang", true, true)
    self:addChild(self.m_guoChangRabbit, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.m_guoChangRabbit:setPosition(display.width / 2, display.height / 2)

    self.m_guoChangLanZi = util_spineCreate("Easter_idle_lanziguochang", true, true)
    self:addChild(self.m_guoChangLanZi, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.m_guoChangLanZi:setPosition(display.width / 2, display.height / 2)
    self.m_guoChangLanZi:setVisible(false)

    self.m_grass = util_spineCreate("Easter_effect_bg_grass", true, true)
    self.m_gameBg:findChild("Node_grass"):addChild(self.m_grass)
    util_spinePlay(self.m_grass, "actionframe", true) -- base
    -- util_spinePlay(self.m_grass,"actionframe2",true) -- fs

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
                return
            end

            if self:isTriggerBonusGame() then
                return
            end

            local isFreeSpinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
            if not isFreeSpinOver and self.m_bIsBigWin then
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
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = "EasterSounds/music_Easter_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId, self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenEasterMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = "EasterSounds/sound_Easter_scatter_ground.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenEasterMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            self:playEnterGameSound("EasterSounds/sound_Easter_enter.mp3")
            self:resetMusicBg()
            self:setMinMusicBGVolume()
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenEasterMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenEasterMachine:addObservers()
    BaseFastMachine.addObservers(self)
end

function CodeGameScreenEasterMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    self:removeChangeReelDataHandler()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenEasterMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Easter_10"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_Easter_Scatter1"
    elseif symbolType == self.SYMBOL_SCATTER_GOLD then
        return "Socre_Easter_Scatter2"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_Easter_Wild1"
    elseif symbolType == self.SYMBOL_SCATTER_WILD then
        return "Socre_Easter_Wild2"
    elseif symbolType == self.SYMBOL_SCATTER_TURN_WILD then
        return "Socre_Easter_Scatter_Wild"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenEasterMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCATTER_GOLD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCATTER_TURN_WILD, count = 2}

    return loadNode
end

---
--设置bonus scatter 层级
function CodeGameScreenEasterMachine:getBounsScatterDataZorder(symbolType)
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

---
-- 根据类型获取对应节点
--
function CodeGameScreenEasterMachine:getSlotNodeBySymbolType(symbolType)
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

function CodeGameScreenEasterMachine:getBaseReelGridNode()
    return "CodeEasterSrc.EasterSlotFastNode"
end

function CodeGameScreenEasterMachine:getRandomStatus()
    while true do
        local status = xcyy.SlotsUtil:getArc4Random() % 4
        if self.m_rabbit_status ~= status then
            return status
        end
    end
end


--[[
    --兔子播放规则
    idle1-3 四条时间线随机播放   如果播放了idle3 则根据情况播放Easter_idle_lanz文件ilanziidle456三条时间线，
    之后播放idle4，idle4结束后继续随机idle，idle1-3
]]
function CodeGameScreenEasterMachine:changeRabbit(_flag)
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bInBonus then
        return
    end
    if not _flag then
        _flag = 1
    end
    self.m_rabbit_status = _flag
    if self.m_rabbit_status <= 4 then
        local actionName = "idle" .. self.m_rabbit_status

        if self.m_rabbit_status == 0 then
            actionName = "idle"
        end

        if self.m_rabbit_status == 1 then
            self.m_rabbit2:setVisible(true)
            util_spinePlay(self.m_rabbit2, "idle1_shou", false)
            util_spineEndCallFunc(
                self.m_rabbit2,
                "idle1_shou",
                function()
                    self.m_rabbit2:setVisible(false)
                end
            )
        end

        util_spinePlay(self.m_rabbit, actionName, false)
        util_spineEndCallFunc(
            self.m_rabbit,
            actionName,
            function()
                if self.m_rabbit_status == 3 then
                    if self.m_upgrade then
                        self:changeRabbit()
                        return
                    end
                    local phase = self.m_phase + 3
                    util_spinePlay(self.m_lanzi, "lanziidle" .. phase, false)
                    util_spineEndCallFunc(
                        self.m_lanzi,
                        "lanziidle" .. phase,
                        function()
                            util_spinePlay(self.m_lanzi, "lanziidle" .. self.m_phase, true)
                        end
                    )
                    local waitNode = cc.Node:create()
                    self:addChild(waitNode)
                    performWithDelay(
                        waitNode,
                        function()
                            waitNode:removeFromParent()
                            self:changeRabbit(4)
                        end,
                        25 / 30
                    )
                else
                    local status = self:getRandomStatus()
                    self:changeRabbit(status)
                end
            end
        )
    end
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenEasterMachine:MachineRule_initGame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --freespin断线重连
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local lockPosList = selfData.lockWild or {}

        if self.m_miniFsReelTop then
            self.m_miniFsReelTop:initFsLockWild(lockPosList)
        end

        if self.m_miniFsReelDown then
            self.m_miniFsReelDown:initFsLockWild(lockPosList)
        end

        self:showFreeSpinGameView()
        self:runCsbAction("idle_shenlun")
    else
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.cells then
            --collect
            --nothing
            self.m_gameBg:runCsbAction("idle_bacegame", true)
            util_spinePlay(self.m_grass, "actionframe", true)
            self:changeRabbit(0)
            self.m_bInBonus = true
        else
            self:showNormalSpinGameView()
        end
    end

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.phase then
        local phase = self.m_runSpinResultData.p_selfMakeData.phase
        self.m_phase = phase + 1
    end
    util_spinePlay(self.m_lanzi, "lanziidle" .. self.m_phase, true)
end

function CodeGameScreenEasterMachine:isTriggerBonusGame()
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.cells then
        return true
    end
    return false
end

------------------------------------------
-- 收集小游戏 断线处理
function CodeGameScreenEasterMachine:initFeatureInfo(spinData, featureData)
    if spinData.p_bonusStatus and spinData.p_bonusStatus ~= "CLOSED" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_reconnect = true
        -- 添加bonus effect
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenEasterMachine:slotOneReelDown(reelCol)
    BaseFastMachine.slotOneReelDown(self, reelCol)
    if reelCol > self:getMaxContinuityBonusCol() then
        if self.m_reelRunSoundTag ~= -1 then
            --停止长滚音效
            gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
            self.m_reelRunSoundTag = -1
        end
    end
end

-- 播放freespin轮盘背景动画触发
function CodeGameScreenEasterMachine:levelFreeSpinEffectChange()
end

--播放freespinover 轮盘背景动画触发
function CodeGameScreenEasterMachine:levelFreeSpinOverChangeEffect()
end
---------------------------------------------------------------------------
--判断是否有金色scatter 有的话变长spin时间
function CodeGameScreenEasterMachine:getHaveGoldScatter()
    local haveGoldScatter_top = self.m_miniFsReelTop:getHaveGoldScatter()
    local haveGoldScatter_down = self.m_miniFsReelDown:getHaveGoldScatter()
    if haveGoldScatter_top or haveGoldScatter_down then
        return true
    end
    return false
end

-- FreeSpinstart
function CodeGameScreenEasterMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("EasterSounds/sound_Easter_scatter_trigger.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local addFreespinTimesCallBackFun = function()
                self.m_freespinSpinbar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount, self.m_runSpinResultData.p_freeSpinsTotalCount)

                self.m_miniFsReelDown:restSelfGameEffects(self.BONUS_FS_ADD_EFFECT)
                self.m_miniFsReelTop:restSelfGameEffects(self.BONUS_FS_ADD_EFFECT)

                local winLines = self:getFsWinLines()
                if #winLines > 0 then
                    self:checkNotifyManagerUpdateWinCoin()
                end
            end

            if effectData.p_selfEffectType == self.BONUS_FS_ADD_EFFECT then
                self:addFreespinTimesByScatter(addFreespinTimesCallBackFun)
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        else
            gLobalSoundManager:playSound("EasterSounds/sound_Easter_freespin_start_tip.mp3")

            local view =
                self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self:showGuoChang(
                        function()
                            self.m_miniFsReelTop:setClipNodeEnable(false)
                            self:playShengLunParticle()
                            gLobalSoundManager:playSound("EasterSounds/sound_Easter_shenglun.mp3")
                            self:runCsbAction(
                                "actionframe",
                                false,
                                function()
                                    self.m_miniFsReelTop:setClipNodeEnable(true)
                                    self:runCsbAction("idle_shenlun")
                                    --这时候是第一次触发freespin 只需播放转化
                                    self:LockWildTurnAct(
                                        function()
                                            self:triggerFreeSpinCallFun()
                                            effectData.p_isPlay = true
                                            self:playGameEffect()
                                        end
                                    )
                                end
                            )
                        end
                    )

                    local waitNode = cc.Node:create()
                    self:addChild(waitNode)
                    performWithDelay(
                        waitNode,
                        function()
                            waitNode:removeFromParent(true)
                            self:showFreeSpinGameView()
                            self.m_freespinSpinbar:setVisible(true)
                            self.m_freespinSpinbar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount, self.m_runSpinResultData.p_freeSpinsTotalCount)
                            self.m_miniFsReelTop:ChangeScatterNode()
                            self.m_miniFsReelDown:CreateSlotNodeByData()
                        end,
                        1.8
                    )
                end
            )

            local freeSpinStartRabbit = util_spineCreate("Easter_FreeSpinStart", true, true)
            view:findChild("spine_tuzi"):addChild(freeSpinStartRabbit)
            util_spinePlay(freeSpinStartRabbit, "start")
            view:setBtnClickFunc(
                function()
                    util_spinePlay(freeSpinStartRabbit, "over")
                end
            )
        end
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        showFSView()
    else
        --  延迟0.5 不做特殊要求都这么延迟
        performWithDelay(
            self,
            function()
                showFSView()
            end,
            0.5
        )
    end
end

--播放升轮粒子效果
function CodeGameScreenEasterMachine:playShengLunParticle()
    self.m_miniFsReelTop:findChild("Particle_1"):resetSystem()
    self.m_miniFsReelTop:findChild("Particle_1_0"):resetSystem()
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent()
            self.m_miniFsReelTop:findChild("Particle_3"):resetSystem()
        end,
        40 / 60
    )
end

---
-- 显示free spin
function CodeGameScreenEasterMachine:showEffect_FreeSpin(effectData)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        effectData.p_isPlay = true
        self:playGameEffect()

        return true
    else
        if self.m_winSoundsId ~= nil then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        self.isInBonus = true

        return BaseFastMachine.showEffect_FreeSpin(self, effectData)
    end
end

---
-- 显示free spin over 动画
function CodeGameScreenEasterMachine:showEffect_FreeSpinOver()
    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")

    local lines = self:getFreeSpinReelsLines()

    if #lines == 0 then
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

function CodeGameScreenEasterMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("EasterSounds/sound_Easter_freespin_over_tip.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:triggerFreeSpinOverCallFun()
            self:RemoveAndCreateRuningFsReelSlotsNode()
            self:changeRabbit()
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 650)
    -- tang
    view:setBtnClickFunc(
        function()
            self:showNormalSpinGameView()
        end
    )
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenEasterMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_FSLittleReelsDownIndex = 0 -- FS停止计数
    self.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数
    self:removeChangeReelDataHandler()
    self:randomMystery()
    self.m_addSounds = {}
    return false -- 用作延时点击spin调用
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenEasterMachine:addSelfEffect()
    self.m_collectList = {}

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        --收集
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        table.insert(self.m_collectList, node)
                    end
                end
            end
        end
        if #self.m_collectList > 0 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.BONUS_COLLECT_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_COLLECT_EFFECT -- 动画类型
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        local feature = self.m_runSpinResultData.p_features
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

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenEasterMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.BONUS_COLLECT_EFFECT then
        self:showSelfEffect_Collect(effectData)
    elseif effectData.p_selfEffectType == self.BONUS_FS_ADD_EFFECT then
        self:showSelfEffect_FreeSpin(effectData)
    end

    return true
end

--wild收集
function CodeGameScreenEasterMachine:showSelfEffect_Collect(effectData)
    local isNeedWait = false

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.cells then
        isNeedWait = true
    end

    local tmpCollectList = self.m_collectList
    self.m_collectList = {}

    if #tmpCollectList > 0 then
        if not isNeedWait then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
        gLobalSoundManager:playSound("EasterSounds/sound_Easter_collect_wild.mp3")
        local endNode = self:findChild("lanzi")
        local endWorldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
        local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
        endPos.y = endPos.y + 50

        for i = 1, #tmpCollectList do
            local startNode = tmpCollectList[i]
            local startWorldPos = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
            local startPos = self:convertToNodeSpace(cc.p(startWorldPos.x, startWorldPos.y))

            local wildSp = util_createAnimation("Socre_Easter_Wild_tw.csb")

            wildSp:setPosition(startWorldPos)
            wildSp:runCsbAction("actionframe")

            self:addChild(wildSp, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)

            local flyNode = self:createFlyAct()

            wildSp:addChild(flyNode)

            local moveTo = cc.MoveTo:create(0.5, endPos)
            local func =
                cc.CallFunc:create(
                function()
                    if wildSp then
                        wildSp:removeFromParent()
                    end
                end
            )

            wildSp:runAction(cc.Sequence:create({moveTo, func}))
        end

        performWithDelay(
            self:findChild("lanzi"),
            function()
                self:playLanZiUpgrade(
                    function()
                        if isNeedWait then
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end
                )
            end,
            32 / 60
        )
    end
end

--播放篮子升级
function CodeGameScreenEasterMachine:playLanZiUpgrade(_func)
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.phase then
        local phase = self.m_runSpinResultData.p_selfMakeData.phase
        if self.m_phase == phase + 1 then
            self.m_upgrade = false
        else
            self.m_phase = phase + 1
            if self.m_phase ~= 1 then
                self.m_upgrade = true
            end
        end
    end

    if self.m_upgrade then
        -- 篮子收集特效
        local phase = self.m_phase - 1
        self.m_lanzi:stopAllActions()
        gLobalSoundManager:playSound("EasterSounds/sound_Easter_wild_fankui.mp3")
        util_spinePlay(self.m_lanzi, "shouji" .. phase)
        util_spineEndCallFunc(
            self.m_lanzi,
            "shouji" .. phase,
            function()
                if self.m_phase == 2 then
                    gLobalSoundManager:playSound("EasterSounds/sound_Easter_shengji1.mp3")
                else
                    gLobalSoundManager:playSound("EasterSounds/sound_Easter_shengji2.mp3")
                end
                util_spinePlay(self.m_lanzi, "shengji" .. (self.m_phase - 1) .. "_" .. self.m_phase)
                self.m_upgrade = false
                util_spineEndCallFunc(
                    self.m_lanzi,
                    "shengji" .. (self.m_phase - 1) .. "_" .. self.m_phase,
                    function()
                        util_spinePlay(self.m_lanzi, "lanziidle" .. self.m_phase, true)
                    end
                )
                if _func then
                    local dealyTime = 60 / 30
                    if self.m_phase == 3 then
                        dealyTime = 73 / 30
                    end
                    local waitNode = cc.Node:create()
                    self:addChild(waitNode)
                    performWithDelay(
                        waitNode,
                        function()
                            if _func then
                                _func()
                            end
                        end,
                        dealyTime
                    )
                end
            end
        )
    else
        -- 篮子收集特效
        gLobalSoundManager:playSound("EasterSounds/sound_Easter_wild_fankui.mp3")
        util_spinePlay(self.m_lanzi, "shouji" .. self.m_phase)
        util_spineEndCallFunc(
            self.m_lanzi,
            "shouji" .. self.m_phase,
            function()
                util_spinePlay(self.m_lanzi, "lanziidle" .. self.m_phase, true)
            end
        )
        if _func then
            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(
                waitNode,
                function()
                    if _func then
                        _func()
                    end
                end,
                1
            )
        end
    end
end

function CodeGameScreenEasterMachine:createFlyAct()
    local flyNode = util_createAnimation("Socre_Easter_Wild_tw_0.csb")

    flyNode:findChild("Particle_1"):setPositionType(0)
    flyNode:findChild("Particle_2"):setPositionType(0)

    return flyNode
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenEasterMachine:showEffect_Bonus(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
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

    self.m_collectEffectData = effectData

    self:showCollectGameView()

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
    return true
end

-- 显示free spin
function CodeGameScreenEasterMachine:showSelfEffect_FreeSpin(effectData)
    if effectData.p_selfEffectType == self.BONUS_FS_ADD_EFFECT then
        self.m_miniFsReelTop:showSelfEffect_FreeSpin(
            false,
            function()
            end
        )

        self.m_miniFsReelDown:showSelfEffect_FreeSpin(
            false,
            function()
                self:showFreeSpinView(effectData)
            end
        )
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenEasterMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

-- function CodeGameScreenEasterMachine:playEffectNotifyNextSpinCall()
--     BaseFastMachine.playEffectNotifyNextSpinCall(self)

--     self:checkTriggerOrInSpecialGame(
--         function()
--             self:reelsDownDelaySetMusicBGVolume()
--         end
--     )
-- end

function CodeGameScreenEasterMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    BaseFastMachine.slotReelDown(self)
end

function CodeGameScreenEasterMachine:createrOneReel(reelId, addNodeName)
    local className = "CodeEasterSrc.MiniReels.EasterMiniMachine"

    local reelData = {}
    reelData.index = reelId
    reelData.maxReelIndex = self.m_ReelDownMaxCount
    reelData.parent = self
    local miniReel = util_createView(className, reelData)
    self:findChild(addNodeName):addChild(miniReel)

    return miniReel
end

-- freespin中多个轮子处理
function CodeGameScreenEasterMachine:FSReelShowSpinNotify(maxCount)
    self.m_FSLittleReelsShowSpinIndex = self.m_FSLittleReelsShowSpinIndex + 1

    if self.m_FSLittleReelsShowSpinIndex == maxCount then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            -- if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            --     BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)
            -- end
            --freespin中等待两个mini轮执行完再执行主类的gameEffect
            self:reelDownNotifyPlayGameEffect()
        end

        self.m_FSLittleReelsShowSpinIndex = 0
    end
end

function CodeGameScreenEasterMachine:getFreeSpinReelsLines()
    local lines = {}

    if self.m_miniFsReelTop then
        local miniReelslines = self.m_miniFsReelTop:getResultLines()
        if miniReelslines then
            for i = 1, #miniReelslines do
                table.insert(lines, miniReelslines[i])
            end
        end
    end

    if self.m_miniFsReelDown then
        local miniReelslines = self.m_miniFsReelDown:getResultLines()
        if miniReelslines then
            for i = 1, #miniReelslines do
                table.insert(lines, miniReelslines[i])
            end
        end
    end

    return lines
end

function CodeGameScreenEasterMachine:playEffectNotifyNextSpinCall()
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
            if self.m_runSpinResultData.p_features and #self.m_runSpinResultData.p_features == 2 and self.m_runSpinResultData.p_features[2] == 1 then
                delayTime = 0.5
            end

            local lines = self:getFreeSpinReelsLines()
            if lines ~= nil and #lines > 0 then
                delayTime = 3
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

local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenEasterMachine:addLastWinSomeEffect() -- add big win or mega win
    local lines = {}
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local lines = self:getFreeSpinReelsLines()
        if #lines == 0 then
            return
        end
    else
        if #self.m_vecGetLineInfo == 0 then
            return
        end
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

function CodeGameScreenEasterMachine:RemoveAndCreateRuningFsReelSlotsNode()
    self.m_miniFsReelTop:removeAllReelsNode()
    self.m_miniFsReelDown:removeAllReelsNode()
end

--freespin下主轮调用父类停止函数
function CodeGameScreenEasterMachine:slotReelDownInLittleBaseReels()
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
    
end

function CodeGameScreenEasterMachine:FSReelDownNotify(maxCount)
    self.m_FSLittleReelsDownIndex = self.m_FSLittleReelsDownIndex + 1

    if self.m_FSLittleReelsDownIndex >= maxCount then
        self.m_FSLittleReelsDownIndex = 0

        self:slotReelDownInLittleBaseReels()

        self.m_miniFsReelTop:playGameEffect()
        self.m_miniFsReelDown:playGameEffect()

        

        local winLines = self:getFsWinLines()
        if #winLines > 0 then
            self:checkNotifyManagerUpdateWinCoin()
        end
    end
end

function CodeGameScreenEasterMachine:getFsWinLines()
    -- 更新钱
    local winLines = {}
    local reelsList = {self.m_miniFsReelTop, self.m_miniFsReelDown}
    for i = 1, #reelsList do
        local reel = reelsList[i]

        if reel.m_reelResultLines and #reel.m_reelResultLines > 0 then
            winLines = reel.m_reelResultLines
        end
    end
    return winLines
end

function CodeGameScreenEasterMachine:checkNotifyManagerUpdateWinCoin()
    -- 这里作为连线时通知钱数更新的 唯一接口
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, isNotifyUpdateTop})
end

---
-- 处理spin 返回结果
function CodeGameScreenEasterMachine:spinResultCallFun(param)
    BaseFastMachine.spinResultCallFun(self, param)
    if param[1] == true then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local spinData = param[2]
            if spinData.result then
                if spinData.result.selfData then
                    if spinData.result.selfData.spinResults and #spinData.result.selfData.spinResults > 0 then
                        spinData.result.selfData.spinResults[1].bet = spinData.result.bet
                        spinData.result.selfData.spinResults[2].bet = spinData.result.bet
                        self.m_miniFsReelDown:netWorkCallFun(spinData.result.selfData.spinResults[1])
                        self.m_miniFsReelTop:netWorkCallFun(spinData.result.selfData.spinResults[2])
                    end
                end
            end
        else
            local spinData = param[2]
            if spinData.action == "SPIN" then
                self:setNetMysteryType()
            end
        end
    end
end

function CodeGameScreenEasterMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_waitChangeReelTime = 0
        release_print("beginReel ... ")

        self:stopAllActions()
        self:requestSpinReusltData() -- 临时注释掉

        -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
        self.m_nScatterNumInOneSpin = 0
        self.m_nBonusNumInOneSpin = 0

        local effectLen = #self.m_gameEffects
        for i = 1, effectLen, 1 do
            self.m_gameEffects[i] = nil
        end

        self:clearWinLineEffect()
        if globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount then
            self:LockWildTurnAct()
        end

        self.m_miniFsReelTop:beginMiniReel()
        self.m_miniFsReelDown:beginMiniReel()
        local haveGoldScatter = self:getHaveGoldScatter()
        if haveGoldScatter then
            self:setWaitChangeReelTime(33 / 30)
        end
        self:setGameSpinStage(GAME_MODE_ONE_RUN)
    else
        BaseFastMachine.beginReel(self)
    end
end

function CodeGameScreenEasterMachine:updateNetWorkData()
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

function CodeGameScreenEasterMachine:showGuoChang(func)
    self.m_guoChangRabbit:setVisible(true)
    util_spinePlay(self.m_guoChangRabbit, "actionframe")
    util_spineEndCallFunc(
        self.m_guoChangRabbit,
        "actionframe",
        function()
            self.m_guoChangRabbit:setVisible(false)
            if func then
                func()
            end
        end
    )
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent()
            gLobalSoundManager:playSound("EasterSounds/sound_Easter_fs_guochang.mp3")
        end,
        24 / 30
    )
end

--增加提示节点
function CodeGameScreenEasterMachine:addReelDownTipNode(nodes)
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

-- 特殊信号下落时播放的音效
function CodeGameScreenEasterMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        if slotNode.p_symbolType == self.SYMBOL_SCATTER_GOLD then
            local iCol = slotNode.p_cloumnIndex
            local soundPath = nil
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end
            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            end
            if soundPath then
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( iCol,soundPath,TAG_SYMBOL_TYPE.SYMBOL_SCATTER )
                else
                    gLobalSoundManager:playSound(soundPath)
                end
            end
        else
            CodeGameScreenEasterMachine.super.playScatterBonusSound(self, slotNode)
        end
    end
end

function CodeGameScreenEasterMachine:checkIsInLongRun(col, symbolType)
    local scatterShowCol = self.m_ScatterShowCol

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GOLD then
        if scatterShowCol ~= nil then
            if self:getInScatterShowCol(col) then
                return true
            else
                return false
            end
        end
    end

    return true
end

---
-- 检测上次feature 数据
--
function CodeGameScreenEasterMachine:checkNetDataFeatures()
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

            if self.checkControlerReelType and self:checkControlerReelType( ) then
                globalMachineController.m_isEffectPlaying = true
            end

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

            if self.checkControlerReelType and self:checkControlerReelType( ) then
                globalMachineController.m_isEffectPlaying = true
            end
            
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

function CodeGameScreenEasterMachine:lineLogicEffectType(winLineData, lineInfo, iconsPos)
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
function CodeGameScreenEasterMachine:compareScatterWinLines(winLines)
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

-- ---- 快滚相关 修改
function CodeGameScreenEasterMachine:getMaxContinuityBonusCol()
    local maxColIndex = 0

    local isContinuity = true

    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0

        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GOLD then
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
function CodeGameScreenEasterMachine:changeReelDownAnima(parentData)
    if parentData.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or parentData.symbolType == self.SYMBOL_SCATTER_GOLD then
        if not self.m_addSounds then
            self.m_addSounds = {}
        end
        if self:getMaxContinuityBonusCol() >= parentData.cloumnIndex then
            local soundIndex = 1
            parentData.reelDownAnima = "buling"
            if not self.m_addSounds[parentData.cloumnIndex] then
                self.m_addSounds[parentData.cloumnIndex] = true
                parentData.reelDownAnimaSound = self.m_scatterBulingSoundArry[soundIndex]
            end
        end
        parentData.order = REEL_SYMBOL_ORDER.REEL_ORDER_3 + ((self.m_iReelRowNum - parentData.rowIndex) * 10 + parentData.cloumnIndex)
    end
end

-- --设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenEasterMachine:getRunStatus(col, nodeNum, showCol)
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
function CodeGameScreenEasterMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
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
        local targetSymbolType = self:getSymbolTypeForNetData(column, row, runLen)
        if targetSymbolType == symbolType or targetSymbolType == self.SYMBOL_SCATTER_GOLD then
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

--设置长滚信息
function CodeGameScreenEasterMachine:setReelRunInfo()
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
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 10)
                self:setLastReelSymbolList()
            end
        end

        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)
        -- bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
        local maxCol = self:getMaxContinuityBonusCol()
        if col > maxCol then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
        elseif maxCol == col then
            if bRunLong then
                addLens = true
            end
        end
    end --end  for col=1,iColumn do
end

-- 金色scatter 固定玩法

function CodeGameScreenEasterMachine:checkIsTriggerWildTurn()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local lockPosList = selfData.newLockWild or {}

    local triggerNum = 0
    local triggerindex = nil
    for i, v in ipairs(lockPosList) do
        local List = v
        if List and #List > 0 then
            triggerindex = i
            triggerNum = triggerNum + 1
        end
    end

    return triggerNum, triggerindex
end

local MAXTIME = 2
--scatter加次数
function CodeGameScreenEasterMachine:addFreespinTimesByScatter(func)
    local curTime = 0

    local callfunc = function()
        curTime = curTime + 1
        if curTime == MAXTIME then
            if func then
                func()
            end
        end
    end

    self.m_miniFsReelTop:addFreespinTimesByScatter(callfunc)
    self.m_miniFsReelDown:addFreespinTimesByScatter(callfunc)
end

-- 金色信号改变
function CodeGameScreenEasterMachine:LockWildTurnAct(func)
    local triggerNum, triggerindex = self:checkIsTriggerWildTurn()
    if triggerNum > 0 then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local lockPosList = selfData.newLockWild or {}
        if triggerNum == 2 then
            -- 第一轮

            self.m_miniFsReelTop:GoldScatterTurnLockWild(
                lockPosList[1],
                function()
                end,
                "buling"
            )
            self.m_miniFsReelDown:GoldScatterTurnLockWild(
                lockPosList[1],
                function()
                    self:lockWildFlyAction(
                        self.m_miniFsReelDown,
                        self.m_miniFsReelTop,
                        lockPosList[1],
                        function()
                            self.m_miniFsReelTop:showLockWild()
                        end
                    )
                end,
                "switch"
            )

            self.m_miniFsReelDown:GoldScatterTurnLockWild(
                lockPosList[2],
                function()
                    if func then
                        func()
                    end
                end,
                "buling"
            )
            -- 第二轮
            self.m_miniFsReelTop:GoldScatterTurnLockWild(
                lockPosList[2],
                function()
                    self:lockWildFlyAction(
                        self.m_miniFsReelTop,
                        self.m_miniFsReelDown,
                        lockPosList[2],
                        function()
                            self.m_miniFsReelDown:showLockWild()
                        end
                    )
                end,
                "switch"
            )
        else
            if triggerindex == 1 then
                self.m_miniFsReelTop:GoldScatterTurnLockWild(
                    lockPosList[triggerindex],
                    function()
                        if func then
                            func()
                        end
                    end,
                    "buling"
                )
                self.m_miniFsReelDown:GoldScatterTurnLockWild(
                    lockPosList[triggerindex],
                    function()
                        self:lockWildFlyAction(
                            self.m_miniFsReelDown,
                            self.m_miniFsReelTop,
                            lockPosList[triggerindex],
                            function()
                                self.m_miniFsReelTop:showLockWild()
                            end
                        )
                    end,
                    "switch"
                )
            else
                self.m_miniFsReelDown:GoldScatterTurnLockWild(
                    lockPosList[triggerindex],
                    function()
                        if func then
                            func()
                        end
                    end,
                    "buling"
                )
                self.m_miniFsReelTop:GoldScatterTurnLockWild(
                    lockPosList[triggerindex],
                    function()
                        self:lockWildFlyAction(
                            self.m_miniFsReelTop,
                            self.m_miniFsReelDown,
                            lockPosList[triggerindex],
                            function()
                                self.m_miniFsReelDown:showLockWild()
                            end
                        )
                    end,
                    "switch"
                )
            end
        end
    else
        if func then
            func()
        end
    end
end

function CodeGameScreenEasterMachine:lockWildFlyAction(manclass1, manclass2, lockList, func)
    gLobalSoundManager:playSound("EasterSounds/sound_Easter_copy_wild.mp3")

    local flyTimes = 15 / 30
    local waitTimes = 0
    local num = 0
    for k, v in pairs(lockList) do
        local index = tonumber(v)
        local fixPos = manclass1:getRowAndColByPos(index)
        local targSp = manclass1:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_FIX_NODE_TAG)

        local node = util_spineCreate("Socre_Easter_Wild_copy", true, true)
        self.m_node_effect:addChild(node, v)
        local beginPos = util_getConvertNodePos(targSp, node)
        node:setPosition(cc.p(beginPos))

        local actionName = "wild_copy"
        if manclass1 == self.m_miniFsReelTop then
            actionName = "wild_copy2"
        end

        util_spinePlay(node, actionName)
        util_spineEndCallFunc(
            node,
            actionName,
            function()
            end
        )
    end

    performWithDelay(
        self.m_node_effect,
        function()
            self.m_node_effect:removeAllChildren(true)
            if func then
                func()
            end
        end,
        33 / 30
    )
end

--添加金边
function CodeGameScreenEasterMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
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
    reelEffectNode:setOpacity(255)
    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--绘制多个裁切区域
function CodeGameScreenEasterMachine:drawReelArea()
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

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000)
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

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
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

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        -- self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        -- self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)
        
        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)
        
        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")

    end
end

function CodeGameScreenEasterMachine:getSlotNodeChildsTopY(colIndex)
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

function CodeGameScreenEasterMachine:quicklyStopReel(colIndex)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        BaseFastMachine.quicklyStopReel(self, colIndex)
    end
end

function CodeGameScreenEasterMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runAnim("actionframe")
    end
    return slotNode
end

function CodeGameScreenEasterMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(
        function()
            performWithDelay(
                self,
                function()
                    self:resetMaskLayerNodes()
                end,
                1
            )

            callFun()
        end,
        util_max(67 / 30, animTime),
        self:getModuleName()
    )
end

function CodeGameScreenEasterMachine:specialSymbolActionTreatment(node)
    if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or node.p_symbolType == self.SYMBOL_SCATTER_GOLD) then
        node:runAnim(
            "buling",
            false,
            function()
                -- node:runAnim("idleframe",true)
            end
        )
    end
end

-------界面切换
function CodeGameScreenEasterMachine:showNormalSpinGameView(isAnim)
    self.m_gameBg:runCsbAction("idle_bacegame", true)
    util_spinePlay(self.m_grass, "actionframe", true)
    self:isShowCollectPerson(true)
    self:changeRabbit()
    self:findChild("Node_reel"):setVisible(true)
    self:findChild("Node_freespin"):setVisible(false)
    self.m_jackPotNode:setVisible(true)
    self.m_jackPotNode:runCsbAction("idle", true)
    self:runCsbAction("base")

    local jackpot = {"major", "mini", "minor"}
    for i = 1, #jackpot do
        self.m_jackPotNode:findChild(jackpot[i]):setVisible(true)
    end
    util_spinePlay(self.m_lanzi, "lanziidle" .. self.m_phase, true)
end

function CodeGameScreenEasterMachine:showFreeSpinGameView(_animName)
    self.m_gameBg:runCsbAction("idle_freegame", true)
    util_spinePlay(self.m_grass, "actionframe2", true)
    self:isShowCollectPerson(false)
    self:findChild("Node_reel"):setVisible(false)
    self:findChild("Node_freespin"):setVisible(true)
    self.m_jackPotNode:runCsbAction("idle2", true)
    self.m_jackPotNode:setVisible(false)
end

function CodeGameScreenEasterMachine:showCollectGameView(isAnim)
    local guochangCallBackFun = function()
        if not self.m_collectGameNode then
            self.m_collectGameNode = util_createView("CodeEasterSrc.EasterCollectGame")
            self.m_collectGameNode:initMachine(self)
            self.m_collectGameNode:initView(
                self.m_runSpinResultData.p_selfMakeData.cells,
                function()
                    self.m_bInBonus = false
                    if self.m_collectEffectData then
                        self.m_collectEffectData.p_isPlay = true
                        self.m_collectEffectData = nil
                    end

                    self:playGameEffect()
                    self.m_phase = 1
                    self:showNormalSpinGameView()
                    self:resetMusicBg(true)
                    if self.m_collectGameNode then
                        self.m_collectGameNode:removeFromParent()
                        self.m_collectGameNode = nil
                    end
                end
            )
            self.m_collectGameNode:setVisible(false)
            self:findChild("root"):addChild(self.m_collectGameNode, 10)
        end

        self:showDuoFuDuoCaiGuoChang(
            function()
                self.m_bInBonus = true
                self.m_bottomUI:checkClearWinLabel()
                if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.cells then
                    --jackpot
                    self:isShowJackPotView(false)

                    --collectperson
                    -- rabbit
                    self:isShowCollectPerson(false)

                    self.m_freespinSpinbar:setVisible(false)

                    --reel
                    self:isShowNormalReel(false)
                    self:isShowDoubleReel(false)

                    self:playBonusBgm()
                    self.m_collectGameNode:setVisible(true)
                else
                    if self.m_collectEffectData then
                        self.m_collectEffectData.p_isPlay = true
                        self.m_collectEffectData = nil
                    end

                    self:playGameEffect()
                end
            end
        )
    end
    -- if self.m_rabbit_status ~= 4 then
    --     self.m_rabbit2:setVisible(false)
    --     self.m_rabbit:stopAllActions()
    --     util_spinePlay(self.m_rabbit, "over")
    --     local waitNode = cc.Node:create()
    --     self:addChild(waitNode)
    --     performWithDelay(
    --         waitNode,
    --         function()
    --             waitNode:removeFromParent()
    --             guochangCallBackFun()
    --         end,
    --         15 / 30
    --     )
    -- else
    --     self.m_rabbit:stopAllActions()
    --     self.m_rabbit:setVisible(false)
    --     self.m_rabbit2:setVisible(false)
    guochangCallBackFun()
    -- end
end

function CodeGameScreenEasterMachine:playBonusBgm()
    self.m_currentMusicBgName = "EasterSounds/music_Easter_collectGame.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

function CodeGameScreenEasterMachine:showDuoFuDuoCaiGuoChang(_fun)
    gLobalSoundManager:playSound("EasterSounds/sound_Easter_bonus_guochang.mp3")
    local guoChangIdle = {"guochang1", "guochang2", "guochang3"}
    --多福多彩过场动画
    util_spinePlay(self.m_lanzi, guoChangIdle[self.m_phase])

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            self.m_guoChangLanZi:setVisible(true)
            util_spinePlay(self.m_guoChangLanZi, "guochang_jindan")
            util_spineEndCallFunc(
                self.m_guoChangLanZi,
                "guochang_jindan",
                function()
                    self.m_guoChangLanZi:setVisible(false)
                end
            )

            performWithDelay(
                waitNode,
                function()
                    if _fun then
                        _fun()
                    end
                    waitNode:removeFromParent()
                end,
                37 / 30
            )
        end,
        25 / 30
    )
end

function CodeGameScreenEasterMachine:isShowJackPotView(isShow, isAnim)
    if self.m_jackPotNode then
        self.m_jackPotNode:setVisible(isShow)
    end
end

function CodeGameScreenEasterMachine:isShowCollectPerson(isShow)
    self.m_rabbit:setVisible(isShow)
    self.m_rabbit2:setVisible(isShow)
    self.m_lanzi:setVisible(isShow)
    util_spinePlay(self.m_lanzi, "lanziidle1", true)
end

function CodeGameScreenEasterMachine:isShowNormalReel(isShow, isAnim)
    --todo
    self:findChild("Node_reel"):setVisible(isShow)
end

function CodeGameScreenEasterMachine:isShowDoubleReel(isShow, isAnim)
    --todo
    self:findChild("Node_freespin"):setVisible(isShow)
end

--切换假滚类型
function CodeGameScreenEasterMachine:randomMystery()
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
function CodeGameScreenEasterMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end
--使用现在获取的数据 来表现假滚 如果一列全相同 则滚动相同信号 一列不同及有快滚则播放配置的假滚数据
function CodeGameScreenEasterMachine:setNetMysteryType()
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
        0.2,
        "changeReelData"
    )
end

--使用配置的假滚数据
function CodeGameScreenEasterMachine:changeSlotReelDatas(_col, _bRunLong)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData, _bRunLong)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end
--判断一列是否是相同的信号块 _iCol 列数， _bNetdata 使用服务器的数据 为true，由于信号块切换过类型使用当前显示的信号块类型为false
function CodeGameScreenEasterMachine:getColIsSameSymbol(_iCol, _bNetdata)
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

function CodeGameScreenEasterMachine:scaleMainLayer()
    CodeGameScreenEasterMachine.super.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    if display.height / display.width == 1024 / 768 then
        mainScale = 0.65
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end

return CodeGameScreenEasterMachine
