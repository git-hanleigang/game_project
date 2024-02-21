---
-- island li
-- 2019年1月26日
-- CodeGameScreenDragonParadeMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "DragonParadePublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotParentData = require "data.slotsdata.SlotParentData"

local CodeGameScreenDragonParadeMachine = class("CodeGameScreenDragonParadeMachine", BaseNewReelMachine)

CodeGameScreenDragonParadeMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenDragonParadeMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型

CodeGameScreenDragonParadeMachine.FREE_ADDBONUS2VALUE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- free bonus2 添加值effect

CodeGameScreenDragonParadeMachine.SYMBOL_BONUS1 = 94
CodeGameScreenDragonParadeMachine.SYMBOL_BONUS2 = 95
CodeGameScreenDragonParadeMachine.SYMBOL_BONUS3 = 96
CodeGameScreenDragonParadeMachine.SYMBOL_BONUS4 = 97

CodeGameScreenDragonParadeMachine.SYMBOL_WILD2 = 101  --92 三次wild    101 两次wild  102 一次wild
CodeGameScreenDragonParadeMachine.SYMBOL_WILD1 = 102
CodeGameScreenDragonParadeMachine.SYMBOL_FIX_BLANK = 200

CodeGameScreenDragonParadeMachine.m_iReelMinRow = 3
CodeGameScreenDragonParadeMachine.m_iReelMaxRow = 6

CodeGameScreenDragonParadeMachine.m_reconnect = nil
-- 构造函数
function CodeGameScreenDragonParadeMachine:ctor()
    CodeGameScreenDragonParadeMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    self.m_iFreeSpinTimes = 0
    self.m_lightScore = 0
    self.m_isSuperGame = false --是否是bonus4触发
    self.m_triggerRespinChangeBoard = false --触发转换棋盘
    self.m_respinIsChanged = true --respin 双棋盘模式是否转换过轮盘
    self.m_isSecondBoard = false --respin判断当前用的哪个轮盘
    self.m_isLastBoard = false --respin判断当前是否转动，转动的时候如果用的第二个轮盘updateReelGridNode在给bonus赋值时就得+15
 
    self.m_baseWildLockNodes = {}

    self.m_fly_baseTriggerBonus = {}
    self.m_allBetData = {}
    self.m_lastCornucopiaIndex = 1 --上次聚宝盆状态

    self.m_respinLastStoreIcons = {}

    self.m_respinRightCount_1 = 0 --计数板计数
    self.m_respinRightCount_2 = 0
    self.m_respinMidCount_1 = 0
    self.m_respinMidCount_2 = 0

    self.m_freeBonus2List = {}
    self.m_freeBonus2ListIndex = 1
    self.m_freeMidCount = 0

    self.m_fly_baseTriggerBonus = {}
    self.m_fly_baseTriggerBonusIndex = 1
    self.m_fly_baseTriggerBonusScore = 0

    self.m_respinIsQuickRun = false --快滚拉伸

    self.m_baseWildResetDelayTime = 0

    self.m_lineChangeTime = 0 --连线开始时间
    self.m_respinCollectOnceTotalScore = 0

    self.m_quickrun_playWildSound = false

    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
    --init
    self:initGame()
end

function CodeGameScreenDragonParadeMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("DragonParadeConfig.csv", "LevelDragonParadeConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenDragonParadeMachine:enterLevel()
    self.m_reconnect = true
    CodeGameScreenDragonParadeMachine.super.enterLevel(self)
end

function CodeGameScreenDragonParadeMachine:initHasFeature()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_FREESPIN and selfData.superGame then
        self.m_iReelRowNum = self.m_iReelMaxRow
    else
        self.m_iReelRowNum = self.m_iReelMinRow
    end

    if self.m_iReelRowNum > self.m_iReelMinRow then
        self:changeReelData()
    end
    CodeGameScreenDragonParadeMachine.super.initHasFeature(self)
end

function CodeGameScreenDragonParadeMachine:requestSpinResult()
    self.m_reconnect = false
    CodeGameScreenDragonParadeMachine.super.requestSpinResult(self)
end

function CodeGameScreenDragonParadeMachine:getModuleName()
    return "DragonParade"  
end

function CodeGameScreenDragonParadeMachine:formatCoins( coins, obligate, notCut, normal, noRounding, useRealObligate )
    return util_formatCoins(coins, obligate, notCut, true, true, useRealObligate)
end

function CodeGameScreenDragonParadeMachine:initUI()

    self.m_baseWildLockNodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local posIdx = self:getPosReelIdx(iRow, iCol)
            self.m_baseWildLockNodes[posIdx] = cc.Node:create()
            self.m_clipParent:addChild(self.m_baseWildLockNodes[posIdx], REEL_SYMBOL_ORDER.REEL_ORDER_2 + posIdx)
        end
    end


    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    --jackpot
    self.m_jackpotBar = util_createView("CodeDragonParadeSrc.DragonParadeJackPotBarView", self)
    self:findChild("Node_Jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:runCsbAction("idle", true)

    --free 次数板 用的respinbar
    self.m_freeTimesBar = util_createView("CodeDragonParadeSrc.DragonParadeRespinBarView")
    self:findChild("Node_bar"):addChild(self.m_freeTimesBar)
    --free bonus2Win
    self.m_freeBonus2WinBar = util_createAnimation("DragonParade_Bonus2ui.csb")
    self:findChild("Node_FG_left"):addChild(self.m_freeBonus2WinBar)
    --free bonus2Win super
    self.m_freeBonus2WinBarSuper = util_createAnimation("DragonParade_Bonus2ui.csb")
    self:findChild("Node_FG_left_Super"):addChild(self.m_freeBonus2WinBarSuper)
    --free right show
    self.m_freeRightBar = util_createAnimation("DragonParade_FG_you.csb")
    self:findChild("Node_FG_right"):addChild(self.m_freeRightBar)
    --free right show super
    self.m_freeRightBarSuper = util_createAnimation("DragonParade_FG_you.csb")
    self:findChild("Node_FG_right_Super"):addChild(self.m_freeRightBarSuper)
    --free mid TotalBonus2 Prize
    self.m_freeBonus2PrizeBar = util_createView("CodeDragonParadeSrc.DragonParadeFreeMidView", self)
    self:findChild("Node_FG_mid"):addChild(self.m_freeBonus2PrizeBar)
    --free mid TotalBonus2 Prize Super
    self.m_freeBonus2PrizeBarSuper = util_createView("CodeDragonParadeSrc.DragonParadeFreeMidView", self)
    self:findChild("Node_FG_mid_Super"):addChild(self.m_freeBonus2PrizeBarSuper)

    --base left
    self.m_baseLeftBar = util_createView("CodeDragonParadeSrc.DragonParadeWildLockNumView", self)
    self:findChild("Node_base_zuo"):addChild(self.m_baseLeftBar)
    --base right
    self.m_baseRightBar = util_createAnimation("DragonParade_base_you.csb")
    self:findChild("Node_base_you"):addChild(self.m_baseRightBar)
    self.m_baseRightBar:runCsbAction("idle", true)
    --base mid 聚宝盆
    self.m_baseMidBar = util_createView("CodeDragonParadeSrc.DragonParadeCornucopiaView", self)
    self:findChild("Node_jvbaopen"):addChild(self.m_baseMidBar)

    --触发收集时 增长计数板
    self.m_baseBonusCollectAddBar = util_createAnimation("DragonParade_jiaqian.csb")
    self:findChild("Node_jiaqian"):addChild(self.m_baseBonusCollectAddBar)
    self.m_baseBonusCollectAddBar:setVisible(false)

    --背光
    self.m_baseBonusCollectAddBarBg = util_createAnimation("DragonParade_tanban_guang.csb")
    self:findChild("Node_jiaqian_beiguang"):addChild(self.m_baseBonusCollectAddBarBg)
    self.m_baseBonusCollectAddBarBg:setVisible(false)
    self.m_baseBonusCollectAddBarBg:runCsbAction("idleframe", true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_jiaqian_beiguang"), true)

    --winlabel 数字 用于respin结算
    self.m_respinWinLabel = util_createAnimation("DragonParade_yingqian_shuzhi.csb")
    self.m_respinWinLabel:setPosition(self.m_bottomUI.m_normalWinLabel:getPositionX(), self.m_bottomUI.m_normalWinLabel:getPositionY())
    self.m_bottomUI.m_normalWinLabel:getParent():addChild(self.m_respinWinLabel)
    self.m_respinWinLabel:setVisible(false)

    --大赢特效
    self.m_effectBigWin = util_spineCreate("Socre_DragonParade_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_effectBigWin)
    self.m_effectBigWin:setVisible(false)

    --人物
    self.m_juese = util_spineCreate("Socre_DragonParade_juese", true, true)
    self:findChild("Node_juese"):addChild(self.m_juese)
    self.m_juese:setVisible(true)
    util_spinePlay(self.m_juese, "idle", true)
 
    self:changeWinCoinEffectCsb(true)

    self:findChild("Node_24"):setVisible(false)

    self:changeUIBG("base")

    self.m_respinQuickEffect = self:findChild("Node_respineffect")

    --respin棋盘
    self.m_respinBoardRoot = util_createAnimation("DragonParade_ReSpin_qipan.csb")
    self:findChild("Node_ReSpin"):addChild(self.m_respinBoardRoot)
    local board_pos1Y = self.m_respinBoardRoot:findChild("Node_qipan_1"):getPositionY()
    local board_pos2Y = self.m_respinBoardRoot:findChild("Node_qipan_2"):getPositionY()
    local board_posUpY = self.m_respinBoardRoot:findChild("Node_qipan_up_pos"):getPositionY()
    --创建时 1在上       board1 2 对应服务器棋盘数据始终不变的 1对应0~14 2对应15~29
    self.m_respinBoard_1 = util_createView("CodeDragonParadeSrc.DragonParadeRespinBoardView", self, {board_pos1Y = board_pos1Y, board_pos2Y = board_pos2Y, board_posUpY = board_posUpY})
    self.m_respinBoardRoot:findChild("Node_qipan"):addChild(self.m_respinBoard_1) --上节点
    --2对应单棋盘 或双棋盘下面棋盘
    self.m_respinBoard_2 = util_createView("CodeDragonParadeSrc.DragonParadeRespinBoardView", self, {board_pos1Y = board_pos1Y, board_pos2Y = board_pos2Y, board_posUpY = board_posUpY})
    self.m_respinBoardRoot:findChild("Node_qipan"):addChild(self.m_respinBoard_2) --下节点
    self.m_respinBoard_1:setVisible(false)
    self.m_respinBoard_2:setVisible(false)
    self.m_respinBoard_1:setFrontOrder()
    self.m_respinBoard_2:setBackOrder()
    self.m_respinBoard_1:setPos1()
    self.m_respinBoard_2:setPos2()


    --wild收集特效层
    self.m_wildCollecteffectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_wildCollecteffectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    --鞭炮过场
    self.m_trans_explore = util_spineCreate("Socre_DragonParade_guochang", true, true)
    local rootPos = util_convertToNodeSpace(self:findChild("root"),self)
    self:addChild(self.m_trans_explore, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_trans_explore:setPosition(cc.p(rootPos))
    self.m_trans_explore:setVisible(false)

    --孔明灯过场
    self.m_trans_light = util_spineCreate("Socre_DragonParade_guochang2", true, true)
    local rootPos = util_convertToNodeSpace(self:findChild("root"),self)
    self:addChild(self.m_trans_light, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_trans_light:setPosition(cc.p(rootPos))
    self.m_trans_light:setVisible(false)

    self.m_upBottomEffectNode = cc.Node:create()
    self:addChild(self.m_upBottomEffectNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_upBottomEffectNode:setPosition(display.center)
    --聚宝盆特效层
    self.m_cornucopiaNode = cc.Node:create()
    self:addChild(self.m_cornucopiaNode, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_cornucopiaNode:setPosition(cc.p(rootPos))
    --多福多彩结束过场
    self.m_jvbaopenEffect = util_spineCreate("DragonParade_jvbaopen", true, true)
    self:addChild(self.m_jvbaopenEffect, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_jvbaopenEffect:setPosition(cc.p(rootPos))
    self.m_jvbaopenEffect:setVisible(false)

    --大赢特效csb
    self.m_bigWinEffect = util_createAnimation("DragonParade_qipan_effect.csb")
    self:findChild("Node_effectRoot"):addChild(self.m_bigWinEffect)
    self.m_bigWinEffect:setVisible(false)
    self.m_prewinSpineEffect = util_spineCreate("Socre_DragonParade_guochang2", true, true)
    self.m_bigWinEffect:findChild("Node_yugao"):addChild(self.m_prewinSpineEffect)
    self.m_prewinSpineEffect:setVisible(false)

    self.m_bigWinEffectSuper = util_createAnimation("DragonParade_qipan_FG_daying.csb")
    self:findChild("Node_effectRoot"):addChild(self.m_bigWinEffectSuper)
    self.m_bigWinEffectSuper:setVisible(false)

    self.m_collectGameNode = util_createView("CodeDragonParadeSrc.DragonParadeCollectGame", self)
    self:findChild("root"):addChild(self.m_collectGameNode, 10)
    self.m_collectGameNode:setVisible(false)


    self:runJueseIdleAni()

end



function CodeGameScreenDragonParadeMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "DragonParadeSounds/sound_DragonParade_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenDragonParadeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenDragonParadeMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()


    -- self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
    -- self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)

     

    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        local hasBonus = self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
        

        if hasBonus then
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local bonusType =  selfdata.bonusType
            if bonusType then
                if bonusType == "pick"  then
                    self:updateBetLockNode()
                end
            end

        else
            self:updateBetLockNode()
        end
        
    end
    
    if self.m_initSpinData == nil then
        self.m_lastCornucopiaIndex = 1
        self.m_baseMidBar:playIdle( self.m_lastCornucopiaIndex )
    end

    self:initGameUI()
end

function CodeGameScreenDragonParadeMachine:initGameUI()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if self.m_bProduceSlots_InFreeSpin == true then
        self:changeFreeSpinByCount()
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_iFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
            if selfData.superGame then
                self.m_iReelRowNum = self.m_iReelMaxRow
            else
                self.m_iReelRowNum = self.m_iReelMinRow
            end

            if self.m_iReelRowNum > self.m_iReelMinRow then
                self:changeReelData()
                self:changeUIBG("super_free")
            else
                self:changeUIBG("free")
            end

            self:enterFreeInit()
        end
    end

    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        local freeBonus2Win = self:getFreeBonus2TotalValue()
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        local curCoins = math.max(lastWinCoin - freeBonus2Win, 0)
        if curCoins and curCoins > 0 then
            self.m_bottomUI:updateWinCount(util_formatCoins(curCoins,50))
        end
    end

    if selfData.wildStatus then
        self.m_lastCornucopiaIndex = selfData.wildStatus
    end
    self:refreshTopMiddleCoins()
end

function CodeGameScreenDragonParadeMachine:refreshTopMiddleCoins()
    if self.m_lastCornucopiaIndex then
        self.m_baseMidBar:playIdle( self.m_lastCornucopiaIndex )
    end
end

function CodeGameScreenDragonParadeMachine:firstInit()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType then
                if slotNode.p_symbolType == 97 then
                    -- self:setSymbolToClipParent(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
                    slotNode:runAnim("idleframe", true)
                elseif slotNode.p_symbolType == 92 then
                    slotNode:runAnim("idleframe", true)
                    self:setSlotsNodeCornerNum(slotNode, "")
                end
            end
        end
    end
end

function CodeGameScreenDragonParadeMachine:addObservers()
    CodeGameScreenDragonParadeMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self:getCurrSpinMode() == RESPIN_MODE then
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

        local soundName = "DragonParadeSounds/sound_DragonParade_last_win_".. soundIndex .. ".mp3"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "DragonParadeSounds/sound_DragonParade_last_win_free_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)


    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    gLobalNoticManager:addObserver(self,function()
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        -- self:resetMaskLayerNodes()

        self:updateBetLockNode()
    end,ViewEventType.NOTIFY_CLICK_BET_CHANGE)

    --winlabel finish
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         self.m_bottomUI:setUseMachineWinLabel(false)
    --     end,
    --     ViewEventType.NOTIFY_UPDATE_WINLABEL_COMPLETE
    -- )
end

function CodeGameScreenDragonParadeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenDragonParadeMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenDragonParadeMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS1 then
        return "Socre_DragonParade_Bonus1"
    elseif symbolType == self.SYMBOL_BONUS2 then
        return "Socre_DragonParade_Bonus2"
    elseif symbolType == self.SYMBOL_BONUS3 then
        return "Socre_DragonParade_Bonus3"
    elseif symbolType == self.SYMBOL_BONUS4 then
        return "Socre_DragonParade_Bonus4"
    elseif symbolType == self.SYMBOL_FIX_BLANK then
        return "Socre_DragonParade_Blank"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_DragonParade_wild1"
    elseif symbolType == self.SYMBOL_WILD2 then
        return "Socre_DragonParade_wild2"
    elseif symbolType == self.SYMBOL_WILD1 then
        return "Socre_DragonParade_wild3"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenDragonParadeMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenDragonParadeMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

function CodeGameScreenDragonParadeMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenDragonParadeMachine.super.slotReelDown(self)

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        --更新free bar值
        -- self:updateFreeMidBonus2TotalWin()

        if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self.m_freeTimesBar:setCompleteType()
        else
            --更新free次数
            self:changeFreeSpinByCount()
        end
    end
    

    if (self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE) then

        local stickData = self:getStickWildData()
        if stickData.wildLeftTimes and stickData.wildLeftTimes > 0 then
            self.m_baseLeftBar:showView()
            
            if stickData.wildLeftTimes == 3 then
                self.m_baseLeftBar:setNumWithAnim(stickData.wildLeftTimes)
            else
                self.m_baseLeftBar:setNum(stickData.wildLeftTimes)
            end
            
        end
    end
end

----------------------------- 玩法处理 -----------------------------------
--
--单列滚动停止回调
--
function CodeGameScreenDragonParadeMachine:slotOneReelDown(reelCol)    
    CodeGameScreenDragonParadeMachine.super.slotOneReelDown(self,reelCol) 
   
    if reelCol == 5 and (self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE) then
        local stickData = self:getStickWildData()
        local wildIconsPos = stickData.wildPos or {}
        local leftCount = stickData.wildLeftTimes or 0
        --重置三次
        if leftCount == 3 then
            self:updateBaseLockNode()
        end
        

        -- --更新base leftBar
        -- self:updateBaseLeftLockTimes()

    elseif reelCol == 5 and self:getCurrSpinMode() == FREE_SPIN_MODE then

    end

    if (self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE) then
        self:wildCollectReelCol(reelCol)
    end
end

function CodeGameScreenDragonParadeMachine:wildCollectReelCol(reelCol)
    local isDelay = false
    local isPlaySound = false
    for iRow = self.m_iReelRowNum, 1, -1 do
        local node = self:getFixSymbol(reelCol, iRow , SYMBOL_NODE_TAG) 
        if node then
            local posIdx = self:getPosReelIdx(iRow, reelCol)
            if self:isWildSymbol(node.p_symbolType) then
                isDelay = true
                if self:getGameSpinStage() == QUICK_RUN then
                    if self.m_quickrun_playWildSound == false then
                        self.m_quickrun_playWildSound = true
                        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling.mp3")
                        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling_fly.mp3")
                    end
                else
                    if not isPlaySound then
                        isPlaySound = true
                        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling.mp3")
                        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling_fly.mp3")
                    end
                end

                --未锁定 刚出现的小块播动画
                node:runAnim("shouji", false, function()
                    node:runAnim("idle", true)
                end)
                self:wildCollectEffect(posIdx) --飞动画
            else
                if self:checkIsInWildLock(posIdx) then --看锁定位置是否有 目前后端给的 锁定位置滚出的都是92
                    isDelay = true
                    --锁定的播动画
                    if self.m_baseWildLockNodes[posIdx] then
                        local lockNode = self.m_baseWildLockNodes[posIdx]:getChildByTag(1)
                        if lockNode then
                            if self:getGameSpinStage() == QUICK_RUN then
                                if self.m_quickrun_playWildSound == false then
                                    self.m_quickrun_playWildSound = true
                                    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling.mp3")
                                    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling_fly.mp3")
                                end
                            else
                                if not isPlaySound then
                                    isPlaySound = true
                                    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling.mp3")
                                    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling_fly.mp3")
                                end
                            end

                            lockNode:playLockAction("shouji", false)
                            self:wildCollectEffect(posIdx) --飞动画
                        end
                    end
                end
            end
        end
    end

    if isDelay then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local curCornucopiaIndex = self.m_lastCornucopiaIndex
        if selfData.wildStatus then
            curCornucopiaIndex = selfData.wildStatus
        end
        self:delayCallBack(15/30, function (  )
            local isLast = false
            local lastCol = self:getLastWildCol()
            if lastCol ~= 0 and lastCol == reelCol then
                self:wildFlyEnd("last", curCornucopiaIndex)
            else
                self:wildFlyEnd(nil, curCornucopiaIndex)
            end
        end)
    end
end
--是否在wild锁定上
function CodeGameScreenDragonParadeMachine:checkIsInWildLock(posIdx)
    local stickData = self:getStickWildData()
    local wildIconsPos = stickData.wildPos or {}
    
    for i=1,#wildIconsPos do
        local lockPos = wildIconsPos[i]
        if lockPos == posIdx then
            return true
        end
    end
    return false
end
--wild收集特效
function CodeGameScreenDragonParadeMachine:wildCollectEffect(posIdx)
    local flyCoinSpine = util_spineCreate("DragonParade_Wild_shouji", true, true)
    self.m_wildCollecteffectNode:addChild(flyCoinSpine)

    local num = 1
    local pos = self:getRowAndColByPos(posIdx)
    local row = pos.iX
    local col = pos.iY

    num = (4-row)+3*(col-1) --转spine索引
    util_spinePlay(flyCoinSpine, "shouji" .. num, false)
    local spineEndCallFunc = function()
        flyCoinSpine:setVisible(false)
    end
    util_spineEndCallFunc(flyCoinSpine, "shouji" .. num, spineEndCallFunc)
end

function CodeGameScreenDragonParadeMachine:wildFlyEnd(_type, _curCornucopiaIndex)
    local type = _type
    local curCornucopiaIndex = _curCornucopiaIndex
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_buling_fly_end.mp3")

    self.m_baseMidBar:playFeedback( self.m_lastCornucopiaIndex )

    if type and type == "last" then
        self:delayCallBack(25/30, function()
            if self.m_lastCornucopiaIndex ~= curCornucopiaIndex then
                if self.m_lastCornucopiaIndex == 1 and curCornucopiaIndex == 2 then
                    self.m_baseMidBar:playSwitch( "1_2" )
                elseif self.m_lastCornucopiaIndex == 1 and curCornucopiaIndex == 3 then
                    self.m_baseMidBar:playSwitch( "1_3" )
                elseif self.m_lastCornucopiaIndex == 2 and curCornucopiaIndex == 3 then
                    self.m_baseMidBar:playSwitch( "2_3" )
                else
                end
                self.m_lastCornucopiaIndex = curCornucopiaIndex
            end
        end)
    end
end
--获取收集最后列
function CodeGameScreenDragonParadeMachine:getLastWildCol()
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    local runResultData = self.m_runSpinResultData.p_reels

    local maxCol = 0
    local stickData = self:getStickWildData()
    local wildPos = stickData.wildPos or {}
    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolType = runResultData[reelRow - i + 1][j]
            if self:isWildSymbol(symbolType) then
                maxCol = math.max(maxCol, j)
            end

            local posIdx = self:getPosReelIdx(i, j)
            if wildPos[posIdx] then
                maxCol = math.max(maxCol, j)
            end
        end
    end

    return maxCol
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenDragonParadeMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenDragonParadeMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

---
-- 处理spin 返回消息的数据结构
--
function CodeGameScreenDragonParadeMachine:operaSpinResultData(param)
    -- local spinData = param[2]

    -- self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
    -- self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)

    CodeGameScreenDragonParadeMachine.super.operaSpinResultData(self, param)

    local spinData = param[2]
    if spinData then
        --free出现bonus2  后端用的是freemore控制的  直接重置次数
        if spinData.result.features and spinData.result.features[2] == 1 or globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            --更新global数据
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_iFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        end
        

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusType =  selfdata.bonusType
        if bonusType then
            if bonusType == "select"  then
                self.m_isPlayWinningNotice = math.random(0, 100) < 60
            end
        end
    end
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenDragonParadeMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("DragonParadeSounds/music_DragonParade_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            --出现bonus2 图标后 会进行触发free 进到此

            --直接下一步
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            self:resetMusicBg(nil,"DragonParadeSounds/music_DragonParade_Bg_free.mp3")
            if self.m_reconnect then
                self.m_iFreeSpinTimes = 0
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()

            else
                self:showTransFree(nil, function()
                    if self.m_iReelRowNum > self.m_iReelMinRow then
                        self:changeReelData(true)
                        self:changeUIBG("super_free")
                    else
                        self:changeUIBG("free")
                    end
        
                    self:enterFreeInit()
        
                    self.m_iFreeSpinTimes = 0
                    self:triggerFreeSpinCallFun()
                end, function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end
            

            
            
            -- view:findChild("m_lb_line"):setString()
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenDragonParadeMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
    -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    -- self:resetMusicBg() --改
end

function CodeGameScreenDragonParadeMachine:enterFreeInit()
    --更新free bar值
    self:updateFreeLeftBonus2Win()
    self:updateFreeMidBonus2TotalWin()

    local score = self:getFreeBonus2TotalValue()
    self.m_freeMidCount = score

    local isSuper = self:getFreeIsSuper()
    local flyEndNode = nil
    if isSuper then
        flyEndNode = self.m_freeBonus2PrizeBarSuper
    else
        flyEndNode = self.m_freeBonus2PrizeBar
    end
    flyEndNode:runIdle()

    --设置类型
    self.m_freeTimesBar:setChangeType()
end

function CodeGameScreenDragonParadeMachine:showFreeSpinOverView()

    local funcNext = function()
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_freeover_pupup_begin.mp3")
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,
            function()

                self:showTrans(nil, function()
                    if self.m_iReelRowNum > self.m_iReelMinRow then
                        self.m_iReelRowNum = self.m_iReelMinRow
                        self:clearWinLineEffect()
                        if self.m_winSoundsId then
                            gLobalSoundManager:stopAudio(self.m_winSoundsId)
                            self.m_winSoundsId = nil
                        end
                        self:changeReelData()
                    end
                    self:changeUIBG("base")
                    
                    
                    --更新锁定
                    self:updateBetLockNode()
                end, function()
                    self:triggerFreeSpinOverCallFun()
                end)
            end
        )
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},631)

        view:findChild("root"):setScale(self.m_machineRootScale)

        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_click.mp3")
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_freeover_pupup_end.mp3")
        end)

        
        
    end

    local bonusWin = self:getFreeBonus2TotalValue()
    -- if self.m_freeMidCount > 0 then
    if bonusWin > 0 then
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        local isSuper = self:getFreeIsSuper()
        local flyEndNode = nil
        if isSuper then
            flyEndNode = self.m_freeBonus2PrizeBarSuper
        else
            flyEndNode = self.m_freeBonus2PrizeBar
        end
        flyEndNode:runTriggerFinal( )

        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_free_final_bonuswin.mp3")

        self:freeOverFlyBonus2(flyEndNode, function()

            if self.m_winSoundsId then
                gLobalSoundManager:stopAudio(self.m_winSoundsId)
                self.m_winSoundsId = nil
            end
            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = bonusWin / totalBet
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

            local soundName = "DragonParadeSounds/sound_DragonParade_last_win_free_".. soundIndex .. ".mp3"

            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
            

            --通知winlabel
            self.m_bottomUI:setNewWinTime(2)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{bonusWin, false, true})
            self.m_bottomUI:setNewWinTime(0)
            self:playCoinWinEffectUI()

            self:delayCallBack(2 + 0.3, function (  )
                self:clearCurMusicBg()
                funcNext()
            end)
            
        end)
    else
        self:clearCurMusicBg()
        funcNext()
    end
end

function CodeGameScreenDragonParadeMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
    -- self:clearCurMusicBg() --改
    self:showFreeSpinOverView()
end

--free结算 飞bonus2 数值
function CodeGameScreenDragonParadeMachine:freeOverFlyBonus2(flyEndNode, func)
   

    self:delayCallBack(105/60, function (  )
        local numNode = flyEndNode:findChild("m_lb_coins")
        local startPos = util_convertToNodeSpace(numNode,self)
    
        local flyNode = util_createAnimation("DragonParade_FG_mid_0.csb")
        self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
        local scoreStr = self:formatCoins(self.m_freeMidCount, 3)
        flyNode:findChild("m_lb_coins"):setString(scoreStr)
        flyNode:setPosition(cc.p(startPos))

        flyNode:runCsbAction("shouji", false)
        flyEndNode:runDisAppear()
        self:delayCallBack(25/60, function (  )
            local endNode = self.m_bottomUI:findChild("font_last_win_value")
            local endPos = util_convertToNodeSpace(endNode,self)
            -- endPos = cc.pAdd(endPos, cc.p(0, -posY))

            local animation = {}
            animation[#animation + 1] = cc.CallFunc:create(function(  )
                gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_free_final_bonuswin_fly_begin.mp3")
            end)
            animation[#animation + 1] = cc.EaseIn:create(cc.MoveTo:create(0.5, endPos), 2.5)
            -- animation[#animation + 1] = cc.DelayTime:create(0.4)
            animation[#animation + 1] = cc.CallFunc:create(function(  )
                gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_free_final_bonuswin_fly_end.mp3")

                flyNode:removeFromParent()
                if func then
                    func()
                end
            end)

            flyNode:runAction(cc.Sequence:create(animation))

        end)
    end)
end



---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenDragonParadeMachine:MachineRule_SpinBtnCall()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    
    self:setMaxMusicBGVolume( )
   
    --清除收集特效
    self.m_wildCollecteffectNode:removeAllChildren()

    self.m_quickrun_playWildSound = false


    return false -- 用作延时点击spin调用
end
--是否有bonus2
function CodeGameScreenDragonParadeMachine:checkHaveBonus2()
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    local runResultData = self.m_runSpinResultData.p_reels
    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolType = runResultData[reelRow - i + 1][j]
            if symbolType == self.SYMBOL_BONUS2 then
                return true
            end
        end
    end
    return false
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenDragonParadeMachine:addSelfEffect()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if self:checkHaveBonus2() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FREE_ADDBONUS2VALUE_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FREE_ADDBONUS2VALUE_EFFECT -- 动画类型
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenDragonParadeMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FREE_ADDBONUS2VALUE_EFFECT then
        self:showSelfEffectFreeBonus2(effectData)
    end
    
    return true
end


function CodeGameScreenDragonParadeMachine:isHaveBigWin()
    local ret = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        ret = true
    end
    return ret
end
--大赢
function CodeGameScreenDragonParadeMachine:showBigWinEffect(effectData)

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_bigwin_before.mp3")

    local delayTime = 140/60
    if self:getFreeIsSuper() then
        --super不播孔明灯 以edge时间线为准
        delayTime = 120/60
    else
        util_spinePlay(self.m_juese, "yugao", false)
        local spineEndCallFunc = function()
            self:runJueseIdleAni()
        end
        util_spineEndCallFunc(self.m_juese, "yugao", spineEndCallFunc)

        self.m_effectBigWin:setVisible(true)
        util_spinePlay(self.m_effectBigWin, "actionframe", false)
        local spineEndCallFunc = function()
            self.m_effectBigWin:setVisible(false)
        end
        util_spineEndCallFunc(self.m_effectBigWin, "actionframe", spineEndCallFunc)
    end
    


    self:jumpBigWinWinLabel()
    
    local isRowSuper = false
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local isSuper = self:getFreeIsSuper()
        if isSuper then
            isRowSuper = true
        end
    end
    if isRowSuper then
        
        self.m_bigWinEffectSuper:setVisible(true)
        for i=1,12 do
            local particle = self.m_bigWinEffectSuper:findChild("Particle_a_" .. i)
            particle:resetSystem()
        end
        self.m_bigWinEffectSuper:runCsbAction("daying_FG", false, function()
            self.m_bigWinEffectSuper:setVisible(false)

            for i=1,12 do
                local particle = self.m_bigWinEffectSuper:findChild("Particle_a_" .. i)
                particle:stopSystem()
            end
            
        end)
    else
        self.m_bigWinEffect:setVisible(true)
        for i=1,16 do
            local particle = self.m_bigWinEffect:findChild("Particle_a_" .. i)
            particle:resetSystem()
        end
        self.m_bigWinEffect:findChild("Node_qipan_chufa_root"):setVisible(false)
        self.m_bigWinEffect:findChild("Node_yugao_effect_root"):setVisible(false)
        self.m_bigWinEffect:findChild("Node_daying_effect_root"):setVisible(true)

        self.m_bigWinEffect:runCsbAction("daying", false, function()
            self.m_bigWinEffect:setVisible(false)

            for i=1,16 do
                local particle = self.m_bigWinEffect:findChild("Particle_a_" .. i)
                particle:stopSystem()
            end
            
        end)
    end
    
    self:shakeOneNodeForever(self:findChild("Node_board_root"), delayTime)
    
    self:delayCallBack(delayTime + 0.3, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

end

--free收集bonus2
function CodeGameScreenDragonParadeMachine:showSelfEffectFreeBonus2(effectData)
    self.m_freeBonus2List = {}
    self.m_freeBonus2ListIndex = 1
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS2 then
                    self.m_freeBonus2List[#self.m_freeBonus2List + 1] = node
                end
            end
        end
    end
    self:delayCallBack(0.5, function()
        --free收集bonus2
        self:freeFlyBonus2(function()
            self:delayCallBack(0.1, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
        
    end)
end
--是否是superFree
function CodeGameScreenDragonParadeMachine:getFreeIsSuper()
    return self.m_iReelRowNum ~= self.m_iReelMinRow
end
--free下 飞bonus2到总bonus2价值处
function CodeGameScreenDragonParadeMachine:freeFlyBonus2(func)
    if self.m_freeBonus2ListIndex > #self.m_freeBonus2List then
        func()
        return
    end

    local flySymbol = self.m_freeBonus2List[self.m_freeBonus2ListIndex]

    local isSuper = self:getFreeIsSuper()
    local flyEndNode = nil
    if isSuper then
        flyEndNode = self.m_freeBonus2PrizeBarSuper
    else
        flyEndNode = self.m_freeBonus2PrizeBar
    end

    local startPos = util_convertToNodeSpace(flySymbol, self)
    local endPos = util_convertToNodeSpace(flyEndNode, self)

    local score = self:getFreeOneBonus2Value()

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_free_bonus_collect_fly_begin.mp3")

    flySymbol:runAnim("shouji", false, function()
        flySymbol:runAnim("idleframe2", true)
    end)
    self:runFreeBonus2FlyAction(0,0.5,startPos,endPos,function()
        self.m_freeMidCount = self.m_freeMidCount + score
        self:updateFreeMidBonus2TotalWin(self.m_freeMidCount)
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_free_bonus_collect_fly_end.mp3")
        flyEndNode:runFeedBack() -- 反馈

        --next
        self.m_freeBonus2ListIndex = self.m_freeBonus2ListIndex + 1
        self:freeFlyBonus2(func)
    end, score)
end

function CodeGameScreenDragonParadeMachine:runFreeBonus2FlyAction(time,flyTime,startPos,endPos,callback, score)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("Socre_DragonParade_Bonus_Num1.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    local scoreStr = self:formatCoins(score, 3)
    node:findChild("m_lb_coins"):setString(scoreStr)
    self:updateLabelSize({label=node:findChild("m_lb_coins"),sx=1,sy=1},162)
    node:setScale(0.8)
    node:setVisible(false)
    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        -- node:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        -- node:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        -- node:findChild("Particle_1"):resetSystem()
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
    end)
    -- actionList[#actionList + 1] = cc.DelayTime:create(0.2)
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        
        -- node:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(1)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenDragonParadeMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenDragonParadeMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenDragonParadeMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end



function CodeGameScreenDragonParadeMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenDragonParadeMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS1 or symbolType == self.SYMBOL_BONUS2 or symbolType == self.SYMBOL_BONUS3 or symbolType == self.SYMBOL_BONUS4 then
        return true
    end
    
    return false
end

function CodeGameScreenDragonParadeMachine:isWildSymbol(symbolType)
    if symbolType == self.SYMBOL_WILD1 or symbolType == self.SYMBOL_WILD2 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return true
    end
    
    return false
end
--次数转换显示信号类型
function  CodeGameScreenDragonParadeMachine:timesToWildSymbol( times )
    if times == 3 then
        return TAG_SYMBOL_TYPE.SYMBOL_WILD
    elseif times == 2 then
        return self.SYMBOL_WILD2
    elseif times == 1 then
        return self.SYMBOL_WILD1
    else
        return TAG_SYMBOL_TYPE.SYMBOL_WILD
    end
end
--bonus触发时 wild切换
function CodeGameScreenDragonParadeMachine:bonusTriggerWildDisappearOneByOne(wildPosArray, idx, leftCount, isSuper, func )

    if idx > #wildPosArray then
        self:delayCallBack(5/30, function (  )
            func()
        end)
        
        return
    end
    local pos = wildPosArray[idx]

    --设置棋盘上 把其他转换成bonus
    local posdata = self:getRowAndColByPos(pos)
    local iRow = posdata.iX
    local iCol = posdata.iY
    local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
    if node then
        if isSuper then
            self:changeSymbolType(node, self.SYMBOL_BONUS4)
        else
            self:changeSymbolType(node, self.SYMBOL_BONUS1)
        end
        
        --设置wild转bonus后的score值
        self:setSpecialNodeScore(node)

        --清理wild上数字
        self:removeSlotsNodeCorner(node)

        --提层
        self.setSymbolToClipReel(self, node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType, 0)
    end



    if self.m_baseWildLockNodes[pos] then
        self.m_baseWildLockNodes[pos]:setVisible(true) --显示锁定的 用来遮挡

        local lockNode = self.m_baseWildLockNodes[pos]:getChildByTag(1)

        if not lockNode then
            lockNode = self:createOneLockNode(pos, self:timesToWildSymbol(leftCount))
            lockNode:updateCornerNum(leftCount)
        else

        end

        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_wild_switchbonus.mp3")

        lockNode:playLockAction("switchtobonus", false, function (  )
        end)
        -- lockNode:numFadeOut(  )

        local time = 10/30
        if isSuper then
            time = 15/30
        end
        self:delayCallBack(time, function (  )
            local idx = idx + 1
            self:bonusTriggerWildDisappearOneByOne(wildPosArray, idx, leftCount, isSuper, func )
        end)
    else
        local idx = idx + 1
        self:bonusTriggerWildDisappearOneByOne(wildPosArray, idx, leftCount, isSuper, func )
    end
end
--bonus触发动画
function CodeGameScreenDragonParadeMachine:triggerBonusAnim( func, isSuper )
    if isSuper then
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_bonus_tirgger_forture.mp3")
    else
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_bonus_tirgger_luckyone.mp3")
    end
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS1 or node.p_symbolType == self.SYMBOL_BONUS4 then
                    node:runAnim("actionframe", false, function (  )
                        node:runAnim("idleframe2", true)
                    end)

                    --提层
                    self.setSymbolToClipReel(self, node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType, 0)
                end
            end
        end
    end
    self:delayCallBack(60/30, function (  )
        if func then
            func()
        end
    end)
end
--base 收集触发bonus的值
function CodeGameScreenDragonParadeMachine:baseCollectTriggerBonusValue( func )
    --压暗
    self:showBlackLayer()

    --收集弹板出现
    self.m_baseBonusCollectAddBar:setVisible(true)
    self.m_baseBonusCollectAddBar:setPosition(cc.p(0, 0))
    self.m_baseBonusCollectAddBar:runCsbAction("start", false, function (  )
        self.m_baseBonusCollectAddBar:runCsbAction("idle", true)
    end)
    self.m_baseBonusCollectAddBar:findChild("m_lb_num"):setString("")

    self.m_baseBonusCollectAddBarBg:setVisible(true)
    self:runCsbAction("start_beiguang", false, function()
        self:runCsbAction("idle_beiguang", true)
    end)

    --上面动画完毕
    self:delayCallBack(20/60, function (  )
        self.m_fly_baseTriggerBonus = {}
        self.m_fly_baseTriggerBonusIndex = 1
        self.m_fly_baseTriggerBonusScore = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node then
                    if node.p_symbolType == self.SYMBOL_BONUS1 or node.p_symbolType == self.SYMBOL_BONUS4 then
                        table.insert(self.m_fly_baseTriggerBonus, node)
                        
                    end
                end
            end
        end
        self:flyTriggerBonus(0, function()
            --压暗
            self:hideBlackLayer()
            --背光消失
            self:runCsbAction("over_beiguang", false, function()
                self.m_baseBonusCollectAddBarBg:setVisible(false)
            end)
            self:delayCallBack(20/60, function()
                gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_choose_popupstart_begin.mp3")

                --还原提层
                self:checkChangeBaseParent()
                local endPos = util_convertToNodeSpace(self:findChild("Node_jiaqianMoveOver"), self:findChild("Node_jiaqian"))
                local actionList = {}
                actionList[#actionList + 1] = cc.EaseCubicActionInOut:create(cc.MoveTo:create(0.5, endPos))
                self.m_baseBonusCollectAddBar:runAction(cc.Sequence:create(actionList))


                self:delayCallBack(0.5, function()
                    func()
                end)
            end)
        end)
    end)
    
end
--触发 收集单个bonus
function CodeGameScreenDragonParadeMachine:flyTriggerBonus(_curTotalCoins, func)
    local curTotalCoins =_curTotalCoins
    if self.m_fly_baseTriggerBonusIndex > #self.m_fly_baseTriggerBonus then
        --展示0.5秒
        self:delayCallBack(0.5 + 0.2, function()
            if func then
                func()
            end
        end)
        

        return
    end

    local symbolNode = self.m_fly_baseTriggerBonus[self.m_fly_baseTriggerBonusIndex]
    self.m_fly_baseTriggerBonusIndex = self.m_fly_baseTriggerBonusIndex + 1

    if symbolNode then
        symbolNode:runAnim("shouji", false, function (  )
            symbolNode:runAnim("idleframe2", true)
        end)
        local startPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
        local numNode = self.m_baseBonusCollectAddBar:findChild("m_lb_num")
        local endPos = numNode:getParent():convertToWorldSpace(cc.p(numNode:getPosition()))
        
        local posIdx = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        local score = self:getStoreIconsBonusScore(posIdx)
        curTotalCoins = curTotalCoins + score
        self.m_fly_baseTriggerBonusScore = self.m_fly_baseTriggerBonusScore + score
        local scoreStr = self:formatCoins(score, 3)
        --飞 数字
        self:runFlyNumAction(0, 0.5, startPos, endPos, function (  )
            
        end, scoreStr, curTotalCoins)
        self:delayCallBack(0.3, function()
            self:flyTriggerBonus(curTotalCoins, func)
        end)
    else
        self:flyTriggerBonus(curTotalCoins, func)
    end
    
end
--trigger bonus数字飞到总金额栏
function CodeGameScreenDragonParadeMachine:runFlyNumAction(time,flyTime,startPos,endPos,callback, scoreStr, _curTotalCoins)
    local curTotalCoins = _curTotalCoins
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("Socre_DragonParade_Bonus_Num1.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    node:findChild("m_lb_coins"):setString(scoreStr)
    self:updateLabelSize({label=node:findChild("m_lb_coins"),sx=1,sy=1},162)
    node:setScale(0.8)
    node:setVisible(false)
    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        -- gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_bonustrigger_collect_fly_begin.mp3")
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_bonustrigger_collect_fly_end.mp3")
        node:setVisible(false)
        self:resetAct(self.m_baseBonusCollectAddBar)
        self.m_baseBonusCollectAddBar:runCsbAction("actionframe", false, function (  )
            self.m_baseBonusCollectAddBar:runCsbAction("idle", true)
        end)
    end)
    -- actionList[#actionList + 1] = cc.DelayTime:create(13 / 60)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        local score = curTotalCoins
        local scoreStr = self:formatCoins(score, 3)
        self.m_baseBonusCollectAddBar:findChild("m_lb_num"):setString(scoreStr)
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(1)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))
end
--重置动画
function CodeGameScreenDragonParadeMachine:resetAct(node)
    if node and not tolua.isnull(node) then
        if node.m_csbAct and not tolua.isnull(node.m_csbAct) then
            util_resetCsbAction(node.m_csbAct)
        end
    end
end
---
-- 显示bonus 触发的小游戏
function CodeGameScreenDragonParadeMachine:showEffect_Bonus(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local superFunc = function()
        self.m_beInSpecialGameTrigger = true

        if globalData.slotRunData.currLevelEnter == FROM_QUEST then
            self.m_questView:hideQuestView()
        end
        -- self:clearFrames_Fun()
        

        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

        --wild转bonus
        local isSuper = selfData.superGame
        if selfData.bonusType == "select" then
            -- self:baseLockWildReplaceReelGrid()
            
            --隐藏base leftbar
            if self.m_baseLeftBar:isVisible() == true then
                self.m_baseLeftBar:hideView()
            end

            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "bonus")
            end

            local stickData = self:getStickWildData()
            local wildIconsPos = stickData.wildPos or {}
            local leftCount = stickData.wildLeftTimes or 0
            if #wildIconsPos > 0 then

                local tempWildIconPos = {}
                for i=1,#wildIconsPos do
                    table.insert(tempWildIconPos, wildIconsPos[i])
                end
                --sort
                table.sort(tempWildIconPos, function ( a, b )
                    local posA = self:getRowAndColByPos(a)
                    local iRowA = posA.iX
                    local iColA = posA.iY
                    local posB = self:getRowAndColByPos(b)
                    local iRowB = posB.iX
                    local iColB = posB.iY
                    if iColA == iColB then
                        return iRowA > iRowB
                    else
                        return iColA < iColB
                    end
                end)

                
                self:bonusTriggerWildDisappearOneByOne(tempWildIconPos, 1, leftCount, isSuper, function (  )
                    --wild消失后
                    
                    -- 停止播放背景音乐
                    self:clearCurMusicBg()
                    --触发动画
                    self:triggerBonusAnim(function (  )
                        self:clearLockNode()

                        --收集
                        self:baseCollectTriggerBonusValue(function (  )
                            self:showBonusGameView(effectData)
                        end)
                        
                    end,isSuper)
                end)


            else
                -- 停止播放背景音乐
                self:clearCurMusicBg()
                --触发动画
                self:triggerBonusAnim(function (  )
                    self:baseCollectTriggerBonusValue(function (  )
                        self:showBonusGameView(effectData)
                    end)              
                end,isSuper)
            end
        else
            -- -- 停止播放背景音乐
            -- self:clearCurMusicBg()
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "pickFeature")
            end
            self:showBonusGameView(effectData)
        end

    end

    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            local cloumnIndex = childs[i].p_cloumnIndex
            if cloumnIndex then
                local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPosition()))
                local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                self:changeBaseParent(childs[i])
                childs[i]:setPosition(pos)
                self.m_slotParents[cloumnIndex].slotParent:addChild(childs[i])
            end
        end
    end

    if self:getLastWinCoin() > 0 and selfData.bonusType == "select" then
        if self:isHaveBigWin() then --有大赢  触发时间延迟到一轮连线动画播完
            local timeCur = xcyy.SlotsUtil:getMilliSeconds()
            local transTime = math.max(timeCur - self.m_lineChangeTime, 0)
            local lineTime = self.m_changeLineFrameTime or 2
            local delayTime = math.max(lineTime - transTime / 1000, 0)
            if delayTime >= 2 then
                delayTime = 2
            end
            scheduler.performWithDelayGlobal(
                function()
                    removeMaskAndLine()
                    self:delayCallBack(0.4, function()
                        superFunc()
                    end)
                    
                end,
                delayTime,
                self:getModuleName()
            )
        else
            scheduler.performWithDelayGlobal(
                function()
                    removeMaskAndLine()
                    self:delayCallBack(0.4, function()
                        superFunc()
                    end)
                end,
                2,
                self:getModuleName()
            )
        end
        
    else
        superFunc()
    end

    return true
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenDragonParadeMachine:showBonusGameView(effectData)
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra or {}  --后端定的 断线重连 如果是中途退的 pick字段加在这里 初始退出加在selfdata上了
    if selfData.bonusType == "select" then
        local isSuper = selfData.superGame

        local score = self.m_fly_baseTriggerBonusScore
        local chooseView = util_createView("CodeDragonParadeSrc.DragonParadeChooseView", self, isSuper, score)
        gLobalViewManager:showUI(chooseView)
        chooseView:findChild("root"):setScale(self.m_machineRootScale)

        chooseView:setEndCall( function( selectId ) 
            --cut    

        end, function ( selectId )
            self.m_reconnect = false
            --trigger
            if selectId == 1 then --选择respin

                self.m_isSelectRespin = true

                self:addLocalEffect(GameEffect.EFFECT_RESPIN)

                effectData.p_isPlay = true
                self:playGameEffect() -- 播放下一轮
            else

                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                self.m_iFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
                -- self.m_iSelectID = self.m_runSpinResultData.p_selfMakeData.freeSpinType + 1 
                if isSuper then
                    self.m_iReelRowNum = self.m_iReelMaxRow
                else
                    self.m_iReelRowNum = self.m_iReelMinRow
                end
                
                -- self.m_configData:setFsModel(self.m_vecFsModel[self.m_iSelectID])
                self:showFreeSpinView(effectData)
            end

            if chooseView then
                chooseView:removeFromParent()
            end
        end)
    elseif selfData.bonusType == "pick" or bonusExtra.bonusType == "pick" then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local curCornucopiaIndex = self.m_lastCornucopiaIndex
        if selfData.wildStatus then
            curCornucopiaIndex = selfData.wildStatus
        end
        local time = 15/30 + 25/30
        if self.m_lastCornucopiaIndex ~= curCornucopiaIndex then
            time = time + 20/30
        end
        self:delayCallBack(time, function (  )
            self:showDFDCView(effectData)
        end)
    end
end
--添加effect
function CodeGameScreenDragonParadeMachine:addLocalEffect(effectType)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = effectType
    bonusGameEffect.p_effectOrder = effectType
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
end

function CodeGameScreenDragonParadeMachine:changeReelData(_isResetSymbolData)
    local isResetSymbolData = _isResetSymbolData
    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i,self.m_iReelRowNum,true)
    end

    if self.m_iReelRowNum == self.m_iReelMinRow then
    else
        for i = self.m_iReelMinRow + 1, self.m_iReelRowNum, 1 do
            if self.m_stcValidSymbolMatrix[i] == nil then
                self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
            end
        end
    end
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x, 
                y = rect.y, 
                width = rect.width, 
                height = columnData.p_slotColumnHeight
            }
        )
    end

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    if isResetSymbolData then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 4, 6 do
                local curRow = self.m_iReelRowNum - iRow + 1
                local reels = self.m_runSpinResultData.p_reels
                local symbolType = reels[curRow][iCol]
                local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if symbolNode and symbolType then
                    symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,symbolType), symbolType)
                    symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(symbolType))

                    if symbolNode.p_symbolImage then
                        symbolNode.p_symbolImage:removeFromParent()
                        symbolNode.p_symbolImage = nil
                    end
                end
            end
        end
    end
end

function CodeGameScreenDragonParadeMachine:changeUIBG(type)
    self:findChild("Node_qipankuang"):setVisible(false)
    self:findChild("Node_kuang_Super"):setVisible(false)
    self:findChild("Reel_base"):setVisible(false)
    self:findChild("Reel_FG"):setVisible(false)
    self:findChild("Reel_FG_Super"):setVisible(false)
    self:findChild("Node_jiange"):setVisible(false)
    self:findChild("Node_jiange_Super"):setVisible(false)

    self:findChild("Node_Base_root"):setVisible(false)
    self:findChild("Node_FG_root"):setVisible(false)
    self:findChild("Node_FG_Super_root"):setVisible(false)
    self:findChild("Node_bar"):setVisible(false)
    self:findChild("Node_jvbaopen"):setVisible(false)
    self:findChild("jinbi"):setVisible(false)

    self:findChild("Node_juese"):setVisible(false)

    self.m_gameBg:findChild("Base"):setVisible(false)
    self.m_gameBg:findChild("FG"):setVisible(false)
    self.m_gameBg:findChild("ReSpin"):setVisible(false)

    if type == "base" then
        self:findChild("Node_qipankuang"):setVisible(true)
        self:findChild("Reel_base"):setVisible(true)
        self:findChild("Node_jiange"):setVisible(true)
        self:findChild("Node_Base_root"):setVisible(true)
        self:findChild("Node_jvbaopen"):setVisible(true)
        self:findChild("Node_juese"):setVisible(true)
        self.m_gameBg:findChild("Base"):setVisible(true)

        self:findChild("jinbi"):setVisible(true)
    elseif type == "free" then
        self:findChild("Node_qipankuang"):setVisible(true)
        self:findChild("Reel_FG"):setVisible(true)
        self:findChild("Node_jiange"):setVisible(true)
        self:findChild("Node_FG_root"):setVisible(true)
        self:findChild("Node_bar"):setVisible(true)
        self:findChild("Node_juese"):setVisible(true)
        self.m_gameBg:findChild("FG"):setVisible(true)
    elseif type == "super_free" then
        self:findChild("Node_kuang_Super"):setVisible(true)
        self:findChild("Reel_FG_Super"):setVisible(true)
        self:findChild("Node_jiange_Super"):setVisible(true)
        self:findChild("Node_FG_Super_root"):setVisible(true)
        self:findChild("Node_bar"):setVisible(true)
        self.m_gameBg:findChild("FG"):setVisible(true)
    elseif type == "respin" then
        self:findChild("Node_juese"):setVisible(true)
        self.m_gameBg:findChild("ReSpin"):setVisible(true)
    elseif type == "super_respin" then
        self.m_gameBg:findChild("ReSpin"):setVisible(true)
    end
end

--重写 修改basedialog
function CodeGameScreenDragonParadeMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("CodeDragonParadeSrc.DragonParadeDialog") --改
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
    return view
end

function CodeGameScreenDragonParadeMachine:getBottomUINode( )
    return "CodeDragonParadeSrc.DragonParadeBottomUiView"
end
--JackPot弹板
function CodeGameScreenDragonParadeMachine:showJackpot(index, coins, func)
    
    local jackPotWinView = util_createView("CodeDragonParadeSrc.DragonParadeJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData({
        coins   = coins,
        index   = index,
        machine = self,
    })
    jackPotWinView:setOverAniRunFunc(function (  )
        if func then
            func()
        end
    end)
end

-- bonus小游戏断线重连
function CodeGameScreenDragonParadeMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" then

        self:playGameEffect()
        return
    end

    if featureData.p_status == "OPEN" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_reconnect = true
        
        self:addLocalEffect(GameEffect.EFFECT_BONUS)
    end
end

-- 断线重连 
function CodeGameScreenDragonParadeMachine:MachineRule_initGame()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then 
        
    end

    local hasRespin = self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    if hasRespin then 
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        self.m_isSuperGame = selfData.superGame
        if selfData.reSpinCurReel == 0 then
            self.m_isSecondBoard = false
        else
            self.m_isSecondBoard = true
        end
    end
end

--多福多彩
function CodeGameScreenDragonParadeMachine:showDFDCView(effectData)

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    
    --聚宝盆飞金币
    self.m_baseMidBar:playTrans(function() 
        --金币过场
        self:showTransDFDC(true, function()
            self.m_bottomUI:checkClearWinLabel()
            --切
            self.m_collectGameNode:initView(self.m_runSpinResultData.p_selfMakeData.pickJackpots or {},
                function()
                    self:showTransDFDC(false, function()
                        self.m_bInBonus = false
                        self.m_jackpotBar:setVisible(true)
                        self.m_juese:setVisible(true)

                        self.m_collectGameNode:setVisible(false)

                        --还原锁定的状态 更新下 锁定块可能连线是触发多福多彩
                        self:updateBetLockNode()

                        self:resetMusicBg()
                    end, function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end)
                end
            )

            self.m_collectGameNode:setVisible(true)
            self.m_jackpotBar:setVisible(false)
            self.m_juese:setVisible(false)
            

            self:resetMusicBg(nil,"DragonParadeSounds/music_DragonParade_Bg_dfdc.mp3")
        end, function()

        end)


    end)

    

end
--过场 多福多彩   开始需和聚宝盆配合 结束直接
function CodeGameScreenDragonParadeMachine:showTransDFDC(isBegin, func1, func2)
    self.m_jvbaopenEffect:setVisible(true)
    if isBegin == false then
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_trans_dfdc_back.mp3")
    end
    util_spinePlay(self.m_jvbaopenEffect, "actionframe_guochang2", false)
    local spineEndCallFunc = function()
        
    end
    util_spineEndCallFunc(self.m_jvbaopenEffect, "actionframe_guochang2", spineEndCallFunc)

    self:delayCallBack(14/30, function()
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(40/30, function()
        if func2 then
            func2()
        end
    end)
end

--过场 孔明灯
function CodeGameScreenDragonParadeMachine:showTransFree(type, func1, func2)
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_trans_light.mp3")

    self.m_trans_light:setVisible(true)

    util_spinePlay(self.m_trans_light, "actionframe_guochang", false)
    local spineEndCallFunc = function()
        
    end
    util_spineEndCallFunc(self.m_trans_light, "actionframe_guochang", spineEndCallFunc)

    self:delayCallBack(76/30, function()
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(140/30, function()
        if func2 then
            func2()
        end
    end)
end

--过场 鞭炮
function CodeGameScreenDragonParadeMachine:showTrans(type, func1, func2)
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_trans_firecracker.mp3")

    self.m_trans_explore:setVisible(true)

    util_spinePlay(self.m_trans_explore, "actionframe_guochang", false)
    local spineEndCallFunc = function()
        
    end
    util_spineEndCallFunc(self.m_trans_explore, "actionframe_guochang", spineEndCallFunc)

    self:delayCallBack(16/30, function()
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(60/30, function()
        if func2 then
            func2()
        end
    end)
end
--过场respin juese龙
function CodeGameScreenDragonParadeMachine:showTransRespin(isSuper, func1, func2, func3, func4)
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_trans_dragon.mp3")

    util_spinePlay(self.m_juese, "guochang", false)
    local spineEndCallFunc = function()
        self:runJueseIdleAni()
    end
    util_spineEndCallFunc(self.m_juese, "guochang", spineEndCallFunc)

    self:delayCallBack(21/30, function() --龙 提层
        local nodePos = util_convertToNodeSpace(self.m_juese, self)
        util_changeNodeParent(self, self.m_juese, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5)
        self.m_juese:setPosition(cc.p(nodePos))
        
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(30/30, function() --切 界面
        if func2 then
            func2()
        end
    end)
    self:delayCallBack(37/30, function() --还原龙   super的话隐藏
        util_changeNodeParent(self:findChild("Node_juese"), self.m_juese, 0)
        self.m_juese:setPosition(cc.p(0, 0))

        if isSuper then
            self:findChild("Node_juese"):setVisible(false)
        end

        if func3 then
            func3()
        end
    end)
    --end
    self:delayCallBack(55/30, function()
        if func4 then
            func4()
        end
    end)
end
--延迟回调
function CodeGameScreenDragonParadeMachine:delayCallBack(time, func)
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

-- 继承底层respinView
function CodeGameScreenDragonParadeMachine:getRespinView()
    return "CodeDragonParadeSrc.DragonParadeRespinView"
end
-- 继承底层respinNode
function CodeGameScreenDragonParadeMachine:getRespinNode()
    return "CodeDragonParadeSrc.DragonParadeRespinNode"
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenDragonParadeMachine:getRespinRandomTypes( )
    local symbolList = {
        -- self.SYMBOL_BONUS1,
        self.SYMBOL_BONUS2,
        self.SYMBOL_BONUS3,
        self.SYMBOL_FIX_BLANK
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenDragonParadeMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_BONUS1, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_BONUS2, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_BONUS3, runEndAnimaName = "buling", bRandom = false}
    }

    return symbolList
end

function CodeGameScreenDragonParadeMachine:showRespinView(effectData)
    self.m_bottomUI:checkClearWinLabel()

    -- --先播放动画 再进入respin
    -- self:clearCurMusicBg()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_isSuperGame = selfData.superGame

    local cutFunc = function()
        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )
        --可随机的特殊信号
        local endTypes = self:getRespinLockTypes()
        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)
    end

    if self.m_reconnect then
        -- 更改respin 状态下的背景音乐
        self:changeReSpinBgMusic()
        cutFunc()
        self:runReSpin()
        if self.m_isSuperGame then
            if self.m_isSecondBoard then
                self.m_respinBoard_1:setPos2(  )
                self.m_respinBoard_2:setPos1(  )
                self.m_respinBoard_2:setFrontOrder(  )
                self.m_respinBoard_1:setBackOrder(  )

                self.m_respinBoard_2:idle()
                self.m_respinBoard_1:dark()

                self.m_respinBoard_1:setRespinBarPos(true)
                --更新赢钱
                local finalWin1, totalMulti1 = self:getRespinFinalTotalWin( "front" )
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{finalWin1, false, false})
                globalData.slotRunData.lastWinCoin = lastWinCoin


                --重置timesbar
                self.m_respinBoard_1:setRespinBarType( "isFinish" )
                self.m_respinBoard_2:setRespinBarType( ) 

                if self:getIsFullWin("front") then --重连 全满 score乘倍
                    local listBack = self.m_respinView_1:getAllCleaningNode()
                    for i=1,#listBack do
                        local symbolNode = listBack[i]
                        if symbolNode and symbolNode.m_score then
                            local score = symbolNode.m_score
                            score = score * 2
                            symbolNode.m_score = score
                            local scoreStr = self:formatCoins(score, 3)
                            self:bonusShowScore(symbolNode, scoreStr)
                        end
                    end
                end
            else
                self.m_respinBoard_1:idle()
                self.m_respinBoard_2:dark()

                --重置timesbar
                self.m_respinBoard_1:setRespinBarType( )
                self.m_respinBoard_2:setRespinBarType( ) 
            end
        else
            --重置timesbar
            self.m_respinBoard_2:setRespinBarType( ) 
        end
        self.m_jackpotBar:setVisible(true)
    else
        -- 更改respin 状态下的背景音乐
        self:changeReSpinBgMusic()
        --过场
        self:showTransRespin(self.m_isSuperGame, function()
        end, function()
            --切
            

            --置回压暗
            if self.m_isSuperGame then
                self.m_respinBoard_1:idle()
                self.m_respinBoard_2:idle()

                self.m_jackpotBar:setVisible(false)

                --重置timesbar
                self.m_respinBoard_1:setRespinBarType( )
                self.m_respinBoard_2:setRespinBarType( ) 

                self.m_respinBoard_1:setRespinBarPos(false) --重置位置
                self.m_respinBoard_2:setRespinBarPos(false)
            else
                self.m_respinBoard_2:idle()
                --重置timesbar
                self.m_respinBoard_2:setRespinBarType( ) 

                self.m_respinBoard_2:setRespinBarPos(false) --重置位置
            end
            
            cutFunc()
        end, function()
        end, function()
            --end
            self:runReSpin()
        end)
    end
    

    
    
end

--触发respin
function CodeGameScreenDragonParadeMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:changeTouchSpinLayerSize()

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol, _isLastReel)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol, _isLastReel)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_respinBoard_2:getClipParentNode():addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE) -- 改
    self.m_respinBoard_2:setVisible(true)

    --双棋盘
    if self.m_isSuperGame then
        self.m_respinView_1 = util_createView(self:getRespinView(), self:getRespinNode())
        self.m_respinView_1:setMachine(self)
        self.m_respinView_1:setCreateAndPushSymbolFun(
            function(symbolType, iRow, iCol, isLastSymbol, _isLastReel)
                return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol, _isLastReel)
            end,
            function(targSp)
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end
        )
        self.m_respinBoard_1:getClipParentNode():addChild(self.m_respinView_1, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE) -- 改
        if self.m_reconnect then
            self.m_respinBoard_1:setVisible(true)
        else
            self.m_respinBoard_1:setVisible(false)
        end

        self:changeUIBG("super_respin")
    else
        self:changeUIBG("respin")
    end
    -- self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    --更新bonus2 bar
    self:updateRespinLeftBonus2Win()

    --bonusNum
    local cntfront = self:getRespinMidNum("front")
    local cntback = self:getRespinMidNum("back")
    

    if self.m_isSuperGame then
        
        local score1 = self:getRespinRightBonus3Score(true)
        local score2 = self:getRespinRightBonus3Score(false)
        self.m_respinRightCount_1 = score1
        self.m_respinRightCount_2 = score2
        local score1Str = self:formatCoins(score1, 3)
        local score2Str = self:formatCoins(score2, 3)

        self.m_respinBoard_1:setBonus3TotalWinNum( score1Str )
        self.m_respinBoard_2:setBonus3TotalWinNum( score2Str )

        self.m_respinMidCount_2 = cntback
        self.m_respinBoard_2:setbonusTotalCount( self.m_respinMidCount_2 )
        self.m_respinMidCount_1 = cntfront
        self.m_respinBoard_1:setbonusTotalCount( self.m_respinMidCount_1 )

        --设置order
        self.m_respinBoard_1:setFrontOrder()
        self.m_respinBoard_2:setBackOrder()

        self:changeTouchSpinLayerSize(true)
    else
        local score2 = self:getRespinRightBonus3Score(true)
        self.m_respinRightCount_2 = score2
        local score2Str = self:formatCoins(score2, 3)

        self.m_respinBoard_2:setBonus3TotalWinNum( score2Str )
        --设置order
        self.m_respinBoard_2:setBackOrder()

        self.m_respinMidCount_2 = cntfront
        self.m_respinBoard_2:setbonusTotalCount( self.m_respinMidCount_2 )
    end


    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenDragonParadeMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据

    --双棋盘
    if self.m_isSuperGame then
        local respinNodeInfo_1 = self:reateRespinNodeInfo("one", "data_front")--1棋盘位置  reels数据
        self.m_respinView_1:setEndSymbolType(endTypes, randomTypes)
        self.m_respinView_1:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)
        self.m_respinView_1:initRespinElement(
            respinNodeInfo_1,
            self.m_iReelRowNum,
            self.m_iReelColumnNum,
            function()
            end
        )

        local respinNodeInfo = self:reateRespinNodeInfo("two", "data_back")   --2棋盘位置  upreels数据

        self.m_respinView:setEndSymbolType(endTypes, randomTypes)
        self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)
        self.m_respinView:initRespinElement(
            respinNodeInfo,
            self.m_iReelRowNum,
            self.m_iReelColumnNum,
            function()
            end,
            true
        )
    else
        local respinNodeInfo = self:reateRespinNodeInfo("two", "data_front")   --2棋盘位置  reels数据

        self.m_respinView:setEndSymbolType(endTypes, randomTypes)
        self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)
        self.m_respinView:initRespinElement(
            respinNodeInfo,
            self.m_iReelRowNum,
            self.m_iReelColumnNum,
            function()
            end
        )
    end

    self:reSpinEffectChange()
    self:playRespinViewShowSound()
    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    
    -- -- 更改respin 状态下的背景音乐
    -- self:changeReSpinBgMusic()

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end
--respin 开始
function CodeGameScreenDragonParadeMachine:runReSpin()
    if self.m_reconnect then
        self:runNextReSpinReel()
    else
        if self.m_isSuperGame then
            --分出棋盘
            self:runRespinRootScale_Init(function()
                self:runNextReSpinReel()
            end, "init")
        else
            self:runNextReSpinReel()
        end
    end
end

--开始下次ReSpin
function CodeGameScreenDragonParadeMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            self:startReSpinRunBefore()

            -- if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
            --     self:startReSpinRun()
            -- end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )

end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenDragonParadeMachine:reateRespinNodeInfo(type, frontOrback)
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol, frontOrback)


            local posIdx = self:getPosReelIdx(iRow, iCol)
            if symbolType ~= 200 and self:checkStoreIconsIsHave(posIdx) and (self:isWildSymbol(symbolType) or not self:isFixSymbol(symbolType)) then
                symbolType = 94
            end
            --进入respin转换信号值
            -- if self:isWildSymbol(symbolType) then
            --     symbolType = 94
            -- end
            if symbolType == 97 then
                symbolType = 94
            end
            if not self:isFixSymbol(symbolType) then
                symbolType = 200
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getLocalRespinReelPos(iCol, type) --改
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

--storeIcons是否有相应位置
function CodeGameScreenDragonParadeMachine:checkStoreIconsIsHave(pos)
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == pos then
            return true
        end
    end
    return false
end

function CodeGameScreenDragonParadeMachine:getLocalRespinReelPos(col, type)
    local reelNode = nil
    if type == "one" then
        reelNode = self.m_respinBoard_1:findChild("sp_reel_" .. (col - 1))
    elseif type == "two" then
        reelNode = self.m_respinBoard_2:findChild("sp_reel_" .. (col - 1))
    end
    
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

function CodeGameScreenDragonParadeMachine:MachineRule_respinTouchSpinBntCallBack()
    local processLogic = function(_view, _type)
        if _view and _view:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
            if self.m_beginStartRunHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
                self.m_beginStartRunHandlerID = nil
            end
            _view:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)
            -- self:startReSpinRun()
            self:startReSpinRunBefore()
        elseif _view and _view:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
            --快停
            self:quicklyStop(_type)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        elseif not _view then
            release_print("当前出错关卡名称:" .. self:getModuleName())
        end
    end
    if self.m_isSuperGame then
        if self.m_isSecondBoard then
            --第二棋盘
            processLogic(self.m_respinView, "board_2")
        else
            --第一棋盘
            processLogic(self.m_respinView_1, "board_1")
        end
    else
        processLogic(self.m_respinView, "board_2")
    end

end
function CodeGameScreenDragonParadeMachine:startReSpinRunBefore()
    --双棋盘
    if self.m_isSuperGame then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}

        if selfData.reSpinCurReel == 0 then --0时只有上棋盘滚动
            if self.m_respinIsChanged == true then
                self.m_respinIsChanged = false
            end
            
            self:startReSpinRun("board_1")
        else
            self:startReSpinRun("board_2")
        end
    else
        self:startReSpinRun("board_2")
    end
end

--开始滚动
function CodeGameScreenDragonParadeMachine:startReSpinRun(type)
    if type == "board_1" then
        if self.m_respinView_1:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
            return
        end
    elseif type == "board_2" then
        if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
            return
        end
    end
    
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    self:requestSpinReusltData()
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    
    self:updateLastRespinStoreIcons()

    if type == "board_1" then
        self.m_respinView_1:startMove()
        if self.m_runSpinResultData.p_reSpinCurCount <= 1 then
            self:showNextQuickNode(self.m_respinView_1)
        end
    elseif type == "board_2" then
        self.m_isLastBoard = true
        self.m_respinView:startMove()
        if self.m_runSpinResultData.p_reSpinCurCount <= 1 then
            self:showNextQuickNode(self.m_respinView)
        end
    end
    
end

--- respin 快停
function CodeGameScreenDragonParadeMachine:quicklyStop(type)
    self.m_respinQuickStop = true

    if type == "board_1" then
        self.m_respinView_1:quicklyStop()
    elseif type == "board_2" then
        self.m_respinView:quicklyStop()
    end
    
end

--消息返回 
function CodeGameScreenDragonParadeMachine:spinResultCallFun(param)
    local isSucc = param[1]
    local spinData = param[2]

    CodeGameScreenDragonParadeMachine.super.spinResultCallFun(self,param)
    if self:getCurrSpinMode() == RESPIN_MODE then
        if isSucc then
            -- 处理respin触发棋盘转换数据
            if spinData.result.respin.extra and spinData.result.respin.extra.options then
                self.m_triggerRespinChangeBoard = true
                -- reSpinCurReel
            end
       end
    end
end

--接收到数据开始停止滚动
function CodeGameScreenDragonParadeMachine:stopRespinRun()
    --双棋盘 one two 此处代表数据取哪
    if self.m_isSuperGame then
        local storedNodeInfo = self:getRespinSpinData("data_back")
        local unStoredReels = self:getRespinReelsButStored(storedNodeInfo, "data_back") --后
        self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)

        local storedNodeInfo_1 = self:getRespinSpinData("data_front")
        local unStoredReels_1 = self:getRespinReelsButStored(storedNodeInfo_1, "data_front") --先
        self.m_respinView_1:setRunEndInfo(storedNodeInfo_1, unStoredReels_1)
    else
        local storedNodeInfo = self:getRespinSpinData("data_front")
        local unStoredReels = self:getRespinReelsButStored(storedNodeInfo, "data_front")
        self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    end
    
end

-- --重写组织respinData信息
function CodeGameScreenDragonParadeMachine:getRespinSpinData(type)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local isNeedAdd = false
        if type == "data_front" then
            if id <= 14 then
                isNeedAdd = true
            end
        elseif type == "data_back" then
            if id > 14 then
                isNeedAdd = true
                id = id - 15
            end
        end
        if isNeedAdd then
            local pos = self:getRowAndColByPos(id)
            local type = self:getMatrixPosSymbolType(pos.iX, pos.iY, type)

            storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
        end
    end

    return storedInfo
end

function CodeGameScreenDragonParadeMachine:getMatrixPosSymbolType(iRow, iCol, type)
    local rowCount = nil
    local reels = nil
    if type == "data_front" then
        rowCount = #self.m_runSpinResultData.p_reels
        reels = self.m_runSpinResultData.p_reels
    elseif type == "data_back" then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        if selfData.upReels == nil then --初始去 reels数据
            selfData.upReels = self.m_runSpinResultData.p_reels
        end
        rowCount = #selfData.upReels
        reels = selfData.upReels
    end
    
    for rowIndex = 1, rowCount do
        local rowDatas = reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

function CodeGameScreenDragonParadeMachine:getRespinReelsButStored(storedInfo, type)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            local type = self:getMatrixPosSymbolType(iRow, iCol, type)
            if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
            end
        end
    end
    return reelData
end

function  CodeGameScreenDragonParadeMachine:respinBeforeEnd( func )
    --是否全满
    if self.m_isSuperGame then
        if self:getIsFullWin() then
            self.m_respinBoard_1:setRespinBarType( "isFinish" )
            self.m_respinBoard_2:setRespinBarType( "isFinish" )
            
            self.m_respinBoard_2:showMidActionFrame() --mid全满动画
            --乘倍动画
            self:respinDoubleAnim( "view", function (  )
                func()
            end )
        else
            --继续
            func()
        end
    else
        if self:getIsFullWin("front") then
            self.m_respinBoard_2:setRespinBarType( "isFinish" )

            self.m_respinBoard_2:showMidActionFrame() --mid全满动画
            --乘倍动画
            self:respinDoubleAnim( "view", function (  )
                func()
            end )
        else
            --继续
            func()
        end
    end
end

---判断结算
function CodeGameScreenDragonParadeMachine:reSpinReelDown(addNode)
    self:setGameSpinStage(STOP_RUN)
    self.m_isLastBoard = false

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()

    local funcEnd = function (  )

        if self.m_isSuperGame then
            self.m_respinBoard_1:setRespinBarType( "isFinish" )
            self.m_respinBoard_2:setRespinBarType( "isFinish" )
        else
            self.m_respinBoard_2:setRespinBarType( "isFinish" )
        end
        

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        if self.m_isSuperGame then
            self.m_respinView_1:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        end

        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false
    end

    local isHaveQuickRun = false
    if self.m_respinIsQuickRun == true then
        self.m_respinIsQuickRun = false
        self:resetMoveNodeStatus() --重置镜头
        isHaveQuickRun = true
    end

    

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_isSuperGame then
        self.m_respinView_1:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    end
    
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end

    local continueFun = function()
        
        
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            self:respinBeforeEnd( function (  )
                funcEnd()
            end )
            
            return
        else
            --继续
            self:runNextReSpinReel()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
        
    end

    local funcGoon = function()
        if self.m_isSuperGame then
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            if selfData.reSpinCurReel ~= 0 and self.m_respinIsChanged == false then
                self.m_respinIsChanged = true
                --设置第二棋盘
                self.m_isSecondBoard = true

                local time = 0.1
                if isHaveQuickRun then --换棋盘等 镜头回去后进行
                    time = 0.6
                end
                self:delayCallBack(time, function (  )
                    --第一棋盘全满
                    if self:getIsFullWin("front") then
                        self.m_respinBoard_1:showMidActionFrame() --mid全满动画
                        self:respinDoubleAnim( "view1", function (  )
                            self:delayCallBack(0.5, function (  )
                                --结算第一棋盘
                                self:endFirstBoard(function()
                                    self:delayCallBack(0.5, function (  )
                                        --换棋盘
                                        self:runRespinRootScale_Change(function()
                                            continueFun()
                                        end, "change")
                                    end)
                                end)
                                
                            end)
                        end )
                    else
                        self:delayCallBack(0.5, function (  )
                            --结算第一棋盘
                            self:endFirstBoard(function()
                                self:delayCallBack(0.5, function (  )
                                    --换棋盘
                                    self:runRespinRootScale_Change(function()
                                        continueFun()
                                    end, "change")
                                end)
                            end)
                            
                        end)
                    end
                    
                end)
                

                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                self.m_respinBoard_1:setRespinBarType( "isFinish" )
                self.m_respinView_1:hideAllTip(  ) --1棋盘隐藏快滚框
            else
                continueFun()
            end
        else
            continueFun()
        end

    end

    --收集bonus2 bonus3
    local diffPosArray = self:getDifferencePosIdxs()
    if #diffPosArray > 0 then
        self:delayCallBack(0.5, function (  )
            self:playRespinBonus2Bonus3Select(function()
                funcGoon()
            end)
        end)
        
    else
        funcGoon()
    end
    


    -- self:delayCallBack(1, function()
        
    -- end)

    
    
end
--结算第一棋盘
function CodeGameScreenDragonParadeMachine:endFirstBoard(func)
    --结算触发动画
    local listBack = self.m_respinView_1:getAllCleaningNode()
    for i=1,#listBack do
        local node = listBack[i]
        node:runAnim("actionframe5", false, function (  )
            node:runAnim("idleframe2", true)
        end)
    end

    local finalWin1, totalMulti1 = self:getRespinFinalTotalWin( "front" )

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinover_totalwin_begin.mp3")

    self:delayCallBack(60/30, function()
        self:runBoardFlyNum(self.m_respinBoard_1, finalWin1)
        self:delayCallBack(240/60, function()
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{finalWin1, false, false})
            globalData.slotRunData.lastWinCoin = lastWinCoin

            self:playCoinWinEffectUI()

            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinover_totalwin_end.mp3")

            --winlabel 特效时间
            self:delayCallBack(40/60, function()
                func()
            end)
        end)
    end)
end
--respin全满双倍动画
function CodeGameScreenDragonParadeMachine:respinDoubleAnim( view, func )
    local respinView = nil
    local boardView = nil
    if view == "view1" then
        respinView = self.m_respinView_1
        boardView = self.m_respinBoard_1
    else
        respinView = self.m_respinView
        boardView = self.m_respinBoard_2
    end
    
    local symbolList = respinView:getAllCleaningNode()
    boardView:doubleEdgeEffectTriggerAnim() --棋盘边框特效

    --双倍触发动画
    for i=1,#symbolList do
        local symbolNode = symbolList[i]
        if symbolNode then
            symbolNode:runAnim("actionframe4", false, function (  )
                symbolNode:runAnim("idleframe2", true)
            end)
        end
    end

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_language_doubleluck.mp3")

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_double_trigger.mp3")

    --触发完 按个翻倍
    self:delayCallBack(120/60, function (  )
        self:respinDoubleOneByOne( symbolList, 1, function (  )
            func()
        end )
    end)

    
end

function CodeGameScreenDragonParadeMachine:respinDoubleOneByOne( array, idx, func )
    if idx > #array then
        self:delayCallBack(0.5, function()
            func()
        end)
        return
    end

    local symbolNode = array[idx]
    symbolNode:runAnim("actionframe4", false, function (  )
        symbolNode:runAnim("idleframe2", true)
    end)

    local doubleX2Node = util_createAnimation("DragonParade_Respin_chengbei.csb")
    local pos = util_convertToNodeSpace(symbolNode, self.m_upBottomEffectNode)
    self.m_upBottomEffectNode:addChild(doubleX2Node)
    doubleX2Node:setPosition(cc.p(pos))
    doubleX2Node:runCsbAction("actionframe", false, function()
        doubleX2Node:removeFromParent()
    end)

    if idx == 1 then
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_language_oh.mp3")
    end
    
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_double_single.mp3")

    if symbolNode.m_score then
        local score = symbolNode.m_score
        local oldScore = score
        score = score * 2
        symbolNode.m_score = score
        -- local scoreStr = self:formatCoins(score, 3)
        -- self:bonusShowScore(symbolNode, scoreStr)


        local aniNode = symbolNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        if spine then
            util_spineRemoveSlotBindNode(spine, "zi")
            spine.m_scoreViewNode = nil
            if not spine.m_scoreViewNode then
                local label = util_createAnimation("Socre_DragonParade_Bonus_Num1.csb")
                label:setScale(0.8)
                util_spinePushBindNode(spine, "zi", label)
                spine.m_scoreViewNode = label
                util_setCascadeOpacityEnabledRescursion(spine, true)
            end
            spine.m_scoreViewNode:setVisible(true)
            spine.m_scoreViewNode:findChild("m_lb_coins"):setString(_scoreStr)
            self:updateLabelSize({label=spine.m_scoreViewNode:findChild("m_lb_coins"),sx=1,sy=1},162)

            -- util_formatCoins(coins, obligate, notCut, true, true, useRealObligate)

            local addValue = oldScore / 30
            util_jumpNum(spine.m_scoreViewNode:findChild("m_lb_coins"), oldScore, score, addValue, 1 / 60, {3, nil, true, true}, "", nil, function()
            end, function()
                local info1={label=spine.m_scoreViewNode:findChild("m_lb_coins"),sx=1,sy=1}
                self:updateLabelSize(info1,162)
            end)
        end


        self:delayCallBack(15/30, function()
            local idx = idx + 1
            self:respinDoubleOneByOne( array, idx, func )
        end)
    else
        local idx = idx + 1
        self:respinDoubleOneByOne( array, idx, func )
    end
    
end

function CodeGameScreenDragonParadeMachine:respinOneReelDown( col, newFixedNum )
    if self.m_isSuperGame then
        if self.m_isSecondBoard then
            if newFixedNum > 0 then
                self.m_respinMidCount_2 = self.m_respinMidCount_2 + newFixedNum
                self.m_respinBoard_2:setbonusTotalCount( self.m_respinMidCount_2 )
            end
        else
            if newFixedNum > 0 then
                self.m_respinMidCount_1 = self.m_respinMidCount_1 + newFixedNum
                self.m_respinBoard_1:setbonusTotalCount( self.m_respinMidCount_1 )
            end
        end
    else
        if newFixedNum > 0 then
            self.m_respinMidCount_2 = self.m_respinMidCount_2 + newFixedNum
            self.m_respinBoard_2:setbonusTotalCount( self.m_respinMidCount_2 )
        end
    end
end
--获取storeicons 对应的bonus分数
function CodeGameScreenDragonParadeMachine:getStoreIconsBonusScore(posIdx)
    local score = self:getReSpinSymbolScore(posIdx) 
    local lineBet = globalData.slotRunData:getCurTotalBet()
    score = score * lineBet
    return score
end
--更新上次storeicons
function CodeGameScreenDragonParadeMachine:updateLastRespinStoreIcons()
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}

    self.m_respinLastStoreIcons = {}
    for i=1, #storedIcons do
        local values = storedIcons[i][1]
        table.insert(self.m_respinLastStoreIcons, values)
    end

    --按纵向走排序
    table.sort(self.m_respinLastStoreIcons, function(a, b)
        -- local aPos = a[1]
        -- local bPos = b[1]
        local posA = self:getRowAndColByPos(a)
        local posB = self:getRowAndColByPos(b)

        if posA.iY == posB.iY then
            return posA.iX > posB.iX
        else
            return posA.iY < posB.iY
        end
    end)

end
--获取新出现的位置
function CodeGameScreenDragonParadeMachine:getDifferencePosIdxs(type)
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local ret = {}
    for i=1, #storedIcons do
        local values = storedIcons[i]
        local isHave = false
        for j = 1, #self.m_respinLastStoreIcons do
            local lastValues = self.m_respinLastStoreIcons[j]
            if lastValues == values[1] then
                isHave = true
            end
        end
        if not isHave then
            table.insert(ret, values[1])
        end
    end

    --按纵向走排序
    table.sort(ret, function(a, b)
        -- local aPos = a[1]
        -- local bPos = b[1]
        local posA = self:getRowAndColByPos(a)
        local posB = self:getRowAndColByPos(b)

        if posA.iY == posB.iY then
            return posA.iX > posB.iX
        else
            return posA.iY < posB.iY
        end
    end)

    return ret
end

function CodeGameScreenDragonParadeMachine:playRespinBonus2Bonus3Select(func)
    local diffPosArray = self:getDifferencePosIdxs()
    for i=1,#diffPosArray do --转0~14
        if diffPosArray[i] > 14 then
            diffPosArray[i] = diffPosArray[i] - 15
        end
    end

    local sortTable = function( sortArray , type)
        table.sort(sortArray, function(a, b)
            local posA = self:getRowAndColByPos(a)
            local posB = self:getRowAndColByPos(b)
    
            local symbolTypeA = self:getAppearSymbolType(type, a)
            local symbolTypeB = self:getAppearSymbolType(type, b)
            if symbolTypeA == symbolTypeB then
                if posA.iY == posB.iY then
                    return posA.iX > posB.iX
                else
                    return posA.iY < posB.iY
                end
            else
                return symbolTypeA < symbolTypeB
            end
            
        end)
    end

    --view1  双棋盘上棋盘 upreel是否去upreel数据
    if self.m_isSuperGame then
        if self.m_isSecondBoard then
            
            sortTable(diffPosArray, "upreel") --和信号值一起排序 先收集同类型的

            self:playRespinBonus23Collect(nil, "upreel", diffPosArray, 1, function()
                func()
            end)
        else
            sortTable(diffPosArray, nil)
            self:playRespinBonus23Collect("view1", nil, diffPosArray, 1, function()
                func()
            end)
        end
    else
        sortTable(diffPosArray, nil)
        self:playRespinBonus23Collect(nil, nil, diffPosArray, 1, function()
            func()
        end)
    end
    
end

function CodeGameScreenDragonParadeMachine:playRespinBonus23Collect(view, upreel, array, idx, func)
    if idx > #array then
        self:delayCallBack(1, function (  )
            func()
        end)
        
        return
    end

    local posData = array[idx]
    local posIdx = posData

    local viewLocal = self.m_respinView
    if view == "view1" then
        viewLocal = self.m_respinView_1
    end

    local symbolType = self:getAppearSymbolType(upreel, posIdx)
    self.m_respinCollectOnceTotalScore = 0 --重置收集score
    local endNode = viewLocal:getOneCleaningNode(posIdx)
    if symbolType == self.SYMBOL_BONUS2 then
        endNode:runAnim("start", false)
        local oldOrder = endNode:getLocalZOrder()
        endNode:setLocalZOrder(5000)
        --收集初始的锁定块
        local initLockNodes = viewLocal:getInitLockNode()
        
        self:delayCallBack(0.2, function (  )
            --收集
            self:playCurrentLockCollect(initLockNodes, 1, endNode, function()
                endNode:runAnim("over", false, function()
                    endNode:setLocalZOrder(oldOrder)
                    endNode:runAnim("idleframe2", true)
                end)
                --收集完一个bonus2
                local addScore = self.m_respinCollectOnceTotalScore

                if view == "view1" then
                    self.m_respinRightCount_1 = self.m_respinRightCount_1 + addScore
                    local scoreStr = self:formatCoins(self.m_respinRightCount_1, 3)
                    self.m_respinBoard_1:setBonus3TotalWinNum( scoreStr , true)
                else
                    self.m_respinRightCount_2 = self.m_respinRightCount_2 + addScore
                    local scoreStr = self:formatCoins(self.m_respinRightCount_2, 3)
                    self.m_respinBoard_2:setBonus3TotalWinNum( scoreStr , true)
                end

                --递归
                local idx = idx + 1
                self:playRespinBonus23Collect(view, upreel, array, idx, func)
            end, "bonus2")
        end)

        
    elseif symbolType == self.SYMBOL_BONUS3 then
        endNode:runAnim("start", false)
        local oldOrder = endNode:getLocalZOrder()
        endNode:setLocalZOrder(5000)
        --收集除未收集的所有
        local allLockNodes = viewLocal:getAllCleaningNode()
        local cutLockNodes = {}
        for i = 1, #allLockNodes do
            local symbolNode = allLockNodes[i]
            local posIdx = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
            
            --如果获取的锁定块 是当前array递归中的当前及以后的 需要刨除去
            local needCut = false
            for i = idx, #array do
                if posIdx == array[i] then
                    needCut = true
                end
            end
            if not needCut then
                table.insert(cutLockNodes, symbolNode)
            end
        end

        --收集顺序 红-黄-绿
        table.sort(cutLockNodes, function ( a, b )
            if a.p_symbolType == b.p_symbolType then
                if a.p_cloumnIndex == b.p_cloumnIndex then
                    return a.p_rowIndex > b.p_rowIndex
                else
                    return a.p_cloumnIndex < b.p_cloumnIndex
                end
            else
                return a.p_symbolType < b.p_symbolType
            end
        end)

        self:delayCallBack(0.2, function (  )
            --收集
            self:playCurrentLockCollect(cutLockNodes, 1, endNode, function()
                endNode:runAnim("over", false, function()
                    endNode:setLocalZOrder(oldOrder)
                    endNode:runAnim("idleframe2", true)
                end)
                --收集完一个bonus3
                local addScore = self.m_respinCollectOnceTotalScore

                if view == "view1" then
                    self.m_respinRightCount_1 = self.m_respinRightCount_1 + addScore
                    local scoreStr = self:formatCoins(self.m_respinRightCount_1, 3)
                    self.m_respinBoard_1:setBonus3TotalWinNum( scoreStr , true)
                else
                    self.m_respinRightCount_2 = self.m_respinRightCount_2 + addScore
                    local scoreStr = self:formatCoins(self.m_respinRightCount_2, 3)
                    self.m_respinBoard_2:setBonus3TotalWinNum( scoreStr , true)
                end

                --递归
                local idx = idx + 1
                self:playRespinBonus23Collect(view, upreel, array, idx, func)
            end, "bonus3")
        end)
        
    end


    

end
--收集本轮锁定的
function CodeGameScreenDragonParadeMachine:playCurrentLockCollect(array, idx, endNode, func, whichBonus)
    if idx > #array then
        self:delayCallBack(0.5, function (  )
            func()
        end)
        
        return
    end

    local beginNode = array[idx]
    local score = beginNode.m_score or 0
    self.m_respinCollectOnceTotalScore = self.m_respinCollectOnceTotalScore + score

    local startPos = beginNode:getParent():convertToWorldSpace(cc.p(beginNode:getPosition()))
    local endPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))

    beginNode:runAnim("actionframe2", false, function()
        beginNode:runAnim("idleframe2", true)
    end)

    
    if whichBonus == "bonus3" then

    end
    local flyTime = 0.4
    local whichIdx = 1
    if beginNode.p_symbolType == self.SYMBOL_BONUS1 then
        -- if whichBonus == "bonus3" then
        --     gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_bonuscollect_flybegin_1_3.mp3")
        -- else
        --     gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_bonuscollect_flybegin_1_2.mp3")
        -- end
    elseif beginNode.p_symbolType == self.SYMBOL_BONUS2 then
        whichIdx = 2
        flyTime = 0.6
        -- if whichBonus == "bonus3" then
        --     gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_bonuscollect_flybegin_2_3.mp3")
        -- end
    elseif beginNode.p_symbolType == self.SYMBOL_BONUS3 then
        whichIdx = 3
        flyTime = 0.8
        -- if whichBonus == "bonus3" then
        --     gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_bonuscollect_flybegin_3_3.mp3")
        -- end
    end
    self:runRespinBonus23FlyAction(0, flyTime,startPos,endPos,function()
        
        if whichBonus == "bonus3" then
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_bonuscollect_flyend_" .. whichIdx ..  "_3.mp3")
        else
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_bonuscollect_flyend_1_2.mp3")
        end

        endNode.m_score = self.m_respinCollectOnceTotalScore

        local scoreStr = self:formatCoins(self.m_respinCollectOnceTotalScore, 3)
        self:bonusShowScore(endNode, scoreStr)

        local dTime = 0
        local tempIdx = idx
        if tempIdx+1 <= #array then
            local nextNode = array[tempIdx+1]
            if beginNode.p_symbolType == self.SYMBOL_BONUS1 and nextNode.p_symbolType == self.SYMBOL_BONUS2 then
                dTime = 0.3
            elseif beginNode.p_symbolType == self.SYMBOL_BONUS2 and nextNode.p_symbolType == self.SYMBOL_BONUS3 then
                dTime = 0.5
            end
        end

        self:delayCallBack(dTime, function (  )
            local idx = idx + 1
            self:playCurrentLockCollect(array, idx, endNode, func, whichBonus)
        end)
        
    end, score, endNode)

end

function CodeGameScreenDragonParadeMachine:runRespinBonus23FlyAction(time,flyTime,startPos,endPos,callback, score, endNode)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = util_createAnimation("Socre_DragonParade_Bonus_Num1.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    local scoreStr = self:formatCoins(score, 3)
    node:findChild("m_lb_coins"):setString(scoreStr)
    self:updateLabelSize({label=node:findChild("m_lb_coins"),sx=1,sy=1},162)
    node:setScale(0.8)
    node:setVisible(false)
    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)

        endNode:runAnim("actionframe3", false, function()
            -- endNode:runAnim("idleframe2", true)
        end)
    end)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(1)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        
        node:removeFromParent()
    end)
    node:runAction(cc.Sequence:create(actionList))
end


function CodeGameScreenDragonParadeMachine:getAppearSymbolType(type, _posIdx)
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    local runResultData = self.m_runSpinResultData.p_reels

    if type == "upreel" then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        if selfData.upReels then
            runResultData = selfData.upReels
        end
    end
    

    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolType = runResultData[reelRow - i + 1][j]
            local posIdx = self:getPosReelIdx(i, j)
            if posIdx == _posIdx then
                return symbolType
            end
        end
    end
    return nil
end


function CodeGameScreenDragonParadeMachine:reSpinEndAction()
    performWithDelay(self, function()
        if self.m_isSuperGame then
            local listFront = self.m_respinView:getAllCleaningNode()
            for i=1,#listFront do
                local node = listFront[i]
                node:runAnim("actionframe5", false, function (  )
                    node:runAnim("idleframe2", true)
                end)
            end
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinover_totalwin_begin.mp3")

            local finalWin2, totalMulti2 = self:getRespinFinalTotalWin( )

            self:delayCallBack(60/30, function()
                self:runBoardFlyNum(self.m_respinBoard_2, finalWin2)
                self:delayCallBack(240/60, function()
                    self.m_bottomUI:setNewWinTime(1.5)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{finalWin2, false, true})
                    self.m_bottomUI:setNewWinTime(0)
                    self:playCoinWinEffectUI()

                    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinover_totalwin_end.mp3")

                    self:delayCallBack(1.5 + 0.4, function()
                        self:respinOver()
                    end)
                end)
            end)
        else
            local listBack = self.m_respinView:getAllCleaningNode()
            for i=1,#listBack do
                local node = listBack[i]
                node:runAnim("actionframe5", false, function (  )
                    node:runAnim("idleframe2", true)
                end)
            end
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinover_totalwin_begin.mp3")


            self:delayCallBack(60/30, function()
                self:runBoardFlyNum(self.m_respinBoard_2, self.m_serverWinCoins)
                self:delayCallBack(240/60, function()
                    local win = self.m_serverWinCoins
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{win, false, false})
                    self:playCoinWinEffectUI()

                    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinover_totalwin_end.mp3")
                    self:delayCallBack(0.4 + 40/60, function()
                        self:respinOver()
                    end)
                end)
            end)

        end
        
    end, 0.5)
    
end

function CodeGameScreenDragonParadeMachine:runBoardFlyNum(board, coins)
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_final_num_jump.mp3")

    board:runEdgeDark()

    local flyNumNode = util_createAnimation("DragonParade_Respin_shuzi.csb")
    self:jumpNodeNum(flyNumNode:findChild("m_lb_coins"), coins)
    flyNumNode:runCsbAction("actionframe", false)
    self.m_upBottomEffectNode:addChild(flyNumNode)
    local startPos = util_convertToNodeSpace(board:findChild("respin_win_num"), self.m_upBottomEffectNode)
    flyNumNode:setPosition(cc.p(startPos))

    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode, self.m_upBottomEffectNode)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(220/60)
    actionList[#actionList + 1] = cc.MoveTo:create(20/60, endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        flyNumNode:findChild("m_lb_coins"):unscheduleUpdate()
        flyNumNode:removeFromParent()
    end)
    flyNumNode:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenDragonParadeMachine:jumpNodeNum(labelNum, coins)
    -- local labelNum = lightAni:findChild("m_lb_coins")
    -- local coins = self.m_iOnceSpinLastWin
    self:updateLabelSize({label=labelNum, sx = 1, sy = 1},502)
    labelNum:setString("")
    local addValue = coins / 60
    util_jumpNum(labelNum, 0, coins, addValue, 1 / 60, {30}, "", nil, function()
    end, function()
        local info1={label=labelNum,sx=1,sy=1}
        self:updateLabelSize(info1,502)
    end)

end

function CodeGameScreenDragonParadeMachine:respinOver()
    self.m_isSuperGame = false
    self.m_isSecondBoard = false
    self.m_isLastBoard = false

    self:setReelSlotsNodeVisible(true)
    self:changeTouchSpinLayerSize(false)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    
    self:showRespinOverView()
    --改
    self.m_respinQuickEffect:removeAllChildren()
end

function CodeGameScreenDragonParadeMachine:showRespinOverView(effectData)
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local view=self:showReSpinOver(strCoins,function()
        self:showTrans(nil, function (  )
            self.m_respinBoard_1:setPos2() --清理块时 设置到base位置
            self.m_respinBoard_2:setPos2()
            self:removeRespinNode()
            self:changeBlankSymbolToRandom(  )
            
            --还原scale
            local scaleNode = self:findChild("Node_Scale")
            scaleNode:setScale(1)

            
            self:changeUIBG("base")
            self.m_jackpotBar:setVisible(true)
            self.m_jackpotBar:runCsbAction("idle", true)
            self.m_respinBoard_1:setVisible(false)
            self.m_respinBoard_2:setVisible(false)

            --更新锁定
            self:updateBetLockNode()
        end, function (  )
            self:setCurrSpinMode( NORMAL_SPIN_MODE)
            self:triggerReSpinOverCallFun(self.m_lightScore)
        end)

        
    end)
    local node = view:findChild("m_lb_coins")
    self:updateLabelSize({label=node,sx=1,sy=1},631)

    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinover_pupup_begin.mp3")
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_click.mp3")
        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respinover_pupup_end.mp3")
    end)
end

--结束移除小块调用结算特效
function CodeGameScreenDragonParadeMachine:removeRespinNode()
    CodeGameScreenDragonParadeMachine.super.removeRespinNode(self)
    -- if self.m_isSuperGame then
    -- end
    if self.m_respinView_1== nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode1 = self.m_respinView_1:getAllEndSlotsNode()
    for i = 1, #allEndNode1 do
        local node = allEndNode1[i]
        node:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
    end
    self.m_respinView_1:removeFromParent()
    self.m_respinView_1 = nil
end

--改变blank小块到随机
function CodeGameScreenDragonParadeMachine:changeBlankSymbolToRandom(  )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 3, 1, -1 do
            local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if symbolNode then
                if symbolNode.p_symbolType == self.SYMBOL_FIX_BLANK or
                symbolNode.p_symbolType == self.SYMBOL_BONUS1 or
                symbolNode.p_symbolType == self.SYMBOL_BONUS2 or
                symbolNode.p_symbolType == self.SYMBOL_BONUS3 then
                    self:changeSymbolType(symbolNode, math.random(0,7))
                    -- self:bonusShowScore(symbolNode, "")
                end
            end
        end
    end
end

--[[
    初始轮盘
]]
function CodeGameScreenDragonParadeMachine:initRandomSlotNodes()
    if type(self.m_configData.isHaveInitReel) == "function" and self.m_configData:isHaveInitReel() then
        self.m_initReelBonus = true
        self:initSlotNodes()
        self.m_initReelBonus = false
    else
        if self.m_currentReelStripData == nil then
            self:randomSlotNodes()
        else
            self:randomSlotNodesByReel()
        end
    end
    self:firstInit()
end

function CodeGameScreenDragonParadeMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol, _isLastReel)
    if isLastSymbol == nil then
        isLastSymbol = false
    end
    local symblNode = self:getSlotNodeBySymbolType(symbolType)
    symblNode.p_cloumnIndex = col
    symblNode.p_rowIndex = row
    symblNode.m_isLastSymbol = isLastSymbol

    self:updateReelGridNode(symblNode, _isLastReel)
    self:checkAddSignOnSymbol(symblNode)
    return symblNode
end

--刷新小块
function CodeGameScreenDragonParadeMachine:updateReelGridNode(node, _isLastReel)
    local isLastReel = _isLastReel
    self:removeSlotsNodeCorner(node)

    if self:isWildSymbol(node.p_symbolType) then
        self:setSlotsNodeCornerNum(node, 3)
    end

    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        if symbolType == self.SYMBOL_BONUS1 or symbolType == self.SYMBOL_BONUS4 then
            self:setSpecialNodeScore(node, isLastReel)
        else
            self:bonusShowScore(node, "")
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if symbolType == self.SYMBOL_BONUS2 then
            local scoreStr = self:getFreeOneBonus2Value(true)
            self:bonusShowScore(node, scoreStr)
        end
        
    end

    -- if self:isWildSymbol(symbolType) then
    --     self:wildChangeShow(node)
    -- end
end

-- 给respin小块进行赋值
function CodeGameScreenDragonParadeMachine:setSpecialNodeScore(symbolNode, _isLastReel)
    local isLastReel = _isLastReel
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType then
        return
    end

    local score = 0
    if iRow ~= nil and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        local symbolIndex = self:getPosReelIdx(iRow, iCol)
        if isLastReel or self.m_isLastBoard then
            symbolIndex = symbolIndex + 15
        end
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
    else
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    
    if symbolNode and symbolNode.p_symbolType then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        --初始化棋盘都是5倍的bet
        if self.m_initReelBonus then
            score = 5
        end
        score = score * lineBet
        symbolNode.m_score = score
        
        score = self:formatCoins(score, 3)
        self:bonusShowScore(symbolNode, score)
        
    end

end

function CodeGameScreenDragonParadeMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    
    if symbolType == self.SYMBOL_BONUS1 or symbolType == self.SYMBOL_BONUS4 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenDragonParadeMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local score = nil
    local idNode = nil

    local func = function(_id)
        for i=1, #storedIcons do
            local values = storedIcons[i]
            if values[1] == _id then
                score = values[2]
                idNode = values[1]
            end
        end
    end
    func(id)
    

    if score == nil then
        return self:randomDownRespinSymbolScore(self.SYMBOL_FIX_SYMBOL)
    end

    return score
end
--是否全满赢
function CodeGameScreenDragonParadeMachine:getIsFullWin(isFront)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}

    local num = 0
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if isFront == "front" then
            if values[1] <= 14 then
                num = num + 1
            end
        else
            if values[1] > 14 then
                num = num + 1
            end
        end
    end
    if num == 15 then
        return true
    end
    return false
end
--获取respin最后总赢钱 2倍的话  前端x2 
function CodeGameScreenDragonParadeMachine:getRespinFinalTotalWin( isFront )
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}

    local num = 0
    local totalMulti = 0
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if isFront == "front" then
            if values[1] <= 14 then
                totalMulti = totalMulti + values[2]
                num = num + 1
            end
        else
            if values[1] > 14 then
                totalMulti = totalMulti + values[2]
                num = num + 1
            end
        end
    end
    --全满
    if num == 15 then
        totalMulti = totalMulti * 2
    end

    local finalWin = 0
    local lineBet = globalData.slotRunData:getCurTotalBet()
    finalWin = totalMulti * lineBet
    return finalWin, totalMulti
end

--[[
    显示bonus分数
]]
function CodeGameScreenDragonParadeMachine:bonusShowScore(_symbolNode, _scoreStr)
    if _symbolNode then
        local aniNode = _symbolNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        if spine then
            util_spineRemoveSlotBindNode(spine, "zi")
            spine.m_scoreViewNode = nil
            if not spine.m_scoreViewNode then
                -- util_spineRemoveSlotBindNode(spine, "zi")
                
                local label = util_createAnimation("Socre_DragonParade_Bonus_Num1.csb")
                 
                label:setScale(0.8)
                util_spinePushBindNode(spine, "zi", label)
                spine.m_scoreViewNode = label

                util_setCascadeOpacityEnabledRescursion(spine, true)
                
            end
            spine.m_scoreViewNode:setVisible(true)
            spine.m_scoreViewNode:findChild("m_lb_coins"):setString(_scoreStr)
            self:updateLabelSize({label=spine.m_scoreViewNode:findChild("m_lb_coins"),sx=1,sy=1},162)
        end

        -- local csbNode = aniNode.m_spineNode
        -- if csbNode then
        --     if not csbNode.m_scoreViewNode then
        --         local label = util_createAnimation("Socre_DragonParade_Bonus_Num1.csb")
                 
        --         -- label:setScale(0.8)
        --         csbNode:addChild(label)
        --         csbNode.m_scoreViewNode = label

        --         util_setCascadeOpacityEnabledRescursion(csbNode, true)
                
        --     end
        --     csbNode.m_scoreViewNode:setVisible(true)
        --     csbNode.m_scoreViewNode:findChild("m_lb_coins"):setString(_scoreStr)
        --     self:updateLabelSize({label=csbNode.m_scoreViewNode:findChild("m_lb_coins"),sx=1,sy=1},162)
        -- end
    end
end
--缩放节点
function CodeGameScreenDragonParadeMachine:scaleOneNode(scaleCur, scaleTo, time, func)
    
    local scaleNode = self:findChild("Node_Scale")
    local curScale = scaleCur or scaleNode:getScale()
    scaleNode:setScale(curScale)

    local actionList={}
    actionList[#actionList+1] = cc.ScaleTo:create(time, scaleTo)
    local seq=cc.Sequence:create(actionList)
    scaleNode:runAction(seq)

    performWithDelay(self, function()
        scaleNode:setScale(scaleTo)
        if func then
            func()
        end
    end, time)
end
--初始分棋盘
function CodeGameScreenDragonParadeMachine:runRespinRootScale_Init(func)
    local time = 120/60
    
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_board_move_up.mp3")

    --缩小
    self:scaleOneNode(nil, 0.8, time, function (  )
        
    end)
    self:shakeOneNodeForever(self.m_respinBoardRoot:findChild("Node_qipan"), time)

    self.m_respinBoard_1:setVisible(true)
    self.m_respinBoard_1:runMove_pos2ToUp(time, function (  )
        self:delayCallBack(1, function (  ) --展示 1s
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_board_move_down.mp3")

            self.m_respinBoard_1:runMove_posUpTo1(60/60, function (  )

            end)
            --下面压黑
            self.m_respinBoard_2:showDark(  )

            --放大
            self:scaleOneNode(nil, 1, 60/60, function()
                if func then
                    func()
                end
            end)

            --jackpot 显示
            self.m_jackpotBar:setVisible(true)
            self.m_jackpotBar:runCsbAction("start", false, function (  )
                self.m_jackpotBar:runCsbAction("idle", true)
            end)
        end)
        
    end)

end
--换棋盘
function CodeGameScreenDragonParadeMachine:runRespinRootScale_Change(func, type)
    local time = 60/60

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_board_move_up.mp3")
    --缩小
    self:scaleOneNode(nil, 0.8, time, function (  )
        
    end)

    self.m_jackpotBar:runCsbAction("over", false, function (  )
        self.m_jackpotBar:setVisible(false)
    end)

    --拉开棋盘
    self.m_respinBoard_1:runMove_pos1ToUp(time, function (  )
        self:delayCallBack(1, function (  ) --展示 1s
            local time_back = 60/60
            gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_board_move_down.mp3")
            --放大
            self:scaleOneNode(nil, 1, time_back, function()
                if func then
                    func()
                end
            end)
            --中途 换complete位置
            self:delayCallBack(20/60, function (  )
                self.m_respinBoard_1:setRespinBarPos(true)
            end)
            
            self.m_respinBoard_2:runMove_pos2To1(time_back, function (  )
                
            end)
            self.m_respinBoard_2:setFrontOrder()
    
            self.m_respinBoard_1:runMove_posUpTo2(time_back, function (  )
                
            end)
            self.m_respinBoard_1:setBackOrder()

            self.m_respinBoard_1:showDark() --压暗

            self.m_jackpotBar:setVisible(true)
            self.m_jackpotBar:runCsbAction("start", false, function (  )
                self.m_jackpotBar:runCsbAction("idle", true)
            end)
        end)
        
    end)
    --取消压暗
    self.m_respinBoard_2:hideDark()
    
end

--棋盘final Over
function CodeGameScreenDragonParadeMachine:runRespinRootScale_Over(func)
    local time = 60/60
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_board_move_up.mp3")
    --缩小
    self:scaleOneNode(nil, 0.8, time, function (  )
        
    end)

    self.m_respinBoard_2:runMove_pos1ToUp(time, function (  )
        self:delayCallBack(0.5, function (  ) --拉开棋盘后延迟0.5秒
            func()
        end)
        
    end)
    self.m_respinBoard_1:hideDark(  )

    self.m_jackpotBar:runCsbAction("over", false, function (  )
        self.m_jackpotBar:setVisible(false)
    end)

end

--创建锁定块
function CodeGameScreenDragonParadeMachine:createOneLockNode(_posIndex, _symbolType)

    local node = util_require("CodeDragonParadeSrc.DragonParadeLockNode"):create(self, 1, _symbolType)
    local parentNode = self.m_baseWildLockNodes[_posIndex]
    parentNode:addChild(node, 1, 1)
    node:setPosition(util_getOneGameReelsTarSpPos(self, _posIndex))

    return node

end

function CodeGameScreenDragonParadeMachine:clearLockNode(_idx)
    for i, v in pairs(self.m_baseWildLockNodes) do
        if v then
            if _idx then
                if _idx == i then
                    v:removeAllChildren()
                end
            else
                v:removeAllChildren()
            end
        end
    end
end

function CodeGameScreenDragonParadeMachine:hideLockNode(_checkLine)
    for i, v in pairs(self.m_baseWildLockNodes) do
        if v then
            if _checkLine then --不连线的不隐藏
                if self:isPosInLine(i) then
                    v:setVisible(false)
                end
            else
                v:setVisible(false)
            end
        end
    end
end

function CodeGameScreenDragonParadeMachine:showLockNode()
    for i, v in pairs(self.m_baseWildLockNodes) do
        if v then
            v:setVisible(true)

            local lockNode = v:getChildByTag(1)
            if lockNode then
                lockNode:resetStatus()
            end
        end
    end
end

--判断Pos是否在连线中
function CodeGameScreenDragonParadeMachine:isPosInLine(_Pos)
    if self.m_reelResultLines ~= nil then
        for i,w in ipairs(self.m_reelResultLines) do
            for j,v in ipairs(self.m_reelResultLines[i].vecValidMatrixSymPos) do
                local posIdx = self:getPosReelIdx(v.iX, v.iY)
                if _Pos == posIdx then
                    return true
                end
            end
        end
    end
    return false
end

function CodeGameScreenDragonParadeMachine:orderLockNode(_order)
    for i, v in pairs(self.m_baseWildLockNodes) do
        if v then
            v:setLocalZOrder(_order + i)
        end
    end
end

--更新base锁定块 初始 切bet .eg
function CodeGameScreenDragonParadeMachine:updateBetLockNode(_ignorePos)
    -- local ignorePos = _ignorePos or {}
    self:clearLockNode()
    self:showLockNode()

    local data = self:getStickWildData()

    local wildIconsPos = data.wildPos or {}
    local leftCount = data.wildLeftTimes or 0

    for i = 1, #wildIconsPos do
        local pos = wildIconsPos[i]
        if self.m_baseWildLockNodes[pos] then
            local lockNode = self.m_baseWildLockNodes[pos]:getChildByTag(1)
            if not lockNode then
                lockNode = self:createOneLockNode(pos, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                lockNode:updateCornerNum(leftCount)
                lockNode:runIdleAction()
            end
        end
    end

    --left
    if leftCount > 0 then
        self.m_baseLeftBar:setNum(leftCount)
        self.m_baseLeftBar:setVisible(true)
        self.m_baseLeftBar:findChild("Node_1"):setOpacity(255)
    else
        self.m_baseLeftBar:setNum(3)
        self.m_baseLeftBar:setVisible(false)
    end
    
end

function CodeGameScreenDragonParadeMachine:showEffect_LineFrame(effectData)
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        self:baseLockWildReplaceReelGrid()
        self:hideLockNode(true)
    end
    return CodeGameScreenDragonParadeMachine.super.showEffect_LineFrame(self, effectData)

end

function CodeGameScreenDragonParadeMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > #winLines then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self.m_lineChangeTime = xcyy.SlotsUtil:getMilliSeconds() --改 加个延时时间的记录
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                self:playInLineNodesIdle()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end
                self.m_lineChangeTime = xcyy.SlotsUtil:getMilliSeconds() --改 加个延时时间的记录
                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    self.m_lineChangeTime = xcyy.SlotsUtil:getMilliSeconds() --改 加个延时时间的记录
    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- end
        self:showAllFrame(winLines) -- 播放全部线框
        -- if #winLines > 1 then
        showLienFrameByIndex()
    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end
        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end

--连线
--固定的替换到棋盘
function CodeGameScreenDragonParadeMachine:baseLockWildReplaceReelGrid()
    local stickData = self:getStickWildData()
    local wildIconsPos = stickData.wildPos or {}
    local leftCount = stickData.wildLeftTimes or 0

    for i = 1, #wildIconsPos do
        local posIdx = wildIconsPos[i]
        if self:isPosInLine(posIdx) then
            local pos = self:getRowAndColByPos(posIdx)
            local row = pos.iX
            local col = pos.iY
            local targSp =  self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
            if targSp then
                self:changeSymbolType(targSp, self:timesToWildSymbol(leftCount))
                self:setSlotsNodeCornerNum(targSp, leftCount)
            end
        end
    end
end

--重写
function CodeGameScreenDragonParadeMachine:beginReel()
    self.m_baseWildResetDelayTime = 0
    self:beforeBeginReel(function()
        CodeGameScreenDragonParadeMachine.super.beginReel(self)
    end)
end

function CodeGameScreenDragonParadeMachine:beforeBeginReel(_func)
    --base下 锁定逻辑
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        self:addBaseLockNode()

        self:showLockNode()
    
        local stickData = self:getStickWildData()
        local wildIconsPos = stickData.wildPos or {}
        local leftCount = stickData.wildLeftTimes or 0
    
        local isChangeNum = false
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local posIdx = self:getPosReelIdx(iRow, iCol)
                local isLock = false
                for i = 1, #wildIconsPos do
                    if wildIconsPos[i] == posIdx then
                        isLock = true--判断数据上是有的
                    end
                end
                
                if self.m_baseWildLockNodes[posIdx] then
                    local lockNode = self.m_baseWildLockNodes[posIdx]:getChildByTag(1)
                    if lockNode and isLock then --数据与实体都存在
                        if leftCount == 1 then
                            --次数1 滚走时
                            local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
                            if symbolNode then
                                self:changeSymbolType(symbolNode, 102)
                                self.m_baseWildLockNodes[posIdx]:removeAllChildren()
                                self:setSlotsNodeCornerNum(symbolNode, 1)
                            end
                        else
                            lockNode:updateCornerNum(math.max(leftCount - 1, 0), true)
                            isChangeNum = true
                        end
                    end
                end
            end
        end
    
        if leftCount - 1 > 0 then
            --更新base leftBar
            self.m_baseLeftBar:setNum( leftCount - 1 )
        else
            self.m_baseLeftBar:hideView()
        end
        
    end

    

    self:delayCallBack(0, function()
        if _func then
            _func()
        end
    end)
end

--设置symbol数字值
function CodeGameScreenDragonParadeMachine:setSlotsNodeCornerNum(_symblNode, _num)
            

    if _symblNode then
        local aniNode = _symblNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        if spine then
            util_spineRemoveSlotBindNode(spine, "guadian")
            spine.m_wildTimesNode = nil
            if not spine.m_wildTimesNode then
                local label = util_createAnimation("Socre_DragonParade_Wild_Num1.csb")
                 
                -- label:setScale(0.8)
                util_spinePushBindNode(spine, "guadian", label)
                spine.m_wildTimesNode = label

                util_setCascadeOpacityEnabledRescursion(spine, true)
                
            end

            spine.m_wildTimesNode:findChild("m_lb_coins"):setString(_num)
        end
    end
end
function CodeGameScreenDragonParadeMachine:removeSlotsNodeCorner(_symblNode)
    if _symblNode then
        local aniNode = _symblNode:checkLoadCCbNode()
        local spine = aniNode.m_spineNode
        if spine then
            util_spineRemoveSlotBindNode(spine, "guadian")
        end
    end
end
--新增锁定块
function CodeGameScreenDragonParadeMachine:addBaseLockNode()

    local stickData = self:getStickWildData()
    local wildIconsPos = stickData.wildPos or {}
    local leftCount = stickData.wildLeftTimes or 0

    if wildIconsPos and #wildIconsPos > 0 then
        for i = 1, #wildIconsPos do
            local pos = wildIconsPos[i]
            if self.m_baseWildLockNodes[pos] then
                local lockNode = self.m_baseWildLockNodes[pos]:getChildByTag(1)
                if leftCount == 3 then
                    if not lockNode then
                        lockNode = self:createOneLockNode(pos, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                        lockNode:updateCornerNum(leftCount)
                    else
                        
                    end
                end
            end
        end
    else
        self:clearLockNode()
    end
end
--更新锁定块 更新次数
function CodeGameScreenDragonParadeMachine:updateBaseLockNode()

    local stickData = self:getStickWildData()
    local wildIconsPos = stickData.wildPos or {}
    local leftCount = stickData.wildLeftTimes or 0

    local isPlaySoundEffect = true
    for i = 1, #wildIconsPos do
        local pos = wildIconsPos[i]
        if self.m_baseWildLockNodes[pos] then
            local lockNode = self.m_baseWildLockNodes[pos]:getChildByTag(1)
            --只更新了 已加入锁定数组里的 新出现的未加入的没有更新
            if lockNode then
                

                local moveTime = self.m_configData.p_reelResTime or 0.1
                if self:getGameSpinStage() == QUICK_RUN then
                    self.m_baseWildResetDelayTime = 0 --快停不做处理
                else
                    self.m_baseWildResetDelayTime = math.max(0.5 - moveTime, 0) --重置的延时0.5秒
                end

                -- 重置次数音效
                if isPlaySoundEffect and leftCount and leftCount == 3 then
                    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_resetWildTimes.mp3")
                    isPlaySoundEffect = false
                end

                lockNode:updateCornerNum(leftCount, true)
            end
        end
    end
end
--更新 free 次数
function CodeGameScreenDragonParadeMachine:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 

    if self.m_freeTimesBar then
        self.m_freeTimesBar:changeRespinTimes(leftFsCount)
    end
end

--获取free下 bonus2价值
function CodeGameScreenDragonParadeMachine:getFreeOneBonus2Value(isStr)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local multiple = selfData.allMultiple or 0
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multiple * lineBet
    local scoreStr = self:formatCoins(score, 3)
    if isStr then
        return scoreStr
    else
        return score
    end
end
--获取free下 bonus2价值 总和
function CodeGameScreenDragonParadeMachine:getFreeBonus2TotalValue(isStr)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusWin = selfData.bonusWin or 0
    local score = bonusWin
    local scoreStr = self:formatCoins(score, 3)
    if isStr then
        return scoreStr
    else
        return score
    end
end
--更新 free bonus2 单个值
function CodeGameScreenDragonParadeMachine:updateFreeLeftBonus2Win()
    if self.m_freeBonus2WinBar and self.m_freeBonus2WinBarSuper then
        local scoreStr = self:getFreeOneBonus2Value(true)

        self.m_freeBonus2WinBar:findChild("m_lb_coins"):setString(scoreStr)
        self.m_freeBonus2WinBarSuper:findChild("m_lb_coins"):setString(scoreStr)
    end
end

--更新 free bonus2 总值
function CodeGameScreenDragonParadeMachine:updateFreeMidBonus2TotalWin(num)
    if self.m_freeBonus2PrizeBar and self.m_freeBonus2PrizeBarSuper then
        local scoreStr = self:getFreeBonus2TotalValue(true)
        if num then
            scoreStr = self:formatCoins(num, 3)
        end
        if scoreStr == "0" then
            scoreStr = ""
        end
        self.m_freeBonus2PrizeBar:findChild("m_lb_coins"):setString(scoreStr)
        self.m_freeBonus2PrizeBarSuper:findChild("m_lb_coins"):setString(scoreStr)
    end
end

--更新respin left
function CodeGameScreenDragonParadeMachine:updateRespinLeftBonus2Win()
    local score = self:getRespinLeftScore()
    score = self:formatCoins(score, 3)

    if self.m_isSuperGame then
        self.m_respinBoard_1:setBonus2TotalWinNum( score )--第一棋盘
        self.m_respinBoard_2:setBonus2TotalWinNum( score )--第二棋盘
    else
        self.m_respinBoard_2:setBonus2TotalWinNum( score )
    end
end

function CodeGameScreenDragonParadeMachine:getRespinLeftScore()

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local multiple = selfData.allMultiple or 0
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multiple * lineBet

    return score
end
-- isone是否是第一棋盘
function CodeGameScreenDragonParadeMachine:getRespinRightBonus3Score(_isOne)
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}

    local getTotalMulti = function(isOne)
        local totalM = 0
        for i=1, #storedIcons do
            local values = storedIcons[i]
            local score = values[2]
            local pos = values[1]

            if isOne then
                if pos <= 14 then
                    totalM = totalM + score
                end
            else
                if pos > 14 then
                    totalM = totalM + score
                end
            end
        end
        return totalM
    end
    

    local lineBet = globalData.slotRunData:getCurTotalBet()

    local allMulti = getTotalMulti(_isOne)
    local final_score = allMulti * lineBet
    return final_score
end

--获取mid数量
function CodeGameScreenDragonParadeMachine:getRespinMidNum(type)
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}

    local totalM = 0
    for i=1, #storedIcons do
        local values = storedIcons[i]
        local score = values[2]
        local pos = values[1]

        if type == "front" then
            if pos <= 14 then
                totalM = totalM + 1
            end
        else
            if pos > 14 then
                totalM = totalM + 1
            end
        end
    end
    return totalM
end

--ReSpin开始改变UI状态
function CodeGameScreenDragonParadeMachine:changeReSpinStartUI(curCount)
    if self.m_isSuperGame then
        if self.m_isSecondBoard then
            --第二棋盘
            self.m_respinBoard_2:changeRespinTimes( curCount )
            self.m_respinBoard_2:setRespinBarType( "change" )
            self.m_respinBoard_1:setRespinBarType( "isFinish" )
        else
            --第一棋盘
            self.m_respinBoard_1:changeRespinTimes( curCount )
            self.m_respinBoard_1:setRespinBarType( "change" )
            self.m_respinBoard_2:changeRespinTimes( 0 )
        end
    else
        self.m_respinBoard_2:changeRespinTimes( curCount )
        self.m_respinBoard_2:setRespinBarType( "change" )
    end
end
--ReSpin刷新数量
function CodeGameScreenDragonParadeMachine:changeReSpinUpdateUI(curCount)
    -- self.m_reSpinBar:toAction("3show")
    -- print("当前展示位置信息  %d ", curCount)
    -- self.m_reSpinBar:updateLeftCount(curCount)

    if self.m_isSuperGame then
        if self.m_isSecondBoard then
            --第二棋盘
            self.m_respinBoard_2:changeRespinTimes( curCount )
            self.m_respinBoard_2:setRespinBarType( "change" )
        else
            --第一棋盘
            self.m_respinBoard_1:changeRespinTimes( curCount )
            self.m_respinBoard_1:setRespinBarType( "change" )
        end
    else
        self.m_respinBoard_2:changeRespinTimes( curCount )
        self.m_respinBoard_2:setRespinBarType( "change" )
    end

end

--[[
    龙待机idle
]]
function CodeGameScreenDragonParadeMachine:runJueseIdleAni()
    self.m_jueseAnimIsPlay = false
    
    local randIndex = math.random(2, 3)
    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_juese,   --执行动画节点  必传参数
        -- soundFile = (randIndex == 3) and nil or nil,  --播放音效 执行动作同时播放 可选参数
        actionName = "idle"..randIndex, --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            self:runJueseIdleAni()
        end
    }
    util_runAnimations(params)
end

---
-- 触发respin 玩法
--
function CodeGameScreenDragonParadeMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    self:clearCurMusicBg()

    self:showRespinView(effectData)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

--重写
-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenDragonParadeMachine:symbolBulingEndCallBack(_slotNode)
    if self:isWildSymbol(_slotNode.p_symbolType) then
        _slotNode:runAnim("idle", true)
    elseif self:isFixSymbol(_slotNode.p_symbolType) then
        _slotNode:runAnim("idleframe2", true)
    end
end
--重写 
-- 有特殊需求判断的 重写一下
function CodeGameScreenDragonParadeMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if self:isFixSymbol(_slotNode.p_symbolType) then
                return true
            end
        end
    end

    return false
end

function CodeGameScreenDragonParadeMachine:initGameStatusData(gameData)
    CodeGameScreenDragonParadeMachine.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.bets then
        self:updateBetData(gameData.gameConfig.bets)
    end
end

--更新数据
function CodeGameScreenDragonParadeMachine:updateBetData(_betData)
    if _betData then
        self.m_allBetData = _betData
    end
end

function CodeGameScreenDragonParadeMachine:updateSingleBetData(wildCount, wildPos, wildLeftTimes)
    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local totalBetStr = tostring(totalBet)
    if self.m_allBetData then
        if not self.m_allBetData[totalBetStr] then
            self.m_allBetData[totalBetStr] = {}
        end
        self.m_allBetData[totalBetStr].wildCount = wildCount
        self.m_allBetData[totalBetStr].wildPos = wildPos
        self.m_allBetData[totalBetStr].wildLeftTimes = wildLeftTimes
    end
end
--重置聚宝盆数据
function CodeGameScreenDragonParadeMachine:resetBetData()
    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local totalBetStr = tostring(totalBet)
    if self.m_allBetData then
        if not self.m_allBetData[totalBetStr] then
            self.m_allBetData[totalBetStr] = {}
        end
    end
end

--获取固定Wild数据
function CodeGameScreenDragonParadeMachine:getStickWildData()
    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local totalBetStr = tostring(totalBet)
    local ret = {}
    if self.m_allBetData and self.m_allBetData[totalBetStr] then
        ret.wildCount = self.m_allBetData[totalBetStr].wildCount
        ret.wildPos = self.m_allBetData[totalBetStr].wildPos
        ret.wildLeftTimes = self.m_allBetData[totalBetStr].wildLeftTimes
    end
    return ret
end

function CodeGameScreenDragonParadeMachine:updateNetWorkData()
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



    --spin后更新 betData
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if selfdata then
        self:updateSingleBetData(selfdata.wildCount, selfdata.wildPos, selfdata.wildLeftTimes)
    end
    

    local nextProcess = function()
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end

    if self.m_isPlayWinningNotice then
        self:preViewWin(function()
            nextProcess()
        end)
    else
        nextProcess()
    end
end

-- 预告中奖
function CodeGameScreenDragonParadeMachine:preViewWin(func)  
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_preview_win.mp3")

    self.m_isPlayWinningNotice = false
    
    self.m_bigWinEffect:setVisible(true)
    for i=1,16 do
        local particle = self.m_bigWinEffect:findChild("Particle_a_" .. i)
        particle:resetSystem()
    end
    
    self.m_bigWinEffect:findChild("Node_qipan_chufa_root"):setVisible(false)
    self.m_bigWinEffect:findChild("Node_yugao_effect_root"):setVisible(true)
    self.m_bigWinEffect:findChild("Node_daying_effect_root"):setVisible(false)

    self.m_bigWinEffect:runCsbAction("yugao", false, function()
        self.m_bigWinEffect:setVisible(false)

        for i=1,16 do
            local particle = self.m_bigWinEffect:findChild("Particle_a_" .. i)
            particle:stopSystem()
        end
        
    end)

    self.m_prewinSpineEffect:setVisible(true)
    util_spinePlay(self.m_prewinSpineEffect, "actionframe_yugao", false)
    local spineEndCallFunc = function()
        self.m_prewinSpineEffect:setVisible(false)
    end
    util_spineEndCallFunc(self.m_prewinSpineEffect, "actionframe_yugao", spineEndCallFunc)

    
    self:shakeOneNodeForever(self:findChild("Node_board_root"), 70/30)

    self:delayCallBack(70/30, function()
        if func then
            func()
        end
    end)

end

--提层
function CodeGameScreenDragonParadeMachine.setSymbolToClipReel(_MainClass, _iCol, _iRow, _type, _zorder)
    local targSp = _MainClass:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = _MainClass:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(_MainClass, index)

        local posIdx = _MainClass:getPosReelIdx(_iRow, _iCol)
        -- local showOrder = _MainClass:getBounsScatterDataZorder(_type) - _iRow
        local showOrder = _MainClass:getBounsScatterDataZorder(_type) + posIdx
        targSp.m_showOrder = showOrder
        targSp.p_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent(false)
        _MainClass.m_clipParent:addChild(targSp, _zorder + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

function CodeGameScreenDragonParadeMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    self.setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)

                    --回弹
                    local newSpeedActionTable = {}
                    for i = 1, #speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            end
        end
    end
end

--重写 点击层所挂父节点
--绘制多个裁切区域
function CodeGameScreenDragonParadeMachine:drawReelArea()
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
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)

        self.m_touchLayerRoot = self.m_csbOwner["Node_touchLayer"] --改点击层所在节点

        self.m_touchLayerRoot:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)--改
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")

        --创建压黑层
        self:createBlackLayer(cc.size(slotW, slotH)) 

    -- 测试数据，看点击区域范围
    -- self.m_touchSpinLayer:setBackGroundColor(cc.c3b(0, 255, 0))
    -- self.m_touchSpinLayer:setBackGroundColorOpacity(140)
    -- self.m_touchSpinLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    end
end
--更改点击区域
function CodeGameScreenDragonParadeMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        if _trigger then
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH * (self.m_iReelRowNum * 2)))
        else
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
        end
       
    end
end

--[[
    创建压黑层
]]
function CodeGameScreenDragonParadeMachine:createBlackLayer(size)
    --压黑层
    self.m_blackLayer = ccui.Layout:create()
    self.m_blackLayer:setContentSize(size)
    self.m_blackLayer:setAnchorPoint(cc.p(0, 0))
    self.m_blackLayer:setTouchEnabled(false)
    self.m_clipParent:addChild(self.m_blackLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 20)
    self.m_blackLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
    self.m_blackLayer:setBackGroundColor(cc.c3b(0, 0, 0))
    self.m_blackLayer:setBackGroundColorOpacity(180)
    self.m_blackLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    self.m_blackLayer:setVisible(false)
end

--[[
    显示压黑层
]]
function CodeGameScreenDragonParadeMachine:showBlackLayer()
    self.m_blackLayer:setVisible(true)
    util_nodeFadeIn(self.m_blackLayer,0.2,0,180)
end

--[[
    隐藏压黑层
]]
function CodeGameScreenDragonParadeMachine:hideBlackLayer( )
    util_fadeOutNode(self.m_blackLayer,0.2,function(  )
        self.m_blackLayer:setVisible(false)
    end)
end

-- shake
function CodeGameScreenDragonParadeMachine:shakeOneNodeForever(node, time)
    local oldPos = cc.p(node:getPosition())
    local changePosY = math.random( 1, 5)
    local changePosX = math.random( 1, 5)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    node:runAction(action)

    self:delayCallBack(time, function()
        node:stopAction(action)
        node:setPosition(oldPos)
    end)
end

--修改赢钱区特效
function CodeGameScreenDragonParadeMachine:changeWinCoinEffectCsb(_isChange)
    local effectCsbName = "GameBottomNodePortrait_jiesuan.csb"
    if _isChange then
        effectCsbName = "DragonParade_yingqian.csb"
    else
        if globalData.slotRunData.isPortrait == true then
            effectCsbName = "GameBottomNodePortrait_jiesuan.csb"
        else
            effectCsbName = "GameBottomNode_jiesuan.csb"
        end
    end
    
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), effectCsbName)
end

--赢钱     重写修改free模式下 需要只计算连线的 后端数据是包含bonus2赢钱的 刨出去
function CodeGameScreenDragonParadeMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    --改
    local onceWinCoins = self.m_iOnceSpinLastWin
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local winLines  = self.m_runSpinResultData.p_winLines or {}
        -- 本次连线赢钱
        local lineCoins = 0
        for i,v in ipairs(winLines)do
            lineCoins = lineCoins + v.p_amount
        end
        onceWinCoins = lineCoins

        local freeBonus2Win = self:getFreeBonus2TotalValue()

        local lastWinCoin = globalData.slotRunData.lastWinCoin
        local curTo = math.max(lastWinCoin - freeBonus2Win, 0)
        local startJumpCoin = math.max(curTo - onceWinCoins, 0)
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {curTo, isNotifyUpdateTop, true, startJumpCoin})
        globalData.slotRunData.lastWinCoin = lastWinCoin
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {onceWinCoins, isNotifyUpdateTop})
    end
    --改
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {onceWinCoins, isNotifyUpdateTop})
end

--[[
    显示下一个快滚节点(拉伸镜头效果)
]]
function CodeGameScreenDragonParadeMachine:showNextQuickNode(respinView)
    local quickNode = respinView:getQuickRunNode()
    if not quickNode then
        return
    end
    self.m_respinIsQuickRun = true
    local moveNode = self:findChild("Node_Scale")
    local parentNode = moveNode:getParent()

    local targetNode = quickNode


    local params = {
        moveNode = moveNode,--要移动节点
        targetNode = targetNode,--目标位置节点
        parentNode = parentNode,--移动节点的父节点
        time = 2.8,--移动时间
        actionType = 3,
        scale = 2,--缩放倍数
    }

    util_moveRootNodeAction(params)

    --放大
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_lens_respinone_scale_add.mp3")
end

--[[
    重置移动节点状态
]]
function CodeGameScreenDragonParadeMachine:resetMoveNodeStatus()
    local moveNode = self:findChild("Node_Scale")
    --恢复移动节点状态
    local spawn = cc.Spawn:create({
        cc.MoveTo:create(0.5,cc.p(0,0)),
        cc.ScaleTo:create(0.5,1)
    })
    moveNode:stopAllActions()
    moveNode:runAction(cc.EaseSineInOut:create(spawn))

    --缩小
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_lens_respinone_scale_reduce.mp3")
end
--重写   修改free下 大赢不算bonus2赢钱
function CodeGameScreenDragonParadeMachine:addLastWinSomeEffect() -- add big win or mega win
    local notAddEffect = self:checkIsAddLastWinSomeEffect()

    if notAddEffect then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local onceWin = self.m_iOnceSpinLastWin
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- 本次连线赢钱
        local winLines  = self.m_runSpinResultData.p_winLines or {}
        local lineCoins = 0
        for i,v in ipairs(winLines)do
            lineCoins = lineCoins + v.p_amount
        end
        onceWin = lineCoins
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = onceWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    -- curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        -- curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        -- curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = onceWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        -- curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = onceWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        -- curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = onceWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = onceWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end
--修改free下赢钱时间
function CodeGameScreenDragonParadeMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()

    local onceWin = self.m_iOnceSpinLastWin
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- 本次连线赢钱
        local winLines  = self.m_runSpinResultData.p_winLines or {}
        local lineCoins = 0
        for i,v in ipairs(winLines)do
            lineCoins = lineCoins + v.p_amount
        end
        onceWin = lineCoins
    end


    local winRate = onceWin / totalBet
    local showTime = 0
    if onceWin > 0 then
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

    return showTime
end

function CodeGameScreenDragonParadeMachine:scaleMainLayer()
    CodeGameScreenDragonParadeMachine.super.scaleMainLayer(self)
    local ratio = display.width/display.height
    if ratio >= 768 / 930 then
        local mainScale = 0.59
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self:findChild("bg"):setScale(1.2)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 17)
    elseif ratio < 768 / 930 and ratio >= 768/1024 then
        local mainScale = 0.69
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 17)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.81 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 12)
    elseif ratio < 640/960 and ratio >= 768/1228 then
        local mainScale = 0.87 - 0.05*((ratio-768/1228)/(640/960 - 768/1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1228 and ratio >= 1200/2000 then
        local mainScale = 0.95 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 1200/2000 and ratio >= 768/1370 then
        local mainScale = 1 - 0.05*((ratio-768/1370)/(768/1228 - 768/1370))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 2)
    elseif ratio < 768/1370 and ratio >= 768/1530 then
        local mainScale = 1 - 0.05*((ratio-768/1530)/(768/1370 - 768/1530))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1530 and ratio >= 768/1660 then
        local mainScale = 1 - 0.05*((ratio-768/1660)/(768/1530 - 768/1660))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_jackpotOffsetY = 80
    end
    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
end

function CodeGameScreenDragonParadeMachine:showPaytableView()
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
--重写 有锁定块重置情况下 延时调用
function CodeGameScreenDragonParadeMachine:reelDownNotifyPlayGameEffect()
    self:delayCallBack(self.m_baseWildResetDelayTime, function()
        CodeGameScreenDragonParadeMachine.super.reelDownNotifyPlayGameEffect(self)
    end)
    
end

function CodeGameScreenDragonParadeMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    

    -- 取消掉赢钱线的显示
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
    else
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        self:clearWinLineEffect()
        -- 停掉背景音乐
        self:clearCurMusicBg()
    end
    

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

function CodeGameScreenDragonParadeMachine:jumpBigWinWinLabel()
    --崩数字
    local lightAni = util_createAnimation("DragonParade_daying_shuzi.csb")
    self.m_bottomUI.coinWinNode:addChild(lightAni)
    -- lightAni:findChild("m_lb_coins"):setString("+"..util_formatCoins(addScore,30))

    local labelNum = lightAni:findChild("m_lb_coins")
    local coins = self.m_iOnceSpinLastWin
    self:updateLabelSize({label=labelNum, sx = 1, sy = 1},520)
    labelNum:setString("")
    local addValue = coins / 108 --1.8s
    util_jumpNum(labelNum, 0, coins, addValue, 1 / 60, {30}, "+", nil, function()
    end, function()
        local info1={label=labelNum,sx=1,sy=1}
        self:updateLabelSize(info1,520)
    end)
    lightAni:runCsbAction("start",false,function(  )--18帧
        lightAni:runCsbAction("idle",true)
    end)

    self:delayCallBack(2, function()
        lightAni:runCsbAction("over",false,function(  )
            labelNum:unscheduleUpdate()
            lightAni:removeFromParent()
        end)
    end)
end

function CodeGameScreenDragonParadeMachine:checkIsHaveSelfEffect(_effectType, _effectSelfType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        local selfType = self.m_gameEffects[i].p_selfEffectType
        if value == _effectType and selfType == _effectSelfType then
            return true
        end
    end

    return false
end

function CodeGameScreenDragonParadeMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenDragonParadeMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenDragonParadeMachine:showEffect_runBigWinLightAni(effectData)
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    self:showBigWinLight(function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenDragonParadeMachine:showBigWinLight(_func)
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_bigwin_before.mp3")

    local delayTime = 140/60
    if self:getFreeIsSuper() then
        --super不播孔明灯 以edge时间线为准
        delayTime = 120/60
    else
        util_spinePlay(self.m_juese, "yugao", false)
        local spineEndCallFunc = function()
            self:runJueseIdleAni()
        end
        util_spineEndCallFunc(self.m_juese, "yugao", spineEndCallFunc)

        self.m_effectBigWin:setVisible(true)
        util_spinePlay(self.m_effectBigWin, "actionframe", false)
        local spineEndCallFunc = function()
            self.m_effectBigWin:setVisible(false)
        end
        util_spineEndCallFunc(self.m_effectBigWin, "actionframe", spineEndCallFunc)
    end
    


    self:jumpBigWinWinLabel()
    
    local isRowSuper = false
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local isSuper = self:getFreeIsSuper()
        if isSuper then
            isRowSuper = true
        end
    end
    if isRowSuper then
        
        self.m_bigWinEffectSuper:setVisible(true)
        for i=1,12 do
            local particle = self.m_bigWinEffectSuper:findChild("Particle_a_" .. i)
            particle:resetSystem()
        end
        self.m_bigWinEffectSuper:runCsbAction("daying_FG", false, function()
            self.m_bigWinEffectSuper:setVisible(false)

            for i=1,12 do
                local particle = self.m_bigWinEffectSuper:findChild("Particle_a_" .. i)
                particle:stopSystem()
            end
            
        end)
    else
        self.m_bigWinEffect:setVisible(true)
        for i=1,16 do
            local particle = self.m_bigWinEffect:findChild("Particle_a_" .. i)
            particle:resetSystem()
        end
        self.m_bigWinEffect:findChild("Node_qipan_chufa_root"):setVisible(false)
        self.m_bigWinEffect:findChild("Node_yugao_effect_root"):setVisible(false)
        self.m_bigWinEffect:findChild("Node_daying_effect_root"):setVisible(true)

        self.m_bigWinEffect:runCsbAction("daying", false, function()
            self.m_bigWinEffect:setVisible(false)

            for i=1,16 do
                local particle = self.m_bigWinEffect:findChild("Particle_a_" .. i)
                particle:stopSystem()
            end
            
        end)
    end
    
    self:shakeOneNodeForever(self:findChild("Node_board_root"), delayTime)
    
    self:delayCallBack(delayTime + 0.3, function()
        if type(_func) == "function" then
            _func()
        end
    end)
end

return CodeGameScreenDragonParadeMachine






