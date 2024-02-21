---
-- island li
-- 2019年1月26日
-- CodeGameScreenBuffaloWildMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = require "Levels.BaseMachine"

local CodeGameScreenBuffaloWildMachine = class("CodeGameScreenBuffaloWildMachine", BaseSlotoManiaMachine)

CodeGameScreenBuffaloWildMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBuffaloWildMachine.SYMBOL_TYPE_NINE = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1  + 2  -- 自定义的小块类型
CodeGameScreenBuffaloWildMachine.SYMBOL_TYPE_TEN = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1  + 1
CodeGameScreenBuffaloWildMachine.SYMBOL_TYPE_BUFFALO_COIN = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  + 1 -- 自定义的小块类型
CodeGameScreenBuffaloWildMachine.UNLOCK_MINI_MACHINE = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenBuffaloWildMachine.ADD_LAST_FREESPINS = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenBuffaloWildMachine.COLLECT_BUFFALO_COIN = GameEffect.EFFECT_SELF_EFFECT - 3

CodeGameScreenBuffaloWildMachine.FLY_SYMBOL_EFFECT = GameEffect.EFFECT_SELF_EFFECT

local DESIGN_HEIGHT = 1370
local FIT_HEIGHT_MAX = 1233
local FIT_HEIGHT_MIN = 1136

-- 构造函数
function CodeGameScreenBuffaloWildMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function CodeGameScreenBuffaloWildMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBuffaloWildMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BuffaloWild"
end

function CodeGameScreenBuffaloWildMachine:getNetWorkModuleName()
    return "AmericanBuffaloV2"
end

function CodeGameScreenBuffaloWildMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainPosY = (uiBH - uiH - 30) / 2
    local mainHeight = display.height - uiH - uiBH
    local designHeight = DESIGN_HEIGHT - uiH - uiBH
    local mainScale = 1

    if display.height < DESIGN_HEIGHT then
        mainScale = mainHeight / designHeight
        -- mainScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 10)
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end

    if globalData.slotRunData.isPortrait then
        local bangHeight =  util_getBangScreenHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - bangHeight )
    end
    
end

function CodeGameScreenBuffaloWildMachine:initUI()

    self.m_freespinBar = util_createView("CodeBuffaloWildSrc.BuffaloFreeSpinBar")
    self:findChild("freespin_bar"):addChild(self.m_freespinBar)
    self.m_freespinBar:setVisible(false)

    self.m_buffaloLogo = util_spineCreateDifferentPath("BuffaloWild_logo", "BuffaloWild_logo", true, true)
    self:findChild("logo"):addChild(self.m_buffaloLogo)
    util_spinePlay(self.m_buffaloLogo, "animation", true)
    self.m_buffaloLogo:setScale(0.9)

    self.m_buffaloRun = util_spineCreateDifferentPath("BuffaloWild_guochang", "BuffaloWild_guochang", true, true)
    self:addChild(self.m_buffaloRun, 10000)
    self.m_buffaloRun:setPosition(display.width * 0.5, 0)
    self.m_buffaloRun:setVisible(false)

    self.m_collectNum = util_createView("CodeBuffaloWildSrc.BuffaloWildCollectNum")
    self:findChild("buffalo_icon"):addChild(self.m_collectNum)
    self.m_collectNum:setVisible(false)

    self.m_collectTittle = util_createView("CodeBuffaloWildSrc.BuffaloWildTittle")
    self:findChild("buffalo_tittle"):addChild(self.m_collectTittle)
    self.m_collectTittle:setVisible(false)

    self.m_collectView = util_createView("CodeBuffaloWildSrc.BuffaloWildCollectView",self)
    self:findChild("node_collect"):addChild(self.m_collectView)

    local index = 1
    if self.m_vecMiniWheel == nil then
        self.m_vecMiniWheel = {}
    end
    while true do
        local node = self:findChild("mini_wheel_" .. index )
        if node ~= nil then
            local data = {}
            data.index = index
            data.parent = self
            data.func = function(vecBuffalo, hasFiveOfKind)
                for i = #vecBuffalo, 1, -1 do
                    self.m_collectList[#self.m_collectList + 1] = vecBuffalo[i]
                    table.remove(vecBuffalo, i)
                end
                if hasFiveOfKind == true then
                    self.m_bHasFiveOfKind = hasFiveOfKind
                end
                self.m_wheelDownNum = self.m_wheelDownNum + 1
                if self.m_wheelDownNum == self.m_lastRunWheelNum then
                    self:allMiniMachineDown()
                end
            end
            local wheel = util_createView("CodeBuffaloWildSrc.GameScreenBuffaloWildMini", data)
            self.m_vecMiniWheel[index] = wheel
            node:addChild(wheel)
            wheel:setVisible(false)

            if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
                self.m_bottomUI.m_spinBtn:addTouchLayerClick(wheel.m_touchSpinLayer)
            end
        else
            break
        end
        index = index + 1
    end

    if display.height > DESIGN_HEIGHT then
        local nodeLogo = self:findChild("logo")
        local wheel = self:findChild("wheel")
        local freespin = self:findChild("freespin")
        local posY = (display.height - DESIGN_HEIGHT)
        nodeLogo:setPositionY(nodeLogo:getPositionY() + posY * 0.12)
        -- wheel:setPositionY(wheel:getPositionY() - posY * 0.5)
        if display.height >= 1550 then
            freespin:setScale(1550 / DESIGN_HEIGHT)
        else
            freespin:setScale(display.height / DESIGN_HEIGHT)
        end

    end

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
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
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundName = "BuffaloWildSounds/sound_buffalo_wild_".. soundIndex .. ".mp3"
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenBuffaloWildMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "BuffaloWildSounds/sound_buffalo_wild_scatter_"..i..".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenBuffaloWildMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )

        gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end

        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenBuffaloWildMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
    self:getCurrSpinMode() ~= RESPIN_MODE
    then

        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end
function CodeGameScreenBuffaloWildMachine:unlockHigherBet()

    if globalData.slotRunData.m_isAutoSpinAction or self.m_isRunningEffect or self:getGameSpinStage( ) > IDLE then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenBuffaloWildMachine:getMinBet( )
    local minBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

function CodeGameScreenBuffaloWildMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if  betCoin == nil or betCoin < self.m_BetChooseGear then
        self.m_iBetLevel = 0
        self.m_collectView:showLock()
    else
        self.m_iBetLevel = 1
        self.m_collectView:showUnLock()
    end
end

function CodeGameScreenBuffaloWildMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:updateBetLevel()

    if self.m_bProduceSlots_InFreeSpin == true and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == false then
        self:initFreeSpinMachine()
        self.m_iFreeSpinTimes = 0
        self.m_reconnectGame = true
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
    end
end

function CodeGameScreenBuffaloWildMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        if perBetLevel > self.m_iBetLevel then

        elseif perBetLevel < self.m_iBetLevel then

        end

    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenBuffaloWildMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBuffaloWildMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_TYPE_BUFFALO_COIN then
        return "Socre_BuffaloWild_Bonus"
    elseif symbolType == self.SYMBOL_TYPE_NINE  then
        return "Socre_BuffaloWild_11"
    elseif symbolType == self.SYMBOL_TYPE_TEN  then
        return "Socre_BuffaloWild_10"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBuffaloWildMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_NINE, count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_TEN, count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_TYPE_BUFFALO_COIN, count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenBuffaloWildMachine:MachineRule_initGame(  )
    local selfMakeData =  self.m_runSpinResultData.p_selfMakeData
    if selfMakeData then
        if selfMakeData.newTask then
            self.m_collectView:initData(selfMakeData.newTask)
        else
            self.m_collectView:initData(selfMakeData.task)
        end
        -- current:0
        -- resetSpinTimes:55
        -- signal:3
        -- spinTimes:0
        -- target:100
        -- taskBetCoins:0
        -- type:"collect"
    else

    end
end

--
--单列滚动停止回调
--
function CodeGameScreenBuffaloWildMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)

end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBuffaloWildMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.m_freespinBar:changeFreeSpinByCount()
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBuffaloWildMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")

end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenBuffaloWildMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_fs_star.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes, function()
                self.m_iFreeSpinTimes = 0
                self.m_buffaloRun:setVisible(true)
                gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_buffalo_run.mp3")
                util_spinePlay(self.m_buffaloRun, "actionframe", false)
                util_spineEndCallFunc(self.m_buffaloRun, "actionframe", function ()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
                performWithDelay(self, function()
                    self:initFreeSpinMachine()
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")
                end, 2)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()
    end,0.5)

end

function CodeGameScreenBuffaloWildMachine:initFreeSpinMachine()
    self:findChild("wheel"):setVisible(false)
    self.m_buffaloLogo:setVisible(false)
    self.m_collectNum:setVisible(true)
    self.m_collectView:setVisible(false)
    local collectNum = self.m_runSpinResultData.p_selfMakeData.hearts
    if collectNum == nil then
        collectNum = 0
    end
    self.m_collectNum:initCollectNum(collectNum)
    self.m_collectTittle:setVisible(true)
    self.m_freespinBar:setVisible(true)

    self.m_lastRunWheelNum = self.m_runSpinResultData.p_selfMakeData.setNum
    self.m_wheelDownNum = 0
    self.m_bHasFiveOfKind = false
    if self.m_collectList == nil then
        self.m_collectList = {}
    end

    for i = 1, #self.m_vecMiniWheel, 1 do
        local wheel = self.m_vecMiniWheel[i]
        wheel:setVisible(true)
        wheel:initLock(self.m_lastRunWheelNum, self.m_runSpinResultData.p_selfMakeData.unlockSetHearts)
        if self.m_runSpinResultData.p_selfMakeData.sets == nil or self.m_runSpinResultData.p_selfMakeData.sets[i] == nil then
            wheel:initRandomSlotNodes()
        else
            wheel:initSlotNode(self.m_runSpinResultData.p_selfMakeData.sets[i])
        end
    end

    if self.m_runSpinResultData.p_selfMakeData.lockWilds ~= nil and #self.m_runSpinResultData.p_selfMakeData.lockWilds > 0 then
        for i = 1, self.m_lastRunWheelNum, 1 do
            self.m_vecMiniWheel[i]:lockWild(self.m_runSpinResultData.p_selfMakeData.lockWilds)
        end
    end

    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
end

function CodeGameScreenBuffaloWildMachine:allMiniMachineDown()
    self.m_wheelDownNum = 0
    if #self.m_collectList > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_selfEffectType = self.COLLECT_BUFFALO_COIN
        table.insert( self.m_gameEffects, 1, selfEffect)
    end

    if self.m_bHasFiveOfKind == true then
        self.m_bHasFiveOfKind = false
        self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

    self:reelDownNotifyChangeSpinStatus()
    self:delaySlotReelDown()
    self:updateQuestDone()
    self:reelDownNotifyPlayGameEffect()
    if self.m_iOnceSpinLastWin > 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin, false})
    end
end

--刷新quest任务
function CodeGameScreenBuffaloWildMachine:updateQuestDone()
    --TODO  后续考虑优化修改 , 检测是否有quest effect ， 将其位置信息放到quest 前面
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == true then
        self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    end
    local questEffect = GameEffectData:create()
    questEffect.p_effectType =  GameEffect.EFFECT_QUEST_DONE  --创建属性
    questEffect.p_effectOrder = 999999  --动画播放层级 用于动画播放顺序排序
    self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
end


function CodeGameScreenBuffaloWildMachine:normalSpinBtnCall( )
    self:setMaxMusicBGVolume( )
    self:removeSoundHandler( )


    BaseSlotoManiaMachine.normalSpinBtnCall(self)

end

function CodeGameScreenBuffaloWildMachine:slotReelDown( )
    BaseSlotoManiaMachine.slotReelDown(self)
    self:removeSoundHandler( )
    self:checkTriggerOrInSpecialGame(function(  )
        performWithDelay(self,function()
            if not self.m_isInBonusWheel then
                self:reelsDownDelaySetMusicBGVolume( )
            end
        end,0.1)

    end)
    -- if self.m_collectList and #self.m_collectList then
    --     self:collectAnima()
    -- end
end

function CodeGameScreenBuffaloWildMachine:playEffectNotifyNextSpinCall( )
    self:removeSoundHandler( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( )
    end)

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end

---
-- 显示free spin over 动画
function CodeGameScreenBuffaloWildMachine:showEffect_FreeSpinOver()

    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")
    if self.m_iOnceSpinLastWin == 0 then
        self.m_freeSpinOverCurrentTime = 2
    end

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
        self.m_fsOverHandlerID =scheduler.scheduleGlobal(function()
            if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
                self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
            else
                self:showEffect_newFreeSpinOver()
            end
        end,0.1)
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function CodeGameScreenBuffaloWildMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_fs_over.mp3")
    performWithDelay(self, function()
        gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_fs_over_window.mp3")
        self.m_reconnectGame = false
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
        local view = self:showFreeSpinOver( strCoins,
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_buffalo_run.mp3")
                self.m_buffaloRun:setVisible(true)
                util_spinePlay(self.m_buffaloRun, "actionframe", false)
                util_spineEndCallFunc(self.m_buffaloRun, "actionframe", function ()
                    self:triggerFreeSpinOverCallFun()
                end)
                performWithDelay(self, function()
                    self:hideFreeSpinUI()
                end, 2)
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.8,sy=0.8},655)
    end, 2.8)


end

function CodeGameScreenBuffaloWildMachine:hideFreeSpinUI()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    self:findChild("wheel"):setVisible(true)
    self.m_buffaloLogo:setVisible(true)
    self.m_collectView:setVisible(true)
    self.m_collectNum:setVisible(false)
    self.m_collectNum:initCollectNum(0)
    self.m_collectTittle:setVisible(false)
    self.m_freespinBar:setVisible(false)
    for i = #self.m_vecMiniWheel, 1, -1 do
        local wheel = self.m_vecMiniWheel[i]
        wheel:setWheelLock()
        wheel:setVisible(false)
    end
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBuffaloWildMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    self.m_winSoundsId = nil



    return false -- 用作延时点击spin调用
end

function CodeGameScreenBuffaloWildMachine:callSpinBtn( )

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1
    -- freespin时不做钱的计算
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
        self:removeSoundHandler( )
        self:checkTriggerOrInSpecialGame(function(  )
            self:reelsDownDelaySetMusicBGVolume( )
        end)
    end

    BaseMachine.callSpinBtn(self)
end

----
--- 处理spin 成功消息
--
function CodeGameScreenBuffaloWildMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" then
        release_print("消息返回胡来了")

        if spinData.result.selfData ~= nil and spinData.result.selfData.sets ~= nil then
            local resultDatas = spinData.result.selfData.sets
            for i = 1, #resultDatas, 1 do
                local resultData = resultDatas[i]
                resultData.bet = 1
                self.m_vecMiniWheel[i]:netWorkCallFun(resultData)
            end
        end

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        -- self:updateNetWorkData()
        if self.m_bProduceSlots_InFreeSpin ~= true then
            self:updateNetWorkData()
        end
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenBuffaloWildMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenBuffaloWildMachine:MachineRule_afterNetWorkLineLogicCalculate()


    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBuffaloWildMachine:addSelfEffect()

    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.unlockSetNum ~= nil
      and self.m_runSpinResultData.p_selfMakeData.unlockSetNum > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.UNLOCK_MINI_MACHINE -- 动画类型
        self.m_unlockMiniMachine = true
    elseif self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.triggerLockWilds ~= nil then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.ADD_LAST_FREESPINS -- 动画类型
        self.m_unlockMiniMachine = true
    end
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    if self.m_iBetLevel == 1  and selfMakeData and selfMakeData.task then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if node and node.p_symbolType == selfMakeData.task.signal then
                    if not self.m_collectAnimaList then
                        self.m_collectAnimaList = {}
                    end
                    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                    self.m_collectAnimaList[#self.m_collectAnimaList + 1] = {startPos=startPos,symbolType=node.p_symbolType}--:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                end
            end
        end
        if self.m_collectAnimaList and #self.m_collectAnimaList > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FLY_SYMBOL_EFFECT

            --是否触发收集小游戏
            if selfMakeData.taskWheels then -- true or
                self.m_bHaveBonusGame = true
            end
        else
            self.m_collectView:initData(self.m_runSpinResultData.p_selfMakeData.task)
        end
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBuffaloWildMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.UNLOCK_MINI_MACHINE then
        self:unlockMiniMachine(effectData)
    end
    if effectData.p_selfEffectType == self.COLLECT_BUFFALO_COIN then
        self:collectBuffaloCoin(effectData)
    end
    if effectData.p_selfEffectType == self.ADD_LAST_FREESPINS then
        self:lockColWild(effectData, true)
    end

    if effectData.p_selfEffectType == self.FLY_SYMBOL_EFFECT then
        self:collectAnima(effectData)
    end

	return true
end

CodeGameScreenBuffaloWildMachine.m_effectDataList = nil
function CodeGameScreenBuffaloWildMachine:collectAnima(effectData)
    if not self.m_effectDataList then
        self.m_effectDataList = {}
    end
    self.m_effectDataList[#self.m_effectDataList+1] = effectData
    self.m_isInBonusWheel = true
    local endPos = self.m_collectView:getCollectPos()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_collect_item.mp3")
    for i = #self.m_collectAnimaList, 1, -1 do
        local nodeData = self.m_collectAnimaList[i]
        local newStartPos = self:convertToNodeSpace(nodeData.startPos)
        local flyNode = util_createAnimation("BuffaloWild_collect_"..nodeData.symbolType..".csb")--self:getSlotNodeBySymbolType(node.p_symbolType)
        if i == 1 then
            flyNode.m_isLastSymbol = true
        end
        flyNode:playAction("actionframe")
        self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        flyNode:setPosition(newStartPos)
         -- gLobalSoundManager:setBackgroundMusicVolume(0.2)
         gLobalSoundManager:playSound("BuffaloWildSounds/buffaloWild_collect_collect1.mp3",false, function( )
            -- gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        print("------collect symbol index----"..i)
        -- performWithDelay(self, function()
            local leftTime = selfData.task.resetSpinTimes - selfData.task.spinTimes
            local taskData = clone(selfData.task)
            if not self.m_bHaveBonusGame and flyNode.m_isLastSymbol and leftTime > 0 then
                -- performWithDelay(self,function()
                    self:clearEffect(effectData)
                -- end,0.3)
            end
            local bez = cc.BezierTo:create(0.7,{cc.p(nodeData.startPos.x + (nodeData.startPos.x - endPos.x) * 0.5, nodeData.startPos.y), cc.p(endPos.x, nodeData.startPos.y), endPos})
            local callback = function()
                if flyNode.m_isLastSymbol == true then
                    print("=====collect end index========"..i)
                    -- self.m_collectView:checkBeforeIsOver()
                    self.m_collectView:updateData(taskData,function()
                        if leftTime <= 0 and not self.m_bHaveBonusGame then
                            self:clearEffect(effectData)
                        end
                        if self.m_bHaveBonusGame then
                            self:clearCurMusicBg()
                            self.m_bHaveBonusGame = false
                            performWithDelay(self,function()
                                local showWheelWin = function()
                                    self:showWheelWinView(function()
                                        self.m_wheelView:showOver(function()
                                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                                            self:resetMusicBg()
                                            self:clearEffect(effectData)
                                        end)
                                    end)

                                end
                                self:showBigWheel(showWheelWin)
                            end,2)
                        end
                    end)
                end
            end
            flyNode:runAction(cc.Sequence:create(bez, cc.CallFunc:create(function()
                callback()
            end), cc.CallFunc:create(function()
                flyNode:removeFromParent()
            end)))
        -- end, 0.2)
    end


    self.m_collectAnimaList = {}
end
function CodeGameScreenBuffaloWildMachine:clearEffect(effectData)
    self.m_isInBonusWheel = false
    for i=1,#self.m_effectDataList do
        if self.m_effectDataList[i] then
            self.m_effectDataList[i].p_isPlay = true
        end
    end
    -- effectData.p_isPlay = true
    -- for i=1,#self.m_gameEffects do
    --     local effectData2 = self.m_gameEffects[i]
    --     if effectData2.p_effectType == GameEffect.EFFECT_SELF_EFFECT and not effectData2.p_isPlay then
    --         -- effectData2.p_isPlay = true
    --         print("----------")
    --     end
    -- end
    self.m_effectDataList = {}
    self:playGameEffect()
end

function CodeGameScreenBuffaloWildMachine:showWheelWinView(callback)
    local view = util_createView("CodeBuffaloWildSrc.BuffaloWildWheelWinView",self.m_runSpinResultData.p_selfMakeData.taskCompleteCoins,callback)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
end

function CodeGameScreenBuffaloWildMachine:showBigWheel(callback)
    self.m_wheelView = util_createView("CodeBuffaloWildSrc.BuffaloWildWheelView",self.m_runSpinResultData.p_selfMakeData,callback)
    -- self:findChild("node_wheel"):addChild(self.m_wheelView)
    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_wheelView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(self.m_wheelView)
end
function CodeGameScreenBuffaloWildMachine:lockColWild(effectData, unlockWheel)
    local playEffect = function()
        gLobalSoundManager:setBackgroundMusicVolume(0.2)
        gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_freespin_move.mp3",false, function( )
            -- gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        local addTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount

        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
        end
        local view = self:showFreeSpinMore( nil,function()
            performWithDelay(self, function()
                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                self.m_freespinBar:changeFreeSpinTimes()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, 0.5)
        end,true)
        view:findChild("addTimes_1"):setVisible(false)
        view:findChild("addTimes_2"):setVisible(false)
        view:findChild("addTimes_"..addTimes):setVisible(true)

    end
    if self.m_runSpinResultData.p_selfMakeData.triggerLockWilds ~= nil then
        gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_lock_wild.mp3")
        for i = 1, self.m_lastRunWheelNum, 1 do
            self.m_vecMiniWheel[i]:lockWildAnimation(self.m_runSpinResultData.p_selfMakeData.triggerLockWilds)
        end
        for i = self.m_lastRunWheelNum + 1, self.m_runSpinResultData.p_selfMakeData.setNum, 1 do
            self.m_vecMiniWheel[i]:lockWildAnimation(self.m_runSpinResultData.p_selfMakeData.lockWilds)
        end
        performWithDelay(self, function()
            playEffect()
        end, 1.8)
    elseif unlockWheel == true then
        gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_lock_wild.mp3")
        for i = 1, self.m_lastRunWheelNum, 1 do
            self.m_vecMiniWheel[i]:lockWildAnimation()
        end
        for i = self.m_lastRunWheelNum + 1, self.m_runSpinResultData.p_selfMakeData.setNum, 1 do
            self.m_vecMiniWheel[i]:lockWildAnimation(self.m_runSpinResultData.p_selfMakeData.lockWilds)
        end
        performWithDelay(self, function()
            playEffect()
        end, 1.8)
    end

end

function CodeGameScreenBuffaloWildMachine:unlockMiniMachine(effectData)
    local wheelNum = self.m_runSpinResultData.p_selfMakeData.setNum
    local unlockNum = self.m_runSpinResultData.p_selfMakeData.unlockSetNum
    local lastNum = wheelNum - unlockNum
    gLobalSoundManager:setBackgroundMusicVolume(0.2)
    gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_unlock_wild.mp3")
    for i = 1, unlockNum, 1 do
        local func = nil
        if i == unlockNum then
            func = function()
                self:lockColWild(effectData, true)
            end
        end
        self.m_vecMiniWheel[lastNum + i]:unlock(func)
    end
end

function CodeGameScreenBuffaloWildMachine:collectBuffaloCoin(effectData)
    local endPos = self.m_collectNum:getCollectPos()
    if self.m_collectList and #self.m_collectList > 0 then
        gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_collect_bonus.mp3")
        -- local delayTime = 0.1
        local bQuickSpin = false
        if self.m_unlockMiniMachine ~= true then
            if self.m_runSpinResultData.p_selfMakeData.triggerLockWilds ~= nil then
            else
                bQuickSpin = true
                -- delayTime = 0
            end
        end
        for i = #self.m_collectList, 1, -1 do
            local node = self.m_collectList[i]
            local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
            local newStartPos = self:convertToNodeSpace(startPos)
            local coins = self:getSlotNodeBySymbolType(self.SYMBOL_TYPE_BUFFALO_COIN)
            if i == 1 then
                coins.m_isLastSymbol = true
            end
            self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
            coins:setPosition(newStartPos)
            coins:setScale(0.46 * self.m_machineRootScale)
           
            local collectNum = self.m_runSpinResultData.p_selfMakeData.hearts
            coins:runAnim("shouji")
            
            if coins.m_isLastSymbol == true and bQuickSpin == true then
                effectData.p_isPlay = true
                self:playGameEffect()
            end

            -- local delayNode = cc.Node:create()
            -- self:addChild(delayNode)
            -- performWithDelay(delayNode, function()
            --     delayNode:removeFromParent()
                if coins.m_isLastSymbol == true and self.m_unlockMiniMachine ~= true then
                    self:lockColWild(effectData)
                end

                local bez =
                cc.BezierTo:create(
                0.5,
                {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
                local scaleTo = cc.ScaleTo:create(0.5, 0.672 * self.m_machineRootScale)
                local callback = function()
                    if coins.m_isLastSymbol == true then

                        self.m_collectNum:collect(collectNum)
                        if self.m_unlockMiniMachine == true then
                            self.m_unlockMiniMachine = false
                            performWithDelay(self, function()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end, 1)
                        end
                    end

                end

                coins:runAction(cc.Sequence:create(cc.Spawn:create(bez, scaleTo), cc.CallFunc:create(function()
                    callback()
                end), cc.CallFunc:create(function()

                    coins:removeFromParent()
                    local symbolType = coins.p_symbolType
                    self:pushSlotNodeToPoolBySymobolType(symbolType, coins)
                end)))
            -- end,delayTime)
            table.remove(self.m_collectList, i)
        end
    end
end

function CodeGameScreenBuffaloWildMachine:beginReel()
    --下次spin变换状态
    if self.m_runSpinResultData.p_selfMakeData.newTask then
        self.m_collectView:initData(self.m_runSpinResultData.p_selfMakeData.newTask)
    end

    if self.m_bProduceSlots_InFreeSpin == true then
        local effectLen = #self.m_gameEffects
        for i = 1, effectLen, 1 do
            self.m_gameEffects[i] = nil
        end
        self:clearWinLineEffect()

        if self.m_vecGetLineInfo ~= nil and #self.m_vecGetLineInfo > 0 then
            for lineIndex = #self.m_vecGetLineInfo , 1, -1 do
                local value = self.m_vecGetLineInfo[lineIndex]
                value:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value

                self.m_vecGetLineInfo[lineIndex] = nil
            end
        end

        self:requestSpinResult()
        self.m_lastRunWheelNum = self.m_runSpinResultData.p_selfMakeData.setNum
        for i = 1, self.m_lastRunWheelNum, 1 do
            self.m_vecMiniWheel[i]:beginReel()
        end
    else
        BaseSlotoManiaMachine.beginReel(self)
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBuffaloWildMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end

function CodeGameScreenBuffaloWildMachine:operaQuicklyStopReel( )
    if self.m_bProduceSlots_InFreeSpin == true then
        return
    end
    BaseSlotoManiaMachine.operaQuicklyStopReel(self)
end

function CodeGameScreenBuffaloWildMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE



    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        local animName = slotNode:getLineAnimName()

        slotNode:runAnim(animName)
    end
    return slotNode
end

return CodeGameScreenBuffaloWildMachine






