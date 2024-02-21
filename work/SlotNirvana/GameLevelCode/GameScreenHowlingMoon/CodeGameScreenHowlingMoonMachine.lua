--
-- 长条lighting
-- Author:{author}
-- Date: 2018-12-22 12:26:51
--

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenHowlingMoonMachine = class("CodeGameScreenHowlingMoonMachine", BaseSlotoManiaMachine)

CodeGameScreenHowlingMoonMachine.m_bnBaseType = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenHowlingMoonMachine.SYMBOL_FIX_MINI = 102
CodeGameScreenHowlingMoonMachine.SYMBOL_FIX_MINOR = 103
CodeGameScreenHowlingMoonMachine.SYMBOL_FIX_MAJOR = 104
CodeGameScreenHowlingMoonMachine.SYMBOL_FIX_GRAND = 105
CodeGameScreenHowlingMoonMachine.SYMBOL_fsScatterType = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2

CodeGameScreenHowlingMoonMachine.m_respinAddRow = 4
CodeGameScreenHowlingMoonMachine.m_respinLittleNodeSize = 2
CodeGameScreenHowlingMoonMachine.m_lockNodeArray = {}

CodeGameScreenHowlingMoonMachine.m_lockNumArray = {8, 12, 16, 20}

CodeGameScreenHowlingMoonMachine.ADD_FREE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3
CodeGameScreenHowlingMoonMachine.m_winSoundsId = nil
CodeGameScreenHowlingMoonMachine.m_littleSymbolScaleSize = nil
CodeGameScreenHowlingMoonMachine.m_triggerSpecialGame = nil -- 只用作断线重连来判断是否播放完进入音后重置背景音月

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136
local FIT_HEIGHT_MOD = 1280

local RESPIN_ROW_COUNT = 8
local NORMAL_ROW_COUNT = 4
function CodeGameScreenHowlingMoonMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_lightScore = 0
    self.m_winSoundsId = nil
    self.m_triggerSpecialGame = false

    self.m_jackpot_status = "Normal"
    self.m_isJackpotEnd = false
    self.m_isFeatureOverBigWinInFree = true

    self:initGame()
end

function CodeGameScreenHowlingMoonMachine:initGame()
    self.m_lockNodeArray = {}
    self.m_littleSymbolScaleSize = 1

    --限定 scatter 出现的列
    self.m_ScatterShowCol = {2, 3, 4}

    -- 中奖音效
    self.m_winPrizeSounds = {}
    for i = 1, 3 do
        self.m_winPrizeSounds[#self.m_winPrizeSounds + 1] = "HowlingMoonSounds/HowlingMoonSounds_win" .. i .. ".mp3"
    end

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end
            local winAmonut = params[1]
            if type(winAmonut) == "number" then
                local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
                local winRatio = winAmonut / lTatolBetNum
                local soundName = nil
                local soundTime = 2
                if winRatio > 0 then
                    if winRatio <= 1 then
                        soundName = self.m_winPrizeSounds[1]
                    elseif winRatio > 1 and winRatio <= 3 then
                        soundName = self.m_winPrizeSounds[2]
                    elseif winRatio > 3 then
                        soundName = self.m_winPrizeSounds[3]
                        soundTime = 3
                    end
                end

                if soundName ~= nil then
                    self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
                end
            end
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    self.m_configData = gLobalResManager:getCSVLevelConfigData("HowlingMoonConfig.csv", "LevelHowlingMoonConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function CodeGameScreenHowlingMoonMachine:initUI(data)
    self:findChild("Node_tx"):setLocalZOrder(2010)
    self:findChild("black_bg"):setVisible(false)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")

    self:findChild("node_lock"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_jackPotBar = util_createView("CodeHowlingMoonSrc.HowlingMoonTopBar")
    self:findChild("node_top"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    --   self:findChild("node_top"):setVisible(false)

    self.m_jackPotBar:setVisible(true)

    local targetNode = self:findChild("node_show")
    targetNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_wonThings = util_createView("CodeHowlingMoonSrc.HowlingMoonWonThings")
    targetNode:addChild(self.m_wonThings)
    util_setCsbVisible(self.m_wonThings, false)

    self:findChild("node_freespin_father"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 105)
    self:findChild("node_freespin"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 105)
    -- self.m_wonBonusTimes = util_createView("CodeHowlingMoonSrc.HowlingMoonBonusGameTittle")
    -- self:findChild("node_freespin"):addChild(self.m_wonBonusTimes,GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN+1)
    --   local node_bar = self:findChild("node_freespin")
    --   local WorldPos = self.m_root:convertToWorldSpace(cc.p(node_bar:getPosition()))
    --   local Pos=  cc.p(self:convertToNodeSpace(WorldPos))
    --   self.m_wonBonusTimes:setPosition(cc.p(Pos.x,Pos.y +370 ))
    -- util_setCsbVisible(self.m_wonBonusTimes,false)

    self:addClick(self:findChild("click"))
    self:findChild("tishi0"):setVisible(false)
    self:findChild("tishi1"):setVisible(false)

    -- self.m_baseFreeSpinBar = self.m_wonBonusTimes
    self:initFreeSpinBar()
    self:initRespinBar()

    -- self:findChild("node_action"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 200)
    self.m_respinStartAction = util_createView("CodeHowlingMoonSrc.HowlingMoonRespinStartAction")
    -- self:findChild("node_action"):addChild(self.m_respinStartAction)

    self:findChild("Node_tc"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 200)
    self:addChild(self.m_respinStartAction, ViewZorder.ZORDER_UI - 1)
    self.m_respinStartAction:setPosition(cc.p(display.width / 2, display.height / 2))
    util_setCsbVisible(self.m_respinStartAction, false)

    for i = 1, 4 do
        self.m_lockNodeArray[#self.m_lockNodeArray + 1] = util_createView("CodeHowlingMoonSrc.HowlingMoonRespinLockReels")
        local index = 5 - i
        self:findChild("Node_lock" .. index):addChild(self.m_lockNodeArray[#self.m_lockNodeArray])
    end
    self:hideAllLockNode()

    self.m_SprAction = util_createView("CodeHowlingMoonSrc.HowlingMoonSprAction")
    self:findChild("Node_tittle"):addChild(self.m_SprAction)

    -- self:findChild("Node_tittle"):setVisible(false)
end

--初始freespin tips
function CodeGameScreenHowlingMoonMachine:initFreeSpinBar()
    local node_bar = self:findChild("node_freespin")
    self.m_baseFreeSpinBar = util_createView("CodeHowlingMoonSrc.HowlingMoonFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end

function CodeGameScreenHowlingMoonMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:changeFreeSpinByCount()
    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenHowlingMoonMachine:initRespinBar()
    local node_bar = self:findChild("node_freespin")
    self.m_baseReSpinBar = util_createView("CodeHowlingMoonSrc.HowlingMoonRespinBarView")
    node_bar:addChild(self.m_baseReSpinBar)
    util_setCsbVisible(self.m_baseReSpinBar, false)
    self.m_baseReSpinBar:setPosition(0, 0)
end

function CodeGameScreenHowlingMoonMachine:clickFunc(sender)
    self:unlockHigherBet()
end
--适配
function CodeGameScreenHowlingMoonMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    --看资源实际的高度
    uiH = 120
    uiBH = 180

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    if display.height / display.width == DESIGN_SIZE.height / DESIGN_SIZE.width then
        --设计尺寸屏
    elseif display.height / display.width > DESIGN_SIZE.height / DESIGN_SIZE.width then
        --高屏
        local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale < wScale then
            mainScale = hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        --jackpot条适当上移
        local disY = -50 --这是一个虚假想象点离node_top点的Y轴距离 最后实际是把jackpot放到这个点的位置
        local dis1 = self:findChild("node_top"):getPositionY() + disY - DESIGN_SIZE.height / 2 -- 离屏幕中心Y轴距离
        local offsetY1 = dis1 * hScale - dis1
        self:findChild("node_top"):setPositionY(self:findChild("node_top"):getPositionY() + disY + offsetY1)
        --轮盘适当下移(由于点很多，这里直接将 root 下移，再把jackpot 背景上移相同距离)
        local dis2 = DESIGN_SIZE.height / 2 - self:findChild("Node_tc"):getPositionY() --用Node_tc这个点只是因为这个点在轮盘的中心位置,用他的位置相对合理一些
        local offsetY2 = dis2 * hScale - dis2
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - offsetY2)
        self:findChild("node_top"):setPositionY(self:findChild("node_top"):getPositionY() + offsetY2)
        self:findChild("bgNode"):setPositionY(self:findChild("bgNode"):getPositionY() + offsetY2)
    else
        --宽屏
        local topAoH = 40
         --顶部条凹下去距离 在宽屏中会被用的尺寸
        local bottomMoveH = 30
         --底部空间尺寸，最后要下移距离
        local hScale1 = (mainHeight + topAoH) / (mainHeight + topAoH - bottomMoveH)
         --有效区域尺寸改变适配
        local hScale = (mainHeight + topAoH) / (DESIGN_SIZE.height - uiH - uiBH + topAoH)
         --有效区域屏幕适配
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale1 * hScale < wScale then
            mainScale = hScale1 * hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        local designDis = (DESIGN_SIZE.height / 2 - uiBH) * mainScale
         --设计离下条距离
        local dis = (display.height / 2 - uiBH)
         --实际离下条距离
        local move = designDis - dis
        --宽屏下轮盘跟底部条更接近，实际整体下移了
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + move - bottomMoveH)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end

function CodeGameScreenHowlingMoonMachine:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenHowlingMoonMachine:playEffectNotifyNextSpinCall()
    BaseMachineGameEffect.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenHowlingMoonMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(8, 5, TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function CodeGameScreenHowlingMoonMachine:requestSpinResult()
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
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenHowlingMoonMachine:showLowerBetTip(first)
    local tip, act = util_csbCreate("HowlingMoon_Tips.csb")
    if first == true then
        self:findChild("Node_tips"):addChild(tip)
        if globalData.slotRunData.machineData.p_portraitFlag then
            tip.getRotateBackScaleFlag = function()
                return false
            end
        end
    else
        local parent = self.m_bottomUI:findChild("bet_eft")
        tip:setPositionY(74)
        parent:addChild(tip)
    end

    util_csbPlayForKey(
        act,
        "AUTO",
        false,
        function()
            tip:removeFromParent(true)
        end
    )
end

function CodeGameScreenHowlingMoonMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end
end

function CodeGameScreenHowlingMoonMachine:unlockHigherBet()
    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE
     then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenHowlingMoonMachine:onEnter()
    self:checkUpateDefaultBet()
    self:initTopCommonJackpotBar()
    self:updataJackpotStatus()

    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    
    
    
    
    self:updateBetLevel()
    self.m_jackPotBar:updateJackpotInfo()
    self:findChild("tishi" .. self.m_iBetLevel):setVisible(true)

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:findChild("tishi" .. self.m_iBetLevel):setVisible(false)
    else
        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
            if self.m_iBetLevel == 0 then
                performWithDelay(
                    self,
                    function()
                        self:showLowerBetTip(true)
                    end,
                    0.2
                )
            end
        end
    end

    local hasFeature = self:checkHasFeature()
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not hasFeature then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_ONENTER)
    end

end

function CodeGameScreenHowlingMoonMachine:changeBetEffect()
    gLobalSoundManager:playSound("HowlingMoonSounds/sound_HowlingMoon_unlock_highbet.mp3")
    local tip, act = util_csbCreate("HowlingMoon_Tips2.csb")
    local tishi = self:findChild("tishi0")
    local parent = tishi:getParent()
    tip:setPosition(tishi:getPositionX(), tishi:getPositionY())
    parent:addChild(tip)

    if globalData.slotRunData.machineData.p_portraitFlag then
        tip.getRotateBackScaleFlag = function()
            return false
        end
    end

    util_csbPlayForKey(
        act,
        "actionframe",
        false,
        function()
            tip:removeFromParent(true)
        end
    )
end

function CodeGameScreenHowlingMoonMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local perBetLevel = self.m_iBetLevel
            self:updateBetLevel()
            --公共jackpot
            self:updataJackpotStatus(params)

            if perBetLevel ~= self.m_iBetLevel then
                self:changeBetEffect()
                scheduler.performWithDelayGlobal(
                    function()
                        self:findChild("tishi" .. self.m_iBetLevel):setVisible(true)
                        self:findChild("tishi" .. perBetLevel):setVisible(false)
                    end,
                    1 / 6,
                    self:getModuleName()
                )
                -- performWithDelay(self, function()
                --     self:findChild("tishi"..self.m_iBetLevel):setVisible(true)
                --     self:findChild("tishi"..perBetLevel):setVisible(false)
                -- end, 1/6)
                if perBetLevel > self.m_iBetLevel then
                    self:showLowerBetTip(true)
                end
            end
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:unlockHigherBet()
        end,
        ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET
    )

    --公共jackpot活动结束
    gLobalNoticManager:addObserver(self,function(target, params)

        if params.name == ACTIVITY_REF.CommonJackpot then
            self.m_isJackpotEnd = true
            self:updataJackpotStatus()
        end

    end,ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function CodeGameScreenHowlingMoonMachine:respinChangeReelGridCount(count)
    for i = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end

-- 断线重连
function CodeGameScreenHowlingMoonMachine:MachineRule_initGame(initSpinData)
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
        self.m_iReelRowNum = #self.m_runSpinResultData.p_reels
        self:respinChangeReelGridCount(#self.m_runSpinResultData.p_reels)
    end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        self:showAllLockNode()
    end

    if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
        self.m_bProduceSlots_InFreeSpin = true
    end
end

function CodeGameScreenHowlingMoonMachine:enterGamePlayMusic()
    gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_goin.mp3")

    scheduler.performWithDelayGlobal(
        function()
            if not self.m_triggerSpecialGame then
                self:resetMusicBg()
                performWithDelay(
                    self,
                    function()
                        self:reelsDownDelaySetMusicBGVolume()
                    end,
                    0.3
                )
            end
        end,
        3.5,
        self:getModuleName()
    )
end

function CodeGameScreenHowlingMoonMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())

    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearTitleNode()
    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearEntryNode()
end

--ReSpin结算改变UI状态
function CodeGameScreenHowlingMoonMachine:changeReSpinOverUI()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinBar()
    end
end

-- jackPot
function CodeGameScreenHowlingMoonMachine:initJackpotInfo(jackpotPool, lastBetId)
    self.m_jackPotBar:updateJackpotInfo()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenHowlingMoonMachine:getModuleName()
    return "HowlingMoon"
end
function CodeGameScreenHowlingMoonMachine:getRespinView()
    return "CodeHowlingMoonSrc.HowlingMoonRespinView"
end

function CodeGameScreenHowlingMoonMachine:getRespinNode()
    return "CodeHowlingMoonSrc.HowlingMoonRespinNode"
end

function CodeGameScreenHowlingMoonMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("bgNode"):addChild(gameBg)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenHowlingMoonMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.m_bnBaseType then
        return "Socre_HowlingMoon_light"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_HowlingMoon_Bonus_mini"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_HowlingMoon_Bonus_minor"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_HowlingMoon_Bonus_major"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_HowlingMoon_Bonus_grand"
    elseif symbolType == self.SYMBOL_fsScatterType then
        return "Socre_HowlingMoon_Spin1"
    end

    return nil
end

function CodeGameScreenHowlingMoonMachine:getReelHeight()
    return 400
end

function CodeGameScreenHowlingMoonMachine:getReelWidth()
    return 825
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenHowlingMoonMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = {symbolType = self.m_bnBaseType, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_GRAND, count = 2}

    return loadNode
end
-- ---------- 玩法处理 --------

function CodeGameScreenHowlingMoonMachine:setLockDataInfo()
    self.m_allLockNodeReelPos = {}
    for i = 1, #self.m_runSpinResultData.p_storedIcons do
        local iconInfo = self.m_runSpinResultData.p_storedIcons[i]
        self.m_allLockNodeReelPos[#self.m_allLockNodeReelPos + 1] = {iconInfo[1], iconInfo[2]}
    end
end
function CodeGameScreenHowlingMoonMachine:getChangeSymbolType(score)
    if score == 20 then
        return self.SYMBOL_FIX_MINI
    elseif score == 50 then
        return self.SYMBOL_FIX_MINOR
    elseif score == 100 then
        return self.SYMBOL_FIX_MAJOR
    elseif score == 500 then
        return self.SYMBOL_FIX_GRAND
    else
        return nil
    end
end

-- 重写 getSlotNodeWithPosAndType 方法
function CodeGameScreenHowlingMoonMachine:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, iRow, iCol, isLastSymbol)

    if symbolType == self.m_bnBaseType or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR or symbolType == self.SYMBOL_FIX_GRAND then
        --下帧调用 才可能取到 x y值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        reelNode:runAction(callFun)
    end
    return reelNode
end
-- 获得respin显示分数
function CodeGameScreenHowlingMoonMachine:getReSpinSymbolScore(_reelPos)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil

    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == _reelPos then
            score = values[2]
        end
    end

    if score == nil then
        return nil
    end

    local pos = self:getRowAndColByPos(_reelPos)
    local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if type == self.SYMBOL_FIX_MINI then
        score = "MINI"
    elseif type == self.SYMBOL_FIX_MINOR then
        score = "MINOR"
    elseif type == self.SYMBOL_FIX_MAJOR then
        score = "MAJOR"
    elseif type == self.SYMBOL_FIX_GRAND then
        score = "GRAND"
    end

    return score
end

function CodeGameScreenHowlingMoonMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if self.m_bProduceSlots_InFreeSpin then
        if symbolType == self.m_bnBaseType then
            score = math.random(1, 2)
        else
            score = "jackpot"
        end
    else
        if symbolType == self.m_bnBaseType then
            score = math.random(1, 2)
        else
            score = "jackpot"
        end
    end

    return score
end

-- 设置respin分数
function CodeGameScreenHowlingMoonMachine:setSpecialNodeScore(sender, parma)
    local symbolNode = parma[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --   symbolNode:runAnim("buling")
        --获取分数
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
        if score then
            local index = 0
            if type(score) ~= "string" then
                local lineBet = self:BaseMania_getLineBet() * self.m_lineCount
                score = score * lineBet
                score = util_formatCoins(score, 3)
                if symbolNode:getCcbProperty("m_lb_score") then
                    if symbolNode:getCcbProperty("m_lb_score").setString then
                        symbolNode:getCcbProperty("m_lb_score"):setString(score)
                    end
                end
            end
        end
    else
        --   symbolNode:runAnim("buling")
        local score = nil
        if globalData.slotRunData.currSpinMode == RESPIN_MODE then
            if symbolNode.p_symbolType == self.m_bnBaseType then
                score = symbolNode.score
            else
                score = "jackpot"
            end
        else
            score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        end

        if type(score) ~= "string" then
            local lineBet = self:BaseMania_getLineBet() * self.m_lineCount
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode:getCcbProperty("m_lb_score") then
                if symbolNode:getCcbProperty("m_lb_score").setString then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
            end
        end
    end
end

function CodeGameScreenHowlingMoonMachine:getPosReelIdx(iRow, iCol)
    local iReelRow = #self.m_runSpinResultData.p_reels
    local index = (iReelRow - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

--[[
    @desc: 自定义动画
    time:2018-12-26 11:35:37
    @return:
]]
function CodeGameScreenHowlingMoonMachine:addSelfEffect()
    if self.m_bProduceSlots_InFreeSpin == true then
        -- 添加freeSpin次数
        local tarzanCount = self:getSymbolCountWithReelResult(self.SYMBOL_fsScatterType)
        if tarzanCount > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.ADD_FREE_EFFECT
        end
    end
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenHowlingMoonMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.ADD_FREE_EFFECT then
        self:clearCurMusicBg()
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_show_view.mp3")
                local view =
                    self:showFreeSpinMore(
                    "+" .. self.m_runSpinResultData.p_freeSpinNewCount,
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                        self:resetMusicBg()
                    end,
                    true
                )
                if self.m_runSpinResultData.p_freeSpinNewCount > 1 then
                    view:findChild("fs award_0"):setVisible(true)
                    view:findChild("fs award"):setVisible(false)
                else
                    view:findChild("fs award_0"):setVisible(false)
                    view:findChild("fs award"):setVisible(true)
                end
            end,
            1.3,
            self:getModuleName()
        )
    end

    return true
end
function CodeGameScreenHowlingMoonMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showHowlingMoonDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showHowlingMoonDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

function CodeGameScreenHowlingMoonMachine:showHowlingMoonDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)
    self:findChild("Node_tc"):addChild(view)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    return view
end
-- 单列滚动结束调用
function CodeGameScreenHowlingMoonMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self, reelCol)

    local isPlayScatter = true
    local isPlayBonus = true
    -- 播放动画
    for i = 1, self.m_iReelRowNum, 1 do
        local symbolType = self.m_stcValidSymbolMatrix[i][reelCol]

        if symbolType == self.SYMBOL_fsScatterType then
            -- local symbolNode = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol,i,SYMBOL_NODE_TAG))
            local symbolNode = self:setSymbolToClipReel(reelCol, i, self.SYMBOL_fsScatterType)
            symbolNode:runAnim(
                "buling",
                false,
                function()
                    symbolNode:runAnim("actionframe", true)
                end
            )
            -- symbolNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE+i)

            if isPlayScatter then
                isPlayScatter = false

                local soundPath = "HowlingMoonSounds/HowlingMoon_freespin_Scatter_down.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

            end
        elseif
            symbolType == self.m_bnBaseType or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR or symbolType == self.SYMBOL_FIX_GRAND
         then
            local symbolNode = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, i, SYMBOL_NODE_TAG))
            if symbolNode then
                symbolNode:runAnim("buling")
            end

            if isPlayBonus then
                isPlayBonus = false

                local soundPath = "HowlingMoonSounds/music_HowlingMoon_spin_light_down2_1.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

            end
        end
    end
end

function CodeGameScreenHowlingMoonMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

--服务端网络数据返回成功后处理
function CodeGameScreenHowlingMoonMachine:MachineRule_afterNetWorkLineLogicCalculate()
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount

    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
end

--ReSpin开始改变UI状态
function CodeGameScreenHowlingMoonMachine:changeReSpinStartUI(respinCount)
    --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    util_setCsbVisible(self.m_baseReSpinBar, true)
    self.m_baseReSpinBar:showRespinBar(respinCount)

    self:resetMusicBg()
end
--ReSpin刷新数量
function CodeGameScreenHowlingMoonMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    -- 更新respin次数
    --   self.m_wonBonusTimes:updataRespinTimes(curCount)
    self.m_baseReSpinBar:updateLeftCount(curCount, false)
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenHowlingMoonMachine:levelFreeSpinEffectChange(isShowAction)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        ---  normal To FeeSpin
        self:changeBGNormalToFreeSpin()
    end
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenHowlingMoonMachine:levelFreeSpinOverChangeEffect(content)
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenHowlingMoonMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_winSoundsId = nil

    return false
end
-- function CodeGameScreenHowlingMoonMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
--     -- 延迟回调播放 界面提示 bonus  freespin
--     scheduler.performWithDelayGlobal(
--         function()
--             -- self:resetMaskLayerNodes()
--             callFun()
--         end,
--         util_max(2, animTime),
--         self:getModuleName()
--     )
-- end

function CodeGameScreenHowlingMoonMachine:setSlotNodeEffectParent(slotNode)
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
        local animName = slotNode:getLineAnimName()

        slotNode:runAnim(animName, false)
    end
    return slotNode
end

-- --------------fs 开始  结束界面  -----------
function CodeGameScreenHowlingMoonMachine:showFreeSpinView(effectData)
    self.m_triggerSpecialGame = true

    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_show_view.mp3")
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                self:showFreeSpinMore(
                    self.m_runSpinResultData.p_freeSpinNewCount,
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    true
                )
            else
                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

                self:showFreeSpinStart(
                    self.m_iFreeSpinTimes,
                    function()
                        self:changeBGNormalToFreeSpin()
                        -- self:transitionView()
                        scheduler.performWithDelayGlobal(
                            function()
                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                                -- self:findChild("tishi"..self.m_iBetLevel):setVisible(false)
                            end,
                            0.5,
                            self:getModuleName()
                        )
                    end
                )
                scheduler.performWithDelayGlobal(
                    function()
                        self:showFreeSpinBar()
                        self:findChild("tishi" .. self.m_iBetLevel):setVisible(false)
                    end,
                    0.5,
                    self:getModuleName()
                )
            end
        end,
        1.5,
        self:getModuleName()
    )
end

function CodeGameScreenHowlingMoonMachine:showFreeSpinOverView()
    -- self.m_wonBonusTimes:overAction(false)

    scheduler.performWithDelayGlobal(
        function()
            scheduler.performWithDelayGlobal(
                function()
                    gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_show_view.mp3")
                end,
                0.5,
                self:getModuleName()
            )
            --切换文本
            scheduler.performWithDelayGlobal(
                function()
                    self:findChild("tishi" .. self.m_iBetLevel):setVisible(true)
                    util_setCsbVisible(self.m_baseFreeSpinBar, false)
                end,
                0.8,
                self:getModuleName()
            )

            local view =
                self:showFreeSpinOver(
                globalData.slotRunData.lastWinCoin,
                self.m_runSpinResultData.p_freeSpinsTotalCount,
                function()
                    self:changeBGFreeSpinToNormal()
                    -- self:transitionView()
                    scheduler.performWithDelayGlobal(
                        function()
                            self:triggerFreeSpinOverCallFun()
                        end,
                        0.2,
                        self:getModuleName()
                    )
                end
            )

            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node, sx = 1, sy = 1}, 645)
        end,
        1,
        self:getModuleName()
    )
end

-- RespinView
function CodeGameScreenHowlingMoonMachine:showRespinView(effectData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_WIN_RESPIN)
    self.m_triggerSpecialGame = true


    scheduler.performWithDelayGlobal(
        function()
            --先播放动画 再进入respin
            gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_enter_bonus.mp3")

            -- 播放自定义light动画
            for j = 1, self.m_iReelColumnNum, 1 do
                for i = 1, self.m_iReelRowNum, 1 do
                    local symbolType = self.m_stcValidSymbolMatrix[i][j]

                    if
                        symbolType == self.m_bnBaseType or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR or
                            symbolType == self.SYMBOL_FIX_GRAND
                     then
                        local symbolNode = self:getReelParent(j):getChildByTag(self:getNodeTag(j, i, SYMBOL_NODE_TAG))
                        symbolNode:runAnim(
                            "actionframe1",
                            false,
                            function()
                            end
                        )
                    end
                end
            end
        end,
        0.2,
        self:getModuleName()
    )

    scheduler.performWithDelayGlobal(
        function()
            scheduler.performWithDelayGlobal(
                function()
                    gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_show_view.mp3")
                end,
                0.2,
                self:getModuleName()
            )

            local func = function()
                if not (globalData.slotRunData.currSpinMode == FREE_SPIN_MODE) then
                    self:transitionView()
                    self:changeBGNormalToRespin()
                else
                    self:transitionView()
                    self:changeBGFreespinToRespin()
                end

                scheduler.performWithDelayGlobal(
                    function()
                        self:findChild("tishi" .. self.m_iBetLevel):setVisible(false)
                        --隐藏 盘面信息
                        self:setReelSlotsNodeVisible(false)
                        self:runCsbAction(
                            "animation0",
                            false,
                            function()
                            end
                        )
                        self.m_jackPotBar:setChangeWith(true)
                        self.m_jackPotBar:runCsbAction("animation1")
                    end,
                    0.5,
                    self:getModuleName()
                )

                self:findChild("Node_tittle"):setVisible(false)
                util_setCsbVisible(self.m_baseFreeSpinBar, false)
                --构造盘面数据
                scheduler.performWithDelayGlobal(
                    function()
                        self:findChild("black_bg"):setVisible(true)
                        self:runCsbAction(
                            "actionframe1",
                            false,
                            function()
                            end
                        )

                        -- util_setCsbVisible(self.m_wonBonusTimes,true)
                        util_setCsbVisible(self.m_baseReSpinBar, true)
                        self.m_bottomUI:checkClearWinLabel()
                        scheduler.performWithDelayGlobal(
                            function()
                                -- self.m_wonBonusTimes:updataRespinTimes(self.m_runSpinResultData.p_reSpinCurCount,true)
                                self.m_baseReSpinBar:showRespinBar(self.m_runSpinResultData.p_reSpinCurCount)
                            end,
                            3.8,
                            self:getModuleName()
                        )

                        gLobalSoundManager:playSound("HowlingMoonSounds/sound_HowlingMoon_reels_change.mp3")

                        --可随机的普通信息
                        local randomTypes = {
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
                            TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
                        }

                        --可随机的特殊信号
                        local endTypes = {
                            {type = self.m_bnBaseType, runEndAnimaName = "", bRandom = true},
                            {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "", bRandom = true},
                            {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "", bRandom = true},
                            {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "", bRandom = true},
                            {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "", bRandom = true}
                        }

                        --构造盘面数据
                        scheduler.performWithDelayGlobal(
                            function()
                                self:showAllLockNode()

                                self.m_iReelRowNum = 8
                                self:respinChangeReelGridCount(8)

                                if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
                                    self:triggerReSpinCallFun(endTypes, randomTypes)
                                else
                                    -- 由玩法触发出来， 而不是多个元素触发
                                    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                                        self.m_runSpinResultData.p_reSpinCurCount = 3
                                    end
                                    self:triggerReSpinCallFun(endTypes, randomTypes)
                                end
                                self.m_jackPotBar:updateMegaShow()
                            end,
                            4.5,
                            self:getModuleName()
                        )
                    end,
                    1.5,
                    self:getModuleName()
                )
            end
            self:showHowlingMoonDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func, BaseDialog.AUTO_TYPE_ONLY)
        end,
        4,
        self:getModuleName()
    )
end

-- --结束移除小块调用结算特效
function CodeGameScreenHowlingMoonMachine:reSpinEndAction()
    scheduler.performWithDelayGlobal(
        function()
            -- self.m_wonBonusTimes:overAction(false)
            -- self.m_baseReSpinBar:
            gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_spin_respin_Over.mp3")

            self:reSpinEndAllLightAction()

            self:clearCurMusicBg()
            scheduler.performWithDelayGlobal(
                function()
                    self:playTriggerLight()
                end,
                3.1,
                self:getModuleName()
            )
        end,
        1.3,
        self:getModuleName()
    )
end
-- respin 结束全部light动画
function CodeGameScreenHowlingMoonMachine:reSpinEndAllLightAction()
    local lightArray = self.m_respinView:getAllCleaningNode()

    for k, v in pairs(lightArray) do
        v:getLastNode():runAnim("actionframe1", false)
        self.m_respinView:createOneActionSymbol(v:getLastNode(), "actionframe1")
    end
end

-- lighting 完毕之后 播放动画
function CodeGameScreenHowlingMoonMachine:playLightEffectEnd()
    self:respinOver()
end

function CodeGameScreenHowlingMoonMachine:playTriggerLight(reSpinOverFunc)
    self:showAllLockNodelightAction()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- gLobalSoundManager:stopBackgroudMusic()

    self.m_chipList = self.m_respinView:getAllCleaningNode()
    --   self.m_jackPotBar:setVisible(false)
    util_setCsbVisible(self.m_wonThings, true)
    self.m_wonThings:findChild("m_lb_coin"):setString("0")
    --   util_setCsbVisible(self.m_wonBonusTimes,false)
    util_setCsbVisible(self.m_baseReSpinBar, false)
    local nDelayTime = #self.m_chipList * (0.1 + 0.85)
    self:playChipCollectAnim()
end

function CodeGameScreenHowlingMoonMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then

        scheduler.performWithDelayGlobal(
            function()
                self:playLightEffectEnd()
            end,
            0.1,
            self:getModuleName()
        )

        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(), chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_colIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol

    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = self:BaseMania_getLineBet() * self.m_lineCount

    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Grand
            addScore = jackpotScore + addScore
            nJackpotType = 4
        elseif score == "MAJOR" then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Major
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif score == "MINOR" then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Minor
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif score == "MINI" then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Mini
            addScore = jackpotScore + addScore
            nJackpotType = 1
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function fishFlyEndJiesuan()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim()
        else
            scheduler.performWithDelayGlobal(
                function()
                    self:showRespinJackpot(
                        nJackpotType,
                        util_formatCoins(jackpotScore, 12),
                        function()
                            self.m_playAnimIndex = self.m_playAnimIndex + 1
                            self:playChipCollectAnim()
                        end
                    )
                end,
                1,
                self:getModuleName()
            )
        end
    end

    local function fishFly()
        self.m_wonThings:showCollectCoin(util_formatCoins(self.m_lightScore, 30))

        fishFlyEndJiesuan()
    end

    chipNode:setLocalZOrder(10000 + self.m_playAnimIndex)

    local time = 0.4

    gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_spin_respin_RunOver.mp3")

    -- self:flySymblos(startPos, endPos, func, csbPath, actionName, time)
    self.m_respinView:createRsOverOneActionSymbol(chipNode, "actionframe3", self.m_clipParent)

    scheduler.performWithDelayGlobal(
        function()
            fishFly()
        end,
        time,
        self:getModuleName()
    )

    chipNode:getLastNode():runAnim("actionframe", true)
end

function CodeGameScreenHowlingMoonMachine:showRespinJackpot(index, coins, func)
    gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_show_JackPOt_view.mp3")
    local jackPotWinView = util_createView("CodeHowlingMoonSrc.HowlingMoonJackPotWinView",{machine = self})
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index, coins, func)
end

function CodeGameScreenHowlingMoonMachine:playRespinViewShowSound()
    -- gLobalSoundManager:playSound("DoubleDragonSounds/music_doubledragon_linghtning_frame.mp3")
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenHowlingMoonMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = nil
            if #self.m_runSpinResultData.p_reels == NORMAL_ROW_COUNT then
                if iRow <= 4 then
                    symbolType = self:getMatrixPosSymbolType(iRow, iCol)
                else
                    symbolType = math.random(0, 8)
                end
            else
                symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            end

            if symbolType == 94 then
                print("dada")
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end
function CodeGameScreenHowlingMoonMachine:triggerChangeRespinNodeInfo(respinNodeInfo)
    for k, v in pairs(respinNodeInfo) do
        if v.Type == nil then
            v.Type = math.random(0, 8) -- 随机信号
        end
    end
end

function CodeGameScreenHowlingMoonMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:initMachine(self)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    self:runNextReSpinReel()
                end
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--开始下次ReSpin
function CodeGameScreenHowlingMoonMachine:runNextReSpinReel()
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end
-- 重写Respinstar
function CodeGameScreenHowlingMoonMachine:showReSpinStart(func)
    scheduler.performWithDelayGlobal(
        function()
            if func then
                func()
            end
        end,
        1.2,
        self:getModuleName()
    )

    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

function CodeGameScreenHowlingMoonMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    scheduler.performWithDelayGlobal(
        function()
            self:showRespinOverView()
        end,
        1,
        self:getModuleName()
    )
end
function CodeGameScreenHowlingMoonMachine:showRespinOverView(effectData)
    gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_show_view.mp3")
    local strCoins = util_formatCoins(self.m_lightScore, 11)

    local view =
        self:showReSpinOver(
        strCoins,
        function()

            self:setReelSlotsNodeVisible(true)
            self:removeRespinNode()
            self:respinChangeReelGridCount(NORMAL_ROW_COUNT)
            self.m_iReelRowNum = 4
            self:findChild("black_bg"):setVisible(false)
            self:runCsbAction("idle")
            self.m_jackPotBar:setChangeWith(false)
            self.m_jackPotBar:hideIcons()
            self.m_jackPotBar:runCsbAction("animation0")
            self:findChild("Node_tittle"):setVisible(true)
            self.m_jackPotBar:setVisible(true)
            util_setCsbVisible(self.m_wonThings, false)
            -- util_setCsbVisible(self.m_wonBonusTimes,false)
            util_setCsbVisible(self.m_baseReSpinBar, false)
            self:hideAllLockNode()
            scheduler.performWithDelayGlobal(
                function()
                    self:triggerReSpinOverCallFun(self.m_lightScore)
                    self.m_lightScore = 0
                    self.m_isRespinOver = true
                    self.m_jackPotBar:updateMegaShow()
                end,
                1.2,
                self:getModuleName()
            )

            if not (self.m_bProduceSlots_InFreeSpin) then
                -- self.m_wonBonusTimes:norAction(false)
                -- self.m_wonBonusTimes:updateFreespinCount( globalData.slotRunData.freeSpinCount )
                self:changeBGRespinToNormal()
                self:transitionView()
                self:findChild("tishi" .. self.m_iBetLevel):setVisible(true)
            else
                -- self.m_wonBonusTimes:changeFreeSpinByCount(  )
                self:findChild("tishi" .. self.m_iBetLevel):setVisible(false)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
                self:changeBGRespinToFreeSpin()
                util_setCsbVisible(self.m_baseFreeSpinBar, true)
                self:transitionView()
            end
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 645)
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenHowlingMoonMachine:operaEffectOver()
    CodeGameScreenHowlingMoonMachine.super.operaEffectOver(self)

    if self.m_isRespinOver then
        self.m_isRespinOver = false
        --公共jackpot
        local midReel = self:findChild("sp_reel_2")
        local size = midReel:getContentSize()
        local worldPos = util_convertToNodeSpace(midReel,self)
        worldPos.x = worldPos.x + size.width / 2
        worldPos.y = worldPos.y + size.height / 2
        if G_GetMgr(ACTIVITY_REF.CommonJackpot) then
            G_GetMgr(ACTIVITY_REF.CommonJackpot):playEntryFlyAction(worldPos,function()

            end)
        end
    end
end

function CodeGameScreenHowlingMoonMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i = 1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

-- 背景变换方法
--- freeSpin To normal
function CodeGameScreenHowlingMoonMachine:changeBGFreeSpinToNormal()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin_normal")
end
---  FreeSpin To Respin
function CodeGameScreenHowlingMoonMachine:changeBGFreespinToRespin()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin_link")
end

--- Respin To normal
function CodeGameScreenHowlingMoonMachine:changeBGRespinToNormal()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "link_normal")
end
--- Respin To freespin
function CodeGameScreenHowlingMoonMachine:changeBGRespinToFreeSpin()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "link_freespin")
end

---  normal To FeeSpin
function CodeGameScreenHowlingMoonMachine:changeBGNormalToFreeSpin()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "nomal_freespin")
end

---  normal To Respin
function CodeGameScreenHowlingMoonMachine:changeBGNormalToRespin()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal_link")
end

function CodeGameScreenHowlingMoonMachine:transitionView()
    gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_spin_transition.mp3")
    self.m_respinStartAction:toAction(
        "actionframe",
        false,
        function()
            util_setCsbVisible(self.m_respinStartAction, false)
        end
    )
    util_setCsbVisible(self.m_respinStartAction, true)
end
--[[
    @desc: 处理 锁行
    author:{author}
    time:2019-01-08 21:55:18
    @return:
]]
function CodeGameScreenHowlingMoonMachine:hideAllLockNode()
    for k, v in pairs(self.m_lockNodeArray) do
        v:setVisible(false)
        v.actionType = 0
    end
end

function CodeGameScreenHowlingMoonMachine:showAllLockNode()
    scheduler.performWithDelayGlobal(
        function()
            for k, v in pairs(self.m_lockNodeArray) do
                v:IdleAction(false)
                scheduler.performWithDelayGlobal(
                    function()
                        v:setVisible(true)
                        v:updateLockLeftNum("")
                        gLobalSoundManager:playSound("HowlingMoonSounds/sound_HowlingMoon_showlock.mp3")
                    end,
                    0.2 * k,
                    self:getModuleName()
                )
            end

            scheduler.performWithDelayGlobal(
                function()
                    self:getShouldLockNodeShowNum()
                end,
                1,
                self:getModuleName()
            )
        end,
        0.7,
        self:getModuleName()
    )
end

function CodeGameScreenHowlingMoonMachine:showAllLockNodelightAction()
    for k, v in pairs(self.m_lockNodeArray) do
        if v:isVisible() then
            v:lightAction(false)
        end
    end
end

---返回没有锁的行个数
function CodeGameScreenHowlingMoonMachine:getLockNodeShowNum()
    local num = 0
    for k, v in pairs(self.m_lockNodeArray) do
        if v.actionType == 1 then
            num = num + 1
        end
    end
    return num
end

---返回应该锁行个数 断线用 第一次进入respin
function CodeGameScreenHowlingMoonMachine:getShouldLockNodeShowNum()
    self:showLeftLockNum()

    local alllockNum = self:getLockNodeShowNum() + 4 -- 本地已经解锁的个数

    local unlockedLines = self.m_runSpinResultData.p_rsExtraData.unlockedLines -- 服务器已经解锁的个数
    local lockedSymbols = self.m_runSpinResultData.p_rsExtraData.totalRewardSignals -- 服务器已经锁住的信号数

    local shouldUnLockLines = unlockedLines - alllockNum
    if shouldUnLockLines >= 0 and alllockNum ~= 8 then
        self:unlockedNode(shouldUnLockLines)
    end
end

-- 解锁
function CodeGameScreenHowlingMoonMachine:unlockedNode(shouldUnLockLines)
    for i = 1, shouldUnLockLines do
        for k, v in pairs(self.m_lockNodeArray) do
            if v:isVisible() and v.actionType == 0 then
                v.actionType = 1
                v:unLockAction(
                    false,
                    function()
                        v:setVisible(false)
                    end
                )
                break
            end
        end
    end
end

-- 解锁
function CodeGameScreenHowlingMoonMachine:unlockedOneNode(index)
    if self.m_lockNodeArray[index]:isVisible() and self.m_lockNodeArray[index].actionType ~= 1 then
        self.m_lockNodeArray[index]:unLockAction(
            false,
            function()
                self.m_lockNodeArray[index]:setVisible(false)
            end
        )
    end
    self.m_lockNodeArray[index].actionType = 1
end

-- 显示剩余个数
function CodeGameScreenHowlingMoonMachine:showLeftLockNum()
    local lightnum = 0
    local lockedSymbols = self.m_runSpinResultData.p_rsExtraData.totalRewardSignals -- 服务器已经锁住的信号数

    if not lockedSymbols then
        for i = 1, #self.m_runSpinResultData.p_reelsData do
            local reels = self.m_runSpinResultData.p_reelsData[i]
            for j = 1, #reels do
                local type = reels[j]
                if type == self.m_bnBaseType or type == self.SYMBOL_FIX_MINI or type == self.SYMBOL_FIX_MINOR or type == self.SYMBOL_FIX_MAJOR or type == self.SYMBOL_FIX_GRAND then
                    lightnum = lightnum + 1
                end
            end
        end
        lockedSymbols = lightnum
    end

    for k, v in pairs(self.m_lockNodeArray) do
        v:updateLockLeftNum(self.m_lockNumArray[k] - lockedSymbols, true)
    end
end

---
--设置bonus scatter 层级
function CodeGameScreenHowlingMoonMachine:getBounsScatterDataZorder(symbolType)
    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_fsScatterType then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.m_bnBaseType or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR or symbolType == self.SYMBOL_FIX_GRAND then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 1
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
--[[
    @desc: 飞信号方法
    author:{author}
    time:2018-12-26 11:32:59
]]
function CodeGameScreenHowlingMoonMachine:flySymblos(startPos, endPos, func, csbPath, actionName, flytimes)
    local flyNode = cc.Node:create()
    -- flyNode:setOpacity()
    self:addChild(flyNode, 30000) -- 是否添加在最上层
    local time = 0
    local count = 1
    local flyTime = 0.1
    if flytimes then
        flyTime = flytimes
    end
    for i = 1, count do
        self:runFlySymblosAction(flyNode, time * i, flyTime, startPos, endPos, i, csbPath, actionName)
    end
    performWithDelay(
        flyNode,
        function()
            if func then
                func()
            end
            flyNode:removeFromParent()
        end,
        flyTime + time * count
    )
end

function CodeGameScreenHowlingMoonMachine:runFlySymblosAction(flyNode, time, flyTime, startPos, endPos, index, csbPath, actionName)
    local actionList = {}
    local opacityList = {185, 145, 105, 65, 25, 1, 1, 1, 1, 1}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node, csbAct = util_csbCreate(csbPath)
    -- node:setVisible(false)
    util_csbPlayForKey(csbAct, actionName, true)

    util_setCascadeOpacityEnabledRescursion(node, true)
    node:setOpacity(opacityList[index])
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            --     node:setVisible(true)
            node:runAction(cc.ScaleTo:create(flyTime, self.m_littleSymbolScaleSize))
        end
    )
    flyNode:addChild(node, 6 - index)
    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, cc.p(endPos))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:setLocalZOrder(index)
        end
    )

    node:runAction(cc.Sequence:create(actionList))
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenHowlingMoonMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    -- 关卡特殊处理 不显示scatter赢钱线动画
    if lineValue.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        print("scatter")
    else
        BaseMachineGameEffect.showLineFrameByIndex(self, winLines, frameIndex)
    end
end

function CodeGameScreenHowlingMoonMachine:getMaxContinuityBonusCol()
    local maxColIndex = 0

    local isContinuity = true

    for iCol = 2, self.m_iReelColumnNum do
        local bonusNum = 0

        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
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

function CodeGameScreenHowlingMoonMachine:isPlayTipAnima(matrixPosY, matrixPosX, node)
    local nodeData = self.m_reelRunInfo[matrixPosY]:getSlotsNodeInfo()

    if nodeData ~= nil and #nodeData ~= 0 then
        for i = 1, #nodeData do
            if self.m_bigSymbolInfos[node.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[node.p_symbolType]
                local startRowIndex = node.p_rowIndex
                local endRowIndex = node.p_rowIndex + symbolCount
                if nodeData[i].x >= matrixPosX and nodeData[i].x <= endRowIndex and nodeData[i].y == matrixPosY then
                    if nodeData[i].bIsPlay == true then
                        return true
                    end
                end
            else
                if nodeData[i].x == matrixPosX and nodeData[i].y == matrixPosY then
                    if nodeData[i].bIsPlay == true then
                        if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            if matrixPosY > self:getMaxContinuityBonusCol() then
                                return false
                            else
                                return true
                            end
                        else
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function CodeGameScreenHowlingMoonMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        local childs = self:getReelParent(iCol):getChildren()
        for j = 1, #childs do
            local node = childs[j]
            node:setVisible(status)
        end
        local slotParentBig = self:getReelBigParent(iCol)
        if slotParentBig then
            local childs = slotParentBig:getChildren()
            for j = 1, #childs do
                local node = childs[j]
                node:setVisible(status)
            end
        end
    end

    --如果为空则从 clipnode获取
    local childs = self.m_clipParent:getChildren()
    local childCount = #childs

    for i = 1, childCount, 1 do
        local slotsNode = childs[i]
        if slotsNode:getTag() > SYMBOL_FIX_NODE_TAG and slotsNode:getTag() < SYMBOL_NODE_TAG then
            slotsNode:setVisible(status)
        end
    end

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(status)
            end
        end
    end
end

---
-- 处理spin 返回结果
function CodeGameScreenHowlingMoonMachine:spinResultCallFun(param)
    CodeGameScreenHowlingMoonMachine.super.spinResultCallFun(self,param)

    self.m_jackPotBar:resetCurRefreshTime()
end

function CodeGameScreenHowlingMoonMachine:initGameStatusData(gameData)
    CodeGameScreenHowlingMoonMachine.super.initGameStatusData(self,gameData)
end

function CodeGameScreenHowlingMoonMachine:updateReelGridNode(symbolNode)
    if symbolNode.p_symbolType == self.SYMBOL_FIX_GRAND then
        symbolNode:getCcbProperty("node_grand"):setVisible(self.m_jackpot_status == "Normal")
        symbolNode:getCcbProperty("node_mega"):setVisible(self.m_jackpot_status == "Mega")
        symbolNode:getCcbProperty("node_super"):setVisible(self.m_jackpot_status == "Super")
    end
end

-------------------------------------------------公共jackpot-----------------------------------------------------------------------

--[[
    更新公共jackpot状态
]]
function CodeGameScreenHowlingMoonMachine:updataJackpotStatus(params)
    local totalBetID = globalData.slotRunData:getCurTotalBet()

    self.m_jackpot_status = "Normal" -- "Mega" "Super"

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        self:updateJackpotBarMegaShow()
        return
    end

    if self.m_isJackpotEnd then
        self:updateJackpotBarMegaShow()
        return
    end

    if not mgr:isDownloadRes() then
        self:updateJackpotBarMegaShow()
        return
    end
    
    local data = mgr:getRunningData()
    if not data or not next(data) then
        self:updateJackpotBarMegaShow()
        return
    end

    local levelData = data:getLevelDataByBet(totalBetID)
    local levelName = levelData.p_name
    self.m_jackpot_status = levelName
    self:updateJackpotBarMegaShow()
end

function CodeGameScreenHowlingMoonMachine:updateJackpotBarMegaShow()
    self.m_jackPotBar:updateMegaShow()
end

function CodeGameScreenHowlingMoonMachine:getCommonJackpotValue(_status, _addTimes)
    _addTimes = math.floor(_addTimes)
    local value     = 0
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if _status == "Mega" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Mega)
        end
    elseif _status == "Super" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Super)
        end
    end

    return value
end

--[[
    新增顶栏和按钮
]]
function CodeGameScreenHowlingMoonMachine:initTopCommonJackpotBar()
    if not ACTIVITY_REF.CommonJackpot then
        return 
    end

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        return
    end

    local commonJackpotTitle = mgr:createTitleNode()

    if not commonJackpotTitle then
        return
    end
    self.m_commonJackpotTitle = commonJackpotTitle
    self:addChild(self.m_commonJackpotTitle, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    local titlePos = util_getConvertNodePos(self.m_topUI:findChild("TopUI_down"), self)
    local topSpSize = self.m_commonJackpotTitle:findChild("sp_Jackpot1"):getContentSize()
    titlePos.y = titlePos.y - topSpSize.height*0.3
    self.m_commonJackpotTitle:setPosition(titlePos)
    self.m_commonJackpotTitle:setScale(globalData.topUIScale)
    
end

return CodeGameScreenHowlingMoonMachine
