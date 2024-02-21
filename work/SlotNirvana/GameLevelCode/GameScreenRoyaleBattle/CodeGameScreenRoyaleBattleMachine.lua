---
-- island li
-- 2019年1月26日
-- CodeGameScreenRoyaleBattleMachine.lua

--[[
    玩法1:wild
    条件: base模式下触发，wild图标不会滚动出来。只会在玩法触发时，将'移动wild'直接添加到对应棋盘位置。
    展示: 出现后可以同行向左移动，每移动到可以参与连线的地方，就停止参与连线展示，展示结束后，循环移动连线过程，直至所有wild图标移出轮盘。

    玩法2:FreeGame
    条件: 上下棋盘加起来超过三个scatter
    展示: 触发和期间每次出现新的scatter时：每个scatter会向另一个棋盘开炮，使另一个棋盘随机位置出现'锁定wild'固定在棋盘上,若随机位置已存在'锁定wild'则重叠变为'乘倍wild'。
          期间再次出现scatter时，每出现一个spin次数+1

    注意 mini轮的effect只用作播连线，其他玩法effect逻辑都在主轮写
]]
local CollectData = require "data.slotsdata.CollectData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenRoyaleBattleMachine = class("CodeGameScreenRoyaleBattleMachine", BaseNewReelMachine)

local BaseDialog = util_require("Levels.BaseDialog")

CodeGameScreenRoyaleBattleMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_M = 100

----信号
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_LOCK_WILD = 93
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_MOVE_WILD = 92

CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_L1 = 40
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_L2 = 50
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_L3 = 60
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_L4 = 70
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_L5 = 80

--Up
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_UP_H1 = 10
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_UP_H2 = 20
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_UP_H3 = 30

CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_UP_SCATTER = 90

--Down
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_DOWN_H1 = 11
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_DOWN_H2 = 21
CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_DOWN_H3 = 31

CodeGameScreenRoyaleBattleMachine.SYMBOL_SCORE_DOWN_SCATTER = 190

CodeGameScreenRoyaleBattleMachine.m_norCSStatesTimes = 0 -- spin按钮可显示计数
CodeGameScreenRoyaleBattleMachine.m_norDownTimes = 0 -- 滚轮停止计数
CodeGameScreenRoyaleBattleMachine.m_maxReelNum = 2
----事件
--玩法事件:base模式下'移动wild'玩法
CodeGameScreenRoyaleBattleMachine.EFFECT_BASE_MOVE_WILD = GameEffect.EFFECT_SELF_EFFECT - 10
CodeGameScreenRoyaleBattleMachine.EFFECT_BASE_COLLECT_SCATTER = GameEffect.EFFECT_SELF_EFFECT - 90
CodeGameScreenRoyaleBattleMachine.EFFECT_BASE_COLLECT_FULL_TIEMS = GameEffect.EFFECT_SELF_EFFECT - 80

CodeGameScreenRoyaleBattleMachine.MAINREEL_OFFSET_Y = -10 --棋盘偏移 <1370 +10
--玩法小块创建的层级
CodeGameScreenRoyaleBattleMachine.ORDER_MOVE_WILD = 10
CodeGameScreenRoyaleBattleMachine.ORDER_LOCK_BALLISTIC = 20
CodeGameScreenRoyaleBattleMachine.ORDER_LOCK_SCATTER = 20
CodeGameScreenRoyaleBattleMachine.ORDER_LOCK_WILD = 15

CodeGameScreenRoyaleBattleMachine.MOVE_WILD_PANEL_TIME = 2 --移动玩法 遮罩提前出现的时间
CodeGameScreenRoyaleBattleMachine.MOVE_WILD_INTERVAL = 0.6 --移动玩法 每个wild出现的间隔
CodeGameScreenRoyaleBattleMachine.MOVE_WILD_SCALE = 1
--1.02 --移动玩法 小块缩放 解决遮挡问题

CodeGameScreenRoyaleBattleMachine.m_longRunSCNum = 4

-- 每个bet 对应的 spin次数
CodeGameScreenRoyaleBattleMachine.m_spinTimesBet = {}
CodeGameScreenRoyaleBattleMachine.m_curTotalBet = 0
CodeGameScreenRoyaleBattleMachine.m_totalSpinTimes = 10

CodeGameScreenRoyaleBattleMachine.m_spineTimesScale = {
    [8] = true,
    [9] = true
}

CodeGameScreenRoyaleBattleMachine.m_panelOpacity = 160

--重写快滚判断 设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

-- 构造函数
function CodeGameScreenRoyaleBattleMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_spinRestMusicBG = true
    self.m_isFeatureOverBigWinInFree = true
    ----移动玩法
    self.m_moveWilds = {
        [1] = {},
        [2] = {}
    }
    self.m_moveWildReplaceSymbol = {
        [1] = {},
        [2] = {}
    }
    self.m_moveWildParams = {
        [1] = {},
        [2] = {}
    }
    self.m_moveWildFirstWinCoin = 0
    ----锁定玩法
    self.m_bLockWildEffect = false
    self.m_lockWilds = {
        [1] = {},
        [2] = {}
    }
    self.m_lockScatter = {
        [1] = {},
        [2] = {}
    }
    self.m_lockWildParams = {
        [1] = {},
        [2] = {}
    }
    self.m_collimatorAnim = {
        [1] = {},
        [2] = {}
    }
    --首次进入关卡标记
    self.m_firstEnterFlag = {
        [1] = 0,
        [2] = 0
    }

    --中奖预告
    self.m_playWinningNotice = false
    --init
    self:initGame()
end

function CodeGameScreenRoyaleBattleMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("RoyaleBattleUpConfig.csv", "LevelRoyaleBattleConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)

    self.m_wildsParent = self:findChild("reelNode")
end

function CodeGameScreenRoyaleBattleMachine:initUI()
    self.m_lockNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_lockNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)

    local parent = self:findChild("Node_fg_cishu")
    self.m_baseFreeSpinBar = util_createView("CodeRoyaleBattleSrc.RoyaleBattleFreespinBarView")
    parent:addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:runCsbAction("idleframe")
    self.m_baseFreeSpinBar:setVisible(false)

    local data = {}
    data.parent = self
    self.m_DownReels = util_createView("CodeRoyaleBattleSrc.DownReel.RoyaleBattleDownReelMiniMachine", data)
    self:findChild("reel_base_xia"):addChild(self.m_DownReels)
    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_DownReels.m_touchSpinLayer)
    end

    self.m_bgBoWen = util_spineCreate("RoyaleBattle_bg_bace_bowen", true, true)
    self.m_gameBg:findChild("bowen"):addChild(self.m_bgBoWen)
    self.m_bgBoWen:setScale(2)
    util_spinePlay(self.m_bgBoWen, "idleframe", true)
    self:playGameBgAction("idle1", true)
    self:runCsbAction("idle", true)

    --遮罩
    self.m_panelUp = self:createRoyaleBattleMask(self)

    --粒子遮罩
    self.m_panelParticle = util_createAnimation("RoyaleBattle_reel_lizi.csb")
    local upNode = self.m_panelParticle:findChild("Panel_1")
    local downNode = self.m_panelParticle:findChild("Panel_1_0")
    util_setCascadeOpacityEnabledRescursion(upNode, true)
    util_setCascadeOpacityEnabledRescursion(downNode, true)
    self:findChild("reelNode"):addChild(self.m_panelParticle)
    self.m_panelParticle:setVisible(false)

    self.m_spinTimeBar = util_createAnimation("RoyaleBattle_basegamedi.csb")
    self:findChild("Node_basegamedi"):addChild(self.m_spinTimeBar)
    self:updateSpinTimeBar(0)

    self.m_topSCNumBar = util_createAnimation("RoyaleBattle_shangjishu.csb")
    self:findChild("Node_shangjishu"):addChild(self.m_topSCNumBar)
    self:updateTopSCNumBar(0)

    self.m_downSCNumBar = util_createAnimation("RoyaleBattle_xiajishu.csb")
    self:findChild("Node_xiajishu"):addChild(self.m_downSCNumBar)
    self:updateDownSCNumBar(0)

    self.m_topBattery = util_spineCreateDifferentPath("RoyaleBattle_shangdangong", "Socre_RoyaleBattle_Scatter_2", true, true)
    self:findChild("Node_shangdangong"):addChild(self.m_topBattery)
    util_spinePlay(self.m_topBattery, "idleframe2", true)

    self.m_downBattery = util_spineCreateDifferentPath("RoyaleBattle_xiadapao", "Socre_RoyaleBattle_Scatter_1", true, true)
    self:findChild("Node_xiadapao"):addChild(self.m_downBattery)
    util_spinePlay(self.m_downBattery, "idleframe", true)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            --下棋盘又发了事件，短时间连线音效不播两次
            if self.m_winSoundsId then
                return
            end

            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
                return
            end

            --移动玩法 连线时不避让大赢
            if self.m_bIsBigWin and not self:isTriggerMoveWild() then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local delayTime = 0
            if winRate <= 1 then
                soundIndex = 1
                delayTime = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                delayTime = 1.5
            elseif winRate > 3 then
                soundIndex = 3
                delayTime = 2
            end

            local soundTime = soundIndex
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = "RoyaleBattleSounds/sound_RoyaleBattle_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
            -- self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

            --下棋盘连线时也会发事件
            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(
                waitNode,
                function()
                    self.m_winSoundsId = nil

                    waitNode:removeFromParent()
                end,
                delayTime
            )
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

-- 断线重连
function CodeGameScreenRoyaleBattleMachine:MachineRule_initGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if self.m_bProduceSlots_InFreeSpin then
        self.m_baseFreeSpinBar:changeFreeSpinByCount()

        self.m_spinTimeBar:setVisible(false)
        self.m_topSCNumBar:setVisible(false)
        self.m_downSCNumBar:setVisible(false)

        --不是进入fs时 切背景
        if self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount then
            self:playGameBgAction("idle2", true)
        end

        local isTrigger = self:isTriggerLockWild(true)

        local allPosData = self:getLockWildParamWildPosData(nil)
        self:createLockWildSymbol(allPosData)
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenRoyaleBattleMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RoyaleBattle"
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenRoyaleBattleMachine:getNetWorkModuleName()
    return "RoyaleBattleV2"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenRoyaleBattleMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_M then
        return "Socre_RoyaleBattle_10"
    end

    if symbolType == self.SYMBOL_SCORE_LOCK_WILD then
        return "Socre_RoyaleBattle_Wild_1"
    end

    if symbolType == self.SYMBOL_SCORE_MOVE_WILD then
        return "Socre_RoyaleBattle_Wild_2"
    end

    if symbolType == self.SYMBOL_SCORE_L1 then
        return "Socre_RoyaleBattle_3"
    end

    if symbolType == self.SYMBOL_SCORE_L2 then
        return "Socre_RoyaleBattle_2"
    end

    if symbolType == self.SYMBOL_SCORE_L3 then
        return "Socre_RoyaleBattle_1"
    end

    if symbolType == self.SYMBOL_SCORE_L4 then
        return "Socre_RoyaleBattle_10"
    end

    if symbolType == self.SYMBOL_SCORE_L5 then
        return "Socre_RoyaleBattle_11"
    end
    --Up

    if symbolType == self.SYMBOL_SCORE_UP_H1 then
        return "Socre_RoyaleBattle_8"
    end

    if symbolType == self.SYMBOL_SCORE_UP_H2 then
        return "Socre_RoyaleBattle_6"
    end

    if symbolType == self.SYMBOL_SCORE_UP_H3 then
        return "Socre_RoyaleBattle_4"
    end

    if symbolType == self.SYMBOL_SCORE_UP_SCATTER then
        return "Socre_RoyaleBattle_Scatter2"
    end

    --Down
    if symbolType == self.SYMBOL_SCORE_DOWN_H1 then
        return "Socre_RoyaleBattle_9"
    end

    if symbolType == self.SYMBOL_SCORE_DOWN_H2 then
        return "Socre_RoyaleBattle_7"
    end

    if symbolType == self.SYMBOL_SCORE_DOWN_H3 then
        return "Socre_RoyaleBattle_5"
    end

    if symbolType == self.SYMBOL_SCORE_DOWN_SCATTER then
        return "Socre_RoyaleBattle_Scatter1"
    end

    return nil
end

function CodeGameScreenRoyaleBattleMachine:updateReelGridNode(node)
end

function CodeGameScreenRoyaleBattleMachine:playGameBgAction(_actionName, _isLoop, _fun)
    self.m_gameBg:runCsbAction(
        _actionName,
        _isLoop,
        function()
            if not _isLoop and _fun then
                _fun()
            end
        end
    )
end
----------------------------- 玩法处理 -----------------------------------
-- 解决scatter 落地时添加
--单列滚动停止回调

function CodeGameScreenRoyaleBattleMachine:slotOneReelDown(reelCol)
    BaseNewReelMachine.slotOneReelDown(self, reelCol)

    -- if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
    --     local isHaveFixSymbol = false
    --     for k = 1, self.m_iReelRowNum do
    --         if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
    --             isHaveFixSymbol = true
    --             break
    --         end
    --     end
    -- end

    --第一列滚动结束时 没有触发FS 关闭遮罩展示
    if 1 == reelCol then
        local leftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        local totalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if (totalCount > 0 and leftCount == totalCount and self.m_isNewReelQuickStop) then
        else
            self:playMaskFadeAction(
                false,
                0.5,
                function()
                    self:changeMaskVisible(false)
                end
            )
        end
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenRoyaleBattleMachine:levelFreeSpinEffectChange()
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenRoyaleBattleMachine:levelFreeSpinOverChangeEffect()
    --背景渐变
    self:playGameBgAction(
        "actionframe",
        false,
        function()
            self:playGameBgAction("idle1", true)
        end
    )
end
---------------------------------------------------------------------------
-- 触发freespin时调用
function CodeGameScreenRoyaleBattleMachine:showFreeSpinView(effectData)
    local showFSView = function()
        local view =
            self:showFreeSpinStart(
            self.m_iFreeSpinTimes,
            function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )

        --第20帧切场景
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                self.m_spinTimeBar:setVisible(false)
                self.m_topSCNumBar:setVisible(false)
                self.m_downSCNumBar:setVisible(false)

                --次数栏展示
                self.m_baseFreeSpinBar:changeFreeSpinByCount()
                self:showFreeSpinBar()
                self.m_baseFreeSpinBar:playMoreTimesAnim()
                --棋盘展示重置状态
                self:resetScatterState()

                waitNode:removeFromParent()
            end,
            20 / 60
        )

        --结束回调
        view:setBtnClickFunc(
            function()
                local delayNode = cc.Node:create()
                self:addChild(delayNode)
                performWithDelay(
                    delayNode,
                    function()
                        --背景渐变
                        self:playGameBgAction(
                            "actionframe2",
                            false,
                            function()
                                self:playGameBgAction("idle2", true)
                            end
                        )

                        delayNode:removeFromParent()
                    end,
                    30 / 60
                )
            end
        )
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:playSelfEffectAddTimes(effectData)
    else
        local reelIndex = math.random(1, 2)
        gLobalSoundManager:playSound(string.format("RoyaleBattleSounds/sound_RoyaleBattle_fs_start_%d.mp3", reelIndex))
        --播放过场 -> 展示弹板
        self:playFreeSpinGuochang(
            function()
                gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_fs_start.mp3")
                showFSView()
            end
        )
    end
end
function CodeGameScreenRoyaleBattleMachine:playFreeSpinGuochang(_fun)
    local endWorldPos = cc.p(display.width * 0.5, display.height * 0.55)

    --2.开炮
    local isPlayLaunch = false
    local playScatterLaunchAnim = function(_scatterChangeData)
        for _reelIndex, _reelData in ipairs(_scatterChangeData) do
            for _index, _data in ipairs(_reelData) do
                local scatter = self.m_lockScatter[_data.startReelIndex][_data.startPos]
                if scatter then
                    --发射动作
                    local launchAnim = 1 == _reelIndex and "actionframe3" or "actionframe"
                    self:playRoyaleBattleScatterAnim(
                        scatter,
                        launchAnim,
                        false,
                        25 / 30,
                        function()
                            --炮弹飞行
                            self:playLockWildTuowei(
                                _data.startWorldPos,
                                endWorldPos,
                                _reelIndex,
                                false,
                                0,
                                function()
                                    if not isPlayLaunch then
                                        isPlayLaunch = true

                                        if _fun then
                                            _fun()
                                        end
                                    end
                                end
                            )
                        end
                    )
                end
            end
        end
    end
    self:clearRoyaleBattleLineFrame()
    --遮罩开启
    self:changeMaskVisible(true)
    --使用触发数据提前创建
    local scatterChangeData = self:getLockWildParamScatterChangeData()
    self:createLockScatterSymbol(scatterChangeData)
    --1
    if #scatterChangeData[1] > 0 then
        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_Scatter_rotation_up.mp3")
    end
    if #scatterChangeData[2] > 0 then
        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_Scatter_rotation_down.mp3")
    end

    for _index, _data in ipairs(scatterChangeData[2]) do
        local scatter = self.m_lockScatter[2][_data.startPos]
        if scatter then
            self:playLockWildRotateAction(scatter, _data.startWorldPos, endWorldPos)
        end
    end
    --2
    playScatterLaunchAnim(scatterChangeData)
end
-- 触发freespin结束时调用
function CodeGameScreenRoyaleBattleMachine:showFreeSpinOverView()
    self:clearLockScatterSymbol()

    gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_fs_over.mp3")

    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins
    local strCoins = util_formatCoins(freeSpinWinCoin, 50)

    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            -- 调用此函数才是把当前游戏置为freespin结束状态
            self:triggerFreeSpinOverCallFun()
        end
    )

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1.25, sy = 1.25}, 489)

    --第30帧切场景
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            --界面切换展示
            self:clearLockWildSymbol()

            self.m_baseFreeSpinBar:setVisible(false)
            self.m_spinTimeBar:setVisible(true)
            self.m_topSCNumBar:setVisible(true)
            self.m_downSCNumBar:setVisible(true)

            waitNode:removeFromParent()
        end,
        30 / 60
    )
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenRoyaleBattleMachine:MachineRule_SpinBtnCall()
    --移除赢钱音效
    self:stopLinesWinSound()

    self:clearCollimatorAnim()

    self.m_norDownTimes = 0
    self.m_norCSStatesTimes = 0

    self:setMaxMusicBGVolume()

    return false -- 用作延时点击spin调用
end

function CodeGameScreenRoyaleBattleMachine:enterGamePlayMusic()
    self:playEnterGameSound("RoyaleBattleSounds/sound_RoyaleBattle_enterLevel.mp3")

    self:initSymbolWorldPos()
end

function CodeGameScreenRoyaleBattleMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self.m_DownReels:enterLevelMiniSelf()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local battleCount = selfdata.battleCount or {0, 0}
    if #battleCount == 2 then
        self:updateTopSCNumBar(battleCount[1])
        self:updateDownSCNumBar(battleCount[2])

        if battleCount[1] > 0 then
            util_spinePlay(self.m_topBattery, "idleframe")
        end
    end

    --==进入关卡时一些控件需要取服务器数据刷新
    self.m_curTotalBet = globalData.slotRunData:getCurTotalBet()
    self:betChangeUpDateSpinTimes(self.m_curTotalBet)
    --==

    self:checkShowGameStartView()

    local interval = 0.5
    self.m_scaleHandlerID =
        scheduler.scheduleGlobal(
        function()
            local leftLabel = self.m_spinTimeBar:findChild("m_lb_num_1")
            local timesValue = tonumber(leftLabel:getString())

            if timesValue and self.m_spineTimesScale[timesValue] then
                local curScale = leftLabel:getScale()
                local scale = math.abs(curScale - 0.57) < 0.1 and 0.7 or 0.57
                leftLabel:runAction(cc.ScaleTo:create(interval, scale))
            else
                leftLabel:setScale(0.57)
            end
        end,
        interval
    )
end

function CodeGameScreenRoyaleBattleMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    --bet数值切换
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local curTotalBet = globalData.slotRunData:getCurTotalBet()

            if self.m_curTotalBet ~= curTotalBet then
                self:betChangeUpDateSpinTimes(curTotalBet)

                self.m_curTotalBet = curTotalBet
            end
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenRoyaleBattleMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    if self.m_scaleHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_scaleHandlerID)
        self.m_scaleHandlerID = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenRoyaleBattleMachine:addCollectSCEffect(_mainClass)
    local topReelSCNum = self:getSymbolCountWithReelResult(self.SYMBOL_SCORE_UP_SCATTER)
    local downReelSCNum = self.m_DownReels:getSymbolCountWithReelResult(self.SYMBOL_SCORE_DOWN_SCATTER)
    if topReelSCNum > 0 or downReelSCNum > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_COLLECT_SCATTER
        _mainClass.m_gameEffects[#_mainClass.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_COLLECT_SCATTER
    end
end

function CodeGameScreenRoyaleBattleMachine:addCollectSCFullTimesEffect(_mainClass)
    local data = self:BaseMania_getCollectData(1)
    if data.p_collectLeftCount == data.p_collectTotalCount then
        -- 结束播放收集满动画
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_COLLECT_FULL_TIEMS
        _mainClass.m_gameEffects[#_mainClass.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_COLLECT_FULL_TIEMS
    end
end

-- ------------玩法处理 --

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenRoyaleBattleMachine:addSelfEffect()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:addCollectSCEffect(self)
        self:addCollectSCFullTimesEffect(self)
    end

    if self:isTriggerMoveWild() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_MOVE_WILD
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_MOVE_WILD

        self.m_DownReels:MainReel_addSelfEffect(selfEffect)
    end

    self:isTriggerLockWild(true)
    --固定wild参加连线
    local wildPosData = self:getLockWildParamWildPosData(nil)
    self:changeFreeSpinLineShow(wildPosData)
end
--检测玩法触发 并存一下 两个轮盘进行该事件的一些服务器参数
-- 移动玩法 每次触发时 只会在一个棋盘出现小龙
function CodeGameScreenRoyaleBattleMachine:isTriggerMoveWild(_initData)
    local isTrigger = false

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.mobileWild and #selfData.mobileWild > 0 then
        isTrigger = true
    end

    local selfData_down = selfData.spinResultDown and selfData.spinResultDown.selfData or {}
    if selfData_down.mobileWild and #selfData_down.mobileWild > 0 then
        isTrigger = true
    end

    if isTrigger and _initData then
        --[[
            self.m_moveWildParams[1] = {
                lines           --每次移动的 连线
                mobileWild      --每次移动的 位置
                winAmounts      --每次移动的 赢钱
                --
                winLines        --每次移动的 连线数据
                WorldPos         --每次移动的 世界坐标
                posData         --每次移动的 棋盘坐标
                winCoin         --每次移动的 累计赢钱
            }
        ]]
        --服务器数据
        self.m_moveWildParams[1] = {
            lines = selfData.lines and clone(selfData.lines) or {},
            mobileWild = selfData.mobileWild and clone(selfData.mobileWild) or {},
            winAmounts = selfData.winAmounts and clone(selfData.winAmounts) or {}
        }
        self.m_moveWildParams[2] = {
            lines = selfData_down.lines and clone(selfData_down.lines) or {},
            mobileWild = selfData_down.mobileWild and clone(selfData_down.mobileWild) or {},
            winAmounts = selfData_down.winAmounts and clone(selfData_down.winAmounts) or {}
        }
        self:initAllMoveWildWinAmounts()
        --自定义
        local allWinLines = self:getAllMoveWildWinLines()
        local allWorldPosList = self:getAllMoveWildWorldPos()
        local allPosData = self:getAllMoveWildPosData()
        local allWinCoin = self:getAllMoveWildWinCoin()

        for _reelIndex = 1, 2 do
            self.m_moveWildParams[_reelIndex].winLines = allWinLines[_reelIndex]
            self.m_moveWildParams[_reelIndex].WorldPos = allWorldPosList[_reelIndex]
            self.m_moveWildParams[_reelIndex].posData = allPosData[_reelIndex]
            self.m_moveWildParams[_reelIndex].winCoin = allWinCoin[_reelIndex]
        end
    end

    return false
end

--从数据列表内取一个值， 每层 数据数量 不一致时 容错 (开始写玩法时 服务器数据有问题的容错处理，服务器解决后 留着也不会有问题就没删)
function CodeGameScreenRoyaleBattleMachine:getMoveWildParamOneData(dataList, reelIndex, index, defultValue)
    return dataList[reelIndex][index] or defultValue
end

function CodeGameScreenRoyaleBattleMachine:getMoveWildParamLines(moveIndex)
    return self:getMoveWildParamByKey("lines", moveIndex)
end
function CodeGameScreenRoyaleBattleMachine:getMoveWildParamMobileWild(moveIndex)
    return self:getMoveWildParamByKey("mobileWild", moveIndex)
end

function CodeGameScreenRoyaleBattleMachine:getMoveWildParamWinLines(moveIndex)
    return self:getMoveWildParamByKey("winLines", moveIndex)
end
function CodeGameScreenRoyaleBattleMachine:getMoveWildParamWorldPos(moveIndex)
    return self:getMoveWildParamByKey("WorldPos", moveIndex)
end
function CodeGameScreenRoyaleBattleMachine:getMoveWildParamPosData(moveIndex)
    return self:getMoveWildParamByKey("posData", moveIndex)
end

function CodeGameScreenRoyaleBattleMachine:getMoveWildParamWinAmounts(moveIndex)
    return self:getMoveWildParamByKey("winAmounts", moveIndex)
end
function CodeGameScreenRoyaleBattleMachine:getMoveWildParamWinCoin(moveIndex)
    return self:getMoveWildParamByKey("winCoin", moveIndex)
end
----@moveIndex = nil 返回全部
function CodeGameScreenRoyaleBattleMachine:getMoveWildParamByKey(key, moveIndex)
    local data = {}

    if self.m_moveWildParams[1][key] and moveIndex then
        data = {
            [1] = self.m_moveWildParams[1][key][moveIndex] or {},
            [2] = self.m_moveWildParams[2][key][moveIndex] or {}
        }
    else
        data = {
            [1] = self.m_moveWildParams[1][key] or {},
            [2] = self.m_moveWildParams[2][key] or {}
        }
    end

    return data
end
--获取本次移动中最大的移动距离
function CodeGameScreenRoyaleBattleMachine:getMoveWildOnceMoveNum(curPosData, nextPosData)
    local defultValue = {iX = 0, iY = 0}
    local moveNum = 0

    for _reelIndex, _posDataList in ipairs(curPosData) do
        for _index, _posData in ipairs(_posDataList) do
            local curCloumnIndex = _posData.iY

            if curCloumnIndex > 0 then
                local nextCloumnIndex = self:getMoveWildParamOneData(nextPosData, _reelIndex, _index, defultValue).iY
                local distance = curCloumnIndex - nextCloumnIndex

                if distance > moveNum then
                    moveNum = distance
                end
            end
        end

        if moveNum > 0 then
            break
        end
    end

    --容错
    if moveNum < 1 or moveNum > 4 then
        moveNum = 4
    end

    return moveNum
end
--获取移动玩法小龙出现的棋盘
function CodeGameScreenRoyaleBattleMachine:getMoveWildReelIndex()
    local reelIndex = 1

    local posList = self:getMoveWildParamWorldPos(1)

    for _reelIndex, _reelData in ipairs(posList) do
        if #_reelData > 0 then
            reelIndex = _reelIndex
            break
        end
    end

    return reelIndex
end
function CodeGameScreenRoyaleBattleMachine:getMoveWildCount()
    local count = 0
    local posList = self:getMoveWildParamWorldPos(1)

    for _reelIndex, _reelData in ipairs(posList) do
        for _index, _pos in ipairs(_reelData) do
            count = count + 1
        end
    end

    return count
end
--存一下进入关卡时 所有小块的世界坐标
function CodeGameScreenRoyaleBattleMachine:initSymbolWorldPos()
    self.m_symbolWorldPos = {
        [1] = {},
        [2] = {}
    }

    local insertData = function(_target, _table)
        for iCol = 1, _target.m_iReelColumnNum do
            if not _table[iCol] then
                _table[iCol] = {}
            end
            for iRow = _target.m_iReelRowNum, 1, -1 do
                local symbol = _target:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                local WorldPos = cc.p(-500, -500)
                --小块存在
                if symbol then
                    --小块不存在
                    WorldPos = symbol:getParent():convertToWorldSpace(cc.p(symbol:getPosition()))
                else
                    release_print(string.format("[CodeGameScreenRoyaleBattleMachine:initSymbolWorldPos] 小块不存在 col=(%d) row=(%d)", iCol, iRow))
                    local nodePos = util_getPosByColAndRow(_target, iCol, iRow)
                    local slotParent = _target:getReelParent(iCol)
                    if slotParent then
                        WorldPos = slotParent:convertToWorldSpace(nodePos)
                    end
                end
                _table[iCol][iRow] = WorldPos
            end
        end
    end

    insertData(self, self.m_symbolWorldPos[1])
    insertData(self.m_DownReels, self.m_symbolWorldPos[2])

    return self.m_symbolWorldPos
end
--是否触发 发射lock玩法, 判断服务器数据初始化本地数据
function CodeGameScreenRoyaleBattleMachine:isTriggerLockWild(_bInitData)
    local isTrigger = false

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.scatterChange and #selfData.scatterChange > 1 then
        isTrigger = true
    end

    local isInitWildPosition = false
    if selfData.wildPositions and #selfData.wildPositions > 1 then
        isInitWildPosition = true
    end

    if _bInitData and (isTrigger or isInitWildPosition) then
        if isTrigger then
            self:changeLockWildEffectState(true)
        end
        --[[
            self.m_lockWildParams[1] = {
                scatterChange      --本次spin新增wild
                wildPositions      --原有wild的位置和乘倍值
                --
                scatterChangeData[1]  = {      --解析 发射位置 和 目标位置
                    endPos              --目标点绝对位置
                    endPosData          --目标点棋盘行列坐标     
                    endWorldPos          --目标点世界坐标
                    endReelIndex        --目标点所属棋盘

                    startPos     
                    startPosData 
                    startWorldPos
                    startReelIndex
                },
                posData[1]            = {      --当前棋盘上wild的坐标和乘倍
                    endPos     
                    endPosData   
                    endWorldPos    
                    endReelIndex
                    
                    multiply   
                },
            }
        ]]
        self.m_lockWildParams[1] = {
            scatterChange = selfData.scatterChange and clone(selfData.scatterChange[1]) or {},
            wildPositions = selfData.wildPositions and clone(selfData.wildPositions[1]) or {}
        }

        self.m_lockWildParams[2] = {
            scatterChange = selfData.scatterChange and clone(selfData.scatterChange[2]) or {},
            wildPositions = selfData.wildPositions and clone(selfData.wildPositions[2]) or {}
        }

        local allScatterChangeData = self:getAllLockWildScatterChangeData()
        local allWildPosData = self:getAllLockWildPosData()
        for _reelIndex = 1, 2 do
            self.m_lockWildParams[_reelIndex].scatterChangeData = allScatterChangeData[_reelIndex]
            self.m_lockWildParams[_reelIndex].posData = allWildPosData[_reelIndex]
        end
    end

    return isTrigger
end

function CodeGameScreenRoyaleBattleMachine:changeLockWildEffectState(_state)
    self.m_bLockWildEffect = _state
    -- self.m_DownReels.m_bLockWildEffect = _state
end
function CodeGameScreenRoyaleBattleMachine:getLockWildParamWildPositions()
    return self:getLockWildParamByKey("wildPositions")
end
function CodeGameScreenRoyaleBattleMachine:getLockWildParamWildPosData()
    return self:getLockWildParamByKey("posData")
end

function CodeGameScreenRoyaleBattleMachine:getLockWildParamScatterChange()
    return self:getLockWildParamByKey("scatterChange")
end
function CodeGameScreenRoyaleBattleMachine:getLockWildParamScatterChangeData()
    return self:getLockWildParamByKey("scatterChangeData")
end

function CodeGameScreenRoyaleBattleMachine:getLockWildParamByKey(key)
    local data = {}

    local dataList = self.m_lockWildParams

    if dataList[1][key] then
        data = {
            [1] = dataList[1][key] or {},
            [2] = dataList[2][key] or {}
        }
    else
        data = {
            [1] = {},
            [2] = {}
        }
    end

    return data
end
-- @ haveNew 连线展示不需要计算新增的wild， 开炮时需要计算新增的wild，保证两个炮台同时击中一个目标时倍率正确
function CodeGameScreenRoyaleBattleMachine:getCurLockWildMultiply(reelIndex, endPos, haveNew)
    local multiply = 0
    --上次残留
    for _index, _posData in ipairs(self.m_lockWildParams[reelIndex].posData) do
        if _posData.endPos == endPos then
            multiply = multiply + _posData.multiply
            break
        end
    end

    if haveNew then
        --本次新增
        local otherReelIndex = 1 == reelIndex and 2 or 1
        for _index, _scatterChangeData in ipairs(self.m_lockWildParams[otherReelIndex].scatterChangeData) do
            if _scatterChangeData.endPos == endPos then
                multiply = multiply + 1
            end
        end
    end

    return multiply
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenRoyaleBattleMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_BASE_MOVE_WILD then
        self:clearRoyaleBattleLineFrame()
        self:removeSoundHandler()
        gLobalSoundManager:playBgMusic("RoyaleBattleSounds/RoyaleBattleSounds_WildGame.mp3")

        self:playAllLineFrameBeforMoveWild()
        self:playSelfEffectMoveWild(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_BASE_COLLECT_SCATTER then
        self:playScatterCollectEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_BASE_COLLECT_FULL_TIEMS then
        self:playScatterCollectFullTimesEffect(effectData)
    end

    return true
end

function CodeGameScreenRoyaleBattleMachine:playScatterCollect(_mainClass)
    for iCol = 1, _mainClass.m_iReelColumnNum do
        for iRow = _mainClass.m_iReelRowNum, 1, -1 do
            local symbol = _mainClass:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbol then
                local aniNode = nil
                local endNode = nil
                if symbol.p_symbolType == self.SYMBOL_SCORE_UP_SCATTER then
                    aniNode = util_createAnimation("Socre_RoyaleBattle_Scatter2_shouji.csb")
                    endNode = self.m_topBattery
                elseif symbol.p_symbolType == self.SYMBOL_SCORE_DOWN_SCATTER then
                    aniNode = util_createAnimation("Socre_RoyaleBattle_Scatter1_shouji.csb")
                    endNode = self.m_downBattery
                end

                if aniNode and endNode then
                    self:addChild(aniNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                    aniNode:setPosition(util_convertToNodeSpace(symbol, self))
                    aniNode:setScale(self.m_machineRootScale)
                    local endPos = util_convertToNodeSpace(endNode, self)
                    aniNode:runCsbAction(
                        "start",
                        false,
                        function()
                            util_playMoveToAction(aniNode, 15 / 60, endPos)

                            local aniNode_1 = aniNode
                            aniNode:runCsbAction(
                                "move",
                                false,
                                function()
                                    local aniNode_2 = aniNode_1
                                    aniNode_1:runCsbAction(
                                        "over",
                                        false,
                                        function()
                                            aniNode_2:removeFromParent()
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            end
        end
    end
end

function CodeGameScreenRoyaleBattleMachine:playScatterCollectEffect(effectData)
    gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_scatter_collect.mp3")

    local topReelSCNum = self:getSymbolCountWithReelResult(self.SYMBOL_SCORE_UP_SCATTER)
    local downReelSCNum = self.m_DownReels:getSymbolCountWithReelResult(self.SYMBOL_SCORE_DOWN_SCATTER)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local battleCount = selfdata.battleCount or {{}, {}}
    local topBattleCount = battleCount[1]
    local downBattleCount = battleCount[2]
    local data = self:BaseMania_getCollectData(1)
    local curBet = globalData.slotRunData:getCurTotalBet()
    if data.p_collectLeftCount == data.p_collectTotalCount then
        local curTopCount = 0
        local curDownCount = 0
        local betData = self:getBetSpinTimesData(curBet)
        if betData then
            curTopCount = betData.topCount or 0
            curDownCount = betData.downCount or 0
        end
        topBattleCount = curTopCount + topReelSCNum
        downBattleCount = curDownCount + downReelSCNum
    end
    --修改炮弹累积数量
    local betData = {
        topCount = topBattleCount,
        downCount = downBattleCount
    }
    self:saveOneBetSpinTimes(curBet, betData)

    if topReelSCNum > 0 then
        self:playScatterCollect(self)
    end

    if downReelSCNum > 0 then
        self:playScatterCollect(self.m_DownReels)
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    local waitTime = 35 / 60
    performWithDelay(
        waitNode,
        function()
            if topReelSCNum > 0 then
                util_spinePlay(self.m_topBattery, "actionframe2")
            -- self:updateTopSCNumBar( topBattleCount)
            end
            if downReelSCNum > 0 then
                util_spinePlay(self.m_downBattery, "actionframe2")
            -- self:updateDownSCNumBar( downBattleCount )
            end
            --飞行期间可能切换bet
            self:betChangeUpDateSpinTimes(globalData.slotRunData:getCurTotalBet(), 20 / 30)

            waitNode:removeFromParent()
        end,
        waitTime
    )

    local data = self:BaseMania_getCollectData(1)
    local features = self.m_runSpinResultData.p_features
    if data.p_collectLeftCount == data.p_collectTotalCount then
        -- 结束那一次等待收集完成
    elseif features and #features >= 2 then
        -- 触发free那一次等待收集完成
    elseif 1 == data.p_collectLeftCount then
        --第9次必须等飞行完毕
        waitTime = 80 / 60
    else
        waitTime = 0
    end

    performWithDelay(
        self,
        function()
            self.m_DownReels:restSelfGameEffects(self.EFFECT_BASE_COLLECT_SCATTER)
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        waitTime
    )
end

function CodeGameScreenRoyaleBattleMachine:playScatterCollectFullTimesEffect(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local featureWild = selfdata.featureWild or {{}, {}}
    local topWildList = featureWild[1] or {}
    local downWildList = featureWild[2] or {}
    self:changeTopDownReelSymbol(topWildList, downWildList)

    local data = self:BaseMania_getCollectData(1)
    local leftTimes = data.p_collectTotalCount - data.p_collectLeftCount
    --存一下0:10数据
    local betData = {
        leftTimes = leftTimes
    }
    self:saveOneBetSpinTimes(globalData.slotRunData:getCurTotalBet(), betData)
    self:updateSpinTimeBar(leftTimes)
    self.m_DownReels:restSelfGameEffects(self.EFFECT_BASE_COLLECT_FULL_TIEMS)

    self.m_lockNode:removeAllChildren()
    self.m_DownReels.m_lockNode:removeAllChildren()

    effectData.p_isPlay = true
    self:playGameEffect()
end
----------*****移动wild玩法
-- 添加移动wild之前，先播‘不存在wild的棋盘’的基础盘面的连线更新底栏赢钱 将连线所得刷到底栏
function CodeGameScreenRoyaleBattleMachine:playAllLineFrameBeforMoveWild(_fun)
    local winlines = {
        [1] = {},
        [2] = {}
    }
    local linesWinCoin = {
        [1] = 0,
        [2] = 0
    }

    local lineData = self:getMoveWildParamWinLines(1)

    --Up
    if #lineData[1] < 1 and #self.m_reelResultLines > 0 then
        winlines[1] = self.m_reelResultLines

        for _index, _winLineData in ipairs(self.m_runSpinResultData.p_winLines) do
            linesWinCoin[1] = linesWinCoin[1] + _winLineData.p_amount
        end
    end
    --Down
    if #lineData[2] < 1 and #self.m_DownReels.m_reelResultLines > 0 then
        winlines[2] = self.m_DownReels.m_reelResultLines

        for _index, _winLineData in ipairs(self.m_DownReels.m_runSpinResultData.p_winLines) do
            linesWinCoin[2] = linesWinCoin[2] + _winLineData.p_amount
        end
    end

    --移除之后的连线事件
    self:removeLineFrameEffect()
    for _reelIndex = 1, 2 do
        local target = 1 == _reelIndex and self or self.m_DownReels
        if #winlines[_reelIndex] > 0 then
            target:showLineFrame()
        end
    end

    local winCoin = linesWinCoin[1] + linesWinCoin[2]

    local jumpTime = 0

    if winCoin > 0 then
        jumpTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
        --更新赢钱
        local curShowWinCoin = 0
        local moveWinCoin = winCoin
        self:bottomUi_upDateWinCoin(curShowWinCoin, moveWinCoin)
    end
    self.m_moveWildFirstWinCoin = winCoin

    --
    local delayTime = math.max(2, jumpTime)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            self:clearRoyaleBattleLineFrame()
            if _fun then
                _fun()
            end

            waitNode:removeFromParent()
        end,
        delayTime + 0.2
    )
end
-- 触发动画 -> 移动到连线位置 -> 代替覆盖的小块参与连线 -> 循环移动和连线，直至全部移出轮盘
function CodeGameScreenRoyaleBattleMachine:playSelfEffectMoveWild(effectData)
    local effectOverFun = function()
        effectData.p_isPlay = true
        self:playGameEffect()

        self.m_DownReels:MainReel_removeSelfEffect(effectData)
    end

    local nextFun = function()
        local animIndex = 1
        self:replaceMoveWildToReel(animIndex)
        --循环连线和移动
        self:playSpecialWildLineFrame(
            animIndex,
            function()
                self:playSpecialWildMove(animIndex, effectOverFun)
            end
        )
    end

    --
    local isPLay = false
    for _reelIndex, _wildList in ipairs(self.m_moveWilds) do
        for _index, _wild in ipairs(_wildList) do
            _wild:setVisible(false)
        end
    end

    nextFun()
end
--展示粒子遮罩 2s 后创建小龙
function CodeGameScreenRoyaleBattleMachine:playSpecialWildParticlePanel()
    --压暗
    local moveWildReelIndex = self:getMoveWildReelIndex()
    self:playParticlePanelFadeAction(true, moveWildReelIndex)
    --延时2s小龙出现
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            self:playSpecialWildCreateAnim()

            --最后一条龙'落地后'，开始淡出
            local wildCount = self:getMoveWildCount()
            local delayTime = (wildCount - 1) * self.MOVE_WILD_INTERVAL + 60 / 30

            performWithDelay(
                waitNode,
                function()
                    self:playParticlePanelFadeAction(false, moveWildReelIndex)
                    waitNode:removeFromParent()
                end,
                delayTime
            )
        end,
        self.MOVE_WILD_PANEL_TIME
    )
end
--创建并播放移动wild动画
function CodeGameScreenRoyaleBattleMachine:playSpecialWildCreateAnim()
    --创建所有移动wild
    local posList = self:getMoveWildParamWorldPos(1)
    self:clearMoveWildSymbol()
    self:createMoveWildSymbol(posList)
    --
    --播放触发动画
    local wildCount = 0
    for _reelIndex, _wildList in ipairs(self.m_moveWilds) do
        for _index, _wild in ipairs(_wildList) do
            --相继出现
            local delayTime = wildCount * self.MOVE_WILD_INTERVAL
            wildCount = wildCount + 1

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(
                waitNode,
                function()
                    gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_MoveWild_down.mp3")
                    _wild:runAnim("actionframe5")

                    _wild:setVisible(true)
                    -- 第15帧 触发爆炸动效
                    performWithDelay(
                        waitNode,
                        function()
                            local WorldPos = posList[_reelIndex][_index] or cc.p(-500, -500)
                            self:playEffectBaozha(WorldPos)
                            self:shakeNodeOnce()

                            waitNode:removeFromParent()
                        end,
                        15 / 30
                    )
                end,
                delayTime
            )
        end
    end
end
function CodeGameScreenRoyaleBattleMachine:playSpecialWildMove(animIndex, fun)
    local allMobileWild = self:getMoveWildParamMobileWild(nil)
    local maxLen = math.max(#allMobileWild[1], #allMobileWild[2])

    if animIndex >= maxLen then
        --释放
        self:clearMoveWildSymbol()
        --恢复背景音乐
        self:resetMusicBg(true)
        if fun then
            fun()
        end

        return
    end

    --移动距离
    local curPosData = self:getMoveWildParamPosData(animIndex)
    local nextPosData = self:getMoveWildParamPosData(animIndex + 1)
    --坐标
    local nextPosition = self:getMoveWildParamWorldPos(animIndex + 1)
    --移动距离
    local moveNum = self:getMoveWildOnceMoveNum(curPosData, nextPosData)
    --标记
    local isPlay = false
    --列表内 列 > 0做移动，移动结束时 列 <= 0 藏起来
    local defultValue = {iX = 0, iY = 0}
    local playSoundMove = false
    local playSoundOver = false
    for _reelIndex, _wildList in ipairs(self.m_moveWilds) do
        for _index, _wild in ipairs(_wildList) do
            local curCloumnIndex = self:getMoveWildParamOneData(curPosData, _reelIndex, _index, defultValue).iY
            if curCloumnIndex > 0 then
                local nextCloumnIndex = self:getMoveWildParamOneData(nextPosData, _reelIndex, _index, defultValue).iY
                --最多移动到 0 列
                local wildMoveNum = math.min(curCloumnIndex, moveNum)
                local animName = ""
                --根据本次移动终点决定移动动画
                if nextCloumnIndex > 0 then
                    animName = string.format("actionframe%d", wildMoveNum)

                    if not playSoundMove then
                        playSoundMove = true
                        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_MoveWild_move.mp3")
                    end
                else
                    animName = string.format("over%d", wildMoveNum)

                    if not playSoundOver then
                        playSoundOver = true
                        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_MoveWild_over.mp3")
                    end
                end

                _wild:runAnim(
                    animName,
                    false,
                    function()
                        _wild:setVisible(false)
                        --移除棋盘时淡出，  未移出则修改坐标
                        if nextCloumnIndex <= 0 then
                        else
                            local nodePos = self.m_wildsParent:convertToNodeSpace(nextPosition[_reelIndex][_index])
                            _wild:setPosition(nodePos)
                            _wild:runAnim("idleframe")
                        end

                        --下一步
                        if not isPlay then
                            isPlay = true

                            self:replaceMoveWildToReel(animIndex + 1)

                            local waitNode = cc.Node:create()
                            self:addChild(waitNode)
                            performWithDelay(
                                waitNode,
                                function()
                                    self:playSpecialWildLineFrame(
                                        animIndex + 1,
                                        function()
                                            self:playSpecialWildMove(animIndex + 1, fun)
                                        end
                                    )

                                    waitNode:removeFromParent()
                                end,
                                0.5
                            )
                        end
                    end
                )
            end
        end
    end
end

function CodeGameScreenRoyaleBattleMachine:playSpecialWildLineFrame(animIndex, fun)
    local allMobileWild = self:getMoveWildParamMobileWild(nil)
    local maxLen = math.max(#allMobileWild[1], #allMobileWild[2])
    --最后一次连线不做处理
    if animIndex >= maxLen then
        if fun then
            fun()
        end
        return
    end

    --参与连线
    local playLineFrame = function(_target, _winLines)
        if #_winLines > 0 then
            _target.m_reelResultLines = _winLines
            _target:showLineFrame()
        end
    end
    local lineData = self:getMoveWildParamWinLines(animIndex)

    playLineFrame(self, lineData[1])
    playLineFrame(self.m_DownReels, lineData[2])
    --更新赢钱
    local curShowWinCoin = self:bottomUi_getCurWinCoins()
    local lineWinCoinData = self:getMoveWildParamWinCoin(animIndex)
    local moveWinCoin = self.m_moveWildFirstWinCoin + lineWinCoinData[1] + lineWinCoinData[2]
    self:bottomUi_upDateWinCoin(curShowWinCoin, moveWinCoin)

    --延时后 取消连线 还原展示 进入下一步
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            --展示临时小块
            local curPosData = self:getMoveWildParamPosData(animIndex)
            local defultPosData = {iX = 0, iY = 0}
            for _reelIndex, _wildList in ipairs(self.m_moveWilds) do
                for _index, _wild in ipairs(_wildList) do
                    local cloumnIndex = self:getMoveWildParamOneData(curPosData, _reelIndex, _index, defultPosData).iY
                    if cloumnIndex > 0 then
                        _wild:setScale(1)
                        _wild:setVisible(true)
                    end
                end
            end
            --还原展示
            local recoveryReelSymbol = function(_target, _reelSymbol)
                for _index, _symbolData in ipairs(_reelSymbol) do
                    local symbolNode = _target:getFixSymbol(_symbolData.iY, _symbolData.iX, SYMBOL_NODE_TAG)
                    if symbolNode then
                        local symbolType = _symbolData.symbolType
                        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
                        symbolNode:changeCCBByName(ccbName, symbolType)
                        symbolNode:changeSymbolImageByName(ccbName)
                        --
                        symbolNode:setScale(1)
                    end
                end
            end
            recoveryReelSymbol(self, self.m_moveWildReplaceSymbol[1])
            recoveryReelSymbol(self.m_DownReels, self.m_moveWildReplaceSymbol[2])

            --清理连线
            self:clearRoyaleBattleLineFrame()

            if fun then
                fun()
            end

            waitNode:removeFromParent()
        end,
        2
    )
end

function CodeGameScreenRoyaleBattleMachine:replaceMoveWildToReel(animIndex)
    self.m_moveWildReplaceSymbol = {
        [1] = {},
        [2] = {}
    }
    --替换棋盘内的小块展示
    local replaceReelSymbol = function(_target, _reelPosData, _reelIndex)
        local symbolType = self.SYMBOL_SCORE_MOVE_WILD
        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
        for _index, _symPosData in ipairs(_reelPosData) do
            if _symPosData.iY > 0 then
                local symbolNode = _target:getFixSymbol(_symPosData.iY, _symPosData.iX, SYMBOL_NODE_TAG)
                if symbolNode then
                    table.insert(
                        self.m_moveWildReplaceSymbol[_reelIndex],
                        {
                            iY = _symPosData.iY,
                            iX = _symPosData.iX,
                            symbolType = symbolNode.p_symbolType
                        }
                    )

                    symbolNode:changeCCBByName(ccbName, symbolType)
                    symbolNode:changeSymbolImageByName(ccbName)
                    --
                    local scale = 1 == animIndex and self.MOVE_WILD_SCALE or 1
                    symbolNode:setScale(scale)
                end
            end
        end
    end
    local posData = self:getMoveWildParamPosData(animIndex)
    replaceReelSymbol(self, posData[1], 1)
    replaceReelSymbol(self.m_DownReels, posData[2], 2)
    --重置层级
    self:reSetSymbolOrder()
end
--创建所有需要移动的wild小块
function CodeGameScreenRoyaleBattleMachine:createMoveWildSymbol(allPosList)
    local parent = self.m_wildsParent
    local symbolType = self.SYMBOL_SCORE_MOVE_WILD

    for _reelIndex, _reelPosList in ipairs(allPosList) do
        for _index, _pos in ipairs(_reelPosList) do
            local wild = self:getSlotNodeBySymbolType(symbolType)
            local nodePos = parent:convertToNodeSpace(_pos)
            wild:setPosition(nodePos)
            local order = self.ORDER_MOVE_WILD
            parent:addChild(wild, order)
            wild:setVisible(false)
            table.insert(self.m_moveWilds[_reelIndex], wild)
            --解决创建在第一行时 没有在滚动过程中完全遮盖背后小块问题
            wild:setScale(self.MOVE_WILD_SCALE)
        end
    end

    return self.m_moveWilds
end
function CodeGameScreenRoyaleBattleMachine:clearMoveWildSymbol()
    for _reelIndex, _wilds in ipairs(self.m_moveWilds) do
        for i, _wildNode in ipairs(_wilds) do
            --放进池子
            _wildNode:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(_wildNode.p_symbolType, _wildNode)
        end

        self.m_moveWilds[_reelIndex] = {}
    end
end
--服务器不赢钱没有发数值，补一下0
function CodeGameScreenRoyaleBattleMachine:initAllMoveWildWinAmounts()
    local allMobileWild = self:getMoveWildParamMobileWild(nil)
    local maxLen = math.max(#allMobileWild[1], #allMobileWild[2])

    for _reelIndex = 1, 2 do
        for _moveIndex = 1, maxLen do
            if not self.m_moveWildParams[_reelIndex].winAmounts[_moveIndex] then
                self.m_moveWildParams[_reelIndex].winAmounts[_moveIndex] = 0
            end
        end
    end
end
function CodeGameScreenRoyaleBattleMachine:getAllMoveWildWinCoin()
    local dataList = {
        [1] = {},
        [2] = {}
    }
    local insertData = function(_allData, _reelDataList)
        for _moveIndex, _data in ipairs(_allData) do
            local lastWinCoin = _reelDataList[_moveIndex - 1] or 0
            _reelDataList[_moveIndex] = lastWinCoin + _data
        end
    end

    local allData = self:getMoveWildParamWinAmounts(nil)

    local data_up = allData[1]
    insertData(data_up, dataList[1])

    local data_down = allData[2]
    insertData(data_down, dataList[2])

    return dataList
end
function CodeGameScreenRoyaleBattleMachine:getAllMoveWildWinLines()
    local dataList = {
        [1] = {},
        [2] = {}
    }
    local insertData = function(_allLines, _reelDataList)
        for _moveIndex, _lineList in ipairs(_allLines) do
            _reelDataList[_moveIndex] = {}
            --
            local m_vecGetLineInfo = {}
            for _index, _lineData in ipairs(_lineList) do
                --转换服务器数据,处理一下
                local winLineData = {
                    p_id = _lineData.id,
                    p_amount = _lineData.amount,
                    p_iconPos = _lineData.icons,
                    p_type = _lineData.type,
                    p_multiple = _lineData.multiple
                }

                local iconsPos = winLineData.p_iconPos
                -- 处理连线数据
                local lineInfo = self:getReelLineInfo()
                local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo, iconsPos)

                lineInfo.enumSymbolType = enumSymbolType
                lineInfo.iLineIdx = winLineData.p_id
                lineInfo.iLineSymbolNum = #iconsPos
                lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())

                table.insert(m_vecGetLineInfo, lineInfo)
            end

            local reelResultLines = {}
            for _index, _value in ipairs(m_vecGetLineInfo) do
                local cloneValue = clone(_value)
                table.insert(_reelDataList[_moveIndex], cloneValue)
            end
        end
    end

    local allLines = self:getMoveWildParamLines(nil)

    local lines_up = allLines[1]
    insertData(lines_up, dataList[1])

    local lines_down = allLines[2]
    insertData(lines_down, dataList[2])

    return dataList
end

function CodeGameScreenRoyaleBattleMachine:getAllMoveWildWorldPos()
    local posList = {
        [1] = {}, -- top
        [2] = {} -- down
    }
    --将两个轮盘的所有移动轨迹计算暂存
    local insertPosList = function(_target, _allMobileWild, _reelPosList, _reelIndex)
        --移动次数，
        for _moveIndex, _oneMobileWild in ipairs(_allMobileWild) do
            _reelPosList[_moveIndex] = {}
            --
            for _index, _pos in ipairs(_oneMobileWild) do
                local offsetX = 0
                local posData = _target:getRowAndColByPos(_pos)
                local cloumnIndex = posData.iY
                local rowIndex = posData.iX
                --本次移出轮盘的话，取 0 列的坐标
                if _pos < 0 or cloumnIndex < 1 then
                    local createPos = _allMobileWild[1][_index] or 0
                    local createPosData = _target:getRowAndColByPos(createPos)
                    --偏移至 第0列 格子
                    offsetX = -_target.m_SlotNodeW
                    cloumnIndex = 1
                    rowIndex = createPosData.iX
                end

                local WorldPos = self.m_symbolWorldPos[_reelIndex][cloumnIndex][rowIndex]
                if WorldPos then
                    WorldPos = cc.p(WorldPos.x + offsetX, WorldPos.y)
                    table.insert(_reelPosList[_moveIndex], WorldPos)
                end
            end
        end
    end

    local allMobileWild = self:getMoveWildParamMobileWild(nil)

    local mobileWild_up = allMobileWild[1]
    insertPosList(self, mobileWild_up, posList[1], 1)

    local mobileWild_down = allMobileWild[2]
    insertPosList(self.m_DownReels, mobileWild_down, posList[2], 2)

    return posList
end
--取出的小块坐标只能用于相互比较，不能作为参数，可能出现0
function CodeGameScreenRoyaleBattleMachine:getAllMoveWildPosData()
    local posDataList = {
        [1] = {},
        [2] = {}
    }

    local insertData = function(_target, _allMobileWild, _reelPosDataList)
        --
        for _moveIndex, _mobileWild in ipairs(_allMobileWild) do
            _reelPosDataList[_moveIndex] = {}
            --
            for _index, _pos in ipairs(_mobileWild) do
                local posData = _target:getRowAndColByPos(_pos)

                --本次移出轮盘的话，取 0 列的坐标
                if _pos < 0 or posData.iY < 1 then
                    local createPos = _allMobileWild[1][_index] or 0
                    posData = _target:getRowAndColByPos(createPos)

                    posData.iY = 0
                end

                table.insert(_reelPosDataList[_moveIndex], posData)
            end
        end
    end

    local allMobileWild = self:getMoveWildParamMobileWild(nil)

    local mobileWild_up = allMobileWild[1]
    insertData(self, mobileWild_up, posDataList[1])

    local mobileWild_down = allMobileWild[2]
    insertData(self.m_DownReels, mobileWild_down, posDataList[2])

    return posDataList
end

function CodeGameScreenRoyaleBattleMachine:clearRoyaleBattleLineFrame()
    local clearLineFrame = function(_target)
        _target:clearWinLineEffect()
    end
    clearLineFrame(self)
    clearLineFrame(self.m_DownReels)
end

--移动玩法 移除连线事件
function CodeGameScreenRoyaleBattleMachine:removeLineFrameEffect()
    local removeEffect = function(_target)
        local has = _target:removeGameEffectType(GameEffect.EFFECT_LINE_FRAME)
    end
    removeEffect(self)
    removeEffect(self.m_DownReels)
end
----------*****锁定wild玩法
function CodeGameScreenRoyaleBattleMachine:playSelfEffectLockWild()
    local nextFun = function()
        self:changeLockWildEffectState(false)
    end
    --创建高层炮台
    local scatterChangeData = self:getLockWildParamScatterChangeData()
    self:clearLockScatterSymbol()
    self:createLockScatterSymbol(scatterChangeData)

    --3.创建升级锁定wild 同时将覆盖的小块修改展示和连线动画名称
    local wildPosData = self:getLockWildParamWildPosData()
    local lockWildType = self.SYMBOL_SCORE_LOCK_WILD
    local isPlayNextFun = false
    local playLockWildCreate = false
    local playLockWildUpGrade = false
    local playNewLockWildAnim = function(_scatterChangeData)
        for _reelIndex, _reelData in ipairs(_scatterChangeData) do
            for _index, _data in ipairs(_reelData) do
                local target = 1 == _data.endReelIndex and self or self.m_DownReels
                local wild = self:getLockWildSymbol(_data.endReelIndex, _data.endPos)
                local symbolNode = target:getFixSymbol(_data.endPosData.iY, _data.endPosData.iX, SYMBOL_NODE_TAG)
                if wild then
                    --
                    local showMultiply = self:getCurLockWildMultiply(_data.endReelIndex, _data.endPos, true)

                    local animName = 1 == showMultiply and "actionframe1" or "actionframe2X1"

                    if not playLockWildCreate and 1 == showMultiply then
                        playLockWildCreate = true
                        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_LockWild_create.mp3")
                    end
                    if not playLockWildUpGrade and 2 == showMultiply then
                        playLockWildUpGrade = true
                        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_LockWild_upGrade.mp3")
                    end

                    wild:runAnim(
                        animName,
                        false,
                        function()
                            if not isPlayNextFun then
                                isPlayNextFun = true

                                nextFun()
                            end
                        end
                    )
                else
                    local waitNode = cc.Node:create()
                    self:addChild(waitNode)
                    performWithDelay(
                        waitNode,
                        function()
                            if not isPlayNextFun then
                                isPlayNextFun = true

                                nextFun()
                            end

                            waitNode:removeFromParent()
                        end,
                        60 / 60
                    )
                end
            end
        end
    end

    --清理连线
    self:clearRoyaleBattleLineFrame()
    --2.开炮
    local isPlayLaunch = false
    local isPlayOver = false
    local isPlayShake = false
    local playScatterLaunchAnim = function(_target, _launchData, _reelIndex)
        for _index, _data in ipairs(_launchData) do
            local scatter = self.m_lockScatter[_data.startReelIndex][_data.startPos]

            if scatter then
                --发射动作 --相对于 spine 的 actionframe
                local launchAnim = 1 == _reelIndex and "actionframe3" or "actionframe"
                self:playRoyaleBattleScatterAnim(
                    scatter,
                    launchAnim,
                    false,
                    25 / 30,
                    function()
                        --炮弹飞行
                        self:playLockWildTuowei(
                            _data.startWorldPos,
                            _data.endWorldPos,
                            _reelIndex,
                            true,
                            30 / 60,
                            function()
                                if not isPlayLaunch then
                                    isPlayLaunch = true

                                    self:clearCollimatorAnim()
                                    self:createLockWildSymbol(scatterChangeData)
                                    playNewLockWildAnim(scatterChangeData)
                                end
                            end
                        )
                        --炮台消失
                        if not isPlayOver then
                            isPlayOver = true

                            self:playAllLockScatterAnim("over")
                        end
                        --爆炸震屏
                        if not isPlayShake then
                            isPlayShake = true

                            local waitNode = cc.Node:create()
                            self:addChild(waitNode)
                            performWithDelay(
                                waitNode,
                                function()
                                    self:shakeNodeOnce(1, 3, 0.3)

                                    waitNode:removeFromParent()
                                end,
                                25 / 60
                            )
                        end
                    end
                )
            end
        end
    end

    playScatterLaunchAnim(self, scatterChangeData[1], 1)
    playScatterLaunchAnim(self.m_DownReels, scatterChangeData[2], 2)
    -- 转向音效 + 随机开火音效
    local fireSound = {
        "RoyaleBattleSounds/sound_RoyaleBattle_Scatter_fire_%d.mp3",
        "RoyaleBattleSounds/sound_RoyaleBattle_fs_start_%d.mp3"
    }
    local fireName = fireSound[math.random(1, #fireSound)]
    local soundName = ""
    if #scatterChangeData[1] > 0 and #scatterChangeData[2] > 0 then
        local soundReelIndex = math.random(1, 2)
        soundName = string.format(fireName, soundReelIndex)
        gLobalSoundManager:playSound(soundName)
    elseif #scatterChangeData[1] > 0 then
        soundName = string.format(fireName, 1)
        gLobalSoundManager:playSound(soundName)
    elseif #scatterChangeData[2] > 0 then
        soundName = string.format(fireName, 2)
        gLobalSoundManager:playSound(soundName)
    end

    --1.转向 (只有下棋盘需要转向)
    if #scatterChangeData[1] > 0 then
        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_Scatter_rotation_up.mp3")
        for _index, _data in ipairs(scatterChangeData[1]) do
            local scatter = self.m_lockScatter[1][_data.startPos]

            if scatter then
                self:playLockWildBallisticAnim(_data.startWorldPos, _data.endWorldPos, 1)
            end
        end
    end

    if #scatterChangeData[2] > 0 then
        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_Scatter_rotation_down.mp3")
        for _index, _data in ipairs(scatterChangeData[2]) do
            local scatter = self.m_lockScatter[2][_data.startPos]

            if scatter then
                self:playLockWildRotateAction(scatter, _data.startWorldPos, _data.endWorldPos)
                self:playLockWildBallisticAnim(_data.startWorldPos, _data.endWorldPos, 2)
            end
        end
    end
end

function CodeGameScreenRoyaleBattleMachine:playLockWildRotateAction(_scatterSymbol, _startPos, _endPos, _fun)
    --相对于 spine 的 actionframe
    local rotateTime = 25 / 30
    local scatterSpine = self:addScatterSpineNode(_scatterSymbol)

    if not scatterSpine then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                if _fun then
                    _fun()
                end

                waitNode:removeFromParent()
            end,
            rotateTime
        )
        return
    end
    local spineParent = scatterSpine:getParent()

    local rotation = util_getAngleByPos(_startPos, _endPos)
    rotation = 90 - rotation

    local act_rotateTo = cc.RotateBy:create(rotateTime, rotation)
    local act_callFun =
        cc.CallFunc:create(
        function()
            if _fun then
                _fun()
            end
        end
    )

    local act_sequence = cc.Sequence:create(act_rotateTo, act_callFun)

    spineParent:runAction(act_sequence)
end
--Scatter炮台弹道展示
function CodeGameScreenRoyaleBattleMachine:playLockWildBallisticAnim(startPos, endPos, reelIndex, rotatAddTime, countNum)
    rotatAddTime = rotatAddTime or 0

    --40帧弹道延伸完毕
    local rotateTime = 20 / 30 + rotatAddTime
    local rotation = util_getAngleByPos(startPos, endPos)
    local length = math.sqrt((endPos.x - startPos.x) * (endPos.x - startPos.x) + (endPos.y - startPos.y) * (endPos.y - startPos.y))
    local order = self.ORDER_LOCK_BALLISTIC

    local parent = self.m_wildsParent

    -- 弹道小点
    local count = countNum or 13
    local totalTime = rotateTime / (count) * (count - 1)
    local centerIndex = math.ceil(count / 2)
    local pointInterval = length / (count + 1)
    local pointList = {}
    for _index = 1, count do
        -- --创建
        -- local ballisticPoint = util_createAnimation("Socre_RoyaleBattle_Scatter_trigger_point.csb")
        -- parent:addChild(ballisticPoint, order)
        -- ballisticPoint:setVisible(false)
        -- pointList[_index] = ballisticPoint
        -- --坐标
        -- local offsetPos = cc.p( util_getCirclePointPos(0,0, pointInterval*_index, rotation) )
        -- local pointPos = cc.p(startPos.x+offsetPos.x, startPos.y+offsetPos.y)
        -- ballisticPoint:setPosition(parent:convertToNodeSpace(pointPos))
        -- --缩放
        -- local scaleX = 1 - math.abs(centerIndex - _index)  * (1 / (centerIndex))
        -- local scaleY = 1
        -- if _index~=centerIndex then
        --     scaleY = 0.8 - (math.abs(centerIndex - _index) - 1) * (0.8 / (centerIndex - 1))
        -- end
        -- ballisticPoint:setScaleX(scaleX)
        -- ballisticPoint:setScaleY(scaleY)
        -- --角度
        -- ballisticPoint:setRotation(- (rotation+90))

        --延时 出现/消失
        local pointIndex = _index
        local delayTime = rotateTime / (count) * (_index - 1)
        local waitNode = cc.Node:create()
        self:addChild(waitNode)

        performWithDelay(
            waitNode,
            function()
                waitNode:removeFromParent()
                -- performWithDelay(ballisticPoint, function()
                -- ballisticPoint:setVisible(true)
                --创建
                local ballisticPoint = util_createAnimation("Socre_RoyaleBattle_Scatter_trigger_point.csb")
                parent:addChild(ballisticPoint, order)
                pointList[_index] = ballisticPoint
                --坐标
                local offsetPos = cc.p(util_getCirclePointPos(0, 0, pointInterval * _index, rotation))
                local pointPos = cc.p(startPos.x + offsetPos.x, startPos.y + offsetPos.y)
                ballisticPoint:setPosition(parent:convertToNodeSpace(pointPos))
                --缩放
                local scaleX = 1 - math.abs(centerIndex - _index) * (1 / (centerIndex))
                local scaleY = 1
                if _index ~= centerIndex then
                    scaleY = 0.8 - (math.abs(centerIndex - _index) - 1) * (0.8 / (centerIndex - 1))
                end
                ballisticPoint:setScaleX(scaleX)
                ballisticPoint:setScaleY(scaleY)
                --角度
                ballisticPoint:setRotation(-(rotation + 90))

                if pointIndex == count then
                    for _index, _point in ipairs(pointList) do
                        --转向-发射-爆炸
                        local act_fade = cc.FadeOut:create((50 + 30 - 40) / 60)
                        local act_callFun =
                            cc.CallFunc:create(
                            function()
                                _point:removeFromParent()
                            end
                        )
                        util_setCascadeOpacityEnabledRescursion(_point, true)
                        _point:runAction(cc.Sequence:create(act_fade, act_callFun))
                    end
                end
            end,
            delayTime
        )
    end

    -- 准星
    local collimatorAnim = util_createAnimation("Socre_RoyaleBattle_Scatter_trigger.csb")
    parent:addChild(collimatorAnim, order)
    collimatorAnim:setPosition(parent:convertToNodeSpace(startPos))
    local act_moveTo = cc.MoveTo:create(rotateTime, parent:convertToNodeSpace(endPos))
    collimatorAnim:runAction(act_moveTo)

    -- local ishide = isOverHide
    collimatorAnim:runCsbAction("actionframe")

    table.insert(self.m_collimatorAnim[reelIndex], collimatorAnim)

    return totalTime, collimatorAnim
end

function CodeGameScreenRoyaleBattleMachine:clearCollimatorAnim()
    for reelIndex, reelData in ipairs(self.m_collimatorAnim) do
        for _index, _anim in ipairs(reelData) do
            _anim:removeFromParent()
        end
        self.m_collimatorAnim[reelIndex] = {}
    end
end
--Scatter炮弹飞行
function CodeGameScreenRoyaleBattleMachine:playLockWildTuowei(_startPos, _endPos, _reelIndex, _playBlast, _delayTime, _fun, _waittime)
    local startPos, endPos, reelIndex, playBlast, delayTime, fun, waittime = _startPos, _endPos, _reelIndex, _playBlast, _delayTime, _fun, _waittime

    waittime = waittime or 0
    --炮口偏移 ，终点偏移
    local startOffset = cc.p(0, 0)
    local endOffset = cc.p(0, 0)
    --
    delayTime = delayTime or (30 / 60)

    local fly_ccbName = 1 == reelIndex and "Socre_RoyaleBattle_Scatter_2tuowei.csb" or "Socre_RoyaleBattle_Scatter_1tuowei.csb"
    local fly_node = util_createAnimation(fly_ccbName)

    local rotation = util_getAngleByPos(startPos, endPos)

    --炮口距中心点长度
    local batteryLength = 1 == reelIndex and 57 or 100
    --动画长度
    local animLength = 1 == reelIndex and 338 or 151
    --弹弓的偏移
    if 1 == reelIndex then
        --大炮的偏移
        startOffset = cc.p(0, batteryLength)
    elseif 2 == reelIndex then
        startOffset = cc.p(util_getCirclePointPos(0, 0, batteryLength, rotation))
    end
    endOffset = cc.p(util_getCirclePointPos(0, 0, animLength, rotation + 180))

    --修改初始位置和角度
    fly_node:setPosition(cc.p(startPos.x + startOffset.x, startPos.y + startOffset.y))
    local order = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5
    self:addChild(fly_node, order)
    fly_node:setRotation(-rotation)

    --放弃缩放手段 改用位移动作
    -- local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
    -- local width = 1==reelIndex and 338 or 151
    -- fly_node:setScaleX(scaleSize / width )
    performWithDelay(
        self,
        function()
            local act_moveTo = cc.MoveTo:create(25 / 60, cc.p(endPos.x + endOffset.x, endPos.y + endOffset.y))
            fly_node:runAction(act_moveTo)

            local func_1 = fun
            fly_node:runCsbAction(
                "actionframe",
                false,
                function()
                    --爆炸
                    if playBlast then
                        self:playEffectBaozha(endPos)
                    end
                    local func_2 = func_1
                    --下一步
                    local waitNode = cc.Node:create()
                    self:addChild(waitNode)
                    performWithDelay(
                        waitNode,
                        function()
                            if func_2 then
                                func_2()
                            end

                            waitNode:removeFromParent()
                        end,
                        delayTime
                    )

                    fly_node:removeFromParent()
                end
            )
        end,
        waittime
    )

    return 25 / 30 + waittime
end

function CodeGameScreenRoyaleBattleMachine:playEffectBaozha(_position, _fun)
    local order = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5
    local baozha = util_createAnimation("Socre_RoyaleBattle_Wild_1L.csb")
    baozha:setPosition(_position)
    self:addChild(baozha, order)
    baozha:runCsbAction(
        "actionframe",
        false,
        function()
            if _fun then
                _fun()
            end

            baozha:removeFromParent()
        end
    )
end
--创建临时wild
--[[
    params = {
        playAnimName = ""
    }
]]
function CodeGameScreenRoyaleBattleMachine:createLockWildSymbol(allPosList, params)
    local parent = self.m_wildsParent
    local symbolType = self.SYMBOL_SCORE_LOCK_WILD
    params = params or {}

    for _reelIndex, _reelPosList in ipairs(allPosList) do
        for _index, _data in ipairs(_reelPosList) do
            local wild = self.m_lockWilds[_data.endReelIndex][_data.endPos]
            --没有 创建
            if not wild then
                --已经存在
                wild = self:getSlotNodeBySymbolType(symbolType)
                local nodePos = parent:convertToNodeSpace(_data.endWorldPos)
                wild:setPosition(nodePos)
                local order = self.ORDER_LOCK_WILD - _data.endPosData.iX
                parent:addChild(wild, order)

                --播放动画
                if params.playAnimName then
                    --首次创建时 带有乘倍字段 (一般在fs重连存在)
                    wild:runAnim(params.playAnimName)
                elseif _data.multiply then
                    local animName = _data.multiply > 1 and "actionframe2X1" or "actionframe1"
                    wild:runAnim(animName)
                end

                self:insertLockWildSymbol(wild, _data.endReelIndex, _data.endPos)
            else
            end
        end
    end

    return self.m_lockWilds
end
function CodeGameScreenRoyaleBattleMachine:insertLockWildSymbol(_wild, _reelIndex, _pos)
    self.m_lockWilds[_reelIndex][_pos] = _wild
end
--固定wild
function CodeGameScreenRoyaleBattleMachine:getLockWildSymbol(_reelIndex, _pos)
    return self.m_lockWilds[_reelIndex][_pos]
end
--清理
function CodeGameScreenRoyaleBattleMachine:clearLockWildSymbol()
    for _reelIndex, _wilds in ipairs(self.m_lockWilds) do
        for _pos, _wildNode in pairs(_wilds) do
            --放进池子
            _wildNode:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(_wildNode.p_symbolType, _wildNode)
        end

        self.m_lockWilds[_reelIndex] = {}
    end
end
--炮台
--[[
    params = {
        limitCol = 0
    }
]]
function CodeGameScreenRoyaleBattleMachine:createLockScatterSymbol(_scatterChangeData, params)
    local parent = self.m_wildsParent
    params = params or {}
    --替换棋盘内的scattr 为随机图标
    local replaceReelScatter = function(_target, _scatter)
        if self:isRoyaleBattleScatter(_scatter.p_symbolType) then
            --取随机信号
            local cloumnIndex = _scatter.p_cloumnIndex
            local reelDatas = _target.m_configData:getNormalReelDatasByColumnIndex(cloumnIndex)
            local symbolType = _scatter.p_symbolType
            while self:isRoyaleBattleScatter(symbolType) do
                symbolType = _target:getRandomReelType(cloumnIndex, reelDatas)
            end
            --切换
            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            _scatter:changeCCBByName(ccbName, symbolType)
            _scatter:changeSymbolImageByName(ccbName)
            _scatter:resetReelStatus()
        end
    end
    --
    for _reelIndex, _reelPosList in ipairs(_scatterChangeData) do
        local target = 1 == _reelIndex and self or self.m_DownReels
        local symbolType = 1 == _reelIndex and self.SYMBOL_SCORE_UP_SCATTER or self.SYMBOL_SCORE_DOWN_SCATTER
        for _index, _data in ipairs(_reelPosList) do
            local limitCol = params.limitCol or self.m_iReelColumnNum
            local canCreate = _data.startPosData.iY <= limitCol
            --

            local scatter = self.m_lockScatter[_data.startReelIndex][_data.startPos]
            --没有 创建
            if not scatter then
                --有的话
                if canCreate then
                    scatter = self:getSlotNodeBySymbolType(symbolType)
                    local nodePos = parent:convertToNodeSpace(_data.startWorldPos)
                    scatter:setPosition(nodePos)
                    local order = self.ORDER_LOCK_SCATTER - _data.startPosData.iX
                    parent:addChild(scatter, order)

                    self.m_lockScatter[_data.startReelIndex][_data.startPos] = scatter
                end
            else
                if canCreate then
                    self:playRoyaleBattleScatterAnim(scatter, "idleframe")
                    self:addScatterSpineNode(scatter)
                end
            end

            if canCreate then
                local reelScatter = target:getFixSymbol(_data.startPosData.iY, _data.startPosData.iX, SYMBOL_NODE_TAG)
                if reelScatter then
                    replaceReelScatter(target, reelScatter)
                end
            --
            end
        end
    end

    return self.m_lockScatter
end
function CodeGameScreenRoyaleBattleMachine:clearLockScatterSymbol()
    for _reelIndex, _scatters in ipairs(self.m_lockScatter) do
        for _pos, _scatterNode in pairs(_scatters) do
            --放进池子
            _scatterNode:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(_scatterNode.p_symbolType, _scatterNode)
        end

        self.m_lockScatter[_reelIndex] = {}
    end
end
function CodeGameScreenRoyaleBattleMachine:playAllLockScatterAnim(_animName, _isLoop, _delay, _fun)
    local isPlay = false

    for _reelIndex, _scatters in ipairs(self.m_lockScatter) do
        for _pos, _scatterNode in pairs(_scatters) do
            self:playRoyaleBattleScatterAnim(
                _scatterNode,
                _animName,
                _isLoop,
                _delay,
                function()
                    if not isPlay then
                        isPlay = true

                        if _fun then
                            _fun()
                        end
                    end
                end
            )
        end
    end
end
function CodeGameScreenRoyaleBattleMachine:resetScatterState()
    for _reelIndex, _scatters in ipairs(self.m_lockScatter) do
        for _pos, _scatterNode in pairs(_scatters) do
            self:playRoyaleBattleScatterAnim(_scatterNode, "idleframe")
            self:addScatterSpineNode(_scatterNode)
        end
    end
end
--连线前 将固定wild 层级修改 加入连线
function CodeGameScreenRoyaleBattleMachine:changeFreeSpinLineShow(_posData)
    if not self.m_bProduceSlots_InFreeSpin then
        return
    end
    local wildPosData = _posData or {}

    local symbolType = self.SYMBOL_SCORE_LOCK_WILD

    for _reelIndex, _reelData in ipairs(wildPosData) do
        for _index, _data in ipairs(_reelData) do
            local target = 1 == _data.endReelIndex and self or self.m_DownReels
            local symbolNode = target:getFixSymbol(_data.endPosData.iY, _data.endPosData.iX, SYMBOL_NODE_TAG)
            if symbolNode then
                local showMultiply = self:getCurLockWildMultiply(_reelIndex, _data.endPos)

                local animName = showMultiply <= 1 and "idleframe3" or "idleframe4"
                local lineFrame = showMultiply <= 1 and "actionframe2" or "actionframe2X2"
                --
                local ccbName = self:getSymbolCCBNameByType(self, symbolType)
                symbolNode:changeCCBByName(ccbName, symbolType)
                symbolNode:changeSymbolImageByName(ccbName)
                symbolNode:setLineAnimName(lineFrame)
                symbolNode:setIdleAnimName(animName)
                --
                symbolNode:runAnim(animName)
            end
        end
    end

    self:changeLockWildVisible(false)
end
function CodeGameScreenRoyaleBattleMachine:changeLockWildVisible(isVis)
    for _reelIndex, _reelNodes in ipairs(self.m_lockWilds) do
        for _index, _wild in pairs(_reelNodes) do
            _wild:setVisible(isVis)
        end
    end
end
--[[
    @desc: 遮罩相关
]]
function CodeGameScreenRoyaleBattleMachine:createRoyaleBattleMask(_mainClass)
    --棋盘主类
    local mainClass = _mainClass or self
    --单列卷轴尺寸
    local reel = mainClass:findChild("sp_reel_0")
    local reelSize = reel:getContentSize()
    local posX = reel:getPositionX()
    local posY = reel:getPositionY()
    local scaleX = reel:getScaleX()
    local scaleY = reel:getScaleY()
    --棋盘尺寸
    local offsetSize = cc.size(5, 5)
    reelSize.width = reelSize.width * scaleX * mainClass.m_iReelColumnNum + offsetSize.width
    reelSize.height = reelSize.height * scaleY + offsetSize.height
    --遮罩尺寸和坐标
    local clipParent = mainClass.m_onceClipNode or mainClass.m_clipParent
    local panelOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1
    local panel = cc.LayerColor:create(cc.c3b(0, 0, 0))
    panel:setOpacity(self.m_panelOpacity)
    panel:setContentSize(reelSize.width, reelSize.height)
    panel:setPosition(cc.p(posX - offsetSize.width / 2, posY - offsetSize.height / 2))
    clipParent:addChild(panel, panelOrder)
    panel:setVisible(false)

    return panel
end
function CodeGameScreenRoyaleBattleMachine:changeMaskVisible(_isVis)
    self.m_panelUp:setVisible(_isVis)
    self.m_panelUp:setOpacity(self.m_panelOpacity)

    self.m_DownReels:MainReel_changeMaskVisible(_isVis)
end
function CodeGameScreenRoyaleBattleMachine:playMaskFadeAction(_isFadeIn, _fadeTime, _fun)
    local fadeTime = _fadeTime or 0.1
    local opacity = _isFadeIn and 0 or self.m_panelOpacity

    local act_fade = _isFadeIn and cc.FadeIn:create(fadeTime) or cc.FadeOut:create(fadeTime)
    self.m_panelUp:setOpacity(opacity)
    self.m_panelUp:setVisible(true)
    self.m_panelUp:runAction(act_fade)

    self.m_DownReels:MainReel_playMaskFadeAction(_isFadeIn, _fadeTime)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            if _fun then
                _fun()
            end

            waitNode:removeFromParent()
        end,
        fadeTime
    )
end

function CodeGameScreenRoyaleBattleMachine:playParticlePanelFadeAction(_isFadeIn, _iReelIndex)
    --坐标
    local posY_up = 302
    local posY_down = -168
    local posY = 1 == _iReelIndex and posY_up or posY_down
    -- posY = posY + self.MAINREEL_OFFSET_Y
    --渐变参数
    local fadeTime = 0.5
    local act_fade = _isFadeIn and cc.FadeIn:create(fadeTime) or cc.FadeOut:create(fadeTime)

    if _isFadeIn then
        --位置调整
        self.m_panelParticle:setPositionY(posY)
        --内部可见性
        local upNode = self.m_panelParticle:findChild("Panel_1")
        local downNode = self.m_panelParticle:findChild("Panel_1_0")
        upNode:setVisible(1 == _iReelIndex)
        downNode:setVisible(2 == _iReelIndex)
        --整个遮罩可见性
        self.m_panelParticle:setVisible(true)

        --要操作的遮罩
        local panel = 1 == _iReelIndex and upNode or downNode
        panel:setOpacity(0)
        panel:runAction(act_fade)
    else
        local act_callFun =
            cc.CallFunc:create(
            function()
                self.m_panelParticle:setVisible(false)
            end
        )

        local upNode = self.m_panelParticle:findChild("Panel_1")
        local downNode = self.m_panelParticle:findChild("Panel_1_0")
        --要操作的遮罩
        local panel = 1 == _iReelIndex and upNode or downNode

        panel:runAction(cc.Sequence:create(act_fade, act_callFun))
    end
end

function CodeGameScreenRoyaleBattleMachine:getAllLockWildScatterChangeData()
    local dataList = {
        [1] = {},
        [2] = {}
    }
    local insertData = function(_target, _otherTarget, _allData, _reelDataList, _reelIndex)
        local otherReelIndex = 1 == _reelIndex and 2 or 1
        for _startPos, _endPos in pairs(_allData) do
            local startPos = tonumber(_startPos)
            local endPos = tonumber(_endPos)
            --用自身
            local startPosData = _target:getRowAndColByPos(startPos)
            local startWorldPos = cc.p(-500, -500)
            local slotParent = _target:getReelParent(startPosData.iY)
            if slotParent then
                local nodePos = util_getPosByColAndRow(_target, startPosData.iY, startPosData.iX)
                startWorldPos = slotParent:convertToWorldSpace(nodePos)
            end
            --用另一个棋盘
            local endPosData = _otherTarget:getRowAndColByPos(endPos)
            local endWorldPos = cc.p(-500, -500)
            slotParent = _otherTarget:getReelParent(endPosData.iY)
            if slotParent then
                local nodePos = util_getPosByColAndRow(_otherTarget, endPosData.iY, endPosData.iX)
                endWorldPos = slotParent:convertToWorldSpace(nodePos)
            end

            local data = {
                --玩法大部分接口必要的字段
                endPos = endPos,
                endPosData = endPosData,
                endWorldPos = endWorldPos,
                endReelIndex = otherReelIndex,
                --可选
                startPos = startPos,
                startPosData = startPosData,
                startWorldPos = startWorldPos,
                startReelIndex = _reelIndex
            }

            table.insert(_reelDataList, data)
        end
    end

    local scatterChange = self:getLockWildParamScatterChange()

    local scatterChange_up = scatterChange[1]
    insertData(self, self.m_DownReels, scatterChange_up, dataList[1], 1)

    local scatterChange_down = scatterChange[2]
    insertData(self.m_DownReels, self, scatterChange_down, dataList[2], 2)

    return dataList
end
function CodeGameScreenRoyaleBattleMachine:getAllLockWildPosData()
    local dataList = {
        [1] = {},
        [2] = {}
    }
    local insertData = function(_target, _allData, _reelDataList, _reelIndex)
        for _endPos, _multiply in pairs(_allData) do
            local endPos = tonumber(_endPos)

            local endPosData = _target:getRowAndColByPos(endPos)
            local endWorldPos = cc.p(-500, -500)
            local slotParent = _target:getReelParent(endPosData.iY)
            if slotParent then
                local nodePos = util_getPosByColAndRow(_target, endPosData.iY, endPosData.iX)
                endWorldPos = slotParent:convertToWorldSpace(nodePos)
            end

            local data = {
                --玩法大部分接口必要的字段
                endPos = endPos,
                endPosData = endPosData,
                endWorldPos = endWorldPos,
                endReelIndex = _reelIndex,
                --可选
                multiply = _multiply
            }

            table.insert(_reelDataList, data)
        end
    end

    local wildPositions = self:getLockWildParamWildPositions()

    local wildPositions_up = wildPositions[1]
    insertData(self, wildPositions_up, dataList[1], 1)

    local wildPositions_down = wildPositions[2]
    insertData(self.m_DownReels, wildPositions_down, dataList[2], 2)

    return dataList
end
----------*****FG次数增加事件展示
function CodeGameScreenRoyaleBattleMachine:playSelfEffectAddTimes(effectData)
    local effectOverFun = function()
        effectData.p_isPlay = true
        self:playGameEffect()

        self.m_DownReels:MainReel_removeSelfEffect(effectData)
    end

    local scatterChangeData = self:getLockWildParamScatterChangeData()

    local offsetY = -self.m_SlotNodeH / 4
    local endWorldPos = util_convertToNodeSpace(self.m_baseFreeSpinBar:getFlyEndNode(), self)
    local isPlayNextFun = false
    local isPlaySound = false
    for _reelIndex, _reelData in ipairs(scatterChangeData) do
        for _index, _data in ipairs(_reelData) do
            local startWorldPos = cc.p(_data.startWorldPos.x, _data.startWorldPos.y + offsetY)
            self:playTimesLabFlyAction(
                startWorldPos,
                endWorldPos,
                function()
                    if not isPlayNextFun then
                        isPlayNextFun = true

                        self.m_baseFreeSpinBar:playMoreTimesAnim(
                            function()
                                self.m_baseFreeSpinBar:changeFreeSpinByCount()
                            end
                        )
                        effectOverFun()
                    end
                end
            )
            if not isPlaySound then
                isPlaySound = true
                local waitNode = cc.Node:create()
                self:addChild(waitNode)
                performWithDelay(
                    waitNode,
                    function()
                        gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_fs_addTimes.mp3")

                        waitNode:removeFromParent()
                    end,
                    30 / 60
                )
            end
        end
    end
end
function CodeGameScreenRoyaleBattleMachine:playTimesLabFlyAction(_startPos, _endPos, _fun)
    local fly_ccbName = "Socre_RoyaleBattle_Scatteradd1.csb"
    local fly_node = util_createAnimation(fly_ccbName)
    local order = self.ORDER_LOCK_SCATTER + (self.m_iReelColumnNum * 10 + self.m_iReelRowNum) + 5
    self:addChild(fly_node, order)
    fly_node:setPosition(_startPos)

    fly_node:findChild("Particle_1"):setPositionType(0)
    fly_node:findChild("Particle_2"):setPositionType(0)

    fly_node:runCsbAction(
        "start",
        false,
        function()
            fly_node:runCsbAction("shouji")
            --10帧开始 30帧结束
            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(
                waitNode,
                function()
                    local act_moveTo = cc.MoveTo:create((30 - 10) / 60, _endPos)
                    local act_callFun =
                        cc.CallFunc:create(
                        function()
                            if _fun then
                                _fun()
                            end

                            fly_node:removeFromParent()
                        end
                    )

                    local act_sequence = cc.Sequence:create(act_moveTo, act_callFun)
                    fly_node:runAction(act_sequence)

                    waitNode:removeFromParent()
                end,
                10 / 60
            )
        end
    )
end
----------*****中奖预告
function CodeGameScreenRoyaleBattleMachine:playWinningNoticeAnim(_fun)
    local reelIndex = self:getMoveWildReelIndex()
    gLobalSoundManager:playSound(string.format("RoyaleBattleSounds/sound_RoyaleBattle_MoveWild_start_%d.mp3", reelIndex))

    self:shakeOneNodeForever(
        function()
            self:runCsbAction(
                "actionframe",
                false,
                function()
                    self:runCsbAction("idle", true)
                end
            )
            --第155帧 播放粒子
            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(
                waitNode,
                function()
                    local particle = self:findChild("Particle_1")
                    if particle then
                        particle:stopSystem()
                        particle:resetSystem()
                    end

                    performWithDelay(
                        waitNode,
                        function()
                            if _fun then
                                _fun()
                            end

                            waitNode:removeFromParent()
                        end,
                        45 / 60
                    )
                end,
                5 / 60
            )
        end
    )

    --
end
--[[
    @desc:  屏幕震动相关
]]
function CodeGameScreenRoyaleBattleMachine:shakeOneNodeForever(_fun)
    local oldPos = cc.p(self:getPosition())
    local changePosY = math.random(1, 3)
    local changePosX = math.random(1, 3)
    local actionList2 = {}
    actionList2[#actionList2 + 1] = cc.MoveTo:create(0.05, cc.p(oldPos.x - changePosX, oldPos.y - changePosY))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(0.05, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
    local seq2 = cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)

    self:runAction(action)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            if _fun then
                _fun()
            end

            performWithDelay(
                waitNode,
                function()
                    self:stopAction(action)
                    self:setPosition(oldPos)

                    waitNode:removeFromParent()
                end,
                1.5
            )
        end,
        0.5
    )
end
function CodeGameScreenRoyaleBattleMachine:shakeNodeOnce(_changeMin, _changeMax, _shakeTime)
    if self.m_actShake then
        return
    end
    --随机幅度
    local changeMin = _changeMin or 3
    local changeMax = _changeMax or 5
    --晃动时间 不能超过触发间隔 移动玩法：self.MOVE_WILD_INTERVAL，锁定玩法 只播一次
    local shakeTime = _shakeTime or 0.4

    local oldPos = cc.p(self:getPosition())
    local changePosY = math.random(changeMin, changeMax)
    local changePosX = math.random(changeMin, changeMax)
    local actionList2 = {}
    actionList2[#actionList2 + 1] = cc.MoveTo:create(shakeTime / 2, cc.p(oldPos.x - changePosX, oldPos.y - changePosY))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(shakeTime / 2, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))

    self.m_actShake = cc.Sequence:create(actionList2)
    self:runAction(self.m_actShake)
    --状态重置放在延时里，防止主棋盘被暂停导致状态无法重置
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            self:setPosition(oldPos)
            self.m_actShake = nil

            waitNode:removeFromParent()
        end,
        shakeTime
    )
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenRoyaleBattleMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
    local reelRunData = self.m_reelRunInfo
end

function CodeGameScreenRoyaleBattleMachine:playEffectNotifyNextSpinCall()
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenRoyaleBattleMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    --将滚动时提层的scatter还原层级
    -- if self.m_bProduceSlots_InFreeSpin then
    self:reSetSymbolOrder(1)
    -- end

    BaseNewReelMachine.slotReelDown(self)
end

-- 将下棋盘的消息返回拆分一下
-- 处理spin 返回结果
function CodeGameScreenRoyaleBattleMachine:spinResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.result then
            if spinData.result.selfData then
                if spinData.result.selfData.spinResultDown then
                    spinData.result.selfData.spinResultDown.bet = spinData.result.bet
                    self.m_DownReels:MainReel_parseResultData(spinData.result.selfData.spinResultDown)
                end
            end
        end
    end
    CodeGameScreenRoyaleBattleMachine.super.spinResultCallFun(self, param)

    if param[1] == true then
        local spinData = param[2]
        if spinData.result then
            if spinData.result.selfData then
                if spinData.result.selfData.spinResultDown then
                    self.m_DownReels:MainReel_updateNetWorkData()
                end
            end
        end
    end
end
function CodeGameScreenRoyaleBattleMachine:beginReel()
    -- 展示遮罩
    -- if self.m_bProduceSlots_InFreeSpin then
    self:changeMaskVisible(true)
    -- end

    if self.m_bLockWildEffect then
        self:playSelfEffectLockWild()
    end

    --滚动时将固定小块层级改为最高
    self:changeLockWildVisible(true)

    CodeGameScreenRoyaleBattleMachine.super.beginReel(self)
    self.m_DownReels:beginMiniReel()
end

function CodeGameScreenRoyaleBattleMachine:playEffectNotifyChangeSpinStatus()
    self:reelShowSpinNotify()
end

function CodeGameScreenRoyaleBattleMachine:reelShowSpinNotify()
    self.m_norCSStatesTimes = self.m_norCSStatesTimes + 1

    if self.m_norCSStatesTimes == self.m_maxReelNum then
        CodeGameScreenRoyaleBattleMachine.super.playEffectNotifyChangeSpinStatus(self)
        self.m_norCSStatesTimes = 0
    end
end

function CodeGameScreenRoyaleBattleMachine:reelDownNotifyPlayGameEffect()
    self:setReelRunDownNotify()
end

function CodeGameScreenRoyaleBattleMachine:setReelRunDownNotify()
    self.m_norDownTimes = self.m_norDownTimes + 1

    if self.m_norDownTimes == self.m_maxReelNum then
        CodeGameScreenRoyaleBattleMachine.super.reelDownNotifyPlayGameEffect(self)
        self.m_norDownTimes = 0
    end
end

-- 初始化上次游戏状态数据
--
function CodeGameScreenRoyaleBattleMachine:initGameStatusData(gameData)
    CodeGameScreenRoyaleBattleMachine.super.initGameStatusData(self, gameData)

    if gameData.spin then
        if gameData.spin.selfData then
            if gameData.spin.selfData.spinResultDown then
                local data = {}
                data.spin = gameData.spin.selfData.spinResultDown
                --!!!插入玩法字段, 公用的字段赋值
                data.spin.features = gameData.spin.features and clone(gameData.spin.features) or {}
                data.spin.freespin = gameData.spin.freespin and clone(gameData.spin.freespin) or {}
                self.m_DownReels:initMiniGameStatusData(data)
            end
        end
    end

    if nil ~= gameData.gameConfig then
        local extra = gameData.gameConfig.extra
        if nil ~= extra then
            local bet = {}
            -- 只拿自己需要的数据重组一下服务器下发的数据
            local allBetData = extra.allBetData or {}
            for _betStr, _betData in pairs(allBetData) do
                local collect = _betData.collect[1]
                bet[_betStr] = {
                    leftTimes = collect.collectTotalCount - collect.collectLeftCount,
                    topCount = _betData.battleCount[1],
                    downCount = _betData.battleCount[2]
                }
            end
            self:initSpinTimesBet(bet)

            local totalSpinTimes = extra.collectTotal or 10
            self.m_totalSpinTimes = totalSpinTimes
        end
    end
end

function CodeGameScreenRoyaleBattleMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 and #self.m_DownReels.m_vecGetLineInfo == 0 then
        notAdd = true
    end

    return notAdd
end

--[[
    @desc: Scatter小块的操作
]]
function CodeGameScreenRoyaleBattleMachine:isRoyaleBattleScatter(_symbolType)
    local isScatter = (_symbolType == self.SYMBOL_SCORE_UP_SCATTER) or (_symbolType == self.SYMBOL_SCORE_DOWN_SCATTER)

    return isScatter
end
function CodeGameScreenRoyaleBattleMachine:getRoyaleBattleScatterIndex(_symbolType)
    local scatterIndex = _symbolType == self.SYMBOL_SCORE_UP_SCATTER and 2 or 1

    return scatterIndex
end
function CodeGameScreenRoyaleBattleMachine:addScatterSpineNode(_scatterSymbol)
    local scatterSpine = nil
    if not self:isRoyaleBattleScatter(_scatterSymbol.p_symbolType) then
        return scatterSpine
    end

    _scatterSymbol:checkLoadCCbNode()
    local spineParent = _scatterSymbol:getCcbProperty("Node_spine")
    if spineParent then
        scatterSpine = spineParent:getChildByName("scatterSpine")

        if not scatterSpine then
            local scatterIndex = self:getRoyaleBattleScatterIndex(_scatterSymbol.p_symbolType)
            local spineName = string.format("Socre_RoyaleBattle_Scatter_%d", scatterIndex)
            scatterSpine = util_spineCreate(spineName, true, true)
            spineParent:addChild(scatterSpine)
            scatterSpine:setName("scatterSpine")

            util_spinePlay(scatterSpine, "idleframe")
        end

        spineParent:setRotation(0)
    end

    return scatterSpine
end
function CodeGameScreenRoyaleBattleMachine:getScatterSpineNode(_scatterSymbol)
    local scatterSpine = nil
    if not self:isRoyaleBattleScatter(_scatterSymbol.p_symbolType) then
        return scatterSpine
    end

    local spineParent = _scatterSymbol:getCcbProperty("Node_spine")
    if spineParent then
        scatterSpine = spineParent:getChildByName("scatterSpine")
    end

    return scatterSpine
end
function CodeGameScreenRoyaleBattleMachine:removeScatterSpineNode(_scatterSymbol)
    if not self:isRoyaleBattleScatter(_scatterSymbol.p_symbolType) then
        return
    end
    local spineParent = _scatterSymbol:getCcbProperty("Node_spine")
    if spineParent then
        local scatterSpine = spineParent:getChildByName("scatterSpine")
        if scatterSpine then
            scatterSpine:removeFromParent()
        end
    end
end
function CodeGameScreenRoyaleBattleMachine:playRoyaleBattleScatterAnim(_scatterSymbol, _animName, _isLoop, _delay, _fun)
    _scatterSymbol:runAnim(_animName, _isLoop)

    local spineParent = _scatterSymbol:getCcbProperty("Node_spine")
    if spineParent then
        local scatterSpine = spineParent:getChildByName("scatterSpine")
        if scatterSpine then
            util_spinePlay(scatterSpine, _animName)
        end
    end

    if _delay and _fun then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                if _fun then
                    _fun()
                end

                waitNode:removeFromParent()
            end,
            _delay
        )
    end
end

function CodeGameScreenRoyaleBattleMachine:reSetSymbolOrder(_reelIndex)
    local reSetReelSymbolOrder = function(_target)
        for iCol = 1, _target.m_iReelColumnNum do
            for iRow = _target.m_iReelRowNum, 1, -1 do
                local node = _target:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

                if node then
                    local order = self:getBounsScatterDataZorder(node.p_symbolType)
                    order = order - iRow
                    self:reelGridNode_updateLayer(node, false, order)
                end
            end
        end
    end

    if not _reelIndex or 1 == _reelIndex then
        reSetReelSymbolOrder(self)
    end
    if not _reelIndex or 2 == _reelIndex then
        reSetReelSymbolOrder(self.m_DownReels)
    end
end

--[[
    @desc: 轮盘小块相关接口
]]
function CodeGameScreenRoyaleBattleMachine:reelGridNode_updateLayer(_symbolNode, _changeToTop, _showOrder)
    _symbolNode.p_showOrder = _showOrder
    _symbolNode:setLocalZOrder(_showOrder)
    --切换层级和当前层级不一致时执行
    if _symbolNode.m_isInTop ~= _changeToTop then
        local oldWorldPos = _symbolNode:getParent():convertToWorldSpace(cc.p(_symbolNode:getPosition()))

        --普通层级信号切换特殊层级信号
        if _changeToTop then
            --特殊层级信号切换普通层级信号
            util_changeNodeParent(_symbolNode.m_topNode, _symbolNode, _symbolNode.p_showOrder)
        else
            util_changeNodeParent(_symbolNode.m_baseNode, _symbolNode, _symbolNode.p_showOrder)
        end

        local newNodePos = _symbolNode:getParent():convertToNodeSpace(oldWorldPos)
        _symbolNode:setPosition(newNodePos)

        _symbolNode.m_isInTop = _changeToTop
    end
end
--[[
    @desc: 底部轮盘调用接口
]]
-- 解决上棋盘无连线 下棋盘有连线时 底栏赢钱不更新问题
-- 下棋盘连线时通知一下上棋盘，检测 是否需要通知底栏变化
function CodeGameScreenRoyaleBattleMachine:miniMachine_checkNotifyUpdateWinCoin(_winLines)
    if #_winLines < 1 then
        return
    end

    if #self.m_reelResultLines > 0 then
        return
    end

    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    local serverWinCoins = self.m_bProduceSlots_InFreeSpin and self.m_runSpinResultData.p_fsWinCoins or self.m_serverWinCoins
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    --
    local curWinCoin = self:bottomUi_getCurWinCoins()
    self:bottomUi_upDateWinCoin(curWinCoin, serverWinCoins, isNotifyUpdateTop)
end

--[[
    @desc: 底栏接口
]]
function CodeGameScreenRoyaleBattleMachine:bottomUi_upDateWinCoin(_begin, _end, _isNotifyUpdateTop, isPlayAnim)
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    local params = {
        [1] = _end,
        [2] = _isNotifyUpdateTop,
        [3] = isPlayAnim,
        [4] = _begin
    }
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    globalData.slotRunData.lastWinCoin = lastWinCoin
end
function CodeGameScreenRoyaleBattleMachine:bottomUi_getCurWinCoins()
    local labelStr = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == labelStr then
        return 0
    end

    local numList = util_string_split(labelStr, ",")
    local numStr = ""
    for i, v in ipairs(numList) do
        numStr = numStr .. v
    end
    local winCoin = tonumber(numStr)

    return winCoin
end
--首次进入时 修改盘面
function CodeGameScreenRoyaleBattleMachine:isFirstEnter()
    local keyStr = string.format("%s_RoyaleBattleFirst", globalData.userRunData.userUdid)
    local flagStr = gLobalDataManager:getStringByField(keyStr, "0")

    return flagStr == "0"
end
function CodeGameScreenRoyaleBattleMachine:saveFirstEnterFlag(_reelIndex)
    self.m_firstEnterFlag[_reelIndex] = 1
    for _reelIndex, _flag in pairs(self.m_firstEnterFlag) do
        if 1 ~= _flag then
            return
        end
    end

    --所有棋盘都初始化了 存一下key
    local keyStr = string.format("%s_RoyaleBattleFirst", globalData.userRunData.userUdid)
    local flagStr = "1"
    gLobalDataManager:setStringByField(keyStr, flagStr, true)
end
function CodeGameScreenRoyaleBattleMachine:getFirstEnterReelSymbol(_reelIndex)
    local symbolList = {
        [1] = {
            {20, 20, 90},
            {40, 40, 40},
            {10, 10, 90},
            {50, 50, 50},
            {30, 30, 90}
        },
        [2] = {
            {190, 21, 21},
            {50, 50, 50},
            {190, 11, 11},
            {40, 40, 40},
            {190, 31, 31}
        }
    }

    return symbolList[_reelIndex]
end
--------------一些特殊需求重写父类接口
-- 解决Scatter小块上面附加的spine节点问题
-- 根据类型获取对应节点
--
function CodeGameScreenRoyaleBattleMachine:getSlotNodeBySymbolType(symbolType)
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
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    --!!!插入修改
    self:addScatterSpineNode(reelNode)

    return reelNode
end
function CodeGameScreenRoyaleBattleMachine:pushAnimNodeToPool(animNode, symbolType)
    self:removeScatterSpineNode(animNode)
    CodeGameScreenRoyaleBattleMachine.super.pushAnimNodeToPool(self, animNode, symbolType)
end
function CodeGameScreenRoyaleBattleMachine:getAnimNodeFromPool(symbolType, ccbName)
    local node = CodeGameScreenRoyaleBattleMachine.super.getAnimNodeFromPool(self, symbolType, ccbName)
    self:removeScatterSpineNode(node)

    return node
end

-- 解决锁定玩法的播放时机
-- 根据枚举的内容播放效果
--
function CodeGameScreenRoyaleBattleMachine:playGameEffect()
    local isGamePause = self:checkGameResumeCallFun()
    if isGamePause == false then
        return
    end

    local isRunning = self:checkOperaGameEffects()

    if isRunning == false then
        self:operaEffectOver()
    end
end
-- 解决落地动画
function CodeGameScreenRoyaleBattleMachine:playCustomSpecialSymbolDownAct(slotNode)
    CodeGameScreenRoyaleBattleMachine.super.playCustomSpecialSymbolDownAct(self, slotNode)

    if slotNode.p_symbolType and self:isRoyaleBattleScatter(slotNode.p_symbolType) then
        local soundPath = "RoyaleBattleSounds/sound_RoyaleBattle_Scatter_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds(reelCol, soundPath)
        else
            gLobalSoundManager:playSound(soundPath)
        end

        self:addScatterSpineNode(slotNode)

        local scatterOrder = self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex
        local slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, -scatterOrder)
        self:playRoyaleBattleScatterAnim(
            slotNode,
            "buling",
            false,
            40 / 60,
            function()
                self:playRoyaleBattleScatterAnim(slotNode, "idleframe")
            end
        )
    end
end

-- 解决开始滚动时 赢钱展示被移除问题
--beginReel时尝试修改层级
function CodeGameScreenRoyaleBattleMachine:checkChangeBaseParent()
    -- 处理特殊信号
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if childs[i].resetReelStatus ~= nil then
            --!!!修改此处
            -- childs[i]:resetReelStatus()
            self:resetReelStatus(childs[i])
        end
        if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            --将该节点放在 .m_clipParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(), childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            if not childs[i].p_showOrder then
                childs[i].p_showOrder = self:getBounsScatterDataZorder(childs[i].p_symbolType)
            end
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            self:changeBaseParent(childs[i])
            childs[i]:setPosition(pos)
            --!!!修改此处
            -- childs[i]:resetReelStatus()
            self:resetReelStatus(childs[i])
        end
    end
end
-- 解决开始滚动时 挂点被移除
-- 节点类的接口重写下
function CodeGameScreenRoyaleBattleMachine:resetReelStatus(symbolNode)
    if symbolNode.p_symbolImage ~= nil and symbolNode.m_imageName ~= nil then
        symbolNode.p_symbolImage:setVisible(true)
        symbolNode:hideBigSymbolClip()

        --!!!修改此处新增判断
        local spineParent = symbolNode:getCcbProperty("Node_spine")
        if spineParent and nil ~= spineParent:getChildByName("scatterSpine") then
            return
        end

        symbolNode:removeAndPushCcbToPool()
    end
end

--解决快滚上下交替展示
--设置bonus scatter 信息 @_target 对象:小轮盘也调这个接口
function CodeGameScreenRoyaleBattleMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong, _target)
    --!!!
    local reelIndex = not _target and 1 or 2
    _target = _target or self
    --

    local reelRunData = _target.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    --!!!修改此处
    local symbolCheckList = {}
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = _target.m_ScatterShowCol
        symbolCheckList = {
            [self.SYMBOL_SCORE_UP_SCATTER] = 1,
            [self.SYMBOL_SCORE_DOWN_SCATTER] = 1
        }
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    end
    --!!! 上轮盘scatter计数 需要拆分下轮盘上列计数检测两次
    local lastDownReelCount = 0
    if 1 == reelIndex and column > 1 then
        local lastCol = column - 1
        local columnData = _target.m_reelColDatas[lastCol]
        for row = 1, columnData.p_showGridCount do
            local symbolType_down = self.m_DownReels:getSymbolTypeForNetData(lastCol, row, runLen)
            if nil ~= symbolCheckList[symbolType_down] then
                lastDownReelCount = lastDownReelCount + 1
            end
        end
    end
    --!!! 下轮盘下列scatter计数 需要添加上轮盘下列的scatter数量
    local nextUpReelCount = 0
    if 2 == reelIndex and column < _target.m_iReelColumnNum then
        local nextCol = column + 1
        local columnData = _target.m_reelColDatas[nextCol]
        for row = 1, columnData.p_showGridCount do
            local symbolType_up = self:getSymbolTypeForNetData(nextCol, row, runLen)
            if nil ~= symbolCheckList[symbolType_up] then
                nextUpReelCount = nextUpReelCount + 1
            end
        end
    end

    --!!!上棋盘检测下列快滚时不使用下棋盘scatter的数量
    if 1 == reelIndex then
        --!!!下棋盘检测下列快滚时需要添加 上棋盘下列scatter数量
        --分开检测数量
        soundType, nextReelLong = _target:getRunStatus(column, allSpecicalSymbolNum, showCol)
        if not nextReelLong and column > 1 then
            soundType, nextReelLong = _target:getRunStatus(column, allSpecicalSymbolNum - lastDownReelCount, showCol)
        end
    else
        --分开检测数量
        soundType, nextReelLong = _target:getRunStatus(column, allSpecicalSymbolNum, showCol)
        if not nextReelLong then
            soundType, nextReelLong = _target:getRunStatus(column, allSpecicalSymbolNum + nextUpReelCount, showCol)
        end
    end

    local columnData = _target.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount
    --!!!当前列下棋盘的数量
    local curColDownSymbolNum = 0
    for row = 1, iRow do
        local symbolType_up = self:getSymbolTypeForNetData(column, row, runLen)
        local symbolType_down = self.m_DownReels:getSymbolTypeForNetData(column, row, runLen)
        if nil ~= symbolCheckList[symbolType_up] or nil ~= symbolCheckList[symbolType_down] then
            local bPlaySymbolAnima = bPlayAni
            --!!!
            local addValue = 1
            if nil ~= symbolCheckList[symbolType_up] and nil ~= symbolCheckList[symbolType_down] then
                addValue = 2
            end
            if nil ~= symbolCheckList[symbolType_down] then
                curColDownSymbolNum = curColDownSymbolNum + 1
            end
            allSpecicalSymbolNum = allSpecicalSymbolNum + addValue

            if bRun == true then
                --!!!上棋盘检测下列快滚时不使用下棋盘scatter的数量
                if 1 == reelIndex then
                    --!!!下棋盘检测下列快滚时需要添加 上棋盘下列scatter数量
                    soundType, nextReelLong = _target:getRunStatus(column, allSpecicalSymbolNum, showCol)
                    if not nextReelLong and column > 1 then
                        soundType, nextReelLong = _target:getRunStatus(column, allSpecicalSymbolNum - curColDownSymbolNum, showCol)
                    end
                else
                    soundType, nextReelLong = _target:getRunStatus(column, allSpecicalSymbolNum, showCol)
                    if not nextReelLong then
                        soundType, nextReelLong = _target:getRunStatus(column, allSpecicalSymbolNum + nextUpReelCount, showCol)
                    end
                end

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
    --!!! FG不会再次快滚
    if not self.m_bProduceSlots_InFreeSpin and bRun == true and nextReelLong == true and bRunLong == false and _target:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return allSpecicalSymbolNum, bRunLong
end
-- 解决快滚时上下棋盘交替滚动
function CodeGameScreenRoyaleBattleMachine:getLongRunLen(col, index, _target)
    --!!!
    local reelIndex = not _target and 1 or 2
    local target = _target or self
    local firstCol, quickReelIndex = self:getRoyaleBattleFirstQuickRunCol()
    --
    local len = 0
    local scatterShowCol = target.m_ScatterShowCol
    local lastColLens = target.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = target.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if scatterShowCol ~= nil then
        if target:getInScatterShowCol(col) then
            --速度x时间 / 列高
            local reelCount = (target.m_configData.p_reelLongRunTime * target.m_configData.p_reelLongRunSpeed) / colHeight
            --!!!
            local offsetValue = math.floor(reelCount) * columnData.p_showGridCount
            local addValue = 2 * offsetValue

            if 1 == reelIndex then
                if 1 == quickReelIndex and col == firstCol then
                    addValue = offsetValue
                end
            elseif 2 == reelIndex then
                lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen() + offsetValue

                if col == firstCol then
                    addValue = 1 == quickReelIndex and offsetValue or 0
                end
            end

            len = lastColLens + addValue
        else
            -- elseif col > scatterShowCol[#scatterShowCol] then
            local reelRunData = target.m_reelRunInfo[col - 1]
            local diffLen = target.m_reelRunInfo[2]:getReelRunLen() - target.m_reelRunInfo[1]:getReelRunLen()
            local lastRunLen = reelRunData:getReelRunLen()
            len = lastRunLen + diffLen
            target.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end
    if len == 0 then
        local reelCount = (target.m_configData.p_reelLongRunTime * target.m_configData.p_reelLongRunSpeed) / colHeight
        len = lastColLens + math.floor(reelCount) * columnData.p_showGridCount --速度x时间 / 列高
    end
    return len
end
-- 解决快滚时上下棋盘交替滚动
function CodeGameScreenRoyaleBattleMachine:creatReelRunAnimation(col, _target)
    --!!!
    local reelIndex = not _target and 1 or 2
    local target = _target or self
    local firstCol, quickReelIndex = self:getRoyaleBattleFirstQuickRunCol()
    --

    local delayTime = 0
    --普通滚动的间隔
    local reelRunLen = self.m_configData.p_reelRunDatas[2] - self.m_configData.p_reelRunDatas[1]
    local upReelRunTime = reelRunLen * self.m_SlotNodeH / self.m_configData.p_reelMoveSpeed

    if 1 == reelIndex then
        if 2 == quickReelIndex then
            delayTime = target.m_configData.p_reelLongRunTime - upReelRunTime
        else
            delayTime = firstCol == col and 0 or target.m_configData.p_reelLongRunTime
        end
    else
        if 2 == quickReelIndex then
            if firstCol == col then
                delayTime = upReelRunTime
            else
                delayTime = target.m_configData.p_reelLongRunTime + upReelRunTime
            end
        else
            delayTime = target.m_configData.p_reelLongRunTime
        end
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            --由于列停止时 下列动效可能还没创建无法清理，只能在创建时检测如果快停则不允许创建
            if not target.m_isNewReelQuickStop then
                target.super.creatReelRunAnimation(target, col)
            end

            waitNode:removeFromParent()
        end,
        delayTime
    )
end
function CodeGameScreenRoyaleBattleMachine:getRoyaleBattleFirstQuickRunCol()
    local quickRunCol = 0
    local reelIndex = 1
    --
    local scatterNum = 0
    local scatterShowCol = {}
    for _index, _iCol in ipairs(self.m_ScatterShowCol) do
        scatterShowCol[_iCol] = 1
    end

    for _iCol = 1, self.m_iReelColumnNum do
        local reelRunData_up = self.m_reelRunInfo[_iCol]
        local runLen_up = reelRunData_up:getReelRunLen()

        local reelRunData_down = self.m_DownReels.m_reelRunInfo[_iCol]
        local runLen_down = reelRunData_up:getReelRunLen()

        local curNum_up = 0
        local curNum_down = 0
        for _iRow = 1, self.m_iReelRowNum do
            local symbolType_up = self:getSymbolTypeForNetData(_iCol, _iRow, runLen_up)
            if self:isRoyaleBattleScatter(symbolType_up) then
                curNum_up = curNum_up + 1
            end

            local symbolType_down = self.m_DownReels:getSymbolTypeForNetData(_iCol, _iRow, runLen_down)
            if self:isRoyaleBattleScatter(symbolType_down) then
                curNum_down = curNum_down + 1
            end
        end
        --
        scatterNum = scatterNum + curNum_up
        if scatterNum == self.m_longRunSCNum then
            _iCol = scatterShowCol[_iCol] and _iCol or _iCol + 1
            quickRunCol = _iCol
            reelIndex = 2
            return quickRunCol, reelIndex
        end

        scatterNum = scatterNum + curNum_down
        if scatterNum == self.m_longRunSCNum then
            _iCol = scatterShowCol[_iCol + 1] and _iCol + 1 or _iCol + 2
            quickRunCol = _iCol
            reelIndex = 1
            return quickRunCol, reelIndex
        end
    end

    return quickRunCol, reelIndex
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenRoyaleBattleMachine:getRunStatus(col, nodeNum, showCol, _target)
    local reelIndex = not _target and 1 or 2
    local target = _target or self

    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i = 1, target.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    if col <= showColTemp[self.m_longRunSCNum] then
        if nodeNum < self.m_longRunSCNum then
            return runStatus.DUANG, false
        else
            return runStatus.DUANG, true
        end
    else
        if nodeNum <= self.m_longRunSCNum then
            return runStatus.DUANG, false
        else
            return runStatus.DUANG, true
        end
    end
end

-- 中奖预告展示 , 锁定玩法
function CodeGameScreenRoyaleBattleMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    --添加标记
    local isTirigger = self:isTriggerMoveWild(true)
    local random_value = 1 --math.random(1, 2)
    self.m_isPlayWinningNotice = isTirigger and (1 == random_value)
    --其内含有快滚逻辑
    self:produceSlots()
    --

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    local delayTime = 0
    if isTirigger then
        local wildCount = self:getMoveWildCount()
        -- 总延迟时间 = 遮罩提前展示时间 + 所有小龙出现时间 + 落地动画 + 遮罩淡出时间
        delayTime = self.MOVE_WILD_PANEL_TIME + (wildCount - 1) * self.MOVE_WILD_INTERVAL + 60 / 30 + 0.5
    end

    if self.m_isPlayWinningNotice then
        self:playWinningNoticeAnim(
            function()
                self.m_isPlayWinningNotice = false
                self:playSpecialWildParticlePanel()

                local waitNode = cc.Node:create()
                self:addChild(waitNode)
                performWithDelay(
                    waitNode,
                    function()
                        self:netBackStopReel()

                        waitNode:removeFromParent()
                    end,
                    delayTime
                )
            end
        )
    else
        --触发了移动玩法 但没有中奖预告 延迟滚动时间
        if isTirigger then
            self:playSpecialWildParticlePanel()
        elseif self.m_bLockWildEffect then
            delayTime = 3
            self.m_DownReels:setWaitChangeReelTime(delayTime)
        end

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                self:netBackStopReel()

                waitNode:removeFromParent()
            end,
            delayTime
        )
    end
end

function CodeGameScreenRoyaleBattleMachine:netBackStopReel(_bool)
    local bool = _bool

    local data = self:BaseMania_getCollectData(1)
    if not self.m_bProduceSlots_InFreeSpin and data.p_collectLeftCount == data.p_collectTotalCount then
        self:playBatteryFight(
            function()
                self.m_isWaitingNetworkData = false
                self:operaNetWorkData()
                self.m_DownReels:updateNetWorkData(true)
            end
        )
    else
        -- self.m_DownReels:updateNetWorkData(bool)
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()
    end
end

-- 解决滚动时小块层级不对问题
-- 重写滚动刷帧
function CodeGameScreenRoyaleBattleMachine:reelSchedulerHanlder(dt)
    self:upDateRoyaleBattleRunOrder()

    CodeGameScreenRoyaleBattleMachine.super.reelSchedulerHanlder(self, dt)
end
function CodeGameScreenRoyaleBattleMachine:upDateRoyaleBattleRunOrder(_target)
    local reelIndex = _target and 2 or 1
    local target = _target or self
    --

    for _iCol = 1, target.m_iReelColumnNum do
        for _iRow = 1, target.m_iReelRowNum do
            local symbolNode = target:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
            if symbolNode then
                local order = self:getBounsScatterDataZorder(symbolNode.p_symbolType)
                order = order - _iRow
                symbolNode.m_showOrder = order
                symbolNode:setLocalZOrder(order)
            end
        end
    end
end
-- 解决新增的scatter信号层级问题
--设置bonus scatter 层级
function CodeGameScreenRoyaleBattleMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCORE_DOWN_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
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

-- 解决freeSpinMore 时停掉背景问题
-- 显示free spin
function CodeGameScreenRoyaleBattleMachine:showEffect_FreeSpin(effectData)
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

    --!!!
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
    end
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
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

function CodeGameScreenRoyaleBattleMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

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
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            self.MAINREEL_OFFSET_Y = 5
            --!!! 尺寸比标准尺寸小时，要求不能直接同步比例 适当调大一些缩放. 1024下缩放偏移为1.15
            local offsetScale = 0.95
            if display.sizeInPixels.height ~= display.height then
                offsetScale = 0.9
            elseif 1024 <= display.height then
                offsetScale = 0.8 + 0.15 * (1 - (display.height - 1024) / (DESIGN_SIZE.height - 1024))
            end

            offsetScale = math.min(offsetScale, 1 / mainScale)
            mainScale = mainScale * offsetScale

            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        elseif display.height == DESIGN_SIZE.height then
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end

        self:changeMainReelPos()

        local bangHeight = util_getBangScreenHeight()
        local bottomHeight = util_getSaveAreaBottomHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - bangHeight + bottomHeight)
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

function CodeGameScreenRoyaleBattleMachine:changeMainReelPos()
    local rootNode = self:findChild("root")
    local rootChildren = rootNode:getChildren()
    for _index, _child in ipairs(rootChildren) do
        local oldY = _child:getPositionY()
        _child:setPositionY(oldY + self.MAINREEL_OFFSET_Y)
    end
end

-- 解决连线时小块层级最高
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenRoyaleBattleMachine:playInLineNodes(_target)
    local target = _target or self
    local reelIndex = _target and 2 or 1
    --
    if target.m_lineSlotNodes == nil then
        return
    end
    --!!!
    -- self:reSetSymbolOrder(reelIndex)

    local animTime = 0
    for i = 1, #target.m_lineSlotNodes do
        local slotsNode = target.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            --!!!
            local order = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            order = order - slotsNode.p_rowIndex + 100 + SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
            slotsNode.m_showOrder = order
            slotsNode.p_showOrder = order

            slotsNode:setLocalZOrder(order)

            slotsNode:runLineAnim()
            if target.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if target.m_bGetSymbolTime == true then
        target.m_changeLineFrameTime = animTime
    end
end

-- 解决连线时小块层级最高
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenRoyaleBattleMachine:showLineFrameByIndex(winLines, frameIndex, _target)
    local target = _target or self
    local reelIndex = _target and 2 or 1
    --

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

        if target.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = target.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = target.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                target:pushFrameToPool(preNode)
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

        local columnData = target.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + target.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = target:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

        if node:getParent() == nil then
            if target.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                target.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
                target.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
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
    if target.m_eachLineSlotNode ~= nil then
        --!!!
        self:reSetSymbolOrder(reelIndex)

        local vecSlotNodes = target.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    --!!!
                    local order = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                    order = order - slotsNode.p_rowIndex + 100
                    slotsNode:setLocalZOrder(order)

                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

--进入关卡时没有玩法，首次轮盘初始化走配置
function CodeGameScreenRoyaleBattleMachine:initRandomSlotNodes(_target)
    local target = _target or self
    local reelIndex = _target and 2 or 1
    --

    if target.m_currentReelStripData == nil then
        target:randomSlotNodes()
    else
        target:randomSlotNodesByReel()
    end

    --!!!
    local isFirst = self:isFirstEnter()
    if isFirst then
        self:initFirstEnterReel(target, reelIndex)
    end
end

function CodeGameScreenRoyaleBattleMachine:initFirstEnterReel(_target, _reelIndex)
    local symbolList = self:getFirstEnterReelSymbol(_reelIndex)
    for iCol = 1, _target.m_iReelColumnNum do
        for iRow = _target.m_iReelRowNum, 1, -1 do
            local symbol = _target:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbol then
                local symbolType = symbolList[iCol][iRow]
                local ccbName = self:getSymbolCCBNameByType(self, symbolType)
                symbol:changeCCBByName(ccbName, symbolType)
                symbol:changeSymbolImageByName(ccbName)
                symbol:resetReelStatus()
                --
                local order = self:getBounsScatterDataZorder(symbolType)

                if 1 == _reelIndex and self:isRoyaleBattleScatter(symbolType) then
                    util_setSymbolToClipReel(_target, iCol, iRow, symbolType, order)
                else
                    order = order - iRow
                    symbol.p_showOrder = order
                    symbol:setLocalZOrder(order)
                end
            end
        end
    end
    self:reSetSymbolOrder(_reelIndex)
    self:saveFirstEnterFlag(_reelIndex)
end

function CodeGameScreenRoyaleBattleMachine:updateSpinTimeBar(_curr)
    --切换bet时直接把文本内 str -> int 存储
    self.m_spinTimeBar:findChild("m_lb_num_1"):setString(_curr)
    self.m_spinTimeBar:findChild("m_lb_num_2"):setString(self.m_totalSpinTimes)

    --不是需要调整缩放的数字时 先停止所有动作再恢复缩放
    if not self.m_spineTimesScale[_curr] then
        local leftLabel = self.m_spinTimeBar:findChild("m_lb_num_1")
        leftLabel:stopAllActions()
        leftLabel:setScale(0.57)
    end
end

function CodeGameScreenRoyaleBattleMachine:updateTopSCNumBar(_curr)
    self.m_topSCNumBar:findChild("m_lb_num_1"):setString(_curr)
end

function CodeGameScreenRoyaleBattleMachine:updateDownSCNumBar(_curr)
    self.m_downSCNumBar:findChild("m_lb_num_1"):setString(_curr)
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenRoyaleBattleMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- 更新收集金币
    local collectNetData = self.m_runSpinResultData.p_collectNetData[1]
    if collectNetData then
        self.m_collectDataList[1].p_collectLeftCount = collectNetData.collectLeftCount
        self.m_collectDataList[1].p_collectCoinsPool = collectNetData.collectCoinsPool
        self.m_collectDataList[1].p_collectTotalCount = collectNetData.collectTotalCount

        local leftTimes = 0
        --spin返回时如果是最后一次 展示 10:10
        if collectNetData.collectLeftCount == collectNetData.collectTotalCount then
            leftTimes = collectNetData.collectLeftCount
        else
            leftTimes = collectNetData.collectTotalCount - collectNetData.collectLeftCount
        end

        local betData = {
            leftTimes = leftTimes
        }
        self:saveOneBetSpinTimes(globalData.slotRunData:getCurTotalBet(), betData)

        self:updateSpinTimeBar(leftTimes)
    end
end
-- 进入关卡时初始化每个bet的spin次数
function CodeGameScreenRoyaleBattleMachine:initSpinTimesBet(_data)
    --[[
        _data = {
            "3000" = {      
                leftTimes  = 0,
                topCount   = 0,
                downCount  = 0,
            }
        }
    ]]
    self.m_spinTimesBet = _data
end
function CodeGameScreenRoyaleBattleMachine:saveOneBetSpinTimes(_bet, _data)
    local betStr = string.format("%d", _bet)
    if not self.m_spinTimesBet[betStr] then
        self.m_spinTimesBet[betStr] = {}
    end
    --只修改传入数据不覆盖
    for k, v in pairs(_data) do
        self.m_spinTimesBet[betStr][k] = v
    end
end
function CodeGameScreenRoyaleBattleMachine:getBetSpinTimesData(_bet)
    return self.m_spinTimesBet[string.format("%d", _bet)]
end
--进入关卡或切换bet时刷新spin次数
function CodeGameScreenRoyaleBattleMachine:betChangeUpDateSpinTimes(_newBet, _delayTime)
    local leftTimes = 0
    local topCount = 0
    local downCount = 0
    local newBetData = self.m_spinTimesBet[string.format("%d", _newBet)]
    if nil ~= newBetData then
        leftTimes = newBetData.leftTimes or 0
        topCount = newBetData.topCount or 0
        downCount = newBetData.downCount or 0
    end

    -- print(string.format("[betChangeUpDateSpinTimes] leftTimes=(%d) topCount=(%d) downCount=(%d)",leftTimes,topCount,downCount))
    self:updateSpinTimeBar(leftTimes)
    --第十次 上下炮弹数量等开火后由其他接口修改
    if leftTimes ~= self.m_totalSpinTimes then
        self.m_collectDataList[1].p_collectLeftCount = self.m_totalSpinTimes - leftTimes

        self:updateTopSCNumBar(topCount)
        self:updateDownSCNumBar(downCount)
    end
    --根据数量刷新 弹弓状态
    _delayTime = _delayTime or 0
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            local actName = topCount > 0 and "idleframe" or "idleframe2"
            util_spinePlay(self.m_topBattery, actName)

            waitNode:removeFromParent()
        end,
        _delayTime
    )

    -- actName = downCount > 0 and "actionframe2" or "idleframe"
    -- util_spinePlay(self.m_downBattery, actName)
end

--第一次进入本关卡初始化本关收集数据 如果数据格式不同子类重写这个方法
function CodeGameScreenRoyaleBattleMachine:BaseMania_initCollectDataList()
    --收集数组
    self.m_collectDataList = {}
    --默认总数
    local pools = {10}
    for i = 1, 1 do
        self.m_collectDataList[i] = CollectData.new()
        self.m_collectDataList[i].p_collectTotalCount = pools[i]
        self.m_collectDataList[i].p_collectLeftCount = pools[i]
        self.m_collectDataList[i].p_collectCoinsPool = 0
        self.m_collectDataList[i].p_collectChangeCount = 0
    end
end

function CodeGameScreenRoyaleBattleMachine:playBatteryFight(_func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local featureWild = selfdata.featureWild or {{}, {}}
    local topWildList = featureWild[1] or {}
    local downWildList = featureWild[2] or {}
    local battleCount = selfdata.battleCount or {}
    --修改炮弹累积数量
    local betData = {
        topCount = battleCount[1] or 0,
        downCount = battleCount[2] or 0
    }
    self:saveOneBetSpinTimes(globalData.slotRunData:getCurTotalBet(), betData)
    local topBatteryWaitTime = 0
    local downBatteryWaitTime = 0

    local topFirWaitTime = 0.2
    local topFirTotalTime = 0

    local downFirWaitTime = 0.2
    local downFirTotalTime = 0

    -- 转向音效 + 随机开火音效
    local fireSound = {
        "RoyaleBattleSounds/sound_RoyaleBattle_Scatter_fire_%d.mp3",
        "RoyaleBattleSounds/sound_RoyaleBattle_fs_start_%d.mp3"
    }
    local fireName = fireSound[math.random(1, #fireSound)]
    local soundName = ""

    if #downWildList > 0 then
        util_spinePlay(self.m_topBattery, "actionframe1")

        soundName = string.format(fireName, 1)
        gLobalSoundManager:playSound(soundName)

        local startWorldPos = self.m_topBattery:getParent():convertToWorldSpace(cc.p(self.m_topBattery:getPosition()))
        topBatteryWaitTime = 25 / 30 + 25 / 30
        local index = 1
        for key, posIndex in ipairs(downWildList) do
            local wildList = {}
            wildList[key] = posIndex
            local endWorldPos = self.m_DownReels.m_clipParent:convertToWorldSpace(cc.p(util_getOneGameReelsTarSpPos(self.m_DownReels, posIndex)))

            local _, aniNode = self:playLockWildBallisticAnim(startWorldPos, endWorldPos, 1, (index - 1) * topFirWaitTime, 25)

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(
                waitNode,
                function()
                    gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_Scatter_rotation_up.mp3")
                    waitNode:removeFromParent()
                end,
                (index - 1) * topFirWaitTime
            )

            self:playLockWildTuowei(
                startWorldPos,
                endWorldPos,
                1,
                true,
                30 / 60,
                function()
                    if aniNode then
                        aniNode:setVisible(false)
                    end
                    self:changeTopDownReelSymbol(nil, wildList, true)
                end,
                25 / 30 + (index - 1) * topFirWaitTime
            )

            index = index + 1
        end
        topFirTotalTime = table_length(downWildList) * topFirWaitTime
        topBatteryWaitTime = topBatteryWaitTime + topFirTotalTime
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            if #battleCount == 2 then
                self:updateTopSCNumBar(battleCount[1])
            end

            if #topWildList > 0 then
                util_spinePlay(self.m_downBattery, "start")
                downBatteryWaitTime = 0.5
            end
            performWithDelay(
                waitNode,
                function()
                    if #topWildList > 0 then
                        local startWorldPos = self.m_downBattery:getParent():convertToWorldSpace(cc.p(self.m_downBattery:getPosition()))

                        downBatteryWaitTime = 25 / 30 + 25 / 30
                        local index = 1
                        local isPlayFireSound = false
                        for key, posIndex in ipairs(topWildList) do
                            local endWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(util_getOneGameReelsTarSpPos(self, posIndex)))
                            local wildList = {}
                            wildList[key] = posIndex
                            performWithDelay(
                                self,
                                function()
                                    local wildList_1 = wildList
                                    local _, aniNode = self:playLockWildBallisticAnim(startWorldPos, endWorldPos, 2, nil, 25)

                                    performWithDelay(
                                        self,
                                        function()
                                            util_spinePlay(self.m_downBattery, "actionframe")
                                            gLobalSoundManager:playSound("RoyaleBattleSounds/sound_RoyaleBattle_Scatter_rotation_down.mp3")
                                            if not isPlayFireSound then
                                                isPlayFireSound = true
                                                soundName = string.format(fireName, 2)
                                                gLobalSoundManager:playSound(soundName)
                                            end
                                        end,
                                        25 / 30
                                    )

                                    self:playLockWildTuowei(
                                        startWorldPos,
                                        endWorldPos,
                                        2,
                                        true,
                                        30 / 60,
                                        function()
                                            if aniNode then
                                                aniNode:setVisible(false)
                                            end
                                            self:changeTopDownReelSymbol(wildList_1, nil, true)
                                        end,
                                        25 / 30
                                    )
                                end,
                                (index - 1) * downFirWaitTime
                            )
                            index = index + 1
                        end

                        downFirTotalTime = table_length(topWildList) * downFirWaitTime
                        downBatteryWaitTime = downBatteryWaitTime + downFirTotalTime
                    end

                    performWithDelay(
                        waitNode,
                        function()
                            if #battleCount == 2 then
                                self:updateDownSCNumBar(battleCount[2])
                            end

                            if #topWildList > 0 then
                                util_spinePlay(self.m_downBattery, "over")
                            end

                            performWithDelay(
                                self,
                                function()
                                    -- if #downWildList then
                                    util_spinePlay(self.m_topBattery, "idleframe2")
                                    -- end

                                    if _func then
                                        _func()
                                    end

                                    waitNode:removeFromParent()
                                end,
                                0.5
                            )
                        end,
                        downBatteryWaitTime
                    )
                end,
                downBatteryWaitTime
            )
        end,
        topBatteryWaitTime
    )
end

function CodeGameScreenRoyaleBattleMachine:getFeatureWildCount(_reelIndex, _index)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local featureWildCount = selfdata.featureWildCount or {{}, {}}
    local reelData = featureWildCount[_reelIndex]

    for k, v in pairs(reelData) do
        if tonumber(k) == _index then
            return tonumber(v)
        end
    end
end

function CodeGameScreenRoyaleBattleMachine:changeOneSymbolCCb(_mainClass, _index, _reelIndex)
    local fixPos = _mainClass:getRowAndColByPos(_index)
    local symbolNode = _mainClass:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
    if symbolNode then
        local symbolType = self.SYMBOL_SCORE_LOCK_WILD
        local ccbName = self:getSymbolCCBNameByType(self, symbolType)
        symbolNode:changeCCBByName(ccbName, symbolType)
        symbolNode:changeSymbolImageByName(ccbName)
        local count = self:getFeatureWildCount(_reelIndex, _index)
        if count then
            if count > 1 then
                symbolNode:setLineAnimName("actionframe2X2")
                symbolNode:setIdleAnimName("idleframe4")
            else
                symbolNode:setLineAnimName("actionframe2")
                symbolNode:setIdleAnimName("idleframe3")
            end
        end
        symbolNode:runIdleAnim()
    end
end

function CodeGameScreenRoyaleBattleMachine:createOneLockWildSymbol(_mainClass, _index, _reelIndex)
    local fixPos = _mainClass:getRowAndColByPos(_index)
    local symbolType = self.SYMBOL_SCORE_LOCK_WILD
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    local wildNode = util_spineCreate(ccbName, true, true)
    if wildNode then
        _mainClass.m_lockNode:addChild(wildNode)
        wildNode:setPosition(util_getOneGameReelsTarSpPos(_mainClass, _index))
        local count = self:getFeatureWildCount(_reelIndex, _index)
        if count then
            if count > 1 then
                util_spinePlay(wildNode, "idleframe4")
            else
                util_spinePlay(wildNode, "idleframe3")
            end
        end
    end
end

function CodeGameScreenRoyaleBattleMachine:changeTopDownReelSymbol(_topList, _downList, _isCreate)
    if _topList then
        for k, v in pairs(_topList) do
            local posIndex = v
            if _isCreate then
                self:createOneLockWildSymbol(self, posIndex, 1)
            else
                self:changeOneSymbolCCb(self, posIndex, 1)
            end
        end
    end

    if _downList then
        for k, v in pairs(_downList) do
            local posIndex = v
            if _isCreate then
                self:createOneLockWildSymbol(self.m_DownReels, posIndex, 2)
            else
                self:changeOneSymbolCCb(self.m_DownReels, posIndex, 2)
            end
        end
    end
end

function CodeGameScreenRoyaleBattleMachine:checkShowGameStartView()
    local features = self.m_runSpinResultData.p_features or {}

    if self:getCurrSpinMode() == FREE_SPIN_MODE or #features >= 2 then
        return
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    local view =
        self:showDialog(
        "GameStart",
        {},
        function()
            if waitNode then
                waitNode:stopAllActions()
                waitNode:removeFromParent()
                waitNode = nil
            end
        end
    )
    performWithDelay(
        waitNode,
        function()
            view:showOver()

            if waitNode then
                waitNode:removeFromParent()
                waitNode = nil
            end
        end,
        2.5
    )
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenRoyaleBattleMachine:checkUpdateReelDatas(_parentData, _mainClass)
    local reelDatas = nil
    local mainClass = _mainClass or self

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = mainClass.m_configData:getFsReelDatasByColumnIndex(mainClass.m_fsReelDataIndex, _parentData.cloumnIndex)
    else
        local data = self:BaseMania_getCollectData(1)
        if 1 == data.p_collectLeftCount then
            -- if data.p_collectLeftCount == (data.p_collectTotalCount - 1) then
            reelDatas = mainClass.m_configData:getFsReelDatasByColumnIndex(1, _parentData.cloumnIndex)
        else
            reelDatas = mainClass.m_configData:getNormalReelDatasByColumnIndex(_parentData.cloumnIndex)
        end
    end

    _parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if _parentData.beginReelIndex == nil then
        _parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

return CodeGameScreenRoyaleBattleMachine
