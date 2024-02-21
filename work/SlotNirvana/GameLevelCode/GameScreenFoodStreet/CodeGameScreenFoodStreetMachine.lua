---
-- island li
-- 2019年1月26日
-- CodeGameScreenFoodStreetMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenFoodStreetMachine = class("CodeGameScreenFoodStreetMachine", BaseNewReelMachine)

CodeGameScreenFoodStreetMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenFoodStreetMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型

CodeGameScreenFoodStreetMachine.SYMBOL_COLLECT = 100 --高bet玩法的收集小块

CodeGameScreenFoodStreetMachine.BONUS_FS_WILD_LOCK_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenFoodStreetMachine.CTCOLLECT_OVER_EFFECTCT = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenFoodStreetMachine.COLLECT_SYMBOL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 自定义动画的标识
CodeGameScreenFoodStreetMachine.COLLECT_LEFT_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1 -- 自定义动画的标识

-- 专门用于商店引导的状态
CodeGameScreenFoodStreetMachine.m_pandaBoard = "pandaBoard"
CodeGameScreenFoodStreetMachine.m_pandaHouse = "pandaHouse"
CodeGameScreenFoodStreetMachine.m_pandaBaoZi = "pandaBaoZi"

CodeGameScreenFoodStreetMachine.m_bugDogStates = "bugDogStates"

-- 构造函数
function CodeGameScreenFoodStreetMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_spinRestMusicBG = true
    --固定wild
    self.m_oldlockWildList = {}
    --累计购买狗的次数
    self.m_buyDogs = 0
    self.m_wheelCoins = nil -- 收集商店的圆盘赢钱
    self.m_betLevel = nil
    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

function CodeGameScreenFoodStreetMachine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenFoodStreetMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FoodStreetConfig.csv", "LevelFoodStreetConfig.lua")
    self.m_isShowLeftTip = false --收集剩余提示面板的显示类型  false 当前收集任务未显示 true 已经显示
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFoodStreetMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FoodStreet"
end

function CodeGameScreenFoodStreetMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_FoodStreetView = util_createView("CodeFoodStreetSrc.FoodStreetView")
    -- self:findChild("xxxx"):addChild(self.m_FoodStreetView)

    self.m_nodeProgress = util_createView("CodeFoodStreetSrc.FoodStreetProgress")
    self:findChild("jindutiao"):addChild(self.m_nodeProgress)

    self.m_unlock = util_createAnimation("FoodStreet_unlock.csb")
    self:findChild("unlockNode"):addChild(self.m_unlock, 100)
    local touch = self.m_unlock:findChild("Panel_1")
    if touch then
        self:addClick(touch)
    end

    self.m_nodeCollect = util_createView("CodeFoodStreetSrc.FoodStreetCollect")
    self:findChild("collect"):addChild(self.m_nodeCollect)

    self.m_nodeIcon = util_createView("CodeFoodStreetSrc.FoodStreetIcon")
    self:findChild("touxiang"):addChild(self.m_nodeIcon)

    self.m_nodeSpinNum = util_createView("CodeFoodStreetSrc.FoodStreetSpinNum")
    self:findChild("spinsleft"):addChild(self.m_nodeSpinNum)

    self.m_nodeDog = util_createView("CodeFoodStreetSrc.FoodStreetDog")
    self:findChild("gou"):addChild(self.m_nodeDog)
    self:findChild("FoodStreet_spinsleft2_1"):setVisible(false)
    -- self.m_nodeDog = self:findChild("gou")

    self.m_protectBtn = self:findChild("Button_protect")
    self.m_protectBtn:setVisible(false)

    self.m_nodeTarget = util_createView("CodeFoodStreetSrc.FoodStreetTarget")
    self:findChild("zhujiemianjianzhu"):addChild(self.m_nodeTarget)

    self.m_mapLayer = util_createView("CodeFoodStreetSrc.FoodStreetMapLayer", {machine = self})
    self:addChild(self.m_mapLayer, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
    self.m_mapLayer:setVisible(false)

    local logo, act = util_csbCreate("FoodStreet_logo.csb")
    self:findChild("logo"):addChild(logo)
    util_csbPlayForKey(act, "zhongjiang", true)

    self:runCsbAction("idle1")
    self:findChild("Button_protect"):setVisible(false)

    self.m_GuoChang = util_createAnimation("FoodStreet_guochang.csb")
    self:addChild(self.m_GuoChang, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_GuoChang:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_GuoChang:setVisible(false)

    self.m_gameBg:runCsbAction("idle1", true)

    self.m_normalSpinBg = self:findChild("normal_bg")
    self.m_freeSpinBg = self:findChild("fs_bg")

    self.m_normalSpinBg:setVisible(true)
    self.m_freeSpinBg:setVisible(false)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
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

            local soundTime = soundIndex
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = "FoodStreetSounds/sound_FoodStreet_last_win_" .. soundIndex .. ".mp3"

            self.m_winSoundsId, self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenFoodStreetMachine:initFreeSpinBar()
    local node_bar = self:findChild("tishikuang")
    self.m_baseFreeSpinBar = util_createView("CodeFoodStreetSrc.FoodStreetFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
end

function CodeGameScreenFoodStreetMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_1" then
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
        self:showMapLayer(false, false)
    elseif name == "Button_protect" then
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
        self:showBuyDogViewTip()
    elseif name == "Panel_1" then
        --高bet autospin 触发freespin时 都不能点击
        if self:getBetLevel() == 1 or self:getCurrSpinMode() == AUTO_SPIN_MODE or self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            return
        end
        self:openLock()
    end
end

--开锁
function CodeGameScreenFoodStreetMachine:openLock()
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end
    -- 设置bet index
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenFoodStreetMachine:upateBetLevel()
    local minBet = self:getMinBet()

    self:updateHighLowBetLock(minBet)
end

function CodeGameScreenFoodStreetMachine:getMinBet()
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

function CodeGameScreenFoodStreetMachine:updateHighLowBetLock(minBet)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_clickBet = true
            self.m_betLevel = 1
            local particle = self.m_unlock:findChild("Particle_1")
            particle:resetSystem()
            self:findChild("protectNode"):setVisible(true)
            gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_open_lock.mp3")
            self.m_unlock:runCsbAction(
                "unlock",
                false,
                function()
                    if self.m_clickBet then
                        self.m_unlock:setVisible(false)
                    end
                end
            )
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_clickBet = false
            self.m_unlock:setVisible(true)
            self:findChild("protectNode"):setVisible(false)
            self.m_unlock:runCsbAction(
                "lock",
                false,
                function()
                    if not self.m_clickBet then
                        self.m_unlock:runCsbAction("idle2", true)
                    end
                end
            )
            self.m_betLevel = 0
        end
    end
end

function CodeGameScreenFoodStreetMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            self:playEnterGameSound("FoodStreetSounds/sound_FoodStreet_enter_game.mp3")
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenFoodStreetMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self.m_mapLayer:initMapUI(self.m_mapInfoData, self.m_mapProgress)
    if self.m_mapProgress == nil then
        self.m_nodeProgress:initProgress(0)
        self:showMapLayer(self.m_bSaleFlag, self.m_mapProgress == nil)
    else
        self:updateTopUI()
    end

    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_selfMakeData.wildPositions ~= nil then
            self:initFsLockWild(self.m_runSpinResultData.p_selfMakeData.wildPositions)
        end
    end
    self:upateBetLevel()
end

function CodeGameScreenFoodStreetMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            self:updateMapBtnEnable(params)
        end,
        "BET_ENABLE"
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upateBetLevel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenFoodStreetMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenFoodStreetMachine:updateMapBtnEnable(flag)
    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
        flag = false
    end
    if globalData.slotRunData.m_isAutoSpinAction then
        flag = false
    end
    local btn = self:findChild("Button_1")
    btn:setEnabled(flag)
    self.m_protectBtn:setEnabled(flag)
end

function CodeGameScreenFoodStreetMachine:showMapLayer(canSell, canChoose)
    self.m_mapLayer:setVisible(true)
    self:setMaxMusicBGVolume()
    self.m_currentMusicBgName = "FoodStreetSounds/music_FoodStreet_map_bgm.mp3"
    gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
    local showDog = self:isBuyDogOrCollect()
    self.m_mapLayer:showMap(
        canSell,
        canChoose,
        showDog,
        function()
            self:normalBgmControl()
        end
    )

    self.m_mapLayer:showTitle(self.m_mapProgress == nil)
end

function CodeGameScreenFoodStreetMachine:updateTopUI()
    self.m_nodeProgress:initProgress(self:getCollectProgress())
    if self.m_collectType ~= nil then
        self.m_nodeIcon:updateIcon(self.m_collectType)
    end

    --正在收集看门狗
    if self.m_mapInfoData[1].status == "PROGRESS" then
        --已经买了看门狗
        self.m_nodeDog:setVisible(false)
        self.m_protectBtn:setVisible(false)
        self.m_nodeProgress:hideCat()
        self.m_nodeSpinNum:setVisible(true)
        self.m_nodeSpinNum:runCsbAction("idle")
    elseif self.m_mapInfoData[1].level > 0 then
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_show_dog_head.mp3")
        self.m_nodeDog:setVisible(true)
        self.m_nodeDog:runCsbAction("actionframe")
        self.m_protectBtn:setVisible(false)
        self.m_nodeProgress:hideCat()
        self.m_nodeSpinNum:setVisible(false)
    else
        self.m_nodeDog:setVisible(false)
        self.m_nodeSpinNum:setVisible(true)
        self.m_nodeSpinNum:runCsbAction("idle1")
        self.m_protectBtn:setVisible(true)
    end
    if self.m_mapProgress then
        self.m_nodeTarget:updateUI(self.m_mapProgress.groupId)
    end
    local collectTimes = self.m_collectTotalCount - self.m_collectCurrCount
    self.m_nodeCollect:setLabNum(collectTimes)
    self.m_nodeSpinNum:setLabNum(self.m_leftSpinTimes)
end

--已经买了看门狗 或者正在收集看门狗
function CodeGameScreenFoodStreetMachine:isBuyDogOrCollect()
    if self.m_mapInfoData[1].level > 0 or self.m_mapInfoData[1].status == "PROGRESS" then
        return true
    end
    return false
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFoodStreetMachine:MachineRule_GetSelfCCBName(symbolType)
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFoodStreetMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

function CodeGameScreenFoodStreetMachine:initGameStatusData(gameData)
    if gameData and gameData.sequenceId and gameData.sequenceId == 0 then
        self:setMapTipStates(self.m_pandaBoard)
        self:setBuyDogStates(self.m_bugDogStates)
    end

    local extraData = gameData.gameConfig.extra
    if extraData ~= nil then
        -- self.m_mapInfoData = extraData.optionItems
        -- if #self.m_mapInfoData <= 0 then
        --     self.m_mapInfoData = extraData.items
        -- end
        self.m_mapInfoData = extraData.items
        self.m_mapProgress = extraData.progressItem
        self.m_collectType = extraData.collectSignal
        self.m_bSaleFlag = extraData.canSell
        self.m_buyDogs = extraData.buyDogs
    end
    self.m_curCollectTaskId = self.m_mapProgress and self.m_mapProgress.id or -1 --当前收集任务的Id

    if gameData.gameConfig.init ~= nil then
        self.m_collectTaskPrice = gameData.gameConfig.init.gems
    end
    self.m_mapInfoData.dogPrice = self:getDogTaskPrice()

    if gameData.collect ~= nil then
        self:updateCollectInfo(gameData.collect[1])
        if self.m_curCollectTaskId >= 0 then
            self:updataCollectLeftTip()
        end
    end

    BaseNewReelMachine.initGameStatusData(self, gameData)
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenFoodStreetMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin == true then
        self:updateMapBtnEnable(false)
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:runCsbAction("idle2")
        self.m_gameBg:runCsbAction("idle2", true)

        self.m_normalSpinBg:setVisible(false)
        self.m_freeSpinBg:setVisible(true)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenFoodStreetMachine:slotOneReelDown(reelCol)
    BaseNewReelMachine.slotOneReelDown(self, reelCol)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFoodStreetMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "fs")
    -- self:runCsbAction("idle2")
    -- self.m_baseFreeSpinBar:changeFreeSpinByCount()
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFoodStreetMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
    -- self.m_gameBg:runCsbAction(
    --     "normal",
    --     false,
    --     function()
    --         self.m_gameBg:runCsbAction("idle1", true)
    --     end
    -- )
    -- self:runCsbAction("idle1")
    -- self:updateTopUI()
end
---------------------------------------------------------------------------
function CodeGameScreenFoodStreetMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    self:showFreeSpinView(effectData)

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenFoodStreetMachine:playScatterTrigger()
    self:playScatterTipMusicEffect()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    targSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if not targSp then
                        targSp = self:setSymbolToClipReel(iCol, iRow, symbolType)
                    end
                    targSp:runAnim("actionframe", false)
                end
            end
        end
    end
end

function CodeGameScreenFoodStreetMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = self:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(self, index)
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end
----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenFoodStreetMachine:showFreeSpinView(effectData)
    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self.m_normalSpinBg:setVisible(false)
            self.m_freeSpinBg:setVisible(true)

            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_window_over.mp3")
                end,
                true
            )
        else
            self.m_GuoChang:setVisible(true)
            gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_guochang.mp3")

            self.m_GuoChang:runCsbAction(
                "star",
                false,
                function()
                    self.m_GuoChang:setVisible(false)
                end
            )

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(
                waitNode,
                function()
                    self.m_normalSpinBg:setVisible(false)
                    self.m_freeSpinBg:setVisible(true)

                    self.m_gameBg:runCsbAction(
                        "fs",
                        false,
                        function()
                            self.m_gameBg:runCsbAction("idle2", true)
                        end
                    )

                    self:runCsbAction("idle2")
                    self.m_baseFreeSpinBar:changeFreeSpinByCount()
                    self.m_baseFreeSpinBar:setVisible(true)
                    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_fs_start_tip.mp3")

                    self:showFreeSpinStart(
                        self.m_iFreeSpinTimes,
                        function()
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                            gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_window_over.mp3")
                        end
                    )

                    waitNode:removeFromParent()
                end,
                0.5
            )
        end
    end

    local dalayTimes = 0.5
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        dalayTimes = 3.0
        self:playScatterTrigger()
    end

    --  延迟0.5 不做特殊要求都这么延迟
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            showFSView()

            waitNode:removeFromParent()
        end,
        dalayTimes
    )
end

function CodeGameScreenFoodStreetMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_fs_over.mp3")

    local fswincoins = self.m_runSpinResultData.p_fsWinCoins or globalData.slotRunData.lastWinCoin or 0

    local strCoins = util_formatCoins(fswincoins, 20)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_window_over.mp3")

            performWithDelay(
                self,
                function()
                    self.m_normalSpinBg:setVisible(true)
                    self.m_freeSpinBg:setVisible(false)

                    self.m_gameBg:runCsbAction(
                        "normal",
                        false,
                        function()
                            self.m_gameBg:runCsbAction("idle1", true)
                        end
                    )
                    self:runCsbAction("idle1", false)
                    self:updateTopUI()
                    self:removeAllReelsNode()
                end,
                0.5
            )
            self.m_GuoChang:setVisible(true)
            gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_guochang.mp3")
            self.m_GuoChang:runCsbAction(
                "star",
                false,
                function()
                    self.m_GuoChang:setVisible(false)
                    self:triggerFreeSpinOverCallFun()
                end
            )
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 600)
end

function CodeGameScreenFoodStreetMachine:beginReel()
    BaseNewReelMachine.beginReel(self)

    self:btnCallFsWildAni()
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFoodStreetMachine:MachineRule_SpinBtnCall()
    self.m_wheelCoins = nil

    self:showAlllockWild()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    self:stopLinesWinSound()

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_nodeSpinNum:setLabNum(self.m_leftSpinTimes - 1)

    return false -- 用作延时点击spin调用
end

---
-- 处理spin 返回结果
function CodeGameScreenFoodStreetMachine:spinResultCallFun(param)
    BaseNewReelMachine.spinResultCallFun(self, param)

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.optionItems then
        self.m_mapInfoData = self.m_runSpinResultData.p_selfMakeData.optionItems
    end

    if param[1] == true then
        local spinData = param[2]
        -- print(cjson.encode(param[2]))
        if spinData.action == "SPECIAL" then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)

            -- base只处理了 action == spin 这块得手动处理
            -- 更新控制类数据
            self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)

            gLobalViewManager:removeLoadingAnima()
            local result = spinData.result
            dump(result, "选择返回结果spinResult")
            if result.selfData.wheel ~= nil then
            end
            self:updateMapInfo(result)
            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.canSell ~= nil then
                self.m_bSaleFlag = self.m_runSpinResultData.p_selfMakeData.canSell
            end
            if result.selfData.select and result.selfData.select == -1 then
                if not self.m_mapProgress then
                    self.m_mapLayer:initMapUI(self.m_mapInfoData, self.m_mapProgress, self.m_bSaleFlag)
                end
            elseif result.selfData.wheelIndex then
                self:addSellShopWheel(
                    result.selfData.wheelIndex,
                    result.selfData.wheel,
                    function()
                        self.m_mapLayer:initMapUI(self.m_mapInfoData, self.m_mapProgress, self.m_bSaleFlag)
                    end
                )
            else
                self:updateTopUI()
                self.m_mapLayer:chooseOver(self.m_mapProgress, self.m_bSaleFlag)
            end

            if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.buyDogs then
                self.m_buyDogs = self.m_runSpinResultData.p_selfMakeData.buyDogs
            end
        end
    end
end

function CodeGameScreenFoodStreetMachine:updateMapInfo(result)
    if result.selfData and result.selfData.items then
        self.m_mapInfoData = result.selfData.items
        self.m_mapInfoData.dogPrice = self:getDogTaskPrice()
    end
    if result.selfData.progressIndex then
        self.m_curCollectTaskId = result.selfData.progressIndex
        self.m_mapProgress = result.selfData.items[result.selfData.progressIndex + 1]
        self.m_collectType = result.selfData.collectSignal
        self:updateCollectInfo(result.collect[1])
    end
end

function CodeGameScreenFoodStreetMachine:updateCollectInfo(collect)
    if collect then
        self.m_collectTotalCount = collect.collectTotalCount
        self.m_collectCurrCount = collect.collectTotalCount - collect.collectLeftCount
        self.m_leftSpinTimes = collect.leftSpinTimes
        self.m_totalSpinTimes = collect.totalSpinTimes
    end
end

function CodeGameScreenFoodStreetMachine:getCollectProgress()
    local percent = 100 * self.m_collectCurrCount / self.m_collectTotalCount
    return percent
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenFoodStreetMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFoodStreetMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFoodStreetMachine:addSelfEffect()
    if self:getBetLevel() == 1 then
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            local lastNum = self.m_collectCurrCount
            self:updateCollectInfo(self.m_runSpinResultData.p_collectNetData[1])
            if lastNum ~= self.m_collectCurrCount then
                for iCol = 1, self.m_iReelColumnNum do
                    for iRow = self.m_iReelRowNum, 1, -1 do
                        local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                        if node then
                            if node.p_symbolType == self.m_collectType then
                                if not self.m_collectList then
                                    self.m_collectList = {}
                                end
                                table.insert(self.m_collectList, 1, node)
                            end
                        end
                    end
                end

                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.COLLECT_SYMBOL_EFFECT -- 动画类型
            elseif self.m_leftSpinTimes == 0 and self.m_collectTotalCount ~= self.m_collectCurrCount then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.CTCOLLECT_OVER_EFFECTCT
            end
        end

        -- 自定义动画创建方式
        if not self.m_isShowLeftTip then
            local bBuy = self:getCanByDog()
            if bBuy then
                if self.m_leftSpinTimes == 0 then
                    print("狗不能弹购买弹板")
                else
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.COLLECT_LEFT_EFFECT
                end
            end
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BONUS_FS_WILD_LOCK_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUS_FS_WILD_LOCK_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFoodStreetMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_SYMBOL_EFFECT then
        self:flySymbols(effectData)
    elseif effectData.p_selfEffectType == self.CTCOLLECT_OVER_EFFECTCT then
        self.m_protectBtn:setVisible(false)
        self.m_mapLayer:collectFailedRestMapTipStates()
        self.m_nodeProgress:collectFailed(
            function()
                self:collectOver(effectData)
            end
        )
    elseif effectData.p_selfEffectType == self.COLLECT_LEFT_EFFECT then
        self:checkLeftTip(effectData)
    elseif effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT then
        self:LockWildTurnAct(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end

    return true
end

function CodeGameScreenFoodStreetMachine:flySymbols(effectData)
    local endPos = self.m_nodeIcon:getParent():convertToWorldSpace(cc.p(self.m_nodeIcon:getPosition()))
    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_fly_symbol.mp3")

    local m_effectData = effectData
    local collectTotalCount = self.m_collectTotalCount
    local collectCurrCount = self.m_collectCurrCount
    local leftSpinTimes = self.m_leftSpinTimes
    local collectType = self.m_collectType

    local m_isTriggerFreeSpin = self:isTriggerFreeSpin()

    local isTriggerBonus = false
    if collectTotalCount == collectCurrCount or leftSpinTimes == 0 then
        isTriggerBonus = true
    end

    local lessNum = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
    local collectListNum = #self.m_collectList
    local m_collectList = self.m_collectList

    local percent = self:getCollectProgress()

    for i = 1, #m_collectList do
        local index = i
        local node = m_collectList[index]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local symbolNode = cc.Node:create()
        local eff = util_createAnimation("Socre_FoodStreet_shouji.csb")
        eff:runCsbAction("actionframe")
        local symbol = self:createFlySymbolByType(collectType)

        symbolNode:addChild(eff, 1)
        symbolNode:addChild(symbol, 2)

        local isLastSymbol = false
        if index == collectListNum then
            isLastSymbol = true
        end

        symbolNode:setScale(self.m_machineRootScale)
        self:addChild(symbolNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)

        symbolNode:setPosition(startPos)

        if isLastSymbol then
            if isTriggerBonus ~= true then
                if not m_isTriggerFreeSpin then
                    m_effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end
        end

        local bez = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        local callback = function()
            symbol:removeFromParent()
            eff:removeFromParent()
            symbolNode:removeFromParent()
            self.m_nodeIcon:collectAnim()

            if isLastSymbol == true then
                self.m_nodeCollect:setLabNum(lessNum)

                local isTriggerBonus_1 = isTriggerBonus
                local isLastSymbol_1 = isLastSymbol
                local m_isTriggerFreeSpin_1 = m_isTriggerFreeSpin
                local percent_1 = percent

                local lessNum_1 = lessNum

                self.m_nodeProgress:updatePercent(
                    percent_1,
                    function()
                        if isLastSymbol_1 == true then
                            if isTriggerBonus_1 == true then
                                if lessNum_1 > 0 then
                                    self.m_protectBtn:setVisible(false)

                                    self.m_mapLayer:collectFailedRestMapTipStates()
                                    self.m_nodeProgress:collectFailed(
                                        function()
                                            self:collectOver(m_effectData)
                                        end
                                    )
                                else
                                    self.m_nodeProgress:hideCat()
                                    self.m_protectBtn:setVisible(false)
                                    self:removeSoundHandler()
                                    gLobalSoundManager:setBackgroundMusicVolume(0)
                                    self.m_nodeProgress:collectSuccess(
                                        function()
                                            self:collectOver(m_effectData)
                                        end
                                    )
                                end
                            else
                                if m_isTriggerFreeSpin_1 then
                                    m_effectData.p_isPlay = true
                                    self:playGameEffect()
                                end
                            end
                        end
                    end
                )
            end
        end

        symbolNode:runAction(cc.Sequence:create(bez, cc.CallFunc:create(callback)))
    end

    self.m_collectList = {}
end

function CodeGameScreenFoodStreetMachine:createFlySymbolByType(_type)
    local eff = util_createAnimation("Socre_FoodStreet_shouji_0.csb")
    for i = 1, 9 do
        local node = eff:findChild("FoodStreet_symbol" .. i)
        node:setVisible(false)
        if (_type + 1) == i then
            node:setVisible(true)
        end
    end
    local node = eff:findChild("FoodStreet_wild")
    if _type == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        node:setVisible(true)
    else
        node:setVisible(false)
    end
    if _type >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 and _type <= TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 then
        eff:runCsbAction("actionframe1")
    else
        eff:runCsbAction("actionframe")
    end
    return eff
end

function CodeGameScreenFoodStreetMachine:isTriggerFreeSpin()
    local isIn = false
    local features = self.m_runSpinResultData.p_features
    if features then
        for k, v in pairs(features) do
            if v == SLOTO_FEATURE.FEATURE_FREESPIN then
                isIn = true
            end
        end
    end

    return isIn
end

function CodeGameScreenFoodStreetMachine:getCollectWheelCoins()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local wheel = selfdata.wheel or {}
    local select = selfdata.select

    if select then
        local coins = wheel[select + 1]
        self.m_wheelCoins = coins

        return coins
    end
end

function CodeGameScreenFoodStreetMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false
    local wheelCoins = self:getCollectWheelCoins()

    if #self.m_vecGetLineInfo == 0 then
        if wheelCoins then
            print("如果有圆盘赢钱不管有没有连线也加大赢")
        else
            notAdd = true
        end
    end

    return notAdd
end

function CodeGameScreenFoodStreetMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local wheelCoins = self.m_wheelCoins
    if wheelCoins then
        local beginCoins = wheelCoins
        if not isNotifyUpdateTop then
            local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
            local winAmant = self.m_serverWinCoins or 0
            beginCoins = fsWinCoins - wheelCoins

            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {fsWinCoins, isNotifyUpdateTop, nil, beginCoins})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        else
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop, nil, beginCoins})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

function CodeGameScreenFoodStreetMachine:collectOver(effectData)
    self.m_currentMusicBgName = "FoodStreetSounds/music_FoodStreet_map_bgm.mp3"
    gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)

    local result = self.m_runSpinResultData.p_selfMakeData.collectFinishItem
    local option = self.m_runSpinResultData.p_selfMakeData.optionItems
    option.dogPrice = self:getDogTaskPrice()
    self.m_bSaleFlag = self.m_runSpinResultData.p_selfMakeData.canSell
    if result ~= nil and result.type == "FOOD" then
        local info = {}
        info.wheel = self.m_runSpinResultData.p_selfMakeData.wheel
        info.select = self.m_runSpinResultData.p_selfMakeData.select

        self.m_mapLayer:setVisible(true)
        self.m_mapLayer:foodCompleted(
            info,
            result,
            option,
            self.m_bSaleFlag,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()

                self:normalBgmControl()
            end
        )
    else
        self.m_mapLayer:setVisible(true)
        self.m_mapLayer:collectOver(
            result,
            option,
            self.m_bSaleFlag,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
                self:normalBgmControl()
            end
        )
    end
    self:resetCollectLeftTip()
    --重置部分收集数据
    self.m_mapProgress = nil
    self.m_curCollectTaskId = -1 --  -1表示当前没有收集任务
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFoodStreetMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenFoodStreetMachine:playEffectNotifyNextSpinCall()
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenFoodStreetMachine:normalBgmControl()
    self:resetMusicBg()
    self:reelsDownDelaySetMusicBGVolume()
end

--判断是否弹出可购买看门狗弹板
function CodeGameScreenFoodStreetMachine:getCanByDog()
    -- --狗的等级
    -- if self:isBuyDogOrCollect() then
    --     return false
    -- end
    -- if self.m_collectType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
    --     return false
    -- end
    -- local percent = 100 * self.m_leftSpinTimes / self.m_totalSpinTimes
    -- if percent > 10 then
    --     return false
    -- end
    -- return true

    --狗的等级
    if self:isBuyDogOrCollect() then
        return false
    end

    local needPer = self.m_collectTotalCount / self.m_totalSpinTimes
    local lessPer = (self.m_collectTotalCount - self.m_collectCurrCount) / self.m_leftSpinTimes

    if needPer < lessPer then
        if self.m_leftSpinTimes <= math.max(10, math.floor(0.1 * self.m_totalSpinTimes)) then
            return true
        end
    end

    return false
end

function CodeGameScreenFoodStreetMachine:updataCollectLeftTip(effectData)
    local bBuy = self:getCanByDog()

    if not self.m_isShowLeftTip and bBuy then
        self.m_isShowLeftTip = true
        -- print("显示提示面板")
        -- print("显示提示面板按钮")
        if effectData then
            self:showBuyDogViewTip(effectData)
        end

        self.m_protectBtn:setVisible(true)
        self.m_nodeProgress:showCat()
    else
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
end

function CodeGameScreenFoodStreetMachine:resetCollectLeftTip()
    self.m_isShowLeftTip = false
    -- print("隐藏提示面板")
    -- print("隐藏提示面板按钮")
    self.m_protectBtn:setVisible(false)
    self.m_nodeProgress:hideCat()
    if self.m_BuyDogTip then
        self.m_BuyDogTip:closeUI()
    end
end

function CodeGameScreenFoodStreetMachine:checkLeftTip(effectData)
    self:updataCollectLeftTip(effectData)
end

function CodeGameScreenFoodStreetMachine:getCurTaskPrice()
    if self.m_collectTaskPrice then
        return self.m_collectTaskPrice[tostring(self.m_curCollectTaskId)]
    end
    return nil
end

function CodeGameScreenFoodStreetMachine:getDogTaskPrice()
    if self.m_collectTaskPrice then
        local idKey = "-1" --看门狗价格对应的key 该值与服务器约定的
        return self.m_collectTaskPrice[idKey]
    end
    return nil
end

function CodeGameScreenFoodStreetMachine:showBuyDogViewTip(effectData)
    local m_effectData = effectData

    if not self.m_BuyDogTip then
        local path = "CodeFoodStreetSrc.FoodStreetBuyDogTipView"

        local price = self:getDogTaskPrice()
        if type(m_effectData) == "nil" then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        else
            local states = self:getBuyDogStates()
            if states and states == self.m_bugDogStates then
                path = "CodeFoodStreetSrc.FoodStreetBuyDogFreeTipView"
            end
        end

        self.m_BuyDogTip = util_createView(path, {num = price, machine = self})
        self:findChild("maigoutanban"):addChild(self.m_BuyDogTip)
        self.m_BuyDogTip:setFun(
            function()
                if m_effectData then
                    m_effectData.p_isPlay = true
                    self:playGameEffect()
                end

                if type(m_effectData) == "nil" then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                end

                self.m_BuyDogTip = nil
            end
        )
    end
end

--[[
    @desc: 如果触发了 freespin 时，将本次触发的bigwin 和 mega win 去掉
    time:2019-01-22 15:31:18
    @return:
]]
function CodeGameScreenFoodStreetMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        -- if self.m_bProduceSlots_InFreeSpin == false then
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
    -- end
    end

    -- 如果处于 freespin 中 那么大赢都不触发
    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect == true then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
    end
end

function CodeGameScreenFoodStreetMachine:LockWildTurnAct(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local lockPosList = selfData.wildPositions or {}
    local newPosList = {}

    for i = 1, #lockPosList do
        local isOld = false
        for j = 1, #self.m_oldlockWildList do
            local wildNode = self.m_oldlockWildList[j]
            if wildNode.posIndex == lockPosList[i] then
                isOld = true
                break
            end
        end

        if not isOld then
            table.insert(newPosList, lockPosList[i])
        end
    end

    if #newPosList > 0 then
        self:turnToLockWild(newPosList, func)
    else
        if func then
            func()
        end
    end
end

function CodeGameScreenFoodStreetMachine:showAlllockWild()
    for i = #self.m_oldlockWildList, 1, -1 do
        local wild = self.m_oldlockWildList[i]
        if wild then
            wild:setVisible(true)
        end
    end
end

function CodeGameScreenFoodStreetMachine:hideAlllockWild()
    for i = #self.m_oldlockWildList, 1, -1 do
        local wild = self.m_oldlockWildList[i]
        if wild then
            wild:setVisible(false)
        end
    end
end

function CodeGameScreenFoodStreetMachine:removeAllReelsNode(notCreate)
    self:stopAllActions()
    self:clearWinLineEffect()

    -- 新滚动移除所有小块
    self:removeAllGridNodes()

    for i = #self.m_oldlockWildList, 1, -1 do
        local wild = self.m_oldlockWildList[i]
        if wild and wild.updateLayerTag then
            wild:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end
        wild:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(wild.m_symbolTag, wild)
        table.remove(self.m_oldlockWildList, i)
    end

    self.m_oldlockWildList = {}

    self:randomSlotNodes()
end

function CodeGameScreenFoodStreetMachine:initFsLockWild(wildPosList)
    if wildPosList and #wildPosList > 0 then
        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

            if targSp then
                self:addLockWild(targSp, pos)
            end
        end
    end

    self:showAlllockWild()
end

function CodeGameScreenFoodStreetMachine:turnToLockWild(wildPosList, func)
    if wildPosList and #wildPosList > 0 then
        for k, v in pairs(wildPosList) do
            local callFunc = nil
            if k == 1 then
                callFunc = function()
                    if func then
                        func()
                    end
                end
            end

            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

            if targSp then
                if callFunc then
                    callFunc()
                end

                self:addLockWild(targSp, pos, true)
            end
        end
    end
end

function CodeGameScreenFoodStreetMachine:addLockWild(targSp, posIndex, _addSign)
    if targSp then
        local wild = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        self.m_clipParent:addChild(wild, REEL_SYMBOL_ORDER.REEL_ORDER_3 + 100000 - 1, targSp:getTag())
        wild:setPosition(pos.x, pos.y)
        wild.p_cloumnIndex = targSp.p_cloumnIndex
        wild.p_rowIndex = targSp.p_rowIndex
        wild.m_isLastSymbol = targSp.m_isLastSymbol
        wild.m_symbolTag = SYMBOL_FIX_NODE_TAG
        wild.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3 + 100000 - 1
        wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        wild:setTag(self:getNodeTag(wild.p_cloumnIndex, wild.p_rowIndex, SYMBOL_NODE_TAG) + SYMBOL_FIX_NODE_TAG)

        local linePos = {}
        linePos[#linePos + 1] = {iX = wild.p_rowIndex, iY = wild.p_cloumnIndex}
        wild.m_bInLine = true
        wild:setLinePos(linePos)
        wild:runAnim("idleframe")
        wild.posIndex = posIndex
        wild:setVisible(false)
        if _addSign then
            wild.m_aniSign = true
        end

        table.insert(self.m_oldlockWildList, wild)
    end
end

function CodeGameScreenFoodStreetMachine:getBuyDogTime()
    return self.m_buyDogs
end

function CodeGameScreenFoodStreetMachine:getBuyDogPay()
    if self.m_mapInfoData and self.m_mapInfoData.dogPrice then
        return self.m_mapInfoData.dogPrice
    end

    return 0
end

function CodeGameScreenFoodStreetMachine:getBuyDogInfo()
    if self.m_mapInfoData and self.m_mapInfoData[1] then
        return self.m_mapInfoData[1]
    end

    return nil
end

function CodeGameScreenFoodStreetMachine:addSellShopWheel(wheelIndex, wheel, callFunc)
    local data = {}
    data.wheel = wheel
    data.wheelIndex = wheelIndex
    data.keepShop = 1

    for i, v in ipairs(self.m_mapInfoData) do
        if v.level > 0 then
            data.keepShop = v.groupId
            break
        end
    end

    self.m_mapLayer:addSuperWheel(data, callFunc)
end

function CodeGameScreenFoodStreetMachine:btnCallFsWildAni()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local child = self.m_clipParent:getChildren()
        if type(child) == "table" then
            local isBuling = false
            for index = 1, #child do
                local slotNode = child[index]
                if slotNode.p_symbolType and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    if slotNode.m_aniSign then
                        slotNode.m_aniSign = nil
                        slotNode:runAnim("buling")
                        isBuling = true
                    end
                end
            end
            if isBuling then
                gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wild_buling.mp3")
            end
        end
    end
end

function CodeGameScreenFoodStreetMachine:playCustomSpecialSymbolDownAct(slotNode)
    CodeGameScreenFoodStreetMachine.super.playCustomSpecialSymbolDownAct(self, slotNode)
end

-- 本地存储 弹板tip

function CodeGameScreenFoodStreetMachine:getMapTipStates()
    local states = gLobalDataManager:getStringByField("FoodStreetTipStates", "")

    return states
end

function CodeGameScreenFoodStreetMachine:setMapTipStates(states)
    gLobalDataManager:setStringByField("FoodStreetTipStates", states, true)
end

-- 本地存储免费买狗

function CodeGameScreenFoodStreetMachine:getBuyDogStates()
    local states = gLobalDataManager:getStringByField("buyDogStates", "")

    return states
end

function CodeGameScreenFoodStreetMachine:setBuyDogStates(states)
    gLobalDataManager:setStringByField("buyDogStates", states, true)
end

function CodeGameScreenFoodStreetMachine:getWinCoinTime()
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

    local features = self.m_runSpinResultData.p_features or {}
    if features and #features == 2 and features[2] == 1 then
        showTime = 0
    end

    return showTime
end

function CodeGameScreenFoodStreetMachine:requestSpinResult()
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

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_SPIN_PROGRESS, data = self.m_collectDataList, jackpot = self.m_jackpotList, betLevel = self:getBetLevel()}

    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

--假滚修改
--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenFoodStreetMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        --分高低bet取出假滚
        local minBet = self:getMinBet()
        local betCoin = globalData.slotRunData:getCurTotalBet()
        local isHeight = betCoin >= minBet

        if isHeight then
            --高bet内 所有100信号变为 当前收集信号
            local curCollectSymbol = self.m_collectType

            local colKey = string.format("reel2_cloumn%d", parentData.cloumnIndex)
            reelDatas = clone(self.m_configData.m_baseHeightReel[colKey])
            for _index, _symbol in ipairs(reelDatas) do
                if _symbol == self.SYMBOL_COLLECT then
                    reelDatas[_index] = curCollectSymbol
                end
            end
        else
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        end
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

return CodeGameScreenFoodStreetMachine
