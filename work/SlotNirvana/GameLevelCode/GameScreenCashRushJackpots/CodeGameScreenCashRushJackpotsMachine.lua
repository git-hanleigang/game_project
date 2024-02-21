---
-- island li
-- 2019年1月26日
-- CodeGameScreenCashRushJackpotsMachine.lua
-- 
-- 玩法：
--[[
    base:
        1.scatter只会出现在2、3、4列，三个触发pick玩法（同时获得一倍totalBet的钱）
        2.一共5档jackpot，由rapid图标个数触发
        3.有wild、2xwild、3xwild，三种wild都会出，只出现在2、3、4列
    jackpot玩法：
        1.任意5个及以上的rapid图标获得jackpot
        2.3个rapid获得1倍
        3.4个rapid获得2倍
        4.5个、6个、7个、8个、9个rapid的jackpot倍数数值定
    pick玩法：
        1.有6种pick选择都是free次数+增加的x倍wild的个数
            ①.5次free+20个2xwild
            ②.7次free+30个2xwild
            ③.10次free+40个2xwild
            ④.12次free+50个2xwild
            ⑤.15次free+40个3xwild
            ⑥.20次free+50个3xwild
        2.最后一种选择是，万能pick项+5次free，如果选中这个，则所有pick进度加1，且最后获得的free总次数+5
        3.如果同时获得几种pick结果，则最后获得最高档的结果
        4.若pick选中了两个万能项，则最后结果会额外加10次free
        5.pick出结果后，进入free，会在free里加入获得的额外wild个数，其他wild也是正常出，先播放往棋盘带子里加wild的动效，然后开始spin，free和base玩法一样，只有线奖和jackpot
        6.free中能再次获得free次数，如果有三个scatter落在棋盘上，直接获得和本次free初始次数相同的free次数，不会再获得wild个数
    free：
        1.free中能再次获得free次数，如果有三个scatter落在棋盘上，直接获得和本次free初始次数相同的free次数，不会再获得wild个数
]]
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "CashRushJackpotsPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCashRushJackpotsMachine = class("CodeGameScreenCashRushJackpotsMachine", BaseNewReelMachine)

CodeGameScreenCashRushJackpotsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCashRushJackpotsMachine.m_pickRootSccale = 1.0

CodeGameScreenCashRushJackpotsMachine.SYMBOL_SCORE_BONUS = 94
CodeGameScreenCashRushJackpotsMachine.SYMBOL_SCORE_WILD_2 = 112
CodeGameScreenCashRushJackpotsMachine.SYMBOL_SCORE_WILD_3 = 113

CodeGameScreenCashRushJackpotsMachine.EFFECT_BIG_WIN_LIGHT = GameEffect.EFFECT_SELF_EFFECT - 2 --   大赢光效
CodeGameScreenCashRushJackpotsMachine.EFFECT_JACKPOT_TRIGGER = GameEffect.EFFECT_SELF_EFFECT - 3  -- 触发jackpot
CodeGameScreenCashRushJackpotsMachine.EFFECT_BONUS_TRIGGER = GameEffect.EFFECT_SELF_EFFECT - 4  -- 触发bonus

-- 构造函数
function CodeGameScreenCashRushJackpotsMachine:ctor()
    CodeGameScreenCashRushJackpotsMachine.super.ctor(self)
    self.m_iBetLevel = 0
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.triggerScatterDelayTime = 0
    self.m_bottomScatterTbl = {}
    -- free下几个star
    self.m_freeStarCount = 2
    -- free下几个wild
    self.m_freeWildCount = 2
    self.m_freeFirstWildTbl = {}
    -- 中jackpot后，logo状态
    self.m_jackpotState = false
    -- 特殊wild连线后状态
    self.m_specialWildLine = false
    -- 没连线的slotNode位置
    self.m_slotNodeNoLinePosData = {}
    -- free除第一次外增加的wild（假滚个数）
    self.m_freeNoFirstAddWildCount = 12
    self.m_freeCurAddWildData = {}
    self.m_lineZorder = 98000
    self.m_triggerBigWinEffect = false
    --假的连线标志tag
    self.m_falseLineIdx = 1000
 
    --init
    self:initGame()
end

function CodeGameScreenCashRushJackpotsMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCashRushJackpotsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CashRushJackpots"  
end

function CodeGameScreenCashRushJackpotsMachine:getBottomUINode()
    return "CodeCashRushJackpotsSrc.CashRushJackpotsBottomNode"
end

function CodeGameScreenCashRushJackpotsMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self.m_bgSpTbl = {}
    self.m_bgSpTbl[1] = self.m_gameBg:findChild("base_bg")
    self.m_bgSpTbl[2] = self.m_gameBg:findChild("free_bg")

    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("Node_base_reel")
    self.m_reelBg[2] = self:findChild("Node_free_reel")

    self.m_reelDarkNode = {}
    self.m_reelDarkNode[1] = self:findChild("Node_base_reel_an")
    self.m_reelDarkNode[2] = self:findChild("Node_free_reel_an")
    self:setReelDarkState(false)

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_baseBar = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsBaseBarView", self)
    self:findChild("Node_bar"):addChild(self.m_baseBar)

    -- logo
    self.m_logoBar = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsLogoView")
    self.m_baseBar:findChild("Node_logo"):addChild(self.m_logoBar)
    local tempTbl_1 = {}
    tempTbl_1.type = "logoBar"
    tempTbl_1.state = false
    tempTbl_1.barAni = self.m_logoBar

    self.m_baseFreeSpinBar = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsFreespinBarView", self)
    self.m_baseBar:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar)
    local tempTbl_2 = {}
    tempTbl_2.type = "freeBar"
    tempTbl_2.state = false
    tempTbl_2.barAni = self.m_baseFreeSpinBar

    -- bonusTips
    self.m_bonusTipBar = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsWinTipsView")
    self.m_baseBar:findChild("Node_JackpotWonTips"):addChild(self.m_bonusTipBar)
    local tempTbl_3 = {}
    tempTbl_3.type = "bonusBar"
    tempTbl_3.state = false
    tempTbl_3.barAni = self.m_bonusTipBar
    
    -- mulTips
    self.m_mulTipBar = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsMulTipsView")
    self.m_baseBar:findChild("Node_MultiplierTips"):addChild(self.m_mulTipBar)
    local tempTbl_4 = {}
    tempTbl_4.type = "mulBar"
    tempTbl_4.state = false
    tempTbl_4.barAni = self.m_mulTipBar

    self.m_baseNodeDataTbl = {}
    table.insert(self.m_baseNodeDataTbl, tempTbl_1)
    table.insert(self.m_baseNodeDataTbl, tempTbl_2)
    table.insert(self.m_baseNodeDataTbl, tempTbl_3)
    table.insert(self.m_baseNodeDataTbl, tempTbl_4)

    -- wildBar
    self.m_wildBar = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsWildBarView", self)
    self:findChild("Node_WildsAddedTips"):addChild(self.m_wildBar)
    self.m_wildBar:setVisible(false)
   
    self.m_jackPotBar = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsJackPotBarView", self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self.m_pickView = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsPickView", self)
    self:addChild(self.m_pickView, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_pickView:setVisible(false)
    self.m_pickView:scaleMainLayer(self.m_pickRootSccale)

    self.m_mainView = self:findChild("ef_yugao")
  
    --遮罩（要在连线图标下边和普通图标上边）
    local m_maskNode = util_createAnimation("CashRushJackpots_reels_cover.csb")
    self.m_clipParent:addChild(m_maskNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1)
    m_maskNode:setPosition(util_convertToNodeSpace(self:findChild("Node_cover"),self.m_clipParent))

    --线
    self.m_lineNode = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsLineNode")
    -- self.m_clipParent:addChild(self.m_lineNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE+1)
    self.m_clipParent:addChild(self.m_lineNode,self.m_lineZorder)
    self.m_lineNode:setPosition(util_convertToNodeSpace(self:findChild("Node_Paylines"),self.m_clipParent))
    self.m_lineNode:setVisible(false)

    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))

    -- pick过场
    self.m_cutScenePickSpine = util_spineCreate("CashRushJackpots_GC",true,true)
    self.m_cutScenePickSpine:setPosition(worldPos)
    self:addChild(self.m_cutScenePickSpine, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    self.m_cutScenePickSpine:setVisible(false)

    -- free过场
    self.m_cutSceneFreeSpine = util_spineCreate("CashRushJackpots_GC2",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneFreeSpine)
    self.m_cutSceneFreeSpine:setVisible(false)

    -- free第一次砸wild
    self.m_zaNodeTbl = {}
    self.m_zaLightAniTbl = {}
    for i=1, 3 do
        self.m_zaNodeTbl[i] = self:findChild("Node_za"..i)
        self.m_zaLightAniTbl[i] = util_createAnimation("CashRushJackpots_wildza.csb")
        self.m_zaNodeTbl[i]:addChild(self.m_zaLightAniTbl[i])
        self.m_zaLightAniTbl[i]:setVisible(false)
    end

    self.m_yuGao = util_createAnimation("CashRushJackpots_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_yuGao)
    self.m_yuGao:setVisible(false)

    --大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("CashRushJackpots_DY",true,true)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bigWinSpine:setVisible(false)

    --scatter触发最上层（假的）
    self.m_scatterNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_scatterNode,20)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:changeBgAndReelBg(1)
    self:changeBaseLogoBar(1)
end


function CodeGameScreenCashRushJackpotsMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 4, 0, 1)
    end,0.2,self:getModuleName())
end

function CodeGameScreenCashRushJackpotsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCashRushJackpotsMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenCashRushJackpotsMachine:addObservers()
    CodeGameScreenCashRushJackpotsMachine.super.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin and not self.m_triggerBigWinEffect then
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

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "fg"
        else
            bgmType = "base"
        end
        
        local soundName = "CashRushJackpotsSounds/music_CashRushJackpots_last_win_".. bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenCashRushJackpotsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCashRushJackpotsMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenCashRushJackpotsMachine:scaleMainLayer()
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
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width / display.height >= 1370/768 then
            mainScale = 1--mainScale * 1.03
            -- mainPosY = mainPosY + 3
            self.m_pickRootSccale = mainScale-- * 1.02
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 1.0
            self.m_pickRootSccale = mainScale * 0.875
        elseif display.width / display.height >= 1152/768 then
            mainScale = mainScale * 0.94
            self.m_pickRootSccale = mainScale * 0.84
        elseif display.width / display.height >= 920/768 then
            mainScale = mainScale * 0.8
            mainPosY = mainPosY + 10
            self.m_pickRootSccale = mainScale * 0.84
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

function CodeGameScreenCashRushJackpotsMachine:initGameUI()
    self:updateBetLevel()
    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self:setFreeWildData()
        self:changeBgAndReelBg(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
        self:changeBaseLogoBar(2)
    end
end

function CodeGameScreenCashRushJackpotsMachine:setFreeWildData()
    if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.star then
        self.m_freeStarCount = self.m_runSpinResultData.p_fsExtraData.star
        self.m_baseFreeSpinBar:changeFreeStarCount(self.m_freeStarCount)
        self.m_wildBar:changeFreeStarCount(self.m_freeStarCount)
    end
    if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.wildCount then
        self.m_freeWildCount = self.m_runSpinResultData.p_fsExtraData.wildCount
        self.m_baseFreeSpinBar:changeFreeWildCount(self.m_freeWildCount)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCashRushJackpotsMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_CashRushJackpots_CashRush"
    elseif symbolType == self.SYMBOL_SCORE_WILD_2 then
        return "Socre_CashRushJackpots_Wild2"
    elseif symbolType == self.SYMBOL_SCORE_WILD_3 then
        return "Socre_CashRushJackpots_Wild3"
    end
    
    return nil
end

---
--设置bonus scatter 层级
function CodeGameScreenCashRushJackpotsMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.SYMBOL_SCORE_BONUS then
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

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCashRushJackpotsMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCashRushJackpotsMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCashRushJackpotsMachine:MachineRule_initGame(  )
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if bonusExtra and bonusStatus == "OPEN" then
        if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            return
        end
        local endCallFunc = function()
            self:playGameEffect() 
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self:showChooseView(endCallFunc, true)
    end
end

function CodeGameScreenCashRushJackpotsMachine:initGameStatusData(gameData)
    local featureData = gameData.feature
    local spinData = gameData.spin
    if featureData and featureData.action == "BONUS" and spinData then
        if featureData.features and spinData.features then
            spinData.features = featureData.features
            if #featureData.features == 2 and featureData.features[2] == 1 then
                spinData.freespin = featureData.freespin
            end
        end
        if featureData.bonus and spinData.bonus then
            spinData.bonus = featureData.bonus
        end
    end
    
    CodeGameScreenCashRushJackpotsMachine.super.initGameStatusData(self,gameData)
end

function CodeGameScreenCashRushJackpotsMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local jackpotLevel = self:getCurJackpotLevel()
    self.m_jackPotBar:jackpotLock(jackpotLevel)
    self.m_iBetLevel = jackpotLevel-1
end

function CodeGameScreenCashRushJackpotsMachine:getCurJackpotLevel()
    local jackpotLevel = 1
    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    if betCoin >= self.m_specialBets[1].p_totalBetValue and betCoin < self.m_specialBets[2].p_totalBetValue then
        jackpotLevel = 2
    elseif betCoin >= self.m_specialBets[2].p_totalBetValue and betCoin < self.m_specialBets[3].p_totalBetValue then
        jackpotLevel = 3
    elseif betCoin >= self.m_specialBets[3].p_totalBetValue and betCoin < self.m_specialBets[4].p_totalBetValue then
        jackpotLevel = 4
    elseif betCoin >= self.m_specialBets[4].p_totalBetValue then
        jackpotLevel = 5
    end
    return jackpotLevel
end

--
--单列滚动停止回调
--
function CodeGameScreenCashRushJackpotsMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCashRushJackpotsMachine.super.slotOneReelDown(self,reelCol)
    local curReelCol = reelCol
   ---本列是否开始长滚
   local isTriggerLongRun = false
   if reelCol == 1 then
       self.isHaveLongRun = false
   end
   if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
       isTriggerLongRun = true
   end
   local delayTime = 45/30
   if isTriggerLongRun then
       self.isHaveLongRun = true
       self:playScatterSpine("idleframe3", reelCol)
   else
       if reelCol == self.m_iReelColumnNum and self.isHaveLongRun == true then
           --落地
           self.triggerScatterDelayTime = 15/30
           self:playScatterSpine("idleframe2", reelCol, true)
       end
   end
end

function CodeGameScreenCashRushJackpotsMachine:playScatterSpine(_spineName, _reelCol, isOver)
    performWithDelay(self.m_scWaitNode, function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if _spineName == "idleframe3" and targSp.m_currAnimName ~= "idleframe3" then
                            targSp:runAnim(_spineName, true)
                        elseif _spineName == "idleframe2" then
                            targSp:runAnim(_spineName, true)
                        end
                    end
                end
            end
        end
    end, 0.1)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCashRushJackpotsMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCashRushJackpotsMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

-- 显示free spin
function CodeGameScreenCashRushJackpotsMachine:showEffect_FreeSpin(effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.triggerScatterDelayTime = 0
        self.m_beInSpecialGameTrigger = true
        local waitTime = 0
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self.m_lineNode:hideNodeLine()
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if slotNode then
                        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            local topSatterNode = self:createCashRushJackpotsSymbol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                            local scatterPos = self:getPosReelIdx(iRow, iCol)
                            local clipTarPos = util_getOneGameReelsTarSpPos(self, scatterPos)
                            local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                            local nodePos = self.m_scatterNode:convertToNodeSpace(worldPos)
    
                            slotNode:setVisible(false)
                            self.m_bottomScatterTbl[#self.m_bottomScatterTbl+1] = slotNode
                            topSatterNode:setPosition(nodePos)
                            local scatterZorder = 10 - iRow + iCol
                            self.m_scatterNode:addChild(topSatterNode, scatterZorder)
                            topSatterNode:runAnim("actionframe", false, function()
                                slotNode:runAnim("idleframe2", true)
                            end)
    
                            local duration = topSatterNode:getAnimDurationTime("actionframe")
                            waitTime = util_max(waitTime,duration)
    
                            if not self.m_slotNodeNoLinePosData[scatterPos] then
                                self.m_slotNodeNoLinePosData[scatterPos] = true
                            end
                        else
                            slotNode:runAnim("zhihui", true)
                        end
                    end
                end
            end
            self:playScatterTipMusicEffect(true)
        end
        
        performWithDelay(self,function(  )
            self:removeTopTriggerScatter()
            self:showFreeSpinView(effectData)
        end,waitTime)
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end, self.triggerScatterDelayTime)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenCashRushJackpotsMachine:showFreeSpinView(effectData)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_More)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            view:findChild("root"):setScale(self.m_machineRootScale)
        else
            local cutSceneFunc = function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
                performWithDelay(self.m_scWaitNode, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startOver)
                end, 5/60)
            end
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startStart)
            performWithDelay(self.m_scWaitNode, function()
                self:setMainShowState(true)
                if self.m_pickView:isVisible() then
                    self.m_pickView:hideSelf()
                end
                self:changeBgAndReelBg(2)
                self:changeBaseLogoBar(2)
            end, 50/60)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()    
            end)
            if self.m_freeStarCount == 2 then
                view:findChild("2xwild"):setVisible(true)
                view:findChild("3xwild"):setVisible(false)
            else
                view:findChild("3xwild"):setVisible(true)
                view:findChild("2xwild"):setVisible(false)
            end
            if self.m_freeWildCount then
                view:findChild("m_lb_num2"):setString(self.m_freeWildCount)
            end
            local time = view:getAnimTime("start")
            view.m_allowClick = false
            performWithDelay(view,function ()
                view.m_allowClick = true
            end, time)
            view:setBtnClickFunc(cutSceneFunc)
            view:findChild("root"):setScale(self.m_machineRootScale)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

--free到base过场
function CodeGameScreenCashRushJackpotsMachine:showCutPlaySceneAni(_callFunc, _freeStart)
    local callFunc = _callFunc
    local freeStart = _freeStart
    self.m_specialWildLine = false
    self.m_jackpotState = false
    self.m_cutSceneFreeSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Base_CutScene)
    util_spinePlay(self.m_cutSceneFreeSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_cutSceneFreeSpine, "actionframe", function()
        self.m_cutSceneFreeSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
    --50帧切过场
    performWithDelay(self.m_scWaitNode, function()
        if freeStart then
            self:changeBgAndReelBg(2)
            self:changeBaseLogoBar(2)
        else
            self:changeBgAndReelBg(1)
            self:changeBaseLogoBar(1)
        end
    end, 50/30)
end

function CodeGameScreenCashRushJackpotsMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    -- self.m_baseFreeSpinBar:setShowStart()
end

function CodeGameScreenCashRushJackpotsMachine:showFreeSpinOverView()

    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_overStart, 3, 0, 1)
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_overOver)
        end, 5/60)
    end
    if globalData.slotRunData.lastWinCoin > 0 then
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver(strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:showCutPlaySceneAni(function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)
        local node=view:findChild("m_lb_coins")
        local nodeCount=view:findChild("m_lb_num")
        view:updateLabelSize({label=node,sx=0.9,sy=0.9},922)
        view:updateLabelSize({label=nodeCount,sx=1.0,sy=1.0},80)
        view:setBtnClickFunc(cutSceneFunc)
        view:findChild("root"):setScale(self.m_machineRootScale)
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:changeBgAndReelBg(1)
            self:triggerFreeSpinOverCallFun()
            self.m_specialWildLine = false
            self.m_jackpotState = false
        end)
        view:setBtnClickFunc(cutSceneFunc)
        view:findChild("root"):setScale(self.m_machineRootScale)
    end
end

function CodeGameScreenCashRushJackpotsMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("NoWins",nil,_func)
    return view
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCashRushJackpotsMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
   
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenCashRushJackpotsMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if not self:getCurIsFreeGameLastSpin() and not self.m_jackpotState and self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
        self.m_triggerBigWinEffect = true
    end
end

-- 判断当前状态是否为free下最后一次spin
function CodeGameScreenCashRushJackpotsMachine:getCurIsFreeGameLastSpin()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        return true
    end
    return false
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCashRushJackpotsMachine:addSelfEffect()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    self.m_jackpotState = false
    local bonusCount = self.m_runSpinResultData.p_selfMakeData.bonusCount
    local jackpotType = self.m_runSpinResultData.p_selfMakeData.jackpotType
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        bonusCount = self.m_runSpinResultData.p_fsExtraData.bonusCount
        jackpotType = self.m_runSpinResultData.p_fsExtraData.jackpotType
    end
    self.m_bonusList = {}
    self.m_specialWildLine = false
    local bonusPosData = {}
    if bonusCount and bonusCount > 2 then
        -- 触发bonus玩法
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BONUS_TRIGGER
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUS_TRIGGER -- 动画类型

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                local pos = self:getPosReelIdx(iRow, iCol)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    table.insert(self.m_bonusList, slotNode)
                    table.insert(bonusPosData, pos)
                end
            end
        end

        --触发jackpot玩法
        if jackpotType then
            self.m_jackpotState = true
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_JACKPOT_TRIGGER
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_JACKPOT_TRIGGER -- 动画类型
        end

        self:addRapidPlayLine(bonusPosData)
    end

    --没有连线的需要置灰
    self:addNoLineSlotNodePos()

    -- 判断是否有wild2、wild3连线
    local winLines = self.m_runSpinResultData.p_winLines or {}
    local posData_wild2 = {}
    local posData_wild3 = {}
    if #winLines > 0 then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    local pos = self:getPosReelIdx(iRow, iCol)
                    if slotNode.p_symbolType == self.SYMBOL_SCORE_WILD_2 then
                        table.insert(posData_wild2, pos)
                    elseif slotNode.p_symbolType == self.SYMBOL_SCORE_WILD_3 then
                        table.insert(posData_wild3, pos)
                    end
                end
            end
        end

        -- 是否存在wild2连线
        if #posData_wild2 > 0 then
            local wildIsLine = self:curSymbolIsLine(posData_wild2)
            if wildIsLine then
                self.m_specialWildLine = 2
            end
        end

        -- 是否存在wild3连线
        if #posData_wild3 > 0 then
            local wildIsLine = self:curSymbolIsLine(posData_wild3)
            if wildIsLine then
                self.m_specialWildLine = 3
            end
        end
    end
end

--没有连线的需要置灰
function CodeGameScreenCashRushJackpotsMachine:addNoLineSlotNodePos()
    self.m_slotNodeNoLinePosData = {}
    local winLines = self.m_runSpinResultData.p_winLines or {}
    if #winLines > 0 then
        for k, v in pairs(winLines) do
            local iconPos = v.p_iconPos
            for i=1, #iconPos do
                local pos = iconPos[i] + 1
                if not self.m_slotNodeNoLinePosData[pos] then
                    self.m_slotNodeNoLinePosData[pos] = true
                end
            end
        end
    end

    -- 触发feature时，scatter不需要置灰
    local featureDatas = self.m_runSpinResultData.p_features or {}
    local isTeiggerPick = false
    local isTriggerFree = false
    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        isTeiggerPick = true
    end
    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        isTriggerFree = true
    end
    if isTeiggerPick or isTriggerFree then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        local scatterPos = self:getPosReelIdx(iRow, iCol)
                        scatterPos = scatterPos + 1
                        if not self.m_slotNodeNoLinePosData[scatterPos] then
                            self.m_slotNodeNoLinePosData[scatterPos] = true
                        end
                    end
                end
            end
        end
    end
end

-- 把rapid图标当成线处理（要求）
function CodeGameScreenCashRushJackpotsMachine:addRapidPlayLine(_bonusPosData)
    local bonusPosData = _bonusPosData
    local winLines = self.m_runSpinResultData.p_winLines
    local rewardCoins = self.m_runSpinResultData.p_selfMakeData.winCoins or 0
    local winLineData = self.m_runSpinResultData:getWinLineDataWithPool({})
    winLineData.p_id = self.m_falseLineIdx
    winLineData.p_amount = rewardCoins
    winLineData.p_iconPos = bonusPosData
    winLineData.p_type = 1
    winLineData.p_multiple = 0
    winLines[#winLines + 1] = winLineData

    -- 处理连线数据
    local lineInfo = self:getReelLineInfo()
    local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo, bonusPosData)

    lineInfo.enumSymbolType = enumSymbolType
    lineInfo.iLineIdx = self.m_falseLineIdx
    lineInfo.iLineSymbolNum = #bonusPosData
    lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())
    self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCashRushJackpotsMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_BONUS_TRIGGER then
        self:showTriggerBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_JACKPOT_TRIGGER then
        self:showTriggerJackpot(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

function CodeGameScreenCashRushJackpotsMachine:showTriggerBonus(_endCallFunc)
    local endCallFunc = _endCallFunc
    local jackpotType = self.m_runSpinResultData.p_selfMakeData.jackpotType
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        jackpotType = self.m_runSpinResultData.p_fsExtraData.jackpotType
    end

    -- 播触发动画
    if self.m_bonusList and #self.m_bonusList > 0 then
        -- rapid触发动画
        -- self.m_bonusTipBar:setBonusNum(#self.m_bonusList)
        -- self:changeBaseLogoBar(3)
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    else
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end
end

function CodeGameScreenCashRushJackpotsMachine:showTriggerJackpot(_endCallFunc)
    local endCallFunc = _endCallFunc
    if not self.m_runSpinResultData.p_selfMakeData then
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
        return
    end
    local jackpotType = self.m_runSpinResultData.p_selfMakeData.jackpotType
    local rewardCoins = self.m_runSpinResultData.p_selfMakeData.winCoins or 0
    local bonusCount = self.m_runSpinResultData.p_selfMakeData.bonusCount or 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        bonusCount = self.m_runSpinResultData.p_fsExtraData.bonusCount
        jackpotType = self.m_runSpinResultData.p_fsExtraData.jackpotType
        rewardCoins = self.m_runSpinResultData.p_fsExtraData.winCoins
    end

    -- 播触发动画
    if self.m_bonusList and #self.m_bonusList > 0 then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_Teigger)
        for k, _slotNode in pairs(self.m_bonusList) do
            _slotNode:runAnim("actionframe", false, function()
                _slotNode:runAnim("idleframe", true)
            end)
        end
    end

    local jackpotIndex = 5
    --5、6、7、8、9rapid配置jackpot个数；客户端写死了
    if jackpotType then
        if jackpotType == "mini" then
            jackpotIndex = 5
            bonusCount = 5
        elseif jackpotType == "minor" then
            jackpotIndex = 4
            bonusCount = 6
        elseif jackpotType == "major" then
            jackpotIndex = 3
            bonusCount = 7
        elseif jackpotType == "mega" then
            jackpotIndex = 2
            bonusCount = 8
        elseif jackpotType == "grand" then
            jackpotIndex = 1
            bonusCount = 9
        end
    end

    --rapid触发动画
    self.m_bonusTipBar:setBonusNum(bonusCount)
    self:changeBaseLogoBar(3)

    -- jackpot触发动画
    self.m_jackPotBar:triggerJackpotAction(jackpotIndex)
    
    -- 播jackpot
    performWithDelay(self.m_scWaitNode, function()
        local tempTbl = {}
        tempTbl.coins = rewardCoins
        tempTbl.index = jackpotIndex
        tempTbl.machine = self
        tempTbl.bonusCount = bonusCount
        local jackPotWinView = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsJackPotWinView")
        self:addChild(jackPotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        self.m_jackPotBar:setJackpotIdle()
        jackPotWinView:initViewData(tempTbl, function()
            -- self:checkNotifyUpdateWinCoin(true)
            if not self:checkHasBigWin() then
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, 0)
            end
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        end)
    end, 60/30)
end

--[[
    连线播大赢前光效
]]
function CodeGameScreenCashRushJackpotsMachine:showBigWinLight(func)
    self.m_bigWinSpine:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self:runCsbAction("idleframe", true)
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Celebrate_Win)
    self:runCsbAction("yugao", true)

    local lineWinCoins  = self:getClientWinCoins()
    self.m_iOnceSpinLastWin = lineWinCoins
    local bFree = self:getCurrSpinMode() == FREE_SPIN_MODE
    local bottomWinCoin = self:getCurBottomWinCoins()
    local lastWinCoin   = 0
    if bFree then
        lastWinCoin = bottomWinCoin + lineWinCoins
    else
        lastWinCoin = lineWinCoins
    end
    self:setLastWinCoin(lastWinCoin)
    --大赢文本 只有连线赢钱触发大赢时,展示底栏大赢文本
    if self:checkHasBigWin() then
        local params = {
            overCoins  = lineWinCoins,
            jumpTime   = 1.5,
            animName   = "actionframe3",
        }
        self:playBottomBigWinLabAnim(params)
    end
end

-- 检测当前小块位置是否连线
function CodeGameScreenCashRushJackpotsMachine:curSymbolIsLine(_posData)
    local posData = _posData
    local isLine = false
    for i=1, #posData do
        local nodePos = posData[i]
        local linePos = self.m_runSpinResultData.p_winLines
        for k, v in pairs(linePos) do
            local iconPos = v.p_iconPos
            if iconPos then
                for i=1, #iconPos do
                    if nodePos == iconPos[i] then
                        isLine = true
                        break
                    end
                end
            end
        end
        if isLine then
            break
        end
    end

    return isLine
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenCashRushJackpotsMachine:checkHasGameEffect(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == effectType and not self.m_gameEffects[i].p_isPlay then
            return true
        end
    end

    return false
end

function CodeGameScreenCashRushJackpotsMachine:checkNotifyUpdateWinCoin(_isBonus)
    local winLines = self.m_reelResultLines

    if #winLines <= 0 and not _isBonus then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenCashRushJackpotsMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenCashRushJackpotsMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenCashRushJackpotsMachine:beginReel()
    self.m_triggerBigWinEffect = false
    self.m_freeCurAddWildData = {}
    self.m_lineNode:hideNodeLine()
    self:setReelDarkState(false)
    self:changeBaseBarLogoIdle()
    self:startSpinSetSlotNodeIdle()
    CodeGameScreenCashRushJackpotsMachine.super.beginReel(self)
end

-- reel条压暗
function CodeGameScreenCashRushJackpotsMachine:setReelDarkState(_showState, _showIndex)
    local showState = _showState
    local showIndex = _showIndex
    if showState then
        for i=1, 2 do
            if i == showIndex then
                self.m_reelDarkNode[i]:setVisible(true)
            else
                self.m_reelDarkNode[i]:setVisible(false)
            end
        end
    else
        for i=1, 2 do
            self.m_reelDarkNode[i]:setVisible(false)
        end
    end
end

-- 改变左上角动画类型
--1:base  2:free  3:bonus  4:特殊wild倍数
function CodeGameScreenCashRushJackpotsMachine:changeBaseBarLogoIdle()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBaseLogoBar(2)
    else
        self:changeBaseLogoBar(1)
    end
end

---
-- 点击快速停止reel
--
function CodeGameScreenCashRushJackpotsMachine:newQuickStopReel(colIndex)
    CodeGameScreenCashRushJackpotsMachine.super.newQuickStopReel(self, colIndex)
end

function CodeGameScreenCashRushJackpotsMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenCashRushJackpotsMachine.super.slotReelDown(self)
end

--顶部补块
function CodeGameScreenCashRushJackpotsMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        symbolType = math.random(1, 5)
    end
    parentData.symbolType = symbolType
    if self.m_bigSymbolInfos[symbolType] ~= nil then
        parentData.order =  self:getBounsScatterDataZorder(symbolType) - rowIndex
    else
        parentData.order = self:getBounsScatterDataZorder(symbolType) - rowIndex
    end
    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    parentData.tag = parentData.cloumnIndex * SYMBOL_NODE_TAG + rowIndex
    parentData.reelDownAnima = nil
    parentData.reelDownAnimaSound = nil
    parentData.m_isLastSymbol = false
    parentData.rowIndex = rowIndex
end

function CodeGameScreenCashRushJackpotsMachine:showBonusGameView(_effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.m_lineNode:hideNodeLine()
        self.triggerScatterDelayTime = 0
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 停掉背景音乐
        -- self:clearCurMusicBg()

        local waitTime = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        local topSatterNode = self:createCashRushJackpotsSymbol(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                        local scatterPos = self:getPosReelIdx(iRow, iCol)
                        local clipTarPos = util_getOneGameReelsTarSpPos(self, scatterPos)
                        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                        local nodePos = self.m_scatterNode:convertToNodeSpace(worldPos)

                        slotNode:setVisible(false)
                        self.m_bottomScatterTbl[#self.m_bottomScatterTbl+1] = slotNode
                        topSatterNode:setPosition(nodePos)
                        local scatterZorder = 10 - iRow + iCol
                        self.m_scatterNode:addChild(topSatterNode, scatterZorder)
                        topSatterNode:runAnim("actionframe", false, function()
                            slotNode:runAnim("idleframe2", true)
                        end)

                        local duration = topSatterNode:getAnimDurationTime("actionframe")
                        waitTime = util_max(waitTime,duration)

                        if not self.m_slotNodeNoLinePosData[scatterPos] then
                            self.m_slotNodeNoLinePosData[scatterPos] = true
                        end
                    else
                        slotNode:runAnim("zhihui", true)
                    end
                end
            end
        end
        self:playScatterTipMusicEffect()
        performWithDelay(self,function(  )
            self:showChooseView(function()
                _effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end,waitTime)
    end, self.triggerScatterDelayTime)
end

function CodeGameScreenCashRushJackpotsMachine:removeTopTriggerScatter()
    self.m_scatterNode:removeAllChildren()
    for i=1, #self.m_bottomScatterTbl do
        local scatterNode = self.m_bottomScatterTbl[i]
        scatterNode:setVisible(true)
    end
    self.m_bottomScatterTbl = {}
end

---
-- 根据Bonus Game 每关做的处理
function CodeGameScreenCashRushJackpotsMachine:showChooseView(_endCallFunc, _onEnter)
    local endCallFunc = _endCallFunc
    local bonusExtra = self.m_runSpinResultData.p_bonusExtra or {}
    self:removeTopTriggerScatter()
    self:clearCurMusicBg()
    self:resetMusicBg(nil, self.m_publicConfig.Music_Pick_Bg)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Pick_CutScene)
    self.m_cutScenePickSpine:setVisible(true)
    util_spinePlay(self.m_cutScenePickSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_cutScenePickSpine, "actionframe", function()
        self.m_cutScenePickSpine:setVisible(false)
    end)
    --40帧切过场
    performWithDelay(self.m_scWaitNode, function()
        self.m_bottomUI:checkClearWinLabel()
        self:setMainShowState(false)
        self.m_pickView:setVisible(true)
        self.m_pickView:refreshView(bonusExtra, endCallFunc, _onEnter)
    end, 35/30)
end

--pick玩法结束过场
function CodeGameScreenCashRushJackpotsMachine:bonusPickGameOver(_endCallFunc, _hideCallFunc)
    self:addPlayEffect()
    if type(_hideCallFunc) == "function" then
        -- self:setMainShowState(true)
        _hideCallFunc()
        _hideCallFunc = nil
    end
    if type(_endCallFunc) == "function" then
        _endCallFunc()
        _endCallFunc = nil
    end
end

function CodeGameScreenCashRushJackpotsMachine:setMainShowState(_state)
    self.m_mainView:setVisible(_state)
end

function CodeGameScreenCashRushJackpotsMachine:addPlayEffect()
    self:setFreeWildData()
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if not featureDatas then
        return
    end

    for i = 1, #featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

function CodeGameScreenCashRushJackpotsMachine:createCashRushJackpotsSymbol(_symbolType)
    local symbol = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenCashRushJackpotsMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenCashRushJackpotsMachine:showFeatureGameTip(_func)
    -- 预告
    local featureDatas = self.m_runSpinResultData.p_features or {}
    local isTeiggerPick = false
    local isTriggerJackpot = false
    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        isTeiggerPick = true
    end
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.jackpotType then
        isTriggerJackpot = true
    end
    if isTeiggerPick or isTriggerJackpot then
        local randomNum = math.random(1, 10)
        if randomNum <= 4 then
            self.b_gameTipFlag = true
            self.triggerScatterDelayTime = 15/30
        end
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local isFeatureTips = false
        if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsTotalCount
        and self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinsLeftCount == 1 then
            isFeatureTips = true
        end
        if isFeatureTips then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Text_Appear)
            self.m_wildBar:setVisible(true)
            self.m_wildBar:setShowStart()
            self:runCsbAction("faguang", false, function()
                self:runCsbAction("idle", true)
                self:showFreeFirstFeatureTips(_func)
            end)
        else
            _func()
        end
    else
        if self.b_gameTipFlag then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_YuGao_Sound)
            self:runCsbAction("idleframe", true)
            self.m_cutSceneFreeSpine:setVisible(true)
            util_spinePlay(self.m_cutSceneFreeSpine, "yugao", false)
            util_spineEndCallFunc(self.m_cutSceneFreeSpine, "yugao", function()
                self.m_cutSceneFreeSpine:setVisible(false)
                _func()
            end)
            self.m_yuGao:setVisible(true)
            self.m_yuGao:runCsbAction("yugao", false, function()
                self.m_yuGao:setVisible(false)
            end)
        else
            _func()
        end
    end
end

function CodeGameScreenCashRushJackpotsMachine:showFreeFirstFeatureTips(_func)
    local func = _func
    -- wild2
    local loopTimes = 2*3
    local delayInterval = 9/30
    local wildSpineName = "Socre_CashRushJackpots_Wild2"
    -- wild3
    if self.m_freeStarCount and self.m_freeStarCount == 3 then
        loopTimes = 4*3
        delayInterval = 6/30
        wildSpineName = "Socre_CashRushJackpots_Wild3"
    end
    
    -- wildBar上涨
    local totalTime = (loopTimes-1)*delayInterval
    self.m_wildBar:jumpWildCount(self.m_freeWildCount, self.m_freeStarCount, totalTime)

    for i=1, loopTimes do
        local delayTime = (i-1)*delayInterval
        local curIndex = math.mod(i, 3)
        if curIndex == 0 then
            curIndex = 3
        end
        local columnData = self.m_reelColDatas[1]
        local posY = columnData.p_showGridH     
        performWithDelay(self.m_scWaitNode, function()
            local wildSpine = util_spineCreate(wildSpineName,true,true)
            table.insert(self.m_freeFirstWildTbl, wildSpine)
            self.m_zaNodeTbl[curIndex]:addChild(wildSpine, 2)

            local wildTopSpine = util_spineCreate(wildSpineName,true,true)
            table.insert(self.m_freeFirstWildTbl, wildTopSpine)
            wildTopSpine:setPositionY(posY)
            self.m_zaNodeTbl[curIndex]:addChild(wildTopSpine, 1)
            wildTopSpine:setVisible(false)

            local wildBottomSpine = util_spineCreate(wildSpineName,true,true)
            table.insert(self.m_freeFirstWildTbl, wildBottomSpine)
            wildBottomSpine:setPositionY(-posY)
            self.m_zaNodeTbl[curIndex]:addChild(wildBottomSpine, 3)
            wildBottomSpine:setVisible(false)

            util_spinePlay(wildSpine, "za", false)
            util_spineEndCallFunc(wildSpine, "za", function()
                if not tolua.isnull(wildSpine) then
                    wildSpine:setVisible(false)
                end
            end)

            performWithDelay(self.m_scWaitNode, function()
                wildTopSpine:setVisible(true)
                util_spinePlay(wildTopSpine, "za", false)
                util_spineEndCallFunc(wildTopSpine, "za", function()
                    if not tolua.isnull(wildTopSpine) then
                        wildTopSpine:setVisible(false)
                    end
                end)
            end, 3/60)

            performWithDelay(self.m_scWaitNode, function()
                wildBottomSpine:setVisible(true)
                util_spinePlay(wildBottomSpine, "za", false)
                util_spineEndCallFunc(wildBottomSpine, "za", function()
                    if not tolua.isnull(wildBottomSpine) then
                        wildBottomSpine:setVisible(false)
                    end
                end)
            end, 6/60)

            self.m_zaLightAniTbl[curIndex]:setVisible(true)
            self.m_zaLightAniTbl[curIndex]:runCsbAction("za", false, function()
                if i == loopTimes then
                    for j=1, 3 do
                        self.m_zaLightAniTbl[j]:setVisible(false)
                    end
                    
                    -- self.m_wildBar:setShowOver()
                    self:runCsbAction("over", false, function()
                        self:runCsbAction("idleframe", true)
                        for k, v in pairs(self.m_freeFirstWildTbl) do
                            if not tolua.isnull(v) then
                                v:removeFromParent()
                            end
                        end
                        if type(func) == "function" then
                            func()
                        end
                    end)
                end
            end)
        end, delayTime)
    end
end

function CodeGameScreenCashRushJackpotsMachine:updateReelGridNode(_symbolNode)
    local bulingNode = _symbolNode.m_bulingNode
    if not tolua.isnull(bulingNode) then
        bulingNode:removeFromParent()
    end
end

---
-- 显示所有的连线框
--
function CodeGameScreenCashRushJackpotsMachine:showAllFrame(winLines)
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local lineId = lineValue.iLineIdx + 1

        if lineId > 0 then
            self.m_lineNode:showNodeLine(lineId)
        end
    end
    CodeGameScreenCashRushJackpotsMachine.super.showAllFrame(self, winLines)
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenCashRushJackpotsMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    self.m_lineNode:hideNodeLine()
    local lineId = lineValue.iLineIdx + 1
    if lineId > 0 and lineId <= 30 then
        self.m_lineNode:showNodeLine(lineId)
    end
    CodeGameScreenCashRushJackpotsMachine.super.showLineFrameByIndex(self, winLines, frameIndex)
end

-- 当前线的层级要在小块下边（特殊要求）
function CodeGameScreenCashRushJackpotsMachine:setLineSlotNodeZorder(_slotsNode, _isLine)
    local isLine = _isLine
    local slotsNode = _slotsNode
    local tempZorder = 2000
    local curZorder = slotsNode:getLocalZOrder()
    if curZorder < self.m_lineZorder and isLine then
        slotsNode:setLocalZOrder(curZorder + tempZorder)
    elseif curZorder >= self.m_lineZorder and not isLine then
        slotsNode:setLocalZOrder(curZorder - tempZorder)
    end
end

function CodeGameScreenCashRushJackpotsMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    self:setLineSlotNodeZorder(slotsNode, true)
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenCashRushJackpotsMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            self:setLineSlotNodeZorder(slotsNode, true)
            slotsNode:runLineAnim()
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenCashRushJackpotsMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            self:setLineSlotNodeZorder(slotsNode, false)
            slotsNode:runIdleAnim()
        end
    end
end

--开始spin时，所有的小块播静帧
function CodeGameScreenCashRushJackpotsMachine:startSpinSetSlotNodeIdle()
    if next(self.m_slotNodeNoLinePosData) then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    local bulingNode = slotNode.m_bulingNode
                    if not tolua.isnull(bulingNode) then
                        bulingNode:removeFromParent()
                    end
                    slotNode:runIdleAnim()
                end
            end
        end
    end
    self.m_slotNodeNoLinePosData = {}
end

--未参与连线的小块需要置灰
function CodeGameScreenCashRushJackpotsMachine:setNoLineSlotNodeMask()
    if next(self.m_slotNodeNoLinePosData) then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:setReelDarkState(true, 2)
        else
            self:setReelDarkState(true, 1)
        end
        local totalCount = self.m_iReelColumnNum*self.m_iReelRowNum
        for i=1, totalCount do
            if not self.m_slotNodeNoLinePosData[i] then
                local fixPos = self:getRowAndColByPos(i-1)
                local symbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                if symbolNode then
                    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS or symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        local bulingNode = symbolNode.m_bulingNode
                        if not tolua.isnull(bulingNode) then
                            bulingNode:setVisible(true)
                        else
                            symbolNode:runAnim("zhihui", true)
                        end
                    else
                        symbolNode:runAnim("zhihui", true)
                    end
                end
            end
        end
    end
end

function CodeGameScreenCashRushJackpotsMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 and not self.m_jackpotState then
        notAdd = true
    end

    return notAdd
end

--获取底栏金币
function CodeGameScreenCashRushJackpotsMachine:getCurBottomWinCoins()
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

function CodeGameScreenCashRushJackpotsMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:setNoLineSlotNodeMask()
    self:showLineFrame()
    local delayTime = 0
    if self.m_specialWildLine then
        self.m_mulTipBar:setStarType(self.m_specialWildLine-1)
        self:changeBaseLogoBar(4)
        delayTime = 0.5
    end

    performWithDelay(self.m_scWaitNode, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end, delayTime)

    return true
end

-- 改变reel条和背景
function CodeGameScreenCashRushJackpotsMachine:changeBgAndReelBg(_bgType)
    local bgType = _bgType
    self:runCsbAction("idleframe", true)
    for i=1, 2 do
        if i == bgType then
            self.m_bgSpTbl[i]:setVisible(true)
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_bgSpTbl[i]:setVisible(false)
            self.m_reelBg[i]:setVisible(false)
        end
    end
end

-- 改变左上角显示类型
-- 1:logo,2:free,3:bonus,4:mul
function CodeGameScreenCashRushJackpotsMachine:changeBaseLogoBar(_logoType)
    local logoType = _logoType
    local isPlay = true
    for k, v in pairs(self.m_baseNodeDataTbl) do
        if v.state and k == logoType then
            isPlay = false
            break
        end
    end

    if isPlay then
        -- 先把显示的隐藏
        for k, v in pairs(self.m_baseNodeDataTbl) do
            if v.state then
                v.barAni:setVisible(true)
                v.barAni:hideAniTips()
                v.state = false
            else
                v.barAni:setVisible(false)
            end
        end
        
        -- 把隐藏的显示出来
        self.m_baseNodeDataTbl[logoType].state = true
        self.m_baseNodeDataTbl[logoType].barAni:showAniTips()
    end
end

--随机信号
function CodeGameScreenCashRushJackpotsMachine:getReelSymbolType(parentData)
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    local isNotFirstFeatureTips = false
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsTotalCount
        and self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinsLeftCount > 1 then
            isNotFirstFeatureTips = true
        end
    end
    
    --free除了第一次之外，后续都需要增加wild
    local curCol = parentData.cloumnIndex
    if not self.m_freeCurAddWildData[curCol] then
        self.m_freeCurAddWildData[curCol] = 0
    end
    if isNotFirstFeatureTips and curCol > 1 and curCol < 5 then
        self.m_freeCurAddWildData[curCol] = self.m_freeCurAddWildData[curCol] + 1
        if self.m_freeCurAddWildData[curCol] <= self.m_freeNoFirstAddWildCount then
            if self.m_freeStarCount == 2 then
                return self.SYMBOL_SCORE_WILD_2
            else
                return self.SYMBOL_SCORE_WILD_3
            end
        else
            return symbolType
        end
    else
        return symbolType
    end
end

function CodeGameScreenCashRushJackpotsMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenCashRushJackpotsMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if symbolCfg[1] and self:checkSymbolBulingSoundPlay(_slotNode) then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
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
                _slotNode:runAnim(symbolCfg[2], false, function()
                    self:symbolBulingEndCallBack(_slotNode)
                end)
                self:playFalseBulingNode(_slotNode)
            end
        end
    end
end

-- 顶层创建假的落地动画，快停置灰时，落地还没有播完；特殊需求
function CodeGameScreenCashRushJackpotsMachine:playFalseBulingNode(_slotNode)
    local slotNode = _slotNode
    local bulingNode = self:createCashRushJackpotsSymbol(slotNode.p_symbolType)
    slotNode:addChild(bulingNode, 100)
    slotNode.m_bulingNode = bulingNode
    bulingNode:setVisible(false)
    bulingNode:runAnim("buling2", false, function()
        bulingNode:runAnim("zhihui", false)
    end)
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenCashRushJackpotsMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                return self:getCurSymbolIsPlayBuLing(_slotNode)
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenCashRushJackpotsMachine:getCurSymbolIsPlayBuLing(_slotNode)
    if _slotNode.p_cloumnIndex < 5 then
        return true
    else
        local bonusCount = 0
        for iCol = 1, self.m_iReelColumnNum-1 do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    bonusCount = bonusCount + 1
                end
            end
        end
        if bonusCount >= 2 then
            return true
        else
            return false
        end
    end
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenCashRushJackpotsMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end
    -- scatter和bonus同时存在只播放scatter
    local isHaveScatter = false
    for k, _slotNode in pairs(slotNodeList) do
        local symbolType = _slotNode.p_symbolType
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            isHaveScatter = true
            break
        end
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if soundPath then
                    if symbolType == self.SYMBOL_SCORE_BONUS then
                        if not isHaveScatter then
                            self:playBulingSymbolSounds(iCol, soundPath, symbolType)
                        end
                    else
                        self:playBulingSymbolSounds(iCol, soundPath, symbolType)
                    end
                end
            end
        end
    end
end

--快停优先播放scatter
function CodeGameScreenCashRushJackpotsMachine:playQuickStopBulingSymbolSound(_iCol)
    if self:getGameSpinStage() == QUICK_RUN then
        if _iCol == self.m_iReelColumnNum then
            local soundIds = {}
            local bulingDatas = self.m_symbolQsBulingSoundArray
            local isPlayOther = true
            for type, path in pairs(bulingDatas) do
                if tonumber(type) == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isPlayOther = false
                    break
                end
            end

            for soundType, soundPaths in pairs(bulingDatas) do
                local soundPath = soundPaths[#soundPaths]
                if tonumber(soundType) == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or isPlayOther then
                    local soundId = gLobalSoundManager:playSound(soundPath)
                    table.insert(soundIds, soundId)
                end
            end

            return soundIds
        end
    end
end

function CodeGameScreenCashRushJackpotsMachine:playScatterTipMusicEffect(_isFreeMore)
    if not _isFreeMore then
        if self.m_ScatterTipMusicPath ~= nil then
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    else
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Scattrt_Trigger)
    end
end

return CodeGameScreenCashRushJackpotsMachine






