---
-- island li
-- 2019年1月26日
-- CodeGameScreenBadgedCowboyMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "BadgedCowboyPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenBadgedCowboyMachine = class("CodeGameScreenBadgedCowboyMachine", BaseNewReelMachine)

CodeGameScreenBadgedCowboyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBadgedCowboyMachine.SYMBOL_SCORE_NULL = -1
CodeGameScreenBadgedCowboyMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenBadgedCowboyMachine.SYMBOL_SCORE_SPECIAL_SCATTER = 91
CodeGameScreenBadgedCowboyMachine.SYMBOL_SCORE_SPECIAL_WILD = 93
CodeGameScreenBadgedCowboyMachine.SYMBOL_SCORE_JACKPOT = 94
CodeGameScreenBadgedCowboyMachine.SYMBOL_SCORE_BONUS = 95
CodeGameScreenBadgedCowboyMachine.SYMBOL_SCORE_SPECIAL_BONUS = 96

CodeGameScreenBadgedCowboyMachine.EFFECT_JACKPOT_PLAY = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenBadgedCowboyMachine.EFFECT_ADD_WILD = GameEffect.EFFECT_SELF_EFFECT - 2     --固定wild
CodeGameScreenBadgedCowboyMachine.EFFECT_ADD_BONUS = GameEffect.EFFECT_SELF_EFFECT - 3     --固定bonus

-- 构造函数
function CodeGameScreenBadgedCowboyMachine:ctor()
    CodeGameScreenBadgedCowboyMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_configData = gLobalResManager:getCSVLevelConfigData("BadgedCowboyConfig.csv", "LevelBadgedCowboyConfig.lua")

    self.m_lightScore = 0

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    --存储free开始时，scatter次数文件
    self.m_freeTimesText = {}

    --存储respin开始时，scatter钱数文件
    self.m_respinCoinsText = {}

    --存储respin二倍光效文件
    self.m_respinDoubleNode = {}

    --respin开始时创建的假的scatter
    self.m_respinFalseScatterTbl = {}

    --jackpot相关
    --先按照mini-minor-major-grand处理，怕后续改变单个
    --直接整成多维数组
    self.m_jackpotNodeEffect = {{}, {}, {}, {}}
    self.m_jackpotNodeDark = {}
    self.m_jackpotNodeText = {}

    self.m_triggerBigWinEffect = false

    self.m_jackpotCsbName = {
        "BadgedCowboy_jackpot_kuang_grand.csb",
        "BadgedCowboy_jackpot_kuang_major.csb",
        "BadgedCowboy_jackpot_kuang_minor.csb",
        "BadgedCowboy_jackpot_kuang_mini.csb",
    }
 
    self.m_symbolNodeRandom = {
        1, 7, 13, 19,
        2, 8, 14, 20,
        3, 9, 15, 21,
        4, 10, 16, 22,
        5, 11, 17, 23,
        6, 12, 18, 24,
    }

    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

    --init
    self:initGame()
end

function CodeGameScreenBadgedCowboyMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBadgedCowboyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BadgedCowboy"  
end

function CodeGameScreenBadgedCowboyMachine:getRespinNode()
    return "CodeBadgedCowboySrc.BadgedCowboyRespinNode"
end

function CodeGameScreenBadgedCowboyMachine:getRespinView()
    return "CodeBadgedCowboySrc.BadgedCowboyRespinView"
end

function CodeGameScreenBadgedCowboyMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_baseBgSpine = util_spineCreate("GameScreenBadgedCowboyBg",true,true)
    self.m_gameBg:findChild("base_bg"):addChild(self.m_baseBgSpine)
    
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_BadgedCowboyView = util_createView("CodeBadgedCowboySrc.BadgedCowboyView")
    -- self:findChild("xxxx"):addChild(self.m_BadgedCowboyView)
   
    self.m_chooseView = util_createView("CodeBadgedCowboySrc.BadgedCowboyChoosePlayView")
    self:addChild(self.m_chooseView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_chooseView:initMachine(self)
    self.m_chooseView:setVisible(false)

    self.m_jackPotBar = util_createView("CodeBadgedCowboySrc.BadgedCowboyJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self.m_baseFreeSpinBar = util_createView("CodeBadgedCowboySrc.BadgedCowboyFreespinBarView", self)
    self:findChild("Node_bar"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)

    self.m_jackpotLight = util_createAnimation("BadgedCowboy_jackpot_tx.csb")
    self:findChild("Node_yugao"):addChild(self.m_jackpotLight)
    self.m_jackpotLight:setVisible(false)

    self.m_yuGao = util_createAnimation("BadgedCowboy_free_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_yuGao)
    self.m_yuGao:setVisible(false)

    self.m_cutSceneSpine = util_spineCreate("BadgedCowboy_guochang",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneSpine)
    self.m_cutSceneSpine:setVisible(false)

    self.m_lineNode = self:findChild("Node_lineNum")

    self.m_baseReSpinBar = util_createView("CodeBadgedCowboySrc.BadgedCowboyRespinBarView")
    self:findChild("Node_respin"):addChild(self.m_baseReSpinBar)
    self.m_baseReSpinBar:setVisible(false)

    -- --respin光效层
    -- self.m_effectNode_respin = {}
    -- for index=1, 4 do
    --     self.m_effectNode_respin[index] = cc.Node:create()
    --     self:findChild("Node_reel"):addChild(self.m_effectNode_respin[index],SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + index)
    -- end

    --大赢
    self.m_bigWinSpine = util_spineCreate("BadgedCowboy_bigwin",true,true)
    self.m_bigWinAni = util_createAnimation("BadgedCowboy_bigwin_lizi.csb")
    self.m_bigWinSpine:setVisible(false)
    self.m_bigWinAni:setVisible(false)
    self.particleTbl = {}
    for i=1, 4 do
        self.particleTbl[i] = self.m_bigWinAni:findChild("Particle_"..i)
    end
    self:findChild("Node_bgEffect"):addChild(self.m_bigWinSpine)
    self:findChild("Node_bgEffect"):addChild(self.m_bigWinAni)

    --大赢飘数字
    self.m_bigwinEffectNum = util_createAnimation("BadgedCowboy_totalwin.csb")
    self.m_bottomUI:findChild("win_txt"):addChild(self.m_bigwinEffectNum, -1)
    self.m_bigwinEffectNum:setVisible(false)

    --scatter震动
    --全屏幕防点击
    self.m_gobalTouchLayer = ccui.Layout:create()
    self.m_gobalTouchLayer:setContentSize(cc.size(50000, 50000))
    self.m_gobalTouchLayer:setAnchorPoint(cc.p(0, 0))
    self.m_gobalTouchLayer:setTouchEnabled(false)
    self.m_gobalTouchLayer:setSwallowTouches(false)
    -- self.m_gobalTouchLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    -- self.m_gobalTouchLayer:setBackGroundColor(cc.c3b(0, 150, 0))
    -- self.m_gobalTouchLayer:setBackGroundColorOpacity(150)
    self:addChild(self.m_gobalTouchLayer, GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN + 1)
    
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)

    self.m_topSymbolLiZiNode = self:findChild("Node_topSymbol_lizi")

    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))
    self.m_jackpotTopSpine = self:createBadgedCowboySymbol(self.SYMBOL_SCORE_JACKPOT)
    self.m_jackpotTopSpine:setPosition(worldPos)
    self:addChild(self.m_jackpotTopSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_jackpotTopSpine:setVisible(false)

    --free特效层
    self.m_effectFixdNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_effectFixdNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)

    self:addClick(self:findChild("Panel_click"))
    self:changeBgSpine(1)
    self.m_chooseView:scaleMainLayer(self.m_machineRootScale)
end


function CodeGameScreenBadgedCowboyMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 3, 0, 1)
    end,0.2,self:getModuleName())
end

function CodeGameScreenBadgedCowboyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBadgedCowboyMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenBadgedCowboyMachine:initGameUI()

    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self:changeBgSpine(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
        self:addFixedWildToInitGame()
    end
    --respin模式
    if self:getCurStateIsRespin() then
        self:initRespinUi(0)
    end
end

function CodeGameScreenBadgedCowboyMachine:addObservers()
    CodeGameScreenBadgedCowboyMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end

        local winLines = self.m_reelResultLines or {}
        if #winLines <= 0 then
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

        local soundName = "BadgedCowboySounds/music_BadgedCowboy_last_win_".. bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenBadgedCowboyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBadgedCowboyMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenBadgedCowboyMachine:scaleMainLayer()
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
    self.m_dialogRootSccale = mainScale
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width / display.height >= 1370/768 then
            mainScale = mainScale * 1.05
            self.m_dialogRootSccale = mainScale
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 1.02
            self.m_dialogRootSccale = mainScale
        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.92
            self.m_dialogRootSccale = mainScale
        elseif display.width / display.height >= 1024/768 then
            mainScale = mainScale * 0.83
            mainPosY = mainPosY + 10
            self.m_dialogRootSccale = mainScale * 0.9
        elseif display.width / display.height >= 1.2 then--1812x2176
            mainScale = mainScale * 0.83
            self.m_dialogRootSccale = mainScale
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBadgedCowboyMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BadgedCowboy_10"
    elseif symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
        return "Socre_BadgedCowboy_Scatter2"
    elseif symbolType == self.SYMBOL_SCORE_SPECIAL_WILD then
        return "Socre_BadgedCowboy_Wild2"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT then
        return "Socre_BadgedCowboy_Jackpot"
    elseif symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_BadgedCowboy_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_SPECIAL_BONUS then
        return "Socre_BadgedCowboy_Bonus2"
    elseif symbolType == self.SYMBOL_SCORE_NULL then
        return "Socre_BadgedCowboy_NULL"
    end
    return nil
end

---
--设置bonus scatter 层级
function CodeGameScreenBadgedCowboyMachine:getBounsScatterDataZorder(symbolType, iCol, iRow)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 500
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 200
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:getCurSymbolIsBonus(symbolType)  then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_SCORE_SPECIAL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end

    --右压左、下压上
    if (iCol and iRow) then
        order = order + iCol * 50 - iRow
    end
    return order
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBadgedCowboyMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenBadgedCowboyMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

--默认按钮监听回调
function CodeGameScreenBadgedCowboyMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" then
        self:feedBackBgEffect(sender)
    end
end

--点击背景反馈特效
function CodeGameScreenBadgedCowboyMachine:feedBackBgEffect(sender)
    local beginPos = sender:getTouchBeganPosition()
    local nodePos = self:findChild("Node_bgEffect"):convertToNodeSpace(beginPos)
    local m_bgAniEffect = util_createAnimation("BadgedCowboy_dianji.csb")
    self:findChild("Node_bgEffect"):addChild(m_bgAniEffect)
    m_bgAniEffect:setPosition(nodePos)
    m_bgAniEffect:runCsbAction("actionframe", false, function()
        m_bgAniEffect:removeFromParent()
    end)
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenBadgedCowboyMachine:MachineRule_initGame(  )

    
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenBadgedCowboyMachine:initGameStatusData(gameData)
    local featureData = gameData.feature
    local spinData = gameData.spin
    if featureData and spinData then
        if featureData.features and #featureData.features == 2 then
            if featureData.features[2] == 1 then
                spinData.freespin = featureData.freespin
            elseif featureData.features[2] == 3 then
                spinData.respin = featureData.respin
            else
                spinData.features = featureData.features
            end

            if featureData.selfData and spinData.selfData then
                spinData.selfData = featureData.selfData
            end
        end
    end

    CodeGameScreenBadgedCowboyMachine.super.initGameStatusData(self,gameData)
end

--顶部补块
function CodeGameScreenBadgedCowboyMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
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

function CodeGameScreenBadgedCowboyMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    local addLens = false
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
        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 6)
                self:setLastReelSymbolList()
            end
        end
        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)
        local maxCol = self:getMaxContinuityBonusCol()
        if col > maxCol then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
        elseif maxCol == col  then
            if bRunLong then
                addLens = true
            end
        end
    end --end  for col=1,iColumn do
end

-- --设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenBadgedCowboyMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i = 1, self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum >= 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 2 then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[1] then
        if nodeNum >= 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum > 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

--设置bonus scatter 信息
function CodeGameScreenBadgedCowboyMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

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
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType or self:getSymbolTypeForNetData(column,row,runLen) == self.SYMBOL_SCORE_SPECIAL_SCATTER then
        
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

--
--单列滚动停止回调
--
function CodeGameScreenBadgedCowboyMachine:slotLocalOneReelDown(_iCol)
    self:playReelDownSound(_iCol, self.m_reelDownSound)
end

--
--单列滚动停止回调
--
function CodeGameScreenBadgedCowboyMachine:slotOneReelDown(reelCol)    
    CodeGameScreenBadgedCowboyMachine.super.slotOneReelDown(self,reelCol)
    ---本列是否开始长滚
    local isTriggerLongRun = false
    if reelCol == 1 then
        self.isHaveLongRun = false
    end
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true
    end
    local delayTime = 15/30
    if isTriggerLongRun then
        self.isHaveLongRun = true
        self:playScatterSpine("idleframe3", reelCol)
    else
        if self.isHaveLongRun then
            --始化长滚信息
            if self.m_reelRunSoundTag ~= -1 then
                --停止长滚音效
                -- printInfo("xcyy : m_reelRunSoundTag2 %d",self.m_reelRunSoundTag)
                gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
                self.m_reelRunSoundTag = -1
            end
            local features = self.m_runSpinResultData.p_features
            local randomPlay = math.random(1, 10)
            if not features or #features <= 1 then
                local randomNum = math.random(1, 2)
                local soundEffect = self.m_publicConfig.Music_Near_MIss_Tbl[randomNum]
                gLobalSoundManager:playSound(soundEffect)
            end
            self:playScatterSpine("idleframe1", reelCol, true)
            self.isHaveLongRun = false
        end
        -- if reelCol == self.m_iReelColumnNum and self.isHaveLongRun == true then
        --     --落地
        --     self.triggerScatterDelayTime = 15/30
        --     self:playScatterSpine("idleframe1", reelCol, true)
        -- end
    end
end

function CodeGameScreenBadgedCowboyMachine:playScatterSpine(_spineName, _reelCol, isOver)
    performWithDelay(self.m_scWaitNode, function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
                        if _spineName == "idleframe3" and targSp.m_currAnimName ~= "idleframe3" then
                            targSp:runAnim(_spineName, true)
                        elseif _spineName == "idleframe1" then
                            targSp:runAnim(_spineName, true)
                        end
                    end
                end
            end
        end
    end, 0.1)
end

--[[
    单列滚动停止
]]
function CodeGameScreenBadgedCowboyMachine:slotOneReelDownFinishCallFunc( reelCol )

    CodeGameScreenBadgedCowboyMachine.super.slotOneReelDownFinishCallFunc(self,reelCol)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE or not selfData or not selfData.specialScPosition then
        return
    end
    -- if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
    local specialScPosition = selfData.specialScPosition
    for k, index in pairs(specialScPosition) do
        local startPos = self:getRowAndColByPos(tonumber(index))
        if startPos.iY == reelCol then
            local fixNode = self:getFixSymbol(startPos.iY , startPos.iX)
            if fixNode then
                fixNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_SPECIAL_WILD), self.SYMBOL_SCORE_SPECIAL_WILD)
                fixNode:setLocalZOrder(self:getBounsScatterDataZorder(self.SYMBOL_SCORE_SPECIAL_WILD) - fixNode.p_rowIndex)

                if fixNode.p_symbolImage then
                    fixNode.p_symbolImage:removeFromParent()
                    fixNode.p_symbolImage = nil
                end
                fixNode:runIdleAnim()
            end
        end
    end
    if reelCol == self.m_iReelColumnNum then
        self.m_effectFixdNode:setVisible(false)
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBadgedCowboyMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBadgedCowboyMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenBadgedCowboyMachine:getCurStateIsRespin()
    --用respin次数判断当前是否是respin状态
    if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        return true
    end
    return false
end

---- lighting 断线重连时，随机转盘数据
function CodeGameScreenBadgedCowboyMachine:respinModeChangeSymbolType( )
    
end

function CodeGameScreenBadgedCowboyMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
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

function CodeGameScreenBadgedCowboyMachine:showReSpinStart(_callFunc)
    local callFunc = _callFunc
    local endCallFunc = function()
        callFunc()
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local totalCoins = selfData.resScore
    local sScore = self:get_formatCoins(totalCoins, 3)
    self:addRespinDoubleCoins()
    self:hideBaseReelSymbol()
    self:changeBgSpine(3)
    -- self:clearCurMusicBg()
    self.m_baseFreeSpinBar:setRespinCoins(1, sScore)
    
    self:recorverFreeScatter()
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_StartStart)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil)
    view:findChild("root"):setScale(self.m_dialogRootSccale)
    local isPlay = false
    local bgSpine = util_spineCreate("BadgedCowboy_tanban",true,true)
    util_spinePlay(bgSpine,"start",false)
    local playClickFunc = function(_auto)
        if isPlay then
            return
        end
        isPlay = true
        if _auto then
            view:runCsbAction("over", false, function()
                view:removeFromParent()
            end)
        end
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_StartOver)
        util_spinePlay(bgSpine,"over",false)
        self:addFalseScatterForRespin()
        self:showCutSceneAni(function()
            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            performWithDelay(self.m_scWaitNode, function()
                self:addFixedMul(endCallFunc)
            end, 0.5)
        end, "respinStart")
    end

    view:findChild("m_lb_coins"):setString(sScore)
    view:findChild("Node_men"):addChild(bgSpine)
    view:setBtnClickFunc(playClickFunc)
    view.m_allowClick = false
    local time = view:getAnimTime("start")
    performWithDelay(view,function ()
        view.m_allowClick = true
        util_spinePlay(bgSpine,"idle",true)
    end, time)
    performWithDelay(self.m_scWaitNode,function ()
        playClickFunc(true)
    end, 5.0)
    util_setCascadeOpacityEnabledRescursion(view, true)
end

--respin 上边会裁切，新建假的scatter，在startMove时移除
function CodeGameScreenBadgedCowboyMachine:addFalseScatterForRespin()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local specialScatterPos = selfData.specialScPosition
    if specialScatterPos and #specialScatterPos == 0 then
        return
    end
    if selfData and selfData.scoreCoins then
        self.m_effectFixdNode:setVisible(true)
        local scoreCoins = selfData.scoreCoins
        local scorePosTbl = {}
        --free前展示free次数
        if scoreCoins then
            for k, v in pairs(scoreCoins) do
                local tempTbl = {}
                tempTbl.pos = tonumber(k)
                table.insert(scorePosTbl, tempTbl)
            end
        end

        if #scorePosTbl >0 then
            --把特殊scatter标记
            if specialScatterPos and #specialScatterPos > 0 then
                for i=1, #scorePosTbl do
                    local pos = scorePosTbl[i].pos
                    for j=1, #specialScatterPos do
                        if pos == specialScatterPos[j] then
                            scorePosTbl[i].special = true
                        end
                    end
                end
            end
        end

        for k, posTbl in pairs(scorePosTbl) do
            local scatterType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
            local scPos = posTbl.pos
            if posTbl.special then
                scatterType = self.SYMBOL_SCORE_SPECIAL_SCATTER
            end
            local scatterNode = self:createBadgedCowboySymbol(scatterType)
            local pos = cc.p(util_getOneGameReelsTarSpPos(self, scPos))
            local fixPos = self:getRowAndColByPos(scPos)
            scatterNode:setPosition(pos)
            local m_zorder = self:getBounsScatterDataZorder(scatterType, fixPos.iY, fixPos.iX)
            self.m_doubleFixdNode:addChild(scatterNode, m_zorder)
            scatterNode:runAnim("idleframe", true)
            table.insert(self.m_respinFalseScatterTbl, scatterNode)
        end
    end
end

--respin开始时，删除假的数据
function CodeGameScreenBadgedCowboyMachine:removeFalseScatter()
    if self.m_respinFalseScatterTbl and #self.m_respinFalseScatterTbl > 0 then
        for k, scNode in pairs(self.m_respinFalseScatterTbl) do
            if not tolua.isnull(scNode) then
                scNode:runAnim("over", false, function()
                    scNode:setVisible(false)
                end)
            end
        end
        performWithDelay(self.m_scWaitNode, function()
            for k, scNode in pairs(self.m_respinFalseScatterTbl) do
                if not tolua.isnull(scNode) then
                    scNode:removeFromParent()
                    self.m_respinFalseScatterTbl[k] = nil
                end
            end
        end, 30/30)
        self.m_respinFalseScatterTbl = {}
    end
end

function CodeGameScreenBadgedCowboyMachine:addFixedMul(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.specialScPosition and #selfData.specialScPosition > 0 then
        --scatter-switch 0-53
        local specialScatterPos = selfData.specialScPosition
        local totalCount = #specialScatterPos
        local delayTime = 20/60
        for k, scPos in pairs(specialScatterPos) do
            local pos = cc.p(util_getOneGameReelsTarSpPos(self, scPos))
            local fixPos = self:getRowAndColByPos(scPos)
            local doubleNode = util_createAnimation("BadgedCowboy_xbei_num.csb")
            doubleNode:setPosition(pos)
            self.m_doubleFixdNode:addChild(doubleNode, 3000+scPos)
            self.m_respinDoubleNode[scPos] = doubleNode
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_Change_Double)
                doubleNode:runCsbAction("start", false, function()
                    doubleNode:runCsbAction("idle", true)
                end)
            end, delayTime*(k-1))
        end
        performWithDelay(self.m_scWaitNode, function()
            self:removeFalseScatter()
            if type(callFunc) == "function" then
                callFunc()
            end
        end, delayTime*totalCount)
    else
        self:removeFalseScatter()
        if type(callFunc) == "function" then
            callFunc()
        end
    end
end

---
-- 触发respin 玩法
--
function CodeGameScreenBadgedCowboyMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    -- self:clearCurMusicBg()
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
        scheduler.performWithDelayGlobal(
            function()
                removeMaskAndLine()
                self:showRespinView(effectData)
            end,
            1,
            self:getModuleName()
        )
    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenBadgedCowboyMachine:showRespinView()

    --先播放动画 再进入respin
    -- self:clearCurMusicBg()

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    self.m_reelResultLines = {}
    self.m_respinDoubleNode = {}
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号 
    local endTypes = self:getRespinLockTypes()
    
    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)

    --jackpot挂点（1-4代表行数，5是grand）
    
    self.m_jackpotNodeMainTbl = {}
    for i=1, 5 do
        local nodePosX, nodePosY = self:findChild("Node_jackpot_"..i):getPosition()
        local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))
        local nodePos = self.m_respinView:convertToNodeSpace(worldPos)

        local respinJackpotNode = cc.Node:create()
        respinJackpotNode:setPosition(nodePos)
        self.m_respinView:addChild(respinJackpotNode, 5000+i)
        self.m_jackpotNodeMainTbl[i] = respinJackpotNode
    end

    --respin光效层-单格
    self.m_respinNodeSingle = {}
    for index=1, 4 do
        self.m_respinNodeSingle[index] = cc.Node:create()
        self.m_respinView:addChild(self.m_respinNodeSingle[index], SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + index)
    end

    --respin光效层-整行
    self.m_respinNodeLight = {}
    for index=1, 4 do
        self.m_respinNodeLight[index] = cc.Node:create()
        self.m_respinView:addChild(self.m_respinNodeLight[index], 9000 + index)
    end

    self.m_doubleFixdNode = cc.Node:create()
    self.m_respinView:addChild(self.m_doubleFixdNode, 9500)
end

function CodeGameScreenBadgedCowboyMachine:hideBaseReelSymbol()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(false)
            end
        end
    end
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenBadgedCowboyMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_SCORE_BONUS, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SCORE_SPECIAL_BONUS, runEndAnimaName = "", bRandom = true},
    }

    return symbolList
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenBadgedCowboyMachine:getRespinRandomTypes( )
    local symbolList = { 
        self.SYMBOL_SCORE_NULL,
        self.SYMBOL_SCORE_BONUS,
    }

    return symbolList
end

--断线回来添加jackpot特效
function CodeGameScreenBadgedCowboyMachine:initRespinUi(_curRowIndex)
    local curRowIndex = _curRowIndex + 1
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpotNames = selfData.jackpotNames
    local JACK_ENUM = 
    {
        GRAND = 1,
        MAJOR = 2,
        MINOR = 3,
        MINI = 4,
    }
    if jackpotNames and #jackpotNames > 0 then
        local totalCount = #jackpotNames
        if curRowIndex > totalCount then
            return
        end
        local jackpot = jackpotNames[curRowIndex]
        local jackpotIndex = 4
        local curJackpotRowIndex = 0
        if jackpot.mini then
            jackpotIndex = JACK_ENUM.MINI
            curJackpotRowIndex = jackpot.mini
        elseif jackpot.minor then
            jackpotIndex = JACK_ENUM.MINOR
            curJackpotRowIndex = jackpot.minor
        elseif jackpot.major then
            jackpotIndex = JACK_ENUM.MAJOR
            curJackpotRowIndex = jackpot.major
        elseif jackpot.grand then
            jackpotIndex = JACK_ENUM.GRAND
            curJackpotRowIndex = jackpot.grand
        end
        --转换成本地行信息
        curJackpotRowIndex = self.m_iReelRowNum - curJackpotRowIndex
        self.m_jackPotBar:playJackpotAction(jackpotIndex, true)
        if jackpotIndex == JACK_ENUM.MINOR then
            local miniRowIndex = nil
            for k, v in pairs(jackpotNames) do
                if v.mini then
                    miniRowIndex = self.m_iReelRowNum - v.mini
                end
            end
            if miniRowIndex then
                local miniEffectNode = util_createAnimation(self.m_jackpotCsbName[JACK_ENUM.MINOR])
                self.m_jackpotNodeMainTbl[miniRowIndex]:addChild(miniEffectNode)
                table.insert(self.m_jackpotNodeEffect[1], miniEffectNode)
                miniEffectNode:runCsbAction("idle", true)
            end
        elseif jackpotIndex == JACK_ENUM.MAJOR then
            --先获取mini和minor位置
            local miniRowIndex, minorRowIndex
            for k, v in pairs(jackpotNames) do
                if v.mini then
                    miniRowIndex = self.m_iReelRowNum - v.mini
                end
                if v.minor then
                    minorRowIndex = self.m_iReelRowNum - v.minor
                end
            end
            if miniRowIndex then
                local miniEffectNode = util_createAnimation(self.m_jackpotCsbName[JACK_ENUM.MAJOR])
                self.m_jackpotNodeMainTbl[miniRowIndex]:addChild(miniEffectNode)
                table.insert(self.m_jackpotNodeEffect[1], miniEffectNode)
                miniEffectNode:runCsbAction("idle", true)
            end
            if minorRowIndex then
                local minorEffectNode = util_createAnimation(self.m_jackpotCsbName[JACK_ENUM.MAJOR])
                self.m_jackpotNodeMainTbl[minorRowIndex]:addChild(minorEffectNode)
                table.insert(self.m_jackpotNodeEffect[2], minorEffectNode)
                minorEffectNode:runCsbAction("idle", true)
            end
        end
        --转换成本地
        local nodeJackpotIndex = 4 - jackpotIndex + 1
        --jackpot黑遮罩
        local jackpotNodeMask = util_createAnimation("BadgedCowboy_jackpot_kuangdark.csb")
        self.m_jackpotNodeMainTbl[curJackpotRowIndex]:addChild(jackpotNodeMask)
        self.m_jackpotNodeDark[nodeJackpotIndex] = jackpotNodeMask
        jackpotNodeMask:runCsbAction("idle", true)

        --jackpot光圈
        local jackpotEffectNode = util_createAnimation(self.m_jackpotCsbName[jackpotIndex])
        --grand是5
        if jackpotIndex == JACK_ENUM.GRAND then
            self.m_jackpotNodeMainTbl[5]:addChild(jackpotEffectNode)
        else
            self.m_jackpotNodeMainTbl[curJackpotRowIndex]:addChild(jackpotEffectNode)
        end
        table.insert(self.m_jackpotNodeEffect[nodeJackpotIndex], jackpotEffectNode)
        jackpotEffectNode:runCsbAction("idle", true)

        --jackpot文案
        local jackpotNodeText = util_createAnimation("BadgedCowboy_jackpot_kuang_zi.csb")
        for i=1, 4 do
            if i == jackpotIndex then
                jackpotNodeText:findChild("jackpot_"..i):setVisible(true)
            else
                jackpotNodeText:findChild("jackpot_"..i):setVisible(false)
            end
        end
        self.m_jackpotNodeMainTbl[curJackpotRowIndex]:addChild(jackpotNodeText, 20)
        self.m_jackpotNodeText[nodeJackpotIndex] = jackpotNodeText
        jackpotNodeText:runCsbAction("idle", true)
        self:initRespinUi(curRowIndex)
    end
end

--判断当前是否已经获得mini
function CodeGameScreenBadgedCowboyMachine:curRewardMini()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpotResult = selfData.jackpotResult
    local jackpotNames = selfData.jackpotNames
    if jackpotNames and jackpotResult then
        if #jackpotNames > 1 or (#jackpotNames == 1 and #jackpotResult == 0) then
            return true
        end
    end
    return false
end

--判断当前是否已经获得三个jackpot
function CodeGameScreenBadgedCowboyMachine:judgeCurIsLastJackpot()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpotResult = selfData.jackpotResult
    local jackpotNames = selfData.jackpotNames
    if jackpotNames and #jackpotNames == 3 then
        return true
    end
    return false
end

function CodeGameScreenBadgedCowboyMachine:reSpinReelDown(addNode)
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        local overCallFunc = function()
            CodeGameScreenBadgedCowboyMachine.super.reSpinReelDown(self)
        end

        --收集bonus
        local addCollectBonusFunc = function(_curTotalCoins)
            local curTotalCoins = _curTotalCoins
            self.m_jackPotBar:playJackpotIdle()
            performWithDelay(self.m_scWaitNode, function()
                self:addCollectBonus(overCallFunc, 0, curTotalCoins)
            end, 0.5)
        end

        --收集jackpot
        local function addJackpotRewardFunc()
            performWithDelay(self.m_scWaitNode, function()
                self.m_baseFreeSpinBar:setRespinEndAni()
                self:addRespinJackpot(addCollectBonusFunc, 1, 0)
            end, 0.5)
        end

        --添加jackpot动效
        local addJckpotEffectFunc = function()
            self:addRespinJackpotEffect(addJackpotRewardFunc, 0)
        end

        self:addRespinDoubleCoins(addJckpotEffectFunc)
        for rowIndex=1, self.m_iReelRowNum do
            self.m_respinView:cleanEffect(rowIndex)
        end
        for k, v in pairs(self.m_respinDoubleNode) do
            if not tolua.isnull(v) then
                v:removeFromParent()
            end
        end
        self.m_respinDoubleNode = {}
    else
        local nextCallFunc = function()
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            self:runNextReSpinReel()
        end

        --添加jackpot动效
        local addJckpotEffectFunc = function()
            self:addRespinJackpotEffect(nextCallFunc, 0)
        end

        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self:addRespinDoubleCoins(addJckpotEffectFunc)
    end
end

--最后单个收集bonus
function CodeGameScreenBadgedCowboyMachine:addCollectBonus(_endCallFunc, _curIndex, _curTotalCoins)
    local endCallFunc = _endCallFunc
    local curTotalCoins = _curTotalCoins
    local curIndex = _curIndex
    curIndex = curIndex + 1

    local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
    if curIndex > symbolTotalNum then
        performWithDelay(self.m_scWaitNode, function()
            self.m_topSymbolLiZiNode:removeAllChildren()
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        end, 0.5)
        return
    end

    local symbolNodePos = self.m_symbolNodeRandom[curIndex]
    local fixPos = self:getRowAndColByPos(symbolNodePos-1)
    local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
    local curBet = globalData.slotRunData:getCurTotalBet()
    local rewardMul = self:getReSpinBonusScore(symbolNodePos-1)

    if rewardMul and symbolNode then
        local curReward = curBet * rewardMul
        curTotalCoins = curTotalCoins + curReward

        local startNodePos, endNodePos = self:getParticleFlyPos(symbolNodePos-1)
        --飞行粒子
        local flyNode = util_createAnimation("BadgedCowboy_shouji_lizi.csb")
        flyNode:setPosition(startNodePos.x, startNodePos.y)
        self.m_topSymbolLiZiNode:addChild(flyNode)

        local particleDelayTime = 0.3
        local m_particleTbl = {}
        for i = 1, 3 do
            m_particleTbl[i] = flyNode:findChild("Particle_"..i)
            m_particleTbl[i]:setPositionType(0)
            m_particleTbl[i]:setDuration(-1)
            m_particleTbl[i]:resetSystem()
        end

        --收集反馈
        local boomNode = util_createAnimation("BadgedCowboy_bar_bd.csb")
        boomNode:setPosition(endNodePos.x, endNodePos.y)
        self.m_topSymbolLiZiNode:addChild(boomNode)
        boomNode:setVisible(false)

        symbolNode:runAnim("jiesuan", false, function()
            symbolNode:runAnim("over", false)
        end)
        local nodeScore = nil
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        if spineNode and spineNode.m_nodeScore then
            nodeScore = spineNode.m_nodeScore
        end
        
        if nodeScore then
            if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
                nodeScore:runCsbAction("over", false)
            else
                nodeScore:runCsbAction("over1", false)
            end
        end
        util_playMoveToAction(flyNode, particleDelayTime, endNodePos, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_CollectFeedBack)
            for i = 1, 3 do
                m_particleTbl[i]:stopSystem()
            end
            boomNode:setVisible(true)
            self.m_baseFreeSpinBar:addRespinTopEndCoins(self:get_formatCoins(curTotalCoins, 3))
            boomNode:runCsbAction("actionframe1", false, function()
                if not tolua.isnull(boomNode) then
                    boomNode:setVisible(false)
                end
                if not tolua.isnull(flyNode) then
                    flyNode:setVisible(false)
                end
            end)
        end)
        performWithDelay(self.m_scWaitNode, function()
            self:addCollectBonus(endCallFunc, curIndex, curTotalCoins)
        end, 0.5)
    else
        local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
        if curIndex >= symbolTotalNum then
            self.m_topSymbolLiZiNode:removeAllChildren()
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        else
            self:addCollectBonus(endCallFunc, curIndex, curTotalCoins)
        end
    end
end

function CodeGameScreenBadgedCowboyMachine:setRespinFalseBonus(_bonusNode, _row, _col)
    local nodeScore = util_createAnimation("BadgedCowboy_BonusCoins.csb")
    nodeScore:setPosition(cc.p(3, -2))
    local spineNode = _bonusNode:getNodeSpine()
    util_spinePushBindNode(spineNode,"zi",nodeScore)
    local curBet = globalData.slotRunData:getCurTotalBet()
    local sScore = ""
    local mul = self:getReSpinBonusScore(self:getPosReelIdx(_row, _col))
    if mul ~= nil and mul ~= 0 then
        local coins = mul * curBet
        sScore = self:get_formatCoins(coins, 3)
    end
    local textNode, textHighNode
    if nodeScore then
        for i=1, 4 do
            local textNode = nodeScore:findChild("m_lb_coins_"..i)
            textNode:setString(sScore)
            self:updateLabelSize({label=textNode,sx=0.35,sy=0.35},207)
        end
        if _bonusNode.m_symbolType == self.SYMBOL_SCORE_BONUS then
            nodeScore:runCsbAction("idleframe", true)
        else
            nodeScore:runCsbAction("idleframe1", true)
        end
    end
end

--respin停轮后添加jackpot动效（respin过程中）
function CodeGameScreenBadgedCowboyMachine:addRespinJackpotEffect(_endCallFunc, _curRowIndex)
    local endCallFunc = _endCallFunc
    local curRowIndex = _curRowIndex + 1
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpotResult = selfData.jackpotResult
    local jackpotNames = selfData.jackpotNames
    local JACK_ENUM = 
    {
        GRAND = 1,
        MAJOR = 2,
        MINOR = 3,
        MINI = 4,
    }
    if jackpotResult and #jackpotResult > 0 then
        local totalCount = #jackpotResult
        if curRowIndex > totalCount then
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
            return
        end
        local jackpot = jackpotResult[curRowIndex]
        local jackpotIndex = 4
        local curJackpotRowIndex = 0
        if jackpot.mini then
            jackpotIndex = JACK_ENUM.MINI
            curJackpotRowIndex = jackpot.mini
        elseif jackpot.minor then
            jackpotIndex = JACK_ENUM.MINOR
            curJackpotRowIndex = jackpot.minor
        elseif jackpot.major then
            jackpotIndex = JACK_ENUM.MAJOR
            curJackpotRowIndex = jackpot.major
        elseif jackpot.grand then
            jackpotIndex = JACK_ENUM.GRAND
            curJackpotRowIndex = jackpot.grand
        end
        --转换成本地行信息
        curJackpotRowIndex = self.m_iReelRowNum - curJackpotRowIndex

        local oriBonusTbl = {}
        local topBonusTbl = {}
        --添加假的bonus在最上层，播完动画后移除
        for colIndex=1, self.m_iReelColumnNum do
            local symbolNode = self.m_respinView:getRespinEndNode(curJackpotRowIndex, colIndex)
            local bonusPos = self:getPosReelIdx(curJackpotRowIndex, colIndex)
            local clipTarPos = cc.p(util_getOneGameReelsTarSpPos(self, bonusPos))
            local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
            local nodePos = self.m_effectFixdNode:convertToNodeSpace(worldPos)
            local bonusNode = self:createBadgedCowboySymbol(symbolNode.p_symbolType)
            self:setRespinFalseBonus(bonusNode, curJackpotRowIndex, colIndex)
            bonusNode:setPosition(nodePos)
            self.m_effectFixdNode:addChild(bonusNode, 1000+colIndex)
            bonusNode:runAnim("jiman", false, function()
                bonusNode:runAnim("idleframe1", true)
            end)
            topBonusTbl[#topBonusTbl+1] = bonusNode
        end

        --先播放一遍jackpot行bonus动画
        for colIndex=1, self.m_iReelColumnNum do
            local symbolNode = self.m_respinView:getRespinEndNode(curJackpotRowIndex, colIndex)
            if symbolNode then
                symbolNode:setVisible(false)
                oriBonusTbl[#oriBonusTbl+1] = symbolNode
                -- symbolNode:runAnim("jiman", false, function()
                --     symbolNode:runAnim("idleframe1", true)
                -- end)
            end
        end
        self.m_jackPotBar:playJackpotAction(jackpotIndex, true)
        self.m_jackpotLight:setVisible(true)
        self.m_jackpotLight:runCsbAction("actionframe", false, function()
            self.m_jackpotLight:setVisible(false)
        end)
        self:shakeRootNode(8)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Repin_BonusFull)
        performWithDelay(self.m_scWaitNode, function()
            for k, _oriBonusNode in pairs(oriBonusTbl) do
                _oriBonusNode:setVisible(true)
                _oriBonusNode:runAnim("idleframe1", true)
            end
            for k, _topBonusNode in pairs(topBonusTbl) do
                _topBonusNode:setVisible(false)
            end
            gLobalSoundManager:playSound(self.m_publicConfig.Music_JackpotFrame_Appear)
            if jackpotIndex == JACK_ENUM.MINOR then
                local miniRowIndex = nil
                for k, v in pairs(jackpotNames) do
                    if v.mini then
                        miniRowIndex = self.m_iReelRowNum - v.mini
                    end
                end
                if miniRowIndex then
                    local miniEffectNode = util_createAnimation(self.m_jackpotCsbName[JACK_ENUM.MINOR])
                    self.m_jackpotNodeMainTbl[miniRowIndex]:addChild(miniEffectNode)
                    table.insert(self.m_jackpotNodeEffect[1], miniEffectNode)
                    miniEffectNode:runCsbAction("start", false, function()
                        miniEffectNode:runCsbAction("idle", true)
                    end)
                end
            elseif jackpotIndex == JACK_ENUM.MAJOR then
                --先获取mini和minor位置
                local miniRowIndex, minorRowIndex
                for k, v in pairs(jackpotNames) do
                    if v.mini then
                        miniRowIndex = self.m_iReelRowNum - v.mini
                    end
                    if v.minor then
                        minorRowIndex = self.m_iReelRowNum - v.minor
                    end
                end
                if miniRowIndex then
                    local miniEffectNode = util_createAnimation(self.m_jackpotCsbName[JACK_ENUM.MAJOR])
                    self.m_jackpotNodeMainTbl[miniRowIndex]:addChild(miniEffectNode)
                    table.insert(self.m_jackpotNodeEffect[1], miniEffectNode)
                    miniEffectNode:runCsbAction("start", false, function()
                        miniEffectNode:runCsbAction("idle", true)
                    end)
                end
                if minorRowIndex then
                    local minorEffectNode = util_createAnimation(self.m_jackpotCsbName[JACK_ENUM.MAJOR])
                    self.m_jackpotNodeMainTbl[minorRowIndex]:addChild(minorEffectNode)
                    table.insert(self.m_jackpotNodeEffect[2], minorEffectNode)
                    minorEffectNode:runCsbAction("start", false, function()
                        minorEffectNode:runCsbAction("idle", true)
                    end)
                end
            end
            --转换成本地
            local nodeJackpotIndex = 4 - jackpotIndex + 1
            --jackpot黑遮罩
            local jackpotNodeMask = util_createAnimation("BadgedCowboy_jackpot_kuangdark.csb")
            self.m_jackpotNodeMainTbl[curJackpotRowIndex]:addChild(jackpotNodeMask)
            self.m_jackpotNodeDark[nodeJackpotIndex] = jackpotNodeMask
            jackpotNodeMask:runCsbAction("start", false, function()
                jackpotNodeMask:runCsbAction("idle", true)
            end)

            --jackpot光圈
            local jackpotEffectNode = util_createAnimation(self.m_jackpotCsbName[jackpotIndex])
            --grand是5
            if jackpotIndex == JACK_ENUM.GRAND then
                self.m_jackpotNodeMainTbl[5]:addChild(jackpotEffectNode)
            else
                self.m_jackpotNodeMainTbl[curJackpotRowIndex]:addChild(jackpotEffectNode)
            end
            table.insert(self.m_jackpotNodeEffect[nodeJackpotIndex], jackpotEffectNode)
            jackpotEffectNode:runCsbAction("start", false, function()
                jackpotEffectNode:runCsbAction("idle", true)
            end)

            --jackpot文案
            local jackpotNodeText = util_createAnimation("BadgedCowboy_jackpot_kuang_zi.csb")
            for i=1, 4 do
                if i == jackpotIndex then
                    jackpotNodeText:findChild("jackpot_"..i):setVisible(true)
                else
                    jackpotNodeText:findChild("jackpot_"..i):setVisible(false)
                end
            end
            self.m_jackpotNodeMainTbl[curJackpotRowIndex]:addChild(jackpotNodeText, 20)
            self.m_jackpotNodeText[nodeJackpotIndex] = jackpotNodeText
            jackpotNodeText:runCsbAction("start", false, function()
                jackpotNodeText:runCsbAction("idle", true)
                self:addRespinJackpotEffect(endCallFunc, curRowIndex)
            end)
        end, 35/30)
    else
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end
end

--respin结束添加jackpot奖励
function CodeGameScreenBadgedCowboyMachine:addRespinJackpot(_endCallFunc, _curColIndex, _curTotalCoins)
    local curColIndex = _curColIndex
    local endCallFunc = _endCallFunc
    local curTotalCoins = _curTotalCoins
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local allJackpotNames = selfData.jackpotNames
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins

    if allJackpotNames and #allJackpotNames > 0 then
        local totalCount = #allJackpotNames
        if curColIndex > totalCount then
            for i=1, 4 do
                --文本
                local jackpotText = self.m_jackpotNodeText[i]
                if not tolua.isnull(jackpotText) then
                    jackpotText:runCsbAction("over", false, function()
                        jackpotText:removeFromParent()
                    end)
                end
                --遮罩
                local jackpotDark = self.m_jackpotNodeDark[i]
                if not tolua.isnull(jackpotDark) then
                    jackpotDark:runCsbAction("over", false, function()
                        jackpotDark:removeFromParent()
                    end)
                end
                --光圈
                local jackpotEffectData = self.m_jackpotNodeEffect[i]
                for k, v in pairs(jackpotEffectData) do
                    if not tolua.isnull(v) then
                        v:runCsbAction("over", false, function()
                            v:removeFromParent()
                        end)
                    end
                end
            end
            self.m_jackpotNodeEffect = {{}, {}, {}, {}}
            self.m_jackpotNodeDark = {}
            self.m_jackpotNodeText = {}
            self.m_topSymbolLiZiNode:removeAllChildren()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_JackpotFrame_Disappear)
            if type(endCallFunc) == "function" then
                endCallFunc(curTotalCoins)
            end
            return
        end

        --从大到小，排个序
        local jackpotNames = {}
        for i=#allJackpotNames, 1, -1 do
            local jackpotInfo = allJackpotNames[i]
            table.insert(jackpotNames, jackpotInfo)
        end

        local jackpot = jackpotNames[curColIndex]
        local jackpotIndex = 4
        local jackpotPos = 0
        local rewardCoins = 0
        if jackpot.mini then
            jackpotIndex = 4
            jackpotPos = jackpot.mini
            rewardCoins = jackpotCoins["Mini"]
        elseif jackpot.minor then
            jackpotIndex = 3
            jackpotPos = jackpot.minor
            rewardCoins = jackpotCoins["Minor"]
        elseif jackpot.major then
            jackpotIndex = 2
            jackpotPos = jackpot.major
            rewardCoins = jackpotCoins["Major"]
        elseif jackpot.grand then
            jackpotIndex = 1
            jackpotPos = jackpot.grand
            rewardCoins = jackpotCoins["Grand"]
        end
        curTotalCoins = curTotalCoins + rewardCoins
        --转换成本地
        local curJackpotRowIndex = 4 - jackpotPos

        local startNodePos = util_convertToNodeSpace(self.m_jackpotNodeMainTbl[curJackpotRowIndex], self.m_topSymbolLiZiNode)
        local endNodePos = util_convertToNodeSpace(self:findChild("Node_bar"), self.m_topSymbolLiZiNode)

        --收集反馈
        local boomNode = util_createAnimation("BadgedCowboy_bar_bd.csb")
        boomNode:setPosition(endNodePos.x, endNodePos.y)
        self.m_topSymbolLiZiNode:addChild(boomNode)
        boomNode:setVisible(false)

        --文本
        --转换成本地
        local nodeJackpotIndex = 4 - jackpotIndex + 1
        local jackpotText = self.m_jackpotNodeText[nodeJackpotIndex]
        if not tolua.isnull(jackpotText) then
            jackpotText:runCsbAction("over", false, function()
                jackpotText:removeFromParent()
            end)
        end

        local jackpotEffectNode = util_createAnimation("BadgedCowboy_jackpot_kuang_zi.csb")
        jackpotEffectNode:setPosition(startNodePos.x, startNodePos.y)
        self.m_topSymbolLiZiNode:addChild(jackpotEffectNode)
        jackpotEffectNode:runCsbAction("fly", false)
        for i=1, 4 do
            if i == jackpotIndex then
                jackpotEffectNode:findChild("jackpot_"..i):setVisible(true)
            else
                jackpotEffectNode:findChild("jackpot_"..i):setVisible(false)
            end
        end

        performWithDelay(self.m_scWaitNode, function()
            local delayTime = 30/60
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Jackpot_Collect)
            util_playMoveToAction(jackpotEffectNode, delayTime, endNodePos, function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Jackpot_Collect_FeedBack)
                boomNode:setVisible(true)
                self.m_baseFreeSpinBar:addRespinTopEndCoins(self:get_formatCoins(curTotalCoins, 3))
                boomNode:runCsbAction("actionframe1", false, function()
                    boomNode:setVisible(false)
                    jackpotEffectNode:setVisible(false)
                    local tempTbl = {}
                    tempTbl.coins = rewardCoins
                    tempTbl.index = jackpotIndex
                    tempTbl.machine = self
                    local jackPotWinView = util_createView("CodeBadgedCowboySrc.BadgedCowboyJackPotWinView")
                    self:addChild(jackPotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    jackPotWinView:initViewData(tempTbl, function()
                        curColIndex = curColIndex + 1
                        self.m_jackPotBar:playJackpotAction(jackpotIndex+1, true)
                        performWithDelay(self.m_scWaitNode, function()
                            self:addRespinJackpot(endCallFunc, curColIndex, curTotalCoins)
                        end, 0.5)
                    end)
                end)
            end)
        end, 9/60)
    else
        if type(endCallFunc) == "function" then
            endCallFunc(curTotalCoins)
        end
    end
end

function CodeGameScreenBadgedCowboyMachine:addRespinDoubleCoins(_endCallFunc)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local specialBonus = selfData.fixedSpecialScPosition
    if specialBonus and #specialBonus > 0 then
        local totalCount = #specialBonus
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Bonus_Change)
        for k, pos in pairs(specialBonus) do
            local fixPos = self:getRowAndColByPos(pos)
            local symbolNode = self.m_respinView:getRespinEndNode(fixPos.iX, fixPos.iY)
            if symbolNode then
                local doubleNode = self.m_respinDoubleNode[pos]
                if not tolua.isnull(doubleNode) then
                    doubleNode:runCsbAction("over", false, function()
                        self.m_respinDoubleNode[pos] = nil
                        doubleNode:removeFromParent()
                    end)
                end
                local curBet = globalData.slotRunData:getCurTotalBet()
                symbolNode:runAnim("switch", false, function()
                    symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_SCORE_SPECIAL_BONUS), self.SYMBOL_SCORE_SPECIAL_BONUS)
                    symbolNode:runAnim("idleframe1", true)
                    if symbolNode.p_symbolImage then
                        symbolNode.p_symbolImage:removeFromParent()
                        symbolNode.p_symbolImage = nil
                    end
                    self:setSpecialNodeScoreBonus(symbolNode, true)
                    if k == totalCount then
                        if type(_endCallFunc) == "function" then
                            _endCallFunc()
                        end
                    end
                end)
                local nodeScore = nil
                local symbol_node = symbolNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                if spineNode and spineNode.m_nodeScore then
                    nodeScore = spineNode.m_nodeScore
                end
                
                if nodeScore then
                    local sScore = ""
                    local mul = self:getReSpinBonusScore(self:getPosReelIdx(fixPos.iX, fixPos.iY))
                    if mul ~= nil and mul ~= 0 then
                        local coins = mul * curBet
                        sScore = self:get_formatCoins(coins, 3)
                    end
                    nodeScore:runCsbAction("switch", false, function()
                        nodeScore:runCsbAction("idleframe1", true)
                    end)
                    performWithDelay(self.m_scWaitNode, function()
                        for i=1, 4 do
                            local textNode = nodeScore:findChild("m_lb_coins_"..i)
                            textNode:setString(sScore)
                            self:updateLabelSize({label=textNode,sx=0.35,sy=0.35},207)
                        end
                    end, 50/60)
                end
            end
        end
        -- performWithDelay(self.m_scWaitNode, function()
        --     if type(_endCallFunc) == "function" then
        --         _endCallFunc()
        --     end
        -- end, 65/60)
    else
        if type(_endCallFunc) == "function" then
            _endCallFunc()
        end
    end
end

--ReSpin开始改变UI状态
function CodeGameScreenBadgedCowboyMachine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_baseReSpinBar, true)
    self.m_baseReSpinBar:showRespinBar(respinCount, self.m_runSpinResultData.p_reSpinsTotalCount)
end

--ReSpin刷新数量
function CodeGameScreenBadgedCowboyMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_baseReSpinBar:updateLeftCount(curCount, self.m_runSpinResultData.p_reSpinsTotalCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenBadgedCowboyMachine:changeReSpinOverUI()
    util_setCsbVisible(self.m_baseReSpinBar, false)
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenBadgedCowboyMachine:checkChangeRespinFixNode(node)
    --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
    local showOrder = self:getChangeRespinOrder(node)
    local posX, posY = node:getPosition()
    local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
    local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
    node.m_symbolTag = SYMBOL_NODE_TAG
    node.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node.m_isLastSymbol = false
    node.m_bRunEndTarge = false
    local columnData = self.m_reelColDatas[node.p_cloumnIndex]
    node.p_slotNodeH = columnData.p_showGridH
    --裁切层小块放回滚轴要调用这个
    self:changeBaseParent(node)
    node:setPosition(nodePos)
    if self:getCurSymbolIsBonus(node.p_symbolType) then
        if node ~= nil then
            node:runAnim("idleframe")
            local nodeScore = nil
            local symbol_node = node:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            if spineNode and spineNode.m_nodeScore then
                nodeScore = spineNode.m_nodeScore
            end
            
            if nodeScore then
                if node.p_symbolType == self.SYMBOL_SCORE_BONUS then
                    nodeScore:runCsbAction("idleframe", true)
                else
                    nodeScore:runCsbAction("idleframe1", true)
                end
            end
        end
    elseif node.p_symbolType == self.SYMBOL_SCORE_NULL then
        local tblRandomCcbName = {"Socre_BadgedCowboy_1", "Socre_BadgedCowboy_2", "Socre_BadgedCowboy_3", "Socre_BadgedCowboy_4", "Socre_BadgedCowboy_5"}
        local tblRandomSymbolType = {8, 7, 6, 5, 4}
        local bRandom = math.random(1, 5)
        node:changeCCBByName(tblRandomCcbName[bRandom], tblRandomSymbolType[bRandom])
        node:runAnim("idleframe")
    end
end

function CodeGameScreenBadgedCowboyMachine:respinOver()

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:showRespinOverView()
end

function CodeGameScreenBadgedCowboyMachine:showRespinOverView(effectData)
    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Respin_OverStart, 3, 0, 1)
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_OverOver)
        end, 5/60)
    end
    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    local lightAni = util_createAnimation("FreeSpinOver_tb_shine.csb")
    local view=self:showReSpinOver(strCoins,function()
        self:showCutSceneAni(function()
            for i=1, 5 do
                local respinJackpotNode = self.m_jackpotNodeMainTbl[i]
                respinJackpotNode:removeAllChildren()
            end
            self.m_jackpotNodeMainTbl = {}
            self:setReelSlotsNodeVisible(true)
            self:removeRespinNode()
            self.m_respinDoubleNode = {}
            self.m_effectFixdNode:removeAllChildren(true)
            self:changeBgSpine(1)
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg()
        end, "respinOver")
    end)
    view.m_allowClick = false
    performWithDelay(view,function ()
        view.m_allowClick = true
    end,40/60)
    view:setBtnClickFunc(cutSceneFunc)
    view:findChild("Node_guang"):addChild(lightAni)
    lightAni:runCsbAction("idle", true)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.0,sy=1.0},719)
    util_setCascadeOpacityEnabledRescursion(view, true)
    view:findChild("root"):setScale(self.m_dialogRootSccale)
end

function CodeGameScreenBadgedCowboyMachine:showBonusGameView(_effectData)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    -- self:clearCurMusicBg()

    local waitTime = 0
    self:shakeOneNodeForeverRootNode(1.2)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.scPosition then
        local scPosition = selfData.scPosition
        for k, v in pairs(scPosition) do
            local fixPos = self:getRowAndColByPos(v)
            local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then

                    local parent = slotNode:getParent()
                    if parent ~= self.m_clipParent then
                        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)
                    else
                        local m_zorder = self:getBounsScatterDataZorder(slotNode.p_symbolType, fixPos.iY, fixPos.iX)
                        slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + m_zorder)
                    end
                    slotNode:runAnim("actionframe", false, function()
                        slotNode:runAnim("idleframe1", true)
                    end)
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                end
            end
        end
    end
    self:playScatterTipMusicEffect()
    performWithDelay(self,function(  )
        self:showChooseView(_effectData)
    end,waitTime)
end

---
-- 根据Bonus Game 每关做的处理
--选择free和respin
function CodeGameScreenBadgedCowboyMachine:showChooseView(effectData)
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    self:clearCurMusicBg()
    self.m_chooseView:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Choose_startStart)
    self.m_chooseView:refreshView()
    self.m_chooseView:runCsbAction("start",false, function()
        self:setScatterIdle()
        self.m_chooseView:refreshData(endCallFunc)
        self.m_chooseView:runCsbAction("idle", true)
    end)
end

-- 显示free spin
function CodeGameScreenBadgedCowboyMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    local waitTime = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:clearWinLineEffect()
        self:shakeOneNodeForeverRootNode(1.2)
        if selfData and selfData.scatterTimes then
            local scatterTimes = selfData.scatterTimes
            local scatterTimesData = {}

            --free前展示free次数
            if scatterTimes then
                for k, v in pairs(scatterTimes) do
                    local pos = tonumber(k)
                    table.insert(scatterTimesData, pos)
                end
            end
            for k, v in pairs(scatterTimesData) do
                local fixPos = self:getRowAndColByPos(v)
                local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if slotNode then
                    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then

                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0)
                        else
                            local m_zorder = self:getBounsScatterDataZorder(slotNode.p_symbolType, fixPos.iY, fixPos.iX)
                            slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + m_zorder)
                        end
                        slotNode:runAnim("actionframe", false, function()
                            slotNode:runAnim("idleframe1", true)
                        end)
                        local duration = slotNode:getAniamDurationByName("actionframe")
                        waitTime = util_max(waitTime,duration)
                    end
                end
            end
            self:playScatterTipMusicEffect(true)

            --翻转加次数
            local scatterTimesTbl = {}

            --free前展示free次数
            if scatterTimes then
                for k, v in pairs(scatterTimes) do
                    local tempTbl = {}
                    tempTbl.pos = tonumber(k)
                    tempTbl.times = v
                    table.insert(scatterTimesTbl, tempTbl)
                end
            end
            
            performWithDelay(self,function(  )
                self:addFreeScatterEffect(function()
                    self:showFreeSpinView(effectData)
                end, scatterTimesTbl, 0)
            end,waitTime)
        end
    else
        self:showFreeSpinView(effectData)
    end
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenBadgedCowboyMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        local bgSpine = util_spineCreate("BadgedCowboy_tanban",true,true)
        self:recorverFreeScatter(true)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_More_startOver)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                performWithDelay(self.m_scWaitNode, function()
                    self:addFixedWild(true, function()
                        effectData.p_isPlay = true
                        self:playGameEffect() 
                    end)
                end, 0.5)
            end,true)
            view:findChild("Node_men"):addChild(bgSpine)
            util_spinePlay(bgSpine,"auto",true)
            view:findChild("root"):setScale(self.m_dialogRootSccale)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startStart)
            local isPlay = false
            util_spinePlay(bgSpine,"start",false)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                
            end)
            local playClickFunc = function(_auto)
                if isPlay then
                    return
                end
                isPlay = true
                if _auto then
                    view:runCsbAction("over", false, function()
                        view:removeFromParent()
                    end)
                else
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
                end
                performWithDelay(self.m_scWaitNode, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_startOver)
                end, 5/60)
                util_spinePlay(bgSpine,"over",false)
                self:showCutSceneAni(function()
                    performWithDelay(self.m_scWaitNode, function()
                        self:addFixedWild(false, function()
                            self:triggerFreeSpinCallFun()
                            effectData.p_isPlay = true
                            self:playGameEffect()  
                        end) 
                    end, 0.5)
                end, "freeStart")
            end

            view:findChild("Node_men"):addChild(bgSpine)
            view:setBtnClickFunc(playClickFunc)
            local time = view:getAnimTime("start")
            performWithDelay(view,function ()
                util_spinePlay(bgSpine,"idle",true)
            end, time)
            performWithDelay(self.m_scWaitNode,function ()
                playClickFunc(true)
            end, 5.0)
            util_setCascadeOpacityEnabledRescursion(view, true)
            view:findChild("root"):setScale(self.m_dialogRootSccale)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenBadgedCowboyMachine:showCutSceneAni(_callFunc, _cutSceneType)
    local callFunc = _callFunc
    local cutSceneType = _cutSceneType
    if cutSceneType == "freeStart" then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Fg_CutScene)
    elseif cutSceneType == "respinStart" then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Base_Respin_CutScene)
    elseif cutSceneType == "respinOver" then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Respin_Base_CutScene)
    end
    
    self.m_cutSceneSpine:setVisible(true)
    util_spinePlay(self.m_cutSceneSpine,"actionframe_guochang",false)
    util_spineEndCallFunc(self.m_cutSceneSpine, "actionframe_guochang", function()
        if type(callFunc) == "function" then
            callFunc()
        end
        self.m_cutSceneSpine:setVisible(false)
    end)
end

--弹板同时，把scatter重置
function CodeGameScreenBadgedCowboyMachine:recorverFreeScatter(_isFree)
    local isFree = _isFree
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local scPosData = nil
    if isFree then
        scPosData = selfData.scatterTimes
    else
        scPosData = selfData.scoreCoins
    end

    --free前展示free次数
    local totalTimes = 0
    if scPosData then
        for k, v in pairs(scPosData) do
            local tempTbl = {}
            local pos = tonumber(k)
            local fixPos = self:getRowAndColByPos(pos)
            local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if slotNode then
                self:removeScoreNode(slotNode)
                slotNode:runAnim("idleframe1", true)
            end
        end
    end
    for k, v in pairs(self.m_freeTimesText) do
        if not tolua.isnull(v) then
            v:removeFromParent()
            self.m_freeTimesText[k] = nil
        end
    end
    for k, v in pairs(self.m_respinCoinsText) do
        if not tolua.isnull(v) then
            v:removeFromParent()
            self.m_respinCoinsText[k] = nil
        end
    end
    self.m_freeTimesText = {}
    self.m_respinCoinsText = {}
end

--弹板结束后，固定wild
function CodeGameScreenBadgedCowboyMachine:addFixedWild(_freeMore, _endCallFunc)
    local freeMore = _freeMore
    local endCallFunc = _endCallFunc
    local specialScatterPos = nil
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if freeMore then
        if selfData and selfData.newSpecialScPosition and #selfData.newSpecialScPosition > 0 then
            specialScatterPos = selfData.newSpecialScPosition
        end
    else
        if selfData and selfData.specialScPosition and #selfData.specialScPosition > 0 then
            specialScatterPos = selfData.specialScPosition
        end
    end
    if specialScatterPos then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_Change_Wild)
        self.m_effectFixdNode:setVisible(true)
        --scatter-switch 0-53
        local delayTime = 53/30
        for k, scPos in pairs(specialScatterPos) do
            local pos = cc.p(util_getOneGameReelsTarSpPos(self, scPos))
            local fixPos = self:getRowAndColByPos(scPos)
            local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if slotNode then
                slotNode:setVisible(false)
            end
            local scatterNode = self:createBadgedCowboySymbol(self.SYMBOL_SCORE_SPECIAL_SCATTER)
            scatterNode:setPosition(pos)
            self.m_effectFixdNode:addChild(scatterNode,scPos)

            local topWildNode = self:createBadgedCowboySymbol(self.SYMBOL_SCORE_SPECIAL_WILD)
            topWildNode:setVisible(false)
            topWildNode:setPosition(pos)
            self.m_effectFixdNode:addChild(topWildNode,scPos)
            
            scatterNode:runAnim("switch", false, function()
                scatterNode:setVisible(false)
                topWildNode:setVisible(true)
                topWildNode:runAnim("idleframe", true)
            end)
        end
        performWithDelay(self.m_scWaitNode, function()
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        end, delayTime)
    else
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end
end

--断线回来添加固定wild
function CodeGameScreenBadgedCowboyMachine:addFixedWildToInitGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.specialScPosition and #selfData.specialScPosition > 0 then
        --scatter-switch 0-53
        local specialScatterPos = selfData.specialScPosition
        local delayTime = 53/30
        for k, scPos in pairs(specialScatterPos) do
            local pos = cc.p(util_getOneGameReelsTarSpPos(self, scPos))
            local fixPos = self:getRowAndColByPos(scPos)

            local topWildNode = self:createBadgedCowboySymbol(self.SYMBOL_SCORE_SPECIAL_WILD)
            topWildNode:setPosition(pos)
            self.m_effectFixdNode:addChild(topWildNode,scPos)
            topWildNode:runAnim("idleframe", true)
        end
    end
end

function CodeGameScreenBadgedCowboyMachine:showFreeSpinOverView()

    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_overStart, 3, 0, 1)
    local cutSceneFunc = function()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Normal_Click)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_overOver)
        end, 5/60)
    end
    if globalData.slotRunData.lastWinCoin > 0 then
        local lightAni = util_createAnimation("FreeSpinOver_tb_shine.csb")
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:clearWinLineEffect()
                self:showCutSceneOverAni(function()
                    self.m_effectFixdNode:removeAllChildren(true)
                    self:changeBgSpine(1)
                    self:triggerFreeSpinOverCallFun()
                end)
            end)

        view.m_allowClick = false
        performWithDelay(view,function ()
            view.m_allowClick = true
        end,40/60)
        view:setBtnClickFunc(cutSceneFunc)
        local node=view:findChild("m_lb_coins")
        view:findChild("Node_guang"):addChild(lightAni)
        lightAni:runCsbAction("idle", true)
        view:updateLabelSize({label=node,sx=1.0,sy=1.0},719)
        util_setCascadeOpacityEnabledRescursion(view, true)
        view:findChild("root"):setScale(self.m_dialogRootSccale)
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:showCutSceneOverAni(function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)
        view:findChild("root"):setScale(self.m_dialogRootSccale)
        view:setBtnClickFunc(cutSceneFunc)
    end
end

function CodeGameScreenBadgedCowboyMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FreeSpinOver_NoWin",nil,_func)
    return view
end

function CodeGameScreenBadgedCowboyMachine:showCutSceneOverAni(_callFunc)
    local callFunc = _callFunc
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_Base_CutScene)
    self.m_cutSceneSpine:setVisible(true)
    util_spinePlay(self.m_cutSceneSpine,"actionframe_guochang2",false)
    util_spineEndCallFunc(self.m_cutSceneSpine, "actionframe_guochang2", function()
        self.m_cutSceneSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

function CodeGameScreenBadgedCowboyMachine:createBadgedCowboySymbol(_symbolType)
    local symbol = util_createView("CodeBadgedCowboySrc.BadgedCowboySymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenBadgedCowboyMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    -- util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenBadgedCowboyMachine:getCurSymbolIsBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_BONUS or symbolType == self.SYMBOL_SCORE_SPECIAL_BONUS then
        return true
    end
    return false
end

function CodeGameScreenBadgedCowboyMachine:getMaxContinuityBonusCol()
    local maxColIndex = 0
    local isContinuity = true
    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
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

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBadgedCowboyMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenBadgedCowboyMachine:beginReel()
    self.m_triggerBigWinEffect = false
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 刷新wild
        self.m_effectFixdNode:removeAllChildren(true)
    else
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local specialScPosition = selfData.specialScPosition
        for k, index in pairs(specialScPosition) do
            local startPos = self:getRowAndColByPos(tonumber(index))
            -- 信号类型
            local symbolType = self:getMatrixPosSymbolType(startPos.iX, startPos.iY)
            if symbolType then
                local fixNode = self:getFixSymbol(startPos.iY , startPos.iX)
                -- fixNode必须判断
                if fixNode then
                    fixNode:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                    fixNode:setLocalZOrder(self:getBounsScatterDataZorder(symbolType) - fixNode.p_rowIndex)

                    if fixNode.p_symbolImage then
                        fixNode.p_symbolImage:removeFromParent()
                        fixNode.p_symbolImage = nil
                    end
                    fixNode:runIdleAnim()
                end
            end
        end
        self.m_effectFixdNode:setVisible(true)
    end
    CodeGameScreenBadgedCowboyMachine.super.beginReel(self)
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBadgedCowboyMachine:addSelfEffect()
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData

    if self:getCurrSpinMode() == FREE_SPIN_MODE and selfData.jackpotResult then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_JACKPOT_PLAY
        effectData.p_selfEffectType = self.EFFECT_JACKPOT_PLAY
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBadgedCowboyMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_ADD_WILD then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local scatterTimes = selfData.scatterTimes
        local scatterTimesTbl = {}

        --free前展示free次数
        if scatterTimes then
            for k, v in pairs(scatterTimes) do
                local tempTbl = {}
                tempTbl.pos = tonumber(k)
                tempTbl.times = v
                table.insert(scatterTimesTbl, tempTbl)
            end
        end
        self.m_baseFreeSpinBar:setFreeAni()
        performWithDelay(self.m_scWaitNode, function()
            self:addFreeScatterEffect(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, scatterTimesTbl, 0)
        end, 0.5)
    elseif effectData.p_selfEffectType == self.EFFECT_ADD_BONUS then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local scoreCoins = selfData.scoreCoins
        local scoreCoinsTbl = {}

        --free前展示free次数
        local totalTimes = 0
        if scoreCoins then
            for k, v in pairs(scoreCoins) do
                local tempTbl = {}
                tempTbl.pos = tonumber(k)
                tempTbl.coins = v
                table.insert(scoreCoinsTbl, tempTbl)
            end
        end
        self.m_baseFreeSpinBar:setRespinAni()
        performWithDelay(self.m_scWaitNode, function()
            self:addRespinScatterEffect(effectData, scoreCoinsTbl, 0, 0)
        end, 0.5)
    elseif effectData.p_selfEffectType == self.EFFECT_JACKPOT_PLAY then
        performWithDelay(self.m_scWaitNode, function()
            self:addFreeJackpot(1, function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end, 0.5)
    end
    
    return true
end

--翻转前全部变成idleframe
function CodeGameScreenBadgedCowboyMachine:setScatterIdle()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.scPosition then
        local scPosition = selfData.scPosition
        for k, v in pairs(scPosition) do
            local fixPos = self:getRowAndColByPos(v)
            local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if slotNode then
                slotNode:runAnim("idleframe", true)
            end
        end
    end
end

--递归添加sc翻转动画加钱数
function CodeGameScreenBadgedCowboyMachine:addRespinScatterEffect(_effectData, _scoreCoinsTbl, _curIndex)
    local effectData = _effectData
    local scoreCoinsTbl = _scoreCoinsTbl
    local curIndex = _curIndex + 1
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    local symbolNodePos = self.m_symbolNodeRandom[curIndex]
    local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
    if curIndex > symbolTotalNum then
        performWithDelay(self.m_scWaitNode, function()
            self:addSctterCoinsToTop(effectData, scoreCoinsTbl, 0, 0)
        end, 0.5)
        return
    end

    local curScatterInfo = nil
    for i = 1, #scoreCoinsTbl do
        local pos = scoreCoinsTbl[i].pos
        if pos+1 == symbolNodePos then
            curScatterInfo = scoreCoinsTbl[i]
            break
        end
    end

    local waitTime = 0
    if curScatterInfo then
        local pos = curScatterInfo.pos
        local coins = curScatterInfo.coins
        local sScore = self:get_formatCoins(coins, 3)
        local fixPos = self:getRowAndColByPos(pos)
        local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if slotNode then
            local symbol_node = slotNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_Flip)
            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local scCoinsText = util_createAnimation("BadgedCowboy_ScCoins.csb")
                local textNode = scCoinsText:findChild("m_lb_coins")
                textNode:setString(sScore)
                self:updateLabelSize({label=textNode,sx=1.0,sy=1.0},207)
                scCoinsText:setPosition(cc.p(3, -2))
                util_spinePushBindNode(spineNode,"zi3",scCoinsText)
                spineNode.m_nodeScore = scCoinsText
                table.insert(self.m_respinCoinsText, scCoinsText)
                slotNode:runAnim("actionframe1", false, function()
                    slotNode:runAnim("idleframe2", true)
                end)
                local duration = slotNode:getAniamDurationByName("actionframe1")
                waitTime = util_max(waitTime,duration)
            elseif slotNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
                local scCoinsText = util_createAnimation("BadgedCowboy_SpecialScCoins.csb")
                local textNode = scCoinsText:findChild("m_lb_coins")
                textNode:setString(sScore)
                self:updateLabelSize({label=textNode,sx=1.0,sy=1.0},207)
                scCoinsText:setPosition(cc.p(3, -2))
                util_spinePushBindNode(spineNode,"zi2",scCoinsText)
                spineNode.m_nodeScore = scCoinsText
                table.insert(self.m_respinCoinsText, scCoinsText)
                slotNode:runAnim("actionframe1", false, function()
                    slotNode:runAnim("idleframe2", true)
                end)
                local duration = slotNode:getAniamDurationByName("actionframe1")
                waitTime = util_max(waitTime,duration)
            end
            performWithDelay(self.m_scWaitNode, function()
                self:addRespinScatterEffect(effectData, scoreCoinsTbl, curIndex)
            end, 0.7)--35/30
        else
            self:addRespinScatterEffect(effectData, scoreCoinsTbl, curIndex)
        end
    else
        self:addRespinScatterEffect(effectData, scoreCoinsTbl, curIndex)
    end
end

--递归，顶部加钱数
function CodeGameScreenBadgedCowboyMachine:addSctterCoinsToTop(_effectData, _scoreCoinsTbl, _curTotalCoins, _curIndex)
    local effectData = _effectData
    local scoreCoinsTbl = _scoreCoinsTbl
    local curTotalCoins = _curTotalCoins
    local curIndex = _curIndex + 1
    local symbolNodePos = self.m_symbolNodeRandom[curIndex]

    local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
    if curIndex > symbolTotalNum then
        performWithDelay(self.m_scWaitNode, function()
            self.m_topSymbolLiZiNode:removeAllChildren()
            if effectData then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end, 0.5)
        return
    end

    local curScatterInfo = nil
    for i = 1, #scoreCoinsTbl do
        local pos = scoreCoinsTbl[i].pos
        if pos+1 == symbolNodePos then
            curScatterInfo = scoreCoinsTbl[i]
            break
        end
    end

    if curScatterInfo then
        local pos = curScatterInfo.pos
        local coins = curScatterInfo.coins
        curTotalCoins = curTotalCoins + coins
        local fixPos = self:getRowAndColByPos(pos)
        local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if slotNode then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_ScatterRs_Collect)
            local startNodePos, endNodePos = self:getParticleFlyPos(pos)
            --收集反馈
            local boomNode = util_createAnimation("BadgedCowboy_bar_bd.csb")
            boomNode:setPosition(endNodePos.x, endNodePos.y)
            self.m_topSymbolLiZiNode:addChild(boomNode)
            boomNode:setVisible(false)

            slotNode:runAnim("fly", false, function()
                slotNode:runAnim("idleframe2", true)
            end)

            --飞行粒子
            local flyNode = util_createAnimation("BadgedCowboy_shouji_lizi.csb")
            flyNode:setPosition(startNodePos.x, startNodePos.y)
            self.m_topSymbolLiZiNode:addChild(flyNode)

            local particleDelayTime = 0.3
            local m_particleTbl = {}
            for i = 1, 3 do
                m_particleTbl[i] = flyNode:findChild("Particle_"..i)
                m_particleTbl[i]:setPositionType(0)
                m_particleTbl[i]:setDuration(-1)
                m_particleTbl[i]:resetSystem()
            end

            util_playMoveToAction(flyNode, particleDelayTime, endNodePos, function()
                for i = 1, 3 do
                    m_particleTbl[i]:stopSystem()
                end
                boomNode:setVisible(true)
                self.m_baseFreeSpinBar:addRespinTopCoins(self:get_formatCoins(curTotalCoins, 3))
                gLobalSoundManager:playSound(self.m_publicConfig.Music_ScatterRs_CollectFeedBack)
                boomNode:runCsbAction("actionframe", false, function()
                    boomNode:setVisible(false)
                    flyNode:setVisible(false)
                end)
            end)
            performWithDelay(self.m_scWaitNode, function()
                self:addSctterCoinsToTop(effectData, scoreCoinsTbl, curTotalCoins, curIndex)
            end, 0.5)
        else
            self:addSctterCoinsToTop(effectData, scoreCoinsTbl, curTotalCoins, curIndex)
        end
    else
        self:addSctterCoinsToTop(effectData, scoreCoinsTbl, curTotalCoins, curIndex)
    end
end

--递归添加sc翻转动画加字体次数
function CodeGameScreenBadgedCowboyMachine:addFreeScatterEffect(_endCallFunc, _scatterTimesTbl, _curIndex)
    local endCallFunc = _endCallFunc
    local scatterTimesTbl = _scatterTimesTbl
    local curIndex = _curIndex + 1

    local symbolNodePos = self.m_symbolNodeRandom[curIndex]
    local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
    if curIndex > symbolTotalNum then
        performWithDelay(self.m_scWaitNode, function()
            local curRemainFreeCount = 0
            if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinNewCount then
                curRemainFreeCount = self.m_runSpinResultData.p_freeSpinsLeftCount - self.m_runSpinResultData.p_freeSpinNewCount
            end
            self:addSctterTimesToTop(endCallFunc, scatterTimesTbl, curRemainFreeCount, 0)
        end, 0.5)
        return
    end

    local curScatterInfo = nil
    for i = 1, #scatterTimesTbl do
        local pos = scatterTimesTbl[i].pos
        if pos+1 == symbolNodePos then
            curScatterInfo = scatterTimesTbl[i]
            break
        end
    end

    local waitTime = 0
    if curScatterInfo then
        local pos = curScatterInfo.pos
        local times = curScatterInfo.times
        local fixPos = self:getRowAndColByPos(pos)
        local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if slotNode then
            local symbol_node = slotNode:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_Flip)
            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local scTimeText = util_createAnimation("BadgedCowboy_ScTimes.csb")
                scTimeText:findChild("m_lb_count"):setString(times)
                scTimeText:findChild("games"):setVisible(times > 1)
                scTimeText:findChild("game"):setVisible(times == 1)
                scTimeText:setPosition(cc.p(2, -5))
                util_spinePushBindNode(spineNode,"zi3",scTimeText)
                spineNode.m_nodeScore = scTimeText
                table.insert(self.m_freeTimesText, scTimeText)
                slotNode:runAnim("actionframe1", false, function()
                    slotNode:runAnim("idleframe2", true)
                end)
                local duration = slotNode:getAniamDurationByName("actionframe1")
                waitTime = util_max(waitTime,duration)
            elseif slotNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
                local scTimeText = util_createAnimation("BadgedCowboy_SpecialScTimes.csb")
                scTimeText:findChild("m_lb_count"):setString(times)
                scTimeText:findChild("games"):setVisible(times > 1)
                scTimeText:findChild("game"):setVisible(times == 1)
                scTimeText:setPosition(cc.p(2, -5))
                util_spinePushBindNode(spineNode,"zi2",scTimeText)
                spineNode.m_nodeScore = scTimeText
                table.insert(self.m_freeTimesText, scTimeText)
                slotNode:runAnim("actionframe1", false, function()
                    slotNode:runAnim("idleframe2", true)
                end)
                local duration = slotNode:getAniamDurationByName("actionframe1")
                waitTime = util_max(waitTime,duration)
            end
            performWithDelay(self.m_scWaitNode, function()
                self:addFreeScatterEffect(endCallFunc, scatterTimesTbl, curIndex)
            end, 0.7)--35/30
        else
            self:addFreeScatterEffect(endCallFunc, scatterTimesTbl, curIndex)
        end
    else
        self:addFreeScatterEffect(endCallFunc, scatterTimesTbl, curIndex)
    end
end

--递归，顶部加次数
function CodeGameScreenBadgedCowboyMachine:addSctterTimesToTop(_endCallFunc, _scatterTimesTbl, _curTotalTimes, _curIndex)
    local endCallFunc = _endCallFunc
    local scatterTimesTbl = _scatterTimesTbl
    local curTotalTimes = _curTotalTimes
    local curIndex = _curIndex + 1
    local symbolNodePos = self.m_symbolNodeRandom[curIndex]

    local symbolTotalNum = self.m_iReelRowNum*self.m_iReelColumnNum
    if curIndex > symbolTotalNum then
        performWithDelay(self.m_scWaitNode, function()
            self.m_topSymbolLiZiNode:removeAllChildren()
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        end, 0.5)
        return
    end

    local curScatterInfo = nil
    for i = 1, #scatterTimesTbl do
        local pos = scatterTimesTbl[i].pos
        if pos+1 == symbolNodePos then
            curScatterInfo = scatterTimesTbl[i]
            break
        end
    end

    if curScatterInfo then
        local pos = curScatterInfo.pos
        local times = curScatterInfo.times
        curTotalTimes = curTotalTimes + times
        local fixPos = self:getRowAndColByPos(pos)
        local slotNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if slotNode then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_ScatterFg_Collect)
            local startNodePos, endNodePos = self:getParticleFlyPos(pos)
            --收集反馈
            local boomNode = util_createAnimation("BadgedCowboy_bar_bd.csb")
            boomNode:setPosition(endNodePos.x, endNodePos.y)
            self.m_topSymbolLiZiNode:addChild(boomNode)
            boomNode:setVisible(false)

            slotNode:runAnim("fly", false, function()
                slotNode:runAnim("idleframe2", true)
            end)

            --飞行粒子
            local flyNode = util_createAnimation("BadgedCowboy_shouji_lizi.csb")
            flyNode:setPosition(startNodePos.x, startNodePos.y)
            self.m_topSymbolLiZiNode:addChild(flyNode)

            local particleDelayTime = 0.3
            local m_particleTbl = {}
            for i = 1, 3 do
                m_particleTbl[i] = flyNode:findChild("Particle_"..i)
                m_particleTbl[i]:setPositionType(0)
                m_particleTbl[i]:setDuration(-1)
                m_particleTbl[i]:resetSystem()
            end

            util_playMoveToAction(flyNode, particleDelayTime, endNodePos, function()
                for i = 1, 3 do
                    m_particleTbl[i]:stopSystem()
                end
                boomNode:setVisible(true)
                self.m_baseFreeSpinBar:addFreeTopLeftCount(curTotalTimes)
                gLobalSoundManager:playSound(self.m_publicConfig.Music_ScatterFg_CollectFeedBack)
                boomNode:runCsbAction("actionframe", false, function()
                    boomNode:setVisible(false)
                    flyNode:setVisible(false)
                end)
            end)
            performWithDelay(self.m_scWaitNode, function()
                self:addSctterTimesToTop(endCallFunc, scatterTimesTbl, curTotalTimes, curIndex)
            end, 0.5)
        else
            self:addSctterTimesToTop(endCallFunc, scatterTimesTbl, curTotalTimes, curIndex)
        end
    else
        self:addSctterTimesToTop(endCallFunc, scatterTimesTbl, curTotalTimes, curIndex)
    end
end

function CodeGameScreenBadgedCowboyMachine:addFreeJackpot(_curIndex, _endCallFunc)
    local curIndex = _curIndex
    local endCallFunc = _endCallFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpotResult = selfData.jackpotResult
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins
    self.m_jackPotBar:playJackpotIdle()

    if jackpotResult and #jackpotResult > 0 then
        local totalCount = #jackpotResult
        if curIndex > totalCount then
            if not self:checkHasBigWin() then
                self:checkNotifyUpdateWinCoin(true)
                --检测大赢
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS, true)
            end
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
            return
        end

        local jackpot = jackpotResult[curIndex]
        local jackpotIndex = 4
        local jackpotPos = 0
        local rewardCoins = 0
        local actionName = "jackpot5_actionframe"
        local actionName2 = "jackpot5_actionframe2"
        local idleName = "jackpot5_idleframe"
        local overName = "jackpot5_over"
        if jackpot.mini then
            jackpotIndex = 4
            jackpotPos = jackpot.mini
            rewardCoins = jackpotCoins["Mini"]
            actionName = "jackpot5_actionframe"
            actionName2 = "jackpot5_actionframe2"
            idleName = "jackpot5_idleframe"
            overName = "jackpot5_over"
        elseif jackpot.minor then
            jackpotIndex = 3
            jackpotPos = jackpot.minor
            rewardCoins = jackpotCoins["Minor"]
            actionName = "jackpot4_actionframe"
            actionName2 = "jackpot4_actionframe2"
            idleName = "jackpot4_idleframe"
            overName = "jackpot4_over"
        elseif jackpot.major then
            jackpotIndex = 2
            jackpotPos = jackpot.major
            rewardCoins = jackpotCoins["Major"]
            actionName = "jackpot3_actionframe"
            actionName2 = "jackpot3_actionframe2"
            idleName = "jackpot3_idleframe"
            overName = "jackpot3_over"
        elseif jackpot.grand then
            jackpotIndex = 1
            jackpotPos = jackpot.grand
            rewardCoins = jackpotCoins["Grand"]
            actionName = "jackpot2_actionframe"
            actionName2 = "jackpot2_actionframe2"
            idleName = "jackpot2_idleframe"
            overName = "jackpot2_over"
        end
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_JackpotTrigger)
        local fixPos = self:getRowAndColByPos(jackpotPos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        if symbolNode then
            symbolNode:runAnim("actionframe", false, function()
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Free_JackpotFlip)
                self.m_jackpotTopSpine:setVisible(true)
                self.m_jackpotTopSpine:runAnim(actionName, false, function()
                    symbolNode:runAnim(idleName, true)
                    self.m_jackPotBar:playJackpotAction(jackpotIndex)
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Jackpot_Twinkle)
                    self.m_jackpotTopSpine:runAnim(overName, false, function()
                        gLobalSoundManager:playSound(self.m_publicConfig.Music_Jackpot_BigScale)
                        symbolNode:runAnim(actionName2, false, function()
                            symbolNode:runAnim(idleName, true)
                            local tempTbl = {}
                            tempTbl.coins = rewardCoins
                            tempTbl.index = jackpotIndex
                            tempTbl.machine = self
                            -- self:shakeRootNode(8)
                            local jackPotWinView = util_createView("CodeBadgedCowboySrc.BadgedCowboyJackPotWinView")
                            self:addChild(jackPotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                            jackPotWinView:initViewData(tempTbl, function()
                                curIndex = curIndex + 1
                                self:addFreeJackpot(curIndex, endCallFunc)
                            end)
                        end)
                        self.m_jackpotTopSpine:setVisible(false)
                    end)
                end)
            end)
        end
    else
        if type(endCallFunc) == "function" then
            endCallFunc()
        end
    end
end

function CodeGameScreenBadgedCowboyMachine:shakeRootNode(_count)

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1, _count do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)
end

-- shake
function CodeGameScreenBadgedCowboyMachine:shakeOneNodeForeverRootNode(time)
    
    self.m_gobalTouchLayer:setTouchEnabled(true)
    self.m_gobalTouchLayer:setSwallowTouches(true)

    local time2 = 0.07
    local time1 = math.max(0, time - time2)

    local root_shake = self
    local root_scale = self:getParent()

    local oldPos = cc.p(root_shake:getPosition())
    local oldRootPos = cc.p(root_scale:getPosition())
    local oldScale = root_scale:getScale()
    local changePosY = math.random( 1, 3)
    local changePosX = math.random( 1, 3)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    root_shake:runAction(action)

    local action1 = cc.ScaleTo:create(time1, 1.15)
    root_scale:runAction(action1)

    performWithDelay(self.m_scWaitNode,function()
        root_shake:stopAction(action)
        root_scale:stopAction(action1)
        root_shake:setPosition(oldPos)
        root_scale:setPosition(oldRootPos)
        
        local actionOver = cc.ScaleTo:create(time2, oldScale)
        root_scale:runAction(actionOver)
        performWithDelay(self,function()
            root_scale:stopAction(actionOver)
            root_scale:setScale(oldScale)
            if self.m_gobalTouchLayer then
                self.m_gobalTouchLayer:setTouchEnabled(false)
                self.m_gobalTouchLayer:setSwallowTouches(false)
            end
        end, time2)
    end, time1)
end

--获取飞行起始位置
function CodeGameScreenBadgedCowboyMachine:getParticleFlyPos(_symbolPos)
    --粒子飞行
    local startClipTarPos = util_getOneGameReelsTarSpPos(self, _symbolPos)
    local startWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(startClipTarPos))
    local startNodePos = self.m_topSymbolLiZiNode:convertToNodeSpace(startWorldPos)
    local endNodePos = util_convertToNodeSpace(self:findChild("Node_bar"), self.m_topSymbolLiZiNode)
    return startNodePos, endNodePos
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenBadgedCowboyMachine:checkHasGameEffect(effectType)
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

function CodeGameScreenBadgedCowboyMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenBadgedCowboyMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenBadgedCowboyMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenBadgedCowboyMachine.super.slotReelDown(self)
end

function CodeGameScreenBadgedCowboyMachine:updateReelGridNode(_symbolNode)

    if self:getCurSymbolIsBonus(_symbolNode.p_symbolType) then
        self:setSpecialNodeScoreBonus(_symbolNode)
    end
end

function CodeGameScreenBadgedCowboyMachine:setSpecialNodeScoreBonus(_symbolNode, _respinDouble)
    local symbolNode = _symbolNode
    local respinDouble = _respinDouble
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType  then
        return
    end

    local curBet = globalData.slotRunData:getCurTotalBet()
    local sScore = ""
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeScore, mul

    if not tolua.isnull(spineNode.m_nodeScore) then
        nodeScore = spineNode.m_nodeScore
    else
        nodeScore = util_createAnimation("BadgedCowboy_BonusCoins.csb")
        nodeScore:setPosition(cc.p(3, -2))
        util_spinePushBindNode(spineNode,"zi",nodeScore)
        spineNode.m_nodeScore = nodeScore
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.resScore then
        sScore = self:get_formatCoins(selfData.resScore, 3)
    end

    if symbolNode.m_isLastSymbol == true and symbolNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_BONUS then
        mul = self:getReSpinBonusScore(self:getPosReelIdx(iRow, iCol))
        if mul ~= nil and mul ~= 0 then
            local coins = mul * curBet
            sScore = self:get_formatCoins(coins, 3)
        end
    end
    -- if symbolNode.m_isLastSymbol == true then
    --     mul = self:getReSpinBonusScore(self:getPosReelIdx(iRow, iCol))
    --     if mul ~= nil and mul ~= 0 then
    --         local coins = mul * curBet
    --         sScore = util_formatCoins(coins, 3)
    --     end
    -- else
    --     local selfData = self.m_runSpinResultData.p_selfMakeData
    --     if selfData and selfData.resScore then
    --         sScore = util_formatCoins(selfData.resScore, 3)
    --     end
    -- end
    local textNode, textHighNode
    if nodeScore then
        for i=1, 4 do
            local textNode = nodeScore:findChild("m_lb_coins_"..i)
            textNode:setString(sScore)
            self:updateLabelSize({label=textNode,sx=0.35,sy=0.35},207)
        end
        util_resetCsbAction(nodeScore.m_csbAct)
        if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS then
            nodeScore:runCsbAction("idleframe", true)
        else
            nodeScore:runCsbAction("idleframe1", true)
        end
    end
end

function CodeGameScreenBadgedCowboyMachine:removeScoreNode(_symbolNode)
    local symbolNode = _symbolNode
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if spineNode and spineNode.m_nodeScore then
        local nodeScore = spineNode.m_nodeScore
        util_spineRemoveBindNode(spineNode, nodeScore)
    end
end

function CodeGameScreenBadgedCowboyMachine:get_formatCoins(coins, obligate, notCut, normal, noRounding, useRealObligate)
    local obK = math.pow(10, 3)
    if type(coins) ~= "number" then
        return coins
    end
    --不需要限制的直接返回
    if obligate < 1 then
        return coins
    end

    --是否添加分割符
    local isCut = true
    if notCut then
        isCut = false
    end

    local str_coins = nil
    coins = tonumber(coins + 0.00001)
    local nCoins = math.floor(coins)
    local count = math.floor(math.log10(nCoins)) + 1
    if count <= obligate then
        str_coins = util_cutCoins(nCoins, isCut, nil, noRounding)
    else
        if count < 3 then
            str_coins = util_cutCoins(nCoins / obK, isCut, nil, noRounding) .. "K"
        else
            local tCoins = nCoins
            local tNum = 0
            local units = {"K", "M", "B", "T"}
            local cell = 1000
            local index = 0
            while (1) do
                index = index + 1
                if index > 4 then
                    return util_cutCoins(tCoins, isCut, nil, noRounding) .. units[4]
                end
                tNum = tCoins % cell
                tCoins = tCoins / cell
                local num = math.floor(math.log10(tCoins)) + 1
                if num <= obligate then
                    --应该保留的小数位
                    local floatNum = obligate - num
                    if normal then
                        return util_cutCoins(tCoins, isCut, floatNum, noRounding) .. units[index]
                    end
                    if not useRealObligate then
                        --保留1位小数
                        if num == 1 and floatNum > 0 then
                            floatNum = 2
                        else
                            --正常模式不保留小数
                            floatNum = 0
                        end
                    end
                    return util_cutCoins(tCoins, isCut, floatNum, noRounding) .. units[index]
                end
            end
        end
    end
    return str_coins
end

--[[
    获取小块真实分数
]]
function CodeGameScreenBadgedCowboyMachine:getReSpinBonusScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil
    if not storedIcons then
        return
    end

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
            break
        end
    end

    return score
end
--[[
    随机bonus分数
]]
function CodeGameScreenBadgedCowboyMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_SCORE_BONUS then
        score = self.m_configData:getBnBasePro(1)
    end

    return score
end

-- 播放预告中奖统一接口
-- 子类重写接口
function CodeGameScreenBadgedCowboyMachine:showFeatureGameTip(_func)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        local randomNum = math.random(1, 10)
        if randomNum <= 4 then
            self.b_gameTipFlag = true
        end
        -- self.b_gameTipFlag = true
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        _func()
    else
        if self.b_gameTipFlag then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_YuGao_Sound)
            self.m_yuGao:setVisible(true)
            self.m_yuGao:runCsbAction("actionframe", false, function()
                _func()
            end)
        else
            _func() 
        end
    end
end

function CodeGameScreenBadgedCowboyMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin；3.respin
    local bgSpineName = {"base", "free", "respin"}
    util_spinePlay(self.m_baseBgSpine,bgSpineName[_bgType],true)

    --freeBar相关
    self.m_baseFreeSpinBar:setVisible(true)
    if _bgType == 1 then
        self.m_baseFreeSpinBar:runCsbAction("idle", true)
        self.m_lineNode:setVisible(true)
    elseif _bgType == 2 then
        self.m_baseFreeSpinBar:runCsbAction("idle1", true)
        self.m_lineNode:setVisible(true)
    else
        self.m_baseFreeSpinBar:runCsbAction("idle2", true)
        self.m_lineNode:setVisible(false)
    end
    self:setReelBgState(_bgType)
end

function CodeGameScreenBadgedCowboyMachine:setReelBgState(_bgType)
    if _bgType == 1 then
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
    elseif _bgType == 2 then
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(false)
    elseif _bgType == 3 then
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(false)
    end
end

function CodeGameScreenBadgedCowboyMachine:addPlayEffect()
    local featureDatas = self.m_runSpinResultData.p_features or {}
    if not featureDatas then
        return
    end

    for i = 1, #featureDatas do
        local featureId = featureDatas[i]
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            self:resetMusicBg(nil, self.m_publicConfig.Music_FG_Bg)
            --添加固定wild事件
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_ADD_WILD
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_ADD_WILD -- 动画类型
            
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
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then
            self:resetMusicBg(nil, self.m_publicConfig.Music_Respin_Bg)
            --添加固定bonus事件
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_ADD_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_ADD_BONUS -- 动画类型

            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
            -- if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
            --     self:normalSpinBtnCall()
            -- end
        end
    end
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenBadgedCowboyMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
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

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect()
        self:addRewaedFreeSpinOverEffect()
    end
end

function CodeGameScreenBadgedCowboyMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

function CodeGameScreenBadgedCowboyMachine:checkNotifyUpdateWinCoin(_isJackpot)
    local winLines = self.m_reelResultLines

    if #winLines <= 0 and not _isJackpot then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenBadgedCowboyMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenBadgedCowboyMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenBadgedCowboyMachine:symbolBulingEndCallBack(node)
    local maxCol = self:getMaxContinuityBonusCol()
    if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or node.p_symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER) then
        node:runAnim("idleframe1", true)
    elseif node.p_symbolType and node.p_symbolType == self.SYMBOL_SCORE_BONUS then
        node:runAnim("idleframe1", true)
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenBadgedCowboyMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType ~= self.SYMBOL_SCORE_JACKPOT then
                local maxCol = self:getMaxContinuityBonusCol()
                if _slotNode.p_cloumnIndex > maxCol then
                    return false
                end
                return true
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
            -- if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
            --     return true
            -- else
            --     -- 不为 scatter 和 bonus 时 不走快滚判断
            --     return true
            -- end
        end
    end

    return false
end

function CodeGameScreenBadgedCowboyMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local nodeList = {}
    for k,_slotNode in pairs(slotNodeList) do
        if _slotNode.p_symbolType then
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_SCORE_SPECIAL_SCATTER then
                if _slotNode.p_cloumnIndex <= self:getMaxContinuityBonusCol() then
                    table.insert( nodeList, _slotNode)
                end
            elseif _slotNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT then
                table.insert( nodeList, _slotNode)
            end
        end
    end
    CodeGameScreenBadgedCowboyMachine.super.playSymbolBulingAnim(self,nodeList, speedActionTable)
end

function CodeGameScreenBadgedCowboyMachine:playScatterTipMusicEffect(_isFreeMore)
    if _isFreeMore then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_FreeGame_TriggerFree)
    else
        if self.m_ScatterTipMusicPath ~= nil then
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

function CodeGameScreenBadgedCowboyMachine:lineLogicWinLines()
    local isFiveOfKind = CodeGameScreenBadgedCowboyMachine.super.lineLogicWinLines(self)
    isFiveOfKind = false
    return isFiveOfKind
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenBadgedCowboyMachine:showEffect_runBigWinLightAni(effectData)
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
function CodeGameScreenBadgedCowboyMachine:showBigWinLight(_func)
    local func = _func

    self.m_bigWinSpine:setVisible(true)
    self.m_bigWinAni:setVisible(true)
    self.m_bigwinEffectNum:setVisible(true)
    for i=1, 4 do
        self.particleTbl[i]:resetSystem()
    end
    util_spinePlay(self.m_bigWinSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe", function()
        for i=1, 4 do
            self.particleTbl[i]:stopSystem()
        end
        self.m_bigWinSpine:setVisible(false)
        self.m_bigWinAni:setVisible(false)
    end)

    local winCoins = self.m_runSpinResultData.p_winAmount
    local coinsText = self.m_bigwinEffectNum:findChild("m_lb_coins")
    if winCoins then
        local strCoins = "+" .. util_formatCoins(winCoins, 15)
        coinsText:setVisible(true)

        local curCoins = 0
        local coinRiseNum =  winCoins / (1.5 * 60)  -- 每秒60帧
        local curRiseStrCoins = "+" .. util_formatCoins(coinRiseNum, 15)
        coinsText:setString(curRiseStrCoins)

        self.m_scWaitNodeAction:stopAllActions()
        util_schedule(self.m_scWaitNodeAction, function()
            curCoins = curCoins + coinRiseNum
            if curCoins >= winCoins then
                coinsText:setString(strCoins)
                performWithDelay(self.m_scWaitNode, function()
                    self.m_bigwinEffectNum:runCsbAction("over",false, function()
                        self.m_bigwinEffectNum:setVisible(false)
                    end)
                    if self.m_winSoundsId then
                        gLobalSoundManager:stopAudio(self.m_winSoundsId)
                        self.m_winSoundsId = nil
                    end
                    if type(func) == "function" then
                        func()
                    end
                end, 0.5)
                self.m_scWaitNodeAction:stopAllActions()
            else
                local curStrCoins = "+" .. util_formatCoins(curCoins, 15)
                coinsText:setString(curStrCoins)
            end
        end, 1/60)
    end
    self.m_bigwinEffectNum:runCsbAction("start",false, function()
        self.m_bigwinEffectNum:runCsbAction("idle", true)
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Celebrate_Win)
    self:shakeRootNode(10)
end

return CodeGameScreenBadgedCowboyMachine






