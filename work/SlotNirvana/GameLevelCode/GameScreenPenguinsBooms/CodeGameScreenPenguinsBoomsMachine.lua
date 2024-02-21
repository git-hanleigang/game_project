---
-- island li
-- 2019年1月26日
-- CodeGameScreenPenguinsBoomsMachine.lua
-- 
-- 玩法：
-- 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "PenguinsBoomsPublicConfig"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local CollectData = require "data.slotsdata.CollectData"
local CodeGameScreenPenguinsBoomsMachine = class("CodeGameScreenPenguinsBoomsMachine", BaseReelMachine)

CodeGameScreenPenguinsBoomsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MINI  = 101
CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MINOR = 102
CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MAJOR = 103
CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MEGA  = 104
CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_GRAND = 105
CodeGameScreenPenguinsBoomsMachine.SYMBOL_Blank = 200  --空信号

CodeGameScreenPenguinsBoomsMachine.BOMB_REEL_EFFECT             = GameEffect.EFFECT_SELF_EFFECT - 10    --炸弹玩法
CodeGameScreenPenguinsBoomsMachine.TRIGGER_BOMB_IN_FREE_EFFECT  = GameEffect.EFFECT_SELF_EFFECT - 20    --free触发必中炸弹玩法(飞bonus动画)
CodeGameScreenPenguinsBoomsMachine.COLLECT_BOMB_EFFECT          = GameEffect.EFFECT_SELF_EFFECT - 30    --收集炸弹
CodeGameScreenPenguinsBoomsMachine.HIT_JACKPOT_EFFECT           = GameEffect.EFFECT_LINE_FRAME + 1      --中jackpot
CodeGameScreenPenguinsBoomsMachine.EFFECT_Bomb_JackpotTrigger   = GameEffect.EFFECT_LINE_FRAME + 5      --炸弹玩法的jackpot触发(放在连线后面)

CodeGameScreenPenguinsBoomsMachine.PenguinsBoomsReSpinEffectOrder = GameEffect.EFFECT_FREE_SPIN - 11

--服务器的炸弹触发类型
CodeGameScreenPenguinsBoomsMachine.BombAwardType = {
    --奖池
    Jackpot = "jackpot",
}

local MAX_ROW_COUNT     =       7
local MIN_ROW_COUNT     =       5
local CHANGE_SPEED      =       700 --升行速度

--特殊图标 和 收集栏 在clipParent上的层级
CodeGameScreenPenguinsBoomsMachine.PenguinsBoomsReelNodeOrder = {
    NormalScatter           = REEL_SYMBOL_ORDER.REEL_ORDER_2_2,             --普通状态-sc
    NormalJackpot           = REEL_SYMBOL_ORDER.REEL_ORDER_2_2,             --普通状态-jackpot
    BaseReelRunCollectBar   = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10,        --棋盘滚动时-收集栏
    BaseReelRunBonus        = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 15,        --棋盘滚动时-bonus的挂点层级
    NormalScatterTop        = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 20,        --普通状态-位置不处于第2行-sc
    NormalJackpotTop        = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 20,        --普通状态-位置不处于第2行-jackpot
    ExpectSymbol            = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 70,        --期待动画
    BaseCollectBar          = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100,       --base和free模式-收集栏
    NormalBonus             = REEL_SYMBOL_ORDER.REEL_ORDER_MASK,            --普通状态-bonus
    ChangeWild              = REEL_SYMBOL_ORDER.REEL_ORDER_MASK + 100,      --bonus变出的wild图标
    WaitTriggerScatter      = REEL_SYMBOL_ORDER.REEL_ORDER_MASK + 150,      --待触发-sc
    WaitTriggerJackpot      = REEL_SYMBOL_ORDER.REEL_ORDER_MASK + 200,      --待触发-jackpot
    WaitTriggerBonus        = REEL_SYMBOL_ORDER.REEL_ORDER_MASK + 250,      --待触发-bonus
    RellTriggerJackpot      = REEL_SYMBOL_ORDER.REEL_ORDER_MASK + 300,      --滚动出来的jackpot触发了奖池
    ReSpinCollectBar        = REEL_SYMBOL_ORDER.REEL_ORDER_MASK + 400,      --reSpin模式-收集栏
    TriggerScatter          = REEL_SYMBOL_ORDER.REEL_ORDER_3,               --触发状态-sc
    TriggerJackpot          = REEL_SYMBOL_ORDER.REEL_ORDER_3,               --触发状态-sc
    TriggerBonus            = REEL_SYMBOL_ORDER.REEL_ORDER_3,               --触发状态-bonus
}

CodeGameScreenPenguinsBoomsMachine.SymbolTypeToJackpotIndex = {
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_GRAND] = 1,
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MEGA]  = 2,
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MAJOR] = 3,
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MINOR] = 4,
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MINI]  = 5,
}
CodeGameScreenPenguinsBoomsMachine.JackpotTypeToJackpotIndex = {
    grand = 1,
    mega  = 2,
    major = 3,
    minor = 4,
    mini  = 5,
}
CodeGameScreenPenguinsBoomsMachine.SymbolTypeToJackpotType = {
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_GRAND] = "grand",
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MEGA]  = "mega",
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MAJOR] = "major",
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MINOR] = "minor",
    [CodeGameScreenPenguinsBoomsMachine.SYMBOL_BONUS_MINI]  = "mini",
}


-- 构造函数
function CodeGameScreenPenguinsBoomsMachine:ctor()
    CodeGameScreenPenguinsBoomsMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isTriggerUpReels = false     --是否触发升行玩法
    self.m_isBombReelOver = false

    self.m_isTriggerFree = false

    --grand锁定
    self.m_iBetLevel    = 0
    -- 预告中奖标记
    self.m_winningNoticeTime   = 0
	self.m_isPlayWinningNotice = false
    -- 本次spin首个快滚的列
    self.m_firstReelRunCol = 0
    self.m_reelRunSymbol   = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    -- 炸弹玩法触发时棋盘上播待触发图标的坐标
    self.m_specialSymbolList = {}
    -- wild边框列表
    self.m_wildFrameList = {}
    -- bonus触发free标记
    self.m_bBonusTriggerFree = false

    -- reSpin流程延时停轮
    self.m_reSpinDelayReelDownTime = 0


    --init
    self:initGame()
end

function CodeGameScreenPenguinsBoomsMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {1,2,3,4,5}
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPenguinsBoomsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "PenguinsBooms"  
end

function CodeGameScreenPenguinsBoomsMachine:getBottomUINode()
    return "CodePenguinsBoomsSrc.PenguinsBoomsBottomNode"
end

function CodeGameScreenPenguinsBoomsMachine:getReelNode()
    return "CodePenguinsBoomsSrc.PenguinsBoomsReelNode"
end

function CodeGameScreenPenguinsBoomsMachine:getBigReelNode()
    return "CodePenguinsBoomsSrc.PenguinsBoomsReelBigNode"
end

function CodeGameScreenPenguinsBoomsMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_freebar")
    self.m_baseFreeSpinBar = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)

    self:hideFreeSpinBar()
end

function CodeGameScreenPenguinsBoomsMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenPenguinsBoomsMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end


function CodeGameScreenPenguinsBoomsMachine:initUI()
    -- util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_changeSizeNode = cc.Node:create()
    self:addChild(self.m_changeSizeNode)

    --棋盘背景 渐变切换
	self.m_gameBgSpine_down = util_spineCreate("GameScreenPenguinsBoomsBg", true, true)
	self.m_gameBgSpine_up = util_spineCreate("GameScreenPenguinsBoomsBg", true, true)
	self.m_gameBg:findChild("Node_spine_down"):addChild(self.m_gameBgSpine_down)
	self.m_gameBg:findChild("Node_spine_up"):addChild(self.m_gameBgSpine_up)
	util_setCascadeOpacityEnabledRescursion(self.m_gameBgSpine_down, true)
	util_setCascadeOpacityEnabledRescursion(self.m_gameBgSpine_up, true)

    --jackpot
    self.m_jackpotBar = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsJackPotBarView",{machine = self})
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)

    --角色
    self.m_roleSpine = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsRoleSpine",{
        spineName = "PenguinsBooms_base_juese",
    })
    self:findChild("Node_roleSpine"):addChild(self.m_roleSpine)
    self.m_roleSpine:playIdleAnim(0, 1)
    self.m_freeRoleSpine = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsRoleSpine",{
        spineName = "PenguinsBooms_free_juese",
    })
    self:findChild("Node_roleSpine"):addChild(self.m_freeRoleSpine)
    self.m_freeRoleSpine:setVisible(false)

    --点击效果层
    self.m_penguinsBoomsclickEffect = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsClickEffect",{
        machine = self
    })
    self:findChild("Node_clickEffect"):addChild(self.m_penguinsBoomsclickEffect)

    --收集条
    local collectBarOrder = self.PenguinsBoomsReelNodeOrder.BaseCollectBar
    self.m_collectBar = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsCollectBar",{machine = self})
    self.m_clipParent:addChild(self.m_collectBar, collectBarOrder, SYMBOL_NODE_TAG * 100)
    self.m_collectBar:setPosition(cc.p(util_convertToNodeSpace(self:findChild("Node_collectbar"),self.m_clipParent)))

    --棋盘上方文案
    self.m_ruleTips = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsRuleTips",{machine = self})
    self:findChild("Node_wenan"):addChild(self.m_ruleTips)

    --reSpin提示和压黑
    self.m_reSpinTip = util_createAnimation("PenguinsBooms_respin_start.csb")
    self:findChild("Node_respin_start"):addChild(self.m_reSpinTip)
    self.m_reSpinTip:setVisible(false)

    --期待动画
    local expectParent = self:findChild("Node_expect")
    self.m_expectAnim = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsFree.PenguinsBoomsSymbolExpectAnim",{
        machine    = self,
    })
    expectParent:addChild(self.m_expectAnim)
    expectParent:setLocalZOrder(self.PenguinsBoomsReelNodeOrder.ExpectSymbol)

    --跳过功能(点击棋盘和spin按钮)
    self.m_skipEffectNode = self:findChild("Node_skipEffect")
    self.m_skipPanelCsb = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsSkip",{
        machine    = self,
        skipEffectNode = self.m_skipEffectNode,
    })
    self:findChild("Node_skip"):addChild(self.m_skipPanelCsb)
    self.m_skipPanelCsb:setVisible(false)

        
    --特效层
    self.m_effectNode = self:findChild("Node_effect")

    -- FreeSpinbar
    self:initFreeSpinBar() 

    --快滚层
    local reelRunEffectOrder = self.PenguinsBoomsReelNodeOrder.BaseReelRunCollectBar - 1
    local reelRunParent = self:findChild("Node_reelRunEffect")
    reelRunParent:setLocalZOrder(reelRunEffectOrder)
    reelRunParent:setPosition(util_convertToNodeSpace(self.m_slotEffectLayer, reelRunParent:getParent()))

    --预告
    local yugaoParent = self:findChild("Node_yugao")
    self.m_yugaoSpine = util_spineCreate("PenguinsBooms_base_yugao",true,true)
    yugaoParent:addChild(self.m_yugaoSpine, 20)
    self.m_yugaoSpine:setVisible(false)
    self.m_yugaoSpine:setPosition(util_convertToNodeSpace(self:findChild("Node_roleSpine"), yugaoParent))
    self.m_yugaoCsb = util_createAnimation("PenguinsBooms_yugao.csb")
    yugaoParent:addChild(self.m_yugaoCsb, 10)
    self.m_yugaoCsb:setVisible(false)

    --大赢效果
	self.m_bigWinSpine = util_spineCreate("PenguinsBooms_bigwin", true, true)
	self:findChild("Node_bigWin"):addChild(self.m_bigWinSpine)
	self.m_bigWinSpine:setVisible(false)
    self.m_bigWinCsb = util_createAnimation("PenguinsBooms_bigwinlizi.csb")
	self:findChild("Node_bigWin"):addChild(self.m_bigWinCsb)
	self.m_bigWinCsb:setVisible(false)


    self:changeReelBg("base", false)
    self.m_collectBar:playBarIdleAnim()
    self:upDateLineNodeShow(false)
end


function CodeGameScreenPenguinsBoomsMachine:enterGamePlayMusic()
    self:delayCallBack(0.4, function()
        self:playEnterGameSound(PublicConfig.sound_PenguinsBooms_enterLevel)
    end)
end

function CodeGameScreenPenguinsBoomsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    CodeGameScreenPenguinsBoomsMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:updateBetLevel(true)
    self:addObservers()
    --调整大信号的滚动层级
    self.m_bigReelNodeLayer:setLocalZOrder(self.PenguinsBoomsReelNodeOrder.BaseReelRunBonus)

    --隐藏最后一行小块
    self:hideLastRowSymbol()
    
    --刷新收集条
    if self.m_bProduceSlots_InFreeSpin then
        self:updateBetData()
    end
    self:refreshCollectBar()

    --显示bet选择界面
    if not globalData.slotRunData.isDeluexeClub then
        if #self.m_gameEffects == 0 and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            self:showChooseBetView()
        end
    else
        self.m_ruleTips:setTipBtnVisible(false)
    end
end

function CodeGameScreenPenguinsBoomsMachine:checkInitSpinWithEnterLevel()
    local isTriggerEffect, isPlayGameEffect = CodeGameScreenPenguinsBoomsMachine.super.checkInitSpinWithEnterLevel(self)

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        --respin要在free之前触发
        if effectData.p_effectType == GameEffect.EFFECT_RESPIN then 
            effectData.p_effectOrder = self.PenguinsBoomsReSpinEffectOrder
            break
        end
    end

    return isTriggerEffect, isPlayGameEffect
end

function CodeGameScreenPenguinsBoomsMachine:updateBetLevel(_bOnEnter)
    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = self:getPenguinsBoomsBetLevelByValue(betCoin)
    local curLockStatus = self.m_iBetLevel <= 1
    local newLockStatus = level <= 1
    self.m_iBetLevel = level
    --锁定状态发生变更刷新UI
    if _bOnEnter or curLockStatus ~= newLockStatus then
        self:lockStatusChangeUpDateUi(newLockStatus)
    end
end
function CodeGameScreenPenguinsBoomsMachine:getPenguinsBoomsBetLevelByValue(_betValue)
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets or {}
    local betLevel = 0
    for index = #specialBets,1,-1 do
        if _betValue >= specialBets[index].p_totalBetValue then
            betLevel = index
            break
        end
    end
    return betLevel
end

--@_newLockStatus : 新的锁定状态(是否锁定)
function CodeGameScreenPenguinsBoomsMachine:lockStatusChangeUpDateUi(_newLockStatus)
    --锁定
    if _newLockStatus then
        self.m_jackpotBar:playLockEffect()
        self.m_jackpotBar:playLockTipStartAnim()
    --解锁 
    else
        self.m_jackpotBar:playUnLockEffect()
        self.m_jackpotBar:playLockTipOverAnim()
    end
end
--显示选择bet界面
function CodeGameScreenPenguinsBoomsMachine:showChooseBetView()
    local curBet   = globalData.slotRunData:getCurTotalBet()
    local betLevel = self:getPenguinsBoomsBetLevelByValue(curBet)

    local view = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsChooseBetView",{
        machine  = self,
        bAuto    = true,
        betLevel = betLevel,
    })
    gLobalViewManager:showUI(view)

    view:setPosition(display.center)
end
--根据level切换bet
function CodeGameScreenPenguinsBoomsMachine:changeBetByLevel(betLevel)
    self.m_bottomUI:changeBetCoinNumByLevels(betLevel)
end

function CodeGameScreenPenguinsBoomsMachine:addObservers()
    CodeGameScreenPenguinsBoomsMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
            self:clearWinLineEffect()
            --刷新收集进度
            local curBet = globalData.slotRunData:getCurTotalBet()
            self.m_collectBar:clearRandomCollectData()
            local collectData = self.m_collectBar:getCollectDataByBetValue(curBet)
            self.m_collectBar:changeBetUpdateCollectItem(collectData)

            self:changeTipsByChangeBets(curBet)
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

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

        local soundKey  = string.format("sound_PenguinsBooms_baseLineFrame_%d", soundIndex)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            soundKey  = string.format("sound_PenguinsBooms_freeLineFrame_%d", soundIndex)
        end
        local soundName = PublicConfig[soundKey]
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --背景音乐在reSpin下被暂停恢复的处理
    gLobalNoticManager:addObserver(self, function(self, params)
        self:noticCallBack_pauseSound(params)
    end, ViewEventType.NOTIFY_PAUSESOUND)
    gLobalNoticManager:addObserver(self, function(self, params)
        self:noticCallBack_resumeSound(params)
    end, ViewEventType.NOTIFY_RESUMESOUND)
    --背景音乐在reSpin下被直接播放时处理
    gLobalNoticManager:addObserver(self, function(self, params)
        self:noticCallBack_playBgMusic(params)
    end, ViewEventType.NOTIFY_PLAYBGMUSIC)
    
end

function CodeGameScreenPenguinsBoomsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    self:stopPenguinsBoomsReSpinMusic(true)

    --停止计时器
    self.m_changeSizeNode:unscheduleUpdate()

    CodeGameScreenPenguinsBoomsMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPenguinsBoomsMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS_GRAND then
        return "Socre_PenguinsBooms_Jackpot_GRAND"
    end
    if symbolType == self.SYMBOL_BONUS_MAJOR then
        return "Socre_PenguinsBooms_Jackpot_MAJOR"
    end
    if symbolType == self.SYMBOL_BONUS_MEGA then
        return "Socre_PenguinsBooms_Jackpot_MEGA"
    end
    if symbolType == self.SYMBOL_BONUS_MINOR then
        return "Socre_PenguinsBooms_Jackpot_MINOR"
    end
    if symbolType == self.SYMBOL_BONUS_MINI then
        return "Socre_PenguinsBooms_Jackpot_MINI"
    end
    if symbolType == self.SYMBOL_Blank then
        return "Socre_PenguinsBooms_Blank"
    end
    

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPenguinsBoomsMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenPenguinsBoomsMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------
--[[
	棋盘背景和卷轴背景
]]
function CodeGameScreenPenguinsBoomsMachine:changeReelBg(_model, _playAnim)
	local bBase   = "base"   == _model
	local bfree   = "free"   == _model

	local bgIdleName = "base"
	if bfree then
		bgIdleName = "free"
	end

	if _playAnim then
		--卷轴
		self:findChild("Node_base_reel"):setVisible(bBase)
		self:findChild("Node_free_reel"):setVisible(bfree)
		--背景
		--打开高层spine
		self.m_gameBgSpine_up:stopAllActions()
		self.m_gameBgSpine_up:setVisible(true)
		--底层spine直接切换到下一个模式的循环idle
		util_spinePlay(self.m_gameBgSpine_down, bgIdleName, false)
		util_spineEndCallFunc(self.m_gameBgSpine_down, bgIdleName, function()
			util_spinePlay(self.m_gameBgSpine_down, bgIdleName, true)
			util_spinePlay(self.m_gameBgSpine_up, bgIdleName, true)
		end)
		--渐变
        local fadeTime = 9/30
		self.m_gameBgSpine_down:setOpacity(0)
		self.m_gameBgSpine_down:runAction(cc.FadeIn:create(fadeTime))
		self.m_gameBgSpine_up:runAction(cc.Sequence:create(
			cc.FadeOut:create(fadeTime),
			cc.CallFunc:create(function()
				self.m_gameBgSpine_up:setVisible(false)
				self.m_gameBgSpine_up:setOpacity(255)
			end)
		))
	else
		--卷轴
		self:findChild("Node_base_reel"):setVisible(bBase)
		self:findChild("Node_free_reel"):setVisible(bfree)
		--背景
		self.m_gameBgSpine_up:stopAllActions()
		util_spinePlay(self.m_gameBgSpine_down, bgIdleName, true)
		util_spinePlay(self.m_gameBgSpine_up, bgIdleName, true)
		self.m_gameBgSpine_down:setVisible(true)
		self.m_gameBgSpine_up:setVisible(false)
	end
    self.m_collectBar:changeBgSpriteVisible(bfree)
	-- self.m_curBgModel = _model
end
--[[
    主界面角色
]]
function CodeGameScreenPenguinsBoomsMachine:getCurRoleSpine(_bFree)
    if nil == _bFree then
        _bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    end
    if _bFree then
        return self.m_freeRoleSpine
    end
    return self.m_roleSpine
end
--[[
    预告中奖
]]
function CodeGameScreenPenguinsBoomsMachine:operaSpinResultData(param)
	CodeGameScreenPenguinsBoomsMachine.super.operaSpinResultData(self,param)
    if param[1] == true then
        print("[CodeGameScreenPenguinsBoomsMachine:operaSpinResultData]", cjson.encode(param[2].result))
    end
    --bet数据
    self:updateBetData()
	-- 预告中奖标记
    self.m_winningNoticeTime   = self:playYugaoAnim()
	self.m_isPlayWinningNotice = self.m_winningNoticeTime > 0
end
function CodeGameScreenPenguinsBoomsMachine:playYugaoAnim()
    -- 由scatter触发的free 且 不在升行状态
    local features = self.m_runSpinResultData.p_features or {}
    local bScatterFree = features[2] == SLOTO_FEATURE.FEATURE_FREESPIN and not self.m_isTriggerUpReels and self:getCurrSpinMode() ~= FREE_SPIN_MODE
    -- 40%
    local bPlay = (math.random(1,10) <= 4)
    if bScatterFree and bPlay then
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_notice)

        --角色
        self.m_roleSpine:playYuGaoAnim()
        --炸弹
        self.m_yugaoSpine:setVisible(true)
        util_spinePlay(self.m_yugaoSpine, "actionframe_yugao", false)
        util_spineEndCallFunc(self.m_yugaoSpine, "actionframe_yugao", function()
            self.m_yugaoSpine:setVisible(false)
        end)
        --粒子遮罩
        self.m_yugaoCsb:setVisible(true)
        self.m_yugaoCsb:runCsbAction("actionframe", false, function()
            self.m_yugaoCsb:setVisible(false)
        end)

        return 180/60
    end

    return 0
end

function CodeGameScreenPenguinsBoomsMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    -- 将下一步的逻辑包裹一下
    local nextFun = function()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end

    -- 判断本次spin的预告中奖标记
    if self.m_isPlayWinningNotice then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            nextFun()
            waitNode:removeFromParent()
        -- 预告中奖时间线长度
        end, self.m_winningNoticeTime)
    elseif self.m_reSpinDelayReelDownTime > 0 then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            nextFun()
            waitNode:removeFromParent()
        -- 预告中奖时间线长度
        end, self.m_reSpinDelayReelDownTime)
        self.m_reSpinDelayReelDownTime = 0
    else
        nextFun()
    end
end
--预告重置快滚
function CodeGameScreenPenguinsBoomsMachine:yugaoResetReelRunData()
    for iCol = 1, self.m_iReelColumnNum do
        local reelRunData = self.m_reelRunInfo[iCol]
        local preRunLen   = reelRunData.initInfo.reelRunLen
        

        reelRunData:setReelRunLen(preRunLen)
        reelRunData:setReelLongRun(false)
        reelRunData:setNextReelLongRun(false)
        --新滚动
        if self.m_baseReelNodes and self.m_baseReelNodes[iCol] then
            local reelNode = self.m_baseReelNodes[iCol]
            reelNode:setRunLen(preRunLen)
        end

        -- 提取某一列所有内容， 一些老关在创建最终信号小块时会以此列表作为最终信号的判断条件
        local columnSlotsList = self.m_reelSlotsList[iCol]  
        -- 新的关卡父类可能没有这个变量
        if columnSlotsList then
            local columnData = self.m_reelColDatas[iCol]
            local curRunLen = reelRunData:getReelRunLen()
            local iRow = columnData.p_showGridCount
            
            -- 底层算好的滚动长度
            local runLen = reelRunData:getReelRunLen()
            -- 将 老的最终列表 依次放入 新的最终列表 对应索引处
            local maxIndex = runLen + iRow
            for checkRunIndex = maxIndex,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[curRunLen + iRow - (maxIndex - checkRunIndex)] = checkData
            end
        end
    end
end

--[[
    刷新收集条
]]
function CodeGameScreenPenguinsBoomsMachine:refreshCollectBar()
    local curTotalBet = globalData.slotRunData:getCurTotalBet()
    local collectData = self.m_collectBar:getCollectDataByBetValue(curTotalBet)
    self.m_collectBar:refreshCollectItems(collectData)
end

--[[
    隐藏最后一行小块
]]
function CodeGameScreenPenguinsBoomsMachine:hideLastRowSymbol()
    for iCol = 1,self.m_iReelColumnNum do
        local symbolNode = self:getFixSymbol(iCol,1)
        if symbolNode and self:isPenguinsBoomsH1Symbol(symbolNode.p_symbolType) then
            local reelNode = self.m_baseReelNodes[iCol]
            reelNode:removeSymbolByRowIndex(1)
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenPenguinsBoomsMachine:slotOneReelDown(reelCol)   
    local reels        = self.m_runSpinResultData.p_reels or {}
    local firstRowData = reels[#reels] or {}
    if self:isPenguinsBoomsH1Symbol(firstRowData[reelCol]) then
        local symbolNode = self:getFixSymbol(reelCol,1)
        self:changePenguinsBoomsSymbolType(symbolNode, self.SYMBOL_Blank)
        local curBet = globalData.slotRunData:getCurTotalBet()
        local collectData  = self.m_collectBar:getCollectDataByBetValue(curBet)
        local collectCount = collectData[tostring(reelCol-1)] or 1
        local lockBonus = self.m_collectBar:getItemByColIndex(reelCol)
        -- 本次固定bonus是两次时 可能另外一次时掉落玩法触发的,buling时只展示数量1
        if not lockBonus:isVisible() then
            collectCount = 1
        end
        self:playBulingSymbolSounds(reelCol, PublicConfig.sound_PenguinsBooms_bonus_buling, nil)
        self.m_collectBar:playBulingAnim(symbolNode.p_cloumnIndex, collectCount)
    end

    CodeGameScreenPenguinsBoomsMachine.super.slotOneReelDown(self,reelCol) 

    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        if self.m_firstReelRunCol == 0 then
            self.m_firstReelRunCol = reelCol
        end
    end
    if reelCol == self.m_iReelColumnNum then
        self.m_firstReelRunCol = 0
        self.m_expectAnim:stopExpectAnim()
    end

    self:playQuickStopBulingSymbolSound(reelCol)
end

--[[
    检测播放落地动画
]]
function CodeGameScreenPenguinsBoomsMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        CodeGameScreenPenguinsBoomsMachine.super.checkPlayBulingAni(self, colIndex)
        return
    end
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList or {}

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        if symbolNode and symbolNode.p_symbolType then
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                if self:checkSymbolBulingAnimPlay(symbolNode) then
                    symbolNode.m_playBuling = true
                elseif self:isPenguinsBoomsH1Symbol(symbolNode.p_symbolType) then
                    symbolNode:runIdleAnim()
                end
            end
            --把落地音效放这里直接检测播放
            if self:checkSymbolBulingSoundPlay(symbolNode) then
                local symbolType = symbolNode.p_symbolType
                local symbolCfg = bulingSoundCfg[symbolType]
                if symbolCfg then
                    local iCol = symbolNode.p_cloumnIndex
                    local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                    if soundPath then
                        self:playBulingSymbolSounds(iCol, soundPath, nil)
                    end
                end
            end
        end
    end

    CodeGameScreenPenguinsBoomsMachine.super.checkPlayBulingAni(self, colIndex)

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        if symbolNode and symbolNode.p_symbolType then
            if not self:checkSymbolBulingAnimPlay(symbolNode) then
                --sc层级默认层级修改
                if self:isPenguinsBoomsScatterSymbol(symbolNode.p_symbolType) then
                    self:setScatterJackpotNormalOrder(symbolNode)
                --jackpot默认层级修改
                elseif self:isPenguinsBoomsJackpotSymbol(symbolNode.p_symbolType) then
                    self:setScatterJackpotNormalOrder(symbolNode)
                end
            end  
        end
    end
end
function CodeGameScreenPenguinsBoomsMachine:checkSymbolBulingSoundPlay(_slotNode)
    if not _slotNode then
        return false
    end

    local symbolType = _slotNode.p_symbolType
    if self:isPenguinsBoomsScatterSymbol(symbolType) or self:isPenguinsBoomsJackpotSymbol(symbolType) then
        local iCol = _slotNode.p_cloumnIndex
        local lastCol = iCol - 1
        local curCount  = self:getSymbolCountByCol(symbolType, lastCol)
        local needCount = math.max(0, 3 - (self.m_iReelColumnNum - lastCol)) 
        if curCount < needCount then
            return false
        end
    end
    if self:isPenguinsBoomsH1Symbol(symbolType) then
        if not self:isPenguinsBoomsUpRow() then
            return false
        end 
    end

    return true
end
function CodeGameScreenPenguinsBoomsMachine:symbolBulingEndCallBack(_symbolNode)
    _symbolNode.m_playBuling = nil
    local symbolType = _symbolNode.p_symbolType

    --落地动画执行完毕后还没开始滚动时
    if self:getGameSpinStage() == IDLE then
        --sc层级默认层级修改
        --jackpot默认层级修改
        if self:isPenguinsBoomsScatterSymbol(symbolType) or self:isPenguinsBoomsJackpotSymbol(symbolType) then
            self:setScatterJackpotNormalOrder(_symbolNode)
        end
    end
    
    --循环idle
    if self:isPenguinsBoomsScatterSymbol(symbolType) or 
        self:isPenguinsBoomsH1Symbol(symbolType) or 
        self:isPenguinsBoomsJackpotSymbol(symbolType) then

        self:playSymbolBreathingAnim(_symbolNode)
    end
    --期待动画
    if symbolType == self.m_reelRunSymbol then 
        if 0 ~= self.m_firstReelRunCol then
            local iCol = _symbolNode.p_cloumnIndex
            local iRow = _symbolNode.p_rowIndex
            if iCol == self.m_firstReelRunCol then
                self.m_expectAnim:playExpectAnim(iCol, nil, self.m_reelRunSymbol)
            elseif iCol > self.m_firstReelRunCol then
                self.m_expectAnim:playExpectAnim(iCol, iRow, self.m_reelRunSymbol)
            end
        end
    end
end

function CodeGameScreenPenguinsBoomsMachine:isFixSymbol(symbolType)
    return false
end

--新滚动使用
function CodeGameScreenPenguinsBoomsMachine:updateReelGridNode(symbolNode)
    if not symbolNode then
        return
    end

    -- self:upDateSymbolTuowei(symbolNode)
    self:addSpineSymbolCsbNode(symbolNode)
    self:resetScatterNodeTimes(symbolNode)
end
-- 拖尾
function CodeGameScreenPenguinsBoomsMachine:upDateSymbolTuowei(_symbolNode)
    -- 棋盘在滚动
    local curSpinStage = globalData.slotRunData.gameSpinStage
    if IDLE ~= curSpinStage then
        --h1拖尾
        if self:isPenguinsBoomsH1Symbol(_symbolNode.p_symbolType) then
            --下一个信号不是h1 就播放拖尾
            local nextSymbolType = self:getPenguinsBoomsNextSymbolTypeByCol(_symbolNode.p_cloumnIndex)
            if not self:isPenguinsBoomsH1Symbol(nextSymbolType) then
                _symbolNode:runAnim("idleframe4", true)
            end
        end
    end
end
function CodeGameScreenPenguinsBoomsMachine:getPenguinsBoomsNextSymbolTypeByCol(_iCol)
    local nextSymbolType = nil
    local reelNode = self.m_baseReelNodes[_iCol]
    
    --停轮中 (假滚队列小于0, 真是数据还有未展示的, 真实数据列表不为空)
    if reelNode.m_leftCount <= 0 and reelNode.m_lastNodeCount > 0 and #reelNode.m_lastList > 0 then
        nextSymbolType = reelNode.m_lastList[1]
    --假滚中
    else
        local beginIndex = reelNode.m_parentData.beginReelIndex or 1
        local reelDatas  = reelNode.m_parentData.reelDatas      or {}
        if beginIndex > #reelDatas then
            beginIndex = 1
        end
        nextSymbolType = reelDatas[beginIndex]
    end

    return nextSymbolType
end
--[[
    scatter次数
]]
function CodeGameScreenPenguinsBoomsMachine:addSpineSymbolCsbNode(_slotsNode)
    if  not _slotsNode.m_isLastSymbol then
        return
    end
    local bindNodeCfg = {
        [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = {csbName = "PenguinsBooms_ScatterLab.csb", slotName = "cishu_guadian"},
    } 
    local symbolType = _slotsNode.p_symbolType or _slotsNode.m_symbolType
    local symbolCfg  = bindNodeCfg[symbolType]
    if not symbolCfg then
        return
    end
    if _slotsNode.p_symbolImage then
        _slotsNode.p_symbolImage:removeFromParent()
        _slotsNode.p_symbolImage = nil
    end

    -- 默认一个spine上面最多有一个插槽可以挂cocos工程,存放的变量名称保持一致
    local animNode = _slotsNode:checkLoadCCbNode()
    if not animNode.m_slotCsb then
        -- 标准小块用的spine是 animNode.m_spineNode, 临时小块的spine直接是 animNode
        local spineNode = animNode.m_spineNode or (_slotsNode.m_symbolType and animNode) 
        animNode.m_slotCsb = util_createAnimation(symbolCfg.csbName)
        util_spinePushBindNode(spineNode, symbolCfg.slotName, animNode.m_slotCsb)
    end
end
function CodeGameScreenPenguinsBoomsMachine:resetScatterNodeTimes(_slotsNode)
    local symbolType = _slotsNode.p_symbolType or _slotsNode.m_symbolType
    if not self:isPenguinsBoomsScatterSymbol(symbolType) then
        return
    end
    -- 没有动画节点 or 没添加插槽工程
    local animNode = _slotsNode:getCCBNode()
    if not animNode or not animNode.m_slotCsb then
        return
    end

    animNode.m_slotCsb:findChild("m_lb_num"):setString("")
end
function CodeGameScreenPenguinsBoomsMachine:upDateScatterNodeTimes(_slotsNode)
    local symbolType = _slotsNode.p_symbolType or _slotsNode.m_symbolType
    if not self:isPenguinsBoomsScatterSymbol(symbolType) then
        return
    end
    -- 没有动画节点 or 没添加插槽工程
    local animNode = _slotsNode:getCCBNode()
    if not animNode or not animNode.m_slotCsb then
        return
    end

    local freeTimes = self:getScatterTimesData(_slotsNode.p_cloumnIndex, _slotsNode.p_rowIndex)
    local labTimes = animNode.m_slotCsb:findChild("m_lb_num")
    labTimes:setString(tostring(freeTimes))
end
function CodeGameScreenPenguinsBoomsMachine:getScatterTimesData(_iCol, _iRow)
    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    local scTimesList = selfData.scTimes or {}
    local reelIndex   = self:getPosReelIdx(_iRow, _iCol)
    local times       = scTimesList[tostring(reelIndex)] or 0
    return times
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenPenguinsBoomsMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenPenguinsBoomsMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

----------- 数据处理相关-------------------------------------------------------------------------
function CodeGameScreenPenguinsBoomsMachine:initGameStatusData(gameData)
    CodeGameScreenPenguinsBoomsMachine.super.initGameStatusData(self, gameData)

    local extraData = gameData.gameConfig.extra
    if nil ~= extraData then
        --bet数据
        local betDataList = extraData.bet and clone(extraData.bet) or {}
        self.m_collectBar:setBetDataList(betDataList)
    end
end
-- 断线重连
function CodeGameScreenPenguinsBoomsMachine:MachineRule_initGame(  )
    if self.m_bProduceSlots_InFreeSpin then
        self.m_bPenguinsBoomsReconnection = true
        --切换展示
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_roleSpine:setVisible(false)
        self.m_freeRoleSpine:setVisible(true)
        self.m_freeRoleSpine:playFreeIdleAnim(0, 1)
        self:changeReelBg("free", false)
    end
end
--断线重连-不添加freeOver事件
function CodeGameScreenPenguinsBoomsMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

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
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:setCurrSpinMode(FREE_SPIN_MODE)
        --!!!这块不要了
        --[[
            if self:checkTriggerFsOver() then
                local fsOverEffect = GameEffectData.new()
                fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
                fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
                self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
            end
        ]]
    
        -- 发送事件显示赢钱总数量
        local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end
--[[
    刷新bet数据
]]
function CodeGameScreenPenguinsBoomsMachine:updateBetData()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.bonusPosition then
        local curBet = globalData.slotRunData:getCurTotalBet()
        self.m_collectBar:setBetDataByBetValue(curBet, selfData.bonusPosition)
    end
end

function CodeGameScreenPenguinsBoomsMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i = 1, featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的，
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                    self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                    else
                        -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                        globalData.slotRunData.totalFreeSpinCount = 0
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    end

                    globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes
                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then -- 触发respin 玩法
                    globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                    if self:getCurrSpinMode() == RESPIN_MODE then
                    else
                        local respinEffect = GameEffectData.new()
                        respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                        if globalData.slotRunData.iReSpinCount == 0 then
                            respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                        end
                        self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                    -- 添加 BonusEffect
                    self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end
            end
        end
    end
end


------------------------------------------------------------------------------

----------- FreeSpin相关

-- 显示free spin
function CodeGameScreenPenguinsBoomsMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    --freeMore不断线重连
    if self.m_bPenguinsBoomsReconnection and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_bPenguinsBoomsReconnection = false

        effectData.p_isPlay = true
        self:playGameEffect() 
        return true
    end
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

    --!!! 放在后面区分处理 停掉背景音乐
    -- self:clearCurMusicBg()
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
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

-- FreeSpinstart
function CodeGameScreenPenguinsBoomsMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMoreAutoNomal( 
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeBar_add)
                    local fsCount    = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    self.m_baseFreeSpinBar:playFreeMoreAnim(fsCount, function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)    
                end,
                true
            )
        else
            --先把free次数初始化了
            self.m_baseFreeSpinBar:changeFreeSpinByCount()

            --reSpin触发free不要过场,弹板弹出直接硬切
            if self.m_bBonusTriggerFree then
                --取消连线
                self:clearWinLineEffect()
                self:stopLinesWinSound()
                --将小块放回原层级
                self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
                    if _slotsNode then
                        self:putSymbolBackToPreParent(_slotsNode)
                    end
                end)
                --角色出现
                self.m_roleSpine:playDownRowAninm(function()
                    self.m_roleSpine:resetIdleLoopAnim(false)
                end)
                self.m_isBombReelOver = false
                --降行
                self:resetReelSize(function()
                end)

                --先注释一下 策划不要了
                --切换展示 
                -- self.m_roleSpine:setVisible(false)
                -- self.m_freeRoleSpine:setVisible(true)
                -- self.m_freeRoleSpine:playFreeIdleAnim(0, 1)
                -- self.m_collectBar:clearCollectBar()
                -- self:showFreeSpinBar()
                -- self:changeReelBg("free", true)
                -- self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                --     self.m_bBonusTriggerFree = false
                --     self:triggerFreeSpinCallFun()
                --     effectData.p_isPlay = true
                --     self:playGameEffect()   
                -- end)
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self.m_roleSpine:setVisible(false)
                    self.m_freeRoleSpine:setVisible(true)
                    self.m_freeRoleSpine:playFreeIdleAnim(0, 1)
                    self:playFreeSpinGuoChang(
                        function()
                            --进入free清空收集进度
                            self.m_collectBar:clearCollectBar()
                            --切换展示
                            self:showFreeSpinBar()
                            self:changeReelBg("free", true)
                        end,
                        function()
                            self.m_bBonusTriggerFree = false
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()       
                        end
                    )
                end)
            else
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self.m_roleSpine:setVisible(false)
                    self.m_freeRoleSpine:setVisible(true)
                    self.m_freeRoleSpine:playFreeIdleAnim(0, 1)
                    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_baseToFreeGuochang)
                    self:playFreeSpinGuoChang(
                        function()
                            --进入free清空收集进度
                            self.m_collectBar:clearCollectBar()
                            --切换展示
                            self:showFreeSpinBar()
                            self:changeReelBg("free", true)
                        end,
                        function()
                            self.m_bBonusTriggerFree = false
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()       
                        end
                    )
                end)
            end
        end
    end

    self:playPenguinsBoomsScatterActionFrame(function()
        self:delayCallBack(0.01, function()
            showFSView()
        end)
    end)
end
--触发+震动+角色+飞粒子到屏幕中央
function CodeGameScreenPenguinsBoomsMachine:playPenguinsBoomsScatterActionFrame(_fun)
    local animName = "actionframe"
    local animTime = 0
    -- reSpin内触发free
    if self.m_bBonusTriggerFree then
        animName = "actionframe2"
    end
    --freeMore
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_scatter_freeActionframe)
    --freeTrigger
    else
        -- 停掉背景音乐
        self:clearCurMusicBg()
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_scatter_baseActionframe)

        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    

    local selfData    = self.m_runSpinResultData.p_selfMakeData or {}
    local scTimesList = selfData.scTimes or {}
    local scatterList = {}
    for _sReelIndex,_freeTimes in pairs(scTimesList) do
        local reelIndex     = tonumber(_sReelIndex)
        local scatterSymbol = self:getSymbolByPosIndex(reelIndex)
        if scatterSymbol then
            table.insert(scatterList, scatterSymbol)
            --强制变回
            if not self:isPenguinsBoomsScatterSymbol(scatterSymbol.p_symbolType) then
                self:changePenguinsBoomsSymbolType(scatterSymbol, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            end
            --提层
            self:setPenguinsBoomsSpecialSymbolOrder(scatterSymbol, self.PenguinsBoomsReelNodeOrder.TriggerScatter)
            --触发动画
            scatterSymbol:runAnim(animName, false, function()
                scatterSymbol:runAnim("idleframe4", true)
            end)
            animTime = scatterSymbol:getAniamDurationByName(animName)
            --刷新sc次数
            self:upDateScatterNodeTimes(scatterSymbol)
        end
    end
    if not self:isPenguinsBoomsUpRow() then
        self.m_roleSpine:playScatterAnim()
    end
    self:delayCallBack(animTime, _fun)
end

function CodeGameScreenPenguinsBoomsMachine:showFreeSpinStart(_times, _fun, _isAuto)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeStartView_start)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local scTimes  = selfData.scTimes or {}

    local freeStartView = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsFree.PenguinsBoomsFreeStartView")
    freeStartView:setPenguinsBoomsFreeStartViewData({
        freeTimes = self.m_iFreeSpinTimes,
        scTimes   = scTimes,
    })
    freeStartView:initViewData(self, freeStartView.DIALOG_TYPE_FREESPIN_START, _fun, freeStartView.AUTO_TYPE_NOMAL, nil)
    freeStartView:updateOwnerVar({})
    freeStartView.m_btnTouchSound = PublicConfig.sound_PenguinsBooms_commonClick
    freeStartView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeStartView_over)
    end)
    gLobalViewManager:showUI(freeStartView)

    --20帧播一下粒子
    -- local waitNode = cc.Node:create()
    -- freeStartView:addChild(waitNode)
    -- performWithDelay(waitNode,function()
    --     local particle = freeStartView:findChild("Particle_1")
    --     particle:setVisible(true)
    --     particle:stopSystem()
    --     particle:resetSystem()
    --     waitNode:removeFromParent()
    -- end, 21/60)

    return freeStartView
end
function CodeGameScreenPenguinsBoomsMachine:playFreeSpinGuoChang(_fun1, _fun2)
    --角色甩手
    self.m_freeRoleSpine:playGuoChangAnim(function()
        self.m_freeRoleSpine:playFreeIdleAnim(0, 1)
    end)
    --炸弹出现
    self.m_yugaoSpine:setVisible(true)
    util_spinePlay(self.m_yugaoSpine, "actionframe_guochang", false)
    --切换
    self:delayCallBack(27/30, function()
        _fun1()
        --结束
        self:delayCallBack(18/30, function()
            self.m_yugaoSpine:setVisible(false)

            _fun2()
        end)
    end)
end

--特殊三条时间线start idle over  自动播放
function CodeGameScreenPenguinsBoomsMachine:showFreeSpinMoreAutoNomal(num, func)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeMoreView_start)

    local function newFunc()
        -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
            -- self:resetMusicBg(true)
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local freeMoreView = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_NOMAL)
    freeMoreView.m_btnTouchSound = PublicConfig.sound_PenguinsBooms_commonClick
    freeMoreView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeMoreView_over)
    end)
    return freeMoreView
end


function CodeGameScreenPenguinsBoomsMachine:showFreeSpinOverView()
    self:stopPenguinsBoomsReSpinMusic(true)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeOverView_start)
    local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    local fsCount    = self.m_runSpinResultData.p_freeSpinsTotalCount

    local view = self:showFreeSpinOver( 
        util_formatCoins(fsWinCoins, 50), 
        fsCount,
        function()
            gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeToBaseGuochang)
            --过场
            self:playFreeSpinGuoChang(
                function()
                    --切换展示
                    self.m_freeRoleSpine:setVisible(false)
                    self.m_roleSpine:setVisible(true)
                    self.m_roleSpine:playIdleAnim(0, 1)
                    self:hideFreeSpinBar()
                    self.m_jackpotBar:playJackpotBarIdleAnim()
                    self:changeReelBg("base", true)
                end,
                function()
                    --随机新的固定bonus
                    self:playReSpinOverResetCollectBarAnim(nil)

                    self:triggerFreeSpinOverCallFun()
                end
            )
        end
    )
    -- 取消连线展示
    self:clearWinLineEffect()
    self:stopLinesWinSound()
    --将小块放回原层级
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        if _slotsNode then
            self:putSymbolBackToPreParent(_slotsNode)
        end
    end)
    self.m_isBombReelOver = false
    --角色出现
    self.m_freeRoleSpine:playDownRowAninm(function()
        self.m_freeRoleSpine:playFreeIdleAnim(0, 1)
    end)
    --降行
    self:resetReelSize(function()
    end)
end
function CodeGameScreenPenguinsBoomsMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    
    if coins == "0" then
        return self:showDialog("NoWin",{},func)
    else
        local freeOverView = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsFree.PenguinsBoomsFreeOverView")
        freeOverView:initViewData(self, freeOverView.DIALOG_TYPE_FREESPIN_OVER, func, freeOverView.AUTO_TYPE_NOMAL, nil)
        self:updateFreeOverView(freeOverView, coins, num)
        gLobalViewManager:showUI(freeOverView)
        
        return freeOverView
    end
end
function CodeGameScreenPenguinsBoomsMachine:updateFreeOverView(_freeOverView, _coins, _num)
    local ownerlist = {}
    ownerlist["m_lb_num"] = _num
    ownerlist["m_lb_coins"] = util_formatCoins(_coins, 30)
    _freeOverView:updateOwnerVar(ownerlist)

    local node = _freeOverView:findChild("m_lb_coins")
    _freeOverView:updateLabelSize({label=node,sx=1,sy=1},590)
    --企鹅+鸟
    local spineBird = util_spineCreate("Socre_PenguinsBooms_7",true,true)
    _freeOverView:findChild("Node_niao"):addChild(spineBird)
    local startName = "start_tanban"
    local idleName  = "idle_tanban"
    util_spinePlay(spineBird, startName, false)
    util_spineEndCallFunc(spineBird, startName, function()
        util_spinePlay(spineBird, idleName, true)
    end)
    local spinePenguin = util_spineCreate("PenguinsBooms_base_juese",true,true)
    _freeOverView:findChild("Node_qie"):addChild(spinePenguin)
    util_spinePlay(spinePenguin, startName, false)
    util_spineEndCallFunc(spinePenguin, startName, function()
        util_spinePlay(spinePenguin, idleName, true)
    end)

    _freeOverView.m_btnTouchSound = PublicConfig.sound_PenguinsBooms_commonClick
    _freeOverView:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeOverView_over)
    end)
end



---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPenguinsBoomsMachine:MachineRule_SpinBtnCall()
    -- 重置一些标记
    self.m_isPlayWinningNotice = false
    self.m_firstReelRunCol = 0
    self.m_reelRunSymbol   = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    --重置ui状态
    self.m_jackpotBar:playJackpotBarIdleAnim()
    
    self.m_ruleTips:setTipTouchEnabled(false)

    self:stopLinesWinSound()
    if not self:isPenguinsBoomsUpRow() then
        self:setMaxMusicBGVolume()
    end
    
    return false -- 用作延时点击spin调用
end

function CodeGameScreenPenguinsBoomsMachine:beginReel()
    --收集栏的透明度 
    self.m_collectBar:changeBgSpriteOpacity(true)
    if self.m_isBombReelOver then
        self.m_isBombReelOver = false
        --随机新的固定bonus
        self:playReSpinOverResetCollectBarAnim(nil)
        --角色出现
        local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
        local roleSpine = self:getCurRoleSpine(bFree)
        roleSpine:playDownRowAninm(function()
            roleSpine:resetIdleLoopAnim(bFree)
        end)
        --降行
        self:resetReelSize(function()  
        end)
        self:stopPenguinsBoomsReSpinMusic()
        self:setMaxMusicBGVolume()
    end
    --收集栏层级
    if not self:isPenguinsBoomsUpRow() then
        self.m_collectBar:setLocalZOrder(self.PenguinsBoomsReelNodeOrder.BaseReelRunCollectBar)
    end
    
    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() == RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false, true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end
    CodeGameScreenPenguinsBoomsMachine.super.beginReel(self)
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPenguinsBoomsMachine:addSelfEffect()

    if self.m_isTriggerUpReels then --当前是升行状态
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BOMB_REEL_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BOMB_REEL_EFFECT -- 动画类型
        
        --bugly日志-23.05.17 如果本次spin没有玩法数据,则打印当前关卡内的部分数据
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local respinChangeData = selfData.respinChangeData or {}
        if #respinChangeData <= 0 then
            local sMsg = "[CodeGameScreenPenguinsBoomsMachine:addSelfEffect]"
            sMsg = string.format("%s %s",sMsg, cjson.encode(selfData))
            util_printLog(sMsg, true)
        end
    end

    --中了jackpot
    if not self.m_isTriggerUpReels then
        local jackpotWinCoins = self.m_runSpinResultData.p_jackpotCoins
        if jackpotWinCoins and next(jackpotWinCoins) then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.HIT_JACKPOT_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.HIT_JACKPOT_EFFECT -- 动画类型
        end
    end
    --炸弹玩法中了jackpot
    if self:isTriggerBombJackpot() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_Bomb_JackpotTrigger
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_Bomb_JackpotTrigger
    end

    

    local selfData = self.m_runSpinResultData.p_selfMakeData
    --free触发必中玩法
    if selfData and selfData.addBonusTrigger then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.TRIGGER_BOMB_IN_FREE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.TRIGGER_BOMB_IN_FREE_EFFECT -- 动画类型
    end

    --有新的炸弹落在最下面
    local reels = self.m_runSpinResultData.p_reels
    if reels and reels[#reels] then
        for iCol = 1,self.m_iReelColumnNum do
            if self:isPenguinsBoomsH1Symbol(reels[#reels][iCol]) then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER + 1
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.COLLECT_BOMB_EFFECT -- 动画类型
                break
            end
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPenguinsBoomsMachine:MachineRule_playSelfEffect(effectData)

    -- 刷新骷髅的idle状态
    if effectData.p_selfEffectType == self.COLLECT_BOMB_EFFECT then
        effectData.p_isPlay = true
        self:playGameEffect()
    --free必中玩法
    elseif effectData.p_selfEffectType == self.TRIGGER_BOMB_IN_FREE_EFFECT then 
        self:playEffectAddBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType ==self.HIT_JACKPOT_EFFECT then --获得jackpot(滚出来的)
        local jackpotWinCoins = self.m_runSpinResultData.p_jackpotCoins
        local rewardsData = {}
        --拼接数据
        for jackpotType,coins in pairs(jackpotWinCoins) do
            local reward = {
                jackpotType = string.lower(jackpotType),
                jackpotWinAmount = coins
            }
            rewardsData[#rewardsData + 1] = reward
        end

        --由小到大排序
        if #rewardsData > 1 then
            table.sort(rewardsData,function(a,b)
                return a.jackpotWinAmount < b.jackpotWinAmount
            end)
        end
        self:getNextJackpot(rewardsData,1,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
    elseif effectData.p_selfEffectType == self.BOMB_REEL_EFFECT then --炸弹玩法
        --升行玩法中不会出现3个以上的相同的jakcpot图标和scatter图标,数值做规避
        self:bombReelEffect(function(  )
            self.m_isTriggerUpReels = false
            self.m_isBombReelOver = true
            -- 炸弹触发free
            if self.m_isTriggerFree then
                self.m_isTriggerFree = false
            end

            self.m_collectBar:setLocalZOrder(self.PenguinsBoomsReelNodeOrder.BaseCollectBar)
            
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_Bomb_JackpotTrigger then
        if self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
            self:delayCallBack(2, function()
                -- 取消连线展示
                self:clearWinLineEffect()
                self:stopLinesWinSound()
                self:playEffectBombJackpot(1, 1, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end)
        else
            self:playEffectBombJackpot(1, 1, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end
    end

    return true
end
-- 是否还处于升行
function CodeGameScreenPenguinsBoomsMachine:isPenguinsBoomsUpRow()
    return self.m_isTriggerUpReels or self.m_isBombReelOver
end
--[[
    炸弹玩法内命中的jackpot触发事件
]]
function CodeGameScreenPenguinsBoomsMachine:isTriggerBombJackpot()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local respinChangeData = selfData.respinChangeData or {}
    for _sKey,_colData in pairs(respinChangeData) do
        for _index,_flyData in ipairs(_colData) do
            if self.BombAwardType.Jackpot == _flyData.rewardType then
                return true
            end
        end
    end
    return false
end
function CodeGameScreenPenguinsBoomsMachine:playEffectBombJackpot(_iCol, _timesIndex, _fun)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local respinChangeData = selfData.respinChangeData
    local sKey = tostring(_iCol - 1)
    local colData = respinChangeData[sKey]
    if not colData then
        --添加炸弹玩法jackpot大赢事件
        self:addBombFlyFeedbackJackpotBigWinEffect()
        _fun()
        return
    end
    local flyData = colData[_timesIndex]
    if not flyData then
        self:playEffectBombJackpot(_iCol+1, 1 , _fun)
        return
    end
    --jackpot坐标和jackpot类型
    local jackpotSymbol = self:getSymbolByPosIndex(flyData.targetPos)
    local symbolType    = self:getSymbolTypeForNetData(jackpotSymbol.p_cloumnIndex, jackpotSymbol.p_rowIndex)
    local jackpotType   = self.SymbolTypeToJackpotType[symbolType]
    local jackpotIndex  = self.SymbolTypeToJackpotIndex[symbolType]
    if not jackpotType then
        self:playEffectBombJackpot(_iCol, _timesIndex+1, _fun)
        return
    end

    -- jackpotBar触发
    self.m_jackpotBar:playJackpotTriggerAnim(jackpotIndex)
    -- 图标触发
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpot_actionframe)
    self:changePenguinsBoomsSymbolType(jackpotSymbol, symbolType)
    self:setPenguinsBoomsSpecialSymbolOrder(jackpotSymbol, self.PenguinsBoomsReelNodeOrder.TriggerJackpot)
    
    --播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    jackpotSymbol:runAnim("actionframe", false, function()
        jackpotSymbol:runAnim("idleframe4", true)
        --弹板
        self:showJackpotWinView(jackpotType, flyData, function(  )
            self:playEffectBombJackpot(_iCol+1, 1 , _fun)
        end)
        --跳钱
        local bottomWinCoin = self:getCurBottomWinCoins()
        local addCoins      = flyData.jackpotWinAmount
        local lastWinCoin   = bottomWinCoin + addCoins
        self:setLastWinCoin(lastWinCoin)
        self:updateBottomUICoins(0, addCoins, false, true, false)
    end)
end
function CodeGameScreenPenguinsBoomsMachine:addBombFlyFeedbackJackpotBigWinEffect()
    local dataList        = self:getBombFlyDataByType("jackpot")
    local jackpotWinCoins = 0
    for _iCol,_colData in ipairs(dataList) do
        for _timesIndex,_flyData in ipairs(_colData) do
            jackpotWinCoins = jackpotWinCoins + _flyData.jackpotWinAmount
        end
    end
    if 0 >= jackpotWinCoins then
        return
    end
    --最后一次free和存在连线时 不用处理
    if not self:isLastFreeSpin() and not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
        self.m_iOnceSpinLastWin = jackpotWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{jackpotWinCoins, self.COLLECT_BOMB_EFFECT})
        self:sortGameEffects()
    else
        local lineWinCoins  = self:getClientWinCoins()
        self.m_iOnceSpinLastWin = lineWinCoins + jackpotWinCoins
    end
    if not self.m_bProduceSlots_InFreeSpin == true or self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        --刷新顶栏
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end
end

--[[
    炸弹玩法
]]
function CodeGameScreenPenguinsBoomsMachine:bombReelEffect(func)
    self:delayCallBack(0.1, function()
        --开启跳过功能
        self.m_skipPanelCsb:setSkipCallBack(function()
            gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_commonClick)
            self.m_skipPanelCsb:clearSkipCallBack()
            self.m_skipPanelCsb:setVisible(false)
            self.m_bottomUI:setSkipBonusBtnVisible(false)
            self:showBombResultReel()
            func()
        end)
        self.m_skipPanelCsb:setVisible(true)
        self.m_bottomUI:setSkipBonusBtnVisible(true)

        self.m_skipPanelCsb:runNext(0.4, function()
            --所有特殊图标待触发
            self:playBombReelEffect_specialSymbolWaitTriggerAnim()
            --炸弹依次播放
            self:bombNextColAni(1, function()
                --wild框消失->wild出现
                self:playWildFrameActionframeAnim(function()
                    self.m_skipPanelCsb:clearSkipCallBack()
                    self.m_skipPanelCsb:setVisible(false)
                    self.m_bottomUI:setSkipBonusBtnVisible(false)
                    func()
                end)
            end)
        end)
    end)
end
function CodeGameScreenPenguinsBoomsMachine:showBombResultReel()
    --清空收集进度
    self.m_collectBar:clearCollectBar()
    --停止本列待触发动画
    for iCol=1,self.m_iReelColumnNum do
        self:playBombReelEffect_clearWaitTriggerAnim(iCol)
        self.m_collectBar:updateBonusLabVisible(iCol, 1)
    end
    
    --盘面修改为最终结果
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local respinChangeData = selfData.respinChangeData
    for iCol=1,self.m_iReelColumnNum do
        local sKey = tostring(iCol-1)
        local colData = respinChangeData[sKey] or {}
        for _index,_flyData in ipairs(colData) do
            --单个图标变wild
            if _flyData.rewardType == "wild" then 
                local symbolNode = self:getSymbolByPosIndex(_flyData.targetPos)
                self:changePenguinsBoomsSymbolType(symbolNode, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                self:setPenguinsBoomsSpecialSymbolOrder(symbolNode, self.PenguinsBoomsReelNodeOrder.ChangeWild)
                symbolNode:runAnim("idleframe2", true)
            --周围9个图标变wild
            elseif _flyData.rewardType == "changeWild" then 
                for index,_wildReelIndex in ipairs(_flyData.wildPos) do
                    local symbolNode = self:getSymbolByPosIndex(_wildReelIndex)
                    self:changePenguinsBoomsSymbolType(symbolNode, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    if 1 ~= symbolNode.p_rowIndex then
                        self:setPenguinsBoomsSpecialSymbolOrder(symbolNode, self.PenguinsBoomsReelNodeOrder.ChangeWild)
                    end
                    symbolNode:runAnim("idleframe2", true)
                end
            --获取jackpot
            elseif _flyData.rewardType == self.BombAwardType.Jackpot then 
                local symbolNode  = self:getSymbolByPosIndex(_flyData.targetPos)
                --被变为wild时就不切换回来了
                if TAG_SYMBOL_TYPE.SYMBOL_WILD ~= symbolNode.p_symbolType then
                    local symbolType  = self:getSymbolTypeForNetData(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex)
                    self:changePenguinsBoomsSymbolType(symbolNode, symbolType)
                    self:setPenguinsBoomsSpecialSymbolOrder(symbolNode, self.PenguinsBoomsReelNodeOrder.TriggerJackpot)
                    symbolNode:runAnim("idleframe4", true)
                end
            --获得freespin
            elseif _flyData.rewardType == "scatter" then 
                self.m_isTriggerFree = true
                self.m_bBonusTriggerFree = true
                local symbolNode = self:getSymbolByPosIndex(_flyData.targetPos)
                --被变为wild时就不切换回来了
                if TAG_SYMBOL_TYPE.SYMBOL_WILD ~= symbolNode.p_symbolType then
                    self:setPenguinsBoomsSpecialSymbolOrder(symbolNode, self.PenguinsBoomsReelNodeOrder.TriggerScatter)
                    self:upDateScatterNodeTimes(symbolNode)
                    symbolNode:runAnim("idleframe4", true)
                end
            end
        end
    end
    --清空跳过动效父节点的所有子节点
    -- PenguinsBoomsSkip:skipPanelClickCallBack() 内已经操作过了
end
--炸弹玩法-特殊图标播放待触发
function CodeGameScreenPenguinsBoomsMachine:playBombReelEffect_specialSymbolWaitTriggerAnim()
    self.m_specialSymbolList = {}
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        if _slotsNode then
            local symbolType = _slotsNode.p_symbolType
            if self:isPenguinsBoomsH1Symbol(symbolType) or 
                self:isPenguinsBoomsScatterSymbol(symbolType) or
                self:isPenguinsBoomsJackpotSymbol(symbolType) then
                --区分 待触发时间线 和 层级
                local animName    = "idleframe3"
                local symbolOrder = self.PenguinsBoomsReelNodeOrder.WaitTriggerJackpot
                if self:isPenguinsBoomsScatterSymbol(symbolType) then
                    animName = "idleframe1"
                    symbolOrder = self.PenguinsBoomsReelNodeOrder.WaitTriggerScatter
                elseif self:isPenguinsBoomsH1Symbol(symbolType) then
                    animName = "actionframe5"
                    symbolOrder = self.PenguinsBoomsReelNodeOrder.WaitTriggerBonus
                end
                --切换层级
                self:setPenguinsBoomsSpecialSymbolOrder(_slotsNode, symbolOrder)
                --保存坐标到列表
                local reelPos = self:getPosReelIdx(_iRow, _iCol)
                self.m_specialSymbolList[reelPos] = _slotsNode

                _slotsNode:runAnim(animName, true)
            end
        end
    end)
end
--炸弹玩法-取消待触发
function CodeGameScreenPenguinsBoomsMachine:playBombReelEffect_clearWaitTriggerAnim(_reelCol)
    for _reelPos,_symbolNode in pairs(self.m_specialSymbolList) do
        if _symbolNode.p_cloumnIndex == _reelCol then
            self.m_specialSymbolList[_reelPos] = nil
            local symbolType = _symbolNode.p_symbolType
            if self:isPenguinsBoomsScatterSymbol(symbolType) then
                self:setScatterJackpotNormalOrder(_symbolNode)
            elseif self:isPenguinsBoomsH1Symbol(symbolType) then
                self:setPenguinsBoomsSpecialSymbolOrder(_symbolNode, self.PenguinsBoomsReelNodeOrder.NormalBonus)
            elseif self:isPenguinsBoomsJackpotSymbol(symbolType) then
                self:setScatterJackpotNormalOrder(_symbolNode)
            end
            self:playSymbolBreathingAnim(_symbolNode)
        end
    end
    if _reelCol == self.m_iReelColumnNum then
        self.m_specialSymbolList = {}
    end
end

--[[
    炸下一列
]]
function CodeGameScreenPenguinsBoomsMachine:bombNextColAni(_iCol,func)
    if _iCol > self.m_iReelColumnNum then
        self.m_skipPanelCsb:runNext(0.5, func)
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local respinChangeData = selfData.respinChangeData
    local sKey = tostring(_iCol - 1)
    local data = respinChangeData[sKey] or {}
    self:playCollectBarBombFlyAnimByCol(_iCol, 1, data, function()
        self:bombNextColAni(_iCol + 1, func)
    end)
end

--本列炸弹飞出收集栏
function CodeGameScreenPenguinsBoomsMachine:playCollectBarBombFlyAnimByCol(_iCol, _times, _colData,_fun)
    local flyData = _colData[_times]
    if not flyData then
        _fun()
        return 
    end
    --移除待触发列表内的触发数据
    self.m_specialSymbolList[flyData.targetPos] = nil

    local startNode = self.m_collectBar:getItemByColIndex(_iCol)
    local endNode   = self:getSymbolByPosIndex(flyData.targetPos) 
    local fixPos = self:getRowAndColByPos(flyData.targetPos)

    --临时小块
    local parent = self.m_skipEffectNode
    local bonusSymbol = self:createPenguinsBoomsTempSymbol({
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
		machine    = self,
    })
    parent:addChild(bonusSymbol)
    local startPos = util_convertToNodeSpace(startNode, parent)
    local endPos = util_convertToNodeSpace(endNode, parent)
    bonusSymbol:setPosition(startPos)
    --隐藏次数图标
    if #_colData - _times <= 1 then
        self.m_collectBar:updateBonusLabVisible(_iCol, 1)
    end
    --隐藏收集栏固定图标
    if _times ==  #_colData then
        self.m_collectBar:hideBomb(_iCol)
    end
    --预备
    local zhunbenTime = bonusSymbol:getAniamDurationByName("zhunbei")
    bonusSymbol:runAnim("zhunbei", false)
    self.m_skipPanelCsb:runNext(zhunbenTime, function()
        local actList = {}
        local easeOutRate = fixPos.iX > 4 and 1.5 or 2
        table.insert(actList, cc.EaseOut:create(cc.MoveTo:create(30/30,endPos), easeOutRate))
        table.insert(actList, cc.DelayTime:create(15/30))
        table.insert(actList, cc.CallFunc:create(function()
            if flyData.rewardType == "changeWild" then
                --飞行结束反馈
                self:playBombFlyFeedback(flyData, function()
                    self:playCollectBarBombFlyAnimByCol(_iCol, _times+1, _colData, _fun)
                end)
                bonusSymbol:removeTempSlotsNode()
            else
                --爆炸
                bonusSymbol:runAnim("actionframe1", false, function()
                    bonusSymbol:removeTempSlotsNode()
                end)
                --第5帧下一步
                self.m_skipPanelCsb:runNext(6/30, function()
                    --飞行结束反馈
                    self:playBombFlyFeedback(flyData, function()
                        self:playCollectBarBombFlyAnimByCol(_iCol, _times+1, _colData, _fun)
                    end)
                end)
            end
            if _times ==  #_colData then
                --停止本列待触发动画
                if flyData.rewardType == "changeWild" then
                    self:playBombReelEffect_clearWaitTriggerAnim(_iCol)
                else
                    self.m_skipPanelCsb:runNext(6/30, function()
                        self:playBombReelEffect_clearWaitTriggerAnim(_iCol)
                    end)
                end
                
            end
        end))
        --飞行
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_bonus_fly)
        bonusSymbol:runAnim("fly", false)
        bonusSymbol:runAction(cc.Sequence:create(actList))
    end)
end
--一个炸弹的飞行反馈
function CodeGameScreenPenguinsBoomsMachine:playBombFlyFeedback(_flyData, _fun)
    --单个图标变wild
    if _flyData.rewardType == "wild" then 
        self:playBombFlyFeedback_wild(_flyData, _fun)
        return
    --周围9个图标变wild
    elseif _flyData.rewardType == "changeWild" then 
        self:playBombFlyFeedback_changeWild(_flyData, _fun)
        return
    --获取jackpot
    elseif _flyData.rewardType == self.BombAwardType.Jackpot then 
        self:playBombFlyFeedback_jackpot(_flyData, _fun)
        return
    --获得freespin
    elseif _flyData.rewardType == "scatter" then 
        self.m_isTriggerFree = true
        self.m_bBonusTriggerFree = true
        self:playBombFlyFeedback_scatter(_flyData, _fun)
        return
    end

    _fun()
end
function CodeGameScreenPenguinsBoomsMachine:playBombFlyFeedback_wild(_flyData, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_wild_show)
    local posIndex = _flyData.targetPos
    local symbolNode = self:getSymbolByPosIndex(posIndex)
    self:changePenguinsBoomsSymbolType(symbolNode, TAG_SYMBOL_TYPE.SYMBOL_WILD)
    self:setPenguinsBoomsSpecialSymbolOrder(symbolNode, self.PenguinsBoomsReelNodeOrder.ChangeWild)
    symbolNode:runAnim("show", false,function()
        symbolNode:runAnim("idleframe2", true)
    end)
        
    self.m_skipPanelCsb:runNext(18/30, _fun)
end
function CodeGameScreenPenguinsBoomsMachine:playBombFlyFeedback_changeWild(_flyData, _fun)
    --待触发+特效框
    self:createWildFrameAnim(_flyData.targetPos)
    --等大图标合成播完就进行下一步
    self.m_skipPanelCsb:runNext(21/60, _fun)
end
--wild边框效果-创建
function CodeGameScreenPenguinsBoomsMachine:createWildFrameAnim(_reelPos)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_bonus_hecheng)

    local symbolNode = self:getSymbolByPosIndex(_reelPos)
    local parent     = self.m_skipEffectNode
    local pos        = util_convertToNodeSpace(symbolNode, parent)
    --大炸弹待触发
    local bonusSymbol = self:createPenguinsBoomsTempSymbol({symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, machine = self,})
    parent:addChild(bonusSymbol, 10)
    bonusSymbol:runAnim("hecheng", false, function()
        bonusSymbol:runAnim("idleframe5", true)
    end)
    bonusSymbol:setPosition(util_convertToNodeSpace(symbolNode, parent))

    --粒子框
    local wildFrameCsb = util_createAnimation("PenguinsBooms_txk.csb")
    parent:addChild(wildFrameCsb)
    wildFrameCsb:setName(tostring(_reelPos))
    wildFrameCsb:setPosition(pos)
    wildFrameCsb:runCsbAction("start", false, function()
        wildFrameCsb:runCsbAction("idleframe1", true)
    end)

    self.m_wildFrameList[_reelPos] = {bonusSymbol, wildFrameCsb}
end
--wild边框效果-触发
function CodeGameScreenPenguinsBoomsMachine:playWildFrameActionframeAnim(_fun)
    --[[
        m_wildFrameList = {
            [reelPos] = {
                bonusSymbol,
                wildFrameCsb
            }
        }
    ]]
    local parent = self.m_skipEffectNode
    local delayTime = 0
    local dataList = self:getBombFlyDataByType("changeWild")
    for _iCol,_colData in ipairs(dataList) do
        for _timesIndex,_flyData in ipairs(_colData) do
            delayTime = 27/30

            local reelPos  = _flyData.targetPos
            local animList = self.m_wildFrameList[reelPos]
            local bonusSymbol  = animList[1]
            local wildFrameCsb = animList[2]
            --爆炸
            bonusSymbol:runAnim("actionframe4", false)
            --wild切换
            local wildPos  = _flyData.wildPos
            local startPos = util_convertToNodeSpace(bonusSymbol, parent)
            for index,_wildReelIndex in ipairs(wildPos) do
                local symbolNode = self:getSymbolByPosIndex(_wildReelIndex)
                
                --临时小块
                local wildSymbol = self:createPenguinsBoomsTempSymbol({
                    symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD,
	            	machine    = self,
                })
                parent:addChild(wildSymbol)
                wildSymbol:setPosition(startPos)
                --飞行
                local endPos = util_convertToNodeSpace(symbolNode, parent)
                local actList = {}
                table.insert(actList, cc.MoveTo:create(12/30, endPos))
                table.insert(actList, cc.CallFunc:create(function()
                    self:changePenguinsBoomsSymbolType(symbolNode, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    symbolNode:runAnim("idleframe2", true)
                    if 1 ~= symbolNode.p_rowIndex then
                        self:setPenguinsBoomsSpecialSymbolOrder(symbolNode, self.PenguinsBoomsReelNodeOrder.ChangeWild)
                    end
                end))
                table.insert(actList, cc.DelayTime:create(15/30))
                table.insert(actList, cc.CallFunc:create(function()
                    wildSymbol:removeTempSlotsNode()
                end))
                wildSymbol:runAction(cc.Sequence:create(actList))
                wildSymbol:runAnim("show", false)
            end
            --wild框消失
            wildFrameCsb:runCsbAction("over", false)
        end
    end
    if delayTime > 0 then
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_bonus_actionframe4)
        --震屏
        self:shakeReelNode({
            shakeTimes    = math.floor((18/30)/0.1),
            shakeOnceTime = 0.1,
            shakeNodeName = {
                "Node_reel",
                "Node_effect",
            }
        })
    end
    
    self.m_skipPanelCsb:runNext(delayTime, function()
        self:resetWildFrame()
        _fun()
    end)
end
-- 获取wild框数据
function CodeGameScreenPenguinsBoomsMachine:getBombFlyDataByType(_rewardType)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local respinChangeData = selfData.respinChangeData or {}
    local dataList = {}
    for _sIndex,_colData in pairs(respinChangeData) do
        local iCol = tonumber(_sIndex) + 1
        dataList[iCol] = {}
        for _timesIndex,_flyData in ipairs(_colData) do
            if _flyData.rewardType == _rewardType then
                table.insert(dataList[iCol], _flyData)
            end
        end
    end
    return dataList
end
--wild边框效果-清理
function CodeGameScreenPenguinsBoomsMachine:resetWildFrame()
    self.m_wildFrameList = {}
end

function CodeGameScreenPenguinsBoomsMachine:playBombFlyFeedback_jackpot(_flyData, _fun)
    -- gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpot_actionframe)
    -- 图标触发
    local symbolNode  = self:getSymbolByPosIndex(_flyData.targetPos)
    local symbolType  = self:getSymbolTypeForNetData(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex)
    self:changePenguinsBoomsSymbolType(symbolNode, symbolType)
    self:setPenguinsBoomsSpecialSymbolOrder(symbolNode, self.PenguinsBoomsReelNodeOrder.TriggerJackpot)
    local animTime = symbolNode:getAniamDurationByName()
    symbolNode:runAnim("idleframe4", true)
    self.m_skipPanelCsb:runNext(animTime, _fun)
end

function CodeGameScreenPenguinsBoomsMachine:playBombFlyFeedback_scatter(_flyData, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_scatter_actionframe1)
    local reelPos = _flyData.targetPos
    local symbolNode = self:getSymbolByPosIndex(reelPos)
    self:setPenguinsBoomsSpecialSymbolOrder(symbolNode, self.PenguinsBoomsReelNodeOrder.TriggerScatter)
    self:upDateScatterNodeTimes(symbolNode)
    symbolNode:runAnim("actionframe1", false, function()
        symbolNode:runAnim("idleframe4", true)
    end)

    local animTime = 36/30
    self:shakeReelNode({
        shakeTimes    = math.floor(animTime/0.1),
        shakeOnceTime = 0.1,
        shakeNodeName = {
            "Node_reel"
        }
    })
    self.m_skipPanelCsb:runNext(animTime, _fun)
end

-- reSpin结束重置底栏
function CodeGameScreenPenguinsBoomsMachine:playReSpinOverResetCollectBarAnim(_fun)
    local curBet = globalData.slotRunData:getCurTotalBet()
    local collectData = self.m_collectBar:getCollectDataByBetValue(curBet)
    local delayTime = 0
    for iCol=1,self.m_iReelColumnNum do
        local collectCount = collectData[tostring(iCol-1)] or 0
        if collectCount > 0 then
            delayTime = 15/30
            self.m_collectBar:playBombAddBonusAnim(iCol, true)
        end
    end

    if _fun then
        self:delayCallBack(delayTime, _fun)
    end
end

--[[
    随机增加固定bonus玩法
]]
function CodeGameScreenPenguinsBoomsMachine:playEffectAddBonus(_fun)
    local selfData        = self.m_runSpinResultData.p_selfMakeData
    local addBonusTrigger = selfData.addBonusTrigger
    local curTotalBet = globalData.slotRunData:getCurTotalBet()
    local collectData = self.m_collectBar:getCollectDataByBetValue(curTotalBet)
    local parent = self.m_effectNode
    local startPosY = util_convertToNodeSpace(self:findChild("Node_addBonus"), parent)  
    local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    --角色扔炸弹
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_bonus_add)
    local roleSpine = self:getCurRoleSpine(bFree)
    roleSpine:playAddBonusAnim(function()
        roleSpine:resetIdleLoopAnim(bFree)
        --策划要求
        self:delayCallBack(0.2, function()
            --炸弹掉落
            local flyTime     = 15/30
            local interval    = 0.1
            for i=1,self.m_iReelColumnNum do
                local iCol = i
                local lockBonus = self.m_collectBar:getItemByColIndex(iCol)
                local endPos    = util_convertToNodeSpace(lockBonus, parent)  
                local startPos  = cc.p(endPos.x, startPosY.y)
                local collectCount = collectData[tostring(iCol-1)] or 1

                local intervalTime = (i - 1) * interval
                self:delayCallBack(intervalTime,function()
                    --临时图标
                    local bonusSymbol = self:createPenguinsBoomsTempSymbol({
                        machine    = self,
			            symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
                    })
                    parent:addChild(bonusSymbol)
                    bonusSymbol:setPosition(startPos)
                    --拖尾
                    local tempSymbolSpine = bonusSymbol:checkLoadCCbNode()
                    local tuoweiCsb = util_createAnimation("PenguinsBooms_tw_lizi.csb")
                    util_spinePushBindNode(tempSymbolSpine, "lizi", tuoweiCsb)
                    local particle_1 = tuoweiCsb:findChild("Particle_1") 
                    local particle_2 = tuoweiCsb:findChild("Particle_2") 
                    particle_1:setPositionType(0)
                    particle_1:setDuration(-1)
                    particle_1:stopSystem()
                    particle_1:resetSystem()
                    particle_2:setPositionType(0)
                    particle_2:setDuration(-1)
                    particle_2:stopSystem()
                    particle_2:resetSystem()
                    --bonus下落
                    bonusSymbol:runAnim("luo", false)
                    bonusSymbol:runAction(cc.Sequence:create(
                        cc.MoveTo:create(flyTime, endPos),
                        cc.CallFunc:create(function()
                            --bonus添加->刷新数量
                            self.m_collectBar:playBombAddBonusAnim(iCol, false)
                            self:delayCallBack(3/30, function()
                                self.m_collectBar:updateBonusLabVisible(iCol, collectCount)
                            end)
                            bonusSymbol:removeTempSlotsNode()
                        end)
                    ))
                end) 
            end
            
            self:delayCallBack(flyTime, function()
                local maxInterval = (self.m_iReelColumnNum-1) * interval
                self:shakeReelNode({
                    shakeTimes    = math.floor(maxInterval/interval),
                    shakeOnceTime = interval,
                    shakeNodeName = {
                        "Node_reel"
                    }
                })
                local delayTime = 15/30 + maxInterval
                self:delayCallBack(delayTime, _fun)
            end)
            
        end)
        
    end)
end

--[[
    获得jackpot奖励(滚出来的,不是升行获得)
]]
function CodeGameScreenPenguinsBoomsMachine:getNextJackpot(data,index,func)
    if index > #data then
        --添加大赢事件
        self:addReelJackpotBigWinEffect()
        func()
        return 
    end
    local jackpotData = data[index]
    
    --奖池索引
    local jackpotIndex = self.JackpotTypeToJackpotIndex[jackpotData.jackpotType] or 1
    --图标类型
    local symbolType = self.SYMBOL_BONUS_GRAND
    for _jackpotSymbolType,_jpIndex in pairs(self.SymbolTypeToJackpotIndex) do
        if jackpotIndex == _jpIndex then
            symbolType = _jackpotSymbolType
            break 
        end
    end
    -- jackpotBar触发
    self.m_jackpotBar:playJackpotTriggerAnim(jackpotIndex)
    --图标触发
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpot_actionframe)
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        if _slotsNode then
            if _slotsNode.p_symbolType == symbolType then
                --切换层级
                self:setPenguinsBoomsSpecialSymbolOrder(_slotsNode, self.PenguinsBoomsReelNodeOrder.RellTriggerJackpot)
                _slotsNode:runAnim("actionframe", false, function()
                    _slotsNode:runAnim("idleframe4", true)
                end)
            end
        end
    end)

    --播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    --弹板
    self:delayCallBack(60/30, function()
        self:showJackpotWinView(jackpotData.jackpotType,jackpotData,function(  )
            self:getNextJackpot(data,index + 1,func)
        end)
        --跳钱
        local bottomWinCoin = self:getCurBottomWinCoins()
        local addCoins      = jackpotData.jackpotWinAmount
        local lastWinCoin   = bottomWinCoin + addCoins
        self:setLastWinCoin(lastWinCoin)
        self:updateBottomUICoins(0, addCoins, false, true, false)
    end)
end
--添加棋盘滚动出现jackpot的大赢事件
function CodeGameScreenPenguinsBoomsMachine:addReelJackpotBigWinEffect()
    local jackpotList = self.m_runSpinResultData.p_jackpotCoins or {}
    local jackpotWinCoins = 0
    for _jpName,_jpWinCoins in pairs(jackpotList) do
        jackpotWinCoins = jackpotWinCoins + _jpWinCoins
    end
    if 0 >= jackpotWinCoins then
        return
    end
    --最后一次free和存在连线时 不用处理
    if not self:isLastFreeSpin() and not self:checkHasGameEffectType(GameEffect.EFFECT_LINE_FRAME) then
        self.m_iOnceSpinLastWin = jackpotWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{jackpotWinCoins, self.HIT_JACKPOT_EFFECT})
        self:sortGameEffects()
    else
        local lineWinCoins  = self:getClientWinCoins()
        self.m_iOnceSpinLastWin = lineWinCoins + jackpotWinCoins
    end

    if not self.m_bProduceSlots_InFreeSpin or self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        --刷新顶栏
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end
end

--[[
    jackpot赢钱
]]
function CodeGameScreenPenguinsBoomsMachine:showJackpotWinView(jackpotType,rewardData,func)
    local params = {
        jackpotType = jackpotType,
        winCoin = rewardData.jackpotWinAmount,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    }
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpotView_start)
    local view = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsJackPotWinView",params)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPenguinsBoomsMachine:MachineRule_ResetReelRunData()
    --预告重置快滚
    if self.m_isPlayWinningNotice then
        self:yugaoResetReelRunData()
        return
    end

    --jackpot修改快滚
    self:jackpotTriggerReelRun()
end

function CodeGameScreenPenguinsBoomsMachine:jackpotTriggerReelRun()
    if self.m_isTriggerUpReels then
        return
    end
    --已经存在快滚了
    for iCol=1,self.m_iReelColumnNum-1 do
        if self:getNextReelIsLongRun(iCol + 1) then
            return
        end
    end

    --jackpot快滚
    local jackPotSymbolList = {
        self.SYMBOL_BONUS_GRAND,
        self.SYMBOL_BONUS_MAJOR,
        self.SYMBOL_BONUS_MEGA,
        self.SYMBOL_BONUS_MINOR,
        self.SYMBOL_BONUS_MINI,
    }
    local longRunIndex  = 0
    local reelRunSymbol = nil
    for iCol=2,self.m_iReelColumnNum do
        local maxCount = 0
        local jackpotSymbol = self.SYMBOL_BONUS_MINI
        if not reelRunSymbol then
            for i,_jackpotSymbolType in ipairs(jackPotSymbolList) do
                local jackpotCount = self:getSymbolCountByCol(_jackpotSymbolType, iCol-1)
                if jackpotCount > maxCount then
                    maxCount = jackpotCount
                    jackpotSymbol = _jackpotSymbolType
                end
            end
        else
            maxCount = self:getSymbolCountByCol(reelRunSymbol, iCol-1)
        end
        
        --触发快滚
        if maxCount >= 2 then
            reelRunSymbol        = jackpotSymbol
            self.m_reelRunSymbol = jackpotSymbol
            longRunIndex = longRunIndex + 1
            local reelRunData  = self.m_reelRunInfo[iCol]
            local columnData   = self.m_reelColDatas[iCol]
            local colHeight    = columnData.p_slotColumnHeight
            
            local runLen = 0
            
            runLen = self:getLongRunLen(iCol, longRunIndex)
            local lastReelRunData = self.m_reelRunInfo[iCol - 1]
            if 1 == longRunIndex then
                lastReelRunData:setNextReelLongRun(true)
            end
            reelRunData:setReelLongRun(true)
            reelRunData:setReelRunLen(runLen)
            --新滚动
            if self.m_baseReelNodes and self.m_baseReelNodes[iCol] then
                local reelNode = self.m_baseReelNodes[iCol]
                reelNode:setRunLen(runLen)
            end
            
            --加速移动
            -- local parentData = self.m_slotParents[iCol]
            -- parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end    
end


function CodeGameScreenPenguinsBoomsMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenPenguinsBoomsMachine.super.playEffectNotifyNextSpinCall( self )
    --升行玩法也当作reSpin处理
    if not self.m_handerIdAutoSpin then
        if self.m_isTriggerUpReels then
            self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(
                function(delay)
                    self:normalSpinBtnCall()
                end,
                0.5,
                self:getModuleName()
            )
        end
    end
    --提示按钮的点击状态
    if self.m_ruleTips:checkClickStatus() then
        self.m_ruleTips:setTipTouchEnabled(true)
    end
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end
function CodeGameScreenPenguinsBoomsMachine:getWinCoinTime()
    local time = CodeGameScreenPenguinsBoomsMachine.super.getWinCoinTime(self)
    if self.m_isTriggerUpReels then
        time = 0
    end
    return time
end

function CodeGameScreenPenguinsBoomsMachine:setGameEffectOrder()
    if self.m_gameEffects == nil then
        return
    end

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        --respin要在free之前触发
        if effectData.p_effectType == GameEffect.EFFECT_RESPIN then 
            effectData.p_effectOrder = self.PenguinsBoomsReSpinEffectOrder
        elseif effectData.p_effectType ~= GameEffect.EFFECT_SELF_EFFECT then
            effectData.p_effectOrder = effectData.p_effectType
        end
    end
end

function CodeGameScreenPenguinsBoomsMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    --收集栏层级
    if not self:isPenguinsBoomsUpRow() then
        self.m_collectBar:setLocalZOrder(self.PenguinsBoomsReelNodeOrder.BaseCollectBar)
    end
    --快滚后没有触发玩法的音效
    self:playPenguinsBoomsNotTriggerSound()

    self:playKuLouReelDownAnim(function()
        CodeGameScreenPenguinsBoomsMachine.super.slotReelDown(self)
    end)
end

function CodeGameScreenPenguinsBoomsMachine:checkTriggerOrInSpecialGame(func)
    if self:getCurrSpinMode() == FREE_SPIN_MODE or 
        self:getCurrSpinMode() == RESPIN_MODE or 
        self:getCurrSpinMode() == AUTO_SPIN_MODE or 
        self:checktriggerSpecialGame() or
        self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE or self:isPenguinsBoomsUpRow() then

        self:removeSoundHandler() -- 移除监听
    else
        if func then
            func()
        end
    end
end
--播放快滚但是没触发玩法的音效
function CodeGameScreenPenguinsBoomsMachine:playPenguinsBoomsNotTriggerSound()
    local bQuickRun = false
    for iCol=1,self.m_iReelColumnNum-1 do
        if self:getNextReelIsLongRun(iCol + 1) then
            bQuickRun = true
            break
        end
    end
    if not bQuickRun then
        return
    end

    --free
    if self:isPenguinsBoomsScatterSymbol(self.m_reelRunSymbol) then
        local features = self.m_runSpinResultData.p_features or {}
        if features[2] ~= SLOTO_FEATURE.FEATURE_FREESPIN then
            gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_scatter_notTrigger)
        end
    --jackpot
    else
        local jackpotWinCoins = self.m_runSpinResultData.p_jackpotCoins or {}
        if not next(jackpotWinCoins) or self.m_isTriggerUpReels then
            gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_jackpot_notTrigger)
        end
    end
end
function CodeGameScreenPenguinsBoomsMachine:playKuLouReelDownAnim(_fun)
    local curBet      = globalData.slotRunData:getCurTotalBet()
    local lockColData = self.m_collectBar:getLockColData(curBet, nil)
    local delayTime = 0
    if #lockColData >= self.m_iReelColumnNum then
        delayTime = 21/60
    end
    --收集栏的透明度 
    self.m_collectBar:changeBgSpriteOpacity(false)
    --刷新收集条的期待
    self.m_collectBar:upDateKuLouIdleAnim(curBet)
    
    self:delayCallBack(delayTime, _fun)
end

---
--判断改变freespin的状态
function CodeGameScreenPenguinsBoomsMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --检测是否触发了升行玩法(升行玩法不算在free次数内)
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if globalData.slotRunData.freeSpinCount == 0 and(selfData and not selfData.addBonusTrigger) then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
            end
        end
    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
        end
    end
end

function CodeGameScreenPenguinsBoomsMachine:checkChangeFsCount()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount ~= nil and globalData.slotRunData.freeSpinCount > 0 then
        
        if not self.m_isTriggerUpReels then
            --减少free spin 次数
            globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            globalData.userRate:pushFreeSpinCount(1)
        end
        
    end
end

---
--保留本轮数据
function CodeGameScreenPenguinsBoomsMachine:keepCurrentSpinData()
    self:insterReelResultLines()

    --TODO   wuxi update on
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount

    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen do
        local value = self.m_vecSymbolEffectType[i]
        local effectData = GameEffectData.new()
        effectData.p_effectType = value
        --                                effectData.p_effectData = data
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

function CodeGameScreenPenguinsBoomsMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end
--[[
    线数框
]]
function CodeGameScreenPenguinsBoomsMachine:upDateLineNodeShow(_bReSpin)
    local baseLineNode = self:findChild("Node_40xian")
    local reSpinLineNode = self:findChild("Node_60xian")
    baseLineNode:setVisible(not _bReSpin)
    reSpinLineNode:setVisible(_bReSpin)
end
--[[
    reSpin背景音乐
        保证当前背景音乐的播放进度不会重置
        等待reSpin玩法结束时播放对应背景不会重新开始
]]
function CodeGameScreenPenguinsBoomsMachine:playPenguinsBoomsReSpinMusic()
    -- self:resetMusicBg(nil, PublicConfig.music_PenguinsBooms_reSpin)
    -- self:setMaxMusicBGVolume()

    local globalBgId = gLobalSoundManager:getBGMusicId()
    if globalBgId ~= self.m_currentMusicId then
        return
    end
    
    gLobalSoundManager:pauseBgMusic()

    if nil ~= self.m_reSpinSoundId then
        self:setPenguinsBoomsReSpinMusicVolume(1)
    else
        self.m_reSpinSoundId = gLobalSoundManager:playSound(PublicConfig.music_PenguinsBooms_reSpin, true)
    end
end
function CodeGameScreenPenguinsBoomsMachine:setPenguinsBoomsReSpinMusicVolume(_volume)
    if nil ~= self.m_reSpinSoundId then
        gLobalSoundManager:setSoundVolumeByID(self.m_reSpinSoundId, _volume)
    end
end
function CodeGameScreenPenguinsBoomsMachine:stopPenguinsBoomsReSpinMusic(_bFreeOver)
    --free模式内 reSpin不会中断只会暂时音量为0
    local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    if not bFree or _bFreeOver then
        if nil ~= self.m_reSpinSoundId then
            gLobalSoundManager:stopAudio(self.m_reSpinSoundId)
            self.m_reSpinSoundId = nil
        end
    else
        self:setPenguinsBoomsReSpinMusicVolume(0)
    end
end
function CodeGameScreenPenguinsBoomsMachine:noticCallBack_pauseSound(_params)
    local pauseSoundId =  gLobalSoundManager.m_bigWinPasueId
    if nil ~= self.m_reSpinSoundId and pauseSoundId == self.m_currentMusicId then
        self:setPenguinsBoomsReSpinMusicVolume(0)
    end
end
-- 恢复接口一般由系统活动弹板关闭接口调起
function CodeGameScreenPenguinsBoomsMachine:noticCallBack_resumeSound(_params)
    local resumeSoundId =  gLobalSoundManager.m_bigWinPasueId
    if resumeSoundId == self.m_currentMusicId then
        if nil ~= self.m_reSpinSoundId then
            gLobalSoundManager:setSoundVolumeByID(resumeSoundId, 0)
            self:setPenguinsBoomsReSpinMusicVolume(1)
        elseif self:isPenguinsBoomsUpRow() then
            self:playPenguinsBoomsReSpinMusic()
        end
    end
end
-- 直接播放接口 可能由系统弹板结束时 直接调用播放之前存储的关卡背景音乐
function CodeGameScreenPenguinsBoomsMachine:noticCallBack_playBgMusic(_params)
    local bgMusicName = _params[2]
    if "string" ~= type(bgMusicName) then
        return
    end
    --[[
        PenguinsBoomsSounds/music_PenguinsBooms_base.mp3
        PenguinsBoomsSounds/music_PenguinsBooms_free.mp3
    ]]
    local levelName   = self:getModuleName()
    if #bgMusicName < #levelName then
        --播放的不是关卡背景音乐 切掉reSpin
        self:stopPenguinsBoomsReSpinMusic()
        return
    end
    local sPrefix = string.sub(bgMusicName, 0, #levelName)
    if levelName ~= sPrefix then
        --播放的不是关卡背景音乐 切掉reSpin
        self:stopPenguinsBoomsReSpinMusic()
        return
    end
    --在reSpin内直接播放关卡的背景音乐时 切掉
    self.m_currentMusicId = gLobalSoundManager.m_bgMusicId
    if self:isPenguinsBoomsUpRow() then
        self:playPenguinsBoomsReSpinMusic()
    end
end
---
-- 触发respin 玩法
--
function CodeGameScreenPenguinsBoomsMachine:showEffect_Respin(effectData)
    --spin不扣钱
    self:setSpecialSpinStates(true)
    --触发升行玩法状态
    self.m_isTriggerUpReels = true
    self.m_reSpinDelayReelDownTime = 2.75
    -- self:delayCallBack(0.5, function()
        -- 取消连线展示
        self:clearWinLineEffect()
        self:stopLinesWinSound()

        --炸弹飞向中央炸出reSin提示流程
        self:playReSpinTipAnim(function()
            --可以spin
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    -- end)
    
    return true
end
function CodeGameScreenPenguinsBoomsMachine:playReSpinTipAnim(_fun)
    local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    -- 重置背景音乐
    self:playPenguinsBoomsReSpinMusic()
    --收集满触发
    self.m_collectBar:setLocalZOrder(self.PenguinsBoomsReelNodeOrder.ReSpinCollectBar)
    self.m_collectBar:playCollectTriggerAnim()
    
    if bFree then
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_bonus_freeActionframe)
    else
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_bonus_actionframe)
    end
    --将升行开始延时到触发时间线的放大效果开始时
    -- self:delayCallBack(21/60, function()
        --角色挥->角色下降
        local roleSpine = self:getCurRoleSpine(nil)
        roleSpine:playAscendRowAninm(nil)
        self:delayCallBack(15/30, function()
            --升行      
            self:changeReelSize(function()
            end)
            --重置棋盘上所有bonus图标的拖尾
            self:resetBonusTuoweiAnim()
        end)
    -- end)
   
    self:delayCallBack(35/30, function()
        --点燃引线->待触发
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_bonus_fly)
        -- gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_bonus_waitTrigger)
        -- 不要引燃时间线延时了
        -- self.m_collectBar:playBombWaitTriggerAnim()
        -- self:delayCallBack(21/30, function()
            --5个炸弹飞向中间炸出reSpin提示
            local flyTime = 30/30
            local endPos = util_convertToNodeSpace(self.m_reSpinTip, self.m_effectNode)
            local curBet = globalData.slotRunData:getCurTotalBet()
            local collectData = self.m_collectBar:getCollectDataByBetValue(curBet)
            for iCol=1,self.m_iReelColumnNum do
                local lockBonus = self.m_collectBar:getItemByColIndex(iCol) 
                local startPos  = util_convertToNodeSpace(lockBonus, self.m_effectNode)
                --临时图标
                local bonusSymbol = self:createPenguinsBoomsTempSymbol({machine = self, symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,})
                self.m_effectNode:addChild(bonusSymbol)
                bonusSymbol:setPosition(startPos)
                --飞行
                -- bonusSymbol:runAnim("zhunbei", false, function()
                    bonusSymbol:runAnim("fly1", false)
                    bonusSymbol:runAction(cc.Sequence:create(
                        cc.MoveTo:create(flyTime, endPos),
                        cc.CallFunc:create(function()
                            bonusSymbol:removeTempSlotsNode()
                        end)
                    ))
                -- end)
            end
            -- local delayTime = 6/30 + flyTime
            local delayTime = flyTime
            self:delayCallBack(delayTime, function()
                --reSpin提示弹板
                gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_reSpinTip_start)
                self.m_reSpinTip:setVisible(true)
                self.m_reSpinTip:runCsbAction("auto", false, function()
                    self.m_reSpinTip:setVisible(false)
                end)
            end)
            --炸弹只要飞了就可以下一步spin了
            _fun()
        -- end)
    end)
end
function CodeGameScreenPenguinsBoomsMachine:resetBonusTuoweiAnim()
    for iCol=1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        reelNode:resetAllRollNodeZOrder()
    end
    self:baseReelSlotsNodeForeach(function(_slotsNode, _iCol, _iRow)
        if _slotsNode then
            if self:isPenguinsBoomsH1Symbol(_slotsNode.p_symbolType) then
                self:playSymbolBreathingAnim(_slotsNode)
            end
        end
    end)
end
--------------升行相关-------------------------------------
--[[
    变更裁切层大小
]]
function CodeGameScreenPenguinsBoomsMachine:changeReelSize(func)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_upRow)
    self.m_bigReelNodeLayer:updatePenguinsBoomsClipNodePosY(true)

    local endCount = 0
    local endFunc = function(  )
        endCount = endCount + 1
        if endCount < self.m_iReelColumnNum then
            return
        end
        --停止计时器
        self.m_changeSizeNode:unscheduleUpdate()
        --切换线数
        self:upDateLineNodeShow(true)
        if type(func) == "function" then
            func()
        end
    end
    
    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        local targetSymbolCount = MAX_ROW_COUNT
        local targetHight = self.m_SlotNodeH * targetSymbolCount

        reelNode:changClipSizeToTarget(targetHight,CHANGE_SPEED,endFunc)
    end

    self.m_iReelRowNum = MAX_ROW_COUNT
    self:changeTouchSpinLayerSize()
    self:resetValidSymbolMatrixArray(self.m_iReelRowNum)

    self.m_changeSizeNode:onUpdate(function(dt)
        --[[
            bug-如果这个地方跳出 使得升行和滚动同时开始 会导致数据互相影响spin上弹后无法继续滚动
            BaseReelNode:addJumoActionAfterReel 
                if endCount >= #self.m_rollNodes then
        ]]
        -- if globalData.slotRunData.gameRunPause then
        --     return
        -- end

        local offset = math.floor(CHANGE_SPEED * dt)
        

        for iCol = 1,self.m_iReelColumnNum do
            local reelNode = self.m_baseReelNodes[iCol]
            reelNode:changeReelSize(dt)
        end

        self:changeUISize(offset)
    end)
    
end

--[[
    重置裁切层大小
]]
function CodeGameScreenPenguinsBoomsMachine:resetReelSize(func)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_downRow)
    self.m_bigReelNodeLayer:updatePenguinsBoomsClipNodePosY(false)

    local endCount = 0
    local endFunc = function()
        endCount = endCount + 1
        if endCount < self.m_iReelColumnNum then
            return
        end
        --停止计时器
        self.m_changeSizeNode:unscheduleUpdate()
        --切换线数
        self:upDateLineNodeShow(false)
        if type(func) == "function" then
            func()
        end
    end

    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        local targetHight = self.m_SlotNodeH * MIN_ROW_COUNT
        reelNode:changClipSizeToTarget(targetHight,CHANGE_SPEED,endFunc)
    end

    self.m_iReelRowNum = MIN_ROW_COUNT
    self:changeTouchSpinLayerSize()
    self:resetValidSymbolMatrixArray(self.m_iReelRowNum)

    self.m_changeSizeNode:onUpdate(function(dt)
        if globalData.slotRunData.gameRunPause then
            return
        end

        local offset = math.floor(CHANGE_SPEED * dt)
        for iCol = 1,self.m_iReelColumnNum do
            local reelNode = self.m_baseReelNodes[iCol]
            reelNode:changeReelSize(dt)
        end

        self:changeUISize(-offset)
    end)
end

--[[
    变更边框大小
]]
function CodeGameScreenPenguinsBoomsMachine:changeUISize(offset)
    local reelNode = self.m_baseReelNodes[1]
    for iCol = 1,self.m_iReelColumnNum do
        --base背景
        local reelBg_base = self:findChild("base_reel_"..(iCol - 1))
        --free背景
        local reelBg_free = self:findChild("free_reel_"..(iCol - 1))
        if not reelNode.m_isChangeEnd then
            local size = reelBg_base:getContentSize()
            local newSize = CCSizeMake(size.width,size.height + offset)
            reelBg_base:setContentSize(newSize)
            reelBg_free:setContentSize(newSize)
        else
            local size = reelBg_base:getContentSize()
            local newSize = CCSizeMake(size.width,reelNode.m_reelSize.height)
            reelBg_base:setContentSize(newSize)
            reelBg_free:setContentSize(newSize)
        end
    end

    --黑背景
    local Panel_1 = self:findChild("Panel_1")
    if not reelNode.m_isChangeEnd then
        local size = Panel_1:getContentSize()
        local newSize = CCSizeMake(size.width,size.height + offset)
        Panel_1:setContentSize(newSize)
    else
        local size   = Panel_1:getContentSize()
        local newSize = CCSizeMake(size.width, reelNode.m_reelSize.height + 10)
        Panel_1:setContentSize(newSize)
    end

    --左右边框
    local reel_left = self:findChild("sheng_zuo")
    local reel_right = self:findChild("sheng_you")
    if not reelNode.m_isChangeEnd then
        local size = reel_left:getContentSize()
        local newSize = CCSizeMake(size.width,size.height + offset)
        reel_left:setContentSize(newSize)
        reel_right:setContentSize(newSize)
    else
        local size = reel_left:getContentSize()
        local height = offset > 0 and 100 + self.m_SlotNodeH * 2 or 100
        local newSize = CCSizeMake(size.width,height)
        reel_left:setContentSize(newSize)
        reel_right:setContentSize(newSize)
    end

    --左右上边角
    local upFrameNode =self:findChild("Node_upFrame") 
    if not reelNode.m_isChangeEnd then
        local curPosY = upFrameNode:getPositionY()
        upFrameNode:setPositionY(curPosY + offset)
        self.m_baseFreeSpinBar:setPositionY(self.m_baseFreeSpinBar:getPositionY() + offset)
    else
        local nextPosY = offset > 0 and self.m_SlotNodeH * 2 or 0
        upFrameNode:setPositionY(nextPosY)
        local freeBarEndPosY = offset > 0 and self.m_SlotNodeH * 2 or 0
        self.m_baseFreeSpinBar:setPositionY(freeBarEndPosY)
    end
end

--[[
    变更点击区域大小
]]
function CodeGameScreenPenguinsBoomsMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
    end
end

function CodeGameScreenPenguinsBoomsMachine:resetValidSymbolMatrixArray(maxRow)
    self.m_stcValidSymbolMatrix = table_createTwoArr(maxRow, self.m_iReelColumnNum, TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE)
end

--------------升行相关  end-------------------------------------


function CodeGameScreenPenguinsBoomsMachine:playSymbolBreathingAnim(_slotsNode)
    _slotsNode:runAnim("idleframe2", true)
end
--[[
    服务器交互的额外数据
    每列最多收集两个,如果玩家切换到没有spin过的bet,每个betLevel固定数量给随机位置发bonus
]]
function CodeGameScreenPenguinsBoomsMachine:getSendMessageData_bonusSelect()
    local bonusSelect = {}
    local curBet = globalData.slotRunData:getCurTotalBet()
    local collectData = self.m_collectBar:getCollectDataByBetValue(curBet)
    local sMsg = string.format("[CodeGameScreenPenguinsBoomsMachine:updateLockBonusData] %d", curBet)
    for iCol=1,self.m_iReelColumnNum do
        local sKey         = tostring(iCol-1)
        local curLockCount = collectData[sKey] or 0
        bonusSelect[iCol] = curLockCount
        sMsg = string.format("%s %d=%d", sMsg, iCol, curLockCount)
    end
    
    util_printLog(sMsg, true)
    return bonusSelect
end
-- 给 messageData 插入数据
function CodeGameScreenPenguinsBoomsMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    self:updateJackpotList()
    self:setSpecialSpinStates(false )

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg         = MessageDataType.MSG_SPIN_PROGRESS,
        data        = self.m_collectDataList,
        jackpot     = self.m_jackpotList,
        betLevel    = self.m_iBetLevel,
        bonusSelect = self:getSendMessageData_bonusSelect(),
    }
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

--[[
	一些工具
]]
function CodeGameScreenPenguinsBoomsMachine:showLineFrame()
    local lineWinCoins  = self:getClientWinCoins()
    self.m_iOnceSpinLastWin = lineWinCoins
    local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + lineWinCoins)

    CodeGameScreenPenguinsBoomsMachine.super.showLineFrame(self)
end
function CodeGameScreenPenguinsBoomsMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    -- 新增:触发了两个jackpot玩法时刷新顶栏放在jackpot弹板结束时
    if self:checkHasPenguinsBoomsSelfEffect(self.HIT_JACKPOT_EFFECT) or 
        self:checkHasPenguinsBoomsSelfEffect(self.EFFECT_Bomb_JackpotTrigger) then

        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end
function CodeGameScreenPenguinsBoomsMachine:isLastFreeSpin()
    local collectLeftCount  = globalData.slotRunData.freeSpinCount
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
    local bLast = self.m_bProduceSlots_InFreeSpin and collectLeftCount ~= collectTotalCount and 0 == collectLeftCount
    return bLast 
end
--获取底栏金币
function CodeGameScreenPenguinsBoomsMachine:getCurBottomWinCoins()
    local winCoin = 0

    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
        if "" == sCoins then
            return winCoin
        end
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
--更新底栏金币
function CodeGameScreenPenguinsBoomsMachine:updateBottomUICoins( _beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end
--设置特殊图标相对收集栏的层级
function CodeGameScreenPenguinsBoomsMachine:setPenguinsBoomsSpecialSymbolOrder(_symbolNode, _baseOrder)
    local symbolType = _symbolNode.p_symbolType
    local iCol = _symbolNode.p_cloumnIndex
    local iRow = _symbolNode.p_rowIndex
    if not symbolType or not iCol or not iRow then
        return
    end
    --提层
    if _symbolNode:getParent() ~= self.m_clipParent then
        util_setSymbolToClipReel(self, iCol, iRow, symbolType, 0)
    end
    local symbolOrder = _baseOrder + iCol * 10 - iRow
    _symbolNode.p_showOrder = symbolOrder
    _symbolNode.m_showOrder = symbolOrder
    _symbolNode:setLocalZOrder(symbolOrder)
end
--normal-jackpot 根据行数区分层级
function CodeGameScreenPenguinsBoomsMachine:setScatterJackpotNormalOrder(_symbolNode)
    local symbolType = _symbolNode.p_symbolType
    local iRow       = _symbolNode.p_rowIndex
    local bTop       = iRow > 2
    if self:isPenguinsBoomsScatterSymbol(symbolType) then
        local baseOrder = bTop and self.PenguinsBoomsReelNodeOrder.NormalScatterTop or self.PenguinsBoomsReelNodeOrder.NormalScatter
        self:setPenguinsBoomsSpecialSymbolOrder(_symbolNode, baseOrder)
    elseif self:isPenguinsBoomsJackpotSymbol(symbolType) then
        local baseOrder = bTop and self.PenguinsBoomsReelNodeOrder.NormalJackpotTop or self.PenguinsBoomsReelNodeOrder.NormalJackpot
        self:setPenguinsBoomsSpecialSymbolOrder(_symbolNode, baseOrder)
    end
end
function CodeGameScreenPenguinsBoomsMachine:isPenguinsBoomsJackpotSymbol(_symbolType)
    if _symbolType == self.SYMBOL_BONUS_GRAND or
        _symbolType == self.SYMBOL_BONUS_MAJOR or
        _symbolType == self.SYMBOL_BONUS_MEGA or
        _symbolType == self.SYMBOL_BONUS_MINOR or
        _symbolType == self.SYMBOL_BONUS_MINI then

        return true
    end

    return false
end
function CodeGameScreenPenguinsBoomsMachine:isPenguinsBoomsH1Symbol(_symbolType)
    if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        return true
    end
    return false
end
function CodeGameScreenPenguinsBoomsMachine:isPenguinsBoomsScatterSymbol(_symbolType)
    return _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER
end
--震动
function CodeGameScreenPenguinsBoomsMachine:shakeReelNode(_params)
    _params = _params or {}
    --随机幅度
    local changeMin     = 1
    local changeMax     = 5
    local shakeTimes    = _params.shakeTimes or 4
    local shakeOnceTime = _params.shakeOnceTime or 0.2
    local shakeNodeName = _params.shakeNodeName or {}

    for i,_nodeName in ipairs(shakeNodeName) do
        local shakeNode = self:findChild(_nodeName)
        local oldPos = cc.p(shakeNode:getPosition())
        local changePosY = math.random(changeMin, changeMax)
        local changePosX = math.random(changeMin, changeMax)
        local actList = {}
        for ii=1,shakeTimes do
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x + changePosX, oldPos.y + changePosY)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x, oldPos.y)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x - changePosX, oldPos.y - changePosY)))
            table.insert(actList, cc.MoveTo:create(shakeOnceTime / 4, cc.p(oldPos.x, oldPos.y)))
        end
        table.insert(actList, cc.CallFunc:create(function()
            shakeNode:setPosition(oldPos)
        end))
        shakeNode:runAction(cc.Sequence:create(actList))
    end
end
-- 循环处理轮盘小块
function CodeGameScreenPenguinsBoomsMachine:baseReelSlotsNodeForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if isJumpFun then
                return
            end
        end
    end
end
function CodeGameScreenPenguinsBoomsMachine:changePenguinsBoomsSymbolType(_slotsNode, _symbolType)
    self:changeSymbolType(_slotsNode, _symbolType)
end
--创建临时小块
function CodeGameScreenPenguinsBoomsMachine:createPenguinsBoomsTempSymbol(_initData)
	--[[
		_initData = {
            machine    = self,
			symbolType = 0,
			iCol       = 1,
			iRow       = 1,
		}
	]]
	_initData = _initData or {}
	_initData.machine = self

	local tempSymbol = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsTempSymbol", _initData)
	tempSymbol:changeSymbolCcb(_initData.symbolType)

	return tempSymbol
end
--获取小块数量
function CodeGameScreenPenguinsBoomsMachine:getSymbolCountByCol(_symbolType, _iCol)
    local count = 0
    local reel = self.m_runSpinResultData.p_reels
    for _lineIndex,_lineData in ipairs(reel) do
        for iCol,_symbol in ipairs(_lineData) do
            if iCol <= _iCol and _symbol == _symbolType then
                count = count + 1
            end
        end
    end

    return count
end

function CodeGameScreenPenguinsBoomsMachine:checkHasPenguinsBoomsSelfEffect(_selfEffectType)
    for i,_effectData in ipairs(self.m_gameEffects) do
        if _effectData.p_selfEffectType == _selfEffectType then
            return true
        end
    end
    return false
end

--[[
	重写底层
]]
-- 生成滚动序列( 影响了新滚动的beginIndex索引，干脆拿出来干掉)
function CodeGameScreenPenguinsBoomsMachine:produceReelSymbolList()
end
function CodeGameScreenPenguinsBoomsMachine:getBounsScatterDataZorder(symbolType )
    local symbolOrder = CodeGameScreenPenguinsBoomsMachine.super.getBounsScatterDataZorder(self, symbolType)

    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_MASK
    elseif self:isPenguinsBoomsJackpotSymbol(symbolType) then
        symbolOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    end

    return symbolOrder
end

--快滚
function CodeGameScreenPenguinsBoomsMachine:createReelEffect(col)
    local parent = self:findChild("Node_reelRunEffect")
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    --底层卸载时又释放一遍
    reelEffectNode:retain()
    effectAct:retain()
    parent:addChild(reelEffectNode)
    reelEffectNode:setVisible(false)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    return reelEffectNode, effectAct
end

function CodeGameScreenPenguinsBoomsMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY   = 8

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
            local bgScale = 1
            -- 1.78
            if display.height / display.width >= 1370/768 then
            --1.59
            elseif display.height / display.width >= 1228/768 then
                mainScale = mainScale * 1.23
                mainPosY  = 12
            --1.5
            elseif display.height / display.width >= 960/640 then
                mainScale = mainScale * 1.27
                mainPosY  = 14
            --1.33
            elseif display.height / display.width >= 1024/768 then
                mainScale = mainScale * 1.32
                mainPosY  = 18
            --1.2
            elseif display.height / display.width >= 1.2--[[2176/1812]] then
                mainScale = mainScale * 1.38
                mainPosY  = 20
                bgScale = 1.2
            end

            mainScale = math.min(1, mainScale)
            util_csbScale(self.m_machineNode, mainScale)
            util_csbScale(self.m_gameBg.m_csbNode, bgScale)
            self.m_machineRootScale  = mainScale
            self.m_machineNode:setPositionY(mainPosY)
        end

    end
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenPenguinsBoomsMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    if self:isTriggerBombJackpot() then
        self.m_isAddBigWinLightEffect = false
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenPenguinsBoomsMachine:showBigWinLight(_func)
    
    local soundKey   = string.format("sound_PenguinsBooms_bigWin%d", math.random(1, 2))
    local soundName  = PublicConfig[soundKey]
    gLobalSoundManager:playSound(soundName)

    local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
	--关卡的大赢动画
    local animName = "actionframe"
    if self:isPenguinsBoomsUpRow() then
        animName =  bFree and "actionframe1_sheng" or "actionframe_sheng"
    else
        animName =  bFree and "actionframe1" or "actionframe"
        --角色联动
        local roleSpine = self:getCurRoleSpine(bFree)
        roleSpine:playBigWinAnim(function()
            roleSpine:resetIdleLoopAnim(bFree)
        end)
    end
    self.m_bigWinSpine:setVisible(true)
	util_spinePlay(self.m_bigWinSpine, animName, false)
    --粒子
    self.m_bigWinCsb:setVisible(true)
    local particleNode = self.m_bigWinCsb:findChild("Particle_1")
	particleNode:stopSystem()
	particleNode:setPositionType(0)
	particleNode:setDuration(-1)
	particleNode:resetSystem()
    util_spineEndCallFunc(self.m_bigWinSpine, animName, function()
        particleNode:stopSystem()
        self.m_bigWinSpine:setVisible(false)
        self.m_bigWinCsb:setVisible(false)

        self:stopLinesWinSound()

		if type(_func) == "function" then
            _func()
        end
    end)
    --震屏
    self:shakeReelNode({
        shakeTimes    = math.floor((60/30)/0.1),
        shakeOnceTime = 0.1,
        shakeNodeName = {
            "Node_reel",
            "Node_effect",
        }
    })
end

--[[
    切换bet 修改tips显示
]]
function CodeGameScreenPenguinsBoomsMachine:changeTipsByChangeBets(_curBet)
    local betLevel = self:getPenguinsBoomsBetLevelByValue(_curBet)

    self.m_ruleTips:findChild("m_lb_num"):setString(betLevel)
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenPenguinsBoomsMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_BIGWIN - 1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

return CodeGameScreenPenguinsBoomsMachine