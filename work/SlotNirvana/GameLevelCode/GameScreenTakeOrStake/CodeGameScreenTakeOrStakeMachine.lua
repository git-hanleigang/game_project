---
-- island li
-- 2019年1月26日
-- CodeGameScreenTakeOrStakeMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "TakeOrStakePublicConfig"
local BaseMachine = require "Levels.BaseMachine"
local SendDataManager = require "network.SendDataManager"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenTakeOrStakeMachine = class("CodeGameScreenTakeOrStakeMachine", BaseNewReelMachine)

CodeGameScreenTakeOrStakeMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenTakeOrStakeMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94
CodeGameScreenTakeOrStakeMachine.SYMBOL_SCORE_10 = 9

-- base随机wild玩法
CodeGameScreenTakeOrStakeMachine.EFFECT_BASE_WILD   = GameEffect.EFFECT_SELF_EFFECT - 1
-- base 收集BONUS分数
CodeGameScreenTakeOrStakeMachine.EFFECT_BASE_COLLECT_BONUS = GameEffect.EFFECT_SELF_EFFECT - 2

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 构造函数
function CodeGameScreenTakeOrStakeMachine:ctor()
    CodeGameScreenTakeOrStakeMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_isShowOutGame = false
    self.m_isShowSystemView = false
    self.m_randomWildData = {} --随机wild相关数据
    self.m_isDuanXian = false -- 是否是断线进来的 用于社交玩法 断线的界面显示
    self.m_isQuicklyStop = false --是否点击快停 
    self.m_bigWinEvent = {} --临时存储大赢事件
    --切换后台的时间戳
    self.m_timeInBack = 0
    self.m_roomDataClone = {}
    self.m_boxNums = 24
    self.m_isTriggerLongRun = false --是否触发了快滚
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

    self.m_publicConfig = PublicConfig


    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")
 
    --init
    self:initGame()
end

function CodeGameScreenTakeOrStakeMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("TakeOrStakeConfig.csv", "LevelTakeOrStakeConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenTakeOrStakeMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "TakeOrStake"  
end

--[[
    初始化房间列表
]]
function CodeGameScreenTakeOrStakeMachine:initRoomList()
    --房间列表
    self.m_roomList = util_createView("CodeTakeOrStakeSrc.TakeOrStakeRoomListView", {machine = self})
    self:findChild("roomList"):addChild(self.m_roomList)
    self.m_roomData = self.m_roomList.m_roomData
end

function CodeGameScreenTakeOrStakeMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    --初始化房间列表
    self:initRoomList()

    --收集分数
    self.m_collectSorce = util_createAnimation("TakeOrStake_Credits.csb")
    self:findChild("credits"):addChild(self.m_collectSorce)
    self.m_shoujiTips = util_createAnimation("TakeOrStake_CreditsTips.csb")
    self.m_collectSorce:findChild("Node_CreditsTips"):addChild(self.m_shoujiTips)
    self.m_shoujiTips:setVisible(false)
    self:addClick(self.m_collectSorce:findChild("Button_1"))

    --bonus玩法界面
    self.m_bonusView = util_createView("CodeTakeOrStakeSrc.TakeOrStakeBonusGame", {machine = self})
    self:findChild("root"):addChild(self.m_bonusView, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 60)
    self.m_bonusView:setPosition(-display.width / 2, -display.height / 2)
    self.m_bonusView:setVisible(false)
    
    --社交玩法 开始的等待界面
    self.m_bonusStartWaiting = util_createAnimation("TakeOrStake/BonusStartWaiting.csb")
    self:findChild("Node_BonusStartWaiting"):addChild(self.m_bonusStartWaiting)
    self.m_bonusStartWaiting:setVisible(false)
    local bonusStartWaitingGuang  = util_createAnimation("TakeOrStake_touxiang1_guang.csb")
    self.m_bonusStartWaiting:findChild("Node_touxiang_guang"):addChild(bonusStartWaitingGuang)
    bonusStartWaitingGuang:runCsbAction("idle", true)

    -- 黑色界面 压暗
    self.m_darkUI = util_createAnimation("TakeOrStake_dark.csb")
    self:findChild("Node_dark_0"):addChild(self.m_darkUI)
    self.m_darkUI:setVisible(false)

    -- 角色
    self.m_jiaoSe = util_spineCreate("Socre_TakeOrStake_juese",true,true)
    self:findChild("juese"):addChild(self.m_jiaoSe)
    self.m_jiaoSe:setVisible(false)

    -- 大赢加强效果
    self.m_bagWinEffect = util_createAnimation("TakeOrStake_Bigwin.csb")
    self:findChild("Node_bigwin"):addChild(self.m_bagWinEffect)
    self.m_bagWinEffect:setVisible(false)

    -- 过场2
    self.m_guochangOver = util_spineCreate("TakeOrStake_guochang2",true,true)
    self:addChild(self.m_guochangOver, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guochangOver:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochangOver:setVisible(false)

    -- 棋盘 压暗
    self.m_qiPanDarkUI = util_createAnimation("TakeOrStake_qipan_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_qiPanDarkUI, 100)
    self.m_qiPanDarkUI:setVisible(false)

    -- 随机wild玩法的动画
    self.m_wild_action = cc.Node:create()
    self.m_wild_action:setPosition(display.width * 0.5, display.height * 0.5)
    self:findChild("Node_dark"):addChild(self.m_wild_action, 200)

    self:setReelBg(1)
end

--设置棋盘的背景
-- _BgIndex 1bace 2社交
function CodeGameScreenTakeOrStakeMachine:setReelBg(_BgIndex)
    if _BgIndex == 1 then
        self.m_gameBg:runCsbAction("base",true)
        self:runCsbAction("idle",true)
    elseif _BgIndex == 2 then
        self.m_gameBg:runCsbAction("bonus",true)
    end
end

function CodeGameScreenTakeOrStakeMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound( self.m_publicConfig.SoundConfig.sound_TakeOrStake_enterGame )

    end,0.4,self:getModuleName())
end

function CodeGameScreenTakeOrStakeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenTakeOrStakeMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    -- 打开提醒框
    self:showTipsOpenView()
end

function CodeGameScreenTakeOrStakeMachine:addObservers()
    CodeGameScreenTakeOrStakeMachine.super.addObservers(self)

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
        local soundIndex = 1
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = self.m_publicConfig.SoundConfig["sound_TakeOrStake_winLine"..soundIndex] 
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:qucikStopCollectEffect()
    end,"QUICKSTOP_COLLECT")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:qucikStopRandomWildEffect()
    end,"QUICKSTOP_RANDOMWILD")

    --切换到后台
    gLobalNoticManager:addObserver(self,function(self, params)
        
        if self.m_bonusView:isVisible() then
            self.m_isQieHuanHouTai = true
            
            if self.m_isInFront then
                self.m_isInFront = false
                return
            end

            self.m_isInBehind = true
            
            local roomData = self.m_roomData:getRoomData()
            local extra = roomData.extra

            if extra.currentPhase == nil and roomData.result then
                self.m_haveBeginOpenBoxEffect = true
            end
            
            if self.m_bonusView.m_isGameOver then
                self.m_isGameOver = true--表示玩家在玩法结束 走过场返回base的时候 切换后台了
            end
            --发送停止刷新房间消息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)

            self.m_isEnterHouTai = true
            
            self.m_bonusView:removeFromParent()
            self.m_bonusView = nil
            
            self.m_bonusView = util_createView("CodeTakeOrStakeSrc.TakeOrStakeBonusGame", {machine = self})
            self:findChild("root"):addChild(self.m_bonusView, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 60)
            self.m_bonusView:setPosition(-display.width / 2, -display.height / 2)
            for index = 1, self.m_boxNums do
                self.m_bonusView.m_chengBeiList[index]:findChild("Particle_1"):setVisible(false)
            end
        end

    end,ViewEventType.APP_ENTER_BACKGROUND_EVENT)

    --切换到前台
    gLobalNoticManager:addObserver(self,function(self, params)
        local curTime = os.time()
        
        if self.m_isQieHuanHouTai then
            if self.m_bonusView.m_isGameOver or self.m_isGameOver then
                self.m_isGameOver = false
                self.m_bonusView:setVisible(false)
                self:bonusBackToBaseUpdataUI()
            end
            if not self.m_isInBehind then
                self.m_isInFront = true
            end
            self.m_isInBehind = false
            
            self.m_isEnterHouTai = false
            --重新刷新房间消息
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
        end
    end,ViewEventType.APP_ENTER_FOREGROUND_EVENT)
end

-- 从玩法返回base刷新数据
-- 只在切换后台的时候 使用
function CodeGameScreenTakeOrStakeMachine:bonusBackToBaseUpdataUI( )
    self.m_roomList.m_refreshTime = os.time()
    self.m_roomList.m_heart_beat_time = 5

    self.m_roomList.m_logOutTime = 0
    self.m_roomList.m_logout_time = 300

    self.m_roomDataClone = {}
    self:setReelBg(1)
    self:setCurrSpinMode(NORMAL_SPIN_MODE)

    self.m_isRunningEffect = false
    self.m_isTriggerBonus = false
    self.m_gameEffects = {}
    self.m_bEnterUpDateCollect = false
    
    self:showBottonUI(true)
    self:findChild("Node_qipan"):setVisible(true)
    self:setCollectBonusNum()

    self:resetMusicBg()
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_collectSorce:runCsbAction("idle",false)
    self:sheJiaoOverShowBonus()
    self.m_isFirstComeInSheJiao = false
    self.m_isNotDuanXianComeInSheJiao = false

    -- 发送领奖消息
    self:sendSeverWins()

    if self.m_bonusView then
        self.m_bonusView.m_isHaveEnd = false
        self.m_bonusView.m_playTriSelectBoxEffect = false
        self.m_bonusView:initSheJiaoUI()
        for index = 1, self.m_boxNums do
            self.m_bonusView.m_boxList[index].isClick = true -- 是否可点击
            self.m_bonusView.m_boxList[index].isShow = true -- 是否显示
            self.m_bonusView.m_boxList[index].isOpen = false -- 是否打开
            self.m_bonusView.m_boxList[index]:setVisible(false)
            self.m_bonusView.m_boxPicList[index]:setVisible(false)
            util_setChildNodeOpacity(self.m_bonusView.m_boxList[index], 255)
            self.m_bonusView.m_chengBeiList[index]:runCsbAction("idle3",false)
        end
    end
end

function CodeGameScreenTakeOrStakeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    CodeGameScreenTakeOrStakeMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    --需手动调用房间列表的退出方法,否则未加载完成退出游戏不会主动调用
    self.m_roomList:onExit()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end
end

--[[
    退出到大厅
]]
function CodeGameScreenTakeOrStakeMachine:showOutGame( )
    if self.m_isShowOutGame then
        return
    end
    self.m_isShowOutGame = true
    local view = util_createView("CodeTakeOrStakeSrc.TakeOrStakeGameOut")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
end

--[[
    暂停轮盘
]]
function CodeGameScreenTakeOrStakeMachine:pauseMachine()
    BaseMachine.pauseMachine(self)
    self.m_isShowSystemView = true
    local roomData = self.m_roomList:getRoomData()
    local extra = roomData.extra

    if self.m_bonusView:isVisible() and not extra.overTake then
    else
        --停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
    end
end

--[[
    恢复轮盘
]]
function CodeGameScreenTakeOrStakeMachine:resumeMachine()
    BaseMachine.resumeMachine(self)
    self.m_isShowSystemView = false

    --重新刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenTakeOrStakeMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_TakeOrStake_Bonus"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_TakeOrStake_10"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenTakeOrStakeMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenTakeOrStakeMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}

    return loadNode
end

-- 进入关卡
--
function CodeGameScreenTakeOrStakeMachine:enterLevel()
    CodeGameScreenTakeOrStakeMachine.super.enterLevel(self)

    --显示 进入的头像动画
    self:waitWithDelay(0.3,function (  )
        self.m_roomList:playTouXiangEffect()
    end)
end

---
-- 进入关卡
--
function CodeGameScreenTakeOrStakeMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        if self.m_initSpinData == nil then
            self:initNoneFeature()
        else
            self:initHasFeature()
        end
    end

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

-- 刷新credits 数值
function CodeGameScreenTakeOrStakeMachine:enterLevelUpDateCollectNum()
    if not self.m_bEnterUpDateCollect then
        local roomData = self.m_roomList:getRoomData()
        if roomData.extra.score then
            self.m_bEnterUpDateCollect = true
            self:setCollectBonusNum(false)
        end
    end
end

--[[
    设置收集的钱数
]] 
function CodeGameScreenTakeOrStakeMachine:setCollectBonusNum(isPlayAni)
    local collectCoinNum = 1

    if isPlayAni == true then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_collectBonus_feedback)
         -- 刷新动效
        self.m_collectSorce:runCsbAction("actionframe", false, function()
            self.m_collectSorce:runCsbAction("idleframe", false)
        end)
    end

    local roomData = self.m_roomList:getRoomData()
    if roomData.extra.score then
        collectCoinNum = roomData.extra.score
    end

    collectCoinNum = math.max(1, collectCoinNum)

    local coinStr = util_formatCoins(collectCoinNum, 300)
    local labCoins = self.m_collectSorce:findChild("m_lb_coins")
    labCoins:setString(coinStr)
    self:updateLabelSize({label = labCoins,sx = 0.5,sy = 0.5}, 340)
end
----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenTakeOrStakeMachine:MachineRule_initGame(  )
    self.m_isDuanXian = true
    self:enterLevelUpDateCollectNum()
    
    -- 断线之后 有奖励
    local winSpots = self.m_roomData:getWinSpots()
    if winSpots and #winSpots > 0 then
        local coins = 0
        for key,winInfo in pairs(winSpots) do
            if winInfo.udid == globalData.userRunData.userUdid then
                coins = coins + winInfo.coins
            end
        end
        if coins > 0 then
            self:showBonusWinView(coins, function()
                self:sendSeverWins()
            end)
        end
    end
end

--[[
    显示bonus 社交玩法 断线 之后 的奖励结果
]]
function CodeGameScreenTakeOrStakeMachine:showBonusWinView(coins,func)
    local ownerlist={}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    local view = self:showDialog("BnousOver_Mail",ownerlist,function()
        if func then
            func()
        end
    end)

    local info={label = view:findChild("m_lb_coins"),sx = 1,sy = 1}
    self:updateLabelSize(info,668)
end

---
-- 点击快速停止reel
--
function CodeGameScreenTakeOrStakeMachine:quicklyStopReel(colIndex)
    self.m_isQuicklyStop = true
    CodeGameScreenTakeOrStakeMachine.super.quicklyStopReel(self, colIndex)
end

--
--单列滚动停止回调
--
function CodeGameScreenTakeOrStakeMachine:slotOneReelDown(reelCol)    
    local isTriggerLongRun = CodeGameScreenTakeOrStakeMachine.super.slotOneReelDown(self,reelCol) 
    if not self.m_isTriggerLongRun then
        self.m_isTriggerLongRun = isTriggerLongRun
    end

    return isTriggerLongRun
end

function CodeGameScreenTakeOrStakeMachine:symbolBulingEndCallBack(_symbolNode)
    if _symbolNode and _symbolNode.p_symbolType == self.SYMBOL_BONUS then
        if self.m_isTriggerLongRun and _symbolNode.p_cloumnIndex ~= self.m_iReelColumnNum then
            local Col = _symbolNode.p_cloumnIndex
            for iCol = 1, Col do
                for iRow = 1,self.m_iReelRowNum do
                    local symbolNode = self:getFixSymbol(iCol,iRow)
                    if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS and symbolNode.m_currAnimName ~= "qidai" then
                        symbolNode:runAnim("qidai", true)
                    end
                end
            end
        else
            _symbolNode:runAnim("idleframe2", true)
        end
    end
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenTakeOrStakeMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    self.m_isTriggerBonus = false
    self.m_isFirstComeInSheJiao = false
    self.m_isTriggerLongRun = false

    if self.m_scheduleId then
        self:showTipsOverView()
    end

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenTakeOrStakeMachine:addSelfEffect()
    -- 收集 bonus 分值
    if self:isTriggerCollect() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_COLLECT_BONUS   
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_COLLECT_BONUS
    end

    -- base随机wild玩法
    if self:isTriggerWild() then
        self:initBaseRandomWildData()
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_WILD   
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_WILD
    end

    self:checkTriggerBonus()
end

--[[
    是否触发收集
]]
function CodeGameScreenTakeOrStakeMachine:isTriggerCollect( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreData = selfData.positionScore or {}
    if table.nums(scoreData) > 0 then
        return true
    end

    return false
end

--[[
    是否触发wild玩法
]]
function CodeGameScreenTakeOrStakeMachine:isTriggerWild( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local positionsData = selfData.positions or {}
    if #positionsData > 0 then
        return true
    end
    
    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenTakeOrStakeMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_BASE_COLLECT_BONUS then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:playEffect_BaseCollectBonus(function()
            self.m_isCollectOver = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BASE_WILD then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:playEffect_BaseRandomWild(1, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_BASE_BIG_WIN_EFFECT then
        for i,vEvent in ipairs(self.m_bigWinEvent) do
            self.m_roomList:showBigWinAni(vEvent)
            if i == #self.m_bigWinEvent then
                self.m_bigWinEvent = {}
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end

        self.m_qiPanDarkUI:setVisible(true)
        self.m_qiPanDarkUI:runCsbAction("start",false,function()
            -- 把落地已经 提层的先还原
            self:checkChangeBaseParent()
        end)
    end

    return true
end

-- 构建随机wild数据
function CodeGameScreenTakeOrStakeMachine:initBaseRandomWildData( )
    self.m_randomWildData = {}

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local positionsData = selfData.positions or {}
    --整理成数组
    for i,v_symbolType in ipairs(selfData.signals) do
        local signalPosData = {}
        for iCol = 1, self.m_iReelColumnNum  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    if v_symbolType == targSp.p_symbolType then
                        local signalRowCol = {}
                        signalRowCol.row = iRow
                        signalRowCol.col = iCol
                        signalRowCol.symbolType = v_symbolType
                        table.insert( signalPosData, signalRowCol)
                    end
                end
            end
        end
        if #signalPosData > 0 then
            table.insert( self.m_randomWildData, signalPosData)
        end
    end
end

function CodeGameScreenTakeOrStakeMachine:collectCoinFly(startWorldPos)
    local flyNode = util_createAnimation("TakeOrStake_Jiesuan_TopWinner.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = self:convertToNodeSpace(startWorldPos)
    local endWorldPos = self.m_collectSorce:findChild("m_lb_coins"):getParent():convertToWorldSpace(cc.p(self.m_collectSorce:findChild("m_lb_coins"):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
    flyNode:setPosition(startPos)
    local actList = {}
    actList[#actList + 1]  = cc.MoveTo:create(0.5,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        flyNode:removeFromParent()
    end)

    flyNode:runAction(cc.Sequence:create(actList))
end

-- 收集bonus分值
function CodeGameScreenTakeOrStakeMachine:playEffect_BaseCollectBonus(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreData  = selfData.positionScore or {}
    local isHavePlay = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true })
    self.m_bottomUI:getSpinBtn():resetStopBtnTouch()  --重置下stop按钮的点击状态

    if table.nums(scoreData) > 0 then
        local isPlay = false
        local isPlayFeedback = false
        for pos, coinNum in pairs(scoreData) do
            local fixPos = self:getRowAndColByPos(tonumber(pos))
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if targSp then
                local startWorldPos = util_convertToNodeSpace(targSp,self:findChild("Node_flyCoins"))
                startWorldPos.y = startWorldPos.y - 65
                local endNode = self.m_collectSorce:findChild("Node_shouji")
                local endPos = util_convertToNodeSpace(endNode,self:findChild("Node_flyCoins"))

                if not isPlay then
                    isPlay = true
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_collectBonus)
                end
                
                targSp:runAnim("shouji_1",false,function()
                    targSp:runAnim("shouji_2",true)
                end)

                performWithDelay(self:findChild("Node_flyCoins"), function()
                    local symbol_node = targSp:checkLoadCCbNode()
                    local spineNode = symbol_node:getCsbAct()
                    if spineNode and spineNode.m_csbNode then
                        spineNode.m_csbNode:setVisible(false)
                    end

                    local flyNode = util_createAnimation("TakeOrStake_Bonus_CreditCoins.csb")
                    self:findChild("Node_flyCoins"):addChild(flyNode)
                    flyNode:setPosition(startWorldPos)
                    flyNode:findChild("m_lb_coins"):setString(util_formatCoins(coinNum, 3))

                    flyNode:runCsbAction("actionframe",false)
                    flyNode:findChild("Particle_1"):setDuration(1)     --设置拖尾时间(生命周期)
                    flyNode:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
                    performWithDelay(self:findChild("Node_flyCoins"), function()
                        local actList = {}
                        actList[#actList + 1]  = cc.MoveTo:create(0.3,endPos)
                        actList[#actList + 1] = cc.CallFunc:create(function (  )
                            flyNode:findChild("m_lb_coins"):setVisible(false)

                            flyNode:removeFromParent()

                            targSp:runAnim("shouji_3",false,function()
                                targSp:runAnim("idle",true)

                                if not isHavePlay then
                                    isHavePlay = true
                                    if func then
                                        func()
                                    end
                                end
                            end)
                            if not isPlayFeedback then
                                isPlayFeedback = true
                                self:setCollectBonusNum(true)
                            end
                        end)

                        flyNode:runAction(cc.Sequence:create(actList))
                    end, 20/60)
                end, 21/30)
            end
        end
    end
end

-- 显示free 钱飞到赢钱框
function CodeGameScreenTakeOrStakeMachine:showFreeBoxCoinFly(winCoins, func)
    local startPos = util_convertToNodeSpace(self.m_freeWinCoinCurNode:findChild("Node_1"),self)

    self.m_freeWinCoinCurNode:findChild("Node_1"):setVisible(false)

    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode,self)
    
    local flyNode = util_createAnimation("PiggyLegendTreasure_FreeWins_Coins.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +5)
    flyNode:setPosition(startPos)
    flyNode:findChild("m_lb_coins"):setString(util_formatCoins(winCoins, 3))

    flyNode:runCsbAction("shouji2",false)
    flyNode:findChild("Particle_1"):setDuration(1)     --设置拖尾时间(生命周期)
    flyNode:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
    self:waitWithDelay(45/60, function()
        local actList = {}
        actList[#actList + 1]  = cc.MoveTo:create(15/60,endPos)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            self:showWinJieSunaAct()
        end)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            self:updateBottomUICoinsFree(winCoins)
        end)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            flyNode:findChild("m_lb_coins"):setVisible(false)
            self:waitWithDelay(0.5, function()
                flyNode:removeFromParent()
            end)

            self.m_freePaoJiSmallCoinIndex = {0,0,0,0,0}
            self.m_freePaoJiBigLeftCoinIndex = 0
            self.m_freePaoJiBigRightCoinIndex = 3

            if func then
                func()
            end
        end)
        flyNode:runAction(cc.Sequence:create(actList))
        gLobalSoundManager:playSound(self.m_musicConfig.Sound_Free_ZhuTotalCoinFly)
    end)
end

function CodeGameScreenTakeOrStakeMachine:playEffect_BaseRandomWild(bonusIndex, func)
    if bonusIndex > #self.m_randomWildData then
        self.m_darkUI:runCsbAction("over",false, function()
            self.m_darkUI:setVisible(false)
        end)
        self.m_qiPanDarkUI:runCsbAction("over",false, function()
            self.m_qiPanDarkUI:setVisible(false)
            self.m_wild_action:removeAllChildren()
        end)
        self:sheJiaoOverShowBonus()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_wild_nvzhuchi_close)

        util_spinePlay(self.m_jiaoSe, "base_over", false)
        util_spineEndCallFunc(self.m_jiaoSe, "base_over", function()
            self.m_jiaoSe:setVisible(false)
        end)

        if func then
            func()
        end
        return
    end

    local randomWildData = self.m_randomWildData[bonusIndex]
    local qieHuanName = "base_huan"
    if self.m_randomWildData[bonusIndex-1] then
        qieHuanName = "base_huan"..self.m_randomWildData[bonusIndex-1][1].symbolType
    end
    self.m_qiPanDarkUI:setVisible(true)
    self.m_qiPanDarkUI:runCsbAction("start",false,function()
        -- 把落地已经 提层的先还原
        self:checkChangeBaseParent()
    end)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_wild_change)

    util_spinePlay(self.m_jiaoSe, qieHuanName, false)
    self:waitWithDelay(4/60, function()
        self.m_jiaoSe:setSkin(self:getCurSkin(randomWildData[1].symbolType))
    end)

    util_spineEndCallFunc(self.m_jiaoSe, qieHuanName, function()
        util_spinePlay(self.m_jiaoSe, "base_idle2", true)
    end)
    
    util_spineFrameEvent(self.m_jiaoSe, qieHuanName,"huan",function()
        for _index, vPos in ipairs(randomWildData) do
            local targSp = self:getFixSymbol(vPos.col, vPos.row, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType then
                self:changeSymbolWild(vPos, targSp, _index)

                if _index == #randomWildData then
                    self:waitWithDelay(100/60, function()
                        self:playEffect_BaseRandomWild(bonusIndex + 1, func)
                    end)
                end
            end
        end
    end)
end

--[[
    把图标变成wild的时候 相关动画
]]
function CodeGameScreenTakeOrStakeMachine:changeSymbolWild(_vPos, _targSp, _index)
    local startWorldPos =  self:getNodePosByColAndRow(_vPos.row, _vPos.col)
    local startPos = self.m_wild_action:convertToNodeSpace(startWorldPos)
    local oldWild = self:createNewWildSymbol()
    oldWild:setPosition(startPos)
    self.m_wild_action:addChild(oldWild, 100)

    local guangUp = util_createAnimation("TakeOrStake_wild_chuxian_deng_up.csb")
    oldWild:addChild(guangUp, 1)
    local guangDown = util_createAnimation("TakeOrStake_wild_chuxian_deng_down.csb")
    oldWild:addChild(guangDown, -1)
    local liHuaDown = util_createAnimation("TakeOrStake_wild_chuxian.csb")
    oldWild:addChild(liHuaDown, 2)

    guangUp:runCsbAction("actionframe",false)
    guangDown:runCsbAction("actionframe1",false)
    liHuaDown:runCsbAction("actionframe",false,function()
        liHuaDown:removeFromParent()
    end)

    self:waitWithDelay(40/60, function()
        local symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        local newWild = self:createNewWildSymbol()
        newWild:setPosition(startPos)
        self.m_wild_action:addChild(newWild, 200)

        if _index == 1 then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_wild_change_qipan)
        end

        util_spinePlay(newWild, "start", false)
        self:waitWithDelay(25/30, function()
            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            _targSp:changeCCBByName(ccbName, symbolType)
            _targSp:changeSymbolImageByName(ccbName)

            oldWild:removeFromParent()
        end)
    end)
    self:waitWithDelay(60/60, function()
        guangUp:removeFromParent()
        guangDown:removeFromParent()
    end)
end

function CodeGameScreenTakeOrStakeMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    return world_pos
end

-- 区分皮肤
function CodeGameScreenTakeOrStakeMachine:getCurSkin(symbolType)
    if symbolType == 0 then
        return "H1guang"
    elseif symbolType == 1 then
        return "H2guang"
    elseif symbolType == 2 then
        return "H3guang"
    elseif symbolType == 3 then
        return "H4guang"
    elseif symbolType == 4 then
        return "H5guang"
    elseif symbolType == 5 then
        return "L1guang"
    elseif symbolType == 6 then
        return "L2guang"
    elseif symbolType == 7 then
        return "L3guang"
    elseif symbolType == 8 then
        return "L4guang"
    elseif symbolType == 9 then
        return "L5guang"
    end
    return nil
end

--[[
    检测是否触发bonus
]]
function CodeGameScreenTakeOrStakeMachine:checkTriggerBonus()
    --检测是否已经添加过bonus,防止刷新数据时导致二次添加
    for k,gameEffect in pairs(self.m_gameEffects) do
        if gameEffect and gameEffect.p_effectType == GameEffect.EFFECT_BONUS then
            return true
        end
    end
    
    --有玩家触发Bonus
    local roomData = self.m_roomData:getRoomData()
    if roomData and roomData.extra and roomData.extra.currentUser then
        print("触发了社交玩法 有房间数据")
        if self.m_isFirstComeInSheJiao then
            return true
        end

        self.m_isFirstComeInSheJiao = true
        self.m_roomDataClone = clone(roomData)
        if self.m_roomDataClone.result then
            self.m_roomDataClone.result = nil
        end
        --发送停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)

        self.m_roomData.m_teamData.room.result = nil

        self:addBonusEffect(roomData)
        return true
    end

    return false
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenTakeOrStakeMachine:addBonusEffect(roomData)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    
    local effect = GameEffectData.new()
    effect.p_effectType = GameEffect.EFFECT_BONUS
    effect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = effect
    --进入玩法后需要使用拷贝出来的result结果,本地roomData中的result需要清空,防止重复触发玩法
    effect.roomData = clone(roomData) 
end

--[[
    Bonus玩法
]]
function CodeGameScreenTakeOrStakeMachine:showEffect_Bonus(effectData)
    -- 暂停背景音乐
    self:clearCurMusicBg()
    self:clearWinLineEffect()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    if self.m_serverWinCoins > 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, true})
    end
    
    effectData.p_isPlay = true

    local playBonusStart = function()
        self:showBonusGameView(effectData.roomData, function()
        end)
    end
    
    -- 1. 自己触发的话，播放bonus信号的触发动画
    local playerData = effectData.roomData.triggerPlayer
    local isMe = (globalData.userRunData.userUdid == playerData.udid)
    if isMe then
        local bHaveBonus = false
        local bPlaySymbolAnim = false
        local childs = self.m_clipParent:getChildren()
        for _, _slotNode in ipairs(childs) do
            local tag = _slotNode:getTag()
            if tag > SYMBOL_FIX_NODE_TAG and _slotNode.p_symbolType == self.SYMBOL_BONUS then
                bHaveBonus = true
                -- bonus触发动画
                _slotNode:runAnim("actionframe",false,function()
                    _slotNode:runAnim("idle",true)
                end)
                -- 在没回来时进行下一步 播放弹板
                self:waitWithDelay(70/30, function()
                    if not bPlaySymbolAnim then
                        bPlaySymbolAnim = true
                        playBonusStart()
                    end
                end)
            end
        end
        
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_bonus_trigger)

        if not bHaveBonus then
            playBonusStart()
        end
    else
        playBonusStart()
    end
    
    return true
end

function CodeGameScreenTakeOrStakeMachine:playGuoChangEffect()
    self:playBonusGuoChangAnim(function()
        self:playGameEffect()
        self:setCurrSpinMode(SPECIAL_SPIN_MODE)

        self:removeSoundHandler()
        self:resetMusicBg(nil,"TakeOrStakeSounds/music_TakeOrStakeSounds_bonusGame.mp3")

        self.m_roomList.m_refreshTime = os.time()
        self.m_roomList.m_heart_beat_time = 1

        self.m_roomList.m_logOutTime = 0
        self.m_roomList.m_logout_time = 6000
        self.m_isTriggerBonus = true

        --重新刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

        -- 正常流程 进入 社交界面
        local roomData = self.m_roomData:getRoomData()
        if self.m_isNotDuanXianComeInSheJiao or (roomData.extra.selected and #roomData.extra.selected == 0) then
            self.m_bonusView:initBox(function()
                self.m_bonusView:initChengBei()
            end)
        else
            --断线进入 显示社交的界面
            self.m_bonusView:initDuanXianUI()
        end 
    end)
end

function CodeGameScreenTakeOrStakeMachine:showBonusGameView(_roomData, func)
    local playerData = _roomData.triggerPlayer
    local isMe = (globalData.userRunData.userUdid == playerData.udid)
    
    -- 把落地已经 提层的先还原
    self:checkChangeBaseParent()

    local head = self.m_bonusStartWaiting:findChild("sp_touxiang")
    local frameNode = self.m_bonusStartWaiting:findChild("Node_touxiang")

    head:removeAllChildren(true)
    frameNode:removeAllChildren(true)

    local frame = util_createAnimation("TakeOrStake_touxiangkuang_moren.csb")
    frameNode:addChild(frame)

    if playerData.frame == "" then
        frame:findChild("Player"):setVisible(isMe)
        frame:findChild("Others"):setVisible(not isMe)
    else
        frame:findChild("Player"):setVisible(false)
        frame:findChild("Others"):setVisible(false)
    end
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(playerData.facebookId, playerData.head, playerData.frame, nil, head:getContentSize())
    head:addChild(nodeAvatar)
    nodeAvatar:setPosition( head:getContentSize().width * 0.5, head:getContentSize().height * 0.5 )
    
    local txt_name = self.m_bonusStartWaiting:findChild("m_lb_PlayerID")
    txt_name:setString(playerData.nickName or "")
    txt_name:stopAllActions()
    
    local clipNode = txt_name:getParent()
    local clipSize = clipNode:getContentSize()
    txt_name:setAnchorPoint(cc.p(0.5,0.5))
    txt_name:setPosition(cc.p(clipSize.width / 2,clipSize.height / 2))
    txt_name:ignoreContentAdaptWithSize(true)
    util_wordSwing(txt_name, 1, clipNode, 2, 30, 2, nil, true)

    self:waitWithDelay(0.1, function()
        --只要用于 断线
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end)

    -- 渐隐效果
    self.m_collectSorce:runCsbAction("over",false)

    -- 取消掉赢钱线的显示 | 底栏
    self.m_bottomUI:resetWinLabel()
    self.m_bottomUI:checkClearWinLabel()

    self:playWaitingStartEffect()
end

--[[
    开始播放进入社交界面之前的等待动画
]]
function CodeGameScreenTakeOrStakeMachine:playWaitingStartEffect( )
    self.m_bonusStartWaiting:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_waiting)

    self.m_bonusStartWaiting:runCsbAction("start",false,function()
        self.m_jiaoSe:setVisible(true)
        util_spinePlay(self.m_jiaoSe, "shejiao_start", false)
        util_spineEndCallFunc(self.m_jiaoSe, "shejiao_start", function()
            util_spinePlay(self.m_jiaoSe, "shejiao_idle", true)
        end)

        self.m_roomList.m_refreshTime = os.time()
        self.m_roomList.m_heart_beat_time = 1
        self.m_isTriggerBonus = false

        --重新刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)

        self.m_bonusStartWaiting:runCsbAction("idle1",true)

        local roomData = self.m_roomList:getRoomData()
        if roomData.extra.currentPhase == 4 then
            self.m_isRunningEffect = false
            self:sendComeInSheJiaoData()
        else
            self:continueWaiting()
        end
    end)
end

-- 进入社交
function CodeGameScreenTakeOrStakeMachine:sendComeInSheJiaoData()
    --重置自动退出时间间隔
    self.m_roomList:resetLogoutTime()

    local httpSendMgr = SendDataManager:getInstance()
    local gameName = self:getNetWorkModuleName()
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end

    local roomData = self.m_roomList:getRoomData()
    local actionData = httpSendMgr:getNetWorkSlots():getSendActionData(ActionType.TeamMissionOption, gameName)
    local params = {}
    params.action = roomData.extra.currentPhase -- 表示当前阶段
    params.extra = {} 
    params.extra.value = 2
    actionData.data.params = json.encode(params)
    httpSendMgr:getNetWorkSlots():sendMessageData(actionData)
end

function CodeGameScreenTakeOrStakeMachine:isComInSheJiao( )
    self.m_roomList:resetLogoutTime()
    local roomData = self.m_roomList:getRoomData()
    local event = self.m_roomList.m_roomData:getRoomEvent()
    local isContinue = false
    if #event > 0 then
        for i,vEvent in ipairs(event) do
            if vEvent.eventType == "GAME_READY_RESULT" then
                isContinue = true
            end
        end
    end
    if not isContinue then
        return
    end

    self.m_isRunningEffect = true
    self:continueWaiting()
end

-- 社交玩法开始之前 会等待所有玩家 进入 ，收到服务器标识 在进入下个流程
function CodeGameScreenTakeOrStakeMachine:continueWaiting()
    --发送停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
    self.m_bonusStartWaiting:runCsbAction("switch",false,function()
        self.m_bonusStartWaiting:runCsbAction("idle2",false,function()
            self.m_bonusStartWaiting:runCsbAction("over",false,function()
                self.m_bonusStartWaiting:setVisible(false)
            end)
            util_spinePlay(self.m_jiaoSe, "shejiao_shenshou", false)
            util_spineEndCallFunc(self.m_jiaoSe, "shejiao_shenshou", function()
                self.m_jiaoSe:setVisible(false)
            end)

            self:waitWithDelay(27/30, function()
                self:playGuoChangEffect()
            end)
        end)
    end)
end

-- 过场动画
function CodeGameScreenTakeOrStakeMachine:playBonusGuoChangAnim(func)
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_shejiao_guochang)

    self.m_guochangOver:setVisible(true)
    util_spinePlay(self.m_guochangOver, "guochang", false)
    util_spineEndCallFunc(self.m_guochangOver, "guochang", function()
        self.m_guochangOver:setVisible(false)

        if func then
            func()
        end
    end)

    self:waitWithDelay(30/30, function()
        self.m_bonusStartWaiting:setVisible(false)
        self.m_gameBg:findChild("caidai"):setVisible(false)
        self:setReelBg(2)

        self.m_bonusView:setVisible(true)
        self:showBottonUI(false)
        self:findChild("Node_qipan"):setVisible(false)

        self.m_bonusView:upDatePlayerItem()

        self.m_bonusView:initChengBeiNum()

        self.m_bonusView:initSheJiaoUI()
        self.m_bonusView.m_isGameOver = false
    end)
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenTakeOrStakeMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenTakeOrStakeMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenTakeOrStakeMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenTakeOrStakeMachine:slotReelDown( )
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            --只有播期待的恢复idle状态
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS and symbolNode.m_currAnimName == "qidai" then
                local ccbNode = symbolNode:getCCBNode()
                if ccbNode then
                    util_spineMix(ccbNode.m_spineNode, symbolNode.m_currAnimName, "idleframe2", 0.5)
                end
                symbolNode:runAnim("idleframe2", true)
            end
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenTakeOrStakeMachine.super.slotReelDown(self)
end

function CodeGameScreenTakeOrStakeMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

-- 延时函数
function CodeGameScreenTakeOrStakeMachine:waitWithDelay(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

-- 隐藏 显示 下UI
function CodeGameScreenTakeOrStakeMachine:showBottonUI(isShow)
    self.m_bottomUI:setVisible(isShow)
end

--新滚动使用
function CodeGameScreenTakeOrStakeMachine:updateReelGridNode(_symbolNode)
    CodeGameScreenTakeOrStakeMachine.super.updateReelGridNode(self, _symbolNode)

    self:setSpecialNodeScore(_symbolNode)
end

-- 给一些信号块上的数字进行赋值
function CodeGameScreenTakeOrStakeMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if symbolNode.p_symbolType == self.SYMBOL_BONUS then
        -- 重置 展示
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        local coinsView
        if not spineNode.m_csbNode then
            coinsView = util_createAnimation("TakeOrStake_Bonus_CreditCoins.csb")
            util_spinePushBindNode(spineNode,"guadian",coinsView)
            spineNode.m_csbNode = coinsView
        else
            spineNode.m_csbNode:setVisible(true)
            coinsView = spineNode.m_csbNode
        end

        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            local pos = self:getPosReelIdx(iRow,iCol)
            local score = self:getReSpinSymbolScore(pos)
            local labCoins = coinsView:findChild("m_lb_coins")
            labCoins:setString(util_formatCoins(score, 3))
            self:updateLabelSize({label = labCoins,sx = 0.65,sy = 0.7}, 160)
        else
            local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
            local labCoins = coinsView:findChild("m_lb_coins")
            labCoins:setString(util_formatCoins(score, 3))
            self:updateLabelSize({label = labCoins,sx = 0.65,sy = 0.7}, 160)
        end
    end
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenTakeOrStakeMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.positionScore or {}
    local score = nil

    for _sPos,_iScore in pairs(storedIcons) do
        if tonumber(_sPos) == id then
            score = _iScore
            break
        end
    end

    if score == nil then
       return 0
    end

    return score
end

function CodeGameScreenTakeOrStakeMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if self.SYMBOL_BONUS == symbolType then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = globalData.slotRunData:getCurTotalBet() * 0.01 
    end

    return score
end

function CodeGameScreenTakeOrStakeMachine:beginReel()
    CodeGameScreenTakeOrStakeMachine.super.beginReel(self)
    
    --重置自动退出时间间隔
    self.m_roomList:resetLogoutTime()

    self.m_isDuanXian = false
    self.m_isNotDuanXianComeInSheJiao = true --如果断线进社交玩法的话 不会有这个值
    self.m_isQuicklyStop = false
    self.m_isCollectOver = false
end

function CodeGameScreenTakeOrStakeMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        -- scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(self.SYMBOL_BONUS, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

function CodeGameScreenTakeOrStakeMachine:getLongRunLen(col, index)
    local len = 0
    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
    len = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    return len
end

--设置bonus scatter 信息
function CodeGameScreenTakeOrStakeMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = false,false --reelRunData:getSpeicalSybolRunInfo(symbolType)
    if symbolType == self.SYMBOL_BONUS then 
        bRun, bPlayAni = true,true
    end

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
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
    return  allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenTakeOrStakeMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum >= 1 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    else
        return runStatus.DUANG, false
    end
end

--震动
function CodeGameScreenTakeOrStakeMachine:shakeNode()
    local changePosY = 15
    local changePosX = 7.5
    local actionList2 = {}
    local oldPos = cc.p(self:findChild("root"):getPosition())

    for i=1,10 do
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x - changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
        actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
    end

    local seq2 = cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)

end

function CodeGameScreenTakeOrStakeMachine:checkIsBigWin( )
    local coins = self.m_serverWinCoins or 0
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = coins / totalBet

    if winRate >= self.m_HugeWinLimitRate then
        return true
    elseif winRate >= self.m_MegaWinLimitRate then
        return true
    elseif winRate >= self.m_BigWinLimitRate then
        return true
    end

    return false
end

-- 向服务器 发送领奖消息
function CodeGameScreenTakeOrStakeMachine:sendSeverWins()
    local winSpots = self.m_roomData:getWinSpots()
    if winSpots and #winSpots > 0 then
        local coins = 0
        for key,winInfo in pairs(winSpots) do
            if winInfo.udid == globalData.userRunData.userUdid then
                coins = coins + winInfo.coins
            end
        end

        if coins > 0 then
            --检测是否获得大奖
            -- self:checkFeatureOverTriggerBigWin(coins)
            self:playGameEffect()

            local gameName = self:getNetWorkModuleName()
            local index = -1 
            gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
                function()
                    globalData.slotRunData.lastWinCoin = 0
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                        coins, true, true
                    })
                end,
                function(errorCode, errorData)
                    
                end
            )
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end
end

--下面内容基本都是快停相关
function CodeGameScreenTakeOrStakeMachine:getBottomUINode( )
    return "CodeTakeOrStakeSrc.TakeOrStakeBottomUI"
end

function CodeGameScreenTakeOrStakeMachine:getIsHaveBonus( )
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                local symbolType = node.p_symbolType
                if symbolType == self.SYMBOL_BONUS then
                    return true
                end
            end
        end
    end
    return false
end

function CodeGameScreenTakeOrStakeMachine:qucikStopCollectEffect( )
    if self.m_isCollectOver then
        return
    end

    if not self:getIsHaveBonus() then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreData  = selfData.positionScore or {}

    self:findChild("Node_flyCoins"):stopAllActions()
    self:findChild("Node_flyCoins"):removeAllChildren()

    self:setCollectBonusNum(true)

    if table.nums(scoreData) > 0 then
        for pos, coinNum in pairs(scoreData) do
            local fixPos = self:getRowAndColByPos(tonumber(pos))
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType then
                targSp:runAnim("idle",true)
            end
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false })

    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType == self.EFFECT_BASE_COLLECT_BONUS and effectData.p_isPlay == false then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
end

function CodeGameScreenTakeOrStakeMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    local delayTime =self:playDarkEffect()

    self:waitWithDelay(delayTime, function()
        self:produceSlots()

        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end

        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end)
end

--[[
    收到数据之后 开始播放动画
]]
function CodeGameScreenTakeOrStakeMachine:playDarkEffect( )
    local delayTime = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local positionsData = selfData.positions or {}
    if #positionsData > 0 then
        delayTime = 0.5
        self.m_darkUI:setVisible(true)
        self.m_darkUI:runCsbAction("start",false)
        performWithDelay(self.m_wild_action, function()
            self.m_jiaoSe:setVisible(true)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_wild_nvzhuchi_chuxian)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_wild_change_first)

            util_spinePlay(self.m_jiaoSe, "base_start", false)
            util_spineEndCallFunc(self.m_jiaoSe, "base_start", function()
                self.m_jiaoSe:setSkin("lucy")
                util_spinePlay(self.m_jiaoSe, "base_idle2", true)
            end)
        end, 0.5)
    end
    return delayTime
end

-- 点击快停 随机wild
function CodeGameScreenTakeOrStakeMachine:qucikStopRandomWildEffect( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local positionsData = selfData.positions or {}
    if #positionsData > 0 then
        self.m_wild_action:stopAllActions()
        self.m_wild_action:removeAllChildren()

        self.m_darkUI:setVisible(true)
        self.m_darkUI:runCsbAction("idle",false)

        self.m_jiaoSe:setSkin("lucy")
        util_spinePlay(self.m_jiaoSe, "base_idle", true)
    end
end

-- 社交玩法结束 bonus图标 恢复原来
function CodeGameScreenTakeOrStakeMachine:sheJiaoOverShowBonus()
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                local symbolType = node.p_symbolType
                if symbolType == self.SYMBOL_BONUS then
                    local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType,0)
                    symbolNode:runAnim("idle",true)
                end
            end
        end
    end
end

-- 适配
function CodeGameScreenTakeOrStakeMachine:scaleMainLayer()
    CodeGameScreenTakeOrStakeMachine.super.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.78
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.86 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.92 - 0.06*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.98 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 10)
end

function CodeGameScreenTakeOrStakeMachine:clickFunc(_sender)
    local name = _sender:getName()

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return
    end

    if name == "Button_1" then
        if self.m_shoujiTips:isVisible() then
            self:showTipsOverView()
        else
            if self.getGameSpinStage() == IDLE then
                self:showTipsOpenView()
            end
        end
    end
end

--打开tips
function CodeGameScreenTakeOrStakeMachine:showTipsOpenView( )
    self.m_shoujiTips:setVisible(true)
    self.m_shoujiTips:runCsbAction("start",false,function()
        self.m_shoujiTips:runCsbAction("idle",true)
        self.m_scheduleId = schedule(self, function(  )
            self:showTipsOverView()
        end, 4)
    end)
    
end

--关闭tips
function CodeGameScreenTakeOrStakeMachine:showTipsOverView( )
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    else
        return
    end

    self.m_shoujiTips:runCsbAction("over",false,function()
        self.m_shoujiTips:setVisible(false)
    end)
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenTakeOrStakeMachine:playCustomSpecialSymbolDownAct( node)
    if node then
        if node.m_scoreItem and node.m_scoreItem:isVisible() then
            node.m_scoreItem:runCsbAction("buling",false,function()
                node.m_scoreItem:runCsbAction("idleframe",true)
            end)
        end

        if node.p_symbolType == self.SYMBOL_BONUS or 
        node.p_symbolType == self.SYMBOL_BONUS_MINI or 
        node.p_symbolType == self.SYMBOL_BONUS_MINOR or 
        node.p_symbolType == self.SYMBOL_BONUS_MAJOR or 
        node.p_symbolType == self.SYMBOL_BONUS_MEGA or 
        node.p_symbolType == self.SYMBOL_WILD_FREE or 
        node.p_symbolType == self.SYMBOL_BONUS_WHEEL then 
            --修改小块层级
            local symbolNode = util_setSymbolToClipReel(self,node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType,0)
            symbolNode:runAnim("buling",false,function()
                self:symbolBulingEndCallBack(symbolNode)
            end)
        end
    end
end

function CodeGameScreenTakeOrStakeMachine:createNewWildSymbol( )
    local wildNode = util_spineCreate("Socre_TakeOrStake_Wild", true, true)

    return wildNode
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenTakeOrStakeMachine:showBigWinLight(_func)
    -- 大赢加强效果
    self:shakeNode()
    self.m_bagWinEffect:setVisible(true)
    self.m_bagWinEffect:findChild("Particle_1"):resetSystem()
    self.m_bagWinEffect:findChild("Particle_2"):resetSystem()

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_TakeOrStake_wild_bigWin)

    self.m_bagWinEffect:runCsbAction("actionframe",false,function()
        self.m_bagWinEffect:setVisible(false)
        if type(_func) == "function" then
            _func()
        end
    end)

    for i,vEvent in ipairs(self.m_bigWinEvent) do
        self.m_roomList:showBigWinAni(vEvent)
        if i == #self.m_bigWinEvent then
            self.m_bigWinEvent = {}
        end
    end
end

return CodeGameScreenTakeOrStakeMachine