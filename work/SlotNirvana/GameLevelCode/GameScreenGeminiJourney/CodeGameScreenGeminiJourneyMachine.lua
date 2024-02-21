---
-- island li
-- 2019年1月26日
-- CodeGameScreenGeminiJourneyMachine.lua
-- 
-- 玩法：
--[[
    条件：
        1.bonus1：会出现在任何位置
        2.bonus2：只在Respin中出现，会出现在任何位置
        3.wild：只在Base、FG中出现，会出现在2、3、4、5列Reel
        4.scatter：只在Base、FG中出现，会出现在任何位置	
    收集玩法：
        1.出现bonus1会收集；收集只会收集本次spin的bonus；切bet或者下次spin会消失（base和free都会收集）
    base:
        1.3个scatter触发free玩法
        2.高bet下5个bonus1触发respin；底bet下6个bonus1触发respin
    free：
        1.3个scatter触发freeMore玩法
        2.高bet下5个bonus1触发respin；底bet下6个bonus1触发respin
    respin：
        1.respin会有两个棋盘；都有最上边两行待解锁行；当出现95（bonus2）时会解锁；可能会有连续解锁的情况
        2.满盘是获得grand
        3.每个盘最多会出现两个95（bonus2）；且最上方必不可能滚出95（bonus2）信号
]]
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "GeminiJourneyPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenGeminiJourneyMachine = class("CodeGameScreenGeminiJourneyMachine", BaseNewReelMachine)

CodeGameScreenGeminiJourneyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_BONUS_1 = 94
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_BONUS_2 = 95
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_BONUS_3 = 96
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_NULL = 100
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_BONUS_MINI = 101
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_BONUS_MINOR = 102
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_BONUS_MAJOR = 103
CodeGameScreenGeminiJourneyMachine.SYMBOL_SCORE_BONUS_MEGA = 104

-- 自定义动画的标识
CodeGameScreenGeminiJourneyMachine.EFFECT_BONUS_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 7  --bonus玩法；bonus1收集

CodeGameScreenGeminiJourneyMachine.m_playAnimIndex = 0
CodeGameScreenGeminiJourneyMachine.m_lightScore = 0 

local RESPIN_ROW_COUNT = 5
local NORMAL_ROW_COUNT = 3

-- 构造函数
function CodeGameScreenGeminiJourneyMachine:ctor()
    CodeGameScreenGeminiJourneyMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("GeminiJourneySrc.GeminiJourneySymbolExpect", self)
    -- 引入控制插件
    self.m_longRunControl = util_createView("GeminiJourneySrc/GeminiJourneyLongRunControl",self) 

    --大赢光效
    self.m_isAddBigWinLightEffect = true
    self.m_lightScore = 0 

    -- 高bet下最小bet
    self.m_highBetLevelCoins = 0
    -- 本地存储每个betList下bonus1数量
    self.m_localBetListBonusData = {}

    -- 当前需要respin的轮盘个数
    self.m_totalRespinNum = 0
    -- 当前respin停止的个数
    self.m_curRespinNum = 0
    -- 左边轮盘是否停止（respin）用于判断右边轮盘转的个数
    self.m_leftReelIsStop = false
    
    -- 左边轮盘是否已经显示过grand
    self.m_leftIsShowGrand = false
    -- 右边轮盘是否已经显示过grand
    self.m_rightIsShowGrand = false

    -- 当前respin状态(base进去还是断线回来)
    self.m_respinIsCeconnection = false
    -- 右侧假的bonus数据
    self.m_rightFalseBonusData = {}
    -- respin解锁的行数(默认为3);停轮后再赋值
    self.m_respinUnlockRowTbl = {3, 3}
    -- respin轮盘最后一个格子是否要延迟（策划觉得最后一个格子中grand的话，切的太快，如果有加个延时）
    self.m_respinGrandDelayTbl = {0, 0}
    -- 当前scatter落地的个数
    self.m_curScatterBulingCount = 0
    -- 当前respin播放音效index
    self.m_curPlayRespinSoundIndex = 1
    -- respin复制bonus音效
    self.m_respinCopyBonusSoundTbl = {}
    -- respin第一次解锁的音效标记
    self.m_resppinFirstPlaySound = false

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true

    self.m_symbolNodeRandom = {
        1, 6, 11, 16, 21,
        2, 7, 12, 17, 22,
        3, 8, 13, 18, 23,
        4, 9, 14, 19, 24,
        5, 10, 15, 20, 25
    }

    --init
    self:initGame()
end

function CodeGameScreenGeminiJourneyMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("GeminiJourneyConfig.csv", "LevelGeminiJourneyConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    self:resetQuickRunData()
end  

-- 当前快滚列是哪种类型的快滚
function CodeGameScreenGeminiJourneyMachine:resetQuickRunData()
    self.m_quickRunSymbolAndCol = 
    {
        SCATTER_MIN_COL = 5,
        BONUS_MIN_COL = 5,
    }
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGeminiJourneyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "GeminiJourney"  
end

function CodeGameScreenGeminiJourneyMachine:getBottomUINode()
    return "GeminiJourneySrc.GeminiJourneBottomNode"
end

-- 继承底层respinView
function CodeGameScreenGeminiJourneyMachine:getRespinView()
    return "GeminiJourneySrc.GeminiJourneyRespinView"    
end

-- 继承底层respinNode
function CodeGameScreenGeminiJourneyMachine:getRespinNode()
    return "GeminiJourneySrc.GeminiJourneyRespinNode"    
end

function CodeGameScreenGeminiJourneyMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets or {}
    end

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    local level = 0
    if next(self.m_specialBets) then
        self.m_highBetLevelCoins = self.m_specialBets[1].p_totalBetValue
        if betCoin >= self.m_specialBets[1].p_totalBetValue then
            level = 1
        else
            level = 0
        end
    end
    self.m_iBetLevel = level
end

function CodeGameScreenGeminiJourneyMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView()

    --右侧收集栏
    self.m_collectBarView = util_createView("GeminiJourneySrc.GeminiJourneyCollectView", self)
    self:findChild("Node_RespinCounter"):addChild(self.m_collectBarView) --修改成自己的节点 

    -- reel条
    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("Node_base_reels")
    self.m_reelBg[2] = self:findChild("Node_free_reels")

    self.m_respinEffectNode = self:findChild("Node_respinEffect")

    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))
    --respin最后收集层
    self.m_respinCollectNode = cc.Node:create()
    self.m_respinCollectNode:setPosition(worldPos)
    self:addChild(self.m_respinCollectNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_respinCollectNode:setScale(self.m_machineRootScale)

    self:addClick(self:findChild("Panel_click"))

    self.m_skip_click = self:findChild("Panel_skip_click")
    self.m_skip_click:setVisible(false)
    self:addClick(self.m_skip_click)

    -- --respin光效层
    -- self.m_respinTopNode = self:findChild("Node_topEffect")
    -- self.m_respinTopNodeTbl = {}
    -- for i=1, 2 do
    --     self.m_respinTopNodeTbl[i] = cc.Node:create()
    --     self.m_respinTopNode:addChild(self.m_respinTopNodeTbl[i])
    -- end

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_respinWaitNode = cc.Node:create()
    self:addChild(self.m_respinWaitNode)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenGeminiJourneyMachine:initSpineUI()
    --背景
    self.m_bgSpine = util_spineCreate("GameScreenGeminiJourneyBg",true,true)
    self.m_gameBg:findChild("root"):addChild(self.m_bgSpine)

    --respin棋盘
    self.m_respinBoardRoot = util_createAnimation("GeminiJourney_ReSpinRootNode.csb")
    self:findChild("Node_RespinNode"):addChild(self.m_respinBoardRoot)
    self.m_respinRootNode1 = self.m_respinBoardRoot:findChild("Node_reel1")
    self.m_respinRootNode2 = self.m_respinBoardRoot:findChild("Node_reel2")

    -- respinBar
    self.m_baseReSpinBarTbl = {}
    for i=1, 2 do
        self.m_baseReSpinBarTbl[i] = util_createView("GeminiJourneySrc.GeminiJourneyRespinBarView")
    end

    --respin光效层(最后一个格子)
    self.m_respinTopNodeTbl = {}
    for i=1, 2 do
        self.m_respinTopNodeTbl[i] = cc.Node:create()
    end

    self.m_respinBoardTbl = {}
    -- 左边respin棋盘
    self.m_respinBoardTbl[1] = util_createView("GeminiJourneySrc.GeminiJourneyRespinBoardView", {_machine = self, _boardIndex = 1, _respinbar = self.m_baseReSpinBarTbl[1], _respinTopNode = self.m_respinTopNodeTbl[1]})
    self.m_respinRootNode1:addChild(self.m_respinBoardTbl[1])

    -- 右边respin棋盘
    self.m_respinBoardTbl[2] = util_createView("GeminiJourneySrc.GeminiJourneyRespinBoardView", {_machine = self, _boardIndex = 2, _respinbar = self.m_baseReSpinBarTbl[2], _respinTopNode = self.m_respinTopNodeTbl[2]})
    self.m_respinRootNode2:addChild(self.m_respinBoardTbl[2])

    -- 预告中奖
    self.m_yuGaoSpine = util_spineCreate("GeminiJourney_yugao",true,true)
    self:findChild("Node_yugao"):addChild(self.m_yuGaoSpine)
    self.m_yuGaoSpine:setVisible(false)

    --大赢下边
    self.m_bigWinAni = util_createAnimation("GeminiJourney_bigwin_bg.csb")
    self:findChild("Node_bigwin_bg"):addChild(self.m_bigWinAni)
    self.m_bigWinAni:setVisible(false)

    --大赢上边
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("GeminiJourney_bigwin",true,true)
    self.m_bigWinSpine:setScale(self.m_machineRootScale)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bigWinSpine:setVisible(false)

    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local freeWorldPos = self:findChild("root"):convertToWorldSpace(cc.p(nodePosX, nodePosY))

    -- base-free过场
    self.m_cutSceneFreeStartSpine = util_spineCreate("GeminiJourney_start_qiu",true,true)
    self.m_cutSceneFreeStartSpine:setVisible(false)
    self.m_cutSceneFreeStartSpine:setPosition(freeWorldPos)
    self.m_cutSceneFreeStartSpine:setScale(self.m_machineRootScale)
    self:addChild(self.m_cutSceneFreeStartSpine, GAME_LAYER_ORDER.LAYER_ORDER_UI + 1)

    -- free-base过场
    self.m_cutSceneFreeOverSpine = util_spineCreate("GeminiJourney_start_qiu",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneFreeOverSpine)
    self.m_cutSceneFreeOverSpine:setVisible(false)

    -- base-respin过场
    self.m_cutSceneRespinSpine = util_spineCreate("Socre_GeminiJourney_9",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneRespinSpine)
    self.m_cutSceneRespinSpine:setVisible(false)

    -- respin结束过场
    self.m_cutSceneRespinOverSpine = util_spineCreate("Socre_GeminiJourney_9",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneRespinOverSpine)
    self.m_cutSceneRespinOverSpine:setVisible(false)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "GeminiJourney_totalwin_tx")

    self:changeBgSpine(1)
    self:setCurPlayState()
end


function CodeGameScreenGeminiJourneyMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Enter_Game, 4, 0, 1)
    end)
end

function CodeGameScreenGeminiJourneyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenGeminiJourneyMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenGeminiJourneyMachine:initGameUI()
    self:updateBetLevel()
    self:updateRightBonus(true)

    --respin模式
    if self:getCurStateIsRespin() then
        self.m_baseFreeSpinBar:setVisible(false)
        self:changeBgSpine(3)
    elseif self.m_bProduceSlots_InFreeSpin then
        --Free模式
        self:changeBgSpine(2)
        self:refreshCollectBar(true, true)
    else
        self:refreshCollectBar(true)
    end
end

function CodeGameScreenGeminiJourneyMachine:addObservers()
    CodeGameScreenGeminiJourneyMachine.super.addObservers(self)
    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:clearWinLineEffect()
            self:updateBetLevel()
            self:refreshCollectBar(true)
            self:updateRightBonus()
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

        local soundName = "GeminiJourneySounds/music_GeminiJourney_last_win_".. bgmType .. "_"..soundIndex..".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenGeminiJourneyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenGeminiJourneyMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenGeminiJourneyMachine:scaleMainLayer()
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
            mainScale = mainScale * 1.04
            mainPosY = mainPosY + 5
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 0.92
            mainPosY = mainPosY + 10
        elseif display.width / display.height >= 1152/768 then
            mainScale = mainScale * 0.92
            mainPosY = mainPosY + 10
        elseif display.width / display.height >= 920/768 then
            mainScale = mainScale * 0.92
            mainPosY = mainPosY + 10
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGeminiJourneyMachine:MachineRule_GetSelfCCBName(symbolType)
    if self:getCurSymbolIsBonus(symbolType) then
        return "Socre_GeminiJourney_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_2 then
        return "Socre_GeminiJourney_BonusRise"
    elseif symbolType == self.SYMBOL_SCORE_NULL then
        return "Socre_GeminiJourney_NULL"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_GeminiJourney_10"
    elseif symbolType == self.SYMBOL_SCORE_BONUS_3 then
        return "Socre_GeminiJourney_BonusNode"
    end 


    
    return nil
end

-- 是否为bonus1或者jackpot类型
function CodeGameScreenGeminiJourneyMachine:getCurSymbolIsBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_BONUS_1 or
       symbolType == self.SYMBOL_SCORE_BONUS_MINI or
       symbolType == self.SYMBOL_SCORE_BONUS_MINOR or
       symbolType == self.SYMBOL_SCORE_BONUS_MAJOR or
       symbolType == self.SYMBOL_SCORE_BONUS_MEGA then
        return true
    end
    return false
end

-- 是否为jackpot类型
function CodeGameScreenGeminiJourneyMachine:getCurSymbolIsBonusJackpot(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_BONUS_MINI or
       symbolType == self.SYMBOL_SCORE_BONUS_MINOR or
       symbolType == self.SYMBOL_SCORE_BONUS_MAJOR or
       symbolType == self.SYMBOL_SCORE_BONUS_MEGA then
        return true
    end
    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGeminiJourneyMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenGeminiJourneyMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

--初始棋盘
function CodeGameScreenGeminiJourneyMachine:initGridList()
    CodeGameScreenGeminiJourneyMachine.super.initGridList(self)
    local hasFeature = self:checkHasFeature()
    if hasFeature == false then
        local curBet = globalData.slotRunData:getCurTotalBet()
        local curMul = 5
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS_1 then
                    local symbol_node = slotNode:checkLoadCCbNode()
                    local spineNode = symbol_node:getCsbAct()
                    if not tolua.isnull(spineNode.m_bonusNodeScore) then
                        local coins = curMul * curBet
                        local sScore = util_formatCoins(coins, 3)
                        local bonusNodeScore = spineNode.m_bonusNodeScore
                        self:setNodeScoreType(bonusNodeScore, self.SYMBOL_SCORE_BONUS_1)
                        local label = bonusNodeScore:findChild("m_lb_coins")
                        label:setString(sScore)
                    end
                end
            end
        end
    end
end

-- 刷新右侧bonus个数
function CodeGameScreenGeminiJourneyMachine:updateRightBonus(_onEnter)
    if _onEnter then
        self.m_collectBarView:collectBonusNode(false, 0, true)
    else
        local curBet = globalData.slotRunData:getCurTotalBet()
        if self.m_localBetListBonusData and self.m_localBetListBonusData[tostring(toLongNumber(curBet) )] then
            local bonusCount = self.m_localBetListBonusData[tostring(toLongNumber(curBet))]
            self.m_collectBarView:collectBonusNode(false, bonusCount)
        else
            self.m_collectBarView:collectBonusNode(false, 0, true)
        end
    end
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenGeminiJourneyMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

function CodeGameScreenGeminiJourneyMachine:initGameStatusData(gameData)
    CodeGameScreenGeminiJourneyMachine.super.initGameStatusData(self,gameData)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenGeminiJourneyMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end


function CodeGameScreenGeminiJourneyMachine:beginReel()
    self.m_curScatterBulingCount = 0
    self.m_respinIsCeconnection = false
    self.m_collectBarView:spinCloseTips()
    self.m_collectBarView:collectBonusNode(false, 0)
    CodeGameScreenGeminiJourneyMachine.super.beginReel(self)
end

--默认按钮监听回调
function CodeGameScreenGeminiJourneyMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" then
        self.m_collectBarView:spinCloseTips()
    elseif name == "Panel_skip_click" then
        self:runSkipCollect()
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenGeminiJourneyMachine:slotLocalOneReelDown(_iCol)
    self:playReelDownSound(_iCol, self.m_reelDownSound)
end

--
--单列滚动停止回调
--
function CodeGameScreenGeminiJourneyMachine:slotOneReelDown(reelCol)    
    CodeGameScreenGeminiJourneyMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
end

---
--添加金边
function CodeGameScreenGeminiJourneyMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    local scatterNode = reelEffectNode:getChildByName("Node_scatter")
    local bonusNode = reelEffectNode:getChildByName("Node_bonus")
    scatterNode:setVisible(col > self.m_quickRunSymbolAndCol.SCATTER_MIN_COL)
    bonusNode:setVisible(col > self.m_quickRunSymbolAndCol.BONUS_MIN_COL)

    if self.m_reelBgEffectName ~= nil and col > self.m_quickRunSymbolAndCol.SCATTER_MIN_COL then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--[[
    滚轮停止
]]
function CodeGameScreenGeminiJourneyMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_collectBarView:closeLastCollectEffectNode()
    CodeGameScreenGeminiJourneyMachine.super.slotReelDown(self)

    -- 重置快滚列
    self:resetQuickRunData()
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGeminiJourneyMachine:addSelfEffect()
    self.m_localBetListBonusData = {}

    -- 判断当前轮盘是否有bonus1信号
    local curBonusCount = self:getCurReelBonusCount()
    if curBonusCount > 0 then
        -- -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = self.EFFECT_BONUS_COLLECT_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.EFFECT_BONUS_COLLECT_EFFECT -- 动画类型

        -- 存储在本地betList列表里
        self:setCurBetBonusCount(curBonusCount)
    end
end

-- 设置当前bet，bonus个数
function CodeGameScreenGeminiJourneyMachine:setCurBetBonusCount(_curBonusCount)
    local curBonusCount = _curBonusCount
    local curBet = globalData.slotRunData:getCurTotalBet()
    self.m_localBetListBonusData[tostring(toLongNumber(curBet))] = curBonusCount
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGeminiJourneyMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BONUS_COLLECT_EFFECT then
        self:showCollecttBaseBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

-- 判断当前轮盘是否有bonus1信号
function CodeGameScreenGeminiJourneyMachine:getCurReelBonusCount()
    local reels = self.m_runSpinResultData.p_reels
    local curBonusCount = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = reels[iRow][iCol]
            if symbolType == self.SYMBOL_SCORE_BONUS_1 then
                curBonusCount = curBonusCount + 1
            end
        end
    end

    return curBonusCount
end

function CodeGameScreenGeminiJourneyMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenGeminiJourneyMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

-- free和freeMore特殊需求
function CodeGameScreenGeminiJourneyMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FreeMore_ScatterTrigger)
        else
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenGeminiJourneyMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end


function CodeGameScreenGeminiJourneyMachine:checkRemoveBigMegaEffect()
    CodeGameScreenGeminiJourneyMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenGeminiJourneyMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("GeminiJourneySrc.GeminiJourneyFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_FreeSpinBar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenGeminiJourneyMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("GeminiJourneySounds/music_GeminiJourney_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        local freeStartSpine = util_spineCreate("GeminiJourney_start_qiu",true,true)
        local lightAni = util_createAnimation("GeminiJourney_free_tbguang.csb")
        lightAni:runCsbAction("idle", true)
        util_spinePlay(freeStartSpine, "actionframe_tanban_start", false)
        util_spineEndCallFunc(freeStartSpine, "actionframe_tanban_start", function()
            util_spinePlay(freeStartSpine, "actionframe_tanban_idle", true)
        end)

        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FgMore_Start)
            self.m_baseFreeSpinBar:setIsRefresh(true)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)

            view:findChild("Node_qiu"):addChild(lightAni)
            view:findChild("Node_qiu"):addChild(freeStartSpine, 2)
            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartStart)
            local cutSceneFunc = function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Normal_Click)

                -- 10帧后切过场
                performWithDelay(self.m_scWaitNode, function()
                    self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_FG_Bg)
                    self:showCutPlaySceneFreeStartAni(function()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()   
                    end)
                end, 10/60)
            end

            self.m_baseFreeSpinBar:changeFreeSpinByCount()
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                 
            end)

            view:setBtnClickFunc(cutSceneFunc)
            view:findChild("Node_qiu"):addChild(lightAni)
            view:findChild("Node_qiu"):addChild(freeStartSpine, 2)
            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

-- base-free过场
function CodeGameScreenGeminiJourneyMachine:showCutPlaySceneFreeStartAni(_callFunc)
    local callFunc = _callFunc
    
    local spineName = "actionframe_guochang"
    self.m_cutSceneFreeStartSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Fg_CutScene)
    util_spinePlay(self.m_cutSceneFreeStartSpine, spineName, false)
    util_spineEndCallFunc(self.m_cutSceneFreeStartSpine, spineName, function()
        self.m_cutSceneFreeStartSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)

    -- 30帧切
    performWithDelay(self.m_scWaitNode, function()
        self.m_baseFreeSpinBar:setVisible(true)
        self:changeBgSpine(2)
    end, 30/30)
end

-- free-base过场
function CodeGameScreenGeminiJourneyMachine:showCutPlaySceneFreeOverAni(_callFunc)
    local callFunc = _callFunc
    
    local spineName = "actionframe_guochang2"
    self.m_cutSceneFreeOverSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Base_CutScene)
    util_spinePlay(self.m_cutSceneFreeOverSpine, spineName, false)
    util_spineEndCallFunc(self.m_cutSceneFreeOverSpine, spineName, function()
        self.m_cutSceneFreeOverSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)

    -- 30帧切
    performWithDelay(self.m_scWaitNode, function()
        self.m_baseFreeSpinBar:setVisible(false)
        self:changeBgSpine(1)
    end, 30/30)
end

-- respin结束过场
function CodeGameScreenGeminiJourneyMachine:showRespinOverCutPlaySceneAni(_callFunc, _endCallFunc)
    local callFunc = _callFunc
    local endCallFunc = _endCallFunc

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Respin_Base_CutScene)
    self.m_cutSceneRespinOverSpine:setVisible(true)
    util_spinePlay(self.m_cutSceneRespinOverSpine, "actionframe_guochang2", false)
    util_spineEndCallFunc(self.m_cutSceneRespinOverSpine, "actionframe_guochang2", function()
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end)

     -- 80帧切
     performWithDelay(self.m_scWaitNode, function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, 80/30)
end

-- base(free)-respin-base(free)过场
function CodeGameScreenGeminiJourneyMachine:showRespinCutPlaySceneAni(_callFunc)
    local callFunc = _callFunc
    self.m_cutSceneRespinSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Enter_Respin_CutScene)
    util_spinePlay(self.m_cutSceneRespinSpine, "actionframe_guochang", false)
    util_spineEndCallFunc(self.m_cutSceneRespinSpine, "actionframe_guochang", function()
        self.m_cutSceneRespinSpine:setVisible(false)
    end)

    -- 80帧切
    performWithDelay(self.m_scWaitNode, function()
        self.m_baseFreeSpinBar:setVisible(false)
        self:changeBgSpine(3)
        if type(callFunc) == "function" then
            callFunc()
        end
    end, 80/30)
end

function CodeGameScreenGeminiJourneyMachine:showFreeSpinOverView(effectData)
    globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Fg_OverStart, 2, 0, 1)
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    if globalData.slotRunData.lastWinCoin > 0 then
        local cutSceneFunc = function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Normal_Click)
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
            end, 5/60)
        end
        local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            self:showCutPlaySceneFreeOverAni(function()
                self:triggerFreeSpinOverCallFun()
            end)  
        end)
        view:setBtnClickFunc(cutSceneFunc)
        local node=view:findChild("m_lb_coins")
        view:findChild("root"):setScale(self.m_machineRootScale)
        view:updateLabelSize({label=node, sx=1.0 ,sy=1.0}, 662)    
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:showCutPlaySceneFreeOverAni(function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)
    end
end

function CodeGameScreenGeminiJourneyMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FreeSpinOver_NoWin",nil,_func)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenGeminiJourneyMachine:showEffect_FreeSpin(effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.m_beInSpecialGameTrigger = true
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 停掉背景音乐
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self:clearCurMusicBg()
        end
        self:levelDeviceVibrate(6, "free")
        local waitTime = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local parent = slotNode:getParent()
                    if parent ~= self.m_clipParent then
                        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                    end
                    slotNode:runAnim("actionframe")
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                end
            end
        end
        self:playScatterTipMusicEffect(true)
        
        performWithDelay(self,function()
            self:showFreeSpinView(effectData)
        end,waitTime)
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end, 0.5)
    return true    
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenGeminiJourneyMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    self.m_bigWinAni:setVisible(true)
    self.m_bigWinSpine:setVisible(true)
    self.m_bigWinAni:runCsbAction("actionframe_bigwin", false)
    util_spinePlay(self.m_bigWinSpine, "actionframe_bigwin", false)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe_bigwin", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinAni:setVisible(false)
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime("actionframe_bigwin")
    util_shakeNode(rootNode,5,10,aniTime)
end

function CodeGameScreenGeminiJourneyMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win)
    local randomNum = math.random(1, 10)
    if randomNum <= 5 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_WinEffect)
    end
    CodeGameScreenGeminiJourneyMachine.super.showEffect_runBigWinLightAni(self, effectData)
    return true
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenGeminiJourneyMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenGeminiJourneyMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
    @desc: 根据symbolType
    time:2019-03-20 15:12:12
    --@symbolType:
	--@row:
    --@col:
    --@isLastSymbol:
    @return:
]]
function CodeGameScreenGeminiJourneyMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol, _reelIndex)
    if isLastSymbol == nil then
        isLastSymbol = false
    end
    local symblNode = self:getSlotNodeBySymbolType(symbolType)
    symblNode.p_cloumnIndex = col
    symblNode.p_rowIndex = row
    symblNode.m_isLastSymbol = isLastSymbol

    self:updateReelGridNode(symblNode, _reelIndex)
    self:checkAddSignOnSymbol(symblNode)
    return symblNode
end

function CodeGameScreenGeminiJourneyMachine:updateReelGridNode(_symbolNode, _reelIndex)
    local symbolType = _symbolNode.p_symbolType
    if self:getCurSymbolIsBonus(symbolType) or symbolType == self.SYMBOL_SCORE_BONUS_3 then
        self:setSpecialNodeScoreBonus(_symbolNode, _reelIndex)
    else
        local nodeScore = _symbolNode:getChildByName("bonus_tag")
        if not tolua.isnull(nodeScore) then
            nodeScore:removeFromParent()
        end
    end
end

-- 给respin小块进行赋值
function CodeGameScreenGeminiJourneyMachine:setSpecialNodeScoreBonus(_symbolNode, _reelIndex, _bonusSpine, _isBonus2)
    local symbolNode = _symbolNode
    local reelIndex = _reelIndex
    local bonusSpine = _bonusSpine
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        symbolNode:runAnim("idleframe2", true)
    end

    local curBet = globalData.slotRunData:getCurTotalBet()
    local spineNode = bonusSpine

    if not bonusSpine then
        local symbol_node = symbolNode:checkLoadCCbNode()
        spineNode = symbol_node:getCsbAct()
    end
    local bonusNodeScore, scatterCoins
    if symbolType == self.SYMBOL_SCORE_BONUS_3 then
        local nodeScore = _symbolNode:getChildByName("bonus_tag")
        if not tolua.isnull(nodeScore) then
            bonusNodeScore = nodeScore
        else
            bonusNodeScore = util_createAnimation("Socre_GeminiJourney_BonusCoins.csb")
            symbolNode:addChild(bonusNodeScore, 100)
            bonusNodeScore:setPosition(cc.p(0, 0))
            bonusNodeScore:setName("bonus_tag")
            bonusNodeScore:setScale(0.54)
        end
    else
        local nodeScore = _symbolNode:getChildByName("bonus_tag")
        if not tolua.isnull(nodeScore) then
            nodeScore:removeFromParent()
        end
        if not tolua.isnull(spineNode.m_bonusNodeScore) then
            bonusNodeScore = spineNode.m_bonusNodeScore
        else
            bonusNodeScore = util_createAnimation("Socre_GeminiJourney_BonusCoins.csb")
            local slotName = "shuzi2"
            if _isBonus2 then
                slotName = "shuzi"
            end
            -- util_bindNode(spineNode,slotName, bonusNodeScore)
            util_spinePushBindNode(spineNode, slotName, bonusNodeScore)
            spineNode.m_bonusNodeScore = bonusNodeScore
        end
    end

    local sScore = ""
    local curMul = 1
    if symbolType == self.SYMBOL_SCORE_BONUS_1 or _isBonus2 then
        if symbolNode.m_isLastSymbol == true then
            local mul = 1
            if reelIndex then
                mul = self:getReSpinBonusScore(self:getPosReelIdx(iRow, iCol), _reelIndex)
            else
                mul = self:getSpinBonusScore(self:getPosReelIdx(iRow, iCol))
            end
            if mul ~= nil and mul ~= 0 then
                curMul = mul
                local coins = mul * curBet
                sScore = util_formatCoins(coins, 3)
            end
        else
            -- 获取随机分数（本地配置）
            local mul = self:randomDownSpinSymbolScore(symbolNode.p_symbolType)
            local coins = mul * curBet
            sScore = util_formatCoins(coins, 3)
        end
    elseif symbolType == self.SYMBOL_SCORE_BONUS_3 then
        -- 获取随机分数（本地配置）
        local mul = self:randomDownSpinSymbolScore(symbolNode.p_symbolType)
        local coins = mul * curBet
        sScore = util_formatCoins(coins, 3)
    end
    
    local label = bonusNodeScore:findChild("m_lb_coins")
    label:setString(sScore)
    if reelIndex then
        self:updateLabelSize({label=label, sx=1.0 ,sy=1.0}, 150)
    end
    self:setNodeScoreType(bonusNodeScore, symbolType)
end

-- 根据网络数据获得baseBonus小块的分数
function CodeGameScreenGeminiJourneyMachine:getSpinBonusScore(id)
    if not self.m_runSpinResultData.p_storedIcons then
        return 0
    end
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}

    local score = 0
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    return score
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenGeminiJourneyMachine:getReSpinBonusScore(id, _reelIndex)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if not rsExtraData then
        return
    end

    local storedIcons = {}
    if _reelIndex and _reelIndex == 1 then
        local reelData1 = rsExtraData.reels1 or {}
        storedIcons = reelData1.storedIcons or {}
    else
        local reelData2 = rsExtraData.reels2 or {}
        storedIcons = reelData2.storedIcons or {}
    end

    local score = 0
    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            break
        end
    end

    return score   
end

function CodeGameScreenGeminiJourneyMachine:randomDownSpinSymbolScore(symbolType)
    local score = self.m_configData:getBnBasePro()

    return score
end

-- 设置bonus1上字体的类型
function CodeGameScreenGeminiJourneyMachine:setNodeScoreType(bonusNodeScore, symbolType)
    bonusNodeScore:runCsbAction("idle", true)
    if symbolType == self.SYMBOL_SCORE_BONUS_1 or symbolType == self.SYMBOL_SCORE_BONUS_2 or symbolType == self.SYMBOL_SCORE_BONUS_3 then
        bonusNodeScore:findChild("m_lb_coins"):setVisible(true)
    else
        bonusNodeScore:findChild("m_lb_coins"):setVisible(false)
    end
    bonusNodeScore:findChild("mini"):setVisible(symbolType == self.SYMBOL_SCORE_BONUS_MINI)
    bonusNodeScore:findChild("minor"):setVisible(symbolType == self.SYMBOL_SCORE_BONUS_MINOR)
    bonusNodeScore:findChild("major"):setVisible(symbolType == self.SYMBOL_SCORE_BONUS_MAJOR)
    bonusNodeScore:findChild("mega"):setVisible(symbolType == self.SYMBOL_SCORE_BONUS_MEGA)
end

function CodeGameScreenGeminiJourneyMachine:MachineRule_respinTouchSpinBntCallBack()
    if (self.m_respinView and self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW) or (self.m_respinView2 and self.m_respinView2:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW) then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)
        self:startReSpinRun()
    elseif (self.m_respinView and self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN) or (self.m_respinView2 and self.m_respinView2:getouchStatus() == ENUM_TOUCH_STATUS.RUN) then
        --快停
        self:quicklyStop()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    elseif not self.m_respinView or not self.m_respinView2 then
        release_print("当前出错关卡名称:" .. self:getModuleName())
    end
end

--- respin 快停
function CodeGameScreenGeminiJourneyMachine:quicklyStop()
    self.m_respinView:quicklyStop()
    self.m_respinView2:quicklyStop()
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenGeminiJourneyMachine:getRespinRandomTypes()
    local symbolList = 
    { 
        self.SYMBOL_SCORE_NULL,
        self.SYMBOL_SCORE_BONUS_3,
    }
    return symbolList    
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenGeminiJourneyMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_SCORE_BONUS_1, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_BONUS_2, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_BONUS_3, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_BONUS_MINI, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_BONUS_MINOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_BONUS_MAJOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_BONUS_MEGA, runEndAnimaName = "", bRandom = true},
    }
    return symbolList    
end

--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function CodeGameScreenGeminiJourneyMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    if self.m_initSpinData and self.m_initSpinData.p_rsExtraData and self.m_initSpinData.p_rsExtraData.reels1 and self.m_initSpinData.p_rsExtraData.reels2 then
        local respinCount1 = self.m_initSpinData.p_rsExtraData.reels1.count or 0
        local respinCount2 = self.m_initSpinData.p_rsExtraData.reels2.count or 0
        local maxRespinCount = util_max(respinCount1, respinCount2)
        if maxRespinCount > 0 then
            self.m_initSpinData.p_reSpinsTotalCount = 3
            self.m_initSpinData.p_reSpinCurCount = maxRespinCount
        end
    end
    if self.m_initSpinData.p_reSpinsTotalCount ~= nil and self.m_initSpinData.p_reSpinsTotalCount > 0 and self.m_initSpinData.p_reSpinCurCount > 0 then
        self.m_respinIsCeconnection = true
        --手动添加freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        local reSpinEffect = GameEffectData.new()
        reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
        reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

        self.m_isRunningEffect = true

        if self.checkControlerReelType and self:checkControlerReelType() then
            globalMachineController.m_isEffectPlaying = true
        end

        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenGeminiJourneyMachine:showReSpinStart(_callFunc)
    local callFunc = _callFunc
    self.collectBonus = true
    local endCallFunc = function()
        callFunc()
    end

    local startRespinFunc = function()
        self:showTriggerRespinAction(endCallFunc)
    end

    -- base进respin
    if not self.m_respinIsCeconnection then
        local respinStartSpine = util_spineCreate("Socre_GeminiJourney_Bonus",true,true)
        util_spinePlay(respinStartSpine, "Respin_start", false)
        util_spineEndCallFunc(respinStartSpine, "Respin_start", function()
            util_spinePlay(respinStartSpine, "guochang", false)
            self:showRespinCutPlaySceneAni(function()
                --隐藏 盘面信息
                -- 更改respin 状态下的背景音乐
                self:changeReSpinBgMusic()
                self.m_respinView:setVisible(false)
                self.m_respinView2:setVisible(false)
                self:setReelSlotsNodeVisible(false)
                self:setCurPlayState(true)
                self:showRespinBar(false)
                for i=1, 2 do
                    self:startRespinUnLockBar(i, 2, true)
                    self:showBottomLight(i, false)
                    self:showBottomReelAni(i, "idle1")
                    self:showGrandAni(i, false, "idle")
                end
                self.m_respinEffectNode:setVisible(true)
            end)
            --添加最上层假的respinbonus
            self:addRespinFalseBonus()
            self.m_respinEffectNode:setVisible(false)
            -- 更新respin次数
            local respinCount1, respinCount2 = self:getCurRespinCount()
            self:changeReSpinStartUI(respinCount1, 1, true)
            self:changeReSpinStartUI(respinCount2, 2, true)
        end)

        local lightAni = util_createAnimation("GeminiJourney_free_tbguang.csb")
        lightAni:runCsbAction("idle", true)

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Respin_StartStart)
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, startRespinFunc, BaseDialog.AUTO_TYPE_ONLY)
        view:findChild("spine"):addChild(respinStartSpine)
        view:findChild("lights"):addChild(lightAni)
        view:findChild("root"):setScale(self.m_machineRootScale)
        util_setCascadeOpacityEnabledRescursion(view, true)
    else
        startRespinFunc()
    end
end

function CodeGameScreenGeminiJourneyMachine:showTriggerRespinAction(_callFunc)
    local callFunc = _callFunc
    local endCallFunc = function()
        callFunc()
    end

    local tblActionList = {}
    if not self.m_respinIsCeconnection then
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.3)
        -- 根据bonus数量延时时间（每个0.4s，再加上落地）
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:flyFalseBonusToRight(0)
            self:setSkipData(endCallFunc, true)
        end)
        local flyTime = table_length(self.m_rightFalseBonusData) * 0.4 + 0.6
        tblActionList[#tblActionList+1] = cc.DelayTime:create(flyTime)
        -- 所有Bonus全部复制结束后0.4s
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.7)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:setSkipData(nil, false)
            --显示respinBar
            self.m_respinEffectNode:removeAllChildren()
            self.m_respinView:setVisible(true)
            self.m_respinView2:setVisible(true)
            self:showRespinBar(true, true)
            local respinViewTbl = {self.m_respinView, self.m_respinView2}
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Respin_LockRow_Show)
            for i=1, 2 do
                respinViewTbl[i]:startShowClipNode(true)
                self:startRespinLockBar(i)
                self:showBottomLight(i, true, true)
                self:showBottomReelAni(i, "idle2")
            end
        end)
        --流程14结束后0.2s，自动开始第一次spin；或流程14结束后，允许玩家开始spin
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.4)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            endCallFunc()
        end)
    else
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            --显示respinBar
            self.m_respinEffectNode:removeAllChildren()
            self.m_respinView:setVisible(true)
            self.m_respinView2:setVisible(true)
            self:setReelSlotsNodeVisible(false)
            self:setCurPlayState(true)
            self:showRespinBar(true)
            -- 更新respin次数
            local respinCount1, respinCount2 = self:getCurRespinCount()
            local respinCountTbl = {respinCount1, respinCount2}
            if respinCount1 == 0 then
                self.m_leftReelIsStop = true
            end
            -- 更新grand
            local isHaveGrand1, isHaveGrand2 = self:getEndIsHaveGrand()
            local grandTbl = {isHaveGrand1, isHaveGrand2}
            local respinViewTbl = {self.m_respinView, self.m_respinView2}
            for i=1, 2 do
                -- 更新respin次数
                if respinCountTbl[i] > 0 then
                    self:changeReSpinStartUI(respinCountTbl[i], i, true)
                else
                    self:changeReSpinUIState(i, true)
                    respinViewTbl[i]:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
                end
                -- 更新respin底光
                local isShow = respinCountTbl[i] > 0 and true or false
                local unlockRow = self.m_respinUnlockRowTbl[i] - 3
                self:startRespinUnLockBar(i, unlockRow, true)
                self:showBottomLight(i, isShow)
                self:showBottomReelAni(i, "idle2")
                self:showGrandAni(i, grandTbl[i], "idle")
            end
            self:changeReSpinBgMusic()
            endCallFunc()
        end)
    end

    self.m_respinWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 往右侧飞动画
function CodeGameScreenGeminiJourneyMachine:flyFalseBonusToRight(_curIndex)
    local curIndex = _curIndex + 1
    if curIndex > 25 then
        return
    end
    local symbolNodePos = self.m_symbolNodeRandom[curIndex]

    local tblActionList = {}
    local rightBonus = self.m_rightFalseBonusData[symbolNodePos-1]
    local fixPos = self:getRowAndColByPos(symbolNodePos-1)
    local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
    if symbolNode and self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
        self.m_respinCopyBonusSoundTbl[curIndex] = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Respin_BonusCopy)
        local curZorder = 1000
        local bonusNode = self:getTopFalseBonus(symbolNode, fixPos.iY, fixPos.iX, curZorder)

        bonusNode:runAnim("actionframe_fuzhi", false, function()
            bonusNode:setVisible(false)
        end)

        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.4)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:flyFalseBonusToRight(curIndex)
        end)
        -- 29/30-0.4
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.57)
        -- 衔接右侧落地动画
        if rightBonus then
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                if not tolua.isnull(rightBonus) then
                    self.m_respinCopyBonusSoundTbl[curIndex] = nil
                    rightBonus:setVisible(true)
                    rightBonus:runAnim("buling2", false, function()
                        if not tolua.isnull(rightBonus) then
                            rightBonus:runAnim("idleframe2", true)
                        end
                    end)
                end
            end)
        end
    else
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:flyFalseBonusToRight(curIndex)
        end)
    end
    self.m_respinWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 假的bonus
function CodeGameScreenGeminiJourneyMachine:addRespinFalseBonus()
    self.m_rightFalseBonusData = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            --左侧棋盘
            local symbolNode = self.m_respinView:getRespinEndNode(iRow,iCol)
            if symbolNode and self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
                local curZorder = iCol*10-iRow
                self:getTopFalseBonus(symbolNode, iCol, iRow, curZorder, true)
            end

            -- 右侧棋盘（先加上，控制显隐）
            local symbolNode = self.m_respinView2:getRespinEndNode(iRow,iCol)
            if symbolNode and self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
                local index = self:getPosReelIdx(iRow, iCol)
                local curZorder = iCol*10-iRow
                local bonusNode = self:getTopFalseBonus(symbolNode, iCol, iRow, curZorder, true)

                bonusNode:setVisible(false)
                self.m_rightFalseBonusData[index] = bonusNode
            end
        end
    end
end

-- 获取创建假的bonus
function CodeGameScreenGeminiJourneyMachine:getTopFalseBonus(symbolNode, iCol, iRow, curZorder, _isAddRespinFalse)
    local nodePos = util_convertToNodeSpace(symbolNode, self.m_respinEffectNode)
    local bonusNode = self:createGeminiJourneySymbol(self.SYMBOL_SCORE_BONUS_1)
    -- 进respin棋盘会向右偏移40个像素，所以要加上，避免设置主棋盘respin动画对不上的情况
    if _isAddRespinFalse then
        nodePos.x = nodePos.x + 40
    end
    bonusNode:setPosition(nodePos)
    bonusNode:runAnim("idleframe2", true)
    self.m_respinEffectNode:addChild(bonusNode, curZorder)

    -- bonus上加钱
    bonusNode.p_symbolType = symbolNode.p_symbolType
    bonusNode.p_cloumnIndex = iCol
    bonusNode.p_rowIndex = iRow
    bonusNode.m_isLastSymbol = true
    local bonusSpine = bonusNode:getNodeSpine()
    self:setSpecialNodeScoreBonus(bonusNode, 1, bonusSpine)

    return bonusNode
end

function CodeGameScreenGeminiJourneyMachine:createGeminiJourneySymbol(_symbolType)
    local symbol = util_createView("GeminiJourneySrc.GeminiJourneySymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

-- respin开始，bonus往右侧飞的时候，在点击的时候跳过移除
function CodeGameScreenGeminiJourneyMachine:setSkipData(func, _state)
    self.m_skipFunc = func
    self.m_skip_click:setVisible(_state)
    self.m_bottomUI:setSkipRespinBtnVisible(_state)
end

function CodeGameScreenGeminiJourneyMachine:runSkipCollect()
    self.m_skip_click:setVisible(false)
    if type(self.m_skipFunc) == "function" then
        self.m_respinEffectNode:removeAllChildren()
        self.m_respinWaitNode:stopAllActions()
        self.m_bottomUI:setSkipRespinBtnVisible(false)

        --显示respinBar
        self.m_respinView:setVisible(true)
        self.m_respinView2:setVisible(true)
        local respinViewTbl = {self.m_respinView, self.m_respinView2}

        local tblActionList = {}
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            for index, soundsId in pairs(self.m_respinCopyBonusSoundTbl) do
                if soundsId then
                    gLobalSoundManager:stopAudio(soundsId)
                    self.m_respinCopyBonusSoundTbl[index] = nil
                end
            end
            
            for i=1, 2 do
                respinViewTbl[i]:startShowClipNode()
                self:showBottomReelAni(i, "idle2")
            end
        end)
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.5)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:showRespinBar(true, true)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Respin_LockRow_Show)
            for i=1, 2 do
                respinViewTbl[i]:startShowClipNode(true)
                self:startRespinLockBar(i)
                self:showBottomLight(i, true, true)
            end
        end)
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.3)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_skipFunc()
            self:setSkipData(nil, false)
        end)
        
        self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
    end
end

---
-- 触发respin 玩法
--
function CodeGameScreenGeminiJourneyMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    self:clearCurMusicBg()
    self:levelDeviceVibrate(6, "respin")
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

    if self:getLastWinCoin() > 0 then -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝
        removeMaskAndLine()
        self:showRespinView(effectData)
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenGeminiJourneyMachine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()
    self:clearWinLineEffect()
    self.m_respinEffectNode:removeAllChildren()
    self.m_respinCollectNode:removeAllChildren()
    self.m_respinCopyBonusSoundTbl = {}
    self.m_resppinFirstPlaySound = true
    
    self.m_iReelRowNum = RESPIN_ROW_COUNT
    self:respinChangeReelGridCount(RESPIN_ROW_COUNT, true)
    self:setCurUnlockRow()
    self.m_leftReelIsStop = false
    self.m_leftIsShowGrand = false
    self.m_rightIsShowGrand = false
    self.m_respinGrandDelayTbl = {0, 0}

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )
    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()

    local tblActionList = {}
    -- base进respin
    if not self.m_respinIsCeconnection then
        local soundTime = 3.0
        if self.m_curPlayRespinSoundIndex > 2 then
            self.m_curPlayRespinSoundIndex = 1
        end
        if self.m_curPlayRespinSoundIndex == 1 then
            soundTime = 4.0
        end
        local curTriggerSound = self.m_publicConfig.SoundConfig.Music_Bonus_TriggerSound[self.m_curPlayRespinSoundIndex]
        self.m_curPlayRespinSoundIndex = self.m_curPlayRespinSoundIndex + 1
        
        tblActionList[#tblActionList+1] = cc.DelayTime:create(0.5)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            globalMachineController:playBgmAndResume(curTriggerSound, soundTime, 0, 1)
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, NORMAL_ROW_COUNT do
                    local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if slotNode and self:getCurSymbolIsBonus(slotNode.p_symbolType) then
                        slotNode:runAnim("actionframe", false, function()
                            slotNode:runAnim("idleframe1", true)
                        end)
                    end
                end
            end
        end)
        tblActionList[#tblActionList+1] = cc.DelayTime:create(60/30)
        --构造盘面数据
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:triggerReSpinCallFun(endTypes, randomTypes)  
        end)
    else
        --构造盘面数据
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:triggerReSpinCallFun(endTypes, randomTypes)  
        end)
    end

    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

--触发respin
function CodeGameScreenGeminiJourneyMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self.m_bottomUI:resetWinLabel()
    self.m_bottomUI:checkClearWinLabel()
    self:changeTouchSpinLayerSize(true)

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol, _reelIndex)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol, _reelIndex)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_respinBoardTbl[1]:getClipParentNode():addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self.m_respinView:setVisible(false)

    self.m_respinView2 = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView2:setMachine(self)
    self.m_respinView2:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol, _reelIndex)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol, _reelIndex)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_respinBoardTbl[2]:getClipParentNode():addChild(self.m_respinView2, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self.m_respinView2:setVisible(false)

    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenGeminiJourneyMachine:initRespinView(endTypes, randomTypes)
    --继承重写 改变盘面数据
    -- self:triggerChangeRespinNodeInfo(respinNodeInfo)

    -- 左侧轮盘
    --构造盘面数据
    local respinNodeInfo1 = self:reateRespinNodeInfo(1)
    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)
    self.m_respinView:initRespinElement(respinNodeInfo1, self.m_iReelRowNum, self.m_iReelColumnNum, function()
        self:reSpinEffectChange()
        self:playRespinViewShowSound()
        self:showReSpinStart(function()
            -- 更改respin 状态下的背景音乐
            -- self:changeReSpinBgMusic()
            self:runNextReSpinReel()
        end)
    end, 1)

    -- 右侧轮盘
    local respinNodeInfo2 = self:reateRespinNodeInfo(2)
    self.m_respinView2:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView2:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)
    self.m_respinView2:initRespinElement(respinNodeInfo2, self.m_iReelRowNum, self.m_iReelColumnNum, function()
        self:reSpinEffectChange()
        self:playRespinViewShowSound()
    end, 2)
end

--隐藏盘面信息
function CodeGameScreenGeminiJourneyMachine:setReelSlotsNodeVisible(status)
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
        if type(slotsNode.isSlotsNode) == "function" and slotsNode:isSlotsNode() then
            slotsNode:setVisible(status)
        end
    end
end

-- 设置respinBar
function CodeGameScreenGeminiJourneyMachine:showRespinBar(_isShow, _isStart)
    for i=1, 2 do
        self.m_baseReSpinBarTbl[i]:startShowAni(_isShow, _isStart)
    end
end

-- respin结束关闭respinBar
function CodeGameScreenGeminiJourneyMachine:closeBarAni()
    for i=1, 2 do
        self.m_baseReSpinBarTbl[i]:closeBarAni()
    end
end

-- 设置respin底条
function CodeGameScreenGeminiJourneyMachine:showBottomLight(_reelIndex, _isShow, _isStart)
    self.m_respinBoardTbl[_reelIndex]:showBottomLight(_isShow, _isStart)
end

-- 设置respin底
function CodeGameScreenGeminiJourneyMachine:showBottomReelAni(_reelIndex, _showType)
    self.m_respinBoardTbl[_reelIndex]:showBottomReelAni(_showType)
end

-- respinLock开始动画+底下的mask
function CodeGameScreenGeminiJourneyMachine:startRespinLockBar(_reelIndex)
    self.m_respinBoardTbl[_reelIndex]:startRespinLockBar()
end

-- respinLock idle动画
function CodeGameScreenGeminiJourneyMachine:showLockState(_reelIndex, _isShow)
    self.m_respinBoardTbl[_reelIndex]:showLockState(_isShow)
    self.m_respinBoardTbl[_reelIndex]:showBottomMaskIdleAni()
end

-- respinLock解锁动画
function CodeGameScreenGeminiJourneyMachine:startRespinUnLockBar(_reelIndex, _unlockRowIndex, _onEnter)
    self.m_respinBoardTbl[_reelIndex]:startRespinUnLockBar(_unlockRowIndex, _onEnter)
end

-- respinLock消失动画++底下遮罩消失
function CodeGameScreenGeminiJourneyMachine:closeLockAni(_reelIndex)
    self.m_respinBoardTbl[_reelIndex]:closeLockAni()
    self.m_respinBoardTbl[_reelIndex]:closeBottomMaskAni()
end

-- grand开始动画
function CodeGameScreenGeminiJourneyMachine:showGrandAni(_reelIndex, _isShow, _showType)
    if _showType == "start" then
        if self.m_curSpinPlaySound then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Grand_Show_Effect)
            self.m_curSpinPlaySound = false
        end
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Grand_Show)
    end
    self.m_respinBoardTbl[_reelIndex]:showGrandAni(_isShow, _showType)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenGeminiJourneyMachine:reateRespinNodeInfo(_reelIndex)
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol, _reelIndex)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getLocalRespinReelPos(iCol, _reelIndex) --self:getReelPos(iCol)
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

function CodeGameScreenGeminiJourneyMachine:getMatrixPosSymbolType(iRow, iCol, _reelIndex)
    if not _reelIndex then
        return
    end
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local rowCount = 5
    local reelData = {}
    if _reelIndex == 1 then
        rowCount = #rsExtraData.reels1.reelData
        reelData = rsExtraData.reels1.reelData
    else
        rowCount = #rsExtraData.reels2.reelData
        reelData = rsExtraData.reels2.reelData
    end
    for rowIndex = 1, rowCount do
        local rowDatas = reelData[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

function CodeGameScreenGeminiJourneyMachine:getRespinReelsButStored(storedInfo, _reelIndex)
    if not _reelIndex then
        return
    end
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
            local type = self:getMatrixPosSymbolType(iRow, iCol, _reelIndex)
            if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
            end
        end
    end
    return reelData
end

-- 转换本地respin轮盘位置
function CodeGameScreenGeminiJourneyMachine:getLocalRespinReelPos(col, _reelIndex)
    local reelNode = nil
    if _reelIndex then
        reelNode = self.m_respinBoardTbl[_reelIndex]:findChild("sp_reel_" .. (col - 1))
    end
    
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

--开始下次ReSpin
function CodeGameScreenGeminiJourneyMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end
    self.m_beginStartRunHandlerID = scheduler.performWithDelayGlobal(function()
        if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW or self.m_respinView2:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
            self:startReSpinRun()
        end
        self.m_beginStartRunHandlerID = nil
    end, self.m_RESPIN_RUN_TIME, self:getModuleName())
end

--开始滚动
function CodeGameScreenGeminiJourneyMachine:startReSpinRun(_reelIndex)
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN or self.m_respinView2:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)

    self:requestSpinReusltData()
    self.m_totalRespinNum = 0
    self.m_curRespinNum = 0
    self.m_curSpinPlaySound = true
    local respinCount1, respinCount2 = self:getCurRespinCount()
    local maxRespinCount = util_max(respinCount1, respinCount2)
    if maxRespinCount > 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
        self.m_runSpinResultData.p_reSpinCurCount = maxRespinCount

        -- 左边轮盘
        if respinCount1 - 1 >= 0 then
            self.m_totalRespinNum = self.m_totalRespinNum + 1
            self:changeReSpinUpdateUI(respinCount1 - 1, 1)
            self.m_respinView:startMove()
        end
        -- 右边轮盘
        if respinCount2 - 1 >= 0 then
            self.m_totalRespinNum = self.m_totalRespinNum + 1
            self:changeReSpinUpdateUI(respinCount2 - 1, 2)
            self.m_respinView2:startMove()
        end
    end
end

-- 获取当前respin次数
function CodeGameScreenGeminiJourneyMachine:getCurRespinCount()
    local respinCount1 = 0
    local respinCount2 = 0
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.reels1 and self.m_runSpinResultData.p_rsExtraData.reels2 then
        respinCount1 = self.m_runSpinResultData.p_rsExtraData.reels1.count or 0
        respinCount2 = self.m_runSpinResultData.p_rsExtraData.reels2.count or 0
    end
    return respinCount1, respinCount2
end

-- 获取当前respin是否停轮
function CodeGameScreenGeminiJourneyMachine:getCurRespinIsStop()
    local respinIsStop1 = false
    local respinIsStop2 = false
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.reels1 and self.m_runSpinResultData.p_rsExtraData.reels2 then
        respinIsStop1 = self.m_runSpinResultData.p_rsExtraData.reels1.spinOver or false
        respinIsStop2 = self.m_runSpinResultData.p_rsExtraData.reels2.spinOver or false
    end
    return respinIsStop1, respinIsStop2
end

-- 判断当前spin是否有grand
function CodeGameScreenGeminiJourneyMachine:getCurSpinIsHaveGrand()
    local isHaveGrand1 = false
    local isHaveGrand2 = false
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.reels1 and self.m_runSpinResultData.p_rsExtraData.reels2 then
        isHaveGrand1 = self.m_runSpinResultData.p_rsExtraData.reels1.spinGrand == 1 and true or false
        isHaveGrand2 = self.m_runSpinResultData.p_rsExtraData.reels2.spinGrand == 1 and true or false
    end
    return isHaveGrand1, isHaveGrand2
end

-- 判断当前spin是否有grand
function CodeGameScreenGeminiJourneyMachine:getEndIsHaveGrand()
    local isHaveGrand1 = false
    local isHaveGrand2 = false
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.reels1 and self.m_runSpinResultData.p_rsExtraData.reels2 then
        isHaveGrand1 = self.m_runSpinResultData.p_rsExtraData.reels1.grand == 1 and true or false
        isHaveGrand2 = self.m_runSpinResultData.p_rsExtraData.reels2.grand == 1 and true or false
    end
    return isHaveGrand1, isHaveGrand2
end

function CodeGameScreenGeminiJourneyMachine:respinChangeReelGridCount(count, isRespin)
    for i=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
        if isRespin then
            columnData.p_showGridH = 92
        else
            columnData.p_showGridH = 168
        end
    end
end

-- 设置当前解锁的行数
function CodeGameScreenGeminiJourneyMachine:setCurUnlockRow()
    local respinUnlockRow1 = 3
    local respinUnlockRow2 = 3
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.reels1 and self.m_runSpinResultData.p_rsExtraData.reels2 then
        respinUnlockRow1 = respinUnlockRow1 + self.m_runSpinResultData.p_rsExtraData.reels1.unlockRows or 0
        respinUnlockRow2 = respinUnlockRow2 + self.m_runSpinResultData.p_rsExtraData.reels2.unlockRows or 0
    end
    self.m_respinUnlockRowTbl[1] = respinUnlockRow1
    self.m_respinUnlockRowTbl[2] = respinUnlockRow2
end

-- 获取当前respin是否有升行（reel1）
function CodeGameScreenGeminiJourneyMachine:getCurRespinIsRiseRow_1()
    local respinIsRow = false
    local addBonusStoredIcons1 = {}
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.reels1 then
        local respinRiseRowData = self.m_runSpinResultData.p_rsExtraData.reels1.currentUnlockRows
        addBonusStoredIcons1 = self.m_runSpinResultData.p_rsExtraData.reels1.addBonus2StoredIcons
        if respinRiseRowData and next(respinRiseRowData) then
            respinIsRow = true
        end
    end
    return respinIsRow, addBonusStoredIcons1
end

-- 获取当前respin是否有升行（reel2）
function CodeGameScreenGeminiJourneyMachine:getCurRespinIsRiseRow_2()
    local respinIsRow = false
    local addBonusStoredIcons2 = {}
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.reels2 then
        local respinRiseRowData = self.m_runSpinResultData.p_rsExtraData.reels2.currentUnlockRows
        addBonusStoredIcons2 = self.m_runSpinResultData.p_rsExtraData.reels2.addBonus2StoredIcons
        if respinRiseRowData and next(respinRiseRowData) then
            respinIsRow = true
        end
    end
    return respinIsRow, addBonusStoredIcons2
end

-- 收集grand
function CodeGameScreenGeminiJourneyMachine:collectRespinGrand(_reelIndex, _endCallFunc)
    local reelIndex = _reelIndex
    local endCallFunc = _endCallFunc
    local isHaveGrand1, isHaveGrand2 = self:getEndIsHaveGrand()
    local grandTbl = {isHaveGrand1, isHaveGrand2}
    if reelIndex <= 2 then
        if grandTbl[reelIndex] then
            local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
            local jackpotName = "Grand"
            local jackpotCoins = allJackpotCoins[jackpotName] or 0
            
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Grand_Trigger)
            self:showGrandAni(reelIndex, true, "actionframe")
            self.m_jackPotBarView:playTriggerJackpotAni(1)
            -- 触发+over=120+30帧
            performWithDelay(self.m_scWaitNode, function()
                self:showJackpotView(jackpotCoins, jackpotName, function()
                    self.m_jackPotBarView:setIdleAni()
                    self:playhBottomLight(jackpotCoins)
                    self:collectRespinGrand(reelIndex+1, endCallFunc)
                end)
            end, 120/60)
        else
            self:collectRespinGrand(reelIndex+1, endCallFunc)
        end
    else
        performWithDelay(self.m_scWaitNode, function()
            self:playBonusTriggerAction(endCallFunc)
        end, 0.3)
    end
end

-- 收集bonus前；需要提层播触发
function CodeGameScreenGeminiJourneyMachine:playBonusTriggerAction(_endCallFunc)
    local endCallFunc = _endCallFunc
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_AllBonus_Trigger)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            --左侧棋盘
            local symbolNode = self.m_respinView:getRespinEndNode(iRow,iCol)
            if symbolNode and symbolNode.p_symbolType ~= self.SYMBOL_SCORE_NULL then
                local actName = "actionframe1"
                self.m_respinView:respinOverChangeNodeParent(1, symbolNode)
                if self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
                    symbolNode:runAnim(actName, false, function()
                        symbolNode:runAnim("idleframe3", true)
                    end)
                else
                    symbolNode:runAnim(actName)
                end
            end

            -- 右侧棋盘（先加上，控制显隐）
            local symbolNode = self.m_respinView2:getRespinEndNode(iRow,iCol)
            if symbolNode and symbolNode.p_symbolType ~= self.SYMBOL_SCORE_NULL then
                self.m_respinView2:respinOverChangeNodeParent(2, symbolNode)
                local actName = "actionframe1"
                if self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
                    symbolNode:runAnim(actName, false, function()
                        symbolNode:runAnim("idleframe3", true)
                    end)
                else
                    symbolNode:runAnim(actName)
                end
            end
        end
    end
    -- 隐藏锁定栏
    -- 隐藏reel底
    for i=1, 2 do
        self:closeLockAni(i)
        self:showBottomReelAni(i, "idle2")
    end
    -- 隐藏respinBar
    self:closeBarAni()
    -- 隐藏裁剪层
    self.m_respinView:closeShowClipNode()
    self.m_respinView2:closeShowClipNode()

    performWithDelay(self.m_scWaitNode, function()
        self:collectRespinBonus(1, 0, endCallFunc)
    end, 35/30+0.4)
end

-- 收集bonus
function CodeGameScreenGeminiJourneyMachine:collectRespinBonus(_reelIndex, _curIndex, _endCallFunc)
    local reelIndex = _reelIndex
    local curIndex = _curIndex + 1
    local endCallFunc = _endCallFunc
    local bonusReward = nil
    local curRespinView = nil
    if reelIndex == 1 then
        bonusReward = self.m_runSpinResultData.p_rsExtraData.reels1.bonusReward
        curRespinView = self.m_respinView
    else
        bonusReward = self.m_runSpinResultData.p_rsExtraData.reels2.bonusReward
        curRespinView = self.m_respinView2
    end
    if not bonusReward or not curRespinView then
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
        return
    end

    -- 根据索引收集bonus
    if curIndex > 25 then
        if reelIndex == 1 then
            self:collectRespinBonus(2, 0, endCallFunc)
        else
            performWithDelay(self.m_scWaitNode, function()
                if type(endCallFunc) == "function" then
                    endCallFunc()
                end
            end, 1.2)
        end
        return
    end
    local symbolNodePos = self.m_symbolNodeRandom[curIndex]
    local fixPos = self:getRowAndColByPos(symbolNodePos-1)
    local symbolNode = curRespinView:getRespinEndNode(fixPos.iX, fixPos.iY)
    local curBonusData = self:getCurPosBonus(symbolNodePos-1, bonusReward)
    if symbolNode and (self:getCurSymbolIsBonus(symbolNode.p_symbolType) or symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2) and curBonusData then
        local rewardCoins = curBonusData[2]

        local actName = "jiesuan1"
        if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_1 then
            actName = "jiesuan1"
        elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
            actName = "jiesuan"
        end
        if self:getCurSymbolIsBonusJackpot(symbolNode.p_symbolType) then
            local jackpotName = "Mini"
            local jackpotIndex = 5
            if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_MINI then
                jackpotName = "Mini"
                jackpotIndex = 5
            elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_MINOR then
                jackpotName = "Minor"
                jackpotIndex = 4
            elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_MAJOR then
                jackpotName = "Major"
                jackpotIndex = 3
            elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_MEGA then
                jackpotName = "Mega"
                jackpotIndex = 2
            end
            local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
            local jackpotCoins = allJackpotCoins[jackpotName] or 0
            -- jackpot触发
            self.m_jackPotBarView:playTriggerJackpotAni(jackpotIndex)

            -- bonus上字体结算
            self:playBonusNodeScoreAni(symbolNode, "jiesuan2")

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_showJackpot_Aha)
            symbolNode:runAnim("jiesuan2", false, function()
                self:showJackpotView(jackpotCoins, jackpotName, function()
                    self.m_jackPotBarView:setIdleAni()
                    self:playhBottomLight(jackpotCoins, true)
                    performWithDelay(self.m_scWaitNode, function()
                        self:collectRespinBonus(reelIndex, curIndex, endCallFunc)
                    end, 0.3)
                end)
            end)
        else
            local lightSpine = util_spineCreate("GeminiJourney_respin_tuowei",true,true)
            --转化坐标位置    
            local startPos = util_convertToNodeSpace(symbolNode, self.m_respinCollectNode)
            local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self.m_respinCollectNode)
            lightSpine:setPosition(startPos)
            self.m_respinCollectNode:addChild(lightSpine)

            local angle = util_getAngleByPos(startPos,endPos)
            lightSpine:setRotation( - angle)
            
            local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 ))
            local lightLen = 675
            local actSpineName = "actionframe"
            if fixPos.iX <= 2 then
                lightLen = 480
                actSpineName = "actionframe3"
            end
            lightSpine:setScaleX(scaleSize / lightLen)
            if reelIndex == 2 then
                lightSpine:setScaleY(-1)
            end
            util_spinePlay(lightSpine, actSpineName, false)
            util_spineEndCallFunc(lightSpine, actSpineName, function()
                lightSpine:setVisible(false)
            end)

            -- bonus上字体结算
            self:playBonusNodeScoreAni(symbolNode, "jiesuan1")
            symbolNode:runAnim(actName, false)
            performWithDelay(self.m_scWaitNode, function()
                self:playhBottomLight(rewardCoins, true)
                self:collectRespinBonus(reelIndex, curIndex, endCallFunc)
            end, 0.4)
        end
    else
        self:collectRespinBonus(reelIndex, curIndex, endCallFunc)
    end
end

-- 结算时bonus上字体结算动画
function CodeGameScreenGeminiJourneyMachine:playBonusNodeScoreAni(_symbolNode, _actName)
    local symbolNode = _symbolNode
    local actName = _actName
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if not tolua.isnull(spineNode.m_bonusNodeScore) then
        local bonusNodeScore = spineNode.m_bonusNodeScore
        bonusNodeScore:runCsbAction(actName, false)
    end
end

-- 获取当前位置的bonus
function CodeGameScreenGeminiJourneyMachine:getCurPosBonus(_curPos, _bonusReward)
    local curPos = _curPos
    local bonusReward = _bonusReward
    local curBonusData = nil
    for k ,v in pairs(bonusReward) do
        if curPos == v[1] then
            curBonusData = v
            break
        end
    end
    return curBonusData
end

---判断结算
function CodeGameScreenGeminiJourneyMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    self.m_curRespinNum = self.m_curRespinNum + 1

    if self.m_curRespinNum == self.m_totalRespinNum then
        self.m_totalRespinNum = 0
        self.m_curRespinNum = 0

        -- 设置当前解锁的行数
        self:setCurUnlockRow()
        self:setGameSpinStage(STOP_RUN)

        -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        self:updateQuestUI()

        local respinCount1, respinCount2 = self:getCurRespinCount()
        local isHaveGrand1, isHaveGrand2 = self:getCurSpinIsHaveGrand()
        if respinCount1 == 0 and respinCount2 == 0 then
            -- 当前次spin是否有升行；有升行先处理升行
            local respinIsRow1, addBonusStoredIcons1 = self:getCurRespinIsRiseRow_1()
            local respinIsRow2, addBonusStoredIcons2 = self:getCurRespinIsRiseRow_2()

            local tblActionList = {}
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
                self.m_respinView2:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        
                --quest
                self:updateQuestBonusRespinEffectData()
            end)
            self.m_respinEffectNode:removeAllChildren()
            -- reel1解锁
            if respinIsRow1 then
                self:addRespinRiseRowAction(tblActionList, addBonusStoredIcons1, 1)
            end
            -- reel2解锁
            if respinIsRow2 then
                self:addRespinRiseRowAction(tblActionList, addBonusStoredIcons2, 2)
            end
            -- 添加reel1-grand
            if isHaveGrand1 and not self.m_leftIsShowGrand then
                self.m_leftIsShowGrand = true
                local delayTime = self.m_respinGrandDelayTbl[1]
                tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self:showGrandAni(1, true, "start")
                end)
                -- 触发35帧
                tblActionList[#tblActionList+1] = cc.DelayTime:create(35/60)
            end
            -- 添加reel2-grand
            if isHaveGrand2 and not self.m_rightIsShowGrand then
                self.m_rightIsShowGrand = true
                local delayTime = self.m_respinGrandDelayTbl[2]
                tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self:showGrandAni(2, true, "start")
                end)
                -- 触发35帧
                tblActionList[#tblActionList+1] = cc.DelayTime:create(35/60)
            end

            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:setRepinOverUiComplete()
            end)
            -- 延时30帧
            tblActionList[#tblActionList+1] = cc.DelayTime:create(30/60)
            
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:collectRespinGrand(1, function()
                    --结束
                    self:reSpinEndAction()
            
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
            
                    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
                    self.m_isWaitingNetworkData = false
                end)
            end)
            
            self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
        else
            local respinIsStop1, respinIsStop2 = self:getCurRespinIsStop()
            local endCallFunc = function()
                self:runNextReSpinReel()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end

            -- 当前次spin是否有升行；有升行先处理升行
            local respinIsRow1, addBonusStoredIcons1 = self:getCurRespinIsRiseRow_1()
            local respinIsRow2, addBonusStoredIcons2 = self:getCurRespinIsRiseRow_2()
            if respinCount1 > 0 then
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            else
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
            end
            if respinCount2 > 0 then
                self.m_respinView2:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            else
                self.m_respinView2:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
            end
    
            local tblActionList = {}
            if respinIsRow1 or respinIsRow2 then
                -- 设置respinbar和次数
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self:setRepinOverUiComplete()
                end)

                tblActionList[#tblActionList+1] = cc.DelayTime:create(0.3)
                
                self.m_respinEffectNode:removeAllChildren()
                -- reel1解锁
                if respinIsRow1 then
                    self:addRespinRiseRowAction(tblActionList, addBonusStoredIcons1, 1)
                end
                -- reel2解锁
                if respinIsRow2 then
                    self:addRespinRiseRowAction(tblActionList, addBonusStoredIcons2, 2)
                end

                -- 添加reel1-grand
                if isHaveGrand1 and not self.m_leftIsShowGrand then
                    self.m_leftIsShowGrand = true
                    local delayTime = self.m_respinGrandDelayTbl[1]
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        self:showGrandAni(1, true, "start")
                    end)
                    -- 触发35帧
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(35/60)
                end
                -- 添加reel2-grand
                if isHaveGrand2 and not self.m_rightIsShowGrand then
                    self.m_rightIsShowGrand = true
                    local delayTime = self.m_respinGrandDelayTbl[2]
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        self:showGrandAni(2, true, "start")
                    end)
                    -- 触发35帧
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(35/60)
                end

                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    endCallFunc()
                end)
            else
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    self:setRepinOverUiComplete()
                    endCallFunc()
                end)
            end

            self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
        end
    else
        -- 第一个轮停止后直接刷新次数
        self:setRepinOverUiComplete(1)
    end
end

-- 添加动作事件
function CodeGameScreenGeminiJourneyMachine:addRespinRiseRowAction(tblActionList, addBonusStoredIcons, reelIndex)
    -- 播升行触发
    for k, v in pairs(addBonusStoredIcons) do
        local bonusPos = v[1]
        local bonusCoins = v[2]
        local serverUnlockRow = v[3]
        -- 转换成本地（服务器给的是从上往下数1、2；转换成2、1）
        local unlockRow = 2 - serverUnlockRow + 1
        -- 本地行数
        local curUnlockRow = unlockRow + 3
        local fixPos = self:getRowAndColByPos(bonusPos)
        local intervalRow = curUnlockRow - fixPos.iX
        local riseName = "actionframe"
        if intervalRow == 2 then
            riseName = "actionframe2"
        elseif intervalRow == 3 then
            riseName = "actionframe3"
        elseif intervalRow == 4 then
            riseName = "actionframe4"
        end
        local curRespinView = nil
        if reelIndex == 1 then
            curRespinView = self.m_respinView
        else
            curRespinView = self.m_respinView2
        end
        local symbolNode = curRespinView:getRespinEndNode(fixPos.iX, fixPos.iY)
        -- 95播触发
        if symbolNode and symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS_2 then
            local nodePos = util_convertToNodeSpace(symbolNode, self.m_respinEffectNode)
            local bonusNode = self:createGeminiJourneySymbol(self.SYMBOL_SCORE_BONUS_2)
            bonusNode:setPosition(nodePos)
            bonusNode:runAnim("idleframe", true)
            bonusNode:setVisible(false)
            self.m_respinEffectNode:addChild(bonusNode)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                bonusNode:setVisible(true)
                symbolNode:runAnim("idleframe4", true)
                symbolNode:setVisible(false)
                -- bonus上加钱
                bonusNode.p_cloumnIndex = symbolNode.p_cloumnIndex
                bonusNode.p_rowIndex = symbolNode.p_rowIndex
                bonusNode.m_isLastSymbol = true
                local bonusSpine = bonusNode:getNodeSpine()
                self:setSpecialNodeScoreBonus(bonusNode, reelIndex, bonusSpine, true)
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_RespinBonus2_Unlock)
                if self.m_resppinFirstPlaySound then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Respin_First_Unlock_Row)
                    self.m_resppinFirstPlaySound = false
                end
                bonusNode:runAnim(riseName, false, function()
                    bonusNode:setVisible(false)
                    symbolNode:setVisible(true)
                    self:setSpecialNodeScoreBonus(symbolNode, reelIndex, nil, true)
                    symbolNode:runAnim("idleframe4", true)
                end)
            end)
        end
        -- 触发40帧（21帧开锁）
        tblActionList[#tblActionList+1] = cc.DelayTime:create(21/30)
        -- 解锁升行
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_RespinBonus2_ShowScore)
            self:startRespinUnLockBar(reelIndex, unlockRow)
        end)
        -- 解锁的那行bonus播idleframe3
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            for iCol = 1, self.m_iReelColumnNum do
                local symbolNode = curRespinView:getRespinEndNode(curUnlockRow, iCol)
                if symbolNode and self:getCurSymbolIsBonus(symbolNode.p_symbolType) then
                    symbolNode:runAnim("idleframe4", true)
                end
            end
        end)
        -- 解锁升行55帧
        tblActionList[#tblActionList+1] = cc.DelayTime:create(55/60)
    end
end

-- 设置respin结束相关挂件
function CodeGameScreenGeminiJourneyMachine:setRepinOverUiComplete(_isLeftReel)
    local respinIsStop1, respinIsStop2 = self:getCurRespinIsStop()
    local respinCount1, respinCount2 = self:getCurRespinCount()
    local isHaveGrand1, isHaveGrand2 = self:getCurSpinIsHaveGrand()

    if _isLeftReel then
        if respinCount1 > 0 then
            self:changeReSpinUpdateUI(respinCount1, 1)
            if respinCount2 == 0 then
                self.m_respinView2:lastRespinScaleAction()
            end
        else
            if respinIsStop1 and not self.m_leftReelIsStop then
                if isHaveGrand1 and not self.m_leftIsShowGrand then
                    self.m_leftIsShowGrand = true
                    local delayTime = self.m_respinGrandDelayTbl[1]
                    performWithDelay(self.m_scWaitNode, function()
                        self:showGrandAni(1, true, "start")
                    end, delayTime)
                end
                self.m_leftReelIsStop = true
                self:changeReSpinUIState(1)
                self.m_respinView:clearLightAniByType(nil, isHaveGrand1)
                if respinCount2 == 0 then
                    self.m_respinView2:lastRespinScaleAction()
                end
            end
        end
    else
        if respinCount1 > 0 then
            if isHaveGrand2 and not self.m_rightIsShowGrand then
                self.m_rightIsShowGrand = true
                local delayTime = self.m_respinGrandDelayTbl[2]
                performWithDelay(self.m_scWaitNode, function()
                    self:showGrandAni(2, true, "start")
                end, delayTime)
            end
            self:changeReSpinUpdateUI(respinCount1, 1)
        else
            if respinIsStop1 and not self.m_leftReelIsStop then
                self.m_leftReelIsStop = true
                self:changeReSpinUIState(1)
                self.m_respinView:clearLightAniByType(nil, isHaveGrand1)
            end
        end
    
        if respinCount2 > 0 then
            self:changeReSpinUpdateUI(respinCount2, 2)
        else
            if respinIsStop2 then
                self:changeReSpinUIState(2)
                self.m_respinView2:clearLightAniByType(nil, isHaveGrand2)
            end
        end
    end
end

function CodeGameScreenGeminiJourneyMachine:getCurStateIsRespin()
    --用respin次数判断当前是否是respin状态
    if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return true
    end
    return false
end

--ReSpin开始改变UI状态
function CodeGameScreenGeminiJourneyMachine:changeReSpinStartUI(respinCount, _reelIndex, _isStart)
    self.m_baseReSpinBarTbl[_reelIndex]:updateLeftCount(respinCount, self.m_runSpinResultData.p_reSpinsTotalCount, _isStart)
end

--ReSpin刷新数量
function CodeGameScreenGeminiJourneyMachine:changeReSpinUpdateUI(curCount, _reelIndex)
    self.m_baseReSpinBarTbl[_reelIndex]:updateLeftCount(curCount, self.m_runSpinResultData.p_reSpinsTotalCount)
end

-- respin停止（完成）动画
function CodeGameScreenGeminiJourneyMachine:changeReSpinUIState(_reelIndex, _onEnter)
    self.m_baseReSpinBarTbl[_reelIndex]:completeAni(_onEnter)
    self.m_respinBoardTbl[_reelIndex]:closeBottomReelAndLight(_onEnter)
end

--ReSpin结算改变UI状态
function CodeGameScreenGeminiJourneyMachine:changeReSpinOverUI()
        
end

function CodeGameScreenGeminiJourneyMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:showRespinOverView()
end

--结束移除小块调用结算特效
function CodeGameScreenGeminiJourneyMachine:removeRespinNode()
    if self.m_respinView == nil and self.m_respinView2 then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    self.m_respinView:removeFromParent()
    self.m_respinView2:removeFromParent()
    self.m_respinView = nil
    self.m_respinView = nil
end

function CodeGameScreenGeminiJourneyMachine:triggerReSpinOverCallFun(score)
    self:changeTouchSpinLayerSize()

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
        local params = {self:getLastWinCoin(), false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    else
        coins = self.m_serverWinCoins or 0
        local params = {self.m_serverWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

function CodeGameScreenGeminiJourneyMachine:showRespinOverView(effectData)
    globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Respin_OverStart, 2, 0, 1)
    local strCoins=util_formatCoins(self.m_serverWinCoins, 50)
    local lightAni = util_createAnimation("GeminiJourney_tb_guang2.csb")
    lightAni:runCsbAction("idleframe", true)

    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Respin_OverOver)
        end, 5/60)
    end

    local view=self:showReSpinOver(strCoins,function()
        self:showRespinOverCutPlaySceneAni(function()
            self:setCurPlayState()
            if self.m_bProduceSlots_InFreeSpin and globalData.slotRunData.freeSpinCount ~= globalData.slotRunData.totalFreeSpinCount then
                self.m_baseFreeSpinBar:setVisible(true)
                self:changeBgSpine(2)
                self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_FG_Bg)
            else
                self:changeBgSpine(1)
                self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_Base_Bg)
            end
            self.collectBonus = false
            self:removeRespinNode()
            self.m_lightScore = 0
            self.m_collectBarView:recoverBonusPlay()
            self:respinChangeReelGridCount(NORMAL_ROW_COUNT)
            self.m_iReelRowNum = NORMAL_ROW_COUNT
            self:setReelSlotsNodeVisible(true)
            self:setCurBetBonusCount(0)
            self:updateRightBonus(true)
            self:refreshCollectBar(true)
            self.m_respinEffectNode:removeAllChildren()
            self.m_respinCollectNode:removeAllChildren()
        end, function()
            self:triggerReSpinOverCallFun(self.m_lightScore)
            -- self.m_bottomUI:checkClearWinLabel()
            self:resetMusicBg()
        end)
    end)
    view:setBtnClickFunc(cutSceneFunc)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.0,sy=1.0},662)  
    view:findChild("guang"):addChild(lightAni)
    view:findChild("root"):setScale(self.m_machineRootScale)  
    util_setCascadeOpacityEnabledRescursion(view, true)
end

--接收到数据开始停止滚动
function CodeGameScreenGeminiJourneyMachine:stopRespinRun()
    local storedNodeInfo1 = self:getRespinSpinData(1)
    local unStoredReels1 = self:getRespinReelsButStored(storedNodeInfo1, 1)
    self.m_respinView:setRunEndInfo(storedNodeInfo1, unStoredReels1)

    local storedNodeInfo2 = self:getRespinSpinData(2)
    local unStoredReels2 = self:getRespinReelsButStored(storedNodeInfo2, 2)
    self.m_respinView2:setRunEndInfo(storedNodeInfo2, unStoredReels2)
end

-- --重写组织respinData信息
function CodeGameScreenGeminiJourneyMachine:getRespinSpinData(_reelIndex)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if not rsExtraData then
        return
    end

    local storedIcons = {}
    local storedInfo = {}

    if _reelIndex and _reelIndex == 1 then
        local reelData1 = rsExtraData.reels1 or {}
        storedIcons = reelData1.storedIcons or {}
    else
        local reelData2 = rsExtraData.reels2 or {}
        storedIcons = reelData2.storedIcons or {}
    end

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY, _reelIndex)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo    
end

function CodeGameScreenGeminiJourneyMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("GeminiJourneySrc.GeminiJourneyJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_Jackpots"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
    显示jackpotWin
]]
function CodeGameScreenGeminiJourneyMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("GeminiJourneySrc.GeminiJourneyJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenGeminiJourneyMachine:symbolBulingEndCallBack(_slotNode)
    local curLongRunData = self.m_longRunControl:getCurLongRunData() or {}
    local LegitimatePos = curLongRunData.LegitimatePos or {}
    if table_length(LegitimatePos) > 0  then
        for i=1,#LegitimatePos do
            local posInfo = LegitimatePos[i]
            if table_vIn(posInfo,_slotNode.p_symbolType) and
                table_vIn(posInfo,_slotNode.p_cloumnIndex) and 
                table_vIn(posInfo,_slotNode.p_rowIndex)  then
                -- self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 
                -- return true
            end
        end
    end
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)   
end

function CodeGameScreenGeminiJourneyMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}})
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {94}})
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {200},["musRunInfos"] = {["startCol"] = 1,["endCol"]=3}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态
end

--[[
    播放预告中奖概率
    GD.SLOTO_FEATURE = {
        FEATURE_FREESPIN = 1,
        FEATURE_FREESPIN_FS = 2, -- freespin 中再次触发fs
        FEATURE_RESPIN = 3, -- 触发respin 玩法
        FEATURE_MINI_GAME_COLLECT = 4, -- 收集玩法小游戏
        FEATURE_MINI_GAME_OTHER = 5, -- 其它小游戏
        FEATURE_JACKPOT = 6 -- 触发 jackpot
    }
]]
function CodeGameScreenGeminiJourneyMachine:getFeatureGameTipChance(_probability)
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if self:getCurFeatureIsFree() then
        -- 出现预告动画概率默认为30%
        local probability = 30
        if _probability then
            probability = _probability
        end
        local isNotice = (math.random(1, 100) <= probability) 
        return isNotice
    end
    
    return false
end

-- 当前是否是free
function CodeGameScreenGeminiJourneyMachine:getCurFeatureIsFree()
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        return true
    end

    return false
end

-- 当前是否是free
function CodeGameScreenGeminiJourneyMachine:getCurFeatureIsRespin()
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_RESPIN then
        return true
    end

    return false
end

--[[
    播放预告中奖统一接口
]]
function CodeGameScreenGeminiJourneyMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance(50) then
        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
    else
        if type(_func) == "function" then
            _func()
        end
    end    
end

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenGeminiJourneyMachine:playFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_Sound)
    self.m_yuGaoSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe_yugao", function()
        self.m_yuGaoSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end) 
end

-- 设置当前玩法状态
function CodeGameScreenGeminiJourneyMachine:setCurPlayState(_isRespin)
    if _isRespin then
        self:runCsbAction("respin", true)
    else
        self:runCsbAction("base", true)
    end
end

function CodeGameScreenGeminiJourneyMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin；3.respin
    local bgSpineName = {"idle1", "idle2", "idle3"}
    util_spinePlay(self.m_bgSpine,bgSpineName[_bgType],true)

    if _bgType < 3 then
        self:setReelBgState(_bgType)
    end
end

function CodeGameScreenGeminiJourneyMachine:setReelBgState(_bgType)
    for i=1, 2 do
        if i == _bgType then
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_reelBg[i]:setVisible(false)
        end
    end
end

--[[
    刷新收集进度
]]
function CodeGameScreenGeminiJourneyMachine:refreshCollectBar(_onEnter, _freeMode)
    local onEnter = _onEnter
    local freeMode = _freeMode
    self.m_collectBarView:setHighBetLevelCoins(self.m_highBetLevelCoins)
    self.m_collectBarView:showCollectBonus(self.m_iBetLevel, onEnter, freeMode)
end

function CodeGameScreenGeminiJourneyMachine:playhBottomLight(_endCoins, _isPlayEffect)
    if _isPlayEffect then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_RespinCollect_BonusFeed)
        self.m_bottomUI:playCoinWinEffectUI()
    end

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenGeminiJourneyMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenGeminiJourneyMachine:getCurBottomWinCoins()
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

function CodeGameScreenGeminiJourneyMachine:tipsBtnIsCanClick()
    local isFreespin = self.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_isRunningEffect == true
    local isAutoSpin = self:getCurrSpinMode() == AUTO_SPIN_MODE
    local features = self.m_runSpinResultData.p_features or {}
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin then
        return false
    end

    return true
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenGeminiJourneyMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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

            -- bonus1的话加右侧收集
            if _slotNode.p_rowIndex <= self.m_iReelRowNum then
                if self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
                    self.m_collectBarView:collectBonusNode(true, 0, false, _slotNode)
                end
            end
            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                _slotNode:runAnim(symbolCfg[2], false, function()
                    self:symbolBulingEndCallBack(_slotNode)
                end)
            end
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenGeminiJourneyMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) then
                    return true
                end
            elseif self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
                if self:isBonusPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

-- scatter落地条件
function CodeGameScreenGeminiJourneyMachine:isPlayTipAnima(colIndex, rowIndex, node)
    local reels = self.m_runSpinResultData.p_reels
    local scatterCount = 0
    for iCol = 1,colIndex - 1 do
        for iRow = 1,self.m_iReelRowNum do
            if reels[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                scatterCount  = scatterCount + 1
            end
        end
    end

    if colIndex < 4 then
        return true
    elseif colIndex == 4 and scatterCount >= 1 then
        return true
    elseif colIndex == 5 and scatterCount >= 2 then
        return true
    end

    return false
end

-- bonus落地条件
function CodeGameScreenGeminiJourneyMachine:isBonusPlayTipAnima(colIndex, rowIndex, node)
    local reels = self.m_runSpinResultData.p_reels
    local bonusCount = 0
    for iCol = 1,colIndex do
        for iRow = 1,self.m_iReelRowNum do
            if self:getCurSymbolIsBonus(reels[iRow][iCol]) then
                bonusCount  = bonusCount + 1
            end
        end
    end

    local bonusColCount4 = 1
    local bonusColCount5 = 2
    if self.m_iBetLevel then
        if self.m_iBetLevel == 1 then
            bonusColCount4 = 2
            bonusColCount5 = 5
        else
            bonusColCount4 = 3
            bonusColCount5 = 6
        end
    end

    if colIndex < 4 then
        return true
    elseif colIndex == 4 and bonusCount >= bonusColCount4 then
        return true
    elseif colIndex == 5 and bonusCount >= bonusColCount5 then
        return true
    end

    return false
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenGeminiJourneyMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    local scatterSoundTbl = self.m_publicConfig.SoundConfig.Music_Scatter_Buling

    local isQuickHaveScatter = false
    -- 检查下前三列是否有scatter（前三列有scatter必然播落地）
    if self:getGameSpinStage() == QUICK_RUN then
        local reels = self.m_runSpinResultData.p_reels
        local curBonusCount = 0
        for iCol = 1, 3 do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = reels[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isQuickHaveScatter = true
                    break
                end
            end
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
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self.m_curScatterBulingCount = self.m_curScatterBulingCount + 1
                        if self.m_curScatterBulingCount > 3 then
                            self.m_curScatterBulingCount = 3
                        end
                        soundPath = scatterSoundTbl[self.m_curScatterBulingCount]
                        if self:getGameSpinStage() == QUICK_RUN then
                            if self:getCurFeatureIsFree() then
                                soundPath = scatterSoundTbl[3]
                            else
                                soundPath = scatterSoundTbl[1]
                            end
                        end
                    end

                    -- 快停时；有scatter 不播bonus
                    if self:getCurSymbolIsBonus(symbolType) then
                        if not isQuickHaveScatter then
                            self:playBulingSymbolSounds(iCol, soundPath, nil)
                        end
                    else
                        self:playBulingSymbolSounds(iCol, soundPath, nil)
                    end
                end
            end
        end
    end
end

function CodeGameScreenGeminiJourneyMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()
    local featureFree = self:getCurFeatureIsFree()
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5)
    elseif featureFree then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 1.5)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true
end

-- respin落地音效特殊判断
function CodeGameScreenGeminiJourneyMachine:setRespinBulingState(_state)
    self.m_respinBulingSoundState = _state
end

function CodeGameScreenGeminiJourneyMachine:getRespinBulingState()
    return self.m_respinBulingSoundState
end

-- respin最后一个音效特殊判断
function CodeGameScreenGeminiJourneyMachine:setRespinLastSymbolState(_state)
    self.m_respinLastSymbolSoundState = _state
end

function CodeGameScreenGeminiJourneyMachine:getRespinLastSymbolState()
    return self.m_respinLastSymbolSoundState
end

return CodeGameScreenGeminiJourneyMachine






