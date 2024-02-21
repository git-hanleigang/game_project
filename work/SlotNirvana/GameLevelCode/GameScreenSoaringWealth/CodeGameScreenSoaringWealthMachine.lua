---
-- island li
-- 2019年1月26日
-- CodeGameScreenSoaringWealthMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local SoaringWealthMusicConfig = require "CodeSoaringWealthSrc.SoaringWealthMusicConfig"
local CodeGameScreenSoaringWealthMachine = class("CodeGameScreenSoaringWealthMachine", BaseNewReelMachine)

CodeGameScreenSoaringWealthMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenSoaringWealthMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenSoaringWealthMachine.SYMBOL_SCORE_BONUS = 94
CodeGameScreenSoaringWealthMachine.SYMBOL_SCORE_JACKPOT_BONUS = 95

CodeGameScreenSoaringWealthMachine.EFFECT_COLLECT_BALL = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenSoaringWealthMachine.EFFECT_WIN_BONUS = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenSoaringWealthMachine.EFFECT_CHANGE_WILD = GameEffect.EFFECT_SELF_EFFECT - 3

CodeGameScreenSoaringWealthMachine.m_curAllConfigInfo = {} 

-- 构造函数
function CodeGameScreenSoaringWealthMachine:ctor()
    CodeGameScreenSoaringWealthMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_isOnceClipNode = false
    self.m_spinRestMusicBG = true
    self.tblReelLineHight = 529
    self.m_maxShowRow = 8
    self.m_curShowRow = 4
    self.m_minRow = 4
    self.nextSpinChangeRow = 4
    self.enumChangeRowType = {["NORMAL"] = 0, ["RISE"] = 1, ["DECLINE"] = 2}
    self.nextChangeRowType = self.enumChangeRowType["NORMAL"]
    self.colChangeBigWild = {}
    self.totalCollectTimes = 0

    self.collectSpotData = 0
    self.tblCollectSpotNode = {}
    self.tblCollectSpot = {}
    self.tblCollectSpotLight = {}
    self.tblBigWildSpine = {}
    self.tblCloudNode = {}
    self.tblCloudAni = {}
    self.tblGameBgNode = {}
    self.tblBaseBgSpine = {}
    self.tblReelBorderNode = {}
    self.tblSpReelBasePanel = {}
    self.tblSpReelFreePanel = {}
    self:initCurConfigInfo()
    self.m_mysterList = {}
    for i = 1, 5 do
        self.m_mysterList[i] = -1
    end
    --init
    self:initGame()
end

function CodeGameScreenSoaringWealthMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("SoaringWealthConfig.csv", "SoaringWealthConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    self.m_ScatterShowCol = {2,3,4}
end  


--- 
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenSoaringWealthMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "SoaringWealth"  
end

function CodeGameScreenSoaringWealthMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    for i=1, 2 do
        self.tblGameBgNode[i] = self.m_gameBg:findChild("base_bg_"..i)
        self.tblBaseBgSpine[i] = util_spineCreate("GameScreenSoaringWealthBG",true,true)
        self.tblGameBgNode[i]:addChild(self.tblBaseBgSpine[i])
    end
    self.tblGameBgNode[2]:setOpacity(0)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_jackpotView = util_createView("CodeSoaringWealthSrc.SoaringWealthJackpotView", self)
    self:addChild(self.m_jackpotView, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_jackpotView:setVisible(false)

    self.m_cutJackpotSceneSpine = util_spineCreate("SoaringWealth_GC",true,true)
    self:addChild(self.m_cutJackpotSceneSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_cutJackpotSceneSpine:setPosition(cc.p(display.width/2, display.height/2))
    self.m_cutJackpotSceneSpine:setVisible(false)

    self.m_jackpotWinView = util_createView("CodeSoaringWealthSrc.SoaringWealthJackpotWinView", self)
    self:addChild(self.m_jackpotWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_jackpotWinView:setVisible(false)

    self.m_jackpotOverView = util_createView("CodeSoaringWealthSrc.SoaringWealthJackpotOverView", self)
    self:addChild(self.m_jackpotOverView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_jackpotOverView:setVisible(false)

    local node_bar = self.m_bottomUI:findChild("node_bar")
    self.m_baseFreeSpinBar = util_createView("CodeSoaringWealthSrc.SoaringWealthFreespinBarView")
    self:findChild("Node_FreeSpinBar"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
    -- self.m_baseFreeSpinBar:setPositionY(35)

    self.m_jackPotBar = util_createView("CodeSoaringWealthSrc.SoaringWealthJackPotBarView")
    self:findChild("Node_Jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self.m_lineNode = util_createAnimation("SoaringWealth_base_lines.csb")
    self:findChild("Node_Lines"):addChild(self.m_lineNode)

    self.m_collectSpot = util_createAnimation("SoaringWealth_CollectSpot.csb")
    self:findChild("Node_CollectSpot"):addChild(self.m_collectSpot)

    self.maskNode = self:findChild("zhezhao")
    self.m_maskAni = util_createAnimation("SoaringWealth_zhezhao.csb")
    self.maskNode:addChild(self.m_maskAni)
    self.maskNode:setVisible(false)

    self.m_collectLightAni = util_createAnimation("SoaringWealth_longzhuxingguang.csb")
    self:findChild("Node_CollectSpot"):addChild(self.m_collectLightAni)
    self.m_collectLightAni:setPositionY(50)
    self.m_collectLightAni:setVisible(false)

    self.m_featureTips = util_createAnimation("SoaringWealth_FeatureTips.csb")
    self:findChild("Node_FeatureTips"):addChild(self.m_featureTips)
    self.m_featureTips:runCsbAction("qie", true)

    self.m_dragonSpine = util_spineCreate("Socre_SoaringWealth_Wild",true,true)
    self:findChild("Node_Dragon"):addChild(self.m_dragonSpine)

    self.m_noticeSpine = util_spineCreate("Socre_SoaringWealth_Wild_yugaotx",true,true)
    self:findChild("Node_notice"):addChild(self.m_noticeSpine)
    self.m_noticeSpine:setVisible(false)

    for i=1, 2 do
        self.tblCloudNode[i] = self:findChild("Node_Clouds_"..i)
        self.tblCloudAni[i] = util_createAnimation("SoaringWealth_BG_Clouds.csb")
        self.tblCloudNode[i]:addChild(self.tblCloudAni[i])
        self.tblCloudAni[i]:runCsbAction("idleframe", true)
    end
    for i=1, 2 do
        util_setCascadeOpacityEnabledRescursion(self.tblCloudNode[i],true)
    end
    self.tblCloudNode[2]:setOpacity(0)

    self.m_reelBaseNode = self:findChild("Node_reel_base")
    self.m_reelFreeNode = self:findChild("Node_reel_free")
    self.m_reelFreeNode:setVisible(false)

    self.tblTopPosY = {-59, 167, 392}
    self.tblBorderSizeX = {116, 343, 570}
    self.tblReelSizeY = {463, 680, 905}
    self.tblPanelSizeY = {446, 673, 896}
    self.tblTopEffectBasePosY = {-247.5, -28.4, 199.4}
    self.m_reelTopBorder = self:findChild("ReelTopBorder")
    for i=1, 2 do
        self.tblReelBorderNode[i] = self:findChild("ReelBorder_"..i)
    end
    self.m_topPanel = self:findChild("Panel_1")
    self.m_backgroundBg = self:findChild("BackGround_bg")
    self.m_baseReelSize = self:findChild("reelBase_0"):getContentSize()
    self.m_spTopEffect = self:findChild("sp_top_effect")

    for i=1, 5 do
        self.tblCollectSpotNode[i] = self.m_collectSpot:findChild("Node_Pearl"..i-1)
        self.tblCollectSpot[i] = util_createAnimation("SoaringWealth_Collection_Longzhu.csb")
        self.tblCollectSpotNode[i]:addChild(self.tblCollectSpot[i])
        self.tblCollectSpot[i]:setVisible(false)
        self.tblCollectSpotLight[i] = util_createAnimation("SoaringWealth_Collection_Longzhufankui.csb")
        self.tblCollectSpotNode[i]:addChild(self.tblCollectSpotLight[i])
        self.tblCollectSpotLight[i]:setVisible(false)

        self.tblSpReelBasePanel[i] = self:findChild("reelBase_"..i-1)
        self.tblSpReelFreePanel[i] = self:findChild("reelFree_"..i-1)
    end

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitDragonNode = cc.Node:create()
    self:addChild(self.m_scWaitDragonNode)

    self.m_scDeclineNode = cc.Node:create()
    self:addChild(self.m_scDeclineNode)

    self.m_jackpotView:scaleJackpotMainLayer(self.m_machineRootScale)
end

function CodeGameScreenSoaringWealthMachine:resetChangeState()
    self.nextChangeRowType = self.enumChangeRowType["NORMAL"]
    self.nextSpinChangeRow = 4
end


function CodeGameScreenSoaringWealthMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(SoaringWealthMusicConfig.Music_EnterGame_Bg, 4, 0, 1)

    end,0.4,self:getModuleName())
end

function CodeGameScreenSoaringWealthMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0 - mainPosY

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
            if display.height / display.width == 1024 / 768 then
                mainScale = 0.68
                tempPosY = 42
            elseif display.height / display.width == 960 / 640 then
                mainScale = 0.80
                tempPosY = 38
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(mainPosY + tempPosY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

function CodeGameScreenSoaringWealthMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_configData:setMainMachine(self)
    CodeGameScreenSoaringWealthMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:updateCurrentInfo()
    self:initGameUI()
    self:updateCurMainReelUI()
    self:initOneAndFiveColGridCount()
end

function CodeGameScreenSoaringWealthMachine:initOneAndFiveColGridCount()
    for i = 1, self.m_iReelColumnNum, 1 do
        if i == 1 or i == 5 then
            local columnData = self.m_reelColDatas[i]
            columnData.p_showGridCount = self.m_maxShowRow
        end
    end
end

function CodeGameScreenSoaringWealthMachine:addObservers()
    CodeGameScreenSoaringWealthMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        if self:getCurIsHaveFreeSpin() then
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

        local bgmType
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgmType = "fg"
        else
            local curRowType = 1
            if self.m_curShowRow > self.m_minRow then
                curRowType = 2
            end
            bgmType = "bg" .. "_" .. curRowType
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "SoaringWealthSounds/SoaringWealth_last_win_"..bgmType.."_"..soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)

        self:resetChangeState()
        self:updateCurrentInfo()
        self:addChangePlay()
        self:updateCurMainReelUI()

    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenSoaringWealthMachine:getCurIsHaveFreeSpin()
    local isHave = false
    for i=1, #self.m_gameEffects do
        local effect = self.m_gameEffects[i]
        if effect.p_effectType == GameEffect.EFFECT_FREE_SPIN then
            isHave = true
            break
        end
    end
    return isHave
end

function CodeGameScreenSoaringWealthMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenSoaringWealthMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    self:removeChangeReelDataHandler()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenSoaringWealthMachine:initGameUI()
    local curRows = self.m_curConfigInfo.reelRows
    local nextRows = self.m_curConfigInfo.nextRows
    if nextRows then
        if nextRows > curRows then
            self.nextChangeRowType = self.enumChangeRowType["RISE"]
            self.nextSpinChangeRow = nextRows
        else
            self.nextChangeRowType = self.enumChangeRowType["DECLINE"]
            self.nextSpinChangeRow = nextRows
        end
    end
    self.m_curShowRow = curRows
end

function CodeGameScreenSoaringWealthMachine:cutBgContentSize()
    local curShowIndex = self:getCurShowIndex()
    self.m_reelTopBorder:setPositionY(self.tblTopPosY[curShowIndex])
    for i=1, 2 do
        self.tblReelBorderNode[i]:setContentSize(cc.size(self.tblBorderSizeX[curShowIndex], 14))
    end
    for i=2, 4 do
        self.tblSpReelBasePanel[i]:setContentSize(cc.size(self.m_baseReelSize.width, self.tblReelSizeY[curShowIndex]))
        self.tblSpReelFreePanel[i]:setContentSize(cc.size(self.m_baseReelSize.width, self.tblReelSizeY[curShowIndex]))
    end
    local sizePanel = self.m_topPanel:getContentSize()
    self.m_topPanel:setContentSize(cc.size(sizePanel.width, self.tblPanelSizeY[curShowIndex]))
    local sizeBg = self.m_topPanel:getContentSize()
    self.m_backgroundBg:setContentSize(cc.size(sizeBg.width, self.tblReelSizeY[curShowIndex]))
end

function CodeGameScreenSoaringWealthMachine:cutBetAndSetSymbolToBaseParent(_cutRow)
    local cutRow = _cutRow
    local symbolNum = 0
    if cutRow == 6 then
        symbolNum = 10
    elseif cutRow == 4 then
        symbolNum = 20
    end

    if symbolNum > 0 then
        for i=1, symbolNum do
            local fixPos = self:getRowAndColByPos(i-1)
            local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- util_setClipReelSymbolToBaseParent(self, symbolNode)
                symbolNode:putBackToPreParent()
            end
        end
    end
end

function CodeGameScreenSoaringWealthMachine:refreshShowBallState(_collectTimes)
    local curCollectNum = _collectTimes[1]
    self.collectSpotData = curCollectNum
    for i=1, 5 do
        if i <= curCollectNum then
            self.tblCollectSpot[i]:setVisible(true)
            if self.m_curShowRow > self.m_minRow then
                self.tblCollectSpot[i]:runCsbAction("idleframe3", true)
            else
                self.tblCollectSpot[i]:runCsbAction("idleframe1", true)
            end
        else
            self.tblCollectSpot[i]:setVisible(false)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:getCurCollectNodePos(_isAdd)
    local pos = self.collectSpotData
    if _isAdd then
        if self.collectSpotData < 5 then
            pos = pos + 1
        else
            pos = 1
        end
    else
        if self.collectSpotData <= 0 or self.collectSpotData > 5 then
            pos = 1
        end
    end
    return pos
end

function CodeGameScreenSoaringWealthMachine:setCurCollectNodePos(_num)
    self.collectSpotData = self.collectSpotData + _num
    self:setCollectAllAni("idleframe3", true, true)
end

function CodeGameScreenSoaringWealthMachine:resetDeclineRowCollect()
    self.collectSpotData = 0
    for i=1, 5 do
        self.tblCollectSpotLight[i]:setVisible(false)
    end
end

function CodeGameScreenSoaringWealthMachine:setCollectAllAni(_idleName, _particlePlay, _isPlayEffect)
    if self.collectSpotData == 5 then
        for i=1, 5 do
            self.tblCollectSpot[i]:runCsbAction(_idleName, true)
        end
        if _particlePlay then
            self.m_collectLightAni:setVisible(true)
            self.m_collectLightAni:runCsbAction("sao", false, function()
                self.m_collectLightAni:setVisible(false)
            end)
            if _isPlayEffect then
                gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_allBonusLight)
            end
            -- self:setDragonSpine("idle3", true)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:initCurConfigInfo()
    self.m_curConfigInfo = {["collectTimes"] = {0, 0}, ["reelRows"] = 4}
end

function CodeGameScreenSoaringWealthMachine:updateCurrentInfo()
    local betIdx = globalData.slotRunData:getCurBetIndex()
    local curBet = globalData.slotRunData:getCurBetValueByIndex(betIdx)
    local curInfo = self.m_curAllConfigInfo[tostring(toLongNumber(curBet) )]

    if curInfo then
        self.m_curConfigInfo = curInfo
    else
        self:initCurConfigInfo()
    end
    self.m_curShowRow = self.m_curConfigInfo.reelRows
end

function CodeGameScreenSoaringWealthMachine:updateCurMainReelUI()
    self.m_curShowRow = self.m_curConfigInfo.reelRows
    local collectTimes = self.m_curConfigInfo.collectTimes
    local maxHeight = self.m_SlotNodeH * self.m_maxShowRow
    local curHight = maxHeight/self.m_maxShowRow*self.m_curShowRow

    self:changeShowRow(curHight, true)
    if collectTimes then
        self:refreshShowBallState(collectTimes)
    end
    self:runCsbAction(self:getCurReelAniIdleName(), true)
    -- 取消掉赢钱线的显示
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearWinLineEffect()
    self:cutBgContentSize()
    if self.m_curShowRow == self.m_maxShowRow then
        self:setJackpotBarActionState(true)
        self:playDragonSpine(3)
        self:refreshLine(nil, "idle3", true)
        self:changeBgSpine(3)
    elseif self.m_curShowRow == 6 then
        self:setJackpotBarActionState(false, true)
        self:playDragonSpine(2)
        self:refreshLine(nil, "idle2", true)
        self:changeBgSpine(3)
        self:cutBetAndSetSymbolToBaseParent(6)
    elseif self.m_curShowRow == self.m_minRow then
        self:setJackpotBarActionState(false, true)
        self:playDragonSpine(1)
        self:setCollectAllAni("idleframe3", true)
        self:refreshLine(nil, "idle1", true)
        self:changeBgSpine(1)
        self:cutBetAndSetSymbolToBaseParent(4)
    end
    if self:getCurColumnIsAllWild(true) then
        self:cutWildSpine(true)
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenSoaringWealthMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenSoaringWealthMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

function CodeGameScreenSoaringWealthMachine:setIdleType(_idleType)
    self.m_idleType = 3
end

function CodeGameScreenSoaringWealthMachine:playDragonSpine(_idleType, _playNext)
    if self.m_idleType and self.m_idleType == _idleType then
        return
    end
    self.m_idleType = _idleType
    if _idleType == 3 then
        self.m_scWaitDragonNode:stopAllActions()
        self.m_dragonSpine:setVisible(false)
        return
    else
        self.m_dragonSpine:setVisible(true)
    end
    local tblActionList = {}
    local playNext = true
    local delayTime, idleName
    if self.m_idleType == 1 then
        delayTime = 198*2/30
        idleName = "idle"
    else
        delayTime = 174*2/30
        idleName = "idle_1"
    end
    if _playNext then
        delayTime = 99/30
        playNext = false
        if self.m_idleType == 1 then
            idleName = "idle2"
        else
            idleName = "idle2_1"
        end
    end
    util_spinePlay(self.m_dragonSpine,idleName,true)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:playDragonSpine(self.m_idleType, playNext)
    end)
    self.m_scWaitDragonNode:stopAllActions()
    self.m_scWaitDragonNode:runAction(cc.Sequence:create(tblActionList))
end

function CodeGameScreenSoaringWealthMachine:setDragonSpine(_idleName, _loop)
    self.m_scWaitDragonNode:stopAllActions()
    self.m_dragonSpine:setVisible(true)
    util_spinePlay(self.m_dragonSpine,_idleName, _loop)
end

--升降6行
function CodeGameScreenSoaringWealthMachine:refreshShowRow_1(_callFunc, _isRise)
    local riseRow = 6
    local callFunc = _callFunc
    local isRise = _isRise
    local maxHeight = self.m_SlotNodeH * self.m_maxShowRow
    local baseHeight, totalTime, endHight, disHight, scheduleDelayTime
    local startIndex, endIndex, targetIndex
    self.curRunTime = 0

    local runCallFunc = function()
        if isRise then
            baseHeight = self.m_SlotNodeH * 4
            totalTime = 120/60
            scheduleDelayTime = 20/60
            endHight = maxHeight/self.m_maxShowRow*riseRow
            disHight = (endHight - baseHeight)/totalTime
            startIndex = 1
            endIndex = 2
            targetIndex = 2
            self:changeBgSpine(3, true)
            self:setCollectAllAni("idleframe3")
            if self.m_curShowRow == riseRow then
                gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_fourToSixRow)
            else
                gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_sixToEightRow)
            end
            self:runCsbAction("sheng1", false)
        else
            baseHeight = maxHeight/self.m_maxShowRow*riseRow
            endHight = self.m_SlotNodeH * 4
            totalTime = 30/60
            disHight = (endHight - baseHeight)/totalTime
            scheduleDelayTime = 0
            startIndex = 2
            endIndex = 1
            targetIndex = 1
            self:changeBgSpine(1, true)
            self:setIdleType(3)
            self:setDragonSpine("idle4_1", false)
            performWithDelay(self.m_scWaitNode, function()
                self:playDragonSpine(1)
            end, 35/30)
            gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_sixToFourRow)
            self:runCsbAction("jiang1", false, function()
                self:resetMusicBg(true)
                self:changeTopEffectPosY(self.tblTopEffectBasePosY[1])
                self:resetDeclineRowCollect()
                self:refreshLine("bian", "idle1")
                if callFunc then
                    callFunc()
                    callFunc = nil
                end
            end)
        end

        performWithDelay(self.m_scWaitNode, function()
            util_schedule(self.m_scDeclineNode, function()
                self.curRunTime = self.curRunTime + 1/60
                if self.curRunTime < totalTime then
                    local curHight = baseHeight + disHight * self.curRunTime
                    self:changeShowRow(curHight, false)

                    local reelDis = self.tblReelSizeY[endIndex] - self.tblReelSizeY[startIndex]
                    local curReelHeight = self.tblReelSizeY[startIndex] + reelDis / totalTime * self.curRunTime
                    self:changeBgReelHeight(curReelHeight)

                    local topDis = self.tblTopPosY[endIndex] - self.tblTopPosY[startIndex]
                    local curTopHeight = self.tblTopPosY[startIndex] + topDis / totalTime * self.curRunTime
                    self:changeTopBorderHeight(curTopHeight)
                    
                    local borderDis = self.tblBorderSizeX[endIndex] - self.tblBorderSizeX[startIndex]
                    local curBorderWidth = self.tblBorderSizeX[startIndex] + borderDis / totalTime * self.curRunTime
                    self:changeBgBorderWidth(curBorderWidth)
                    
                    local panelDis = self.tblPanelSizeY[endIndex] - self.tblPanelSizeY[startIndex]
                    local curPanelHeight = self.tblPanelSizeY[startIndex] + panelDis / totalTime * self.curRunTime
                    self:changeBgPanelHight(curPanelHeight)

                    if isRise then
                        local topEffectDis = self.tblTopEffectBasePosY[2] - self.tblTopEffectBasePosY[1]
                        local curParPosY = self.tblTopEffectBasePosY[1] + topEffectDis / totalTime * self.curRunTime
                        self:changeTopEffectPosY(curParPosY)
                    end
                else
                    self:changeShowRow(endHight, true)
                    self:changeBgReelHeight(self.tblReelSizeY[targetIndex])
                    self:changeTopBorderHeight(self.tblTopPosY[targetIndex])
                    self:changeBgBorderWidth(self.tblBorderSizeX[targetIndex])
                    self:changeBgPanelHight(self.tblPanelSizeY[targetIndex])
                    if isRise then
                        self:changeTopEffectPosY(self.tblTopEffectBasePosY[2])
                        self:setDragonSpine("yugao2", false)
                        performWithDelay(self.m_scWaitNode, function()
                            self:setIdleType(3)
                            self:playDragonSpine(2)
                        end, 60/30)
                        if self.m_curShowRow == riseRow then
                            performWithDelay(self.m_scWaitNode, function()
                                self:resetMusicBg(true)
                            end, 80/60)
                            self:runCsbAction("idle2", false, function()
                                self:runCsbAction("bianliang2", false, function()
                                    self:refreshLine("bian1", "idle2")
                                    self:runCsbAction("idleliang1", true)
                                    self:playCollectBall()
                                    if callFunc then
                                        callFunc()
                                        callFunc = nil
                                    end
                                end)
                            end)
                        else
                            self:refreshLine("bian1", "idle2")
                            self:showMiddleDragonSpine(callFunc, true)
                        end
                    end
                    self.m_scDeclineNode:stopAllActions()
                end
            end, 1/60)
        end, scheduleDelayTime)
    end

    if _isRise then
        self:setDragonSpine("idle4", false)
        performWithDelay(self.m_scWaitNode, function()
            runCallFunc()
        end, 30/60)
    else
        runCallFunc()
    end
end

function CodeGameScreenSoaringWealthMachine:showMiddleDragonSpine(_callFunc, _isRise)
    local callFunc = _callFunc
    local isRise = _isRise
    self.m_noticeSpine:setVisible(true)
    util_spinePlay(self.m_noticeSpine, "yugao3", false)
    util_spinePlay(self.m_dragonSpine, "yugao3", false)
    performWithDelay(self.m_scWaitNode, function()
        self.m_noticeSpine:setVisible(false)
        self:refreshShowRow_2(callFunc, isRise)
    end, 60/30)
end

--升降8行
function CodeGameScreenSoaringWealthMachine:refreshShowRow_2(_callFunc, _isRise)
    local riseRow = 8
    local callFunc = _callFunc
    local isRise = _isRise
    local maxHeight = self.m_SlotNodeH * self.m_maxShowRow
    local baseHeight, totalTime, endHight, disHight, scheduleDelayTime
    local startIndex, endIndex, targetIndex
    self.curRunTime = 0
    
    if _isRise then
        baseHeight = self.m_SlotNodeH * 6
        totalTime = 120/60
        scheduleDelayTime = 20/60
        startIndex = 2
        endIndex = 3
        targetIndex = 3
        endHight = maxHeight/self.m_maxShowRow*riseRow
        disHight = (endHight - baseHeight)/totalTime
        self:resetMusicBg(true)
        self:setDragonSpine("idle5", false)
        self:runCsbAction("sheng2", false)
    else
        baseHeight = maxHeight/self.m_maxShowRow*riseRow
        endHight = self.m_SlotNodeH * 4
        totalTime = 30/60
        disHight = (endHight - baseHeight)/totalTime
        scheduleDelayTime = 0
        startIndex = 3
        endIndex = 1
        targetIndex = 1
        self:changeBgSpine(1, true)
        gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_eightToFourRow)
        self:runCsbAction("jiang2", false, function()
            self:setJackpotBarActionState(false)
            self:resetMusicBg(true)
            self:changeTopEffectPosY(self.tblTopEffectBasePosY[1])
            self:refreshLine("bian3", "idle1")
            self:setIdleType(3)
            self:setDragonSpine("idle6", false)
            self:resetDeclineRowCollect()
            performWithDelay(self.m_scWaitNode, function()
                self:playDragonSpine(1)
            end, 45/30)
            if callFunc then
                callFunc()
                callFunc = nil
            end
        end)
    end

    performWithDelay(self.m_scWaitNode, function()
        util_schedule(self.m_scDeclineNode, function()
            self.curRunTime = self.curRunTime + 1/60
            if self.curRunTime < totalTime then
                local curHight = baseHeight + disHight * self.curRunTime
                self:changeShowRow(curHight, false)

                local reelDis = self.tblReelSizeY[endIndex] - self.tblReelSizeY[startIndex]
                local curReelHeight = self.tblReelSizeY[startIndex] + reelDis / totalTime * self.curRunTime
                self:changeBgReelHeight(curReelHeight)

                local topDis = self.tblTopPosY[endIndex] - self.tblTopPosY[startIndex]
                local curTopHeight = self.tblTopPosY[startIndex] + topDis / totalTime * self.curRunTime
                self:changeTopBorderHeight(curTopHeight)
                
                local borderDis = self.tblBorderSizeX[endIndex] - self.tblBorderSizeX[startIndex]
                local curBorderWidth = self.tblBorderSizeX[startIndex] + borderDis / totalTime * self.curRunTime
                self:changeBgBorderWidth(curBorderWidth)
                
                local panelDis = self.tblPanelSizeY[endIndex] - self.tblPanelSizeY[startIndex]
                local curPanelHeight = self.tblPanelSizeY[startIndex] + panelDis / totalTime * self.curRunTime
                self:changeBgPanelHight(curPanelHeight)

                if isRise then
                    local topEffectDis = self.tblTopEffectBasePosY[2] - self.tblTopEffectBasePosY[1]
                    local curPosY = self.tblTopEffectBasePosY[2] + topEffectDis / totalTime * self.curRunTime
                    self:changeTopEffectPosY(curPosY)
                end
            else
                self:changeShowRow(endHight, true)
                self:changeBgReelHeight(self.tblReelSizeY[targetIndex])
                self:changeTopBorderHeight(self.tblTopPosY[targetIndex])
                self:changeBgBorderWidth(self.tblBorderSizeX[targetIndex])
                self:changeBgPanelHight(self.tblPanelSizeY[targetIndex])

                if isRise then
                    self:changeTopEffectPosY(self.tblTopEffectBasePosY[3])
                    self:setJackpotBarActionState(true)
                    self:runCsbAction("bianliang1", false, function()
                        self:refreshLine("bian2", "idle3")
                        self:runCsbAction("idleliang2", true)
                        self:playCollectBall()
                        if callFunc then
                            callFunc()
                            callFunc = nil
                        end
                    end)
                end
                self.m_scDeclineNode:stopAllActions()
            end
        end, 1/60)
    end, scheduleDelayTime)
end

function CodeGameScreenSoaringWealthMachine:changeBgReelHeight(_curReelHeight)
    local curReelHeight = _curReelHeight
    for i=2, 4 do
        self.tblSpReelBasePanel[i]:setContentSize(cc.size(self.m_baseReelSize.width, curReelHeight))
        self.tblSpReelFreePanel[i]:setContentSize(cc.size(self.m_baseReelSize.width, curReelHeight))
    end
    local sizeBg = self.m_backgroundBg:getContentSize()
    self.m_backgroundBg:setContentSize(cc.size(sizeBg.width, curReelHeight))
end

function CodeGameScreenSoaringWealthMachine:changeTopBorderHeight(_curTopHeight)
    local curTopHeight = _curTopHeight
    self.m_reelTopBorder:setPositionY(curTopHeight)
end

function CodeGameScreenSoaringWealthMachine:changeBgBorderWidth(_curBorderWidth)
    local curBorderWidth = _curBorderWidth
    for i=1, 2 do
        self.tblReelBorderNode[i]:setContentSize(cc.size(curBorderWidth, 14))
    end
end

function CodeGameScreenSoaringWealthMachine:changeBgPanelHight(_curPanelHeight)
    local curPanelHeight = _curPanelHeight
    local sizePanel = self.m_topPanel:getContentSize()
    self.m_topPanel:setContentSize(cc.size(sizePanel.width, curPanelHeight))
end

function CodeGameScreenSoaringWealthMachine:changeShowRow(_curHight, _isRun)
    local curHight = _curHight
    local isRun = _isRun
    for i = 1, self.m_iReelColumnNum, 1 do
        if i ~= 1 and i ~= 5 then
            local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
            local rect = clipNode:getClippingRegion()
            clipNode:setClippingRegion(
                {
                    x = rect.x,
                    y = rect.y,
                    width = rect.width,
                    height = curHight
                }
            )
        end
    end

    if isRun and self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
end

function CodeGameScreenSoaringWealthMachine:changeTopEffectPosY(_curPosY)
    local curPosY = _curPosY
    self.m_spTopEffect:setPositionY(curPosY)
end

function CodeGameScreenSoaringWealthMachine:changeTouchSpinLayerSize()
    if self.m_SlotNodeH and self.m_curShowRow then
        local size = self.m_touchSpinLayer:getContentSize()
        self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH * self.m_curShowRow))
    end
end

function CodeGameScreenSoaringWealthMachine:getCurShowIndex()
    local curShowIndex = (self.m_curShowRow-2)/2
    return curShowIndex
end

function CodeGameScreenSoaringWealthMachine:refreshLine(_aniName, _idleName, _isCut)
    local aniName = _aniName
    local idleName = _idleName
    local isCut = _isCut

    if isCut then
        self.m_lineNode:runCsbAction(idleName, true)
    else
        self.m_lineNode:runCsbAction(aniName, false, function()
            self.m_lineNode:runCsbAction(_idleName, true)
        end)
    end
end

function CodeGameScreenSoaringWealthMachine:initGameStatusData(gameData)
    CodeGameScreenSoaringWealthMachine.super.initGameStatusData(self,gameData)
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenSoaringWealthMachine:MachineRule_initGame(  )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    
    if selfData then
        local spinConfig = selfData.spinConfigSend
        if spinConfig then
            self.m_curAllConfigInfo = spinConfig
        end
    end
    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self:changeBgSpine(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_reelFreeNode:setVisible(true)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenSoaringWealthMachine:slotOneReelDown(reelCol)    
    CodeGameScreenSoaringWealthMachine.super.slotOneReelDown(self,reelCol) 
   
    ---本列是否开始长滚
    local isTriggerLongRun = false
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true
    end
    if isTriggerLongRun then
        -- 开始快滚的时候 其他scatter 播放ialeframe2
        self:playScatterSpine("idleframe2", reelCol)
    else
        if reelCol == self.m_iReelColumnNum then
            self:playScatterSpine("idleframe", reelCol)
        end
    end

    if reelCol == self.m_iReelColumnNum then
        for iRow = 1, self.m_curShowRow do
            local slotNode = self:getFixSymbol(3, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_BONUS then
                self:showMaskByJackpot(iRow, 3)
                slotNode:runAnim("actionframe", false)
            end
        end
    end
end

function CodeGameScreenSoaringWealthMachine:showMaskByJackpot(_iRow, _iCol)
    globalMachineController:playBgmAndResume(SoaringWealthMusicConfig.Music_triggerJackpotPlay, 4, 0, 1)
    local jackpotBonus = self.maskNode:getChildByName("jackpotBonus")
    if not jackpotBonus then
        jackpotBonus = self:createSoaringWealthSymbol(self.SYMBOL_SCORE_JACKPOT_BONUS)
        self.maskNode:addChild(jackpotBonus, 10)
    end
    local nodePos = self:getPosReelIdx(_iRow, _iCol)
    local clipTarPos = util_getOneGameReelsTarSpPos(self, nodePos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
    local nodePos = self.maskNode:convertToNodeSpace(worldPos)
    jackpotBonus:setName("jackpotBonus")
    jackpotBonus:setPosition(nodePos)
    self:setCurRowMask()
    jackpotBonus:runAnim("actionframe", false)
    self.m_maskAni:runCsbAction("chuxian", false, function()
        self.m_maskAni:runCsbAction("idle", true)
    end)
    self.maskNode:setVisible(true)
end

function CodeGameScreenSoaringWealthMachine:setCurRowMask()
    local curShowIndex = self:getCurShowIndex()
    for i=1, 3 do
        if i == curShowIndex then
            self.m_maskAni:findChild("Node_mask_"..i):setVisible(true)
        else
            self.m_maskAni:findChild("Node_mask_"..i):setVisible(false)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:createSoaringWealthSymbol(_symbolType)
    local symbol = util_createView("CodeSoaringWealthSrc.SoaringWealthSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenSoaringWealthMachine:playScatterSpine(_spineName, _reelCol)
    performWithDelay(self.m_scWaitNode,function()
        for iCol = 1, _reelCol  do
            local curRowNum = self:getCurBonusScatterRow(iCol)
            for iRow = 1, curRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if _spineName == "idleframe" and targSp.m_currAnimName ~= "buling" then
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

--添加金边
function CodeGameScreenSoaringWealthMachine:creatReelRunAnimation(col)
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

    local tblActionName = {"run", "run2", "run3"}
    local curShowIndex = self:getCurShowIndex()
    
    util_csbPlayForKey(reelAct, tblActionName[curShowIndex], true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
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

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenSoaringWealthMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenSoaringWealthMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

-- 显示free spin
function CodeGameScreenSoaringWealthMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 停掉背景音乐
    --self:clearCurMusicBg()
    -- freeMore时不播放
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if self.m_curShowRow == self.m_minRow then
        self:updateCurrentInfo()
    end
    local waitTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_curShowRow do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

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
    end
    self:playScatterTipMusicEffect()
    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenSoaringWealthMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("SoaringWealthSounds/music_SoaringWealth_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_fG_moreStartOver)
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,false)
        else
            self.m_baseFreeSpinBar:setVisible(true)
            self.m_baseFreeSpinBar:changeFreeSpinByCount()
            gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_fG_bgStart)
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_fG_bgStart_over)
                self.m_isPlayVolume = true
                self:showCutSceneAni(function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                    self:changeBgSpine(2)
                    self.m_reelFreeNode:setVisible(true)
                end, true)  
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenSoaringWealthMachine:triggerFreeSpinCallFun()
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
end

function CodeGameScreenSoaringWealthMachine:showCutSceneAni(_callFunc, _isFreeSpin)
    local callFunc = _callFunc
    local isFreeSpin = _isFreeSpin
    self.m_cutJackpotSceneSpine:setVisible(true)
    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_fG_cutScene)
    util_spinePlay(self.m_cutJackpotSceneSpine,"guochang",false)
    performWithDelay(self.m_scWaitNode, function()
        if callFunc then
            callFunc()
            callFunc = nil
        end
        if isFreeSpin then
            performWithDelay(self.m_scWaitNode, function()
                self:resetMusicBg()
            end, 1.0)
        end
    end, 25/30)
end

function CodeGameScreenSoaringWealthMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_NOMAL)
    end
end

function CodeGameScreenSoaringWealthMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("SoaringWealthSounds/music_SoaringWealth_over_fs.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local fsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local changBgFunc = function()
        if self.m_curShowRow == self.m_minRow then
            self:changeBgSpine(1)
        else
            self:changeBgSpine(3)
        end
    end
    globalMachineController:playBgmAndResume(SoaringWealthMusicConfig.Music_fG_bgOver, 4, 0, 1)
    if globalData.slotRunData.lastWinCoin > 0 then
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount, function()
            self:triggerFreeSpinOverCallFun()
            changBgFunc()
            self.m_reelFreeNode:setVisible(false)
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.0,sy=1.0},620)
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:triggerFreeSpinOverCallFun()
            changBgFunc()
            self.m_reelFreeNode:setVisible(false)
        end)
    end
end

function CodeGameScreenSoaringWealthMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FreeSpinOver_NoWins",nil,_func)
    return view
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenSoaringWealthMachine:MachineRule_SpinBtnCall()
    
    if not self.m_isPlayVolume then
        self:setMaxMusicBGVolume( )
    end
    self.m_isPlayVolume = false
   
    self:removeChangeReelDataHandler()
    self:randomMystery()


    return false -- 用作延时点击spin调用
end

function CodeGameScreenSoaringWealthMachine:randomMystery()
    self.m_bNetSymbolType = false
    for i = 1, #self.m_mysterList do
        local symbolInfo = self:getColIsSameSymbol(i)
        self.m_mysterList[i] = symbolInfo.symbolType
    end

    self.m_configData:setMysterSymbol(self.m_mysterList)
end

--随机信号
function CodeGameScreenSoaringWealthMachine:getReelSymbolType(parentData)
    local cloumnIndex = parentData.cloumnIndex
    if self.m_bNetSymbolType == true then
        if self.m_mysterList[cloumnIndex] ~= -1 then
            return self.m_mysterList[cloumnIndex]
        end
    end
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end
    return symbolType
end

--使用现在获取的数据
function CodeGameScreenSoaringWealthMachine:setNetMysteryType()
    self.m_changeReelDataId =
        scheduler.performWithDelayGlobal(
        function()
            self.m_bNetSymbolType = true
            local bRunLong = false
            for i = 1, #self.m_mysterList do
                local symbolInfo = self:getColIsSameSymbol(i)
                self.m_mysterList[i] = symbolInfo.symbolType
                local reelRunData = self.m_reelRunInfo[i]
                if bRunLong then
                    self.m_mysterList[i] = -1
                end
                if self.m_mysterList[i] == -1 then
                    self:changeSlotReelDatas(i, bRunLong)
                end
                if reelRunData:getNextReelLongRun() == true then
                    bRunLong = true
                end
            end
        end,
        0.5,
        "changeReelData"
    )
end

function CodeGameScreenSoaringWealthMachine:changeSlotReelDatas(_col, _bRunLong)
    local slotsParents = self.m_slotParents

    local parentData = slotsParents[_col]
    local slotParent = parentData.slotParent
    local slotParentBig = parentData.slotParentBig
    local reelDatas = self:checkUpdateReelDatas(parentData, _bRunLong)
    self:checkReelIndexReason(parentData)
    self:resetParentDataReel(parentData)
    self:checkChangeClipParent(parentData)
end

function CodeGameScreenSoaringWealthMachine:checkUpdateReelDatas(parentData, _bRunLong)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function CodeGameScreenSoaringWealthMachine:removeChangeReelDataHandler()
    if self.m_changeReelDataId ~= nil then
        scheduler.unschedulesByTargetName("changeReelData")
        self.m_changeReelDataId = nil
    end
end

function CodeGameScreenSoaringWealthMachine:getColIsSameSymbol(_iCol)
    if _iCol == 1 or _iCol == 5 then
        local symbolInfo = {}
        symbolInfo.symbolType = -1
        symbolInfo.bSame = false
        return symbolInfo
    end
    local reelsData = self.m_runSpinResultData.p_reels
    if reelsData and next(reelsData) then
        local symbolInfo = {}
        local tempType
        local symbolType = nil
        local endIndex = self.m_maxShowRow - self.m_curShowRow + 1
        for iRow = self.m_maxShowRow, endIndex, -1 do
            tempType = reelsData[iRow][_iCol]
            if symbolType == nil then
                symbolType = tempType
            end
            if symbolType ~= tempType then
                symbolInfo.symbolType = -1
                symbolInfo.bSame = false
                return symbolInfo
            end
        end
        symbolInfo.symbolType = tempType
        symbolInfo.bSame = true
        return symbolInfo
    else
        local symbolInfo = {}
        symbolInfo.symbolType = -1
        symbolInfo.bSame = false
        return symbolInfo
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenSoaringWealthMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --self:updateCurrentInfo()
    self:addChangePlay()
    if self:getCurColumnIsAllWild() then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_CHANGE_WILD
        effectData.p_selfEffectType = self.EFFECT_CHANGE_WILD
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end

    if selfData and selfData.winBonus then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_WIN_BONUS
        effectData.p_selfEffectType = self.EFFECT_WIN_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end

    if self.m_curConfigInfo.collectTimes[2] > 0 then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_COLLECT_BALL
        effectData.p_selfEffectType = self.EFFECT_COLLECT_BALL
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

function CodeGameScreenSoaringWealthMachine:addChangePlay()
    if self.m_curConfigInfo.nextRows and self.m_curConfigInfo.nextRows > self.m_minRow then
        self.nextChangeRowType = self.enumChangeRowType["RISE"]
        self.nextSpinChangeRow = self.m_curConfigInfo.nextRows
    end
    if self.m_curConfigInfo.nextRows and self.m_curConfigInfo.nextRows == self.m_minRow then
        self.nextChangeRowType = self.enumChangeRowType["DECLINE"]
        self.nextSpinChangeRow = self.m_curConfigInfo.nextRows
    end
end

function CodeGameScreenSoaringWealthMachine:setJackpotBarActionState(_state, _isCut)
    local showState = _state
    local isCut = _isCut
    if showState then
        if not self.m_jackPotBar:getBarActionState() then
            self.m_jackPotBar:setBarActionState(showState)
            self.m_jackPotBar:runBarAction()
        end
    else
        self.m_jackPotBar:setBarActionState(showState)
        if isCut then
            self.m_jackPotBar:cutShowBar()
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenSoaringWealthMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_CHANGE_WILD then
        self:playChangeAllWild(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_WIN_BONUS then
        self:playWinBonus(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_BALL then
        self:playCollectBall(effectData)
    end
    return true
end

function CodeGameScreenSoaringWealthMachine:playCollectBall(_effectData)
    local effectData = _effectData
    local collectTimes = self.m_curConfigInfo.collectTimes
    local iconPos = self.m_runSpinResultData.p_storedIcons

    local delayTime = 58/60
    local actionDelayTime = 18/60

    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    if collectTimes[2] > 0 then
        self.totalCollectTimes = self.totalCollectTimes + 1
        if iconPos and iconPos[1] then
            local pos = iconPos[1]
            local fixPos = self:getRowAndColByPos(pos)
            local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)

            gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_collectBonus)
            symbolNode:runAnim("shouji",false, function()
                symbolNode:runAnim("idleframe",true)
                if fixPos.iX == self.m_curShowRow or fixPos.iX == 1 then
                    -- util_setClipReelSymbolToBaseParent(self, symbolNode)
                    symbolNode:putBackToPreParent()
                end
            end)
            
            local collectNodePos = self:getCurCollectNodePos(true)
            local clipTarPos = util_getOneGameReelsTarSpPos(self, pos)
            local startPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
            local endPos = util_convertToNodeSpace(self.tblCollectSpotNode[collectNodePos], self)
            local flyNode = util_createAnimation("SoaringWealth_Collection_Longzhu.csb")
            flyNode:setPosition(startPos.x, startPos.y)
            self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)
            
            local particle = flyNode:findChild("Particle_1")
            particle:setPositionType(0)
            particle:setDuration(-1)
            particle:resetSystem()

            flyNode:runCsbAction("shouji")
            performWithDelay(flyNode, function()
                local action_1
                if collectNodePos == 3 then
                    action_1 = cc.MoveTo:create(actionDelayTime, endPos)
                else
                    local disPosX, disPosY = self:getCurDisPos(collectNodePos)
                    local bezier = {}
                    bezier[1] = cc.p(startPos.x, startPos.y)
                    bezier[2] = cc.p(startPos.x + disPosX, startPos.y + disPosX)
                    bezier[3] = endPos
                    action_1 = cc.BezierTo:create(actionDelayTime, bezier)
                end
                flyNode:runAction(action_1)
                performWithDelay(flyNode, function()
                    self.tblCollectSpotLight[collectNodePos]:setVisible(true)
                    self.tblCollectSpot[collectNodePos]:setVisible(true)
                    self.tblCollectSpot[collectNodePos]:runCsbAction("idleframe1", true)
                    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_collectBonusFeedback)
                    self.tblCollectSpotLight[collectNodePos]:runCsbAction("fankui", false, function()
                        particle:stopSystem()
                        self.tblCollectSpotLight[collectNodePos]:setVisible(false)
                        self:setCurCollectNodePos(1)
                        if self.totalCollectTimes < collectTimes[2] then
                            self:playCollectBall(effectData)
                        else
                            endCallFunc()
                            self.totalCollectTimes = 0
                        end
                    end)
                    flyNode:findChild("Node_bg"):setVisible(false)
                    performWithDelay(self.m_scWaitNode, function()
                        flyNode:removeFromParent()
                    end, 1.0)
                end, actionDelayTime)
            end, delayTime)
        end
    else
        local collectNodePos = self:getCurCollectNodePos(false)
        self:setCurCollectNodePos(-1)
        gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_collectBonus_disappear)
        self.tblCollectSpot[collectNodePos]:runCsbAction("xiaoshi", false, function()
            self.tblCollectSpot[collectNodePos]:setVisible(false)
            endCallFunc()
        end)
    end
end

function CodeGameScreenSoaringWealthMachine:playChangeRows(_callFunc, _curRowNum)
    local callFunc = _callFunc
    local curRowNum = _curRowNum
    self.m_curShowRow = self.nextSpinChangeRow

    local isRise = self.nextChangeRowType == self.enumChangeRowType["RISE"] and true or false

    if isRise then
        self:refreshShowRow_1(callFunc, isRise)
    else
        if curRowNum == 6 then
            self:refreshShowRow_1(callFunc, isRise)
        else
            self:refreshShowRow_2(callFunc, isRise)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:getCurDisPos(_collectNodePos)
    local collectNodePos = _collectNodePos
    local disX = 0
    local disY = 0
    if collectNodePos == 1 then
        disX = -300
        disY = 0
    elseif collectNodePos == 2 then
        disX = -150
        disY = 0
    elseif collectNodePos == 4 then
        disX = 150
        disY = 0
    elseif collectNodePos == 5 then
        disX = 300
        disY = 0
    end
    return disX, disY
end

function CodeGameScreenSoaringWealthMachine:getCurWildZorder(_col)
    local curCol = _col
    local tblZorderList = {}
    local symbolNode_4 = self:getFixSymbol(curCol , 4, SYMBOL_NODE_TAG)
    local symbolNode_6 = self:getFixSymbol(curCol , 6, SYMBOL_NODE_TAG)
    local symbolNode_8 = self:getFixSymbol(curCol , 8, SYMBOL_NODE_TAG)
    local zorder_4 = symbolNode_4:getLocalZOrder()
    local zorder_6 = symbolNode_6:getLocalZOrder()
    local zorder_8 = symbolNode_8:getLocalZOrder()
    if self.m_curShowRow == self.m_maxShowRow then
        tblZorderList = {zorder_4, zorder_6, zorder_8}
    elseif self.m_curShowRow == 6 then
        tblZorderList = {zorder_4, zorder_6}
    elseif self.m_curShowRow == self.m_minRow then
        tblZorderList = {zorder_4}
    end
    table.sort(tblZorderList, function(a, b)
        return a > b
    end)
    return tblZorderList[1]
end

function CodeGameScreenSoaringWealthMachine:setDragonPos(_symbolNode, _col)
    local curCol = _col
    local zorder = self:getCurWildZorder(curCol) + 10
    -- local zorder1 = _symbolNode:getLocalZOrder() + 1000
    _symbolNode:setLocalZOrder(zorder)

    local posY = (0.5-self.m_curShowRow)*self.m_SlotNodeH
    self.tblBigWildSpine[curCol]:setPosition(cc.p(-self.m_SlotNodeW/2, posY))

    self.tblBigWildSpine[curCol]:setName("allWildSpine")
    self.tblBigWildSpine[curCol]:retain()
    self.tblBigWildSpine[curCol]:removeFromParent()
    _symbolNode:addChild(self.tblBigWildSpine[curCol], 100)
    self.tblBigWildSpine[curCol]:release()
end

function CodeGameScreenSoaringWealthMachine:playChangeAllWild(_effectData)
    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_allWild_effect)
    local changeName = {"bian1", "bian2", "bian3"}
    local actionFrameNeme = {"actionframe1", "actionframe2", "actionframe3"}
    local playIndex = self:getCurShowIndex()
    local dalayTime = 30/30
    local isPlayEffect = false
    
    for i=2, 4 do
        local symbolNode = self:getFixSymbol(i , self.m_curShowRow, SYMBOL_NODE_TAG)
        if self.colChangeBigWild[i] == true and symbolNode then
            self.tblBigWildSpine[i] = nil
            self.tblBigWildSpine[i] = util_spineCreate("Socre_SoaringWealth_Wild",true,true)
            self:setDragonPos(symbolNode, i)
            util_spinePlay(self.tblBigWildSpine[i],changeName[playIndex],false)
            performWithDelay(self.m_scWaitNode, function()
                util_spinePlay(self.tblBigWildSpine[i],actionFrameNeme[playIndex],true)
                if not isPlayEffect then
                    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_allWild_SpittingFire)
                    isPlayEffect = true
                end
            end, dalayTime)
            --下边的wild不播actionFrame
            for j=1, self.m_curShowRow do
                local node = self:getFixSymbol(i , j, SYMBOL_NODE_TAG)
                if node then
                    node:setLineAnimName("idleframe")
                end
            end
        end
    end
    performWithDelay(self.m_scWaitNode, function()
        self.colChangeBigWild = {}
        if _effectData then
            _effectData.p_isPlay = true
            self:playGameEffect()
        end
    end, dalayTime)
end

function CodeGameScreenSoaringWealthMachine:cutWildSpine(_isIdle)
    local isIdle = _isIdle
    local actionFrameNeme = {"actionframe1", "actionframe2", "actionframe3"}
    local idleFrameName = {"idleframe1", "idleframe2", "idleframe3"}
    local playIndex = self:getCurShowIndex()
    for i=2, 4 do
        local symbolNode = self:getFixSymbol(i , self.m_curShowRow, SYMBOL_NODE_TAG)
        if self.colChangeBigWild[i] == true and symbolNode then
            if tolua.isnull(self.tblBigWildSpine[i]) then
                self.tblBigWildSpine[i] = util_spineCreate("Socre_SoaringWealth_Wild",true,true)
            end
            self:setDragonPos(symbolNode, i)
            if isIdle then
                util_spinePlay(self.tblBigWildSpine[i],idleFrameName[playIndex],true)
            else
                util_spinePlay(self.tblBigWildSpine[i],actionFrameNeme[playIndex],true)
            end
        end
    end
    self.colChangeBigWild = {}
end

function CodeGameScreenSoaringWealthMachine:playWinBonus(_effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local winBonus = selfData.winBonus
    local chooseBonus = selfData.chooseBonus
    local unChooseBonus = selfData.unChooseBonus

    local endCallFunc = function()
        if _effectData then
            _effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    local showCallFunc = function()
        self.maskNode:setVisible(false)
        self.m_jackpotView:setVisible(true)
        self.m_jackpotView:refreshRewardNode(winBonus, chooseBonus, unChooseBonus, endCallFunc)
    end
    performWithDelay(self.m_scWaitNode, function()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end
        self:showCutSceneAni(showCallFunc)
    end, 50/30)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenSoaringWealthMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenSoaringWealthMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenSoaringWealthMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenSoaringWealthMachine:beginReel()
    CodeGameScreenSoaringWealthMachine.super.beginReel(self)
    local idleFrameName = {"idleframe1", "idleframe2", "idleframe3"}
    local curShowIndex = self:getCurShowIndex()
    for i=2, 4 do
        if not tolua.isnull(self.tblBigWildSpine[i]) then
            util_spinePlay(self.tblBigWildSpine[i],idleFrameName[curShowIndex],true)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:updateNetWorkData()
    local callFunc = function()
        CodeGameScreenSoaringWealthMachine.super.updateNetWorkData(self)
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local curRowNum = self.m_curShowRow
    self.isQuickLongRun = false
    self.isWinBonus = false
    self:setNetMysteryType()
    self:updateCurInfo()
    self:updateCurrentInfo()
    if selfData and selfData.winBonus then
        self.isWinBonus = true
    end

    local isNoticeAni = self:checkIsFreeGame()
    if isNoticeAni then
        local random = math.random(1, 2)
        if random == 1 then
            isNoticeAni = false
        end
    end

    if self.nextChangeRowType == self.enumChangeRowType["RISE"] or self.nextChangeRowType == self.enumChangeRowType["DECLINE"] then
        self:playChangeRows(callFunc, curRowNum)
        self.nextChangeRowType = self.enumChangeRowType["NORMAL"]
    else
        local collectTimes = self.m_curConfigInfo.collectTimes
        if collectTimes and collectTimes[2] < 0 then
            self:playCollectBall()
        end
        if isNoticeAni then
            self.isQuickLongRun = true
            self:playNoticeAni(callFunc)
        else
            callFunc()
        end
    end
end

function CodeGameScreenSoaringWealthMachine:checkIsFreeGame()
    local features = self.m_runSpinResultData.p_features or {}
    if features and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN and self.m_curShowRow < self.m_maxShowRow then
        return true
    end
    return false
end

function CodeGameScreenSoaringWealthMachine:playNoticeAni(_callFunc)
    local callFunc = _callFunc
    local actionFrameName = {"yugao", "yugao2"}
    local tblActionNeme = {"yugao1", "yugao2", "yugao3"}
    local curShowIndex = self:getCurShowIndex()
    self.m_noticeSpine:setVisible(true)
    util_spinePlay(self.m_noticeSpine, actionFrameName[curShowIndex], false)
    util_spinePlay(self.m_dragonSpine,actionFrameName[curShowIndex], false)    
    self:runCsbAction(tblActionNeme[curShowIndex], false)

    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_noticeReward)
    performWithDelay(self.m_scWaitNode, function()
        self.m_noticeSpine:setVisible(false)
        self:setIdleType(3)
        if self.m_curShowRow == self.m_minRow then
            self:playDragonSpine(1)
        elseif self.m_curShowRow == 6 then
            self:playDragonSpine(2)
        end
        if callFunc then
            callFunc()
            callFunc = nil
        end
    end, 60/30)
end

function CodeGameScreenSoaringWealthMachine:updateCurInfo( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local spinConfigSend = selfdata.spinConfigSend 
    if spinConfigSend then
        self.m_curAllConfigInfo = spinConfigSend
    end
end

function CodeGameScreenSoaringWealthMachine:updateReelGridNode(_symbolNode)
    local allWildSpine = _symbolNode:getChildByName("allWildSpine")
    if allWildSpine then
        allWildSpine:removeFromParent()
    end
    if _symbolNode.p_symbolType then
        _symbolNode:setLineAnimName("actionframe")
        _symbolNode:setIdleAnimName("idleframe")
    end
end

function CodeGameScreenSoaringWealthMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        if not self.isWinBonus then
            self:reelsDownDelaySetMusicBGVolume( ) 
        end
    end)

    CodeGameScreenSoaringWealthMachine.super.slotReelDown(self)
end

function CodeGameScreenSoaringWealthMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenSoaringWealthMachine:getCurColumnIsAllWild(_isIdle)
    local isAllWild = false
    local isIdle = _isIdle
    for _reelCol = 2, 4 do
        local curWildNum = 0
        local isLine = false
        for iRow = 1, self.m_curShowRow do
            local slotNode = self:getFixSymbol(_reelCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                curWildNum = curWildNum + 1
                if isLine == false then
                    if self:curSymbolIsLine(iRow, _reelCol, isIdle) then
                        isLine = true
                    else
                        isLine = nil
                    end
                end
            end
        end
        if curWildNum == self.m_curShowRow and isLine then
            self.colChangeBigWild[_reelCol] = true
            isAllWild = true
        end
    end
    
    return isAllWild
end

function CodeGameScreenSoaringWealthMachine:curSymbolIsLine(_row, _col, _isIdle)
    local isIdle = _isIdle
    if isIdle then
        return true
    end
    local nodePos = self:getPosReelIdx(_row, _col)
    local linePos = self.m_runSpinResultData.p_winLines
    for k, v in pairs(linePos) do
        local iconPos = v.p_iconPos
        if iconPos then
            for i=1, #iconPos do
                if nodePos == iconPos[i] then
                    return true
                end
            end
        end
    end
    return false
end

function CodeGameScreenSoaringWealthMachine:getCurReelAniIdleName()
    if self.m_curConfigInfo.reelRows == 4 then
        return "idle1"
    elseif self.m_curConfigInfo.reelRows == 6 then
        return "idleliang1"
    elseif self.m_curConfigInfo.reelRows == 8 then
        return "idleliang2"
    end
end

-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenSoaringWealthMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_SoaringWealth_10"
    elseif symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_SoaringWealth_Bonus"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_BONUS then
        return "Socre_SoaringWealth_JackpotBonus"
    end
    return nil
end

--设置bonus scatter 层级
function CodeGameScreenSoaringWealthMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==  self.SYMBOL_SCORE_BONUS then
            order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType ==  self.SYMBOL_SCORE_JACKPOT_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
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

function CodeGameScreenSoaringWealthMachine:showJackpotWinView(_rewardType, _clickStateFunc, _callFunc)
    local rewardType = _rewardType
    local clickStateFunc = _clickStateFunc
    local callFunc = _callFunc
    self.m_jackpotWinView:refreshRewardType(rewardType, clickStateFunc, callFunc)
    self.m_jackpotWinView:setVisible(true)
    gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_jackpotStart)
    self.m_jackpotWinView:runCsbAction("start", false, function()
        self.m_jackpotWinView:setJumpCoinsOver()
        self.m_jackpotWinView:setClickState(true)
        self.m_jackpotWinView:runCsbAction("idle", true)
    end)
end

function CodeGameScreenSoaringWealthMachine:showJackpotOverView(_totalReward, _colseCallFunc)
    local colseCallFunc = _colseCallFunc
    local totalReward = _totalReward
    self.m_jackpotOverView:refreshRewardType(totalReward, colseCallFunc)
    self.m_jackpotOverView:setVisible(true)
    globalMachineController:playBgmAndResume(SoaringWealthMusicConfig.Music_bonusOver, 3, 0, 0)
    self.m_jackpotOverView:runCsbAction("start", false, function()
        self.m_jackpotOverView:setClickState(true)
        self:setWinCoins()
        self.m_jackpotOverView:runCsbAction("idle", true)
    end)
end

function CodeGameScreenSoaringWealthMachine:getBottomUi()
    return self.m_bottomUI
end

--BottomUI接口
function CodeGameScreenSoaringWealthMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenSoaringWealthMachine:playhBottomLight(_endCoins, _endCallFunc)
    self.m_bottomUI:playCoinWinEffectUI(_endCallFunc)

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

function CodeGameScreenSoaringWealthMachine:setWinCoins()
    local totalCoins = self.m_runSpinResultData.p_winAmount
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    if totalCoins and lastWinCoin then
        if totalCoins > lastWinCoin then
            self:setLastWinCoin(0)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:getCurBottomWinCoins()
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

function CodeGameScreenSoaringWealthMachine:changeBgSpine(_bgType, _isOpacticy)
    local tblIdleBgName = {"idleframe", "idleframe2", "idleframe3"}
    local tblIdleCloudName = {"idleframe3", "idleframe2", "idleframe"}
    local bgType = _bgType
    local isOpacticy = _isOpacticy
    
    if isOpacticy then
        if self.tblGameBgNode[1]:getOpacity() == 0 then
            util_spinePlay(self.tblBaseBgSpine[1], tblIdleBgName[bgType], true)
            self.tblCloudAni[1]:runCsbAction(tblIdleCloudName[bgType], true)
        else
            util_spinePlay(self.tblBaseBgSpine[2], tblIdleBgName[bgType], true)
            self.tblCloudAni[2]:runCsbAction(tblIdleCloudName[bgType], true)
        end
        self:changeOpacticyNode()
    else
        for i=1, 2 do
            util_spinePlay(self.tblBaseBgSpine[i], tblIdleBgName[bgType], true)
            self.tblCloudAni[i]:runCsbAction(tblIdleCloudName[bgType], true)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:changeOpacticyNode()
    local delayTime = 60/60
    local tblAction = {}
    local actFadeIn = cc.FadeIn:create(delayTime)
    local actFadeOut = cc.FadeOut:create(delayTime)

    if self.tblGameBgNode[1]:getOpacity() == 0 then
        self.tblCloudNode[1]:runAction(cc.FadeIn:create(delayTime))
        self.tblCloudNode[2]:runAction(cc.FadeOut:create(delayTime))
        self.tblGameBgNode[1]:runAction(cc.FadeIn:create(delayTime))
        self.tblGameBgNode[2]:runAction(cc.FadeOut:create(delayTime))
    else
        self.tblCloudNode[1]:runAction(cc.FadeOut:create(delayTime))
        self.tblCloudNode[2]:runAction(cc.FadeIn:create(delayTime))
        self.tblGameBgNode[1]:runAction(cc.FadeOut:create(delayTime))
        self.tblGameBgNode[2]:runAction(cc.FadeIn:create(delayTime))
    end
end

function CodeGameScreenSoaringWealthMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and self:curNodeIsRow(_slotNode) then
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

function CodeGameScreenSoaringWealthMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false
    local selfData = self.m_runSpinResultData.p_selfMakeData

    if #self.m_vecGetLineInfo == 0 and (not selfData or not selfData.winBonus) then
        notAdd = true
    end

    return notAdd
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenSoaringWealthMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and self:curNodeIsRow(_slotNode) then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self:isSymbolBonus(_slotNode) then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if (self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true or self:isSymbolBonus(_slotNode)) then
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

function CodeGameScreenSoaringWealthMachine:curNodeIsRow(_node)
    local node = _node
    local isPlay = true
    if (node.p_cloumnIndex == 1 or node.p_cloumnIndex == 5) and node.p_rowIndex > 3 then
        isPlay = false
    elseif node.p_cloumnIndex > 1 and node.p_cloumnIndex < 5 and node.p_rowIndex > self.m_curShowRow then
        isPlay = false
    end
    return isPlay
end

function CodeGameScreenSoaringWealthMachine:getCurBonusScatterRow(_column)
    local column = _column
    local curRow = 3
    if column == 1 or column == 5 then
        curRow = 3
    else
        curRow = self.m_curShowRow
    end
    return curRow
end

function CodeGameScreenSoaringWealthMachine:isSymbolBonus(_symbolNode)
    if _symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS or _symbolNode.p_symbolType == self.SYMBOL_SCORE_JACKPOT_BONUS then
        return true
    else
        return false
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenSoaringWealthMachine:symbolBulingEndCallBack(node)
    if node.p_symbolType then
        if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self:isSymbolBonus(node) then
            node:runAnim("idleframe", true)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

--设置bonus scatter 信息
function CodeGameScreenSoaringWealthMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    --设置滚动状态
    local runStatus = 
    {
        DUANG = 1,
        NORUN = 2,
    }
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
    local iRow = self:getCurBonusScatterRow(column)--columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            if not self.curScatterCol or self.curScatterCol ~= column then
                allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            end

            self.curScatterCol = column
            
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

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true and not self.isQuickLongRun then
        self.isQuickLongRun = false
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenSoaringWealthMachine:playScatterTipMusicEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalSoundManager:playSound(SoaringWealthMusicConfig.Music_triggerFgScatter)
    else
        if self.m_ScatterTipMusicPath ~= nil then
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 4, 0, 0)
        end
    end
end

function CodeGameScreenSoaringWealthMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    else
        self.m_currentMusicBgName = self:getCurBgMusic()
    end

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
    gLobalSoundManager:setBackgroundMusicVolume(1)
end

function CodeGameScreenSoaringWealthMachine:getCurBgMusic()
    if self.m_curShowRow == self.m_minRow then
        return SoaringWealthMusicConfig.Music_Base_Bg
    else
        return SoaringWealthMusicConfig.Music_Base_Rise_Bg
    end
end

return CodeGameScreenSoaringWealthMachine






