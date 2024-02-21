---
-- island li
-- 2019年1月26日
-- CodeGameScreenRedHotDevilsMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "RedHotDevilsPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenRedHotDevilsMachine = class("CodeGameScreenRedHotDevilsMachine", BaseNewReelMachine)

CodeGameScreenRedHotDevilsMachine.MAIN_JACK_ADD_POSY = 0
CodeGameScreenRedHotDevilsMachine.m_chooseRootScale = 1
CodeGameScreenRedHotDevilsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenRedHotDevilsMachine.SYMBOL_SCORE_10 = 9

CodeGameScreenRedHotDevilsMachine.EFFECT_JACKPOT_PLAY = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenRedHotDevilsMachine.EFFECT_COLLECT_PLAY = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenRedHotDevilsMachine.EFFECT_CHANGE_WILD = GameEffect.EFFECT_SELF_EFFECT - 3
-- CodeGameScreenRedHotDevilsMachine.EFFECT_BIG_WIN_LIGHT = GameEffect.EFFECT_SELF_EFFECT - 4 --   大赢光效



-- 构造函数
function CodeGameScreenRedHotDevilsMachine:ctor()
    CodeGameScreenRedHotDevilsMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig

    self.triggerWildPlayDelayTime = 0
    self.triggerScatterDelayTime = 0
    self.m_curCollectLevel = 1
    self.m_triggerBigWinEffect = false
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
 
    --init
    self:initGame()
end

function CodeGameScreenRedHotDevilsMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenRedHotDevilsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RedHotDevils"  
end


function CodeGameScreenRedHotDevilsMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_baseBgSpine = util_spineCreate("GameScreenRedHotDevilsBg",true,true)
    self.m_gameBg:findChild("Node_Bg"):addChild(self.m_baseBgSpine)
    self:changeBgSpine(1)

    self.m_baseFreeSpinBar = util_createView("CodeRedHotDevilsSrc.RedHotDevilsFreespinBarView")
    self:findChild("freegamebar"):addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)

    self.m_jackpotView = util_createView("CodeRedHotDevilsSrc.RedHotDevilsJackpotView", self)
    self:findChild("Node_duofuduocai"):addChild(self.m_jackpotView)
    self.m_jackpotView:setVisible(false)

    self.m_chooseView = util_createView("CodeRedHotDevilsSrc.RedHotDevilsChoosePlayView")
    self:addChild(self.m_chooseView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_chooseView:initMachine(self)
    self.m_chooseView:setVisible(false)

    self.m_jackPotBar = util_createView("CodeRedHotDevilsSrc.RedHotDevilsJackPotBarView")
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
   
    self.m_fuCaiSpine = util_spineCreate("RedHotDevils_duofuduocai_pen",true,true)
    self:findChild("Node_pen"):addChild(self.m_fuCaiSpine)

    local nodePosX, nodePosY = self:findChild("Node_Pen_GuoChang"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))

    self.m_guoChangSpine_2 = util_spineCreate("RedHotDevils_duofuduocai_pen",true,true)
    self.m_guoChangSpine_2:setPosition(worldPos)
    self:addChild(self.m_guoChangSpine_2, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChangSpine_2:setVisible(false)
    
    self.m_guoChangSpine = util_spineCreate("RedHotDevils_duofuduocai_pen",true,true)
    self.m_guoChangSpine:setPosition(worldPos)
    -- self:findChild("Node_Pen_GuoChang"):addChild(self.m_guoChangSpine)
    self:addChild(self.m_guoChangSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guoChangSpine:setVisible(false)

    self.m_yuGao = util_createAnimation("RedHotDevils_yugao.csb")
    self:findChild("Node_cutScene"):addChild(self.m_yuGao)
    self.m_yuGao:setVisible(false)

    self.m_cutSceneSpine = util_spineCreate("Socre_RedHotDevils_juese",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_cutSceneSpine)
    self.m_cutSceneSpine:setVisible(false)

    self.m_darkAni = util_createAnimation("RedHotDevils_qipan_dark.csb")
    self:findChild("Node_dark"):addChild(self.m_darkAni)
    self.m_darkAni:setVisible(false)

    self.m_lightAni = util_createAnimation("RedHotDevils_wild_juguangdeng.csb")
    self:findChild("Node_dark"):addChild(self.m_lightAni, 10)
    self.m_lightAni:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_dark"), true)

    self.m_topSymbolLiZiNode = self:findChild("Node_topSymbol_lizi")
    self.m_topSymbolNode = self:findChild("Node_topSymbol")
 
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitCollectNode = cc.Node:create()
    self:addChild(self.m_scWaitCollectNode)
    
    self.m_panel_clipeNode = self:findChild("panel_clipeNode")

    self.m_jackpotView:scaleMainLayer(self.MAIN_JACK_ADD_POSY)
    self.m_chooseView:scaleMainLayer(self.m_chooseRootScale)
    self:setBaseIdle()
end


function CodeGameScreenRedHotDevilsMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Enter_Game, 3, 0, 1)
    end,0.2,self:getModuleName())
end

function CodeGameScreenRedHotDevilsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRedHotDevilsMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData then
        local featureDatas = self.m_runSpinResultData.p_features or {}

        if selfData.jackpotResult and featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            -- 发送事件显示赢钱总数量
            local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
            -- self:addSelfEffect(true)
        end
        if selfData.collectLevel then
            self.m_curCollectLevel = selfData.collectLevel
        end
    end
    self:initGameUI()
end

function CodeGameScreenRedHotDevilsMachine:addObservers()
    CodeGameScreenRedHotDevilsMachine.super.addObservers(self)
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
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 4
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

        local soundName = "RedHotDevilsSounds/music_RedHotDevils_last_win_"..bgmType.."_".. soundIndex .. ".mp3"
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenRedHotDevilsMachine:scaleMainLayer()
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
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        if display.width / display.height >= 1660/768 then
            mainScale = mainScale * 1.08
            tempPosY = tempPosY - 3
            self.MAIN_JACK_ADD_POSY = 5
        elseif display.width / display.height >= 1530/768 then
            mainScale = mainScale * 1.08
            tempPosY = tempPosY - 3
            self.MAIN_JACK_ADD_POSY = 5
        elseif display.width / display.height >= 1370/768 then
            tempPosY = tempPosY - 3
            mainScale = mainScale * 1.08
            self.MAIN_JACK_ADD_POSY = 5
        elseif display.width / display.height >= 1228/768 then
            mainScale = mainScale * 1.06
            tempPosY = tempPosY - 5
            self.MAIN_JACK_ADD_POSY = 5
            self.m_chooseRootScale = 0.9
        elseif display.width / display.height >= 960/640 then
            mainScale = mainScale * 0.96
            self.m_chooseRootScale = 0.85
        elseif display.width / display.height >= 1024/768 then
            mainScale = mainScale * 0.85
            self.m_chooseRootScale = 0.77
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY+tempPosY)
    end
end

function CodeGameScreenRedHotDevilsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRedHotDevilsMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenRedHotDevilsMachine:initGameUI()
    self:refreshTopMiddleCoins()
    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self:changeBgSpine(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
        self.m_baseFreeSpinBar:runCsbAction("idle", true)
    end
end

function CodeGameScreenRedHotDevilsMachine:refreshTopMiddleCoins()
    if self.m_curCollectLevel then
        local actionFrameName = "idleframe"..self.m_curCollectLevel
        util_spinePlay(self.m_fuCaiSpine, actionFrameName, true)
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenRedHotDevilsMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_RedHotDevils_10"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenRedHotDevilsMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenRedHotDevilsMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenRedHotDevilsMachine:MachineRule_initGame(  )

    
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenRedHotDevilsMachine:initGameStatusData(gameData)
    CodeGameScreenRedHotDevilsMachine.super.initGameStatusData(self,gameData)
    local featureData = gameData.feature
    if featureData then
        local freespinData = featureData.freespin
        local feature = featureData.features
        if feature then
            self.m_runSpinResultData.p_features = feature
            if freespinData then
                self.m_runSpinResultData.p_freeSpinsLeftCount = freespinData.freeSpinsLeftCount
                self.m_runSpinResultData.p_freeSpinsTotalCount = freespinData.freeSpinsTotalCount
            end
        end
    end
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenRedHotDevilsMachine:MachineRule_ResetReelRunData()
    if self.isPlayYuGao then
        self.isPlayYuGao = false
        for i = 1, #self.m_reelRunInfo do
            local runInfo = self.m_reelRunInfo[i]
            runInfo:setReelRunLen(runInfo.initInfo.reelRunLen)
            runInfo:setNextReelLongRun(runInfo.initInfo.bReelRun)      
            runInfo:setReelLongRun(true)
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenRedHotDevilsMachine:slotOneReelDown(reelCol)    
    CodeGameScreenRedHotDevilsMachine.super.slotOneReelDown(self,reelCol) 
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
        self:playScatterSpine("idle", reelCol)
    else
        if reelCol == self.m_iReelColumnNum and self.isHaveLongRun == true then
            --落地
            self.triggerScatterDelayTime = 15/30
            self:playScatterSpine("idleframe", reelCol, true)
        end
    end
end

--顶部补块
function CodeGameScreenRedHotDevilsMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
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

function CodeGameScreenRedHotDevilsMachine:playScatterSpine(_spineName, _reelCol, isOver)
    performWithDelay(self.m_scWaitNode, function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        if _spineName == "idle" and targSp.m_currAnimName ~= "idle" then
                            targSp:runAnim(_spineName, true)
                        elseif _spineName == "idleframe" then
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
function CodeGameScreenRedHotDevilsMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenRedHotDevilsMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenRedHotDevilsMachine:showBonusGameView(_effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.triggerScatterDelayTime = 0
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        -- 停掉背景音乐
        self:clearCurMusicBg()

        local waitTime = 0
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
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
            self:showChooseView(_effectData)
        end,waitTime)
    end, self.triggerScatterDelayTime)
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenRedHotDevilsMachine:showChooseView(effectData)
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    self.m_chooseView:setVisible(true)
    self.m_chooseView:playSpineIdle()
    self:runCsbAction("actionframe1", false)
    util_spinePlay(self.m_baseBgSpine,"actionframe1",false)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_FreeGame_ChooseStart)
    self.m_chooseView:runCsbAction("start",false, function()
        self.m_chooseView:refreshData(endCallFunc)
        self.m_chooseView:runCsbAction("idle", true)
    end)
end

-- 显示free spin
function CodeGameScreenRedHotDevilsMachine:showEffect_FreeSpin(effectData)
    performWithDelay(self.m_scWaitNode, function()
        self.triggerScatterDelayTime = 0
        self.m_beInSpecialGameTrigger = true
        local waitTime = 0
        if not self.m_bInSuperFreeSpin and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
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
            self:playScatterTipMusicEffect(true)
        end
        
        performWithDelay(self,function(  )
            self:showFreeSpinView(effectData)
        end,waitTime)
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    end, self.triggerScatterDelayTime)
    return true
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenRedHotDevilsMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("RedHotDevilsSounds/music_RedHotDevils_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        local lightAni = util_createAnimation("RedHotDevils_tanban_guang.csb")
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_More_startOver)
            -- 停掉背景音乐
            -- self:clearCurMusicBg()
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            -- self.m_bottomUI:updateWinCount("")
            -- self:setLastWinCoin(0)
            self:runCsbAction("idle2", true)
            self.m_baseFreeSpinBar:changeFreeSpinByCount()
            self:showCutSceneAni(function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            -- local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
            --     self:showCutSceneAni(function()
            --         self:triggerFreeSpinCallFun()
            --         effectData.p_isPlay = true
            --         self:playGameEffect()
            --     end)
            -- end)
            -- view:findChild("Node_guang"):addChild(lightAni)
            -- lightAni:runCsbAction("idle", true)
            -- util_setCascadeOpacityEnabledRescursion(view, true)
            -- if self.m_runSpinResultData.p_freeSpinsTotalCount then
            --     view:findChild("wenzi2"):setVisible(false)
            --     view:findChild("wenzi3"):setVisible(false)
            --     view:findChild("wenzi4"):setVisible(false)
            --     if self.m_runSpinResultData.p_freeSpinsTotalCount == 5 then
            --         view:findChild("wenzi2"):setVisible(true)
            --     elseif self.m_runSpinResultData.p_freeSpinsTotalCount == 10 then
            --         view:findChild("wenzi3"):setVisible(true)
            --     elseif self.m_runSpinResultData.p_freeSpinsTotalCount == 20 then
            --         view:findChild("wenzi4"):setVisible(true)
            --     end
            -- end

        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end


function CodeGameScreenRedHotDevilsMachine:showCutSceneAni(_callFunc)
    local callFunc = _callFunc
    self.m_cutSceneSpine:setVisible(true)
    util_spinePlay(self.m_baseBgSpine,"actionframe2",false)
    util_spinePlay(self.m_cutSceneSpine,"guochang1",false)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Enter_FreeCutScene)
    util_spineFrameEventAndRemove(self.m_cutSceneSpine , "guochang1","quan",function ()
        self:setBaseIdle()
        self.m_baseFreeSpinBar:setVisible(true)
        self:changeBgSpine(2)
        self.m_baseFreeSpinBar:runCsbAction("start", false, function()
            self.m_baseFreeSpinBar:runCsbAction("idle", true)
        end)
    end)
    performWithDelay(self.m_scWaitNode, function()
        self.m_cutSceneSpine:setVisible(false)
        if callFunc then
            callFunc()
            callFunc = nil
        end
    end, 101/30)
end

function CodeGameScreenRedHotDevilsMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        -- self:resetMusicBg(true)
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
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

function CodeGameScreenRedHotDevilsMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("RedHotDevilsSounds/music_RedHotDevils_over_fs.mp3")

    local function callFunc()
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_OverClick)
        performWithDelay(self.m_scWaitNode, function()
            gLobalSoundManager:playSound(self.m_publicConfig.Music_Fg_OverDialog)
        end, 5/60)
    end
    self:runCsbAction("actionframe1", false)
    util_spinePlay(self.m_baseBgSpine,"actionframe3",false)
    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Fg_BgOver, 4, 0, 1)
    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    if globalData.slotRunData.lastWinCoin > 0 then
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:showCutSceneOverAni(function()
                    self:triggerFreeSpinOverCallFun()
                end)
            end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1.0,sy=1.0},719)
        view:setBtnClickFunc(callFunc)
    else
        local view = self:showFreeSpinOverNoWin(function()
            self:showCutSceneOverAni(function()
                self:triggerFreeSpinOverCallFun()
            end)
        end)
        view:setBtnClickFunc(callFunc)
    end
end

function CodeGameScreenRedHotDevilsMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("FreeSpinOver_NoWins",nil,_func)
    return view
end

function CodeGameScreenRedHotDevilsMachine:showCutSceneOverAni(_callFunc)
    local callFunc = _callFunc
    self.m_cutSceneSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_FgOver_CutScane)
    self.m_baseFreeSpinBar:runCsbAction("over", false, function()
        self.m_baseFreeSpinBar:setVisible(false)
    end)
    util_spinePlay(self.m_cutSceneSpine,"guochang2",false)
    util_spineFrameEventAndRemove(self.m_cutSceneSpine , "guochang2","quan",function ()
        self:changeBgSpine(1)
        self:setBaseIdle()
    end)
    performWithDelay(self.m_scWaitNode, function()
        self.m_cutSceneSpine:setVisible(false)
        if callFunc then
            callFunc()
            callFunc = nil
        end
    end, 80/30)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenRedHotDevilsMachine:MachineRule_SpinBtnCall()
    
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
function CodeGameScreenRedHotDevilsMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
        self.m_triggerBigWinEffect = true
    end
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenRedHotDevilsMachine:addSelfEffect(isInitGame)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.isDuoFuDuoCai = false

    if selfData.changeLocs and #selfData.changeLocs > 0 and not isInitGame then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_CHANGE_WILD
        effectData.p_selfEffectType = self.EFFECT_CHANGE_WILD
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end

    if selfData.collectLocs and #selfData.collectLocs > 0 then
        local effectData = GameEffectData.new()
        effectData.p_effectType     = GameEffect.EFFECT_SELF_EFFECT
        effectData.p_effectOrder    = self.EFFECT_COLLECT_PLAY
        effectData.p_selfEffectType = self.EFFECT_COLLECT_PLAY
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end

    if selfData.jackpotResult then
        self.isDuoFuDuoCai = true
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
function CodeGameScreenRedHotDevilsMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_CHANGE_WILD then
        performWithDelay(self.m_scWaitNode, function()
            self:playChangeWild(effectData)
        end, self.triggerWildPlayDelayTime)
    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_PLAY then
        performWithDelay(self.m_scWaitNode, function()
            self.triggerScatterDelayTime = 0
            self:playCollectScatter(effectData)
        end, self.triggerScatterDelayTime)
    elseif effectData.p_selfEffectType == self.EFFECT_JACKPOT_PLAY then
        self:playJackpotPlay(effectData)
    end
    
    return true
end

--H1-H3变成发狂模式
function CodeGameScreenRedHotDevilsMachine:playChangeWild(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local changeLocs = selfData.changeLocs
    local collectLocs = selfData.collectLocs
    local particleDelayTime = 15/60
    local tblBoomNode = {}
    
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    if #changeLocs > 0 then
        self.m_topSymbolNode:setVisible(true)
        local tblBaseChangeSymbol = {}
        local tblChangeSymbol = {}
        local baseWildNode = nil
        local wildNode = nil
        local wildPos = nil
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(self.m_iReelColumnNum, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                baseWildNode = slotNode
                wildPos = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
                wildNode = self:createRedHotSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                local nodePos = self:getTopSymbolPos(wildPos)
                wildNode:setPosition(nodePos)
                self.m_topSymbolNode:addChild(wildNode, 100)
                baseWildNode:setVisible(false)
                break
            end
        end

        for i = 1, #changeLocs do
            local pos = changeLocs[i]
            local fixPos = self:getRowAndColByPos(pos)
            local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
            if symbolNode then
                tblBaseChangeSymbol[#tblBaseChangeSymbol + 1] = symbolNode
                symbolNode:setVisible(false)

                local topSymbolNode = self:createRedHotSymbol(symbolNode.p_symbolType)
                local topSymbolSpineNode = topSymbolNode:getNodeSpine()
                if topSymbolSpineNode.setSkin then
                    topSymbolSpineNode:setSkin("cai")
                end
                local nodePos = self:getTopSymbolPos(pos)
                topSymbolNode:setPosition(nodePos)
                self.m_topSymbolNode:addChild(topSymbolNode)
                tblChangeSymbol[#tblChangeSymbol + 1] = topSymbolNode
                topSymbolNode:runAnim("idleframe", true)
            end
        end

        local isPlayJinAction = true
        if #changeLocs == 2 and not self.m_triggerBigWinEffect then
            isPlayJinAction = false
        end

        self.m_panel_clipeNode:setClippingEnabled(true)
        
        self.m_darkAni:setVisible(true)
        self.m_darkAni:runCsbAction("start", false, function()
            self.m_darkAni:runCsbAction("idle", true)
        end)

        if isPlayJinAction then
            local fadeInAct = cc.FadeIn:create(0.5)
            self.m_lightAni:setOpacity(0)
            self.m_lightAni:setVisible(true)
            self.m_lightAni:runCsbAction("actionframe", true)
            if self.m_lightAni.m_csbAct then
                self.m_lightAni.m_csbAct:setTimeSpeed(1.0)
            end
            self.m_lightAni:runAction(fadeInAct)
        end

        local wildSpineNode = wildNode:getNodeSpine()
        -- local ccbNode = wildNode:getCCBNode()
        -- local wildSpineNode = ccbNode.m_spineNode
        local randomNum = math.random(1, 2)
        if randomNum < 2 then
            gLobalSoundManager:playSound(self.m_publicConfig.Music_WooHoo_Sound)
        end
        gLobalSoundManager:playSound(self.m_publicConfig.Music_Trigger_Wild)
        wildNode:runAnim("zhan_start", false, function()
            wildNode:runAnim("zhan_actionframe", false, function()
                wildNode:runAnim("zhan_over", false, function()
                    wildNode:runAnim("actionframe1", false, function()
                        wildNode:runAnim("idleframe", true)
                    end)
                end)
            end)
            util_spineFrameEventAndRemove(wildSpineNode , "zhan_actionframe","shijian",function ()
                --粒子飞行
                local startClipTarPos = util_getOneGameReelsTarSpPos(self, wildPos)
                local startWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(startClipTarPos))
                local startNodePos = self.m_topSymbolLiZiNode:convertToNodeSpace(startWorldPos)

                for i = 1, #changeLocs do
                    local pos = changeLocs[i]
                    local clipTarPos = util_getOneGameReelsTarSpPos(self, pos)
                    local endWorldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
                    local endNodePos = self.m_topSymbolLiZiNode:convertToNodeSpace(endWorldPos)
                    local flyNode = util_createAnimation("RedHotDevils_wild_lizi.csb")
                    flyNode:setPosition(startNodePos.x, startNodePos.y)
                    self.m_topSymbolLiZiNode:addChild(flyNode)

                    local particle = flyNode:findChild("Particle_1")
                    particle:setPositionType(0)
                    particle:setDuration(-1)
                    particle:resetSystem()

                    local boomNode = util_createAnimation("RedHotDevils_wild_bao.csb")
                    boomNode:setPosition(endNodePos.x, endNodePos.y)
                    self.m_topSymbolLiZiNode:addChild(boomNode)
                    boomNode:setVisible(false)

                    if not isPlayJinAction then
                        self.m_darkAni:runCsbAction("over", false, function()
                            self.m_darkAni:setVisible(false)
                        end)
                    end

                    util_playMoveToAction(flyNode, particleDelayTime, endNodePos,function()
                        particle:stopSystem()
                        boomNode:setVisible(true)
                        boomNode:runCsbAction("actionframe", false, function()
                            flyNode:removeFromParent()
                            if i == #changeLocs then
                                self.m_topSymbolLiZiNode:removeAllChildren()
                            end
                        end)
                        performWithDelay(self.m_scWaitNode, function()
                            
                            local baseSymbolNode = tblBaseChangeSymbol[i]
                            self:setSpecialSymbolSkin(baseSymbolNode, "jin", "actionframe2")

                            local topSymbolNode = tblChangeSymbol[i]
                            local topSymbolSpineNode = topSymbolNode:getNodeSpine()
                            if topSymbolSpineNode.setSkin then
                                topSymbolSpineNode:setSkin("jin")
                            end
                            
                            if isPlayJinAction then
                                if i == #changeLocs then
                                    if self.m_lightAni.m_csbAct then
                                        self.m_lightAni.m_csbAct:setTimeSpeed(3.0)
                                    end
                                end
                                if self.m_triggerBigWinEffect then
                                    -- self:showEffect_BigWinLight()
                                    self.m_triggerBigWinEffect = false
                                end
                                topSymbolNode:runAnim("actionframe2", false)
                                local topSpineNode = topSymbolNode:getNodeSpine()
                                util_spineFrameEventAndRemove(topSpineNode , "actionframe2","yaan",function ()
                                    if i == #changeLocs then
                                        self.m_darkAni:runCsbAction("over", false, function()
                                            self.m_darkAni:setVisible(false)
                                        end)

                                        local actionTbl = {}
                                        actionTbl[#actionTbl+1] = cc.FadeOut:create(20/60)
                                        actionTbl[#actionTbl+1] = cc.CallFunc:create(function()
                                            self.m_lightAni:setVisible(false)
                                            for j = 1, #tblChangeSymbol do
                                                tblBaseChangeSymbol[j]:setVisible(true)
                                                tblBaseChangeSymbol[j]:runAnim("idleframe", true)
                                                tblChangeSymbol[j]:setVisible(false)
                                            end
                                            wildNode:stopAllActions()
                                            baseWildNode:setVisible(true)
                                            baseWildNode:runAnim("idleframe", true)
                                            self.m_topSymbolNode:setVisible(false)
                                            self.m_panel_clipeNode:setClippingEnabled(false)
                                            endCallFunc()
                                        end)
                                        local seq = cc.Sequence:create(actionTbl)
                                        self.m_lightAni:runAction(seq)
                                    end
                                end)
                            else
                                if i == #changeLocs then
                                    self.m_darkAni:setVisible(false)
                                    for j = 1, #tblChangeSymbol do
                                        tblBaseChangeSymbol[j]:setVisible(true)
                                        tblBaseChangeSymbol[j]:runAnim("idleframe", true)
                                        tblChangeSymbol[j]:setVisible(false)
                                    end
                                    wildNode:stopAllActions()
                                    baseWildNode:setVisible(true)
                                    baseWildNode:runAnim("idleframe", true)
                                    self.m_topSymbolNode:setVisible(false)
                                    self.m_panel_clipeNode:setClippingEnabled(false)
                                    endCallFunc()
                                end
                            end
                        end, 5/60)
                    end)
                end
            end)
        end)
        -- 站起来后播放H1-H3
        util_spineFrameEventAndRemove(wildSpineNode , "zhan_start","shijian",function ()
            for i = 1, #tblChangeSymbol do
                local symbolNode = tblChangeSymbol[i]
                symbolNode:runAnim("actionframe19", false)
            end
        end)
    end
end

function CodeGameScreenRedHotDevilsMachine:getTopSymbolPos(_pos)
    local clipTarPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
    local nodePos = self.m_topSymbolNode:convertToNodeSpace(worldPos)
    return nodePos
end

function CodeGameScreenRedHotDevilsMachine:createRedHotSymbol(_symbolType)
    local symbol = util_createView("CodeRedHotDevilsSrc.RedHotDevilsSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

function CodeGameScreenRedHotDevilsMachine:playCollectScatter(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collectLocs = selfData.collectLocs
    local collectLevel = selfData.collectLevel
    local delayTime = 15/30

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
            effectData = nil
        end
    end

    if #collectLocs > 0 then
        for i = 1, #collectLocs do
            local pos = collectLocs[i]
            local clipTarPos = util_getOneGameReelsTarSpPos(self, pos)
            local startPos = self.m_clipParent:convertToWorldSpace(cc.p(clipTarPos))
            local endPos = util_convertToNodeSpace(self:findChild("Node_pen"), self)

            local flyNode = util_spineCreate("Socre_RedHotDevils_Scatter",true,true)
            flyNode:setPosition(startPos.x, startPos.y)
            self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1)

            if i == #collectLocs then
                gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_Collect)
            end
            util_spinePlay(flyNode, "shouji", false)
            --收集不打断spin
            local lastClooectLevel = self.m_curCollectLevel
            local duoFuDuoCai = self.isDuoFuDuoCai
            local isTriggerFG = self:isTriggerFreeGame()
            if i == #collectLocs and not duoFuDuoCai and not isTriggerFG then
                self.m_curCollectLevel = collectLevel
                endCallFunc()
            end
            self.m_scWaitCollectNode:stopAllActions()
            util_playMoveToAction(flyNode, delayTime, endPos,function()
                flyNode:removeFromParent()
                if i == #collectLocs then
                    gLobalSoundManager:playSound(self.m_publicConfig.Music_Scatter_FeedBack)
                    local shoujiDelayTime = 0
                    if collectLevel == lastClooectLevel and not duoFuDuoCai then
                        shoujiDelayTime = 20/30
                        local collectName = "shouji"..lastClooectLevel
                        util_spinePlay(self.m_fuCaiSpine, collectName, false)
                    end
                    performWithDelay(self.m_scWaitCollectNode, function()
                        if duoFuDuoCai then
                            local changeName = nil
                            local delayTime = 0
                            --1变3
                            if lastClooectLevel == 1 then
                                delayTime = 25/30
                                changeName = "switch3"
                            --2变3
                            elseif lastClooectLevel == 2 then
                                delayTime = 25/30
                                changeName = "switch2"
                            --3档不变
                            elseif lastClooectLevel == 3 then
                                delayTime = 0
                            end
                            if changeName then
                                util_spinePlay(self.m_fuCaiSpine, changeName, false)
                            end
                            performWithDelay(self.m_scWaitCollectNode, function()
                                self.m_curCollectLevel = 3
                                self:refreshTopMiddleCoins()
                                endCallFunc()
                            end, delayTime)
                        else
                            if lastClooectLevel == collectLevel then
                                self:refreshTopMiddleCoins()
                                if isTriggerFG then
                                    endCallFunc()
                                end
                            elseif collectLevel > lastClooectLevel then
                                local changeName = nil
                                local delayTime = 25/30
                                --1变2; 2变3
                                if lastClooectLevel == 1 then
                                    if collectLevel == 2 then
                                        changeName = "switch1"
                                    else
                                        changeName = "switch3"
                                    end
                                --2变3
                                elseif lastClooectLevel == 2 and collectLevel == 3 then
                                    changeName = "switch2"
                                end
                                if changeName then
                                    util_spinePlay(self.m_fuCaiSpine, changeName, false)
                                end
                                performWithDelay(self.m_scWaitCollectNode, function()
                                    -- self.m_curCollectLevel = collectLevel
                                    self:refreshTopMiddleCoins()
                                    if isTriggerFG then
                                        endCallFunc()
                                    end
                                end, delayTime)
                            end
                        end
                    end, shoujiDelayTime)
                end
            end)
        end
    end
end

function CodeGameScreenRedHotDevilsMachine:isTriggerFreeGame()
    local featureDatas = self.m_runSpinResultData.p_features or {}

    if featureDatas and (featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureDatas[2] == SLOTO_FEATURE.FEATURE_FREESPIN) then
        return true
    end
    return false
end

function CodeGameScreenRedHotDevilsMachine:shakeRootNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i = 1,10 do
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

function CodeGameScreenRedHotDevilsMachine:playJackpotPlay(effectData)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "pickFeature")
    end
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins

    local collectLevel = selfData.collectLevel
    self.m_curCollectLevel = collectLevel

    local endCallFunc = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
    
    self.m_guoChangSpine:setVisible(true)
    self.m_guoChangSpine_2:setVisible(true)
    self.m_fuCaiSpine:setVisible(false)
    util_spinePlay(self.m_guoChangSpine_2, "guochang", false)
    globalMachineController:playBgmAndResume(self.m_publicConfig.Music_Jackpot_CutScane, 3, 0, 1)
    util_spinePlay(self.m_guoChangSpine, "guochang2", false)
    util_spineFrameEventAndRemove(self.m_guoChangSpine , "guochang2","switch",function ()
        self.m_guoChangSpine_2:setVisible(false)
        self:resetMusicBg(nil, self.m_publicConfig.Music_Jackpot_Bg)
        self.m_jackpotView:setVisible(true)
        self.m_jackpotView:refreshData(selfData, jackpotCoins, endCallFunc)
    end)
    performWithDelay(self.m_scWaitNode, function()
        self:runCsbAction("idle2", true)
        self.m_guoChangSpine:setVisible(false)
    end, 111/30)
end

function CodeGameScreenRedHotDevilsMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenRedHotDevilsMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenRedHotDevilsMachine:beginReel()
    CodeGameScreenRedHotDevilsMachine.super.beginReel(self)
    self.triggerScatterDelayTime = 0
    self.m_topSymbolNode:removeAllChildren()
    self.m_panel_clipeNode:setClippingEnabled(false)
end

function CodeGameScreenRedHotDevilsMachine:updateNetWorkData()
    local callFunc = function()
        CodeGameScreenRedHotDevilsMachine.super.updateNetWorkData(self)
    end

    self.isPlayYuGao = false
    local featureDatas = self.m_runSpinResultData.p_features or {}

    -- if featureDatas and (featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureDatas[2] == SLOTO_FEATURE.FEATURE_FREESPIN) then
    if featureDatas and featureDatas[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        local randomNum = math.random(1, 10)
        if randomNum <= 4 then
            self.isPlayYuGao = true
            self.triggerScatterDelayTime = 15/30
        end
        -- isPlayYuGao = true
    end
    
    if self.isPlayYuGao then
        local bgType = 1
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            bgType = 2
            util_spinePlay(self.m_baseBgSpine,"show2",false)
        else
            bgType = 1
            util_spinePlay(self.m_baseBgSpine,"show1",false)
        end
        self.m_yuGao:setVisible(true)
        gLobalSoundManager:playSound(self.m_publicConfig.Music_YuGao_Sound)
        self.m_yuGao:runCsbAction("yugao", false, function()
            self:changeBgSpine(bgType)
            callFunc()
        end)
    else
        callFunc() 
    end
end

function CodeGameScreenRedHotDevilsMachine:updateReelGridNode(_symbolNode)

    self:setSpecialSymbolSkin(_symbolNode, "cai", "actionframe")
end

function CodeGameScreenRedHotDevilsMachine:setSpecialSymbolSkin(_symbolNode, _skinName, _lineName)
    if _symbolNode.m_isLastSymbol == true and self:getCurSymbolIsSpecial(_symbolNode.p_symbolType) then
        _symbolNode:setLineAnimName(_lineName)
        local ccbNode = _symbolNode:getCCBNode()
        if not ccbNode then
            _symbolNode:checkLoadCCbNode()
        end
        ccbNode = _symbolNode:getCCBNode()
        if ccbNode then
            ccbNode.m_spineNode:setSkin(_skinName)
        end
    end
end

function CodeGameScreenRedHotDevilsMachine:setBaseIdle()
    self:runCsbAction("idle", true)
end

function CodeGameScreenRedHotDevilsMachine:getCurSymbolIsSpecial(_symbolType)
    if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
    or _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8
    or _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        return true
    end
    return false
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenRedHotDevilsMachine:checkHasGameEffect(effectType)
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

--判断当前是否为free最后一次spin
function CodeGameScreenRedHotDevilsMachine:getCurIsFreeGameLastSpin()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        return true
    end
    return false
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenRedHotDevilsMachine:checkFeatureOverTriggerBigWin(winAmonut, feature, isCurentLase)
    if winAmonut == nil then
        return
    end

    if isCurentLase and self:featureOverTriggerBigWinSpecCheck(feature) then
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

function CodeGameScreenRedHotDevilsMachine:jackpotGameOver(endCallFunc)
    if not self:checkHasBigWin() then
        --检测大赢
        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS, true)
    end
    self.m_fuCaiSpine:setVisible(true)
    self.m_guoChangSpine:setVisible(false)
    self.m_guoChangSpine_2:setVisible(false)
    self:refreshTopMiddleCoins()
    self.m_cutSceneSpine:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Jackpot_Over)
    util_spinePlay(self.m_cutSceneSpine,"guochang2",false)
    util_spineFrameEventAndRemove(self.m_cutSceneSpine , "guochang2","quan",function ()
        self:resetMusicBg()
        self:setBaseIdle()
        self:changeBgSpine(1)
    end)
    performWithDelay(self.m_scWaitNode, function()
        self.m_cutSceneSpine:setVisible(false)
        if endCallFunc then
            endCallFunc()
            endCallFunc = nil
        end
    end, 80/30)
end

function CodeGameScreenRedHotDevilsMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenRedHotDevilsMachine.super.slotReelDown(self)
end

function CodeGameScreenRedHotDevilsMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenRedHotDevilsMachine:changeBgSpine(_bgType)
    -- 1.base；2.freespin
    if _bgType == 1 then
        util_spinePlay(self.m_baseBgSpine,"base",true)
    elseif _bgType == 2 then
        util_spinePlay(self.m_baseBgSpine,"free",true)
    end
    self:setReelBgState(_bgType)
end

function CodeGameScreenRedHotDevilsMachine:setReelBgState(_bgType)
    if _bgType == 1 then
        self:findChild("reel_bg_base"):setVisible(true)
        self:findChild("reel_bg_free"):setVisible(false)
    else
        self:findChild("reel_bg_free"):setVisible(true)
        self:findChild("reel_bg_base"):setVisible(false)
    end
end

function CodeGameScreenRedHotDevilsMachine:addPlayEffect()
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

function CodeGameScreenRedHotDevilsMachine:playhBottomLight(_endCoins, _endCallFunc)
    
    self.m_bottomUI:playCoinWinEffectUI(_endCallFunc)

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    -- self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenRedHotDevilsMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenRedHotDevilsMachine:getCurBottomWinCoins()
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
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenRedHotDevilsMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                self.triggerWildPlayDelayTime = 0
                if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    if _slotNode.p_cloumnIndex == self.m_iReelColumnNum then
                        self.triggerWildPlayDelayTime = 15/30
                    end
                end
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

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenRedHotDevilsMachine:symbolBulingEndCallBack(node)
    if node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        node:runAnim("idleframe", true)
    elseif node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        node:runAnim("idle", true)
    end
end

function CodeGameScreenRedHotDevilsMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenRedHotDevilsMachine:playScatterTipMusicEffect(_isFreeMore)
    if _isFreeMore then
        gLobalSoundManager:playSound(self.m_publicConfig.Music_FreeGame_TriggerFree)
    else
        if self.m_ScatterTipMusicPath ~= nil then
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 4, 0, 0)
        end
    end
end

--@isMustPlayMusic 是否必须播放音乐
--@musicName 需要修改的音乐路径
function CodeGameScreenRedHotDevilsMachine:resetMusicBg(isMustPlayMusic, musicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    self:resetCurBgMusicName(musicName)

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
end

---
-- 轮盘停下后 改变数据
--
function CodeGameScreenRedHotDevilsMachine:MachineRule_stopReelChangeData()
    self.m_isAddBigWinLightEffect = true
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local changeLocs = selfData.changeLocs or {}
    if #changeLocs <= 0 then 
        self.m_isAddBigWinLightEffect = false
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenRedHotDevilsMachine:showBigWinLight(_func)
    local lightAni = util_createAnimation("RedHotDevils_bigwin.csb")

    local particle = lightAni:findChild("Particle_1")
    particle:setPositionType(0)
    particle:setDuration(-1)
    particle:resetSystem()

    self:findChild("Node_bigwin"):addChild(lightAni)
    lightAni:runCsbAction("actionframe", false, function()
        particle:stopSystem()
        lightAni:removeFromParent()
        if type(_func) == "function" then
            _func()
        end
    end)
    gLobalSoundManager:playSound(self.m_publicConfig.Music_Celebrate_Win)
    self:shakeRootNode()
end

return CodeGameScreenRedHotDevilsMachine






