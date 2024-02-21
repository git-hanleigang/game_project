---
-- island li
-- 2019年1月26日
-- CodeGameScreenJackpotOGoldMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local JackpotOGoldBaseData = require "CodeJackpotOGoldSrc.JackpotOGoldBaseData"
local CodeGameScreenJackpotOGoldMachine = class("CodeGameScreenJackpotOGoldMachine", BaseNewReelMachine)

CodeGameScreenJackpotOGoldMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenJackpotOGoldMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- bonus
CodeGameScreenJackpotOGoldMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenJackpotOGoldMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- bonus收集
CodeGameScreenJackpotOGoldMachine.COLLECT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- jackpot弹板
CodeGameScreenJackpotOGoldMachine.COLLECT_GUANZI_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 20次spin翻转出金币罐子
CodeGameScreenJackpotOGoldMachine.COLLECT_WHEEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 触发转轮玩法
-- 收集18个jackpot 可以触发 转轮玩法
-- 如果当次spin 中的jackpot比较多，全部收集的话 超过18个 则只收集到第18个 其他的jackpot 不收集到小转轮，只弹jackpot弹板就行

-- 构造函数
function CodeGameScreenJackpotOGoldMachine:ctor()
    CodeGameScreenJackpotOGoldMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true

    self.m_spinRestMusicBG = true 
    self.m_isDuanXian = false -- 是否断线进来
    self.m_WheelLogoCollect = {} --小轮盘收集个数
    self.m_jackpotEffectNode = {} -- 差一个字母中 jackpot的时候 特殊效果 ，最多五个
    self.m_isClick = true -- 判断轮盘logo 是否可以点击
    self.m_isClickLogoAndReel = true -- 点击logo的一瞬间 不能点击棋盘
    self.m_isQuickStop = false -- 是否快停了
    self.m_isInit = true
    self.m_isWheelReturnClick = false -- 转轮界面点击了 返回
    self.m_winCoinCurSpin = 0 -- 每一步赢钱累加
    self.m_curSpinNum = 0 --当前spin次数
    self.m_isPlayWinSound = true -- 是否播放赢钱音效
    -- 首次进入关卡 初始化棋盘上面的bonus字母 {棋盘位置，bonus类型，字母ID}

    self.m_isWheelBackInterval = false -- 是否是wheel back 时间段内
    self.m_initReelSysmblBonus = {
        {0,0,1},{6,0,2},{12,0,3},{8,0,4},{4,0,5}
    }

	--init
	self:initGame()
end

function CodeGameScreenJackpotOGoldMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    self.m_configData = gLobalResManager:getCSVLevelConfigData("JackpotOGoldConfig.csv", "LevelJackpotOGoldConfig.lua")
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenJackpotOGoldMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "JackpotOGold"  
end

function CodeGameScreenJackpotOGoldMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    -- 创建jackpot Grand
    self.m_JackpotGrandView = util_createView("CodeJackpotOGoldSrc.JackpotOGoldJackPotGrandBarView")
    self:findChild("Node_jackpot_Grand"):addChild(self.m_JackpotGrandView)
    self.m_JackpotGrandView:initMachine(self)

    -- 创建jackpot Super
    self.m_JackpotSuperView = util_createView("CodeJackpotOGoldSrc.JackpotOGoldJackPotSuperBarView")
    self:findChild("Node_jackpot_Super"):addChild(self.m_JackpotSuperView)
    self.m_JackpotSuperView:initMachine(self)

    -- 创建jackpot Major
    self.m_JackpotMajorView = util_createView("CodeJackpotOGoldSrc.JackpotOGoldJackPotMajorBarView")
    self:findChild("Node_jackpot_Major"):addChild(self.m_JackpotMajorView)
    self.m_JackpotMajorView:initMachine(self)

    -- 创建jackpot Minor
    self.m_JackpotMinorView = util_createView("CodeJackpotOGoldSrc.JackpotOGoldJackPotMinorBarView")
    self:findChild("Node_jackpot_Minor"):addChild(self.m_JackpotMinorView)
    self.m_JackpotMinorView:initMachine(self)

    -- 创建jackpot Mini
    self.m_JackpotMiniView = util_createView("CodeJackpotOGoldSrc.JackpotOGoldJackPotMiniBarView")
    self:findChild("Node_jackpot_MIni"):addChild(self.m_JackpotMiniView)
    self.m_JackpotMiniView:initMachine(self)

    -- 轮盘入口
    self.m_WheelLogo = util_createAnimation("JackpotOGold_Wheel_Logo.csb")
    self:findChild("Node_wheel_logo"):addChild(self.m_WheelLogo)
    self.m_WheelLogo:runCsbAction("idle",true)

    -- 说明tips
    self.m_shoujiTips = util_createAnimation("JackpotOGold_Tips.csb")
    self.m_WheelLogo:findChild("Node_Tips"):addChild(self.m_shoujiTips)
    self.m_shoujiTips:setVisible(false)
    self:addClick(self.m_WheelLogo:findChild("btn_i"))

    -- 添加触摸
    self:addClick(self.m_WheelLogo:findChild("Panel_1"))
    for i=1,18 do
        local logoCollectNode = util_createAnimation("JackpotOGold_Wheel_collect.csb")
        self.m_WheelLogo:findChild("collect_1_"..i):addChild(logoCollectNode)
        logoCollectNode:setVisible(false)
        self.m_WheelLogoCollect[i] = logoCollectNode
    end

    -- 收集金币罐子
    self.m_CollectPot = util_createAnimation("JackpotOGold_Pot.csb")
    self:findChild("Node_pot"):addChild(self.m_CollectPot)
    self.m_CollectPot:runCsbAction("idle1",true)

    -- 说明tips
    self.m_shoujiTipsPot = util_createAnimation("JackpotOGold_Tips_1.csb")
    self.m_CollectPot:findChild("Node_Tips_1"):addChild(self.m_shoujiTipsPot)
    self.m_shoujiTipsPot:setVisible(false)
    self:addClick(self.m_CollectPot:findChild("click_pot"))

    -- 创建spin 剩余次数 进度
    self.m_SpinNum = util_createView("CodeJackpotOGoldSrc.JackpotOGoldSpinNumBarView",self)
    self:findChild("Node_SpinNum"):addChild(self.m_SpinNum)

    -- 创建大转盘
    self.m_bonusWheel = util_createView("CodeJackpotOGoldSrc.JackpotOGoldWheelView",self)
    self:findChild("Node_wheel"):addChild(self.m_bonusWheel)
    self.m_bonusWheel:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_bonusWheel:findChild("Node"), true)
    util_setCascadeColorEnabledRescursion(self.m_bonusWheel:findChild("Node"), true)

    -- 创建过场
    self.m_guochang = util_createAnimation("JackpotOGold_guochang.csb")
    self:findChild("guochang"):addChild(self.m_guochang)
    self.m_guochang:setVisible(false)

    -- 创建转轮背景过场
    self.m_guochangWheelBg = util_createAnimation("JackpotOGold_wheel_bg.csb")
    self:findChild("guochang"):addChild(self.m_guochangWheelBg)
    self.m_guochangWheelBg:setVisible(false)

    -- jackpot弹板
    self.m_jackpotView = util_createView("CodeJackpotOGoldSrc.JackpotOGoldJackPotWinView",self)
    -- self.m_jackpotView = util_createAnimation("JackpotOGold/JackpotWinView.csb")
    self:findChild("Node_JackpotWinView"):addChild(self.m_jackpotView)
    self.m_jackpotView:runCsbAction("idle",false)
    self.m_jackpotView:setVisible(false)

    -- 背景spine
    self.m_gameBgSpine = util_spineCreate("GameScreenJackpotOGoldBg", true, true)
    self.m_gameBg:findChild("Node_spine"):addChild(self.m_gameBgSpine)

    -- 背景idle
    self:changeShowBgIdle(1,false,false)

    --主要会挂载一些动效相关的节点
    self.m_role_node = self:findChild("Node_jackpotEffect")
    
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        if not self.m_isPlayWinSound then
            self.m_isPlayWinSound = true
            return
        end

        local spintime = self.m_runSpinResultData.p_selfMakeData.spintime 
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

        if spintime >= 20 then
            if winRate <= 1 then
                soundIndex = 11
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 22
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 33
            elseif winRate > 6 then
                soundIndex = 33
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "JackpotOGoldSounds/music_JackpotOGold_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenJackpotOGoldMachine:initMachineUI( )
    
    CodeGameScreenJackpotOGoldMachine.super.initMachineUI( self )

    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for i =1 ,#self.m_slotParents do
        local parentData = self.m_slotParents[i]
        
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

    end
    --创建压黑层
    local node = cc.Node:create()
    local reel1 = self:findChild("sp_reel_1")
    local reelSize1 = reel1:getContentSize()
    self.m_slotParents[5].slotParent:getParent():addChild(node,REEL_SYMBOL_ORDER.REEL_ORDER_2 + 10)
    self.slotParentNode_1 = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
    self.slotParentNode_1:setOpacity(200)
    self.slotParentNode_1:setContentSize(cc.size(slotW, slotH))
    self.slotParentNode_1:setAnchorPoint(cc.p(0, 0))
    self.slotParentNode_1:setTouchEnabled(false)
    node:addChild(self.slotParentNode_1,REEL_SYMBOL_ORDER.REEL_ORDER_2 + 10)
    self.slotParentNode_1:setPosition(cc.p(-slotW + reelSize1.width + reelSize1.width/2 ,0))
    self.slotParentNode_1:setVisible(false)
end

-- 背景切换
-- 1表示base 2表示free 3表示wheel
-- isChange 表示idle1 和 idle2 相互切换
-- isChangeWheel 表示从转轮背景切换到idle1 或者 idle2
function CodeGameScreenJackpotOGoldMachine:changeShowBgIdle(_index, isChange, isChangeWheel)
    if _index == 1 then
        self.m_gameBgSpine:setVisible(true)
        if isChange then
            self.m_gameBg:runCsbAction("switch",true)
            self.m_gameBg:findChild("Particle_6"):resetSystem()
            util_spinePlay(self.m_gameBgSpine,"switch2")
            util_spineEndCallFunc(self.m_gameBgSpine,"switch2",function ()
                self.m_gameBg:runCsbAction("idle".._index,true)
                util_spinePlay(self.m_gameBgSpine,"idle".._index,true)
                self.m_gameBg:findChild("Particle_1"):resetSystem()
                self.m_gameBg:findChild("Particle_2"):resetSystem()
            end)
        elseif isChangeWheel then
            self.m_gameBg:runCsbAction("over",false, function()
                self.m_gameBg:runCsbAction("idle".._index,true)
                util_spinePlay(self.m_gameBgSpine,"idle".._index,true)
                self.m_gameBg:findChild("Particle_1"):resetSystem()
                self.m_gameBg:findChild("Particle_2"):resetSystem()
            end)
            
        else 
            self.m_gameBg:runCsbAction("idle".._index,true)
            util_spinePlay(self.m_gameBgSpine,"idle".._index,true)
            self.m_gameBg:findChild("Particle_1"):resetSystem()
            self.m_gameBg:findChild("Particle_2"):resetSystem()
        end
    elseif _index == 2 then
        self.m_gameBgSpine:setVisible(true)
        if isChange then
            self.m_gameBg:runCsbAction("switch",true)
            self.m_gameBg:findChild("Particle_6"):resetSystem()
            util_spinePlay(self.m_gameBgSpine,"switch1")
            util_spineEndCallFunc(self.m_gameBgSpine,"switch1",function ()
                self.m_gameBg:runCsbAction("idle".._index,true)
                util_spinePlay(self.m_gameBgSpine,"idle".._index,true)
                self.m_gameBg:findChild("Particle_3"):resetSystem()
                self.m_gameBg:findChild("Particle_4"):resetSystem()
                self.m_gameBg:findChild("Particle_5"):resetSystem()
            end)
        elseif isChangeWheel then
            self.m_gameBg:runCsbAction("over",false, function()
                self.m_gameBg:runCsbAction("idle".._index,true)
                util_spinePlay(self.m_gameBgSpine,"idle".._index,true)
                self.m_gameBg:findChild("Particle_3"):resetSystem()
                self.m_gameBg:findChild("Particle_4"):resetSystem()
                self.m_gameBg:findChild("Particle_5"):resetSystem()
            end)
        else
            self.m_gameBg:runCsbAction("idle".._index,true)
            util_spinePlay(self.m_gameBgSpine,"idle".._index,true)
            self.m_gameBg:findChild("Particle_3"):resetSystem()
            self.m_gameBg:findChild("Particle_4"):resetSystem()
            self.m_gameBg:findChild("Particle_5"):resetSystem()
        end
    elseif _index == 3 then
        self.m_gameBgSpine:setVisible(false)
        self.m_gameBg:runCsbAction("start",false,function()
            self.m_gameBg:runCsbAction("idle".._index,true)
        end)
    end
end

function CodeGameScreenJackpotOGoldMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound( "JackpotOGoldSounds/sound_JackpotOGold_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenJackpotOGoldMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenJackpotOGoldMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    -- 打开提醒框
    self:showTipsOpenView()
    self:showTipsPotOpenView()
end

function CodeGameScreenJackpotOGoldMachine:addObservers()
    CodeGameScreenJackpotOGoldMachine.super.addObservers(self)

    -- 切换bet
    gLobalNoticManager:addObserver(self,function(self,params)
        local betCoin = globalData.slotRunData:getCurTotalBet()
        local cur_coin = JackpotOGoldBaseData:getInstance():getDataByKey("curBetValue")
        local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0
        local currentMusicBgName = self.m_currentMusicBgName
        if tonumber(betCoin) ~= tonumber(cur_coin) then
            self:updataJackpotOGoldCurBetData()
            
            if self.m_curSpinNum >= 20 then
                if currentMusicBgName ~= "JackpotOGoldSounds/music_basegame20_bg.mp3" then
                    self:resetMusicBg(nil,"JackpotOGoldSounds/music_basegame20_bg.mp3")
                end
            else
                if currentMusicBgName ~= "JackpotOGoldSounds/music_basegame_bg.mp3" then
                    self:resetMusicBg()
                end
            end

            if volume ~= 0 then
                gLobalSoundManager:setBackgroundMusicVolume(1)
                self:checkTriggerOrInSpecialGame(function(  )
                    self:reelsDownDelaySetMusicBGVolume( ) 
                end)
            else
                gLobalSoundManager:setBackgroundMusicVolume(0)
            end


            self:updateLock(false)
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenJackpotOGoldMachine:enterLevel()
    CodeGameScreenJackpotOGoldMachine.super.enterLevel(self)

    self:updateLock(true)
    self:updataJackpotOGoldCurBetData()
end

function CodeGameScreenJackpotOGoldMachine:updataJackpotOGoldCurBetData( )
    local betValue = toLongNumber(globalData.slotRunData:getCurTotalBet()) 
    JackpotOGoldBaseData:getInstance():setCurBetValue(tostring(betValue))
    local bonusModeData = JackpotOGoldBaseData:getInstance():getDataByKey("bonusMode")
    -- 进入关卡刷新 界面的数据
    self:updateViewDate(bonusModeData[tostring(betValue)])
end

-- 进入关卡刷新 界面的数据
function CodeGameScreenJackpotOGoldMachine:updateViewDate(bonusModeData)

    self.m_CollectPot:findChild("m_lb_coins"):setString(util_formatCoins(bonusModeData.totalbonus,3))
    self.m_SpinNum:findChild("m_lb_num"):setString(bonusModeData.spintime)

    self.m_curSpinNum = bonusModeData.spintime

    if bonusModeData.spintime == 20 then
        -- 背景idle
        self.m_gameBgSpine:setVisible(true)
        self.m_gameBg:runCsbAction("idle2",true)
        util_spinePlay(self.m_gameBgSpine,"idle2",true)
        self.m_gameBg:findChild("Particle_3"):resetSystem()
        self.m_gameBg:findChild("Particle_4"):resetSystem()
        self.m_gameBg:findChild("Particle_5"):resetSystem()
        
        self:findChild("reel_base"):setVisible(false)
        self:findChild("reel_base_20"):setVisible(true)

        self.m_SpinNum:runCsbAction("idle3",true)
        self:runCsbAction("idle",true)
    else
        -- 背景idle
        self.m_gameBgSpine:setVisible(true)
        self.m_gameBg:runCsbAction("idle1",true)
        util_spinePlay(self.m_gameBgSpine,"idle1",true)
        self.m_gameBg:findChild("Particle_1"):resetSystem()
        self.m_gameBg:findChild("Particle_2"):resetSystem()

        self:findChild("reel_base"):setVisible(true)
        self:findChild("reel_base_20"):setVisible(false)

        if bonusModeData.spintime >= 18 and bonusModeData.spintime <= 19 then
            self.m_SpinNum:runCsbAction("idle2",true)
        else
            self.m_SpinNum:runCsbAction("idle",true)
        end
        self:runCsbAction("idle1",true)
    end

    for i=1,24 do
        self:showJackpotLight(i, false)
    end

    for i,_jackpotId in ipairs(bonusModeData.getjackpot) do
        self:showJackpotLight(_jackpotId, true)
    end

    -- 删除差一个集齐的特效
    for iId=1,5 do
        if self.m_jackpotEffectNode[iId] and #self.m_jackpotEffectNode[iId] > 0 then
            for i,vNode in ipairs(self.m_jackpotEffectNode[iId]) do
                vNode:setVisible(false)
                vNode:removeFromParent()
                self.m_jackpotEffectNode[iId] = nil
            end
        end
    end
    self:setJackpotEffect(bonusModeData)
end

--[[
    begin 前重新刷新收集的jackpot
]]
function CodeGameScreenJackpotOGoldMachine:againUpdateJackpotCollect()
    local betValue = toLongNumber(globalData.slotRunData:getCurTotalBet())
    JackpotOGoldBaseData:getInstance():setCurBetValue(tostring(betValue))
    local bonusModeList = JackpotOGoldBaseData:getInstance():getDataByKey("bonusMode")
    local bonusModeData = bonusModeList[tostring(betValue)]
    for i=1,24 do
        self:showJackpotLight(i, false)
    end

    for i,_jackpotId in ipairs(bonusModeData.getjackpot) do
        self:showJackpotLight(_jackpotId, true)
    end
    self:setJackpotEffect(bonusModeData)
end

function CodeGameScreenJackpotOGoldMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenJackpotOGoldMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    JackpotOGoldBaseData:clear()
    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    if self.m_scheduleIdPot then
        self:stopAction(self.m_scheduleIdPot)
        self.m_scheduleIdPot = nil
    end
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenJackpotOGoldMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_BONUS then
        return "Socre_JackpotOGold_Bonus"
    end
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_JackpotOGold_10"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenJackpotOGoldMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenJackpotOGoldMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenJackpotOGoldMachine:MachineRule_initGame(  )
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local spintime = self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.spintime or 0

    self.m_isDuanXian = true
    if selfMakeData and selfMakeData.collectcredit and #selfMakeData.collectcredit ~= 18 then
        for i=1,#selfMakeData.collectcredit do
            self.m_WheelLogoCollect[i]:setVisible(true)
        end
    end

    if spintime == 20 then
        -- 背景idle
        self:changeShowBgIdle(2,false,false)
        self.m_SpinNum:runCsbAction("idle3",true)
        self:runCsbAction("idle",true)
        self:findChild("reel_base"):setVisible(false)
        self:findChild("reel_base_20"):setVisible(true)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenJackpotOGoldMachine:slotOneReelDown(reelCol)    
    CodeGameScreenJackpotOGoldMachine.super.slotOneReelDown(self,reelCol) 

    if reelCol == 1 then
        self:reelStopHideMask(1,1)
    end
    
end

---------------------------------------------------------------------------

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenJackpotOGoldMachine:MachineRule_SpinBtnCall()
    if self.m_isWheelBackInterval then
        self:waitWithDelay(function()
            self:setGameSpinStage(IDLE)
        end,0.1)
        return true
    end
    -- 转轮界面开着的话 点击spin 关闭
    if self.m_bonusWheel:isVisible() then
        return false -- 用作延时点击spin调用
    else
        local spintime = self.m_curSpinNum
        if spintime == 19 then
            self:resetMusicBg(nil,"JackpotOGoldSounds/music_basegame20_bg.mp3")
        elseif spintime == 20 then
            self:resetMusicBg()
        else
            self:setMaxMusicBGVolume( )
        end

        if self.m_scheduleId then
            self:showTipsOverView()
        end

        if self.m_scheduleIdPot then
            self:showTipsPotOverView()
        end

        return false -- 用作延时点击spin调用
    end
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenJackpotOGoldMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenJackpotOGoldMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenJackpotOGoldMachine:addSelfEffect()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local jackpot_win = self.m_runSpinResultData.p_selfMakeData.jackpot_win
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local spintime = self.m_runSpinResultData.p_selfMakeData.spintime

    local isTriZimu = false --翻转字母
    local isTriGold = false -- 翻转金币
    for _index, _data in ipairs(storedIcons) do
        if _data[2] == 0 then
            isTriZimu = true
        else
            isTriGold = true
        end
    end

    -- bonus翻转 收集
    if storedIcons then
        -- 自定义动画创建方式 COLLECT_BONUS_EFFECT
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT
    end

    -- jackpot 奖励弹板
    if jackpot_win then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_JACKPOT_EFFECT
    end

    -- bonus翻转 收集 第二十次
    if isTriGold and spintime >= 20 then
        -- 自定义动画创建方式 COLLECT_GUANZI_EFFECT
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_GUANZI_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_GUANZI_EFFECT
    end

    -- 触发转轮玩法
    if #selfMakeData.collectcredit >= 18 and selfMakeData.collectwin then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_WHEEL_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_WHEEL_EFFECT
    end

end

-- 检查自定义事件
function CodeGameScreenJackpotOGoldMachine:cheakGameEffect(effectType)
    -- 
    for i,v in ipairs(self.m_gameEffects) do
        if v.p_selfEffectType == effectType then
            return true
        end
    end
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenJackpotOGoldMachine:MachineRule_playSelfEffect(effectData)
    if not self:cheakGameEffect(self.COLLECT_BONUS_EFFECT) then
        self.m_isClick = true
    end

    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:slotReelStopBonus(function()
            if not self:cheakGameEffect(self.COLLECT_JACKPOT_EFFECT) and not self:cheakGameEffect(self.COLLECT_GUANZI_EFFECT) then
                self.m_isClick = true
            end

            effectData.p_isPlay = true
            self:playGameEffect()
            self.m_isQuickStop = false
        end)
    elseif effectData.p_selfEffectType == self.COLLECT_JACKPOT_EFFECT then
        self:showJackpotView(function(  )
            if not self:cheakGameEffect(self.COLLECT_WHEEL_EFFECT) and not self:cheakGameEffect(self.COLLECT_GUANZI_EFFECT) then
                self.m_isClick = true

                -- 检查是否有大赢 没有的话 判断添加
                if not self:checkBigWin() then
                    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, self.COLLECT_JACKPOT_EFFECT)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                end
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.COLLECT_GUANZI_EFFECT then
        self:slotReelStopBonusGuanZi(function(  )
            if not self:cheakGameEffect(self.COLLECT_WHEEL_EFFECT) then
                self.m_isClick = true

                -- 检查是否有大赢 没有的话 判断添加
                if not self:checkBigWin() then
                    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, self.COLLECT_GUANZI_EFFECT)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                end
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.COLLECT_WHEEL_EFFECT then
        self:triWheelByJackpot(function(  )
            self.m_isClick = true
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
	return true
end

-- 集满18个jackpot 
function CodeGameScreenJackpotOGoldMachine:triWheelByJackpot(_func)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local waitTime = 4
    if #selfMakeData.collectcredit ~= #selfMakeData.collectcreditNew then
        waitTime = 0
    end
    if #selfMakeData.collectcredit == 18 and #selfMakeData.collectcredit == #selfMakeData.collectcreditNew then
        waitTime = 50/60
    end

    self:waitWithDelay(function()
        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_logo_jiman_trigger.mp3")

        self.m_WheelLogo:runCsbAction("actionframe3",false,function()
            self:JiManOpenWheelView(true,_func)
        end)
    end,waitTime)
end

-- 显示jackpot
function CodeGameScreenJackpotOGoldMachine:showJackpotView(_func)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    local nodeName = {"grand", "major", "mini", "minor", "super"}
    local jackpot_win = self.m_runSpinResultData.p_selfMakeData.jackpot_win
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData

    local addIndexMan = 5 -- 用来判断集满18个jackpot时 是否有多余的，如果有多余的 就不收集了
    if #selfMakeData.collectcredit ~= #selfMakeData.collectcreditNew then
        addIndexMan = #jackpot_win - (#selfMakeData.collectcreditNew - #selfMakeData.collectcredit)
    end

    local function createTuoweiFly(nodeName)
        if nodeName == "grand" then
            return 1,5
        elseif nodeName == "super" then
            return 6,10
        elseif nodeName == "major" then
            return 11,15
        elseif nodeName == "minor" then
            return 16,20
        elseif nodeName == "mini" then
            return 21,24
        end
    end

    local function getJackpot(nodeName)
        if nodeName == "grand" then
            return self.m_JackpotGrandView
        elseif nodeName == "super" then
            return self.m_JackpotSuperView
        elseif nodeName == "major" then
            return self.m_JackpotMajorView
        elseif nodeName == "minor" then
            return self.m_JackpotMinorView
        elseif nodeName == "mini" then
            return self.m_JackpotMiniView
        end
    end

    local function getJackpotId(nodeName)
        if nodeName == "grand" then
            return 1
        elseif nodeName == "super" then
            return 2
        elseif nodeName == "major" then
            return 3
        elseif nodeName == "minor" then
            return 4
        elseif nodeName == "mini" then
            return 5
        end
    end

    for index, vJackpotWin in ipairs(jackpot_win) do
        local waitTime = ((60+120+39)/60+2.2+170/60)*(index-1)+90/60

        -- 收集jackpot有溢出情况，超过18个的 需要减去自动打开转轮所需要的时间
        if #selfMakeData.collectcredit ~= #selfMakeData.collectcreditNew and (index > (addIndexMan+1)) then
            waitTime = waitTime - 260/60*(index-(addIndexMan+1))
        end 

        -- jackpot集满 触发的时候 音效 多个 只播放一次
        if index == 1 then
            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_jackpot_man.mp3")
        end
        -- actionframe播放完 再弹弹板 90/60
        getJackpot(vJackpotWin[1]):runCsbAction("actionframe",false,function()
            -- 只有中多个jackpot的时候 除了第一个 其他的 会播放idle2
            if #jackpot_win > 1 and index ~= 1 then
                getJackpot(vJackpotWin[1]):runCsbAction("idle2",true)
            end
        end)

        self:waitWithDelay(function()
            for m,vName in ipairs(nodeName) do
                self.m_jackpotView:findChild(vName):setVisible(false)
                self.m_jackpotView:findChild("light_"..vName):setVisible(false)
            end

            self.m_jackpotView:findChild(vJackpotWin[1]):setVisible(true)
            self.m_jackpotView:findChild("light_"..vJackpotWin[1]):setVisible(true)

            getJackpot(vJackpotWin[1]):findChild("Particle_7"):resetSystem()

            self.m_jackpotView:setVisible(true)

            local startIndex, endIndex = createTuoweiFly(vJackpotWin[1])
            for jackpotIndex = startIndex, endIndex do
                local startWorldPos =  self:getJackPotNode(jackpotIndex):getParent():convertToWorldSpace(cc.p(self:getJackPotNode(jackpotIndex):getPosition()))
                local startPos = self.m_role_node:convertToNodeSpace(startWorldPos)
                
                local endPosWord = self.m_jackpotView:findChild("Node_jackpot"):getParent():convertToWorldSpace(cc.p(self.m_jackpotView:findChild("Node_jackpot"):getPosition()))
                local endPos = self.m_role_node:convertToNodeSpace(endPosWord)
                self:runFlyLineActTuoWei(startPos, endPos, jackpotIndex)
                if jackpotIndex == startIndex then
                    getJackpot(vJackpotWin[1]):runCsbAction("idle",true)
                    self:resetJackpotShow(vJackpotWin)
                end
            end

            self.m_jackpotView:findChild("Particle_7_0"):resetSystem()
            self.m_jackpotView:findChild("Particle_7"):resetSystem()

            self.m_jackpotView:showResult(self,vJackpotWin[2],getJackpotId(vJackpotWin[1]))
            globalData.jackpotRunData:notifySelfJackpot(vJackpotWin[2],getJackpotId(vJackpotWin[1]))

            local random = math.random(1, 2)
            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_jackpot_tanban" .. random .. ".mp3")

            self.m_jackpotView:runCsbAction("start",false,function(  )
                self.m_jackpotView:runCsbAction("idle",false,function(  )
                    if index <= addIndexMan then
                        for i = startIndex, endIndex do
                            local startWorldPos =  self.m_jackpotView:findChild("JackpotOGold_"..i):getParent():convertToWorldSpace(cc.p(self.m_jackpotView:findChild("JackpotOGold_"..i):getPosition()))
                            local startPos = self.m_role_node:convertToNodeSpace(startWorldPos)
                            
                            local endPosWord = self.m_WheelLogo:getParent():convertToWorldSpace(cc.p(self.m_WheelLogo:getPosition()))
                            local endPos = self.m_role_node:convertToNodeSpace(endPosWord)
                            self:runFlyLineActTuoWei(startPos,endPos,i,function()
                                if i == startIndex then
                                    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_jackpot_Logo_feedback.mp3")

                                    self.m_WheelLogo:runCsbAction("actionframe",false,function()
                                        self.m_WheelLogo:runCsbAction("idle",true)
                                    end)
                                    if #selfMakeData.collectcredit == 0 then
                                        for wheelIndex = 1, 18 do
                                            self.m_WheelLogoCollect[wheelIndex]:setVisible(false)
                                        end
                                    else
                                        if #selfMakeData.collectcredit == 18 then
                                            if #selfMakeData.collectcredit ~= #selfMakeData.collectcreditNew then
                                                for _index = 1, (#selfMakeData.collectcredit-addIndexMan+index) do
                                                    self.m_WheelLogoCollect[_index]:setVisible(true)
                                                end
                                            else
                                                for _index = 1, (#selfMakeData.collectcredit-#jackpot_win+index) do
                                                    self.m_WheelLogoCollect[_index]:setVisible(true)
                                                end
                                            end
                                        else
                                            for _index = 1, (#selfMakeData.collectcredit-#jackpot_win+index) do
                                                self.m_WheelLogoCollect[_index]:setVisible(true)
                                            end
                                        end
                                    end

                                    -- 刚好收集18个jackpot 不用再打开转轮界面
                                    -- 溢出的话 正常打开
                                    if #selfMakeData.collectcredit == 18 and #selfMakeData.collectcredit == #selfMakeData.collectcreditNew and index == #jackpot_win then
                                    else
                                        self:waitWithDelay( function (  )
                                            -- 打开转轮界面
                                            self:openWheelView(nil,index)
                                        end,1.2)
                                    end
                                end
                            end)
                        end
                    end

                    globalData.slotRunData.lastWinCoin = 0
                    self.m_isPlayWinSound = false
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_winCoinCurSpin + vJackpotWin[2],false,true,self.m_winCoinCurSpin})
                    self.m_winCoinCurSpin = self.m_winCoinCurSpin + vJackpotWin[2]
                    self.m_jackpotView:findChild("Particle_7_0"):resetSystem()
                    self.m_jackpotView:findChild("Particle_7"):resetSystem()

                    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_jackpot_tanban_ZimuFlyToLogo.mp3")
                    self.m_jackpotView:jackPotOver(function()
                        self.m_jackpotView:runCsbAction("over",false,function(  )
                            self.m_jackpotView:setVisible(false)
                            self.m_jackpotView:runCsbAction("idle",false)
                            self.m_jackpotView:onExit()
                            
                            if index == #jackpot_win then
                                if #selfMakeData.collectcredit ~= #selfMakeData.collectcreditNew then
                                    if _func then
                                        _func()
                                    end
                                else
                                    if #selfMakeData.collectcredit == 18 and #selfMakeData.collectcredit == #selfMakeData.collectcreditNew and index == #jackpot_win then
                                        if _func then
                                            _func()
                                        end
                                    else
                                        self:waitWithDelay( function (  )
                                            if _func then
                                                _func()
                                            end
                                        end, 277/60)
                                    end
                                end
                            end
                        end)
                    end)
                end)
            end)
        end,waitTime)
    end
    
end

-- jackpot拖尾动画
function CodeGameScreenJackpotOGoldMachine:runFlyLineActTuoWei(startPos,endPos,zimuId,func)

    -- gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_CollectFly.mp3")
    -- 创建粒子
    local flyNode =  util_createAnimation("JackpotOGold_ZiMushouji.csb")
    self.m_role_node:addChild(flyNode,300000)
    flyNode:setPosition(cc.p(startPos))

    -- 创建字母
    local flyZiMuNode =  util_createAnimation("JackpotOGold_ZiMushouji_2.csb")
    self.m_role_node:addChild(flyZiMuNode,300001)
    flyZiMuNode:setPosition(cc.p(startPos))

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)

    -- local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    -- flyNode:setScaleX(scaleSize / 250 )

    --创建临时乘倍标签和粒子一起飞下去
    local zimuNode =  util_createAnimation("Socre_JackpotOGold_Bonus_coin.csb")
    flyZiMuNode:findChild("zimu"):addChild(zimuNode,1)

    zimuNode:findChild("Particle_1"):setVisible(false)
    zimuNode:findChild("Particle_2"):setVisible(false)
    zimuNode:findChild("Node_CoinNum"):setVisible(false)
    for jackpotIndex = 1, 24 do
        zimuNode:findChild("jackpot_"..jackpotIndex):setVisible(false)
    end
    zimuNode:findChild("jackpot_"..zimuId):setVisible(true)

    self:waitWithDelay(function()
        if flyZiMuNode:findChild("Particle_16") then
            flyZiMuNode:findChild("Particle_16"):setDuration(500)
            flyZiMuNode:findChild("Particle_16"):setPositionType(0)
            flyZiMuNode:findChild("Particle_16"):resetSystem()
        end
        if flyZiMuNode:findChild("Particle_16_0") then
            flyZiMuNode:findChild("Particle_16_0"):setDuration(500)
            flyZiMuNode:findChild("Particle_16_0"):setPositionType(0)
            flyZiMuNode:findChild("Particle_16_0"):resetSystem()
        end

        local move = cc.MoveTo:create(21/60,endPos)
        local call = cc.CallFunc:create(function ()
            if flyZiMuNode:findChild("Particle_16") then
                flyZiMuNode:findChild("Particle_16"):stopSystem()
            end
            if flyZiMuNode:findChild("Particle_16_0") then
                flyZiMuNode:findChild("Particle_16_0"):stopSystem()
            end
            flyZiMuNode:findChild("zimu"):setVisible(false)

            if func then
                func()
            end

            self:waitWithDelay( function()
                flyZiMuNode:removeFromParent()
            end,0.5)
        end)

        local seq = cc.Sequence:create(move,call)
        flyZiMuNode:runAction(seq)
    end,5/60)

    self:waitWithDelay(function()
    
        local move = cc.MoveTo:create(21/60,endPos)
        local call = cc.CallFunc:create(function ()
            
        end)

        local seq = cc.Sequence:create(move,call)
        flyNode:runAction(seq)
    end,5/60)

    self:waitWithDelay(function()
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end,30/60)
    
    flyZiMuNode:runCsbAction("shouji1",false)
    flyNode:runCsbAction("shouji1",false)
end

-- 重置jackpot显示
function CodeGameScreenJackpotOGoldMachine:resetJackpotShow(vJackpotWin)
    if vJackpotWin[1] == "grand" then
        for i=1,5 do
            self.m_JackpotGrandView:findChild("Collect_"..i):setVisible(false)
            self.m_JackpotGrandView:findChild("Dark_"..i):setVisible(not false)
        end
    elseif vJackpotWin[1] == "super" then
        for i=6,10 do
            self.m_JackpotSuperView:findChild("Collect_"..i):setVisible(false)
            self.m_JackpotSuperView:findChild("Dark_"..i):setVisible(not false)
        end
    elseif vJackpotWin[1] == "major" then
        for i=11,15 do
            self.m_JackpotMajorView:findChild("Collect_"..i):setVisible(false)
            self.m_JackpotMajorView:findChild("Dark_"..i):setVisible(not false)
        end
    elseif vJackpotWin[1] == "minor" then
        for i=16,20 do
            self.m_JackpotMinorView:findChild("Collect_"..i):setVisible(false)
            self.m_JackpotMinorView:findChild("Dark_"..i):setVisible(not false)
        end
    elseif vJackpotWin[1] == "mini" then
        for i=21,24 do
            self.m_JackpotMiniView:findChild("Collect_"..i):setVisible(false)
            self.m_JackpotMiniView:findChild("Dark_"..i):setVisible(not false)
        end
    end
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenJackpotOGoldMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenJackpotOGoldMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenJackpotOGoldMachine.super.slotReelDown(self)

end

-- 轮盘停止之后 bonus信号94 翻转
function CodeGameScreenJackpotOGoldMachine:slotReelStopBonus(_func)
    -- p_storedIcons里面的数据表示bonus翻转之后的信息
    -- 第一个表示bonus位置
    -- 第二个表示bonus类型（0表示jackpot对应的字母，1表示金币）
    -- 第三个表示字母对应的ID（1-24个），或者金币的数量
    -- 前19次和第20次翻转的金币不一样 显示的
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local spintime = self.m_runSpinResultData.p_selfMakeData.spintime
    local totalBonus = self.m_runSpinResultData.p_selfMakeData.totalbonus
    local isHaveCoin = false
    local isHaveZiMu = false
    for _index, _data in ipairs(storedIcons) do
        -- 提前判断反正出来的 是否有金币
        if _data[2] == 1 then
            isHaveCoin = true
        elseif _data[2] == 0 then
            isHaveZiMu = true
        end
    end

    --从左到右 从上到下哦 排序
    table.sort( storedIcons, function(a, b)
        local rowColDataA = self:getRowAndColByPos(a[1])
        local rowColDataB = self:getRowAndColByPos(b[1])
        if rowColDataA.iY == rowColDataB.iY then
            return rowColDataA.iX > rowColDataB.iX
        end
        return rowColDataA.iY < rowColDataB.iY
    end )

    if #storedIcons > 0 then
        for _index, _storedIconsData in ipairs(storedIcons) do
            local waitTime = 0
            -- 第20次没有点击快停的话 依次间隔翻转
            if spintime == 20 and (not self.m_isQuickStop) then
                waitTime = 20/30*(_index-1)
            end
            self:waitWithDelay(function()
                local rowColData = self:getRowAndColByPos(_storedIconsData[1])
                local targSp = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == self.SYMBOL_BONUS then
                        -- 翻转出字母
                        if _storedIconsData[2] == 0 then
                            local actionName = "switch1"
                            local bonusChangeDelayTime = 49/30 --前19次延时时间为 bonus翻转的时间线49帧；第20次需要间隔翻转，延时时间为最后一次翻转的时间；快停延时0
                            if spintime == 20 then
                                bonusChangeDelayTime = 20/30*(#storedIcons-_index)+49/30
                            end
                            if self.m_isQuickStop then
                                actionName = "idle"
                                bonusChangeDelayTime = 0
                            else
                                if spintime >= 20 then
                                    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusTurn.mp3")
                                else
                                    if _index == 1 then
                                        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusTurn.mp3")
                                    end
                                end
                            end

                            self:bonusChangeShow(actionName,targSp, self:getBonusSkin(_storedIconsData[3]))
                            self:waitWithDelay( function()
                                local startWorldPos =  self:getNodePosByColAndRow( rowColData.iX, rowColData.iY)
                                local startPos = self.m_role_node:convertToNodeSpace(startWorldPos)
                                local endPosWord = self:getJackPotNode(_storedIconsData[3]):getParent():convertToWorldSpace(cc.p(self:getJackPotNode(_storedIconsData[3]):getPosition()))
                                local endPos = self.m_role_node:convertToNodeSpace(endPosWord)
                                if _index == 1 then
                                    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusFly.mp3")
                                end
                                self:runFlyLineAct(_storedIconsData[2],_storedIconsData[3],startPos,endPos,function()
                                    if _index == #storedIcons then
                                        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusFlyToJackpot.mp3")
                                        if isHaveCoin and spintime ~= 20 then
                                            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusFlyToPot.mp3")
                                            self.m_CollectPot:runCsbAction("actionframe",false)
                                            self:waitWithDelay( function()
                                                self.m_CollectPot:findChild("m_lb_coins"):setString(util_formatCoins(totalBonus,3))
                                            end, 5/60)
                                        end
                                        if _func then
                                            _func()
                                        end
                                        
                                        -- 差一个字母时候 jackpot有特殊效果
                                        self:setJackpotEffect()
                                    end
                                    self:deleteJackpotEffect()

                                    local jackpotShoujiNode =  util_createAnimation("JackpotOGold_Jackpot_shouji.csb")
                                    self.m_role_node:addChild(jackpotShoujiNode,100) 
                                    local endPosWord = self:getJackPotNode(_storedIconsData[3]):getParent():convertToWorldSpace(cc.p(self:getJackPotNode(_storedIconsData[3]):getPosition()))
                                    local endPos = self.m_role_node:convertToNodeSpace(endPosWord)

                                    jackpotShoujiNode:setPosition(endPos)
                                    jackpotShoujiNode:runCsbAction("actionframe",false,function()
                                        jackpotShoujiNode:removeFromParent()
                                    end)
                                    self:showJackpotLight(_storedIconsData[3], true)
                                end)
                            end,bonusChangeDelayTime)
                        else
                            if spintime < 20 then
                                local actionName = "switch"
                                if self.m_isQuickStop then
                                    actionName = "idleframe"
                                else
                                    if spintime >= 20 then
                                        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusTurn.mp3")
                                    else
                                        if _index == 1 then
                                            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusTurn.mp3")
                                        end
                                    end
                                end
                                targSp:runAnim(actionName,false,function()
                                    local startWorldPos =  self:getNodePosByColAndRow( rowColData.iX, rowColData.iY)
                                    local startPos = self.m_role_node:convertToNodeSpace(startWorldPos)
                                    local endPosWord = self.m_CollectPot:findChild("m_lb_coins"):getParent():convertToWorldSpace(cc.p(self.m_CollectPot:findChild("m_lb_coins"):getPosition()))
                                    local endPos = self.m_role_node:convertToNodeSpace(endPosWord)

                                    if _index == 1 then
                                        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusFly.mp3")
                                    end

                                    self:runFlyLineAct(_storedIconsData[2],_storedIconsData[3],startPos,endPos,function()
                                        if _index == #storedIcons then
                                            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusFlyToPot.mp3")
                                            -- 判断有字母的话 播放音效
                                            if isHaveZiMu then
                                                gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusFlyToJackpot.mp3")
                                            end
                                            self.m_CollectPot:runCsbAction("actionframe",false)
                                            self:waitWithDelay( function()
                                                self.m_CollectPot:findChild("m_lb_coins"):setString(util_formatCoins(totalBonus,3))
                                            end, 5/60)
                                            if _func then
                                                _func()
                                            end

                                            -- 差一个字母时候 jackpot有特殊效果
                                            self:setJackpotEffect()
                                        end
                                    end)
                                end)
                                if targSp.m_goldNode == nil then
                                    local actionName1 = "switch"
                                    if self.m_isQuickStop then
                                        actionName1 = "idle"
                                    end
                                    targSp.m_goldNode = util_createAnimation("Socre_JackpotOGold_Bonus_coin.csb")
                                    targSp.m_goldNode:findChild("m_lb_coins"):setString(util_formatCoins(_storedIconsData[3]*self.m_runSpinResultData.p_bet*self.m_runSpinResultData.p_payLineCount,3))
                                    targSp.m_goldNode:setPosition(cc.p(0, 0))
                                    targSp:addChild(targSp.m_goldNode, 2)
                                    for j=1, 24 do
                                        targSp.m_goldNode:findChild("jackpot_"..j):setVisible(false)
                                    end
                                    targSp.m_goldNode:runCsbAction(actionName1,false)
                                    targSp.m_goldNode:setScale(2)
                                end
                                
                            else
                                local actionName = "actionframe3"
                                local bonusChangeDelayTime = 20/30*(#storedIcons-_index)+49/30
                                if self.m_isQuickStop then
                                    actionName = "idle2"
                                    bonusChangeDelayTime = 0
                                else
                                    if spintime >= 20 then
                                        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusTurn.mp3")
                                    else
                                        if _index == 1 then
                                            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusTurn.mp3")
                                        end
                                    end
                                end
                                self:waitWithDelay( function()
                                    if _index == 1 and isHaveZiMu then
                                        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusFly.mp3")
                                    end
                                end,bonusChangeDelayTime)
                                -- actionframe3 60帧
                                targSp:runAnim(actionName,false,function()
                                    if _index == #storedIcons then
                                        -- 判断有字母的话 播放音效
                                        if isHaveZiMu then
                                            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonusFlyToJackpot.mp3")
                                        end

                                        if _func then
                                            _func()
                                        end
                                        -- 差一个字母时候 jackpot有特殊效果
                                        self:setJackpotEffect()
                                    end
                                end)
                            end
                        end
                    end
                end
            end,waitTime)
        end
    else
        if _func then
            _func()
        end
    end
end

-- 轮盘停止之后 bonus信号94 翻转出罐子
function CodeGameScreenJackpotOGoldMachine:slotReelStopBonusGuanZi(_func)
    -- p_storedIcons里面的数据表示bonus翻转之后的信息
    -- 第一个表示bonus位置
    -- 第二个表示bonus类型（0表示jackpot对应的字母，1表示金币）
    -- 第三个表示字母对应的ID（1-24个），或者金币的数量
    -- 前19次和第20次翻转的金币不一样 显示的
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local spintime = self.m_runSpinResultData.p_selfMakeData.spintime
    local totalBonus = self.m_runSpinResultData.p_selfMakeData.totalbonus
    local guanziBonusNum = 0 --罐子数量

    table.sort( storedIcons, function(a, b)
        return a[2] < b[2]
    end )

    if #storedIcons > 0 then
        for _index, _storedIconsData in ipairs(storedIcons) do
            local rowColData = self:getRowAndColByPos(_storedIconsData[1])
            local targSp = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == self.SYMBOL_BONUS then
                    -- 翻转出罐子
                    if _storedIconsData[2] == 1 then
                        if spintime >= 20 then
                            guanziBonusNum = guanziBonusNum + 1
                            if guanziBonusNum == 1 then
                                gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_bonus20pot_trigger.mp3")
                            end

                            targSp:runAnim("actionframe4",false,function()
                                -- 罐子触发喷 彩虹时候的 音效
                                if _index == #storedIcons then
                                    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_pot_trigger.mp3")
                                end

                                self.m_CollectPot:runCsbAction("actionframe2",false,function()
                                    local endWorldPos =  self:getNodePosByColAndRow( rowColData.iX, rowColData.iY)
                                    local endPos = self.m_role_node:convertToNodeSpace(endWorldPos)
                                    
                                    local startWorldPos = self.m_CollectPot:findChild("m_lb_coins"):getParent():convertToWorldSpace(cc.p(self.m_CollectPot:findChild("m_lb_coins"):getPosition()))
                                    local startPos = self.m_role_node:convertToNodeSpace(startWorldPos)

                                    -- 灌子上的钱 飞向棋盘上的bonus音效 同时飞 只播放一次
                                    if _index == #storedIcons then
                                        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_pot_CoinToBonus.mp3")
                                    end
                                    self:runFlyLineAct(_storedIconsData[2],_storedIconsData[3],startPos,endPos,function()
                                        if _index == #storedIcons then
                                            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_pot_CoinToBonus_trigger.mp3")
                                        end
                                        targSp:runAnim("shouji",false,function()
                                            if _index == #storedIcons then
                                                self:waitWithDelay( function()
                                                    if _func then
                                                        _func()
                                                    end
                                                end,0.5)

                                                globalData.slotRunData.lastWinCoin = 0
                                                self.m_isPlayWinSound = false
                                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{guanziBonusNum*_storedIconsData[3]*self.m_runSpinResultData.p_bet*self.m_runSpinResultData.p_payLineCount+self.m_winCoinCurSpin,false,true,self.m_winCoinCurSpin})
                                                self.m_winCoinCurSpin = self.m_winCoinCurSpin + guanziBonusNum*_storedIconsData[3]*self.m_runSpinResultData.p_bet*self.m_runSpinResultData.p_payLineCount
                                            end
                                            
                                        end)
                                        if targSp.m_goldNode == nil then
                                            targSp.m_goldNode = util_createAnimation("Socre_JackpotOGold_Bonus_Pot_qianshu.csb")
                                            targSp.m_goldNode:findChild("m_lb_coins_0"):setString(util_formatCoins(_storedIconsData[3]*self.m_runSpinResultData.p_bet*self.m_runSpinResultData.p_payLineCount,3))
                                            targSp.m_goldNode:setPosition(cc.p(0, 0))
                                            targSp:addChild(targSp.m_goldNode, 2)
                                            targSp.m_goldNode:runCsbAction("shouji",false)
                                        end
                                    end)
                                end)
                                
                            end)
                        end
                    end
                end
            end
        end
    else
        if _func then
            _func()
        end
    end
end

-- 翻转之后收集飞
function CodeGameScreenJackpotOGoldMachine:runFlyLineAct(indexId,coinId,startPos,endPos,func)

    -- gLobalSoundManager:playSound("ZooManiaSounds/music_ZooMania_ChooseGame_CollectFly.mp3")
    -- 创建粒子
    local flyNode =  util_createAnimation("Socre_JackpotOGold_Bonus_coin.csb")
    self.m_role_node:addChild(flyNode,300000)

    if indexId == 1 then
        for j=1, 24 do
            flyNode:findChild("jackpot_"..j):setVisible(false)
        end
        flyNode:findChild("m_lb_coins"):setString(util_formatCoins(coinId*self.m_runSpinResultData.p_bet*self.m_runSpinResultData.p_payLineCount,3))
    elseif indexId == 0 then
        flyNode:findChild("Node_CoinNum"):setVisible(false)
        for j=1, 24 do
            flyNode:findChild("jackpot_"..j):setVisible(false)
        end
        flyNode:findChild("jackpot_"..coinId):setVisible(true)

    end

    flyNode:setPosition(cc.p(startPos))

    if flyNode:findChild("Particle_1") then
        flyNode:findChild("Particle_1"):setDuration(500)
        flyNode:findChild("Particle_1"):setPositionType(0)
        flyNode:findChild("Particle_1"):resetSystem()
    end
    if flyNode:findChild("Particle_2") then
        flyNode:findChild("Particle_2"):setDuration(500)
        flyNode:findChild("Particle_2"):setPositionType(0)
        flyNode:findChild("Particle_2"):resetSystem()
    end

    local actionList = {}
    actionList[#actionList+1] = cc.MoveTo:create(18/60,endPos)
    actionList[#actionList+1] = cc.CallFunc:create(function ()
        if flyNode:findChild("Particle_1") then
            flyNode:findChild("Particle_1"):stopSystem()
        end
        if flyNode:findChild("Particle_2") then
            flyNode:findChild("Particle_2"):stopSystem()
        end
        if indexId == 0 then
            flyNode:findChild("jackpot_"..coinId):setVisible(false)
        else
            flyNode:findChild("Node_CoinNum"):setVisible(false)
        end

        if func then
            func()
        end
    end)
    actionList[#actionList+1] = cc.DelayTime:create(0.5)
    actionList[#actionList+1] = cc.CallFunc:create(function ()
        flyNode:removeFromParent()
    end)

    local seq = cc.Sequence:create(actionList)
    flyNode:runAction(seq)
    flyNode:runCsbAction("shouji",false)
end

-- 获取jackpot node
function CodeGameScreenJackpotOGoldMachine:getJackPotNode( _jackpotId)
    local JackNode = nil
    if _jackpotId >= 1 and _jackpotId <= 5 then
        -- jackpot Grand
        JackNode = self.m_JackpotGrandView:findChild("Dark_".._jackpotId)
    elseif _jackpotId >= 6 and _jackpotId <= 10 then
        -- jackpot Super
        JackNode = self.m_JackpotSuperView:findChild("Dark_".._jackpotId)
    elseif _jackpotId >= 11 and _jackpotId <= 15 then
        -- jackpot Major
        JackNode = self.m_JackpotMajorView:findChild("Dark_".._jackpotId)
    elseif _jackpotId >= 16 and _jackpotId <= 20 then
        -- jackpot Minor
        JackNode = self.m_JackpotMinorView:findChild("Dark_".._jackpotId)
    else
        -- jackpot Mini
        JackNode = self.m_JackpotMiniView:findChild("Dark_".._jackpotId)
    end

    return JackNode
end

-- jackpot 字母 亮
function CodeGameScreenJackpotOGoldMachine:showJackpotLight(_jackpotId, _isLight)
    if _jackpotId >= 1 and _jackpotId <= 5 then
        -- jackpot Grand
        self.m_JackpotGrandView:findChild("Collect_".._jackpotId):setVisible(_isLight)
        self.m_JackpotGrandView:findChild("Dark_".._jackpotId):setVisible(not _isLight)
    elseif _jackpotId >= 6 and _jackpotId <= 10 then
        -- jackpot Super
        self.m_JackpotSuperView:findChild("Collect_".._jackpotId):setVisible(_isLight)
        self.m_JackpotSuperView:findChild("Dark_".._jackpotId):setVisible(not _isLight)
    elseif _jackpotId >= 11 and _jackpotId <= 15 then
        -- jackpot Major
        self.m_JackpotMajorView:findChild("Collect_".._jackpotId):setVisible(_isLight)
        self.m_JackpotMajorView:findChild("Dark_".._jackpotId):setVisible(not _isLight)
    elseif _jackpotId >= 16 and _jackpotId <= 20 then
        -- jackpot Minor
        self.m_JackpotMinorView:findChild("Collect_".._jackpotId):setVisible(_isLight)
        self.m_JackpotMinorView:findChild("Dark_".._jackpotId):setVisible(not _isLight)
    else
        -- jackpot Mini
        self.m_JackpotMiniView:findChild("Collect_".._jackpotId):setVisible(_isLight)
        self.m_JackpotMiniView:findChild("Dark_".._jackpotId):setVisible(not _isLight)
    end

end

-- 切换皮肤
function CodeGameScreenJackpotOGoldMachine:bonusChangeShow(actionName,node,skinName,func)

    local ccbNode = node:getCCBNode()
    if not ccbNode then
        node:checkLoadCCbNode()
    end
    ccbNode = node:getCCBNode()
    if ccbNode then
        ccbNode.m_spineNode:setSkin(skinName)
    end
    node:runAnim(actionName,false,function()
        if func then
            func()
        end
    end)
end

-- 分类皮肤名字
function CodeGameScreenJackpotOGoldMachine:getBonusSkin(_index)
    if _index == 1 then
        return "grand_G"
    elseif _index == 2 then
        return "grand_R"
    elseif _index == 3 then
        return "grand_A"
    elseif _index == 4 then
        return "grand_N"
    elseif _index == 5 then
        return "grand_D"
    elseif _index == 6 then
        return "super_S"
    elseif _index == 7 then
        return "super_U"
    elseif _index == 8 then
        return "super_P"
    elseif _index == 9 then
        return "super_E"
    elseif _index == 10 then
        return "super_R"
    elseif _index == 11 then
        return "major_M"
    elseif _index == 12 then
        return "major_A"
    elseif _index == 13 then
        return "major_J"
    elseif _index == 14 then
        return "major_O"
    elseif _index == 15 then
        return "major_R"
    elseif _index == 16 then
        return "minor_M"
    elseif _index == 17 then
        return "minor_I"
    elseif _index == 18 then
        return "minor_N"
    elseif _index == 19 then
        return "minor_O"
    elseif _index == 20 then
        return "minor_R"
    elseif _index == 21 then
        return "mini_M"
    elseif _index == 22 then
        return "mini_I"
    elseif _index == 23 then
        return "mini_N"
    elseif _index == 24 then
        return "mini_I"
    end
end

function CodeGameScreenJackpotOGoldMachine:beginReel()
    local callBack = function ()
        local spintime = self.m_curSpinNum

        self:againUpdateJackpotCollect()

        gLobalNoticManager:postNotification("SHOW_SPIN_NUM")

        if spintime == 19 then
            self.m_SpinNum:runCsbAction("switch",false,function()
                self.m_SpinNum:runCsbAction("idle3",true)
            end)
            self.m_SpinNum:findChild("Particle_1"):resetSystem()
            
            -- 背景idle
            self:changeShowBgIdle(2,true,false)
            local random = math.random(1, 2)
            -- 第20次的时候 背景开始变化 随机播放一个音效
            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_spin20_BG_" .. random .. ".mp3")
            
            self:waitWithDelay(function()
                self:runCsbAction("start",false,function()
                    self:findChild("reel_base"):setVisible(false)
                    self:findChild("reel_base_20"):setVisible(true)
                end)
            end,20/30)
        end
        -- 第二十次的时候 重置数据
        if spintime == 20 then
            -- 背景idle
            self:changeShowBgIdle(1,true,false)
            -- self:waitWithDelay(function()
                self:runCsbAction("over",false,function()
                    self:findChild("reel_base"):setVisible(true)
                    self:findChild("reel_base_20"):setVisible(false)
                end)
            -- end,20/30)

            self.m_SpinNum:runCsbAction("idle",true)

            self.m_CollectPot:findChild("m_lb_coins"):setString(util_formatCoins(self.m_runSpinResultData.p_bet*self.m_runSpinResultData.p_payLineCount,3))
            
            for i=1,24 do
                self:showJackpotLight(i, false)
            end

            for iId=1,5 do
                if self.m_jackpotEffectNode[iId] and #self.m_jackpotEffectNode[iId] > 0 then
                    for i,vNode in ipairs(self.m_jackpotEffectNode[iId]) do
                        vNode:setVisible(false)
                        vNode:removeFromParent()
                        self.m_jackpotEffectNode[iId] = nil
                    end
                end
            end
            
        end
        
        -- 棋盘遮罩
        self:beginReelShowMask()

        self.m_winCoinCurSpin = 0

        if self.m_isDuanXian then
            self.m_isDuanXian = false
        end
        self.m_isClick = false
        self.m_isInit = false

        CodeGameScreenJackpotOGoldMachine.super.beginReel(self)
    end

    if self.m_isWheelReturnClick or not self.m_isClickLogoAndReel then
        -- 延时处理 不然callSpinBtn 方法 会重置这个值
        self:waitWithDelay(function()
            self:setGameSpinStage(IDLE)
        end,0.1)
        return
    end

    -- 转轮界面开着的话 点击spin 关闭
    if self.m_bonusWheel:isVisible() then
        
        self.m_isWheelReturnClick = true
        self:clickCloseWheelView(function()
            -- if self:getCurrSpinMode() == AUTO_SPIN_MODE then
                callBack()
            -- end
            
        end)
        -- 延时处理 不然callSpinBtn 方法 会重置这个值
        self:waitWithDelay(function()
            self:setGameSpinStage(IDLE)
            
        end,0.1)
        return
        
    end

    callBack()
end

function CodeGameScreenJackpotOGoldMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenJackpotOGoldMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    local spintime = self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.spintime or 0
    self.m_curSpinNum = spintime
    local callBack = function()
        self:produceSlots()

        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end

        local selfMakeData = self.m_runSpinResultData.p_selfMakeData
        JackpotOGoldBaseData:getInstance():initModes(selfMakeData)

        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end

    if spintime == 20 then
        self:waitWithDelay(function()
            callBack()
        end,50/30)
    else
        callBack()
    end
end

-- 延时函数
function CodeGameScreenJackpotOGoldMachine:waitWithDelay(endFunc, time)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
        waitNode = nil
    end, time)
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenJackpotOGoldMachine:initGameStatusData(gameData)
    CodeGameScreenJackpotOGoldMachine.super.initGameStatusData(self,gameData)
    if gameData.gameConfig and gameData.gameConfig.extra then
        JackpotOGoldBaseData:getInstance():setDataByKey("bonusMode", gameData.gameConfig.extra)
    end
end

function CodeGameScreenJackpotOGoldMachine:getBaseReelGridNode()
    return "CodeJackpotOGoldSrc.JackpotOGoldSlotNode"
end

-- 点击开启转轮玩法
function CodeGameScreenJackpotOGoldMachine:clickOpenWheelView()
    self.m_bottomUI:updateBetEnable(false)
    local p_selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local collectcredit = {}
    if p_selfMakeData == nil or #p_selfMakeData.collectcredit >= 18 then
        collectcredit = {}
    else
        collectcredit = p_selfMakeData.collectcredit
    end
    self.m_isClick = false
    self.m_isClickLogoAndReel = false 

    self.m_bonusWheel.m_WheelTotalWin:findChild("m_lb_coins"):setString(" ")
    self.m_bonusWheel:updateWheelView(collectcredit,false,nil)

    local startPosWord = self:findChild("Node_wheel_logo"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_wheel_logo"):getPosition()))
    local startPos = self.m_bonusWheel:convertToNodeSpace(startPosWord)

    util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_down,"start")
    util_spineEndCallFunc(self.m_bonusWheel.m_Wheel_maozi_down,"start",function ()
        util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_down,"idle")
    end)

    util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_up,"start")
    util_spineEndCallFunc(self.m_bonusWheel.m_Wheel_maozi_up,"start",function ()
        util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_up,"idle")
    end)

    self.m_guochangWheelBg:setVisible(true)
    self.m_guochangWheelBg:runCsbAction("start",false,function (  )
        self.m_guochangWheelBg:runCsbAction("idle3",false)
        -- 背景idle
        self:changeShowBgIdle(3,false,false)
    end)

    self:removeSoundHandler() -- 移除监听

    self:resetMusicBg(nil,"JackpotOGoldSounds/music_wheelgame_no_trigger_bg.mp3")

    self.m_bonusWheel:setVisible(true)
    self.m_bonusWheel:findChild("Node"):setPosition(startPos)

    local move = cc.MoveTo:create(20/60,cc.p(0,0))
    local seq = cc.Sequence:create(move)
    self.m_bonusWheel:findChild("Node"):runAction(seq)

    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_jackpot_open.mp3")

    self.m_bonusWheel:findChild("Btn_return"):setTouchEnabled(false)

    self.m_bonusWheel:runCsbAction("start",false,function (  )
        
        self.m_bonusWheel:findChild("Btn_return"):setTouchEnabled(true)

        self:showOrCloseViewNode(false)
        self.m_guochangWheelBg:setVisible(false)

        self.m_isClickLogoAndReel = true 
    end)

    self.m_bonusWheel:findChild("Node"):setZOrder(6)
    self.m_bonusWheel:findChild("Node_TotalWin"):setZOrder(5)
end

-- 集满自动开启转轮玩法
function CodeGameScreenJackpotOGoldMachine:JiManOpenWheelView(isJiMan,_func)
    self.m_bonusWheel.m_WheelTotalWin:findChild("m_lb_coins"):setString(" ")
    self.m_guochang:setVisible(true)
    self.m_bonusWheel:updateWheelView(self.m_runSpinResultData.p_selfMakeData.collectcredit,false,_func)

    self.m_bonusWheel:findChild("Btn_return"):setTouchEnabled(false)
    self.m_bonusWheel:findChild("Btn_return"):setBright(false)

    util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_down,"guochang")
    util_spineEndCallFunc(self.m_bonusWheel.m_Wheel_maozi_down,"guochang",function ()
        util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_down,"idle")
    end)

    util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_up,"guochang")
    util_spineEndCallFunc(self.m_bonusWheel.m_Wheel_maozi_up,"guochang",function ()
        util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_up,"idle")
    end)

    self.m_guochang:runCsbAction("guochang",false,function (  )
        self.m_guochang:setVisible(false)
        self:showOrCloseViewNode(false)
    end)

    self:waitWithDelay(function()
        -- 背景idle
        self:changeShowBgIdle(3,false,false)
    end,40/60)

    self.m_bonusWheel:setVisible(true)

    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_jiman_open.mp3")

    self:removeSoundHandler() -- 移除监听

    self:resetMusicBg(nil,"JackpotOGoldSounds/music_wheelgame_bg.mp3")

    self.m_bonusWheel:runCsbAction("guochang",false,function (  )

        self.m_bonusWheel.m_wheelSmallNode[1]:runCsbAction("actionframe",false,function()
            self.m_bonusWheel:beginWheelAction()
        end)
    end)
    if isJiMan then
        self:waitWithDelay(function()
            self.m_bonusWheel:playGuangEffectNode(self.m_runSpinResultData.p_selfMakeData.collectcredit)
        end,45/60)

        self:waitWithDelay(function()
            -- 轮盘刷出 光圈
            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_jiman_guangquan.mp3")

            self.m_bonusWheel:findChild("lizi1"):resetSystem()
            self.m_bonusWheel:findChild("lizi2"):resetSystem()
        end,47/60)
        self:waitWithDelay(function()
            self.m_bonusWheel:findChild("lizi3"):resetSystem()
            self.m_bonusWheel:findChild("lizi4"):resetSystem()
        end,77/60)
        self:waitWithDelay(function()
            self.m_bonusWheel:findChild("lizi5"):resetSystem()
            self.m_bonusWheel:findChild("lizi6"):resetSystem()
        end,107/60)
    end

    self.m_bonusWheel:findChild("Node_TotalWin"):setZOrder(5)
    self:waitWithDelay(function()
        self.m_bonusWheel:findChild("Node"):setZOrder(6)
    end,18/30)
end

-- 开启转轮玩法(收集一次jackpot的时候 自动打开)
function CodeGameScreenJackpotOGoldMachine:openWheelView(_func, _index)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local jackpot_win = self.m_runSpinResultData.p_selfMakeData.jackpot_win
    local spintime = self.m_runSpinResultData.p_selfMakeData.spintime or 0
    self.m_bonusWheel.m_WheelTotalWin:findChild("m_lb_coins"):setString(" ")

    local collectcredit = {}
    self.m_bonusWheel:setVisible(true)
    
    if #selfMakeData.collectcredit ~= #selfMakeData.collectcreditNew then
        local addIndexMan = #jackpot_win - (#selfMakeData.collectcreditNew - #selfMakeData.collectcredit)
        for collectcreditIndex = 1, (#self.m_runSpinResultData.p_selfMakeData.collectcredit - addIndexMan + _index) do
            table.insert(collectcredit,self.m_runSpinResultData.p_selfMakeData.collectcredit[collectcreditIndex])
        end
    else
        for collectcreditIndex = 1, (#self.m_runSpinResultData.p_selfMakeData.collectcredit - #jackpot_win + _index) do
            table.insert(collectcredit,self.m_runSpinResultData.p_selfMakeData.collectcredit[collectcreditIndex])
        end
    end

    self.m_bonusWheel:updateWheelView(collectcredit,true,nil)

    local startPosWord = self:findChild("Node_wheel_logo"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_wheel_logo"):getPosition()))
    local startPos = self.m_bonusWheel:convertToNodeSpace(startPosWord)
    self.m_bonusWheel:findChild("Node"):setPosition(startPos)

    local move = cc.MoveTo:create(20/60,cc.p(0,0))
    local seq = cc.Sequence:create(move)
    self.m_bonusWheel:findChild("Node"):runAction(seq)

    util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_down,"start")
    util_spineEndCallFunc(self.m_bonusWheel.m_Wheel_maozi_down,"start",function ()
        util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_down,"idle")
    end)

    util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_up,"start")
    util_spineEndCallFunc(self.m_bonusWheel.m_Wheel_maozi_up,"start",function ()
        util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_up,"idle")
    end)

    self.m_bonusWheel:findChild("Btn_return"):setTouchEnabled(false)
    self.m_bonusWheel:findChild("Btn_return"):setBright(false)

    self.m_guochangWheelBg:setVisible(true)
    self.m_guochangWheelBg:runCsbAction("start",false,function (  )
        self.m_guochangWheelBg:runCsbAction("idle3",false)
        -- 背景idle
        self:changeShowBgIdle(3,false,false)
    end)

    self.m_bonusWheel:findChild("Node"):setZOrder(6)
    self.m_bonusWheel:findChild("Node_TotalWin"):setZOrder(5)

    -- 收集jackpot 自动打开转轮
    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_jackpot_open.mp3")

    self.m_bonusWheel:runCsbAction("start",false,function (  )
        self:showOrCloseViewNode(false)
        self.m_guochangWheelBg:setVisible(false)

        self.m_bonusWheel:updateNewJackpotWheelView(#collectcredit, collectcredit[#collectcredit],function()
            self:waitWithDelay(function()

                util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_down,"over")
                util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_up,"over")
                self:waitWithDelay(function()
                    self:showOrCloseViewNode(true)

                    self.m_guochangWheelBg:setVisible(true)
                    self.m_guochangWheelBg:runCsbAction("idle3",false)

                    self:waitWithDelay(function()
                        local startPosWord = self:findChild("Node_wheel_logo"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_wheel_logo"):getPosition()))
                        local startPos = self.m_bonusWheel:convertToNodeSpace(startPosWord)
    
                        local move = cc.MoveTo:create(20/60,startPos)
                        local seq = cc.Sequence:create(move)
                        self.m_bonusWheel:findChild("Node"):runAction(seq)

                        self.m_guochangWheelBg:runCsbAction("over",false,function (  )
                            self.m_guochangWheelBg:setVisible(false)
                        end)

                        -- 背景idle
                        if spintime == 20 then
                            self:changeShowBgIdle(2,false,true)
                        else
                            self:changeShowBgIdle(1,false,true)
                        end

                    end,15/60)
                    
                    -- 收集jackpot 自动打开转轮在关闭
                    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_jackpot_close.mp3")
                    self.m_bonusWheel:runCsbAction("over",false,function (  )
                        self.m_bonusWheel:findChild("Node"):setZOrder(3)
                        self.m_bonusWheel:findChild("Node_TotalWin"):setZOrder(2)
    
                        self.m_bonusWheel:runCsbAction("idle",false)
    
                        self.m_bonusWheel:findChild("Btn_return"):setTouchEnabled(true)
                        self.m_bonusWheel:findChild("Btn_return"):setBright(true)
                        
                        self.m_bonusWheel:setVisible(false)
                        if _func then
                            _func()
                        end
                    end)
                end,20/30)
            end,0.5)
        end)

        self.m_bonusWheel:runCsbAction("idle2",false,function (  )
        end)
    end)
end

-- 关闭转轮玩法
function CodeGameScreenJackpotOGoldMachine:clickCloseWheelView(_func)
    self.m_isWheelBackInterval = true

    self.m_bottomUI:updateBetEnable(true)
    local spintime = self.m_curSpinNum

    self:showOrCloseViewNode(true)

    self.m_guochangWheelBg:setVisible(true)
    self.m_guochangWheelBg:runCsbAction("idle3",false)

    util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_down,"over")
    util_spinePlay(self.m_bonusWheel.m_Wheel_maozi_up,"over")

    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_jackpot_close.mp3")

    self:waitWithDelay(function()
        self:waitWithDelay(function()
            local startPosWord = self:findChild("Node_wheel_logo"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_wheel_logo"):getPosition()))
            local startPos = self.m_bonusWheel:convertToNodeSpace(startPosWord)
    
            local move = cc.MoveTo:create(20/60,startPos)
            local seq = cc.Sequence:create(move)
            self.m_bonusWheel:findChild("Node"):runAction(seq)

            self.m_guochangWheelBg:runCsbAction("over",false,function (  )
                self.m_guochangWheelBg:setVisible(false)
            end)
            if spintime == 20 then
                self:changeShowBgIdle(2,false,true)
            else
                self:changeShowBgIdle(1,false,true)
            end

        end,15/60)

        self.m_bonusWheel:runCsbAction("over",false,function (  )
            
            self.m_bonusWheel:setVisible(false)
            self.m_bonusWheel:runCsbAction("idle",false)
            self.m_isWheelReturnClick = false

            self.m_bonusWheel:findChild("Node"):setZOrder(3)
            self.m_bonusWheel:findChild("Node_TotalWin"):setZOrder(2)

            self.m_bonusWheel:findChild("Btn_return"):setTouchEnabled(true)
            self.m_bonusWheel:findChild("Btn_return"):setBright(true)

            self.m_isClick = true

            self.m_isWheelBackInterval = false 
    
            if spintime == 20 then
                self:resetMusicBg(nil,"JackpotOGoldSounds/music_basegame20_bg.mp3")
            else
                self:resetMusicBg()
            end
            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)

            if _func then
                _func()
            end
        end)
    end,10/30)
end

--切换转轮玩法 显示的节点处理
function CodeGameScreenJackpotOGoldMachine:showOrCloseViewNode(isShow)
    local children = self:findChild("root"):getChildren()
    for k, _node in pairs(children) do
        if _node:getName() ~= "bg" and _node:getName() ~= "Node_wheel" then
            _node:setVisible(isShow)
        end
    end
end

function CodeGameScreenJackpotOGoldMachine:clickFunc(_sender)
    local name = _sender:getName()

    self:getMinBet()

    if not self.m_isClick then
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return
    end

    if name == "Panel_1" then -- 打开转轮
        self.m_isClick = false
        -- self.m_WheelLogo:findChild("Particle_2"):resetSystem()
        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_Logo_click.mp3")

        -- self.m_WheelLogo:runCsbAction("actionframe2",false,function()
            self.m_WheelLogo:runCsbAction("idle",true)
            
        -- end)
        --问题：autoSpin获得jackpot后断掉autoSpin，点击wheel,spin按钮无法点击
        --强制更新spin按钮
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        --由于强制更新spin会使切换bet按钮开启，所以先更新按钮，后关闭bet按钮
        self:clickOpenWheelView()
    end

    if name == "btn_i" then
        if self.m_shoujiTips:isVisible() then
            self:showTipsOverView()
        else
            if self.getGameSpinStage() == IDLE then
                self:showTipsOpenView()
            end
        end
    end

    if name == "click_pot" then
        if self.m_shoujiTipsPot:isVisible() then
            self:showTipsPotOverView()
        else
            if self.getGameSpinStage() == IDLE then
                self:showTipsPotOpenView()
            end
        end
    end

end

function CodeGameScreenJackpotOGoldMachine:playCustomSpecialSymbolDownAct( slotNode )

    if slotNode and  slotNode.p_symbolType == self.SYMBOL_BONUS then
        local symbolNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)
        self:playScatterBonusSound(slotNode)
        symbolNode:runAnim("buling")
        -- self:playBulingSymbolSounds( slotNode.p_cloumnIndex,"JackpotOfBeerSounds/music_JackpotOfBeer_fixSymoblDown.mp3" )
    end

end

function CodeGameScreenJackpotOGoldMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    return world_pos
end

-- 初始显示轮盘数据
function CodeGameScreenJackpotOGoldMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do

            local symbolType = nil
            if self.m_runSpinResultData.p_reels and #self.m_runSpinResultData.p_reels > 0 then
                symbolType = self:getResultReelSysmbl(rowIndex,colIndex)
            else
                -- symbolType = self:getRandomReelType(colIndex, reelDatas)
                symbolType = self:getInitReelSysmbl(rowIndex,colIndex)
            end
            
            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            -- 切换皮肤
            if self.m_runSpinResultData.p_reels and #self.m_runSpinResultData.p_reels > 0 and node.p_symbolType == self.SYMBOL_BONUS then
                local newRowIndex = rowIndex
                if rowIndex == 1 then
                    newRowIndex = 3
                elseif rowIndex == 3 then
                    newRowIndex = 1
                end
                if self.m_runSpinResultData.p_storedIcons then
                    for i,vData in ipairs(self.m_runSpinResultData.p_storedIcons) do
                        if vData[1] == ((newRowIndex-1)*5+colIndex-1) then
                            if vData[2] == 1 then
                                if self.m_runSpinResultData.p_selfMakeData.spintime == 20 then
                                    node:runAnim("idle1",false)
                                    if node.m_goldNode == nil then
                                        node.m_goldNode = util_createAnimation("Socre_JackpotOGold_Bonus_Pot_qianshu.csb")
                                        node.m_goldNode:findChild("m_lb_coins_0"):setString(util_formatCoins(vData[3]*self.m_runSpinResultData.p_bet*self.m_runSpinResultData.p_payLineCount,3))
                                        node.m_goldNode:setPosition(cc.p(0, 0))
                                        node:addChild(node.m_goldNode, 2)
                                        node.m_goldNode:runCsbAction("idle",false)
                                    end
                                else
                                    node:runAnim("idleframe",false)
                                    if node.m_goldNode == nil then
                                        node.m_goldNode = util_createAnimation("Socre_JackpotOGold_Bonus_coin.csb")
                                        node.m_goldNode:findChild("m_lb_coins"):setString(util_formatCoins(vData[3]*self.m_runSpinResultData.p_bet*self.m_runSpinResultData.p_payLineCount,3))
                                        node.m_goldNode:setPosition(cc.p(0, 0))
                                        node:addChild(node.m_goldNode, 2)
                                        for j=1, 24 do
                                            node.m_goldNode:findChild("jackpot_"..j):setVisible(false)
                                        end
                                        node.m_goldNode:runCsbAction("idle",false)
                                        node.m_goldNode:setScale(2)
                                    end
                                end
                            else
                                self:bonusChangeShow("idle",node, self:getBonusSkin(vData[3]),nil)
                            end
                        end
                    end
                end
            end
            if not self.m_runSpinResultData.p_reels or #self.m_runSpinResultData.p_reels == 0 then
                for i,v in ipairs(self.m_initReelSysmblBonus) do
                    local newRowIndex = rowIndex
                    if rowIndex == 1 then
                        newRowIndex = 3
                    elseif rowIndex == 3 then
                        newRowIndex = 1
                    end
                    if v[1] == ((newRowIndex-1)*5+colIndex-1) and node.p_symbolType == self.SYMBOL_BONUS then
                        if v[2] == 0 then
                            self:bonusChangeShow("idle",node, self:getBonusSkin(v[3]),nil)
                        end
                    end
                end 
                
            end

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            --            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function CodeGameScreenJackpotOGoldMachine:getResultReelSysmbl(rowIndex,colIndex)
    if rowIndex == 1 then
        return self.m_runSpinResultData.p_reels[3][colIndex]
    elseif rowIndex == 3 then
        return self.m_runSpinResultData.p_reels[1][colIndex]
    else
        return self.m_runSpinResultData.p_reels[rowIndex][colIndex]
    end
end

function CodeGameScreenJackpotOGoldMachine:getInitReelSysmbl(rowIndex,colIndex)
    local reel = {
        {4, 4, 94, 4, 4},
        {4, 94, 2, 94, 4},
        {94, 2, 2, 2, 94}
    }
    local symbol = reel[rowIndex][colIndex]
    return symbol
end

-- 差一个字母 jackpot 有特殊效果
function CodeGameScreenJackpotOGoldMachine:setJackpotEffect(_selfMakeData)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    if _selfMakeData then
        selfMakeData = _selfMakeData
    end
    local jackpotIndex = {}
    for index = 1, 5 do
        jackpotIndex[index] = {}
    end

    local function getStartAndEndId(index)
        if index == 1 then
            return 1,5
        elseif index == 2 then
            return 6,10
        elseif index == 3 then
            return 11,15
        elseif index == 4 then
            return 16,20
        elseif index == 5 then
            return 21,24
        end
    end

    if selfMakeData and selfMakeData.getjackpot then
        local function createJackpotEffect(iId, vIndex)
            local startIndex, endIndex = getStartAndEndId(iId)
            for jackpotIndex = startIndex, endIndex do
                local isHave = false
                for _, vData in ipairs(vIndex) do
                    if jackpotIndex == vData then
                        isHave = true
                    end
                end
                if not isHave then
                    if self.m_jackpotEffectNode[iId] and jackpotIndex ~= self.m_jackpotEffectNode[iId][1].m_jackpotIndex then
                        for _, _node in ipairs(self.m_jackpotEffectNode[iId]) do
                            _node:removeFromParent()
                        end
                        
                        self.m_jackpotEffectNode[iId] = nil
                    end

                    if self.m_jackpotEffectNode[iId] == nil then
                        self.m_jackpotEffectNode[iId] = {}
                        local jackpotShoujiNode =  util_createAnimation("JackpotOGold_Jackpot_shouji.csb")
                        self.m_role_node:addChild(jackpotShoujiNode,100) 
                        local endPosWord = self:getJackPotNode(jackpotIndex):getParent():convertToWorldSpace(cc.p(self:getJackPotNode(jackpotIndex):getPosition()))
                        local endPos = self.m_role_node:convertToNodeSpace(endPosWord)
                        jackpotShoujiNode.m_jackpotIndex = jackpotIndex
                        table.insert(self.m_jackpotEffectNode[iId], jackpotShoujiNode)
                        jackpotShoujiNode:setPosition(endPos)
                        jackpotShoujiNode:runCsbAction("shouji_"..iId,true)
                    end
                end
            end
        end
        for _, vId in ipairs(selfMakeData.getjackpot) do
            if vId >= 1 and vId <= 5 then
                table.insert(jackpotIndex[1], vId)
            elseif vId >= 6 and vId <= 10 then
                table.insert(jackpotIndex[2], vId)
            elseif vId >= 11 and vId <= 15 then
                table.insert(jackpotIndex[3], vId)
            elseif vId >= 16 and vId <= 20 then
                table.insert(jackpotIndex[4], vId)
            elseif vId >= 21 and vId <= 24 then
                table.insert(jackpotIndex[5], vId)
            end
        end

        for _index, _vIndex in ipairs(jackpotIndex) do
            if _index == 5 then
                if #_vIndex == 3 then
                    createJackpotEffect(_index, _vIndex)
                end
            else
                if #_vIndex == 4 then
                    while true
                    do
                        if _index == 1 and self:checkIsLock(2) then
                            break
                        elseif _index == 2 and self:checkIsLock(1) then
                            break
                        end
                        createJackpotEffect(_index, _vIndex)
                        break
                    end
                end
            end
        end
    end
end

-- 集齐 jackpot 删除特殊效果
function CodeGameScreenJackpotOGoldMachine:deleteJackpotEffect( )
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData
    local jackpotIndex = {}
    for index = 1, 5 do
        jackpotIndex[index] = {}
    end

    if selfMakeData and selfMakeData.getjackpot then
        local function deleteJackpotEffect(iId)
            if self.m_jackpotEffectNode[iId] and #self.m_jackpotEffectNode[iId] > 0 then
                for _, vNode in ipairs(self.m_jackpotEffectNode[iId]) do
                    vNode:setVisible(false)
                    vNode:removeFromParent()
                    self.m_jackpotEffectNode[iId] = nil
                end
            end
        end

        for _, vId in ipairs(selfMakeData.getjackpot) do
            if vId >= 1 and vId <= 5 then
                table.insert(jackpotIndex[1], vId)
            elseif vId >= 6 and vId <= 10 then
                table.insert(jackpotIndex[2], vId)
            elseif vId >= 11 and vId <= 15 then
                table.insert(jackpotIndex[3], vId)
            elseif vId >= 16 and vId <= 20 then
                table.insert(jackpotIndex[4], vId)
            elseif vId >= 21 and vId <= 24 then
                table.insert(jackpotIndex[5], vId)
            end
        end

        for i,vIndex in ipairs(jackpotIndex) do
            if #vIndex == 0 or #vIndex == 5 then
                deleteJackpotEffect(i)
            end
        end
    end
end

-- 触发转轮 结束时调用
function CodeGameScreenJackpotOGoldMachine:showWheelOverView(_func,winCoin)

    -- gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_showFreeSpinOver.mp3")

    local strCoins=util_formatCoins(winCoin,30)
    local view = self:showWheelOver( strCoins,function()

        self:clickCloseWheelView(function()
            -- 检查是否有大赢 没有的话 判断添加
            if not self:checkBigWin() then
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, self.COLLECT_WHEEL_EFFECT)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
                if _func then
                    _func()
                end
            else
                if _func then
                    _func()
                end
            end
        end)
        for wheelIndex = 1, 18 do
            self.m_WheelLogoCollect[wheelIndex]:setVisible(false)
        end
        
        self:waitWithDelay(function()
            self.m_bonusWheel:resetWheelView()
        end,1)

        self.m_WheelLogo:runCsbAction("idle",true)
        
    end)
    if display.height < 1370 then
        view:findChild("root"):setScale(self.m_machineRootScale)
    end
    local node=view:findChild("m_lb_num")
    view:updateLabelSize({label=node,sx=1,sy=1},671)
    view.m_btnTouchSound = "JackpotOGoldSounds/sound_JackpotOGold_wheel_tanban_close.mp3"
end


function CodeGameScreenJackpotOGoldMachine:showWheelOver(coins, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = util_formatCoins(coins, 30)
    return self:showDialog("BonusOver", ownerlist, func)

end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenJackpotOGoldMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i = 1, #self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert(self.m_gameEffects, i + 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, i + 2, effectData)
                break
            end
        end
        if isAddEffect == false then
            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert(self.m_gameEffects, i + 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, i + 2, effectData)
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert(self.m_gameEffects, 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, 2, effectData)
            end
        end
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
end

-- 检查大赢
function CodeGameScreenJackpotOGoldMachine:checkBigWin( )
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        return true
    end
    return false
end

--快停
function CodeGameScreenJackpotOGoldMachine:operaQuicklyStopReel()
    if self.m_quickStopReelIndex then
        return
    end
    --有停止并且未回弹的停止快停
    self.m_quickStopReelIndex = nil
    for i=1,#self.m_reels do
        if self.m_reels[i]:isReelDone() then
            self.m_quickStopReelIndex = i
        end
    end
    if not self.m_quickStopReelIndex then
        self:newQuickStopReel(1)
    end
    self.m_isQuickStop = true
end

--轮盘滚动显示遮罩
function CodeGameScreenJackpotOGoldMachine:beginReelShowMask()

    self.slotParentNode_1:setVisible(true)
    util_nodeFadeIn(self.slotParentNode_1,0.3,0,200,nil,nil)
end

--轮盘停止隐藏遮罩
function CodeGameScreenJackpotOGoldMachine:reelStopHideMask(actionTime, col)
    local act = cc.FadeOut:create(0.3)
    self.slotParentNode_1:runAction(act)

    self:waitWithDelay(function()
        self.slotParentNode_1:setVisible(false)
    end,0.3)
end

--设置bonus 层级
function CodeGameScreenJackpotOGoldMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenJackpotOGoldMachine.super.getBounsScatterDataZorder(self,symbolType)
    if symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    end
    return order
end

--打开tips
function CodeGameScreenJackpotOGoldMachine:showTipsOpenView( )
    self.m_shoujiTips:setVisible(true)
    self.m_shoujiTips:runCsbAction("show",false,function()
        self.m_shoujiTips:runCsbAction("idle",true)
        self.m_scheduleId = schedule(self, function(  )
            self:showTipsOverView()
        end, 4)
    end)
    
end

--关闭tips
function CodeGameScreenJackpotOGoldMachine:showTipsOverView( )
    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    self.m_shoujiTips:runCsbAction("over",false,function()
        self.m_shoujiTips:setVisible(false)
    end)
end

--打开tips
function CodeGameScreenJackpotOGoldMachine:showTipsPotOpenView( )
    self.m_shoujiTipsPot:setVisible(true)
    self.m_shoujiTipsPot:runCsbAction("show",false,function()
        self.m_shoujiTipsPot:runCsbAction("idle",true)
        self.m_scheduleIdPot = schedule(self, function(  )
            self:showTipsPotOverView()
        end, 4)
    end)
    
end

--关闭tips
function CodeGameScreenJackpotOGoldMachine:showTipsPotOverView( )
    if self.m_scheduleIdPot then
        self:stopAction(self.m_scheduleIdPot)
        self.m_scheduleIdPot = nil
    end

    self.m_shoujiTipsPot:runCsbAction("over",false,function()
        self.m_shoujiTipsPot:setVisible(false)
    end)
end

-- 转轮玩完之后 更新一下底部赢钱
function CodeGameScreenJackpotOGoldMachine:updateBottomCoin(wheelCoin)
    globalData.slotRunData.lastWinCoin = 0
    self.m_isPlayWinSound = false
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_winCoinCurSpin + wheelCoin,false,true,self.m_winCoinCurSpin})
    self.m_winCoinCurSpin = self.m_winCoinCurSpin + wheelCoin
end

function CodeGameScreenJackpotOGoldMachine:scaleMainLayer()
    CodeGameScreenJackpotOGoldMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if  ratio >= 768/1024 then
        local mainScale = 0.68
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("root"):setPositionY(self:findChild("root"):getPositionY() + 10)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.79 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.88 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio > 768/1370 then
        local mainScale = 0.95 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio <= 768/1370 then
    end
end

function CodeGameScreenJackpotOGoldMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenJackpotOGoldMachine.super.playEffectNotifyNextSpinCall(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

-- 显示paytableview 界面
function CodeGameScreenJackpotOGoldMachine:showPaytableView()
    local csbFileName = "PayTableLayer" .. self.m_moduleName .. ".csb"

    local sCsbpath = self.m_moduleName .. "/" .. csbFileName
    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(sCsbpath)

    if not CCFileUtils:sharedFileUtils():isFileExist(fileNamePath) then
        release_print("没有 paytable csb  = " .. fileNamePath)
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local view = gLobalViewManager:showPauseUI("base/BasePayTableView", sCsbpath)
    view:findChild("root"):setScale(self.m_machineRootScale)
    if view then
        view:setOverFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                gLobalViewManager:viewResume(
                    function()
                        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.noobTaskStart1)
                    end
                )
            end
        )
    end
end

function CodeGameScreenJackpotOGoldMachine:getMinBet( )
    local minBetSuper = 0
    local minBetGrand = 0

    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 2
        return 0, 0
    end
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBetSuper = self.m_specialBets[1].p_totalBetValue
    end
    if self.m_specialBets and self.m_specialBets[2] then
        minBetGrand = self.m_specialBets[2].p_totalBetValue
    end

    return minBetSuper, minBetGrand
end

function CodeGameScreenJackpotOGoldMachine:updateLock(_isInit)
    local isInit = not not _isInit
    local betCoin = globalData.slotRunData:getCurTotalBet()
    local minBetSuper, minBetGrand = self:getMinBet()
    local isUnlockGrand = false
    local lockNum = 2
    if betCoin >= minBetGrand then
        isUnlockGrand = true
        self.m_JackpotGrandView:unLock(isInit)
    else
        lockNum = lockNum - 1
        self.m_JackpotGrandView:lock(isInit)
    end
    if betCoin >= minBetSuper then
        self.m_JackpotSuperView:unLock(isInit, not isUnlockGrand)
    else
        lockNum = lockNum - 1
        self.m_JackpotSuperView:lock(isInit)
    end

    
    self.m_iBetLevel = lockNum
end

function CodeGameScreenJackpotOGoldMachine:checkIsLock(jackPotType)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    local minBetSuper, minBetGrand = self:getMinBet()
    if betCoin < minBetSuper and jackPotType == 1 then
        return true
    end

    if betCoin < minBetGrand and jackPotType == 2 then
        return true
    end

    return false
end

function CodeGameScreenJackpotOGoldMachine:getBottomUINode()
    return "CodeJackpotOGoldSrc.JackpotOGoldBottomNode"
end

--[[
    检查是否可以解锁jackpot
]]
function CodeGameScreenJackpotOGoldMachine:checkIsUnLockJackpot()
    if self.m_bProduceSlots_InFreeSpin == true or
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and
    self:getGameSpinStage() ~= IDLE ) or
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return false
    end
    return true
end

return CodeGameScreenJackpotOGoldMachine






