---
-- island li
-- 2019年1月26日
-- CodeGameScreenFrogPrinceMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local FrogPrinceSlotsNode = require "CodeFrogPrinceSrc.FrogPrinceSlotsNode"
local CodeGameScreenFrogPrinceMachine = class("CodeGameScreenFrogPrinceMachine", BaseFastMachine)

CodeGameScreenFrogPrinceMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenFrogPrinceMachine.m_betLevel = nil
CodeGameScreenFrogPrinceMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 -- 自定义的小块类型

CodeGameScreenFrogPrinceMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenFrogPrinceMachine.EFFECT_TYPE_COLLECT_BONUS = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenFrogPrinceMachine.EFFECT_SHOW_BONUS_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 3

CodeGameScreenFrogPrinceMachine.boxVec = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}


-- 构造函数
function CodeGameScreenFrogPrinceMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_FsDownTimes = 0
    self.m_betLevel = nil
    self.m_baseReelSymbolType = 0
    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

function CodeGameScreenFrogPrinceMachine:initGame()

    --初始化基本数据
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FrogPrinceConfig.csv", "LevelFrogPrinceConfig.lua")
    self.m_configData:initMachine(self)
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFrogPrinceMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FrogPrince"
end


function CodeGameScreenFrogPrinceMachine:initUI()
    -- self:initFreeSpinBar() -- FreeSpinbar

    self.m_collectView = util_createView("CodeFrogPrinceSrc.FrogPrinceCollectView")
    self.m_csbOwner["_jindutiao"]:addChild(self.m_collectView)
    local collectData = self:BaseMania_getCollectData()
    self.m_collectView:setMachine(self)
    self.m_collectView:initViewData(collectData.p_collectCoinsPool, collectData.p_collectLeftCount, collectData.p_collectTotalCount)

    self.m_RunDi = {}
    for i = 1, 5 do
        local longRunDi = util_createAnimation("WinFrameFrogPrince_run_0.csb")
        self:findChild("Node_1"):addChild(longRunDi, 1)
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_" .. (i - 1)):getPosition()))
        longRunDi:setVisible(false)
        table.insert(self.m_RunDi, longRunDi)
    end
    self:runCsbAction("idle")
    -- self:createFrogPrinceWheelView()
    
    -- activity 收集的起点
    local worldPos, reelHeight, reelWidth = self:getReelPos(3)
    globalData.bingoCollectPos = cc.p(worldPos.x + reelWidth * 0.5, worldPos.y + reelHeight * 0.5)
    
    self.m_tipView = util_createAnimation("FrogPrince_jackPoTip.csb")
    self:findChild("FrogPrince_jackPoTip"):addChild(self.m_tipView)
    self:findChild("FrogPrince_jackPoTip"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    self.m_tipView:setVisible(false)

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

    performWithDelay(self.m_actNode,function(  )
        
        if self:isNormalStates( ) then
            self.m_tipView:setVisible(true)
            self.m_tipView:runCsbAction("open",false,function(  )

                if not  self.m_tipView.isSpin then
                    self.m_tipView:runCsbAction("idle",true)

                    performWithDelay(self.m_actNode,function(  )
                        if not  self.m_tipView.isSpin then
                            self.m_tipView.isOverAct = true
                            self.m_tipView:runCsbAction("over",false)
                        end
                        
                    end,3)
                end
                

            end)
        end
    end,0.1)
    

    

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 1
            local soundTime = 1
            if winRate < 1 then
                soundIndex = 1
            elseif winRate >= 1 and winRate < 3 then
                soundIndex = 2
                soundTime = 3
            else
                soundIndex = 3
                soundTime = 4
            end

            local soundName = "FrogPrinceSounds/sound_FrogPrince_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
    self.pos = cc.p(0, 0)
end

--中奖线 上是否有信号wild
function CodeGameScreenFrogPrinceMachine:checkIsLinesHaveWildSymbol()
    --接下来判断连线上是否有信号块Wild
    local winLines = self.m_runSpinResultData.p_winLines
    if winLines and #winLines > 0 then
        for i = 1, #winLines do
            local lineData = winLines[i]
            if lineData.p_iconPos and #lineData.p_iconPos > 0 then
                for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                    local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                    local checkEnd = false
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]
                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function CodeGameScreenFrogPrinceMachine:createFrogPrinceWheelView()
    self.m_wheelView = util_createView("CodeFrogPrinceSrc.FrogPrinceWheelViewBg")
    self:findChild("wheelNode"):addChild(self.m_wheelView)
    self.m_wheelView:initMachine(self)
    self:changeNormalAndFreespinReel(2)
    self.m_wheelView:playOpenAction()
    self:runCsbAction(
        "over",
        false,
        function()
            self:findChild("reel"):setVisible(false)
            self.m_currentMusicBgName = "FrogPrinceSounds/sound_FrogPrince_wheel.mp3"
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    )
end

function CodeGameScreenFrogPrinceMachine:isNormalStates( )
    
    if self.m_bIsInBonusGame then

        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        return false

    end

    return true
end

function CodeGameScreenFrogPrinceMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.m_bIsInBonusGame then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    else
                        self.m_currentMusicBgName = "FrogPrinceSounds/music_FrogPrince_bonusgame.mp3"
                        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
                    end
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenFrogPrinceMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    if self.m_collectView then
        self.m_collectView:setPercent(self.m_collectProgress)
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self:upateBetLevel()
end

function CodeGameScreenFrogPrinceMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upateBetLevel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.getCurrSpinMode() ~= RESPIN_MODE and self.getCurrSpinMode() ~= FREE_SPIN_MODE then
                -- gLobalSoundManager:playSound("PirateSounds/sound_pirate_freespin_start.mp3")
                local selfData = self.m_runSpinResultData.p_selfMakeData
                local num = 0
                if selfData and selfData.pigNum then
                    num = selfData.pigNum
                end
                self:showBonusView(
                    num,
                    true,
                    function()
                        self.m_collectView:setButtonTouchEnabled(true)
                        self.m_bonusView:removeFromParent()
                        self.m_bonusView = nil
                        self.m_collectView:setClickFlag(true)
                    end
                )
            end
        end,
        "SHOW_BONUS_MAP"
    )
end

function CodeGameScreenFrogPrinceMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


-- 根据类型获取对应节点
--
function CodeGameScreenFrogPrinceMachine:getSlotNodeBySymbolType(symbolType)
    
    if self:getMysteryChangeToType() then
        if symbolType == 93 then
            symbolType = self:getMysteryChangeToType()
        end
    else
        if symbolType == 93 then
            symbolType = 0
        end
    end
    local reelNode = BaseSlotoManiaMachine.getSlotNodeBySymbolType(self,symbolType)

    return reelNode
end

--小块
function CodeGameScreenFrogPrinceMachine:getBaseReelGridNode()
    return "CodeFrogPrinceSrc.FrogPrinceSlotsNode"
end


--- 获取ccbname 根据symbol type
function CodeGameScreenFrogPrinceMachine:getSymbolCCBNameByType(MainClass, symbolType)
    if self:getMysteryChangeToType() then
        if symbolType == 93 then
            symbolType = self:getMysteryChangeToType()
        end
    else
        if symbolType == 93 then
            symbolType = 0
        end
    end
    local ccbName = BaseFastMachine.getSymbolCCBNameByType(self,self, symbolType)
    return ccbName
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFrogPrinceMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_FrogPrince_10"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFrogPrinceMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)

    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 15}
    }
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 15}

    return loadNode
end
function CodeGameScreenFrogPrinceMachine:getBetLevel()
    return self.m_betLevel
end
--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenFrogPrinceMachine:upateBetLevel()
    local minBet = self:getMinBet()

    self:updateHighLowBetLock(minBet)
end

function CodeGameScreenFrogPrinceMachine:getMinBet()
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

function CodeGameScreenFrogPrinceMachine:updateHighLowBetLock(minBet)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_clickBet = true
            self.m_betLevel = 1
            self.m_collectView:playOpenLock()
            -- self.m_collectView:setClickFlag(true)
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            -- self.m_collectView:setClickFlag(false)
            self.m_betLevel = 0
            self.m_collectView:playLock()
            self.m_collectView:setHighLowBetNum(minBet)
        else
            
        end
    end
end
----------------------------- 玩法处理 -----------------------------------
--
--单列滚动停止回调
--
function CodeGameScreenFrogPrinceMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            gLobalSoundManager:playSound(self.m_reelDownSound)  
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound) 
    end

    --GoldWild and Scatter  play "buling" animation
    local isHaveWild = false
    for iRow = 1, self.m_iReelRowNum do
        -- local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, iRow, SYMBOL_NODE_TAG))
        if targSp and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self.m_scatterNum = self.m_scatterNum + 1
            targSp = self:setSymbolToClipReel(reelCol, iRow, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            if targSp then
                targSp:runAnim("buling",false, function( )
                    targSp:resetReelStatus()
                end)
            end
            local soundIndex = 1
            if self.m_scatterNum == 1 then
                soundIndex = 1
            elseif self.m_scatterNum == 2 then
                soundIndex = 2
            else
                soundIndex = 3
            end

            local soundPath = "FrogPrinceSounds/sound_FrogPrince_scatter" .. soundIndex .. ".mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath,TAG_SYMBOL_TYPE.SYMBOL_SCATTER )
            else
                gLobalSoundManager:playSound(soundPath)
            end

        end
    end

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end
    if reelCol > 2 then
        local rundi = self.m_RunDi[reelCol]
        if rundi:isVisible() then
            rundi:playAction(
                "stop",
                false,
                function()
                    rundi:setVisible(false)
                end
            )
        end
    end
    if reelCol == 5 then
        if self.m_fastRunID then
            gLobalSoundManager:stopAudio(self.m_fastRunID)
            self.m_fastRunID = nil
        end
    end
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end
--添加金边
function CodeGameScreenFrogPrinceMachine:creatReelRunAnimation(col)
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
    -- if self.m_fastRunID == nil  then
    --     self.m_fastRunID = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_reel_run.mp3")
    -- end
    if col > 2 then
        local rundi = self.m_RunDi[col]
        if rundi then
            rundi:setVisible(true)
            rundi:playAction("run")
        end
    end
    reelEffectNode:setVisible(true)
    util_setCascadeOpacityEnabledRescursion(reelEffectNode, true)
    reelEffectNode:setOpacity(0)
    util_playFadeInAction(reelEffectNode, 0.1)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_fast_run.mp3")
end

function CodeGameScreenFrogPrinceMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        local linePos = {}
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = true
        targSp:setLinePos(linePos)
    end
    return targSp
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFrogPrinceMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFrogPrinceMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenFrogPrinceMachine:showFreeSpinView(effectData)
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_scatter_begin.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        else
            self:clearCurMusicBg()
            self.m_effectData = effectData
            self:createFrogPrinceWheelView()
        end
    end

    --全部scatter的触发动画
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    targSp:runAnim("actionframe",false, function( )
                        targSp:resetReelStatus()
                    end)
                     -- gLobalSoundManager:playSound("PirateSounds/sound_Pirate_scatter_ground.mp3")
                end
            end
        end
    end
    --  延迟1.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        4.5
    )
end

function CodeGameScreenFrogPrinceMachine:showFreeSpinStartView()
    performWithDelay(
        self,
        function()
            self:findChild("reel"):setVisible(false)
            self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    local reelNum = self.m_runSpinResultData.p_selfMakeData.reelNum
                    self.m_wheelView:playWheelOverEffect(
                        reelNum,
                        function()
                            self:initMiniMachine(false)
                            performWithDelay(
                                self,
                                function()
                                    self.m_wheelView:removeFromParent()
                                    self.m_wheelView = nil
                                end,
                                1.2
                            )
                        end
                    )
                end
            )
        end,
        1.5
    )
end

function CodeGameScreenFrogPrinceMachine:showFreeSpinStart(num, func)
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_freespin_start.mp3")
    self:clearCurMusicBg()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local lockReelDataNum = {2, 3, 2, 2, 2, 1, 4, 2}
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_num_1"] = selfData.reelNum
    local reelnum = lockReelDataNum[selfData.wildClosIndex + 1]
    ownerlist["m_lb_num_2"] = reelnum
    local view = self:showFrogPrinceDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local root = self.m_machineNode:getChildByName("root")
    if root then
        local scale = root:getScale()
        view:setScale(scale)
    end
    return view
end

function CodeGameScreenFrogPrinceMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_freespin_over.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_small_reel_shou.mp3")
            self:changeNormalAndFreespinReel(3)
            -- self:runCsbAction("idle")
            self:findChild("reel"):setVisible(true)
            self.m_baseFreeSpinBar:setVisible(false)
            self:runCsbAction(
                "start",
                false,
                function()
                    self:runCsbAction("idle")
                end
            )
            self.m_vecMiniWheelBg:runCsbAction(
                "over",
                false,
                function()
                    self:triggerFreeSpinOverCallFun()
                    self:removeMiniMachine()
                    self:resetMusicBg(true)
                end
            )
          
        end
    )
    local root = self.m_machineNode:getChildByName("root")
    if root then
        local scale = root:getScale()
        view:setScale(scale)
    end
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
end

--重写FreeSpinOver
function CodeGameScreenFrogPrinceMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    return self:showFrogPrinceDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func)
end

--添加到 轮盘节点上 适配 
function CodeGameScreenFrogPrinceMachine:showFrogPrinceDialog(ccbName,ownerlist,func,isAuto,index)
    local view=util_createView("Levels.BaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    self:findChild("ViewNode"):addChild(view)
    return view
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFrogPrinceMachine:MachineRule_SpinBtnCall()
    self.m_scatterNum = 0
    gLobalSoundManager:setBackgroundMusicVolume(1)
   
    
    

    if not self.m_tipView.isOverAct then
        
        if not self.m_tipView.isSpin then
            self.m_tipView:runCsbAction("over",false,function(  )
                self.m_tipView:setVisible(false)
            end) 
        end
        
    end
    
    self.m_tipView.isSpin = true

    

    if self.m_bonusView then
        self.m_bonusView:hideBoxView()
    end
    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenFrogPrinceMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFrogPrinceMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCoins = self.m_runSpinResultData.p_collectNetData[1].collectCoinsPool
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        self:BaseMania_updateCollect(addCount, addCoins, 1, totalCount)
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFrogPrinceMachine:addSelfEffect()
    self.m_collectList = nil
    if self:getBetLevel() == 1 then
        if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE or globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if node then
                        if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                            if not self.m_collectList then
                                self.m_collectList = {}
                            end
                            self.m_collectList[#self.m_collectList + 1] = node
                            node:runAnim("actionframe")
                        end
                    end
                end
            end

            if self.m_collectList and #self.m_collectList > 0 then
                local addCount = #self.m_collectList
                --收集bonus
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT

                --是否触发收集小游戏
                if self:BaseMania_isTriggerCollectBonus() then
                    -- 收集满了之后的自定义操作
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT_BONUS
                end
            end
        end

        local openBonusView = self.m_runSpinResultData.p_selfMakeData.isNewCollect
        if openBonusView == 1 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_SHOW_BONUS_COLLECT
        else
            self.m_collectView:setButtonTouchEnabled(true)
        end
    else
        self.m_collectView:setButtonTouchEnabled(true)
    end
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData then
        self.m_baseReelSymbolType = self.m_runSpinResultData.p_selfMakeData.nextBaseChageSignal
    end
end

--是否触发收集小游戏
function CodeGameScreenFrogPrinceMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
    return false
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFrogPrinceMachine:MachineRule_playSelfEffect(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isCollectGame = nil
    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        if self.m_collectList and #self.m_collectList > 0 then
            self:flyBonus(
                self.m_collectList,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
        end
    end

    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT_BONUS then
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    if effectData.p_selfEffectType == self.EFFECT_SHOW_BONUS_COLLECT then
        self.m_effectData = effectData
        self.m_collectView:playCollectfull(
            function()
                local collectEffect = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusOpenView")
                self:findChild("bonusEffectNode"):addChild(collectEffect)
                local root = self.m_machineNode:getChildByName("root")
                if root then
                    local scale = root:getScale()
                    collectEffect:setScale(scale)
                end
                local num = selfData.pigNum
                local str = self:getValueByPos(num)
                local lab1 = collectEffect:findChild("m_lb_coins_1")
                local lab2 = collectEffect:findChild("m_lb_coins_2")
                lab1:setString(str)
                lab2:setString(str)
                gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_bigbox_fly.mp3")
                collectEffect:runCsbAction(
                    "actionframe",
                    false,
                    function()
                        gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_lab_run.mp3")
                        collectEffect:removeFromParent()
                        -- collectEffect:runCsbAction(
                        --     "actionframe2",
                        --     false,
                        --     function()
                        --         collectEffect:removeFromParent()
                        --     end
                        -- )
                    end
                )
                self:showBonusView(
                    num,
                    false,
                    function()
                        if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
                            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
                            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
                            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
                            if self.m_effectData ~= nil then
                                self.m_effectData.p_isPlay = true
                                self:playGameEffect()
                                self.m_collectView:setButtonTouchEnabled(true)
                            end
                        else
                            self.m_bonusView:removeFromParent()
                            self.m_bonusView = nil
                            self.m_collectView:setClickFlag(true)
                            self.m_collectView:resetProgress(function()
                                if self.m_effectData ~= nil then
                                    self.m_effectData.p_isPlay = true
                                    self:playGameEffect()
                                    self.m_collectView:setButtonTouchEnabled(true)
                                end
                            end)
                        end
                    end
                )
            end
        )
    end
    return true
end
--获取位置对应的字母
function CodeGameScreenFrogPrinceMachine:getValueByPos(pos)
    return self.boxVec[pos]
end

function CodeGameScreenFrogPrinceMachine:showBonusView(_num, _flag, _func)
    if self.m_bonusView == nil then
        self.m_bonusView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusView")
        self.m_bonusView:initMachine(self)
        self:findChild("bonusNode"):addChild(self.m_bonusView)
    end
    self.m_bonusView:setFunCall(_func)
    self.m_bonusView:setOpenBonusFlag(_flag)
    self.m_bonusView:showBoxView(_num)
  
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFrogPrinceMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenFrogPrinceMachine:initCollectInfo(spinData, lastBetId, isTriggerCollect)
    local collectData = self:BaseMania_getCollectData()
    local num = self.m_runSpinResultData.p_selfMakeData.pigNum
    if  collectData.p_collectLeftCount == 0 then
        collectData.p_collectLeftCount = collectData.p_collectTotalCount
    end
    self.m_collectView:updateCollect(num, collectData.p_collectLeftCount, collectData.p_collectTotalCount, time)
end

function CodeGameScreenFrogPrinceMachine:updateCollect(time)
    local collectData = self:BaseMania_getCollectData()
    local num = self.m_runSpinResultData.p_selfMakeData.pigNum
    self.m_collectView:updateCollect(num, collectData.p_collectLeftCount, collectData.p_collectTotalCount, time)
end

function CodeGameScreenFrogPrinceMachine:BaseMania_initCollectDataList()
    local CollectData = require "data.slotsdata.CollectData"
    --收集数组
    self.m_collectDataList = {}
    --默认总数
    local pools = {10, 10}
    for i = 1, 2 do
        self.m_collectDataList[i] = CollectData.new()
        self.m_collectDataList[i].p_collectTotalCount = pools[i]
        self.m_collectDataList[i].p_collectLeftCount = 0
        self.m_collectDataList[i].p_collectCoinsPool = 0
        self.m_collectDataList[i].p_collectChangeCount = 0
    end
end

--更新收集数据 addCount增加的数量  addCoins增加的奖金
function CodeGameScreenFrogPrinceMachine:BaseMania_updateCollect(addCount, addCoins, index, totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectCoinsPool = addCoins
        self.m_collectDataList[index].p_collectChangeCount = 0
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

--收集完成重置收集进度
function CodeGameScreenFrogPrinceMachine:BaseMania_completeCollectBonus(index, totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectTotalCount = totalCount or 200
        self.m_collectDataList[index].p_collectLeftCount = totalCount or 200
        self.m_collectDataList[index].p_collectCoinsPool = 0
        self.m_collectDataList[index].p_collectChangeCount = 0
    end
end

function CodeGameScreenFrogPrinceMachine:removeFlynode(node)
    node:setVisible(true)
    node:removeFromParent()
end

--使用的假滚
function CodeGameScreenFrogPrinceMachine:getMachineBaseType()
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData then
        return self.m_runSpinResultData.p_selfMakeData.nextBaseReelName
    end
end

--Mystery变为的类型
function CodeGameScreenFrogPrinceMachine:getMysteryChangeToType()
    if self.m_baseReelSymbolType ~= nil  then
        return self.m_baseReelSymbolType
    end
end

--收集玩法
function CodeGameScreenFrogPrinceMachine:flyBonus(list, func)
    local endPos = self.m_collectView:getCollectPos()
    local bezTime = 1
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_collect_fly.mp3")
    local isShowCollect = false

    for _, node in pairs(list) do
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local coins, coinsAct = util_csbCreate("FrogPrince_collect_bonus.csb")
        util_csbPlayForKey(coinsAct, "start", false)
        local root = self.m_machineNode:getChildByName("root")
        if root then
            local scale = root:getScale()
            coins:setScale(scale)
        end
        self:findChild("wheelNode"):addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        -- coins:runAnim("actionframe")
        coins:setPosition(newStartPos)
        local bez = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        -- local scale = cc.ScaleTo:create(0.5, 0.6)
        -- local spw = cc.Spawn:create(bez, scale)
        coins:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), bez))

        local par = self:createFlyPart()
        par:setPosition(newStartPos)
        self:findChild("wheelNode"):addChild(par, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        local bez1 = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        local scale1 = cc.ScaleTo:create(0.5, 0.6)
        local spw1 = cc.Spawn:create(bez1, scale1)
        par:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), spw1))
        scheduler.performWithDelayGlobal(
            function()
                self.m_collectView:showAddAnim()
                if isShowCollect == false then
                    isShowCollect = true
                end
                par:removeFromParent()
                self:removeFlynode(coins)
                coins = nil
            end,
            bezTime + 0.1,
            self:getModuleName()
        )
    end
    if list and #list > 0 then
        if self:IsCanClickSpin() then
            if func ~= nil then
                func()
            end
        else
            scheduler.performWithDelayGlobal(
                function()
                    if func ~= nil then
                        func()
                    end
                end,
                1.5,
                self:getModuleName()
            )
        end
        scheduler.performWithDelayGlobal(
            function()
                self:updateCollect(0.1, collectData)
            end,
            1.1,
            self:getModuleName()
        )
    else
        if func ~= nil then
            func()
        end
    end
end

function CodeGameScreenFrogPrinceMachine:createFlyPart()
    local par = cc.ParticleSystemQuad:create("effect/FrogPrince_shouji_lizi1.plist")
    return par
end
--收集不触发效果可以快点
function CodeGameScreenFrogPrinceMachine:IsCanClickSpin()
    local isHave = true
    for i = 1, #self.m_gameEffects do
        local effectData = self.m_gameEffects[i]
        local effectType = effectData.p_selfEffectType
        if effectType == self.EFFECT_SHOW_BONUS_COLLECT then
            isHave = false
        end
    end
    return isHave
end
----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenFrogPrinceMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        else
            self:initMiniMachine(true)
            self:findChild("reel"):setVisible(false)
            self:changeNormalAndFreespinReel(1)
        end
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
    elseif self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        self:triggerFreeSpinCallFun()
    end
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData then
        self.m_baseReelSymbolType = self.m_runSpinResultData.p_selfMakeData.nextBaseChageSignal
    end
    -- local num = self.m_runSpinResultData.p_selfMakeData.pigNum
    -- self.m_collectView:initCollectNum(num)
end

function CodeGameScreenFrogPrinceMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == false then
        self:playGameEffect()
        return
    end

    if featureData.p_status == "OPEN" then
        self:changeNormalAndFreespinReel(1)
        self.m_bonusView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusView")
        self.m_bonusView:initMachine(self)
        self.m_bonusView:initReconnectView(spinData, self)
        self:findChild("bonusNode"):addChild(self.m_bonusView)
        self.m_bottomUI:setVisible(false)
        self:findChild("reel"):setVisible(false)
        self.m_bonusView:runCsbAction("start2")

        if self.m_bProduceSlots_InFreeSpin ~= true then
            self.m_bottomUI:checkClearWinLabel()
        else
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(spinData.p_fsWinCoins))
        end
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(spinData.p_fsWinCoins))
        end
        performWithDelay(
            self,
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            end,
            0.1
        )
        self.m_bIsInBonusGame = true
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        local featureID = spinData.p_features[#spinData.p_features]

        if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            table.remove(self.m_runSpinResultData.p_features, #self.m_runSpinResultData.p_features)
        end

        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        end
    end

    if featureData.p_data ~= nil and featureData.p_data.freespin ~= nil then
        self.m_runSpinResultData.p_freeSpinsLeftCount = featureData.p_data.freespin.freeSpinsLeftCount
        self.m_runSpinResultData.p_freeSpinsTotalCount = featureData.p_data.freespin.freeSpinsTotalCount
    end
end

function CodeGameScreenFrogPrinceMachine:initGameStatusData(gameData)
    if gameData.collect ~= nil then
        self.m_collectProgress = self:getProgress(gameData.collect[1])
    else
        self.m_collectProgress = 0
    end
    BaseFastMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenFrogPrinceMachine:initMiniMachine(bReconnect)
    self.m_vecMiniWheel = {} -- mini轮盘列表
    local reelNum = self.m_runSpinResultData.p_selfMakeData.reelNum
    self.m_vecMiniWheelBg = util_createView("CodeFrogPrinceSrc.MiniReel.FrogPrinceMiniReelsBg", reelNum)
    self:findChild("miniReels"):addChild(self.m_vecMiniWheelBg)
    if  display.height/display.width >= 768/1024 then
        self.m_vecMiniWheelBg:setScale(0.9)
    end
    local LockReels = self.m_runSpinResultData.p_selfMakeData.wildClos
    for i = 1, reelNum do
        local name = "Node_" .. i
        local addNode = self.m_vecMiniWheelBg:findChild(name)
        if addNode then
            local data = {}
            data.index = i
            data.parent = self
            local miniMachine = util_createView("CodeFrogPrinceSrc.MiniReel.FrogPrinceMiniMachine", data)
            addNode:addChild(miniMachine)
            miniMachine:setCurrSpinMode(FREE_SPIN_MODE)
            table.insert(self.m_vecMiniWheel, miniMachine)

            if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
                self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniMachine.m_touchSpinLayer)
            end
        end
    end
    if bReconnect then
        self.m_vecMiniWheelBg:runCsbAction("idle", false)
        for i = 1, #self.m_vecMiniWheel do
            miniMachine = self.m_vecMiniWheel[i]
            miniMachine:initReconnectLockReels(LockReels)
        end
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_baseFreeSpinBar = util_createView("CodeFrogPrinceSrc.FrogPrinceFreespinBarView")
        self.m_baseFreeSpinBar:setPosition(0, 0)
        self.m_vecMiniWheelBg:findChild("FrogPrince_4rl_jushu"):addChild(self.m_baseFreeSpinBar)
        self.m_baseFreeSpinBar:setVisible(true)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
    else
        local strName = "start"
        if reelNum > 2 then
            strName = "start2"
        end
        self.m_vecMiniWheelBg:runCsbAction(
            strName,
            false,
            function()
                for i = 1, #self.m_vecMiniWheel do
                    miniMachine = self.m_vecMiniWheel[i]
                    miniMachine:initLockReels(LockReels)
                end
                gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_wild_to_big.mp3")
                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

                self.m_baseFreeSpinBar = util_createView("CodeFrogPrinceSrc.FrogPrinceFreespinBarView")
                self.m_baseFreeSpinBar:setPosition(0, 0)
                self.m_vecMiniWheelBg:findChild("FrogPrince_4rl_jushu"):addChild(self.m_baseFreeSpinBar)
                self.m_baseFreeSpinBar:setVisible(true)
                self.m_baseFreeSpinBar:changeFreeSpinByCount()
                performWithDelay(
                    self,
                    function()
                        self:triggerFreeSpinCallFun()
                        self.m_effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    3.0
                )
            end
        )
    end
end

function CodeGameScreenFrogPrinceMachine:removeMiniMachine()
    for i = 1, #self.m_vecMiniWheel do
        local reels = self.m_vecMiniWheel[i]
        reels:removeFromParent()
    end
    self.m_vecMiniWheel = nil
    self.m_baseFreeSpinBar:removeFromParent()
    self.m_vecMiniWheelBg:removeFromParent()
    globalData.slotRunData.levelConfigData = self.m_configData
    -- 配置全局信息，供外部使用
    globalData.slotRunData.levelGetAnimNodeCallFun = function(symbolType, ccbName)
        return self:getAnimNodeFromPool(symbolType, ccbName)
    end
    globalData.slotRunData.levelPushAnimNodeCallFun = function(animNode, symbolType)
        self:pushAnimNodeToPool(animNode, symbolType)
    end
end

function CodeGameScreenFrogPrinceMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:resetReelDataAfterReel()

        for i = 1, #self.m_vecMiniWheel do
            local reels = self.m_vecMiniWheel[i]
            reels:beginMiniReel()
        end
    else
        BaseFastMachine.beginReel(self)
        self.m_collectView:setButtonTouchEnabled(false)
    end
end

function CodeGameScreenFrogPrinceMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if (self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE) then
        local delayTime = 0.5

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            delayTime = 1.5
            local lines = {}

            for i = 1, #self.m_vecMiniWheel do
                local reels = self.m_vecMiniWheel[i]
                local miniReelslines = reels:getResultLines()

                if miniReelslines then
                    for i = 1, #miniReelslines do
                        table.insert(lines, miniReelslines[i])
                    end
                end
            end

            if lines ~= nil and #lines > 0 then
                delayTime = delayTime + self:getWinCoinTime()
                if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsLeftCount then
                    if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                        delayTime = 0.5
                    end
                end
            end
        else
            if self.m_reelResultLines ~= nil and #self.m_reelResultLines > 0 then
                delayTime = delayTime + self:getWinCoinTime()
            end
        end

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end
-- 处理spin 返回结果
function CodeGameScreenFrogPrinceMachine:spinResultCallFun(param)
    BaseFastMachine.spinResultCallFun(self, param)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if param[1] == true then
            local spinData = param[2]
            if spinData.result then
                if spinData.result.selfData then
                    if spinData.result.selfData.spinResults then
                        local datas = spinData.result.selfData.spinResults

                        for i = 1, #self.m_vecMiniWheel do
                            local miniReelsData = datas[i]
                            miniReelsData.bet = 0
                            miniReelsData.payLineCount = 0
                            local reels = self.m_vecMiniWheel[i]
                            reels:netWorkCallFun(miniReelsData)
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenFrogPrinceMachine:setFsAllRunDown(times)
    self.m_FsDownTimes = self.m_FsDownTimes + times
    local reelNum = self.m_runSpinResultData.p_selfMakeData.reelNum
    if self.m_FsDownTimes == reelNum then
        -- if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) and self:getCurrSpinMode() == FREE_SPIN_MODE then
        --     print("不做")
        -- else
        --     BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)
        -- end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then

            local isUpdate = false
            local winlines = {}
            for i=1,#self.m_vecMiniWheel do
                local miniReel = self.m_vecMiniWheel[i]
                local lines = miniReel:getResultLines()
                if lines and #lines > 0 then
                    isUpdate = true
                    break
                end
            end
            if isUpdate then
                self:UpdateWinCoin()
            end

        else
            self:UpdateWinCoin()
        end
        
        

        
        self.m_FsDownTimes = 0
    end
end

function CodeGameScreenFrogPrinceMachine:UpdateWinCoin()
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 or self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        isNotifyUpdateTop = false
    end
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    -- self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin, GameEffect.EFFECT_BONUS)
end
--freespin下主轮调用父类停止函数
function CodeGameScreenFrogPrinceMachine:slotReelDownInFS()
    self:setGameSpinStage(STOP_RUN)
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()
    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()
end

function CodeGameScreenFrogPrinceMachine:getProgress(collect)
    local collectTotalCount = collect.collectTotalCount
    local collectCount = nil
    if collectTotalCount ~= nil then
        collectCount = collect.collectTotalCount - collect.collectLeftCount
    else
        collectTotalCount = collect.p_collectTotalCount
        collectCount = collect.p_collectTotalCount - collect.p_collectLeftCount
    end

    local percent = collectCount / collectTotalCount * 100
    return percent
end

function CodeGameScreenFrogPrinceMachine:showBonusStartView()
    if self.m_bonusView ~= nil then
        self.m_bonusView:setVisible(true)
    else
        self.m_bonusView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusView")
        -- gLobalViewManager:showUI(self.m_bonusView)
        self.m_bonusView:initMachine(self)
        self:findChild("bonusNode"):addChild(self.m_bonusView)
        self.m_bonusView:runCsbAction("start")
        
    end
    self:findChild("reel"):setVisible(false)
    self.m_bonusView:showStartView()
    self:changeNormalAndFreespinReel(2)
    self.m_currentMusicBgName = "FrogPrinceSounds/music_FrogPrince_bonusgame.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

function CodeGameScreenFrogPrinceMachine:isTriggerBonusGame()
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        return true
    end
    return false
end

function CodeGameScreenFrogPrinceMachine:BonusGameOver()
    self.m_bonusView:removeFromParent()
    self:clearWinLineEffect()
    self:changeNormalAndFreespinReel(3)
    self.m_bottomUI:setVisible(true)
    self.m_bonusView = nil
    self.m_collectView:setClickFlag(true)
    self.m_collectView:resetProgress(function(  )
        if self.m_effectData ~= nil then
            self.m_effectData.p_isPlay = true
            self:playGameEffect()
        end
        if self.m_bIsInBonusGame == true then
            self.m_bIsInBonusGame = false
            self:playGameEffect()
        end
    end)
    local WinCoins = self.m_runSpinResultData.p_winAmount
    self:checkFeatureOverTriggerBigWin(WinCoins, GameEffect.EFFECT_BONUS)
    globalData.slotRunData.lastWinCoin = WinCoins
    self:findChild("reel"):setVisible(true)
    globalData.slotRunData.lastWinCoin = 0
    self.m_bottomUI:checkClearWinLabel()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {WinCoins, true, true})
    globalData.slotRunData.lastWinCoin = WinCoins
end

function CodeGameScreenFrogPrinceMachine:BonusMapOver(_flag)
end

function CodeGameScreenFrogPrinceMachine:showEffect_Bonus(effectData)
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    self.m_effectData = effectData
    local bonusGame = function()
        self:showBonusStartView()
        self.m_bottomUI:setVisible(false)
    end
    performWithDelay(
        self,
        function()
            bonusGame()
        end,
        0.1
    )

    return true
end

function CodeGameScreenFrogPrinceMachine:changeNormalAndFreespinReel(_type)
    if _type == 1 then
        self.m_gameBg:runCsbAction("idle2", false)
    elseif _type == 0 then
        self.m_gameBg:runCsbAction("idle", false)
    elseif _type == 2 then
        self.m_gameBg:runCsbAction(
            "start",
            false,
            function()
                self.m_gameBg:runCsbAction("idle2", false)
            end
        )
    elseif _type == 3 then
        self.m_gameBg:runCsbAction(
            "over",
            false,
            function()
                self.m_gameBg:runCsbAction("idle", false)
            end
        )
    end
end

function CodeGameScreenFrogPrinceMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_SPIN_PROGRESS, data = self.m_collectDataList, jackpot = self.m_jackpotList, betLevel = self:getBetLevel()}

    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenFrogPrinceMachine:normalSpinBtnCall()
    BaseFastMachine.normalSpinBtnCall(self)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
end

function CodeGameScreenFrogPrinceMachine:slotReelDown()
    BaseFastMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

-- 增加赢钱后的 效果
function CodeGameScreenFrogPrinceMachine:addLastWinSomeEffect() -- add big win or mega win
    if #self.m_vecGetLineInfo == 0 and self.getCurrSpinMode() ~= FREE_SPIN_MODE then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    local curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

function CodeGameScreenFrogPrinceMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        -- if self.m_bProduceSlots_InFreeSpin == false then
            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
        -- end
    end

    -- 如果处于 freespin 中 那么大赢都不触发
    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect == true then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
    end
end

function CodeGameScreenFrogPrinceMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    
    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
   
    if globalData.slotRunData.isPortrait == true then
        mainScale = wScale
        util_csbScale(self.m_machineNode, wScale)
    else
        mainScale = hScale
        local ratio = display.height/display.width
        if  ratio >= 768/1024 then
            mainScale = 0.85
        elseif ratio < 768/1024 and ratio >= 640/960 then
            mainScale = 0.95 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end
    -- if  display.height/display.width >= 768/1024 then
    --     local miniReelNode = self:findChild("miniReels")
    --     util_csbScale(self:findChild("miniReels"), 0.5)
    -- end
end

function CodeGameScreenFrogPrinceMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue then
        -- 关卡特殊处理 不显示scatter赢钱线动画
        if lineValue.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            print("scatter")
        else
            BaseMachineGameEffect.showLineFrameByIndex(self, winLines, frameIndex)
        end
    end
end

--移除scatter 连线
function CodeGameScreenFrogPrinceMachine:showLineFrame()
    if self.m_reelResultLines and type(self.m_reelResultLines) == "table" then
        local scatterLineValue = nil
        for i = #self.m_reelResultLines, 1, -1 do
            local lineData = self.m_reelResultLines[i]
            if lineData then
                if lineData.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    table.remove(self.m_reelResultLines, i)
                end
            end
        end
    end

    BaseMachineGameEffect.showLineFrame(self)
end

function CodeGameScreenFrogPrinceMachine:checkNotifyUpdateWinCoin()
    if self.m_iOnceSpinLastWin == 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenFrogPrinceMachine:quicklyStopReel(colIndex)
    print("quicklyStopReel  调用了快停")
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        BaseFastMachine.quicklyStopReel(self, colIndex) 
    end
end

return CodeGameScreenFrogPrinceMachine
