---
-- island li
-- 2019年1月26日
-- CodeGameScreenBlackFridayMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
local PublicConfig = require "BlackFridayPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenBlackFridayMachine = class("CodeGameScreenBlackFridayMachine", BaseNewReelMachine)

CodeGameScreenBlackFridayMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBlackFridayMachine.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  
CodeGameScreenBlackFridayMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenBlackFridayMachine.SYMBOL_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3  
CodeGameScreenBlackFridayMachine.SYMBOL_BONUS4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4  -- 特殊bonus
CodeGameScreenBlackFridayMachine.SYMBOL_SCORE_BLANK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7 --100
CodeGameScreenBlackFridayMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1

CodeGameScreenBlackFridayMachine.COLLECT_SHOP_SCORE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 收集商店金币次数
CodeGameScreenBlackFridayMachine.COLLECT_ENVELOPE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集 信封打开物品
CodeGameScreenBlackFridayMachine.SUPER_FREE_BACK_OPENSHOP_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- super free返回需要打开商店

CodeGameScreenBlackFridayMachine.m_lightScore = 0
CodeGameScreenBlackFridayMachine.m_MiNiTotalNum = 3 --mini小轮盘的总个数

-- 构造函数
function CodeGameScreenBlackFridayMachine:ctor()
    CodeGameScreenBlackFridayMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_miniMachine = {} -- mini轮盘
    self.m_isShowJiaoBiao = false --判断是否显示角标 断线进来不显示
    self.m_iBetLevel = 0 -- bet等级
    self.m_lockWilds = {}
    self.m_isQuicklyStop = false --是否点击快停
    self.m_isGetIndexMini = false
    self.m_isCanClickShop = true --滚动出来 bonus4信封 图标之后 需要判断点击商店的时机
    self.m_isTriggerFreeMore = false --是否触发了 freemore 用来判断free次数增加显示 动效
    self.m_jiaoseIdleIndex = 1 --播放角色 idle 的顺序 ID
    self.m_bonus3List = {} -- 存储respin 滚动出来的bonus3
    self.m_bonus3MiniMachineList = {} -- 存储respin 滚动出来bonus3 的mini棋盘ID
    self.m_isPlayBulingSound = true
    self.m_respinQiPanJimanPlaySound = true --判断respin棋盘集满动画 的时候 播放音效一次
    self.m_isPlayBonus1Buling = {}
    for i=1,5 do
        self.m_isPlayBonus1Buling[i] = true
    end
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

    self.m_publicConfig = PublicConfig
	--init
	self:initGame()
end

function CodeGameScreenBlackFridayMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("BlackFridayConfig.csv", "LevelBlackFridayConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBlackFridayMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BlackFriday"  
end

function CodeGameScreenBlackFridayMachine:initUI()
    --快滚音效
    self.m_reelRunSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_quickRun

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    self:findChild("Node_fly"):setLocalZOrder(1000)

    self:initFreeSpinBar() -- FreeSpinbar

    -- 隐藏respin相关节点
    self:findChild("Node_2"):setVisible(false)

    for MiNiIndex = 1, self.m_MiNiTotalNum do
        self.m_miniMachine[MiNiIndex] = util_createView("CodeBlackFridaySrc.BlackFridayMini.BlackFridayMiniMachine",{machine = self,index = MiNiIndex})
        self:findChild("Node_respin_qipan"..MiNiIndex):addChild(self.m_miniMachine[MiNiIndex])

        if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
            self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniMachine[MiNiIndex].m_touchSpinLayer)
        end

        -- 创建每个小轮盘上面的3个板子
        for i=1,3 do
            self.m_miniMachine[MiNiIndex]["banzi"..i] = util_spineCreate("BlackFriday_link",true,true)
            self.m_miniMachine[MiNiIndex]:findChild("Node_ban_"..i):addChild(self.m_miniMachine[MiNiIndex]["banzi"..i])
            util_spinePlay(self.m_miniMachine[MiNiIndex]["banzi"..i],"idleframe")
        end

        -- 创建棋盘集满动画
        self.m_miniMachine[MiNiIndex].qiPanJiManSpine = util_spineCreate("BlackFriday_respin_win",true,true)
        self:findChild("Node_jiman"..MiNiIndex):addChild(self.m_miniMachine[MiNiIndex].qiPanJiManSpine)
        self.m_miniMachine[MiNiIndex].qiPanJiManSpine:setVisible(false)

        self.m_miniMachine[MiNiIndex].qiPanJiManEffect = util_createAnimation("BlackFriday_respin_win.csb")
        self:findChild("Node_jiman"..MiNiIndex):addChild(self.m_miniMachine[MiNiIndex].qiPanJiManEffect)
        self.m_miniMachine[MiNiIndex].qiPanJiManEffect:setVisible(false)
        
        -- 创建棋盘动画
        self.m_miniMachine[MiNiIndex].qiPanEffect = util_createAnimation("BlackFriday_respin_qipan.csb")
        self.m_miniMachine[MiNiIndex]:findChild("Node_respin_prize"):addChild(self.m_miniMachine[MiNiIndex].qiPanEffect)
        self.m_miniMachine[MiNiIndex].qiPanEffect:setVisible(false)

        -- 创建棋盘集满结算动画
        self.m_miniMachine[MiNiIndex].jiManEffect = util_createAnimation("BlackFriday_respin_prize.csb")
        self.m_miniMachine[MiNiIndex]:findChild("Node_respin_prize"):addChild(self.m_miniMachine[MiNiIndex].jiManEffect)
        self.m_miniMachine[MiNiIndex].jiManEffect:setVisible(false)
        self.m_miniMachine[MiNiIndex].jiManEffect.winCoinNode = util_createAnimation("BlackFriday_respin_prize_shuzhi.csb")
        self.m_miniMachine[MiNiIndex].jiManEffect:findChild("Node_3"):addChild(self.m_miniMachine[MiNiIndex].jiManEffect.winCoinNode)
        local JiManEffect = util_createAnimation("BlackFriday_respin_prize_0.csb")
        self.m_miniMachine[MiNiIndex].jiManEffect:findChild("prize"):addChild(JiManEffect)
        JiManEffect:runCsbAction("idle",true)


    end
    -- 创建棋盘动画
    self.m_qiPanJiManDark = util_createAnimation("BlackFriday_respin_winzz.csb")
    self:findChild("Node_zhezhao"):addChild(self.m_qiPanJiManDark)
    self.m_qiPanJiManDark:setVisible(false)

    --jackpot 
    self.m_jackpotBar = util_createView("CodeBlackFridaySrc.BlackFridayJackPotBarView",{machine = self})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    --jackpot respin
    self.m_jackpotRespinBar = util_createView("CodeBlackFridaySrc.BlackFridayJackPotReSpinBarView",{machine = self})
    self:findChild("Node_respin_jackpot"):addChild(self.m_jackpotRespinBar)

    --角色
    self.m_jiaoSeSpine = util_spineCreate("BlackFriday_juese",true,true)
    self:findChild("Node_ren"):addChild(self.m_jiaoSeSpine)
    self:playJiaoSeIdleFrame()

    --金币收集条
    self.m_coinCollectBar = util_createView("CodeBlackFridaySrc.BlackFridayCoinCollectBar",{machine = self})
    self:findChild("Node_shop"):addChild(self.m_coinCollectBar)
    -- 更改 tip的层级
    local node = self.m_coinCollectBar.m_tip
    local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    pos = self:findChild("Node_guochang"):convertToNodeSpace(pos)
    util_changeNodeParent(self:findChild("Node_guochang"), self.m_coinCollectBar.m_tip)
    node:setPosition(pos.x, pos.y)

    -- 折扣信息
    self.m_zheKouOffNode = util_createAnimation("BlackFriday_off.csb")
    self:findChild("Node_off"):addChild(self.m_zheKouOffNode)

    -- free过场动画
    self.m_guochangFreeEffect = util_spineCreate("BlackFriday_guochang",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochangFreeEffect)
    self.m_guochangFreeEffect:setVisible(false)

    -- respin过场动画
    self.m_guochangRespinEffect = util_spineCreate("BlackFriday_guochang2",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochangRespinEffect)
    self.m_guochangRespinEffect:setVisible(false)

    -- respin过场动画 over
    self.m_guochangRespinOverEffect = util_spineCreate("BlackFriday_guochang3",true,true)
    self:findChild("Node_guochang"):addChild(self.m_guochangRespinOverEffect)
    self.m_guochangRespinOverEffect:setVisible(false)

    -- respin过场动画 背景遮挡
    self.m_guochangRespinBg = util_createAnimation("BlackFriday/GameScreenBlackFridayBg.csb")
    self:findChild("bg_guochang"):addChild(self.m_guochangRespinBg)
    self.m_guochangRespinBg:setVisible(false)

    --商店界面
    self.m_shopView = util_createView("CodeBlackFridaySrc.BlackFridayShop.BlackFridayShopView",{machine = self})
    self:findChild("Node_guochang"):addChild(self.m_shopView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    -- 大赢动画
    self.m_bigwinEffect = util_spineCreate("BlackFriday_bigwin", true, true)
    self:findChild("Node_guochang"):addChild(self.m_bigwinEffect)
    self.m_bigwinEffect:setVisible(false)

    -- superfree 棋盘遮罩
    self.m_superFreeQiPanDark = util_createAnimation("BlackFriday_qipan_gdwild.csb")
    self:findChild("Node_superfree"):addChild(self.m_superFreeQiPanDark)
    self.m_superFreeQiPanDark:setVisible(false)
   
    self:setReelBg(1)

    self:runCsbAction("idleframe", true)
    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end

        if self:getCurrSpinMode() == RESPIN_MODE then
            return
        end
        
        -- 音效让大赢的时候 播放连线
        -- if self.m_bIsBigWin then
        --     return
        -- end

        local features = self.m_runSpinResultData.p_features or {}
        if #features > 1 then
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

        local soundName = nil
        if self.m_bProduceSlots_InFreeSpin then
            if self.m_isSuperFree then
                soundName = self.m_publicConfig.SoundConfig["sound_BlackFriday_superFree_winLine"..soundIndex] 
            else
                soundName = self.m_publicConfig.SoundConfig["sound_BlackFriday_free_winLine"..soundIndex] 
            end
        else
            soundName = self.m_publicConfig.SoundConfig["sound_BlackFriday_winLine"..soundIndex] 
        end

        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenBlackFridayMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_bar")
    self.m_baseFreeSpinBar = util_createView("CodeBlackFridaySrc.BlackFridayFreespinBarView",{machine = self})
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)

    -- respinber
    self.m_RespinBarView = util_createView("CodeBlackFridaySrc.BlackFridayRespinBerView",{machine = self})
    self:findChild("Node_respin_bar"):addChild(self.m_RespinBarView)
    self.m_RespinBarView:setVisible(false)
    self:findChild("Node_respin_bar"):setLocalZOrder(101)
end

function CodeGameScreenBlackFridayMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end

    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:refreshInfo(self.m_isSuperFree)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    util_nodeFadeIn(self.m_baseFreeSpinBar, 0.5, 0, 255, nil, function()
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_free_bar_start)
end

-- 进入free玩法走过场的时候 需要隐藏base界面的部分显示
function CodeGameScreenBlackFridayMachine:hideBaseByFree( )
    
    self:findChild("Node_shop"):setVisible(false)
    self:findChild("Node_off"):setVisible(false)

    self:setReelBg(2)
end

function CodeGameScreenBlackFridayMachine:hideFreeSpinBar()
    
end

-- 退出free玩法走过场的时候 需要显示base界面的部分显示
function CodeGameScreenBlackFridayMachine:showBaseByFree( )
    if not self.m_baseFreeSpinBar then
        return
    end

    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    
    self:findChild("Node_shop"):setVisible(true)
    self:findChild("Node_off"):setVisible(true)

    self:setReelBg(1)

end

function CodeGameScreenBlackFridayMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "BlackFridaySounds/sound_BlackFriday_scatter_buling.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenBlackFridayMachine:initGameStatusData(gameData)
    if gameData.special then
        gameData.spin.features = gameData.special.features
        gameData.spin.freespin = gameData.special.freespin
        gameData.spin.selfData = gameData.special.selfData
        gameData.spin.lines = gameData.special.lines
    end
    if not self.m_specialBets then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    CodeGameScreenBlackFridayMachine.super.initGameStatusData(self, gameData)
    self.m_shopConfig = gameData.gameConfig.extra or {}
    self.m_shopConfig.firstRound = true
    if gameData.spin then
        if gameData.spin.selfData then
            self.m_shopConfig.firstRound = gameData.spin.selfData.firstRound
        end
    end 
    self.m_isSuperFree = self.m_shopConfig.superFree

    -- 收到数据 开始计时
    if self.m_shopConfig and self.m_shopConfig.discountTime and self.m_shopConfig.discountTime > 0 then
        self.m_zheKouOffNode:runCsbAction("idle1",false)
        self:upDataDiscountTime()
    else
        self.m_zheKouOffNode:runCsbAction("idle",false)
    end
end

-- 刷新倒计时 折扣卷
function CodeGameScreenBlackFridayMachine:upDataDiscountTime( )
    
    local leftTime = tonumber(self.m_shopConfig.endTime) - (globalData.userRunData.p_serverTime/1000)

    -- 倒计时之前先显示 出来数据
    if leftTime > 0 then
        self:showTimeDown(leftTime, self.m_zheKouOffNode)

        -- 显示商店的倒计时
        self:showTimeDown(leftTime, self.m_shopView.m_discountBar)
    end

    -- 
    if self.m_timeCutDown then
        return
    end

    self.m_timeCutDown =
        schedule(
        self:findChild("Node_guochang"),
        function()
            local leftTime = tonumber(self.m_shopConfig.endTime) - (globalData.userRunData.p_serverTime/1000)

            if leftTime > 0 then
                self:showTimeDown(leftTime, self.m_zheKouOffNode)

                -- 显示商店的倒计时
                self:showTimeDown(leftTime, self.m_shopView.m_discountBar)
            else
                -- 倒计时 结束
                if self.m_timeCutDown then
                    self:stopAction(self.m_timeCutDown)
                    self.m_timeCutDown = nil
                end
                self.m_shopConfig.discountTime = 0
                
                self:showTimeDown(0, self.m_zheKouOffNode)

                self.m_zheKouOffNode:runCsbAction("over",false)
                -- 显示商店的倒计时
                self:showTimeDown(0, self.m_shopView.m_discountBar)

                self.m_shopView.m_discountBar:runCsbAction("over",false)
                if self.m_shopView:isVisible() then
                    self.m_shopView.m_isZheKou = false
                    self.m_shopView:refreshView()
                    self.m_shopView:changeCoinNodeParent()
                end
            end
        end,
        1
    )
end

--[[
    通过时间戳 得到 小时 分钟 秒
]]
function CodeGameScreenBlackFridayMachine:getHourMinuteSecond(_time)
    local hour = math.floor(_time / 3600)
    local minute = math.floor((_time % 3600) / 60)
    local second = math.floor(_time % 60)
    local second = string.format("%02d",second)

    return hour, minute, second
end

--[[
    显示倒计时 时间
]]
function CodeGameScreenBlackFridayMachine:showTimeDown(_leftTime, _node)
    local hour, minute, second = self:getHourMinuteSecond(_leftTime)
    if hour > 0 then
        _node:findChild("Node_h"):setVisible(true)
        _node:findChild("Node_m"):setVisible(false)

        _node:findChild("m_lb_num2"):setString(hour)
        _node:findChild("m_lb_num2_0"):setString(minute)
        _node:findChild("m_lb_num2_1"):setString(second)
    else
        _node:findChild("Node_h"):setVisible(false)
        _node:findChild("Node_m"):setVisible(true)

        _node:findChild("m_lb_num2_0_0"):setString(minute)
        _node:findChild("m_lb_num2_1_0"):setString(second)
    end

    
end

function CodeGameScreenBlackFridayMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_enterGame)
       
    end,0.4,self:getModuleName())
end

function CodeGameScreenBlackFridayMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    CodeGameScreenBlackFridayMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    --刷新商店积分
    self:refreshShopScore(true)

    --superFree刷新固定图标
    if self.m_isSuperFree then
        self:refreshLockWild(nil, true)
    end

    if self:findChild("Node_shop"):isVisible() then
        -- 打开提醒框
        self.m_coinCollectBar:showTip()
    end

    -- 进入关卡先初始化一遍jackpot解锁情况
    self:changeBetCallBack(nil, true)

end

function CodeGameScreenBlackFridayMachine:showShopView()
    --检测按钮是否可以点击
    if not self:collectBarClickEnabled() then
        return
    end

    if not self.m_isCanClickShop then
        return 
    end

    self:setMaxMusicBGVolume()

    self.m_shopView:showView()
end

---
-- 判断当前是否可点击
-- 商店玩法等滚动过程中不允许点击的接口
-- 返回true,允许点击
function CodeGameScreenBlackFridayMachine:collectBarClickEnabled()
    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    local bonusStates = self.m_runSpinResultData.p_bonusStatus or ""
    --

    if self.m_isWaitingNetworkData then
        return false
    elseif self:getGameSpinStage() ~= IDLE then
        return false
    elseif bonusStates == "OPEN" then
        return false
    elseif self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return false
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return false
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return false
    elseif reSpinCurCount and reSpinCurCount and reSpinCurCount > 0 and reSpinsTotalCount > 0 then
        return false
    -- elseif self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
    --     return false
    elseif #featureDatas > 1 then
        return false
    elseif self.m_isRunningEffect then
        return false
    end

    return true
end

function CodeGameScreenBlackFridayMachine:addObservers()
    CodeGameScreenBlackFridayMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            -- 切换bet解锁进度条
            self:changeBetCallBack()
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)

        if self:isNormalStates( ) then
            if self.m_iBetLevel == 0 then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_click)
                self:unlockHigherBet()
            end
        end
    end,"SHOW_UNLOCK_JACKPOT")
end

--[[
    判断是否可以点击解锁
]]
function CodeGameScreenBlackFridayMachine:isNormalStates( )
    
    local featureLen = self.m_runSpinResultData.p_features or {}

    if #featureLen >= 2 then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        return false
    end

    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return false
    end

    if self.m_bonusReconnect and self.m_bonusReconnect == true then
        return false
    end

    return true
end

--[[
    切换bet jackpot变化
]]
function CodeGameScreenBlackFridayMachine:changeBetCallBack(_betCoins, _isFirstComeIn)
    self.m_iBetLevel = 0
    local betCoins =_betCoins or globalData.slotRunData:getCurTotalBet()

    for _betLevel,_betData in ipairs(self.m_specialBets) do
        if betCoins < _betData.p_totalBetValue then
            break
        end
        self.m_iBetLevel = _betLevel
    end

    -- 上锁
    if self.m_iBetLevel == 0 then
        self.m_jackpotBar:lockGrand()
        self.m_jackpotRespinBar:lockGrand()
    -- 解锁
    else
        self.m_jackpotBar:unLockGrand(_isFirstComeIn)
        self.m_jackpotRespinBar:unLockGrand(_isFirstComeIn)
    end
end

--[[
    点击解锁jackpot
]]
function CodeGameScreenBlackFridayMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and
    self:getGameSpinStage() ~= IDLE ) or
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end

    self.m_jackpotBar:unLockGrand()
    self.m_jackpotRespinBar:unLockGrand()

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

--[[
    获取解锁进度条对应的bet
]]
function CodeGameScreenBlackFridayMachine:getMinBet()
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

function CodeGameScreenBlackFridayMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    CodeGameScreenBlackFridayMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_coinCollectBar.m_scheduleId then
        self.m_coinCollectBar:stopAction(self.m_coinCollectBar.m_scheduleId)
        self.m_coinCollectBar.m_scheduleId = nil
    end

    if self.m_jackpotBar.m_scheduleId then
        self.m_jackpotBar:stopAction(self.m_jackpotBar.m_scheduleId)
        self.m_jackpotBar.m_scheduleId = nil
    end

    if self.m_timeCutDown then
        self:stopAction(self.m_timeCutDown)
        self.m_timeCutDown = nil
    end

end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free 3respin 4商店
]]
function CodeGameScreenBlackFridayMachine:setReelBg(_BgIndex)
    
    if _BgIndex == 1 then
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("Node_base"):setVisible(true)
        self:findChild("Node_FG"):setVisible(false)

        self.m_gameBg:findChild("base_bg"):setVisible(true)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
        self.m_gameBg:findChild("respin_bg"):setVisible(false)
        self.m_gameBg:findChild("shop_bg"):setVisible(false)
    elseif _BgIndex == 2 then
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("Node_base"):setVisible(false)
        self:findChild("Node_FG"):setVisible(true)

        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(true)
        self.m_gameBg:findChild("respin_bg"):setVisible(false)
        self.m_gameBg:findChild("shop_bg"):setVisible(false)
    elseif _BgIndex == 3 then
        self.m_gameBg:findChild("shop_bg"):setVisible(false)
        self.m_gameBg:findChild("base_bg"):setVisible(false)
        self.m_gameBg:findChild("free_bg"):setVisible(false)
        self.m_gameBg:findChild("respin_bg"):setVisible(true)
        self.m_gameBg:runCsbAction("idle",false)
    elseif _BgIndex == 4 then
        self.m_gameBg:runCsbAction("start",false,function()
            self.m_gameBg:findChild("base_bg"):setVisible(false)
            self.m_gameBg:findChild("free_bg"):setVisible(false)
            self.m_gameBg:findChild("respin_bg"):setVisible(false)
            self.m_gameBg:findChild("shop_bg"):setVisible(true)
        end)
    end
end

--[[
    随机播放三种角色的idle动画
]]
function CodeGameScreenBlackFridayMachine:playJiaoSeIdleFrame( )
    
    -- 先播3个idleframe，再播一次idleframe2，再播3个idleframe再播一次idleframe3
    local jiaoseIdleList = {"idleframe","idleframe","idleframe","idleframe2","idleframe","idleframe","idleframe","idleframe3"}

    util_spinePlay(self.m_jiaoSeSpine, jiaoseIdleList[self.m_jiaoseIdleIndex], false)
    util_spineEndCallFunc(self.m_jiaoSeSpine, jiaoseIdleList[self.m_jiaoseIdleIndex], function()
        self.m_jiaoseIdleIndex = self.m_jiaoseIdleIndex + 1
        if self.m_jiaoseIdleIndex > #jiaoseIdleList then
            self.m_jiaoseIdleIndex = 1
        end
        self:playJiaoSeIdleFrame()
    end)
end

--[[
    改了播放2种角色的idle动画 free
]]
function CodeGameScreenBlackFridayMachine:playFreeJiaoSeIdle( )
    local random = math.random(1,100)
    local idleName = "idleframe5"
    if random <= 80 then
        idleName = "idleframe4"
    end
    util_spinePlay(self.m_jiaoSeSpine, idleName, false)
    util_spineEndCallFunc(self.m_jiaoSeSpine, idleName, function()
        if idleName == "idleframe5" then
            util_spinePlay(self.m_jiaoSeSpine, "idleframe4", false)
            util_spineEndCallFunc(self.m_jiaoSeSpine, "idleframe4", function()
                self:playFreeJiaoSeIdle()
            end)
        else
            self:playFreeJiaoSeIdle()
        end
    end)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBlackFridayMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BONUS1 then
        return "Socre_BlackFriday_Bonus1"
    end

    if symbolType == self.SYMBOL_BONUS2 then
        return "Socre_BlackFriday_Link2"
    end

    if symbolType == self.SYMBOL_BONUS3 then
        return "Socre_BlackFriday_Link3"
    end

    if symbolType == self.SYMBOL_BONUS4 then
        return "Socre_BlackFriday_Bonus4"
    end 

    if symbolType == self.SYMBOL_SCORE_BLANK then
        return "Socre_BlackFriday_Blank"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BlackFriday_10"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBlackFridayMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenBlackFridayMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BLANK,count =  2} 

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenBlackFridayMachine:MachineRule_initGame(  )

    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:hideBaseByFree()
        if self.m_isSuperFree then
            --平均bet值 展示
            self.m_bottomUI:showAverageBet()

            self:setReelBg(3)
        else
            self:setReelBg(2)
        end

        self:playFreeJiaoSeIdle()
    end

end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBlackFridayMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBlackFridayMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

-- 显示free spin
function CodeGameScreenBlackFridayMachine:showEffect_FreeSpin(effectData)
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

    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end

    if scatterLineValue ~= nil then
        --
        -- 角色动画
        util_spinePlay(self.m_jiaoSeSpine, "actionframe_chufa", false)

        local waitTime = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        
                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                        end
                        slotNode:runAnim("actionframe", false)

                        local duration = slotNode:getAniamDurationByName("actionframe")
                        waitTime = util_max(waitTime,duration)
                    end
                end
            end
        end

        self:waitWithDelay(waitTime,function()
            self:showFreeSpinView(effectData)
        end)

        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            -- 播放提示时播放音效
            self:playScatterTipMusicEffect()
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_freeMore_trigger)
        end
        
    else
        --
        self:showFreeSpinView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenBlackFridayMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("BlackFridaySounds/music_BlackFriday_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        local view = nil
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self.m_isTriggerFreeMore = true
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_freeMore)

            view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:playGuoChangFree(function()
                    if self.m_isSuperFree then
                        --平均bet值 展示
                        self.m_bottomUI:showAverageBet()
                    end
                    self:hideBaseByFree()

                    self:changeLowSymbolFree()

                end,function()
                    --清空赢钱
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
                    
                    self:triggerFreeSpinCallFun()

                    effectData.p_isPlay = true
                    self:playGameEffect()  
                end, true) 
            end)
        end

        -- 弹板上的光
        local tanbanShine = util_createAnimation("BlackFriday_FreeSpin_guang.csb")
        view:findChild("guang"):addChild(tanbanShine)
        tanbanShine:runCsbAction("idle",true)
        util_setCascadeOpacityEnabledRescursion(view:findChild("guang"), true)
        util_setCascadeColorEnabledRescursion(view:findChild("guang"), true)
        
        -- 弹板闪烁
        local tanbanShanShuo = util_createAnimation("BlackFriday_shanshuo.csb")
        view:findChild("shanshuo"):addChild(tanbanShanShuo)
        tanbanShanShuo:runCsbAction("idle",true)
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFSView()    
    end,0.1)

end

---------------------------------弹版----------------------------------
function CodeGameScreenBlackFridayMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local view = nil
    if self.m_isSuperFree then
        view = self:showDialog("SuperFreeSpinStart", ownerlist, func)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_click
        view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_superfree_start_xiaoshi
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_superfree_start_chuxian)
    else
        
        if isAuto then
            view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
        else
            view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
        end
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_click
        view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_free_start_xiaoshi
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_free_start_chuxian)
    end

    return view
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

-- 进入free玩法的时候 移除低级图标 换成随机的高级图标
function CodeGameScreenBlackFridayMachine:changeLowSymbolFree( )
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType then
                if symbolNode.p_symbolType >= 5 and symbolNode.p_symbolType <= 9 then
                    local random = math.random(0,4)
                    self:changeSymbolType(symbolNode, random)
                end
            end
        end
    end
end

-- 过场动画
function CodeGameScreenBlackFridayMachine:playGuoChangFree(_func1, _func2, _isPlayFreeIdle)
    -- 22帧 播放音效
    self:waitWithDelay(22/30,function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_free_guochang)
    end)

    self.m_guochangFreeEffect:setVisible(true)
    util_spinePlay(self.m_guochangFreeEffect, "actionframe_guochang", false)

    -- switch  35帧
    util_spineFrameCallFunc(self.m_guochangFreeEffect, "actionframe_guochang", "switch", function()
        if _func1 then
            _func1()
        end
    end, function()
        self.m_guochangFreeEffect:setVisible(false)
        if _func2 then
            _func2()
        end
    end)

    -- 角色动画
    util_spinePlay(self.m_jiaoSeSpine, "actionframe_guochang", false)
    -- 35帧 切换角色
    self:waitWithDelay(35/30,function()
        if _isPlayFreeIdle then
            self:playFreeJiaoSeIdle()
        else
            self.m_jiaoseIdleIndex = 1
            self:playJiaoSeIdleFrame()
        end
    end)
end

function CodeGameScreenBlackFridayMachine:showFreeSpinOverView()

    if globalData.slotRunData.lastWinCoin == 0 then
        local view = self:showDialog("FreeSpinOver_NoWins", {}, function()
            self:playGuoChangFree(function()
                self:showBaseByFree()
                if self.m_isSuperFree then
                    --平均bet值 隐藏
                    self.m_bottomUI:hideAverageBet()
                end
            end,function()
                if self.m_isSuperFree then
                    self.m_fsReelDataIndex = 0
                    -- 添加superfreespin effect back
                    local superfreeSpinEffect = GameEffectData.new()
                    superfreeSpinEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    superfreeSpinEffect.p_effectOrder = self.SUPER_FREE_BACK_OPENSHOP_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = superfreeSpinEffect
                    superfreeSpinEffect.p_selfEffectType = self.SUPER_FREE_BACK_OPENSHOP_EFFECT -- 动画类型           
                end
                self.m_isSuperFree = false
                
                self:triggerFreeSpinOverCallFun()

                -- free玩法结束 判断是否 需要弹出jackpot tips
                self.m_jackpotBar:checkIsNeedOpenTips()
            end, false)
        end)
        view:findChild("root"):setScale(self.m_machineRootScale)
    else
        local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin,30)
        local view = self:showFreeSpinOver( strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:playGuoChangFree(function()
                self:showBaseByFree()
                if self.m_isSuperFree then
                    --平均bet值 隐藏
                    self.m_bottomUI:hideAverageBet()
                end
            end,function()

                if self.m_isSuperFree then
                    -- 添加superfreespin effect back
                    local superfreeSpinEffect = GameEffectData.new()
                    superfreeSpinEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    superfreeSpinEffect.p_effectOrder = self.SUPER_FREE_BACK_OPENSHOP_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = superfreeSpinEffect
                    superfreeSpinEffect.p_selfEffectType = self.SUPER_FREE_BACK_OPENSHOP_EFFECT -- 动画类型           
                end
                self.m_isSuperFree = false

                self:triggerFreeSpinOverCallFun()

                -- free玩法结束 判断是否 需要弹出jackpot tips
                self.m_jackpotBar:checkIsNeedOpenTips()
                
            end, false)
        end)
        view:findChild("root"):setScale(self.m_machineRootScale)

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},650)
    end

end

function CodeGameScreenBlackFridayMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view = nil
    if self.m_isSuperFree then
        --清理固定图标
        self:clearLockWild()
        view = self:showDialog("SuperFreeSpinOver", ownerlist, func)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_click
        view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_superfree_over_xiaoshi
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_superfree_over_chuxian)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_click
        view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_free_over_xiaoshi
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_free_over_chuxian)
    end

    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end


function CodeGameScreenBlackFridayMachine:beginReel()
    
    --superfree显示固定wild
    if self.m_isSuperFree then
        -- superfree 第一次 需要显示 棋盘遮罩
        if self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
            
        else
            for index, wildNode in ipairs(self.m_lockWilds) do
                wildNode:setVisible(true)
            end
        end
        self.m_fsReelDataIndex = 1
        
    end

    self.m_isShowJiaoBiao = true
    self.m_isQuicklyStop = false
    self.m_isPlayBulingSound = true
    for i=1,5 do
        self.m_isPlayBonus1Buling[i] = true
    end

    CodeGameScreenBlackFridayMachine.super.beginReel(self)

end

function CodeGameScreenBlackFridayMachine:normalSpinBtnCall( )
    -- 商店打开的话 点击 spin 关闭商店
    if self.m_shopView:isVisible() then
        self.m_shopView:cheakIsCanClick(function()
            self.m_shopView:hideView()
        end)
        return
    end

    CodeGameScreenBlackFridayMachine.super.normalSpinBtnCall(self)
    self:setMaxMusicBGVolume( )
    self:removeSoundHandler()
    
end
--[[
    superfree 第一次 需要显示 棋盘遮罩 和 wild 出现的爆炸
]]
function CodeGameScreenBlackFridayMachine:superFreeDarkEffect(_func)
    self.m_superFreeQiPanDark:setVisible(true)
    self.m_superFreeQiPanDark:runCsbAction("start",false,function()
        self.m_superFreeQiPanDark:runCsbAction("idle",false)

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_superfree_add_wild)

        for index, wildNode in ipairs(self.m_lockWilds) do
            local wildBaoZhaNode = util_createAnimation("BlackFriday_qipan_gdwild_tx.csb")
            self:findChild("Node_guochang"):addChild(wildBaoZhaNode,1)

            wildBaoZhaNode:setPosition(cc.p(wildNode:getPosition()))

            wildBaoZhaNode:runCsbAction("actionframe",false,function()
                wildBaoZhaNode:removeFromParent()
                wildBaoZhaNode = nil
            end)
        end

        -- 爆炸 25帧 wild出现
        self:waitWithDelay(25/60,function()
            for index, wildNode in ipairs(self.m_lockWilds) do
                wildNode:setVisible(true)
            end
        end)

        -- 爆炸的时间 54帧 走完播 遮罩over
        self:waitWithDelay(54/60,function()
            self.m_superFreeQiPanDark:runCsbAction("over",false,function()
                self.m_superFreeQiPanDark:setVisible(false)
            end)
            if _func then
                _func()
            end
        end)
    end)
end

---
-- 点击快速停止reel
--
function CodeGameScreenBlackFridayMachine:quicklyStopReel(colIndex)
    self.m_isQuicklyStop = true
    CodeGameScreenBlackFridayMachine.super.quicklyStopReel(self, colIndex)
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBlackFridayMachine:MachineRule_SpinBtnCall()
    -- self:setMaxMusicBGVolume( )
   
    if self.m_coinCollectBar.m_scheduleId then
        self.m_coinCollectBar:hideTip()
    end

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
function CodeGameScreenBlackFridayMachine:addSelfEffect()

    --收集商店积分
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.score then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_SHOP_SCORE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_SHOP_SCORE_EFFECT -- 动画类型
    end

    --收集 信封打开
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local specialBonus = selfData.specialBonus or {}

    if #specialBonus > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_ENVELOPE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_ENVELOPE_EFFECT -- 动画类型
    end
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBlackFridayMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_SHOP_SCORE_EFFECT then --收集商店积分

        self:collectShopScoreEffect(effectData)

    elseif effectData.p_selfEffectType == self.COLLECT_ENVELOPE_EFFECT then --收集 信封打开之后 的物品

        self:waitWithDelay(15/30,function()
            self:collectEnvelopeResultEffect(effectData)
        end)

    elseif effectData.p_selfEffectType == self.SUPER_FREE_BACK_OPENSHOP_EFFECT then

        local isSuperFreeBack = false
    
        if self.m_shopConfig.firstRound then
            isSuperFreeBack = true
        end

        effectData.p_isPlay = true
        self:playGameEffect()

        self.m_shopView:showView(isSuperFreeBack)

    end

	return true
end

-- 滚动出来 信封小块之后 的处理
function CodeGameScreenBlackFridayMachine:collectEnvelopeResultEffect(effectData)
    self.m_isCanClickShop = false

    local score = 0
    local discountTime = 30
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.coins then
        score = self.m_runSpinResultData.p_selfMakeData.coins or 0
        if score == 0 then
            score = self.m_shopConfig.coins or 0
        else --刷新配置中的积分数量
            self.m_shopConfig.coins = score
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local specialBonus = selfData.specialBonus or {}

    local isFirst = true
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS4 then
                local symbol_node = symbolNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                local actionName1 = "actionframe"
                local actionName2 = "fly"

                -- 折扣卷
                if specialBonus[1] and specialBonus[1][2] and specialBonus[1][2] == "time" then
                    discountTime = specialBonus[1][3]
                    -- spineNode.m_csbNodeDiscount:findChild("Node_1"):setVisible(true)
                    -- spineNode.m_csbNodeDiscount:findChild("Node_2"):setVisible(false)
                    actionName1 = "actionframe2"
                    actionName2 = "fly2"
                    --设置皮肤
                    spineNode:setSkin("min_"..discountTime)
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus4_trigger1)
                else
                    -- -- 金币
                    spineNode.m_csbNodeDiscount:setVisible(true)
                    spineNode.m_csbNodeDiscount:findChild("Node_1"):setVisible(false)
                    spineNode.m_csbNodeDiscount:findChild("Node_2"):setVisible(true)
                    spineNode.m_csbNodeDiscount:findChild("m_lb_coins"):setString(specialBonus[1][3])
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus4_trigger2)
                end

                symbolNode:runAnim(actionName1,false,function()
                    symbolNode:runAnim(actionName2,false,function()
                        symbolNode:runAnim("idleframe2",true)
                    end)

                    spineNode.m_csbNodeDiscount:setVisible(false)

                    self:flyCollectBonus4Result(score, spineNode, specialBonus, function()
                        if #specialBonus <= 0 then
                            return
                        end
                        if specialBonus[1] and specialBonus[1][2] and specialBonus[1][2] == "time" then
                            self.m_zheKouOffNode:runCsbAction("actionframe",false)
                            
                            -- actionframe 40帧开始刷新倒计时
                            self:waitWithDelay(40/60,function()
                                self.m_shopConfig.endTime = selfData.endTime
                                self.m_shopConfig.discountTime = selfData.discountTime

                                -- 开始倒计时
                                self:upDataDiscountTime()
                            end)
                        else
                            self.m_coinCollectBar:runCsbAction("actionframe",false,function()
                                self.m_coinCollectBar:runCsbAction("idle",true)
                            end)
                            --刷新商店积分
                            self.m_coinCollectBar:updateCoins(score)
                        end
                    end,discountTime)

                    if isFirst then
                        isFirst = false
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                end)

                -- actionframe 第15帧的时候 可以点击商店
                self:waitWithDelay(15/30,function()
                    self.m_isCanClickShop = true
                end)
            end
        end
    end
end

--[[
    飞 收集 bonus4 信封打开之后 的折扣卷 或者 金币
]]
function CodeGameScreenBlackFridayMachine:flyCollectBonus4Result(_score, _startNode, _specialBonus, _func, _discountTime)

    if #_specialBonus <= 0 then
        if type(_func) == "function" then
            _func()
        end
        return
    end

    local flyNode = util_createAnimation("BlackFriday_bonus_off.csb")
    local endNode = self.m_coinCollectBar:findChild("Node_baozha")
    local startPos = nil
    local moveTime = 14/30

    if _specialBonus[1] and _specialBonus[1][2] and _specialBonus[1][2] == "time" then
        endNode = self.m_zheKouOffNode:findChild("Node_baozha")
        flyNode:findChild("Node_1"):setVisible(true)
        flyNode:findChild("Node_2"):setVisible(false)
        startPos = util_convertToNodeSpace(_startNode,self.m_effectNode)
        startPos.y = startPos.y + 20
        moveTime = 7/30
        local discountName = {"mins_30", "mins_60", "mins_90"}
        for k,vName in pairs(discountName) do
            flyNode:findChild(vName):setVisible(false)
        end
        if _discountTime then
            flyNode:findChild("mins_".._discountTime):setVisible(true)
        end
    else
        flyNode:findChild("m_lb_coins"):setString(_specialBonus[1][3])
        flyNode:findChild("Node_1"):setVisible(false)
        flyNode:findChild("Node_2"):setVisible(true)
        startPos = util_convertToNodeSpace(_startNode.m_csbNodeDiscount,self.m_effectNode)
    end

    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    flyNode:runCsbAction("fly",false)

    local seq = cc.Sequence:create({
        cc.EaseCubicActionIn:create(cc.MoveTo:create(moveTime,endPos)),
        cc.CallFunc:create(function()

            if type(_func) == "function" then
                _func()
            end

            flyNode:removeFromParent()
        end),
    })

    flyNode:runAction(seq)
end

-- 收集商店金币的动画
function CodeGameScreenBlackFridayMachine:collectShopScoreEffect(effectData)
    local score = 0
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.coins then
        score = self.m_runSpinResultData.p_selfMakeData.coins or 0
        if score == 0 then
            score = self.m_shopConfig.coins or 0
        else --刷新配置中的积分数量
            self.m_shopConfig.coins = score
        end
    end
    -- 收集金币的同时有bonus4 开出金币
    -- 先播放的收集金币动画 后播放bonus4动画
    -- 所以收集金币的时候 刷新金币总数 减去bonus4的金币
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local specialBonus = selfData.specialBonus or {}
    if specialBonus[1] and specialBonus[1][2] and specialBonus[1][2] == "coins" then
        if specialBonus[1][3] then
            score = score - specialBonus[1][3]
        end
    end

    -- 收集的同时 还有别的事件的话 等收集完在播其他的
    local isDelayPlay = false
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == GameEffect.EFFECT_FREE_SPIN or effectData.p_effectType == GameEffect.EFFECT_RESPIN then
            isDelayPlay = true
        end
        if effectData.p_effectType == self.COLLECT_ENVELOPE_EFFECT then
            isDelayPlay = false
            break
        end
    end

    local isFirst = true
    local isPlaySound = true
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.m_scoreItem and symbolNode.m_scoreItem.score > 0 then
                symbolNode.m_scoreItem:setVisible(false)
                self:flyCollectShopScore(symbolNode.m_scoreItem.score,symbolNode.m_scoreItem,self.m_coinCollectBar:findChild("Node_baozha"),function()
                    if isFirst then
                        isFirst = false
                        self.m_coinCollectBar:runCsbAction("actionframe",false,function()
                            self.m_coinCollectBar:runCsbAction("idle",true)
                        end)
                        --刷新商店积分
                        self.m_coinCollectBar:updateCoins(score)

                        if isDelayPlay then
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end
                end,isPlaySound)
                if isPlaySound then
                    isPlaySound = false
                end
            end
        end
    end

    if not isDelayPlay then
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

--[[
    收集商店积分
]]
function CodeGameScreenBlackFridayMachine:flyCollectShopScore(_score, _startNode, _endNode, _func, _isPlaySound)
    local flyNode = util_createAnimation("BlackFriday_shop_coin.csb")
    flyNode:findChild("m_lb_num"):setString(_score)

    local startPos = util_convertToNodeSpace(_startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(_endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    if flyNode:findChild("Particle_1") then
        flyNode:findChild("Particle_1"):setVisible(false)
        flyNode:findChild("Particle_1"):setDuration(1)     --设置拖尾时间(生命周期)
        flyNode:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
    end

    flyNode:runCsbAction("fly",false)

    if _isPlaySound then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_jiaobiao_collect)
    end

    local seq = cc.Sequence:create({
        cc.DelayTime:create(10/60),
        cc.CallFunc:create(function()
            if flyNode:findChild("Particle_1") then
                flyNode:findChild("Particle_1"):setVisible(true)
                flyNode:findChild("Particle_1"):resetSystem()
            end
            self:waitWithDelay(14/60, function()
                if type(_func) == "function" then
                    _func()
                end
            end)
        end),
        cc.MoveTo:create(18/60,endPos),
        cc.CallFunc:create(function()

            if _isPlaySound then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_jiaobiao_fankui)
            end
            if flyNode:findChild("Particle_1") then
                flyNode:findChild("Particle_1"):stopSystem()
            end
            flyNode:findChild("Node_1"):setVisible(false)

            self:waitWithDelay(0.5, function()
                flyNode:removeFromParent()
            end)
        end),
    })

    flyNode:runAction(seq)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBlackFridayMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenBlackFridayMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenBlackFridayMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenBlackFridayMachine:slotReelDown( )

    if #self.m_lockWilds > 0 then
        for index, wildNode in ipairs(self.m_lockWilds) do
            wildNode:setVisible(false)
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenBlackFridayMachine.super.slotReelDown(self)
end

function CodeGameScreenBlackFridayMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenBlackFridayMachine:updateReelGridNode(symbolNode)
    if symbolNode.m_scoreItem then
        symbolNode.m_scoreItem:setVisible(false)
        symbolNode.m_scoreItem.score = 0
    end

    -- 收集金币相关
    if symbolNode:isLastSymbol() and self.m_isShowJiaoBiao then
        self:createCollectCoinsByNode(symbolNode)
    end

    local symbolType = symbolNode.p_symbolType
    if symbolType == self.SYMBOL_BONUS1 then
        self:setSpecialNodeScore(self,{symbolNode})
    end

    if symbolType == self.SYMBOL_BONUS4 then
        self:setSpecialNodeResult(self,{symbolNode})
    end

    if symbolType == self.SYMBOL_BONUS3 then
        self:setSpecialNodeBonus3(self,{symbolNode})
    end
end

--[[
    创建角标
]]
function CodeGameScreenBlackFridayMachine:createCollectCoinsByNode(_symbolNode)
    local reelsIndex = self:getPosReelIdx(_symbolNode.p_rowIndex, _symbolNode.p_cloumnIndex)
        
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.score then
        local collectScore = selfData.score[reelsIndex + 1]
        if collectScore and collectScore > 0 then
            
            --创建积分角标
            if not _symbolNode.m_scoreItem then
                _symbolNode.m_scoreItem =  util_createAnimation("BlackFriday_shop_coin.csb")
                _symbolNode:addChild(_symbolNode.m_scoreItem,1000)
                local symbolSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH)
                local size = _symbolNode.m_scoreItem:findChild('di'):getContentSize()
                local scale = _symbolNode.m_scoreItem:findChild('di'):getScale()
                size.width = size.width * scale
                size.height = size.height * scale
                _symbolNode.m_scoreItem:setPosition(cc.p(symbolSize.width / 2 - size.width / 2,-symbolSize.height / 2 + size.height / 2))
            end
            _symbolNode.m_scoreItem:setVisible(true)
            _symbolNode.m_scoreItem.score = collectScore
            _symbolNode.m_scoreItem:findChild("m_lb_num"):setString(collectScore)
        end
    end
end

--[[
     给 bonus3 小块进行 挂载钻石
]]
function CodeGameScreenBlackFridayMachine:setSpecialNodeBonus3(sender,param)
    local symbolNode = param[1]

    if not symbolNode then
        return
    end

    if not symbolNode.p_symbolType then
        return
    end

    --创建钻石
    if not symbolNode:getCcbProperty("spine"):getChildren() or #symbolNode:getCcbProperty("spine"):getChildren() <= 0 then
        local spineNode = util_spineCreate("Socre_BlackFriday_Link3",true,true)
        symbolNode:getCcbProperty("spine"):addChild(spineNode)
        util_spinePlay(spineNode,"idleframe",false)
        if self.m_comeInReSpin then
            spineNode:setVisible(false)
        end
    else
        local child = symbolNode:getCcbProperty("spine"):getChildren()
        for spineIndex = 1, #child do
            util_spinePlay(child[spineIndex],"idleframe",false)
            if self.m_comeInReSpin then
                child[spineIndex]:setVisible(false)
            else
                child[spineIndex]:setVisible(true)
            end
        end
    end

    -- bonus3 上如果有文字的话
    if not symbolNode:getCcbProperty("wenzi"):getChildren() or #symbolNode:getCcbProperty("wenzi"):getChildren() <= 0 then
        -- 没有文字 新创建
        local coinsView = util_createAnimation("Socre_BlackFriday_Link1Zi.csb")
        symbolNode:getCcbProperty("wenzi"):addChild(coinsView)
        if self.m_comeInReSpin then
            if symbolNode.p_symbolType == self.SYMBOL_BONUS3 then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                coinsView:findChild("BitmapFontLabel_1"):setVisible(true)
                coinsView:findChild("BitmapFontLabel_1"):setString(util_formatCoins(1 * lineBet, 3))
                self:updateLabelSize({label = coinsView:findChild("BitmapFontLabel_1"),sx = 0.9,sy = 0.9}, 142)
            end
        else
            coinsView:setVisible(false)
        end
    else
        local child = symbolNode:getCcbProperty("wenzi"):getChildren()
        for spineIndex = 1, #child do
            if self.m_comeInReSpin then
                if symbolNode.p_symbolType == self.SYMBOL_BONUS3 then
                    local lineBet = globalData.slotRunData:getCurTotalBet()
                    child[spineIndex]:findChild("BitmapFontLabel_1"):setVisible(true)
                    child[spineIndex]:runCsbAction("idleframe",false)
                    child[spineIndex]:findChild("BitmapFontLabel_1"):setString(util_formatCoins(1 * lineBet, 3))
                    self:updateLabelSize({label = child[spineIndex]:findChild("BitmapFontLabel_1"),sx = 0.9,sy = 0.9}, 142)
                end
            else
                child[spineIndex]:setVisible(false)
            end
        end
    end
    symbolNode:runAnim("idle",false)
end

--[[
     给 bonus4 小块进行赋值
]]
function CodeGameScreenBlackFridayMachine:setSpecialNodeResult(sender,param)
    local symbolNode = param[1]

    if not symbolNode then
        return
    end

    if not symbolNode.p_symbolType then
        return
    end

    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local coinsView
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()

    --创建折扣卷
    if not spineNode.m_csbNodeDiscount then
        coinsView = util_createAnimation("BlackFriday_bonus_off.csb")
        util_spinePushBindNode(spineNode,"guadian",coinsView)
        spineNode.m_csbNodeDiscount = coinsView
        spineNode.m_csbNodeDiscount:setVisible(false)
    else
        spineNode.m_csbNodeDiscount:setVisible(false)
    end
end

--[[
     给respin小块进行赋值
]]
function CodeGameScreenBlackFridayMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local miniIndex = param[2]

    if not symbolNode then
        return
    end

    if not symbolNode.p_symbolType then
        return
    end

    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if #symbolNode:getCcbProperty("bonusSpine"):getChildren() > 0 then
        local child = symbolNode:getCcbProperty("bonusSpine"):getChildren()
        for spineIndex = 1, #child do
            child[spineIndex]:removeFromParent()
            child[spineIndex] = nil
        end
    end
    local spineNode = util_spineCreate("Socre_BlackFriday_Link1",true,true)
    symbolNode:getCcbProperty("bonusSpine"):addChild(spineNode)
    util_spinePlay(spineNode,"idleframe",false)

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        if miniIndex then
            score = self.m_miniMachine[miniIndex]:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        end
        local index = 0
        if score ~= nil then
            
            local lineBet = globalData.slotRunData:getCurTotalBet()

            if symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
                symbolNode:getCcbProperty("BitmapFontLabel_1"):setString(util_formatCoins(score * lineBet, 3))
                self:updateLabelSize({label = symbolNode:getCcbProperty("BitmapFontLabel_1"),sx = 0.9,sy = 0.9}, 142)
            end
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if miniIndex then
            score = self.m_miniMachine[miniIndex]:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        end

        local lineBet = globalData.slotRunData:getCurTotalBet()
        if symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
            symbolNode:getCcbProperty("BitmapFontLabel_1"):setString(util_formatCoins(score * lineBet, 3))
            self:updateLabelSize({label = symbolNode:getCcbProperty("BitmapFontLabel_1"),sx = 0.9,sy = 0.9}, 142)
        end
    end
end

function CodeGameScreenBlackFridayMachine:randomDownRespinSymbolScore(_symbolType)
    local score = nil
    
    if _symbolType == self.SYMBOL_BONUS1 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

function CodeGameScreenBlackFridayMachine:playCustomSpecialSymbolDownAct( slotNode )

    if slotNode and slotNode.p_symbolType == self.SYMBOL_BONUS1 then 
        if self:getIsPlayBonusBuling(slotNode.p_cloumnIndex) then
            slotNode:runAnim("buling",false)
            -- bonus1上面的数字 动画
            self:playBonus1CoinsEffect(slotNode, "buling", "idleframe2")
            if self.m_isPlayBulingSound then
                if self.m_isPlayBonus1Buling[slotNode.p_cloumnIndex] then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus1Buling)
                    self.m_isPlayBonus1Buling[slotNode.p_cloumnIndex] = false
                end
            end

            if self.m_isQuicklyStop then
                self.m_isPlayBulingSound = false
            end
        end
    end

    if slotNode and slotNode.p_symbolType == self.SYMBOL_BONUS4 then 
        local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)
        slotNode:runAnim("buling",false)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus4_buling)
    end
end

--[[
    判断是否播放bonus的落地buling
    5个 bonus 触发玩法
    前三列 必播 ，前四列超过2个 第四列必播，棋盘超五个 第五列必播
]]
function CodeGameScreenBlackFridayMachine:getIsPlayBonusBuling(_iCol)
    if _iCol <= 3 then
        return true
    elseif _iCol == 4 then
        local bonusNum = 0
        for iCol = 1,self.m_iReelColumnNum - 1 do
            for iRow = 1,self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(iCol,iRow)
                if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
                    bonusNum = bonusNum + 1
                end
            end
        end
        if bonusNum >= 2 then
            return true
        else
            return false
        end
    elseif _iCol == 5 then
        local bonusNum = 0
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                local symbolNode = self:getFixSymbol(iCol,iRow)
                if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
                    bonusNum = bonusNum + 1
                end
            end
        end
        if bonusNum >= 5 then
            return true
        else
            return false
        end
    end
end

--[[
    根据网络数据获得Bonus小块的分数
]]
function CodeGameScreenBlackFridayMachine:getReSpinSymbolScore(_id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local score = nil
    local idNode = nil
    local symbolType = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == _id then
            score = values[3]
            symbolType = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
       return 0
    end

    return score
end

--[[
    延时函数
]]
function CodeGameScreenBlackFridayMachine:waitWithDelay(time, endFunc)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(endFunc) == "function" then
                endFunc()
            end
        end,
        time
    )

    return waitNode
end

-- respin过场
function CodeGameScreenBlackFridayMachine:playReSpinChangeGuoChang(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_guochang)

    util_spinePlay(self.m_jiaoSeSpine, "actionframe", false)
    self:waitWithDelay(55/30,function()
        self.m_guochangRespinEffect:setVisible(true)
        util_spinePlay(self.m_guochangRespinEffect, "actionframe_guochang2", false)

        -- 60帧 切换场景
        self:waitWithDelay(60/30,function()
            if _func1 then
                _func1()
            end
        end)

        -- 105帧 弹出说明弹板
        self:waitWithDelay(105/30,function()
            if _func2 then
                _func2()
            end
        end)

        -- 过场 总时长 144帧
        self:waitWithDelay(144/30,function()
            self.m_guochangRespinEffect:setVisible(false)
        end)
    end)
end

-- respin过场
function CodeGameScreenBlackFridayMachine:playReSpinChangeGuoChangOver(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_over_guochang)

    self.m_guochangRespinOverEffect:setVisible(true)
    util_spinePlay(self.m_guochangRespinOverEffect, "actionframe_guochang3", false)

    -- 50帧 切换场景
    self:waitWithDelay(50/30,function()
        if _func1 then
            _func1()
        end
    end)

    -- 过场 总时长 104帧
    self:waitWithDelay(104/30,function()
        self.m_guochangRespinOverEffect:setVisible(false)
        if _func2 then
            _func2()
        end
    end)
end

-- 显示当前的小轮盘上面的板子
function CodeGameScreenBlackFridayMachine:showReSpinMiNiBanzi(_isPlayEffect, _func)
    -- 没有滚动出来 bonus3 不需要升行 
    if _isPlayEffect and #self.m_bonus3List <= 0 then
        if _func then
            _func()
        end
        return
    end

    local isFirst = true
    local isFirstPlay = true
    if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.Row then
        local isPlaySound = true
        -- 行数最大为9行 防止 服务器数据大于9 
        if self.m_runSpinResultData.p_rsExtraData.Row > 9 then
            self.m_runSpinResultData.p_rsExtraData.Row = 9
        end
        -- 计算属于第几个小轮盘
        local miniIndex = math.floor(self.m_runSpinResultData.p_rsExtraData.Row / self.m_MiNiTotalNum)
        -- 计算属于小轮盘的第几个板子
        local miniBanZiIndex = self.m_runSpinResultData.p_rsExtraData.Row % self.m_MiNiTotalNum

        local dangbanEffectFunc = function(dangBanNode)
            if dangBanNode:isVisible() then
                if _isPlayEffect then
                    if self.m_bonus3List[1] then
                        local bonus3Node = clone(self.m_bonus3List[1])
                        table.remove(self.m_bonus3List, 1)

                        self:isNeedCloseDangBanTips()

                        self:playBonus3FlyEffect(bonus3Node, dangBanNode, function()
                            dangBanNode.isPlayEffect = true
                            util_spinePlay(dangBanNode,"actionframe")

                            util_spineEndCallFunc(dangBanNode,"actionframe",function ()
                                dangBanNode:setVisible(false)

                                if isFirstPlay then
                                    isFirstPlay = false
                                    self:waitWithDelay(0.5,function()
                                        self:isNeedShowDangBanTips()
                                    end)
                                end
                            end)
                        end, function()
                            -- 继续下面 流程
                            if isFirst then
                                isFirst = false

                                if _func then
                                    _func()
                                end
                            end
                        end, isPlaySound)
                        if isPlaySound then
                            isPlaySound = false
                        end
                    end
                else
                    dangBanNode:setVisible(false)
                end
            end
        end

        for miniReelIndex = 1, miniIndex do
            for banziIndex=1,3 do
                local dangBanNode = self.m_miniMachine[miniReelIndex]["banzi"..banziIndex]
                dangbanEffectFunc(dangBanNode)
            end
        end

        -- 表示整个的小轮盘板子 都打开了
        if miniBanZiIndex ~= 0 then
            for banziIndex=1,miniBanZiIndex do
                local dangBanNode = self.m_miniMachine[miniIndex+1]["banzi"..banziIndex]
                dangbanEffectFunc(dangBanNode)
            end
        end
    end
end

--[[
    播放respin挡板上面的 idle 
    每隔5帧播一个idle 依次播放 播放一轮后 空80帧 在播一次 以此类推
    self.m_respinMiniIndex = 2
    self.m_respinBanZiIndex = 1
]]
function CodeGameScreenBlackFridayMachine:playRespinBanZiIdle()
    if not self.m_isReSpin then
        return
    end

    if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.Row then
        -- 行数最大为9行 全部挡板打开不在播放扫光
        if self.m_runSpinResultData.p_rsExtraData.Row >= 9 then
            return
        end
    end

    local delayTime = 5/30
    local dangBanNode = self.m_miniMachine[self.m_respinMiniIndex]["banzi"..self.m_respinBanZiIndex]

    self.m_respinBanZiIndex = self.m_respinBanZiIndex + 1
    if self.m_respinMiniIndex == 2 and self.m_respinBanZiIndex > 3 then
        self.m_respinMiniIndex = 3
        self.m_respinBanZiIndex = 1
    end
    
    if self.m_respinMiniIndex == 3 and self.m_respinBanZiIndex > 3 then
        self.m_respinMiniIndex = 2
        self.m_respinBanZiIndex = 1
        delayTime = 80/30
    end

    if not dangBanNode:isVisible() or dangBanNode.isPlayEffect then
        self:playRespinBanZiIdle()
        return
    end

    util_spinePlay(dangBanNode,"idleframe",false)
    
    self:waitWithDelay(delayTime,function()
        self:playRespinBanZiIdle()
    end)
end

--[[
    respin 棋盘滚动出来 bonus3之后 存在列表
    miniMachineIndex 表示mini轮盘的index 1 2 3
]]
function CodeGameScreenBlackFridayMachine:addBonus3List(_node, _miniMachineIndex)
    
    self.m_bonus3List[#self.m_bonus3List + 1] = _node
    self.m_bonus3MiniMachineList[#self.m_bonus3MiniMachineList + 1] = _miniMachineIndex

end

--[[
    显示小棋盘 集满的棋盘动画
]]
function CodeGameScreenBlackFridayMachine:showMiniQiPanEffect(_miniMachineIndex)
    if self.m_miniMachine[_miniMachineIndex].qiPanEffect:isVisible() then
        return false
    end

    self:showMiniQiPanTriggerEffect(_miniMachineIndex, function()
        self.m_miniMachine[_miniMachineIndex].qiPanEffect:setVisible(true)
        self.m_miniMachine[_miniMachineIndex].qiPanEffect:runCsbAction("idle",true)
    end)

    return true
end

--[[
    棋盘集满的触发动画
]]
function CodeGameScreenBlackFridayMachine:showMiniQiPanTriggerEffect(_miniMachineIndex, _func)
    --提层的时候 用来判断
    -- self.m_isNeedChangeNode = true
    --mini棋盘提层
    -- util_changeNodeParent(self:findChild("Node_respin_new_qipan".._miniMachineIndex), self.m_miniMachine[_miniMachineIndex])
    self.m_miniMachine[_miniMachineIndex]:getParent():setLocalZOrder(100)
    -- self.m_isNeedChangeNode = false
    if self.m_respinQiPanJimanPlaySound then
        self.m_respinQiPanJimanPlaySound = false
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_qipan_jiman)
    end

    self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine:setVisible(true)
    self.m_miniMachine[_miniMachineIndex].qiPanJiManEffect:setVisible(true)
    util_spinePlay(self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine,"actionframe",false)
    for i=1,4 do
        local liZiNode = self.m_miniMachine[_miniMachineIndex].qiPanJiManEffect
        liZiNode:findChild("Particle_"..i):resetSystem()
    end

    if not self.m_qiPanJiManDark:isVisible() then
        self.m_qiPanJiManDark:setVisible(true)
        self.m_qiPanJiManDark:runCsbAction("actionframe", false)
    end

    self:waitWithDelay(120/60,function()
        if _func then
            _func()
        end
    end)

    self:waitWithDelay(140/60,function()
        -- self.m_isNeedChangeNode = true
        --还原 mini棋盘提层
        self.m_miniMachine[_miniMachineIndex]:getParent():setLocalZOrder(0)
        -- util_changeNodeParent(self:findChild("Node_respin_qipan".._miniMachineIndex), self.m_miniMachine[_miniMachineIndex])
        -- self.m_isNeedChangeNode = false

        self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine:setVisible(false)
        self.m_miniMachine[_miniMachineIndex].qiPanJiManEffect:setVisible(false)
        self.m_qiPanJiManDark:setVisible(false)
    end)
end

--[[
    respin 棋盘滚动出来 bonus3之后 的动画
]]
function CodeGameScreenBlackFridayMachine:playBonus3FlyEffect(_chipBonus3Node, _endNode, _func1, _func2, _isPlaySound)
    if _isPlaySound then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus3_fly)
    end

    local flyNode = util_createAnimation("Socre_BlackFriday_Link3_0.csb") 
    -- 钻石
    local spine = util_spineCreate("Socre_BlackFriday_Link3",true,true)
    flyNode:findChild("spine"):addChild(spine)

    local startPos = util_convertToNodeSpace(_chipBonus3Node,self:findChild("Node_fly"))
    local endPos = util_convertToNodeSpace(_endNode,self:findChild("Node_fly"))

    self:findChild("Node_fly"):addChild(flyNode)
    flyNode:setPosition(startPos)
    flyNode:setScale(0.75)

    -- 先隐藏小块上原本的钻石
    local child = _chipBonus3Node:getCcbProperty("spine"):getChildren()
    for spineIndex = 1, #child do
        child[spineIndex]:setVisible(false)
    end

    flyNode:runCsbAction("fly",false)
    util_spinePlay(spine,"fly2",true)
    -- fly 70-164帧
    -- 第100帧的时候 飞， 130帧 结束飞行
    local seq = cc.Sequence:create({
        cc.DelayTime:create(25/60),
        cc.CallFunc:create(function()

            -- 钻石飞走之后 bonus3上显示金币数量
            self:showBonus3Coins(_chipBonus3Node)

        end),
        cc.EaseCubicActionIn:create(cc.MoveTo:create(30/60,endPos)),
        cc.CallFunc:create(function()

            if type(_func1) == "function" then
                _func1()
            end

        end),
        cc.DelayTime:create(34/60),
        cc.CallFunc:create(function()

            if type(_func2) == "function" then
                _func2()
            end

        end),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    
end

--[[
    钻石飞走之后 显示金币在 bonus3上
]]
function CodeGameScreenBlackFridayMachine:showBonus3Coins(_chipBonus3Node)

    local child = _chipBonus3Node:getCcbProperty("wenzi"):getChildren()
    if #child <= 0 then
        -- 没有文字 新创建
        local coinsView = util_createAnimation("Socre_BlackFriday_Link1Zi.csb")
        _chipBonus3Node:getCcbProperty("wenzi"):addChild(coinsView)
    end
    
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local child = _chipBonus3Node:getCcbProperty("wenzi"):getChildren()
    for nodeIndex = 1, #child do
        child[nodeIndex]:setVisible(true)
        child[nodeIndex]:findChild("BitmapFontLabel_1"):setVisible(true)
        child[nodeIndex]:findChild("BitmapFontLabel_1"):setString(util_formatCoins(1 * lineBet, 3))
        self:updateLabelSize({label = child[nodeIndex]:findChild("BitmapFontLabel_1"),sx = 0.9,sy = 0.9}, 142)
    end
    
    _chipBonus3Node:runAnim("actionframe_wenzi",false,function()
        _chipBonus3Node:runAnim("idle2",true)
    end)

end

--[[
    respin 相关
]]
function CodeGameScreenBlackFridayMachine:showRespinView()
    -- 表示刚进入respin 用来判断断线重连 初始化棋盘的时候 棋盘上有bonus3 需要让bonus3做动画
    self.m_comeInReSpin = true
    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS1 then
                    local symbolNode = util_setSymbolToClipReel(self,iCol, iRow, node.p_symbolType,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                    curBonusList[#curBonusList + 1] = node
                end
            end
        end
    end

    local random = math.random(1,2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_BlackFriday_bonus_trigger"..random])

    -- 角色动画
    util_spinePlay(self.m_jiaoSeSpine, "actionframe_chufa", false)
    
    -- 播放触发动画
    for bonusIndex, bonusNode in ipairs(curBonusList) do
        bonusNode:runAnim("actionframe",false,function (  )
            bonusNode:runAnim("idleframe",true)
        end)
        -- bonus1上面的数字 动画
        self:playBonus1CoinsEffect(bonusNode, "actionframe")
    end

    self:waitWithDelay(2,function()
        local view = self:showReSpinStart(function()
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()

            self:playReSpinChangeGuoChang(function()
                self.m_isReSpin = true
                self:showReSpinGuoChangBg()
                -- self:findChild("Node_1"):setVisible(false)
                -- 显示respin相关节点
                self:findChild("Node_2"):setVisible(true)
                
                self:setCurrSpinMode(RESPIN_MODE)

                -- 重置一下这个字段 防止刚好升级的时候 触发了respin玩法 报错
                self.m_spinIsUpgrade = false

                self.m_bonus3List = {}
                self.m_bonus3MiniMachineList = {}

                self:showReSpinMiNiBanzi(false)

                self:isNeedShowDangBanTips()

                util_nodeFadeIn(self:findChild("Node_2"), 20/60, 0, 255, nil, function()
                end)

                for miniIndex = 1, self.m_MiNiTotalNum do
                    self.m_miniMachine[miniIndex]:initMiniReelData(self.m_runSpinResultData.p_rsExtraData["reels"..miniIndex])

                    self.m_miniMachine[miniIndex]:showRespinView()

                    util_nodeFadeIn(self.m_miniMachine[miniIndex], 20/60, 0, 255, nil, function()
                    end)
                end

                --清空赢钱
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN) 

            end,function()
                self.m_guochangRespinBg:setVisible(false)
                self.m_respinMiniIndex = 2
                self.m_respinBanZiIndex = 1

                self:playRespinBanZiIdle()

                -- 开始jackpot切换
                self.m_jackpotRespinBar:playJackpot()

                -- 弹出说明弹板
                self:showReSpinExplainView(function()
                    self.m_comeInReSpin = false
                    for miniIndex = 1, self.m_MiNiTotalNum do
                        self.m_miniMachine[miniIndex]:runNextReSpinReel()
                    end
                end)
            end)
        end)
        -- 弹板上的光
        local tanbanShine = util_createAnimation("BlackFriday_FreeSpin_guang.csb")
        view:findChild("guang"):addChild(tanbanShine)
        tanbanShine:runCsbAction("idle",true)
        util_setCascadeOpacityEnabledRescursion(view:findChild("guang"), true)
        util_setCascadeColorEnabledRescursion(view:findChild("guang"), true)
    end)
    
end

--[[
    新建一个背景 respin 过场的时候 遮挡
]]
function CodeGameScreenBlackFridayMachine:showReSpinGuoChangBg()
    self.m_guochangRespinBg:setVisible(true)
    self.m_guochangRespinBg:findChild("base_bg"):setVisible(false)
    self.m_guochangRespinBg:findChild("free_bg"):setVisible(false)

    self.m_guochangRespinBg:runCsbAction("actionframe",false,function()
        self:findChild("Node_1"):setVisible(false)
        self:setReelBg(3)
    end)
end

-- respin 说明弹板
function CodeGameScreenBlackFridayMachine:showReSpinExplainView(_func)
   
    local explainView = util_createView("CodeBlackFridaySrc.BlackFridayReSpinExplainView", {machine = self, callBackFunc = _func})
    if globalData.slotRunData.machineData.p_portraitFlag then
        explainView.getRotateBackScaleFlag = function()
            return false
        end
    end

    gLobalViewManager:showUI(explainView, ViewZorder.ZORDER_UI_LOWER)
    explainView:setPosition(display.width * 0.5, display.height * 0.5)
    explainView:setScale(self.m_machineRootScale)
end

function CodeGameScreenBlackFridayMachine:showReSpinStart(_func)
    local view = nil
    view = self:showDialog("ReSpinStart",nil,_func,1)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_start_chuxian)

    return view
end

--ReSpin开始改变UI状态
function CodeGameScreenBlackFridayMachine:changeReSpinStartUI(curCount)
    self.m_RespinBarView:updateLeftCount(curCount,false)
    self.m_RespinBarView:setVisible(true)

end

--ReSpin刷新数量
function CodeGameScreenBlackFridayMachine:changeReSpinUpdateUI(curCount,isLiang)
    print("当前展示位置信息  %d ", curCount)
    self.m_RespinBarView:updateLeftCount(curCount,isLiang)
end

--spin结果
function CodeGameScreenBlackFridayMachine:spinResultCallFun(param)
    CodeGameScreenBlackFridayMachine.super.spinResultCallFun(self, param)

    if param[1] == true then
        if param[2] and param[2].result then
            local spinData = param[2]
            if spinData.action == "SPIN" then
                if self:getCurrSpinMode() == RESPIN_MODE then

                    if spinData.result.respin and spinData.result.respin.extra and spinData.result.respin.extra.reels1 then
                        local resultDatas = spinData.result.respin.extra

                        for miniIndex = 1, self.m_MiNiTotalNum do

                            local mninReel = self.m_miniMachine[miniIndex]
                            local dataName = "reels".. miniIndex

                            local miniReelsResultDatas = resultDatas[dataName]
                            spinData.result.reels = miniReelsResultDatas.reels
                            spinData.result.storedIcons = miniReelsResultDatas.storedIcons
                            spinData.result.pos = miniReelsResultDatas.pos

                            mninReel:netWorkCallFun(spinData.result)
                        end
                    
                    end
                end

            end
        end
    end
end

--[[
    检测是否所有respinView都已经停止滚动
]]
function CodeGameScreenBlackFridayMachine:isAllRespinViewDown()
    for index = 1,#self.m_miniMachine do
        if not self.m_miniMachine[index]:isRespinViewDown() then
            return false
        end
    end
    return true
end

---判断结算
function CodeGameScreenBlackFridayMachine:reSpinSelfReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount}
    self:upDateRespinNums()

    --停轮之后 关闭快滚音效
    if self.m_respinQuickRunSound then
        gLobalSoundManager:stopAudio(self.m_respinQuickRunSound)
        self.m_respinQuickRunSound = nil
    end
    
    if self.m_runSpinResultData.p_reSpinCurCount ~= 0 then
        for miniIndex = 1, self.m_MiNiTotalNum do
            self.m_miniMachine[miniIndex].m_respinView:runQuickEffect()
        end
    end

    self:setGameSpinStage(STOP_RUN)
    
    self.m_respinQiPanJimanPlaySound = true

    self:showReSpinMiNiBanzi(true, function()
        -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        -- 每次 滚动需要判断 是否有集满的棋盘
        local needPlayNum = 0
        if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.fullReel then
            for miniIndex = 1, self.m_MiNiTotalNum do
                if self.m_runSpinResultData.p_rsExtraData.fullReel[miniIndex] == 1 then
                    local isNeedPlay = self:showMiniQiPanEffect(miniIndex)
                    if isNeedPlay then
                        needPlayNum = needPlayNum + 1
                    end
                end 
            end
        end
        local delayTime = 0
        if needPlayNum > 0 then
            delayTime = 50/60
        end
        self:waitWithDelay(delayTime,function()
            self:updateQuestUI()
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                
                self:waitWithDelay(0.4,function()
                    self:respinOverJieSuan()
                end)

                return
            end

            self:clearBonus3SymbolInfo()
            self:reSpinSelfReelDownNext()
        end)

    end)
end

--防止钻石清理不干净 临时加的
function CodeGameScreenBlackFridayMachine:clearBonus3SymbolInfo( )
    local jieSuoRow = self.m_runSpinResultData.p_rsExtraData.Row 
    for miniReelIndex = 1, 3 do
        for banziIndex=1, 3 do
            local banziRowIndex = (miniReelIndex-1)*3 + banziIndex
            if banziRowIndex <= jieSuoRow then
                local dangBanNode = self.m_miniMachine[miniReelIndex]["banzi"..banziIndex]
                if dangBanNode:isVisible() then
                    dangBanNode:setVisible(false)
                    for i,_chipBonus3Node in ipairs(self.m_bonus3List) do
                        local child = _chipBonus3Node:getCcbProperty("spine"):getChildren()
                        for spineIndex = 1, #child do
                            child[spineIndex]:setVisible(false)
                        end
                        -- 钻石飞走之后 bonus3上显示金币数量
                        self:showBonus3Coins(_chipBonus3Node)
                    end
                end
            end
        end
    end
end

-- respin结束之后 开始结算
function CodeGameScreenBlackFridayMachine:respinOverJieSuan( )
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    for miniIndex = 1, self.m_MiNiTotalNum do
        self.m_miniMachine[miniIndex].m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
    end

    --quest
    self:updateQuestBonusRespinEffectData()

    for miniIndex = 1, self.m_MiNiTotalNum do
        --结束
        self.m_miniMachine[miniIndex]:reSpinEndAction()
        self.m_miniMachine[miniIndex].m_lightEffectNode:removeAllChildren(true)
        self.m_miniMachine[miniIndex].m_respinView.m_single_lights = {}
    end
    --结束
    self:reSpinEndAction()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
    self.m_isWaitingNetworkData = false
end

-- 落地之后 刷新次数respin
function CodeGameScreenBlackFridayMachine:upDateRespinNums( )
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        if self.m_runSpinResultData.p_reSpinCurCount >= 3 then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)
        else
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,false)
            if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
                self.m_RespinBarView:showReSpinBerUI()
            end 
        end
    end
end
--[[
    每次respin 滚动完 下次spin的流程
]]
function CodeGameScreenBlackFridayMachine:reSpinSelfReelDownNext()
    for miniIndex = 1, self.m_MiNiTotalNum do
        self.m_miniMachine[miniIndex].m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    end

    self.m_bonus3List = {}
    self.m_bonus3MiniMachineList = {}

    --继续
    for miniIndex = 1, self.m_MiNiTotalNum do
        self.m_miniMachine[miniIndex]:runNextReSpinReel()
    end

    -- 播放respin 快滚音效
    for miniIndex = 1, self.m_MiNiTotalNum do
        local qucikRespinNode = self.m_miniMachine[miniIndex].m_respinView.m_qucikRespinNode
        if qucikRespinNode and #qucikRespinNode > 0 then
            self.m_respinQuickRunSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_quick_run)
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end

--结束移除小块调用结算特效
function CodeGameScreenBlackFridayMachine:reSpinEndAction()    

    self:getReSpinEndWheelChip()

    self.m_playWheelIndex = 1 --依次转动wheel 的标识

    self:reSpinMiniWheelEffect(function()
        -- 棋盘有集满 先结算 集满
        self:showMiniJiManEffect(function()
            -- 播放全部bonus的 触发动效在 一个一个收集
            self:playBonusTriggerEffect(function()
                self.m_maxIndexMini = 3 --结算顺序为 从上到下 三个小转盘 
                self:playChipCollectAnim(self.m_maxIndexMini)
            end)
        end)
    end)
    
end

--结算之前 如果有轮盘 先把wheel查找出来
function CodeGameScreenBlackFridayMachine:getReSpinEndWheelChip()
    self.m_wheelChipList = {}
    for miniIndex = self.m_MiNiTotalNum, 1, -1 do
        for chipNodeIndex = 1, #self.m_miniMachine[miniIndex].m_chipList do
            local chipNode = self.m_miniMachine[miniIndex].m_chipList[chipNodeIndex]
            if chipNode.p_symbolType == self.SYMBOL_BONUS2 then
                local score = self.m_miniMachine[miniIndex]:getReSpinSymbolScore(self:getPosReelIdx(chipNode.p_rowIndex ,chipNode.p_cloumnIndex))
                chipNode.m_score = score
                table.insert(self.m_wheelChipList, chipNode)
            end
        end
    end
end

--结算之前 如果有轮盘 轮盘需要转动
function CodeGameScreenBlackFridayMachine:reSpinMiniWheelEffect(_func)
    if self.m_playWheelIndex > #self.m_wheelChipList then
        if _func then
            _func()
        end

        return 
    end

    local chipWheelNode = self.m_wheelChipList[self.m_playWheelIndex]
    local nJackpotType = 0
    if chipWheelNode.m_score == "grand" then
        nJackpotType = 1
    elseif chipWheelNode.m_score == "major" then
        nJackpotType = 2
    elseif chipWheelNode.m_score == "minor" then
        nJackpotType = 3
    elseif chipWheelNode.m_score == "mini" then
        nJackpotType = 4
    end

    self:flyReSpinWheel(chipWheelNode,function()
        self:showZhuanPanWheel(chipWheelNode, function ()

            self:waitWithDelay(0.5,function()
                self.m_playWheelIndex = self.m_playWheelIndex + 1
                self:reSpinMiniWheelEffect(_func)   
            end)
             
        end,nJackpotType)
    end)
    
end

--[[
    wheel 出现之前的动画
]]
function CodeGameScreenBlackFridayMachine:flyReSpinWheel(_startNode,_func)
    local flyNode = util_spineCreate("Socre_BlackFriday_Link2",true,true)

    local startPos = util_convertToNodeSpace(_startNode,self:findChild("Node_guochang"))
    local endPos = cc.p(0,0)

    self:findChild("Node_guochang"):addChild(flyNode)
    flyNode:setPosition(startPos)
    flyNode:setScale(0.75)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus2_trigger)

    util_spinePlay(flyNode, "actionframe", false)

    local seq = cc.Sequence:create({
        cc.DelayTime:create(30/30),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus2_move_change_big)
        end),
        cc.MoveTo:create(15/30,endPos),
        cc.CallFunc:create(function()
            if type(_func) == "function" then
                _func()
            end
        end),
        cc.DelayTime:create(15/30),
        cc.CallFunc:create(function()
            flyNode:removeFromParent()
            flyNode = nil
        end),
    })
    flyNode:runAction(seq)
    
end

--[[
    结算bonus图标之前 有集满的棋盘需要先做动画 
]]
function CodeGameScreenBlackFridayMachine:showMiniJiManEffect(_func)
    -- 集满的赢钱节点 飞的时候 用
    self.m_jiManWinCoinsNode = {}

    self.m_playJiManIndex = 1
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.fullReel then
        for miniIndex = self.m_MiNiTotalNum, 1, -1 do
            if self.m_runSpinResultData.p_rsExtraData.fullReel[miniIndex] == 1 then

                self.m_miniMachine[miniIndex].qiPanEffect:setVisible(false)
                self:showMiniQiPanTriggerEffect(miniIndex)

                local coins = self.m_runSpinResultData.p_rsExtraData.fullCoins[miniIndex] or 0
                self.m_miniMachine[miniIndex].jiManEffect.m_coins = coins
                table.insert(self.m_jiManWinCoinsNode, self.m_miniMachine[miniIndex].jiManEffect)

                self.m_miniMachine[miniIndex].jiManEffect.winCoinNode:setVisible(true)
                self.m_miniMachine[miniIndex].jiManEffect.winCoinNode:findChild("m_lb_coins"):setString(util_formatCoins(coins,30))
                self:updateLabelSize({label=self.m_miniMachine[miniIndex].jiManEffect.winCoinNode:findChild("m_lb_coins"),sx=0.7,sy=0.7},537)
                self.m_miniMachine[miniIndex].jiManEffect.winCoinNode:runCsbAction("idle",true)

                self.m_miniMachine[miniIndex].jiManEffect:setVisible(true)
                self.m_miniMachine[miniIndex].jiManEffect:runCsbAction("start",false,function()

                    self.m_miniMachine[miniIndex].jiManEffect:runCsbAction("idle",true)
                end)
            end 
        end
    end

    if #self.m_jiManWinCoinsNode > 0 then
        self:waitWithDelay(148/60,function()
            self.m_jiManWinCoinsNode[self.m_playJiManIndex]:runCsbAction("over",false)

            self:flyReSpinCollectWinCois(self.m_jiManWinCoinsNode[self.m_playJiManIndex].winCoinNode, self.m_jiManWinCoinsNode[self.m_playJiManIndex].m_coins, function()
                if _func then
                    _func()
                end
            end)
        end)
    else
        if _func then
            _func()
        end
    end

end

--[[
    赢钱先飞到 底部赢钱区
]]
function CodeGameScreenBlackFridayMachine:flyReSpinCollectWinCois(_startNode, _coins, _func) 
    _startNode:setVisible(false)
    local flyNode = util_createAnimation("BlackFriday_respin_prize_shuzhi.csb")

    flyNode:findChild("m_lb_coins"):setString(util_formatCoins(_coins,30))
    self:updateLabelSize({label=flyNode:findChild("m_lb_coins"),sx=0.7,sy=0.7},537)

    local startPos = util_convertToNodeSpace(_startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    flyNode:runCsbAction("fly",false)

    -- 飞到底部 
    local seq = cc.Sequence:create({
        cc.DelayTime:create(10/60),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_jiman_fly)
        end),
        cc.EaseQuarticActionIn:create(cc.MoveTo:create(30/60,endPos)),
        cc.CallFunc:create(function()

            self.m_lightScore = self.m_lightScore + _coins
            self:playhBottomLight(_coins, function()
                self.m_playJiManIndex = self.m_playJiManIndex + 1
                if self.m_playJiManIndex > #self.m_jiManWinCoinsNode then
                    if _func then
                        _func()
                    end
                else
                    self.m_jiManWinCoinsNode[self.m_playJiManIndex]:runCsbAction("over",false)

                    self:flyReSpinCollectWinCois(self.m_jiManWinCoinsNode[self.m_playJiManIndex].winCoinNode, self.m_jiManWinCoinsNode[self.m_playJiManIndex].m_coins, _func)
                end
            end,true)
            
            flyNode:removeFromParent()
            flyNode = nil
        end),
    })

    flyNode:runAction(seq)
end

--[[
    结算bonus之前 播放 触发动效
]]
function CodeGameScreenBlackFridayMachine:playBonusTriggerEffect(_func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_jiesuan_bonus)

    for miniIndex = 1, self.m_MiNiTotalNum do
        if self.m_miniMachine[miniIndex].m_chipList and #self.m_miniMachine[miniIndex].m_chipList > 0 then
            for chipNodeIndex = 1, #self.m_miniMachine[miniIndex].m_chipList do
                local chipNode = self.m_miniMachine[miniIndex].m_chipList[chipNodeIndex]
                if chipNode.p_symbolType == self.SYMBOL_BONUS1 or chipNode.p_symbolType == self.SYMBOL_BONUS3 then
                    local child = chipNode:getCcbProperty("js_chufa"):getChildren()
                    if #child > 0 then
                        for spineIndex = 1, #child do
                            child[spineIndex]:removeFromParent()
                            child[spineIndex] = nil
                        end
                    end
                    local chufaNode = util_createAnimation("BlackFriday_js_chufa_tx.csb")
                    chipNode:getCcbProperty("js_chufa"):addChild(chufaNode)
                    chufaNode:runCsbAction("actionframe",false)

                    chipNode:runAnim("actionframe3",false,function()
                    end)

                elseif chipNode.p_symbolType == self.SYMBOL_BONUS2 then
                    local symbol_node = chipNode:checkLoadCCbNode()
                    local spineNode = symbol_node:getCsbAct()
                    if not spineNode.m_jieSuanNode then
                        local jiesuanView = util_createAnimation("BlackFriday_js_chufa_tx.csb")
                        util_spinePushBindNode(spineNode,"js_chufa",jiesuanView)
                        spineNode.m_jieSuanNode = jiesuanView
                    end
                    chipNode:runAnim("actionframe3",false,function()
                    end)

                    spineNode.m_jieSuanNode:runCsbAction("actionframe",false)
                end
                
            end
        end
    end

    self:waitWithDelay(60/30,function()
        if _func then
            _func()
        end
    end)
end

--[[
    结算所有的小块
]]
function CodeGameScreenBlackFridayMachine:playChipCollectAnim(_indexMini, _isCollectEnd)

    if _isCollectEnd then
        -- 此处跳出迭代
        self:playLightEffectEnd(_indexMini)
        
        return 
    end

    if self.m_miniMachine[_indexMini].m_playAnimIndex > #self.m_miniMachine[_indexMini].m_chipList then
        self.m_maxIndexMini = self.m_maxIndexMini - 1

        -- mini计数小于1 说明结算完毕
        if self.m_maxIndexMini < 1 then
            self:playChipCollectAnim(self.m_maxIndexMini,true)
        else
            self:playChipCollectAnim(self.m_maxIndexMini)
        end
        
        return
    end

    local chipNode = self.m_miniMachine[_indexMini].m_chipList[self.m_miniMachine[_indexMini].m_playAnimIndex]

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    -- 根据网络数据获得当前固定小块的分数
    local score = self.m_miniMachine[_indexMini]:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()
    
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "grand" then
            jackpotScore = self:BaseMania_getJackpotScore(1)
            addScore = jackpotScore + addScore
            nJackpotType = 1
        elseif score == "major" then
            jackpotScore = self:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif score == "minor" then
            jackpotScore =  self:BaseMania_getJackpotScore(3)
            addScore =jackpotScore + addScore                  ---self:BaseMania_getJackpotScore(3)
            nJackpotType = 3
        elseif score == "mini" then
            jackpotScore = self:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                      ---self:BaseMania_getJackpotScore(4)
            nJackpotType = 4
        end
    end

    -- 如果是钻石 服务器没给金币数据 自己写成默认1倍
    if chipNode.p_symbolType == self.SYMBOL_BONUS3 then
        if score == nil then
            addScore = 1 * lineBet
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    -- gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus_collect)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus_collect_fankui)

    if nJackpotType == 0 then
        self:flyCollectCoin(chipNode, function()
            self.m_miniMachine[_indexMini].m_playAnimIndex = self.m_miniMachine[_indexMini].m_playAnimIndex + 1
            self:playChipCollectAnim(_indexMini) 
        end, addScore)
    else
        chipNode:runAnim("actionframe2",false,function()
            self:waitWithDelay(0.0,function()
                self:showRespinJackpot(nJackpotType, jackpotScore, function()
                    self:flyCollectCoin(nil,function()
                        self.m_miniMachine[_indexMini].m_playAnimIndex = self.m_miniMachine[_indexMini].m_playAnimIndex + 1
                        self:playChipCollectAnim(_indexMini)
                    end,jackpotScore)
                end)
            end)
        end)
    end
end

-- 收集金币
function CodeGameScreenBlackFridayMachine:flyCollectCoin(_startNode, _func, _addScore)

    if _startNode then
        _startNode:runAnim("actionframe2",false)
        if _startNode.p_symbolType == self.SYMBOL_BONUS1 then
            -- bonus1上面的数字 动画
            self:playBonus1CoinsEffect(_startNode, "actionframe2")
        end
    end

    -- self.m_bottomUI:playCoinWinEffectUI()

    local lightAni = util_createAnimation("BlackFriday_yingqianqv.csb")
    self.m_bottomUI.coinWinNode:addChild(lightAni)
    lightAni:findChild("m_lb_coins"):setString("+"..util_formatCoins(_addScore,30))
    lightAni:runCsbAction("actionframe",false,function(  )
        lightAni:removeFromParent()
    end)

    self:setLastWinCoin(self.m_lightScore)

    local params = {_addScore, false, true}
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)

    self:waitWithDelay(0.4,function()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenBlackFridayMachine:showRespinJackpot(_index,_coins,_func)
    
    local jackPotWinView = util_createView("CodeBlackFridaySrc.BlackFridayJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(_index,_coins,_func,self)
end

-- 结束respin收集
function CodeGameScreenBlackFridayMachine:playLightEffectEnd(_indexMini)
    self:waitWithDelay(0.5, function()
        -- 通知respin结束
        self:respinOver()
    end)
    
end

function CodeGameScreenBlackFridayMachine:respinOver()
    
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:clearCurMusicBg() 

    self:showRespinOverView()

    self:isNeedCloseDangBanTips()
end

function CodeGameScreenBlackFridayMachine:showRespinOverView(effectData)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    local strCoins=util_formatCoins(self.m_serverWinCoins,30)
    local view=self:showReSpinOver(strCoins,function()

        self:playReSpinChangeGuoChangOver(function()
            self.m_isReSpin = false

            self:findChild("Node_1"):setVisible(true)
            -- 显示respin相关节点
            self:findChild("Node_2"):setVisible(false)

            if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                self:setReelBg(1)
            else
                self:setReelBg(2)
            end

            self:playJiaoSeIdleFrame()

            for miniIndex = 1, self.m_MiNiTotalNum do

                self.m_miniMachine[miniIndex]:setReelSlotsNodeVisible(true)
                self.m_miniMachine[miniIndex]:removeRespinNode()

                -- 每个小mini 轮盘上的 三个挡板
                for banziIndex=1,3 do
                    self.m_miniMachine[miniIndex]["banzi"..banziIndex]:setVisible(true)
                    util_spinePlay(self.m_miniMachine[miniIndex]["banzi"..banziIndex],"idleframe")
                    self.m_miniMachine[miniIndex]["banzi"..banziIndex].isPlayEffect = false
                end
                self.m_miniMachine[miniIndex].qiPanEffect:setVisible(false)

                self.m_miniMachine[miniIndex].jiManEffect:setVisible(false)

            end
    
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
    
        end,function()
            if self.m_bProduceSlots_InFreeSpin then
                self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
            end
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg() 

            -- respin 玩法结束 判断是否 需要弹出jackpot tips
            self.m_jackpotBar:checkIsNeedOpenTips()
        end)
        
    end)
    -- gLobalSoundManager:playSound("WestRangerrSounds/music_WestRangerr_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},653)
end

function CodeGameScreenBlackFridayMachine:showReSpinOver(_coins, _func, _index)

    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(_coins, 30)
    local view = nil

    view = self:showDialog("ReSpinOver", ownerlist, _func, nil, _index)
    view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_click
    view.m_tanbanOverSound = self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_over_xiaoshi
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_over_chuxian)

    return view
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

-- 显示转盘
function CodeGameScreenBlackFridayMachine:showZhuanPanWheel(_chipNode, _func, _nJackpotType)
    local startPos = util_convertToNodeSpace(_chipNode,self:findChild("root"))
    -- 转盘 转完之后 棋盘上的小块 显示成带jackpot的
    local showWheelNodeJackpot = function()
        local symbol_node = _chipNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        spineNode:setSkin(_chipNode.m_score)
        _chipNode:runAnim("idleframe_jackpot2", true)
    end

    --显示转盘
    local view = util_createView("CodeBlackFridaySrc.BlackFridayWheelView",{machine = self,JackpotType = _nJackpotType,callBack = function()
        if _func then
            _func()
        end
    end, endPos = startPos, changeJackpotCallBack = showWheelNodeJackpot})

    self:findChild("root"):addChild(view, 100)
end

-- 判断哪个小轮盘 没有集满
function CodeGameScreenBlackFridayMachine:getIndexReelMiniNoJiMan( )
    for miniIndex = 1, self.m_MiNiTotalNum do
        local reelData = self.m_runSpinResultData.p_rsExtraData["reels"..miniIndex]
        for iCol = 1, self.m_iReelColumnNum  do
            for iRow = 1, self.m_iReelRowNum do
                if reelData.reels[iRow][iCol] == self.SYMBOL_SCORE_BLANK then
                    self.m_IndexReelMini = miniIndex
                    return
                end
            end
        end
    end
end

--[[
    刷新商店积分
]]
function CodeGameScreenBlackFridayMachine:refreshShopScore(_isReConnect)
    local score = 0
    if _isReConnect then
        score = self.m_shopConfig.coins or 0
    elseif self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.coins then
        score = self.m_runSpinResultData.p_selfMakeData.coins or 0
        if score == 0 then
            score = self.m_shopConfig.coins or 0
        else --刷新配置中的积分数量
            self.m_shopConfig.coins = score
        end
    end

    self.m_coinCollectBar:updateCoins(score)
end

--[[
    添加freespin
]]
function CodeGameScreenBlackFridayMachine:addFreeEffect()
    -- 添加freespin effect
    local freeSpinEffect = GameEffectData.new()
    freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
    freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

    --手动添加freespin次数
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
end

--[[
    触发superfree
]]
function CodeGameScreenBlackFridayMachine:triggerSuperFree()
    self.m_isSuperFree = true
    --添加free事件
    self:addFreeEffect()
    
    self:playGameEffect()
end

--[[
    刷新固定图标
]]
function CodeGameScreenBlackFridayMachine:refreshLockWild(_func, _isDuanXian)
    --已经创建好了,不需要二次创建
    if #self.m_lockWilds > 0 then
        return
    end

    local superFreeType = self.m_runSpinResultData.p_selfMakeData.superFreeType
    if not superFreeType then
        return
    end
    local wildConfig = self.m_shopConfig.shopWildConfig[tostring(superFreeType)]
    if not _isDuanXian then
        --创建wild图标
        for i,posIndex in ipairs(wildConfig) do

            local pos = util_getOneGameReelsTarSpPos(self,posIndex ) 
            local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
            local nodePos = self:findChild("Node_guochang"):convertToNodeSpace(worldPos)

            --后期会换成spine
            local wildAni = util_spineCreate("Socre_BlackFriday_Wild",true,true)
            self:findChild("Node_guochang"):addChild(wildAni, -1)
            wildAni:setPosition(nodePos)
            util_spinePlay(wildAni, "idleframe", false)
            wildAni:setVisible(false)
            
            self.m_lockWilds[#self.m_lockWilds + 1] = wildAni
        end
    else
        --创建wild图标
        for i,posIndex in ipairs(wildConfig) do

            local pos = util_getOneGameReelsTarSpPos(self,posIndex ) 
            local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
            local nodePos = self:findChild("Node_guochang"):convertToNodeSpace(worldPos)

            local wildAni = util_spineCreate("Socre_BlackFriday_Wild",true,true)
            self:findChild("Node_guochang"):addChild(wildAni, -1)
            wildAni:setPosition(nodePos)
            if _isDuanXian then
                util_spinePlay(wildAni, "idleframe", false)
                wildAni:setVisible(false)
            else
                util_spinePlay(wildAni, "idleframe", false)
            end
            
            self.m_lockWilds[#self.m_lockWilds + 1] = wildAni
        end
    end
    
    if _func then
        self:waitWithDelay(1/30,function()
            _func()
        end)
    end
end

--[[
    清空固定图标
]]
function CodeGameScreenBlackFridayMachine:clearLockWild()
    for i,wildAni in ipairs(self.m_lockWilds) do
        wildAni:removeFromParent()
    end
    self.m_lockWilds = {}
end

function CodeGameScreenBlackFridayMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_runSpinResultData.p_winLines = {}
    end

    if self.m_bProduceSlots_InFreeSpin then
        local freeNum = self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinsLeftCount 
        if self.m_isSuperFree and freeNum == 1 then
            self:clearLockWild()
            --刷新固定图标
            self:refreshLockWild(function()
                self:superFreeDarkEffect(function()
                    self:produceSlots()

                    local isWaitOpera = self:checkWaitOperaNetWorkData()
                    if isWaitOpera == true then
                        return
                    end

                    self.m_isWaitingNetworkData = false
                    self:operaNetWorkData() -- end
                end)
            end)
        else
            self:produceSlots()

            local isWaitOpera = self:checkWaitOperaNetWorkData()
            if isWaitOpera == true then
                return
            end

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end
    else
        self:produceSlots()
    
        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end

        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end
end

--[[
    处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
]]
function CodeGameScreenBlackFridayMachine:specialSymbolActionTreatment(_node)
    if _node and _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local symbolNode = util_setSymbolToClipReel(self,_node.p_cloumnIndex, _node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)

        symbolNode:runAnim("buling",false,function()
            symbolNode:runAnim("idleframe2", true)
        end)
    end

end

-- 每个reel条滚动到底
function CodeGameScreenBlackFridayMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)
    
    if isTriggerLongRun then
        -- 开始快滚的时候 其他scatter 播放ialeframe3
        self:waitWithDelay(0.1,function()
            for iCol = 1, reelCol  do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        local symbolType = targSp.p_symbolType
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            -- 触发快停
                            if self.m_isQuicklyStop then
                                targSp:runAnim("idleframe2",true)
                            else
                                targSp:runAnim("idleframe3",true)
                            end
                        end
                    end
                end
            end
        end)
        
    end

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
            for iCol = 1, reelCol  do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        local symbolType = targSp.p_symbolType
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            targSp:runAnim("idleframe2",true)
                        end
                    end
                end
            end
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        self:triggerLongRunChangeBtnStates()
    end
    
    return isTriggerLongRun
end

--[[
    商店购买之后 赢钱显示在底部
]]
function CodeGameScreenBlackFridayMachine:playhBottomLight(_endCoins, _endCallFunc, isAdd)
    
    self.m_bottomUI:playCoinWinEffectUI(_endCallFunc)

    if isAdd then
        local bottomWinCoin = self:getCurBottomWinCoins()
        local totalWinCoin = bottomWinCoin + tonumber(_endCoins)
        self:setLastWinCoin(totalWinCoin)
        self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
    else
        self:setLastWinCoin(tonumber(_endCoins))
        self:updateBottomUICoins(0, tonumber(_endCoins), true)
    end

end

function CodeGameScreenBlackFridayMachine:getCurBottomWinCoins()
    local winCoin = 0
    local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == sCoins then
        return winCoin
    end
    if nil == self.m_bottomUI.m_updateCoinHandlerID then
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

--[[
    BottomUI接口
]]
function CodeGameScreenBlackFridayMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenBlackFridayMachine:scaleMainLayer()
    CodeGameScreenBlackFridayMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if  ratio >= 768/1024 then
        local mainScale = 0.68
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 15)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.81 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 10)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.88 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

--bonus1上面挂载的 金币文件随着spine一起播放动画
function CodeGameScreenBlackFridayMachine:playBonus1CoinsEffect(_symbolNode, _actionName, _actionName2)
    local child = _symbolNode:getCcbProperty("bonusSpine"):getChildren()
    for spineIndex = 1, #child do
        util_spinePlay(child[spineIndex], _actionName, false)
        if _actionName2 then
            util_spineEndCallFunc(child[spineIndex], _actionName, function()
                util_spinePlay(child[spineIndex], _actionName2, true)
            end)
        end
    end
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenBlackFridayMachine:showDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("CodeBlackFridaySrc.BlackFridayDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    -- if self.m_root then
    --     self.m_root:addChild(view,999999)
    --     local wordPos=view:getParent():convertToWorldSpace(cc.p(view:getPosition()))
    --     local curPos=self.m_root:convertToNodeSpace(wordPos)
    --     view:setPosition(cc.pSub(cc.p(0,0),wordPos))
    -- else
    gLobalViewManager:showUI(view)
    -- end

    return view
end

-- 重置当前背景音乐名称
function CodeGameScreenBlackFridayMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_isSuperFree then
            self.m_currentMusicBgName = "BlackFridaySounds/music_BlackFriday_superfree.mp3"
        else
            self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        end

        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end

-- 判断当前respin 挡板上是否需要显示解锁说明
function CodeGameScreenBlackFridayMachine:isNeedShowDangBanTips( )
    if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.Row then

        if self.m_runSpinResultData.p_rsExtraData.Row > 9 then
            self.m_runSpinResultData.p_rsExtraData.Row = 9
        end

        --显示解锁说明的行数
        local row = self.m_runSpinResultData.p_rsExtraData.Row + 1

        for miniIndex = 1, self.m_MiNiTotalNum do
            for banziIndex = 1, 3 do
                local rowIndex = (miniIndex - 1)*3 + banziIndex
                local banziNode = self.m_miniMachine[miniIndex]["banzi"..banziIndex] 
                if banziNode:isVisible() and rowIndex == row then
                    if not banziNode.m_tips then
                        local dangbanTips = util_createAnimation("BlackFriday_respin_suodingtips.csb")
                        banziNode:getParent():addChild(dangbanTips)
                        dangbanTips:runCsbAction("start",false,function()
                            dangbanTips:runCsbAction("idle",true)
                        end)
                        banziNode.m_tips = dangbanTips
                    end
                    return
                end
            end
        end
    end
end

-- 判断当前respin 挡板上是否需要关闭解锁说明
function CodeGameScreenBlackFridayMachine:isNeedCloseDangBanTips( )
    for miniIndex = 1, self.m_MiNiTotalNum do
        for banziIndex = 1, 3 do
            local banziNode = self.m_miniMachine[miniIndex]["banzi"..banziIndex] 
            if banziNode:isVisible() and banziNode.m_tips then
                banziNode.m_tips:runCsbAction("over",false,function()
                    banziNode.m_tips:removeFromParent()
                    banziNode.m_tips = nil
                end)
                return
            end
        end
    end
end

--[[
    @desc: 计算每条应前线
    time:2020-07-21 20:48:31
    @return:
]]
function CodeGameScreenBlackFridayMachine:lineLogicWinLines()
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if self:getCurrSpinMode() == RESPIN_MODE then
        winLines = {}
    else
        if self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount >= 0 then
            winLines = {}
        end
    end 
    if #winLines > 0 then
        self:compareScatterWinLines(winLines)

        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo, iconsPos)

            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())

            if lineInfo.iLineSymbolNum >= 5 then
                isFiveOfKind = true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end
    end

    return isFiveOfKind
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenBlackFridayMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    -- free玩法的最后 一次 不播放大赢
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_runSpinResultData and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self.m_isAddBigWinLightEffect = false
        end
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenBlackFridayMachine:showBigWinLight(_func)
    self.m_bigwinEffect:setVisible(true)

    local actionName = "actionframe_daying"

    -- self:shakeNode()
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bigWin_yugao)

    util_spinePlay(self.m_bigwinEffect,actionName)
    util_spineEndCallFunc(self.m_bigwinEffect,actionName,function()
        self.m_bigwinEffect:setVisible(false)

        -- 如果连线没播完大赢出来了，切断连线中奖音效
        self:stopLinesWinSound()
        
        if _func then
            _func()
        end
    end)

    -- 角色动画
    util_spinePlay(self.m_jiaoSeSpine, actionName, false)
    util_spineEndCallFunc(self.m_jiaoSeSpine, actionName, function()
        self.m_jiaoseIdleIndex = 1
        self:playJiaoSeIdleFrame()
    end)
end

return CodeGameScreenBlackFridayMachine