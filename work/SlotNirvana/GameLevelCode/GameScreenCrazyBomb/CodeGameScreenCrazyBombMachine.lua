---
-- xcyy
-- 2018年5月11日
-- CodeGameScreenCrazyBombMachine.lua
--
-- 玩法： 法老金币
--

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseMachine = require "Levels.BaseMachine"
local CrazyBombBrick = require "CodeCrazyBombSrc.CrazyBombBrick"
local BaseDialog = util_require("Levels.BaseDialog")
local SendDataManager = require "network.SendDataManager"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenCrazyBombMachine = class("CodeGameScreenCrazyBombMachine", BaseSlotoManiaMachine)

CodeGameScreenCrazyBombMachine.m_iRespinTimes = 5
CodeGameScreenCrazyBombMachine.m_lightScore = 0
CodeGameScreenCrazyBombMachine.m_vecRunActionPos = nil
CodeGameScreenCrazyBombMachine.m_vecRunActionPig = nil
CodeGameScreenCrazyBombMachine.m_vecCurrShowShape = nil
CodeGameScreenCrazyBombMachine.m_vecSinglePig = nil
CodeGameScreenCrazyBombMachine.m_vecPigs = nil
CodeGameScreenCrazyBombMachine.m_vecPigInfo = nil

CodeGameScreenCrazyBombMachine.SYMBOL_BIG_WILD = 101
CodeGameScreenCrazyBombMachine.m_bnBaseType = 102

CodeGameScreenCrazyBombMachine.m_isMachineBGPlayLoop = true

CodeGameScreenCrazyBombMachine.m_vecMultipleTotalBet = {1, 3, 5}
CodeGameScreenCrazyBombMachine.m_vecFreeSpinTimes = {0, 0, 10, 15, 25}
CodeGameScreenCrazyBombMachine.m_vecRespinTimes = {0, 0, 5, 7, 10}

CodeGameScreenCrazyBombMachine.m_vecCrazyBombBrick = nil
CodeGameScreenCrazyBombMachine.m_choiceTriggerRespin = nil

CodeGameScreenCrazyBombMachine.m_aFreeSpinWildArry = nil
CodeGameScreenCrazyBombMachine.m_freeSpinWildChange = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenCrazyBombMachine.m_Wheel = GameEffect.EFFECT_SELF_EFFECT - 2

CodeGameScreenCrazyBombMachine.m_vecHighProPos = nil
CodeGameScreenCrazyBombMachine.m_vecBigWild = nil
CodeGameScreenCrazyBombMachine.m_vecAnimationPig = nil
CodeGameScreenCrazyBombMachine.m_vecRestorePigs = nil
CodeGameScreenCrazyBombMachine.m_vecHidePigs = nil
CodeGameScreenCrazyBombMachine.m_vecChangeShape = nil
CodeGameScreenCrazyBombMachine.m_bIsChangeShape = nil

CodeGameScreenCrazyBombMachine.m_bIsSelectCall = nil
CodeGameScreenCrazyBombMachine.m_iSelectID = nil
CodeGameScreenCrazyBombMachine.m_gameEffect = nil

CodeGameScreenCrazyBombMachine.m_chooseRepin = nil
CodeGameScreenCrazyBombMachine.m_WheelTipNode = nil
CodeGameScreenCrazyBombMachine.m_clickBet = nil

local CHOOSE_INDEX = {
    CHOOSE_FREESPIN = 0,
    CHOOSE_RESPIN = 1
}

local RESPIN_BIG_REWARD_MULTIP = 5000
local RESPIN_BIG_REWARD_SYMBOL_NUM = 15

-- 构造函数
function CodeGameScreenCrazyBombMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_lightScore = 0
    self.m_isBonusTrigger = false
    self.m_isFeatureOverBigWinInFree = true

    --init
    self:initGame()
end

function CodeGameScreenCrazyBombMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("CrazyBombConfig.csv", "LevelCrazyBombConfig.lua")

    self:setClipWidthRatio(5)

    --设置音效
    --初始化基本数据
    self:initMachine(self.m_moduleName)

    self.m_scatterBulingSoundArry = {}
    for i = 1, self.m_iReelColumnNum do
        local soundPath = "CrazyBombSounds/sound_CrazyBomb_scatter_1.mp3"
        if i > 2 and i < 5 then
            soundPath = "CrazyBombSounds/sound_CrazyBomb_scatter_2.mp3"
        elseif i == 5 then
            soundPath = "CrazyBombSounds/sound_CrazyBomb_scatter_3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end

    -- self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 10)
end

function CodeGameScreenCrazyBombMachine:initUI()
    self.m_gameBg:runCsbAction("normal")

    self.m_machineBomb = util_spineCreateDifferentPath("CrazyBomb_Spine_Guochang", "CrazyBomb_Spine_Guochang", true, true)
    self.m_machineBomb:setVisible(false)
    -- self.m_machineBomb:setPosition(cc.p(self.m_root:getPosition()))
    self.m_root:addChild(self.m_machineBomb, 99999)
    -- util_spinePlay(self.m_dropPig, "actionframe", false)

    self.m_BgRing_1 = util_createView("CodeCrazyBombSrc.CrazyBombBgRing")
    self.m_gameBg:findChild("light_1"):addChild(self.m_BgRing_1)
    self.m_BgRing_1:setVisible(false)

    self.m_BgRing_2 = util_createView("CodeCrazyBombSrc.CrazyBombBgRing")
    self.m_gameBg:findChild("light_2"):addChild(self.m_BgRing_2)
    self.m_BgRing_2:setVisible(false)

    self.m_BreakTu = util_createView("CodeCrazyBombSrc.CrazyBombBreakTu")
    self.m_root:addChild(self.m_BreakTu, 99999)
    self.m_BreakTu:setVisible(false)

    self.m_betChoiceIcon = util_createView("CodeCrazyBombSrc.CrazyBombHighLowBetIcon", self)
    self:findChild("Node_highLowBet"):addChild(self.m_betChoiceIcon)
    -- self:findChild("Node_highLowBet"):setPositionX(display.cx-self.m_betChoiceIcon:getIconWidth())
    self:findChild("Node_highLowBet"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100000)

    self.m_winFrame = util_createView("CodeCrazyBombSrc.CrazyBombWinFrame")
    local targetNode = self:findChild("RespinTimes")
    targetNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    targetNode:addChild(self.m_winFrame, 10)
    -- self.m_winFrame:setFadeInAction()
    util_setCsbVisible(self.m_winFrame, false)

    self.m_jackPotBar = util_createView("CodeCrazyBombSrc.CrazyBombTopBar")
    self:findChild("Jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self:initFreeSpinBar()
    -- util_setPositionPercent(self.m_csbNode,0.44)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end

            local winAmonut = params[1]
            if type(winAmonut) == "number" then
                local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
                local winRatio = winAmonut / lTatolBetNum
                local index = 1
                local soundTime = 2
                if winRatio > 0 then
                    if winRatio < 1 then
                        index = 1
                        soundTime = 2
                    elseif winRatio >= 1 and winRatio < 3 then
                        index = 2
                        soundTime = 2
                    else
                        index = 3
                        soundTime = 3
                    end
                end
                globalMachineController:playBgmAndResume("CrazyBombSounds/music_Chinese_last_win_" .. index .. ".mp3", soundTime, 0.4, 1)
            end
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    self:runCsbAction("animation0", true)

    self.m_choiceTriggerRespin = false
    self.m_vecRunActionPos = {}
    self.m_vecRunActionPig = {}
    self.m_vecCurrShowShape = {}
    self.m_vecSinglePig = {}
    self.m_vecPigs = {}
    self.m_vecCrazyBombBrick = {}
    self.m_vecPigInfo = nil
    self.m_aFreeSpinWildArry = {}
    self.m_vecHighProPos = {}
    self.m_vecAnimationPig = {}
    self.m_vecRestorePigs = {}
    self.m_vecHidePigs = {}
    self.m_vecChangeShape = {}
    self.m_bIsChangeShape = false
    self.m_chooseRepin = false
end

--ReSpin结算改变UI状态
function CodeGameScreenCrazyBombMachine:changeReSpinOverUI()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinBar()
    end
end

function CodeGameScreenCrazyBombMachine:initJackpotInfo(jackpotPool, lastTotalBet)
    self.m_jackPotBar:updateJackpotInfo()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCrazyBombMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CrazyBomb"
end

function CodeGameScreenCrazyBombMachine:getRespinView()
    return "CodeCrazyBombSrc.CrazyBombRespinView"
end

function CodeGameScreenCrazyBombMachine:getRespinNode()
    return "CodeCrazyBombSrc.CrazyBombRespinNode"
end

--统计quest
function CodeGameScreenCrazyBombMachine:MachineRule_afterNetWorkLineLogicCalculate()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCrazyBombMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.m_bnBaseType then
        return "CrazyBomb_Spine_chip"
    elseif symbolType == self.SYMBOL_BIG_WILD then
        return "Socre_CrazyBomb_Wild_1x3"
    end

    return nil
end

function CodeGameScreenCrazyBombMachine:getReelHeight()
    return 578
end

function CodeGameScreenCrazyBombMachine:getReelWidth()
    return 1065
end

function CodeGameScreenCrazyBombMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("bg_0"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)
    self.m_gameBg = gameBg
end

function CodeGameScreenCrazyBombMachine:scaleMainLayer()
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
    if globalData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        -- self.m_machineNode:setPositionY(mainPosY + posChange)
        local posChange = 10
        local ratio = display.height / display.width
        if ratio >= 768 / 1024 then
            mainScale = 0.80
        elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
            mainScale = 0.9 - 0.05 * ((ratio - 640 / 960) / (768 / 1024 - 640 / 960))
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCrazyBombMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.m_bnBaseType, count = 2}

    return loadNode
end

--[[
    @desc: 处理大信号裁剪区域问题， 主要是因为小猪长条 wild 要高于格子*所占行数
    time:2019-03-02 12:51:06
    --@showMask:
    @return:
]]
function CodeGameScreenCrazyBombMachine:operaBigSymbolShowMask(childNode)
    -- 这行是获取每列的显示行数， 为了适应多不规则轮盘
    local colIndex = childNode.p_cloumnIndex
    local columnData = self.m_reelColDatas[colIndex]
    local rowCount = self.m_iReelRowNum

    local symbolCount = self.m_bigSymbolInfos[childNode.p_symbolType]
    local startRowIndex = childNode.p_rowIndex

    local chipH = 0
    local diffH = 30
    local addY = 0
    local addH = 0
    if startRowIndex < 1 then --
        chipH = (symbolCount + startRowIndex - 1) * columnData.p_showGridH
        addH = diffH * 0.5
    elseif startRowIndex > 1 then
        local diffCount = startRowIndex + symbolCount - 1 - rowCount
        if diffCount > 0 then
            chipH = (symbolCount - diffCount) * columnData.p_showGridH
        else
            chipH = symbolCount * columnData.p_showGridH
        end

        addH = diffH * 0.5
        addY = -diffH * 0.5
    else
        chipH = symbolCount * columnData.p_showGridH
        addH = diffH
        addY = -diffH * 0.5
    end

    local clipY = 0
    if startRowIndex < 1 then
        clipY = math.abs((startRowIndex - 1) * columnData.p_showGridH)
    end
    chipH = chipH + addH
    clipY = clipY - columnData.p_showGridH * 0.5 + addY

    -- local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + colIndex)
    local clipNode = self:getClipNodeForTage(CLIP_NODE_TAG + colIndex)
    local reelW = clipNode:getClippingRegion().width

    childNode:showBigSymbolClip(clipY, reelW, chipH)
end

----------------------------- 玩法处理 ----------------------------------

--ReSpin开始改变UI状态
function CodeGameScreenCrazyBombMachine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_winFrame, true)
    self.m_winFrame:setFadeInAction()
    self.m_winFrame:updateLeftCount(respinCount)

    self.m_BgRing_1:setVisible(true)
    self.m_BgRing_1:runCsbAction("actionframe", true)
    self.m_BgRing_2:setVisible(true)
    self.m_BgRing_2:runCsbAction("actionframe", true)

    if self.m_runSpinResultData.p_freeSpinsTotalCount == nil or self.m_runSpinResultData.p_freeSpinsTotalCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal_change_respin")
    else
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin_change_respin")
    end
end

--ReSpin刷新数量
function CodeGameScreenCrazyBombMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_winFrame:updateLeftCount(curCount)
end

---respinFeature
function CodeGameScreenCrazyBombMachine:getRespinFeature(...)
    if self.m_reSpinCurCount == self.m_iRespinTimes then
        return {0, 3}
    end
    return {0}
end

function CodeGameScreenCrazyBombMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self, reelCol)

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for k = 1, self.m_iReelRowNum do
            if self.m_stcValidSymbolMatrix[k][reelCol] == self.m_bnBaseType then
                isHaveFixSymbol = true
                break
            end
        end
        if isHaveFixSymbol == true then
        -- gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_bonus_auto.mp3")
        end
    end

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        if self:getGameSpinStage() == QUICK_RUN then
            for k, v in pairs(self.m_reelRunAnima) do
                local runEffectBg = v
                if runEffectBg ~= nil and runEffectBg[1]:isVisible() then
                    runEffectBg[1]:setVisible(false)
                end
            end
        end
    end
end

---------------------------------------------------------------------------

function CodeGameScreenCrazyBombMachine:showEffect_FreeSpin(effectData)
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

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if scatterLineValue ~= nil then
        --
        gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_trigger_fs.mp3")

        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                gLobalSoundManager:stopAllAuido() -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenCrazyBombMachine:showFreatureChooseView(freeSpinNum, respinNum, func)
    local view = util_createView("CodeCrazyBombSrc.CrazyBombFeatureChooseView")
    -- if self.m_isLocalData == true then
    --     view:enableLocalData(self)
    -- end

    performWithDelay(
        self,
        function()
            self.m_bottomUI:checkClearWinLabel()
        end,
        0.8
    )
    view:initViewData(
        freeSpinNum,
        respinNum,
        func,
        function()
            self:levelFreeSpinEffectChange()
        end
    )
    gLobalViewManager:showUI(view)
end

function CodeGameScreenCrazyBombMachine:showReSpinStart(func)
    self:clearCurMusicBg()

    -- self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func,BaseDialog.AUTO_TYPE_ONLY)
    -- gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_show_choose_layer.mp3")
    scheduler.performWithDelayGlobal(
        function()
            func()
        end,
        1.3,
        self:getModuleName()
    )

    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

function CodeGameScreenCrazyBombMachine:spinResultCallFun(param)
    BaseSlotoManiaMachine.spinResultCallFun(self, param)
    if self.m_bIsSelectCall then
        if self.m_iSelectID == CHOOSE_INDEX.CHOOSE_RESPIN then --  clock feature
            -- self:normalSpinBtnCall()
            self.m_iFreeSpinTimes = 0
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0
            self.m_bProduceSlots_InFreeSpin = false
            if self.m_gameEffect then
                self.m_gameEffect.p_isPlay = true
            end

            self.m_choiceTriggerRespin = true
            self.m_chooseRepin = true
            self.m_chooseRepinGame = true --选择respin
            self:playGameEffect()
        else
            self.m_isBonusTrigger = false
            globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
            globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes
            self:triggerFreeSpinCallFun()
            self.m_gameEffect.p_isPlay = true
            self:playGameEffect()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end
    end
    self.m_bIsSelectCall = false
end

function CodeGameScreenCrazyBombMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

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
    elseif self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end
end

-- function CodeGameScreenCrazyBombMachine:checkRemoveBigMegaEffect()
--     local bHasBonusEffect = self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
--     if bHasBonusEffect == true then
--         if self.m_bProduceSlots_InFreeSpin == false then
--             self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
--             self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
--         end

--     end

--     -- 如果处于 freespin 中 那么大赢都不触发
--     local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
--     if hasFsOverEffect == true or  self.m_bProduceSlots_InFreeSpin == true then
--         self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
--         self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
--     end

-- end

function CodeGameScreenCrazyBombMachine:showEffect_Bonus(effectData)
    self.m_isBonusTrigger = true
    if self.m_runSpinResultData.p_selfMakeData then
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes_FREESPIN.times
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_iRespinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes_RESPIN.times
        end
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

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                gLobalSoundManager:stopAllAuido() -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenCrazyBombMachine:sendData(index)
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
        --     self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGameNew")
    else
        local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
        local httpSendMgr = SendDataManager:getInstance()
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
    end
end
function CodeGameScreenCrazyBombMachine:getNetWorkModuleName()
    return "CrazyBombV2"
end

function CodeGameScreenCrazyBombMachine:showFreeSpinView(effectData)
    if effectData.p_effectType == GameEffect.EFFECT_FREE_SPIN then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:triggerFreeSpinCallFun()
        effectData.p_isPlay = true
        self:playGameEffect()
    else
        -- 界面选择回调
        local function chooseCallBack(index)
            self:sendData(index)
            self.m_bIsSelectCall = true
            self.m_iSelectID = index
            self.m_gameEffect = effectData
        end

        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            scheduler.performWithDelayGlobal(
                function()
                    self:showFreatureChooseView(self.m_iFreeSpinTimes, self.m_iRespinTimes, chooseCallBack)
                end,
                0.7,
                self:getModuleName()
            )
        else
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            scheduler.performWithDelayGlobal(
                function()
                    self:showFreeSpinMore(
                        self.m_runSpinResultData.p_freeSpinNewCount,
                        function()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end,
                        true
                    )
                    gLobalSoundManager:playSound("LinkCatSounds/music_linkCat_custom_enter_fs_2.mp3")
                end,
                0.8,
                self:getModuleName()
            )
        end
    end
end

function CodeGameScreenCrazyBombMachine:showFreeSpinStart(num, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_ONLY)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenCrazyBombMachine:bombMove(func)
    local endPos = cc.p(0, 0)
    local startPos = cc.p(-display.width / 2, -display.height / 4)
    self:nodeJumpAction(startPos, endPos, 0.5, func)
end

function CodeGameScreenCrazyBombMachine:nodeJumpAction(startPos, endPos, flyTime, func)
    local node = cc.Node:create()
    local spinenode = util_spineCreateDifferentPath("CrazyBomb_Spine_chip", "CrazyBomb_Spine_chip", true, true)
    node:addChild(spinenode)
    self:findChild("root"):addChild(node, 99999)
    node:setPosition(startPos)

    local actionList = {}

    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            local scaleLIst = {}
            scaleLIst[#scaleLIst + 1] = cc.ScaleTo:create(flyTime, 1)
            node:runAction(cc.Sequence:create(scaleLIst))
        end
    )

    actionList[#actionList + 1] = cc.EaseInOut:create(cc.JumpTo:create(flyTime, cc.p(endPos), 200, 1), 1)

    -- actionList[#actionList + 1] = cc.DelayTime:create(flyTime)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if node then
                node:removeFromParent()
            end
            func()
        end
    )

    node:runAction(cc.Sequence:create(actionList))

    util_spinePlay(spinenode, "idleframe", true)
end

function CodeGameScreenCrazyBombMachine:showFreeSpinOverView()
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_1.mp3")

            local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 20)

            local view =
                self:showFreeSpinOver(
                strCoins,
                self.m_runSpinResultData.p_freeSpinsTotalCount,
                function()
                    gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_touch_view_btn.mp3")

                    self.m_machineBomb:setVisible(true)
                    gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_thief_run.mp3")
                    util_spinePlay(self.m_machineBomb, "actionframe", false)
                    util_spineEndCallFunc(
                        self.m_machineBomb,
                        "actionframe",
                        function()
                            self:triggerFreeSpinOverCallFun()
                        end
                    )

                    util_spineFrameEvent(
                        self.m_machineBomb,
                        "actionframe",
                        "show",
                        function()
                            self:levelFreeSpinOverChangeEffect()
                        end
                    )
                end
            )
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_STATUS,false)
            local node = view:findChild("m_lb_coins")

            view:updateLabelSize({label = node, sx = 1.0, sy = 1.0}, 677)
        end,
        1.6
    )
end

function CodeGameScreenCrazyBombMachine:respinEnd()
    for i = #self.m_vecCurrShowShape, 1, -1 do
        if self.m_vecCurrShowShape[i].area >= 4 then
            local vecBrick = self.m_configData:getPigShapePro(self.m_vecCurrShowShape[i].area)
            local result = 0
            local lineBet = globalData.slotRunData:getCurTotalBet()
            for j = 1, #self.m_runSpinResultData.p_winLines, 1 do
                if self.m_vecCurrShowShape[i].position == self.m_runSpinResultData.p_winLines[j].p_id then
                    result = self.m_runSpinResultData.p_winLines[j].p_multiple
                    break
                end
            end
            local vecShowBrick = self.m_configData:getPigShapeShow(self.m_vecCurrShowShape[i].area)
            self.m_vecCurrShowShape[i].vecBrick = vecShowBrick
            self.m_vecCurrShowShape[i].result = result
        end
    end
end
function CodeGameScreenCrazyBombMachine:reSpinReelDown(addNode)
    --刷新quest计数
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self:updatePigShape()
        self:respinEnd()
        self:playPigsAnimation(
            function()
                -- BaseMachine.reSpinReelDown(self)
                self:selfMakeReSpinReelDown()
                if
                    self.m_runSpinResultData.p_features and #self.m_runSpinResultData.p_features == 2 and
                        (self.m_runSpinResultData.p_features[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or self.m_runSpinResultData.p_features[2] == SLOTO_FEATURE.FEATURE_FREESPIN)
                 then
                    local bonusGameEffect = GameEffectData.new()
                    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
                    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
                    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
                end
            end
        )
    else
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self:runNextReSpinReel(true)
    end
end

function CodeGameScreenCrazyBombMachine:runNextReSpinReel(_isCrazyBombStates)
    self:updatePigShape()
    self:playPigsAnimation(
        function()
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                self:reSpinReelDown()
                return
            end
            BaseMachine.runNextReSpinReel(self)
            if _isCrazyBombStates then
                self:setGameSpinStage(STOP_RUN)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
        end
    )
end

function CodeGameScreenCrazyBombMachine:playPigsAnimation(fuc)
    local vecShapes = self.m_runSpinResultData.p_rsExtraData.shapes

    if #vecShapes == 0 then
        performWithDelay(
            self,
            function()
                fuc()
            end,
            0.5
        )
        return
    end

    if self.m_bIsChangeShape then
        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pig_hide_show.mp3")
        for i = 1, #self.m_vecChangeShape, 1 do
            self.m_vecChangeShape[i].node:runAnim(
                "changstart",
                false,
                function()
                    if self.m_vecChangeShape[i].node:getChildByName("bg") then
                        self.m_vecChangeShape[i].node:getChildByName("bg"):removeFromParent()
                    end
                    scheduler.performWithDelayGlobal(
                        function()
                            self.m_vecChangeShape[i].node:removeFromParent()
                        end,
                        0.1,
                        self:getModuleName()
                    )
                end
            )
        end

        for i = 1, #self.m_vecRunActionPig, 1 do
            local newPos = {iX = 0, iY = 0}
            local maxCol = 0
            for j = 1, #self.m_vecRunActionPig[i].pos do
                local pos = self.m_vecRunActionPig[i].pos[j]
                maxCol = math.max(maxCol, pos.iY)
                local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
                 --self:getReelParent(pos.iX):getChildByTag(self:getNodeTag(pos.iX,  pos.iY, SYMBOL_NODE_TAG))
                newPos.iX = newPos.iX + symbolNode:getPositionX()
                newPos.iY = newPos.iY + symbolNode:getPositionY()
                local isHidePig = false
                for n = 1, #self.m_vecHidePigs, 1 do
                    if pos.iX == self.m_vecHidePigs[n].iX and pos.iY == self.m_vecHidePigs[n].iY then
                        table.remove(self.m_vecHidePigs, n)
                        isHidePig = true
                        break
                    end
                end
                if isHidePig == false then
                    symbolNode:runAnim(
                        "changstart",
                        false,
                        function()
                            if symbolNode:getChildByName("bg") then
                                symbolNode:getChildByName("bg"):removeFromParent()
                            end
                        end
                    )
                end
            end
            newPos.iX = newPos.iX / self.m_vecRunActionPig[i].area
            newPos.iY = newPos.iY / self.m_vecRunActionPig[i].area

            local newPig = self.m_vecAnimationPig[i]
            self.m_respinView:addChild(newPig, REEL_SYMBOL_ORDER.REEL_ORDER_2 + maxCol)
            newPig:setPosition(newPos.iX, newPos.iY)
            newPig:release()
            local indexNum = i
            newPig:setVisible(false)
            if newPig:getChildByName("bg") then
                newPig:getChildByName("bg"):setVisible(false)
            end
            if indexNum == #self.m_vecRunActionPig then
                performWithDelay(
                    self,
                    function()
                        gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_to_big.mp3")
                    end,
                    0.2
                )
            end

            performWithDelay(
                self,
                function()
                    newPig:setVisible(true)
                    if newPig:getChildByName("bg") then
                        newPig:getChildByName("bg"):setVisible(true)
                    end
                    newPig:runAnim(
                        "changover",
                        false,
                        function()
                            -- newPig:runAnim("buling", false, function ()
                            newPig:runAnim("idleframe", true)
                            if indexNum == #self.m_vecRunActionPig then
                                fuc()
                            end
                            -- end)
                        end
                    )
                end,
                0.4
            )
        end

        for i = 1, #self.m_vecRestorePigs, 1 do
            local pos = self.m_vecRestorePigs[i]
            local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
             --self:getReelParent(pos.iX):getChildByTag(self:getNodeTag(pos.iX,  pos.iY, SYMBOL_NODE_TAG))
            performWithDelay(
                self,
                function()
                    symbolNode:runAnim(
                        "changover",
                        false,
                        function()
                            symbolNode:runAnim("idleframe", true)
                        end
                    )
                end,
                0.4
            )
        end

        if #self.m_vecRunActionPig == 0 then
            performWithDelay(
                self,
                function()
                    fuc()
                end,
                0.5
            )
        end
    else
        performWithDelay(
            self,
            function()
                fuc()
            end,
            0.5
        )
    end
end

function CodeGameScreenCrazyBombMachine:updatePigShape()
    local vecShapes = self.m_runSpinResultData.p_rsExtraData.shapes
    local vecPigsShape = {}
    if self.m_vecSinglePig == nil then
        self.m_vecSinglePig = {}
    end
    for i = #self.m_vecSinglePig, 1, -1 do
        table.remove(self.m_vecSinglePig, i)
    end

    for i = 1, #vecShapes, 1 do
        local pig = {}
        pig.shape = vecShapes[i].width .. "x" .. vecShapes[i].height
        pig.area = vecShapes[i].width * vecShapes[i].height
        pig.icons = vecShapes[i].icons
        pig.position = vecShapes[i].position
        pig.md5 = pig.shape .. vecShapes[i].position
        if pig.area > 1 then
            vecPigsShape[#vecPigsShape + 1] = pig
        elseif self.m_runSpinResultData.p_reSpinCurCount == 0 then
            self.m_vecSinglePig[#self.m_vecSinglePig + 1] = self:getRowAndColByPos(vecShapes[i].position)
        end
    end

    local pigsShapesInfo = self:initPigsShapesInfo(vecPigsShape)

    self.m_bIsChangeShape = false
    for i = #self.m_vecRestorePigs, 1, -1 do
        table.remove(self.m_vecRestorePigs, i)
    end
    for i = #self.m_vecHidePigs, 1, -1 do
        table.remove(self.m_vecHidePigs, i)
    end
    for i = #self.m_vecChangeShape, 1, -1 do
        table.remove(self.m_vecChangeShape, i)
    end

    for i = #self.m_vecAnimationPig, 1, -1 do
        table.remove(self.m_vecAnimationPig, i)
    end

    if self.m_vecPigInfo == nil then
        self.m_bIsChangeShape = true
        self.m_vecPigInfo = pigsShapesInfo
        for i = 1, #pigsShapesInfo.info, 1 do
            self.m_vecRunActionPig[#self.m_vecRunActionPig + 1] = self:getPigsShapesInfo(pigsShapesInfo.info[i], self.m_vecRunActionPos)
        end
    else
        if self.m_vecPigInfo.priority < pigsShapesInfo.priority then
            self.m_bIsChangeShape = true
            self.m_vecPigInfo = pigsShapesInfo
            local vecRunActionPig = {}
            local vecRunActionPos = {}
            for i = 1, #pigsShapesInfo.info, 1 do
                vecRunActionPig[#vecRunActionPig + 1] = self:getPigsShapesInfo(pigsShapesInfo.info[i], vecRunActionPos)
            end

            for i = #self.m_vecRunActionPos, 1, -1 do
                local posA = self.m_vecRunActionPos[i]
                for j = 1, #vecRunActionPos, 1 do
                    if posA.iX == vecRunActionPos[j].iX and posA.iY == vecRunActionPos[j].iY then
                        self.m_vecHidePigs[#self.m_vecHidePigs + 1] = posA
                        table.remove(self.m_vecRunActionPos, i)
                        break
                    end
                end
            end
            for i = 1, #self.m_vecRunActionPos, 1 do
                self.m_vecRestorePigs[#self.m_vecRestorePigs + 1] = self.m_vecRunActionPos[i]
            end

            for i = #self.m_vecCurrShowShape, 1, -1 do
                local bFlag = false
                for j = 1, #vecRunActionPig, 1 do
                    if self.m_vecCurrShowShape[i].md5 == vecRunActionPig[j].md5 then
                        bFlag = false
                        table.remove(vecRunActionPig, j)
                        break
                    else
                        bFlag = true
                    end
                end
                if bFlag then
                    self.m_vecChangeShape[#self.m_vecChangeShape + 1] = self.m_vecCurrShowShape[i]
                end
            end
            for i = 1, #self.m_vecChangeShape, 1 do
                for j = 1, #self.m_vecCurrShowShape, 1 do
                    if self.m_vecChangeShape[i].md5 == self.m_vecCurrShowShape[j].md5 then
                        table.remove(self.m_vecCurrShowShape, j)
                        break
                    end
                end
            end

            self.m_vecRunActionPig = vecRunActionPig
            self.m_vecRunActionPos = vecRunActionPos
        end
    end

    if self.m_bIsChangeShape then
        for i = 1, #self.m_vecRunActionPig, 1 do
            local csbName = "CrazyBomb_Spine_chip" .. self.m_vecRunActionPig[i].shape
            local data = {}
            data.csbName = csbName
            data.vecCrazyBombBrick = self.m_vecCrazyBombBrick
            data.cloumnIndex = self.m_vecRunActionPig[i].pos[1].iX
            data.rowIndex = self.m_vecRunActionPig[i].pos[1].iY
            data.width = self.m_vecRunActionPig[i].width
            for j = 2, #self.m_vecRunActionPig[i].pos do
                data.rowIndex = math.max(data.rowIndex, self.m_vecRunActionPig[i].pos[j].iY)
                data.cloumnIndex = math.min(data.cloumnIndex, self.m_vecRunActionPig[i].pos[j].iX)
            end
            data.m_machine = self
            local newPig = util_createView("CodeCrazyBombSrc.CrazyBombPigShape", data)
            newPig:retain()
            self.m_vecAnimationPig[#self.m_vecAnimationPig + 1] = newPig

            local currShowShape = {}
            currShowShape.node = newPig
            currShowShape.pos = self.m_vecRunActionPig[i].pos
            currShowShape.area = self.m_vecRunActionPig[i].area
            currShowShape.md5 = self.m_vecRunActionPig[i].md5
            currShowShape.position = self.m_vecRunActionPig[i].position
            self.m_vecCurrShowShape[#self.m_vecCurrShowShape + 1] = currShowShape
        end
    end
end

function CodeGameScreenCrazyBombMachine:getPigsShapesInfo(info, changePos)
    local tempShape = {}
    tempShape.shape = info.shape
    tempShape.area = info.area
    tempShape.md5 = info.md5
    tempShape.position = info.position
    tempShape.width = tonumber(string.sub(tempShape.shape, 1, 1))
    tempShape.height = tonumber(string.sub(tempShape.shape, -1))
    for i = 1, #info.icons, 1 do
        local pos = self:getRowAndColByPos(info.icons[i])
        if tempShape.pos == nil then
            tempShape.pos = {}
        end
        tempShape.pos[#tempShape.pos + 1] = pos
        changePos[#changePos + 1] = pos
    end
    return tempShape
end

function CodeGameScreenCrazyBombMachine:initPigsShapesInfo(vecPigsShape)
    local pigsShapesInfo = {}
    local strNum = ""
    for i = 1, 5, 1 do
        local num
        if i <= #vecPigsShape then
            strNum = strNum .. vecPigsShape[i].area
        else
            strNum = strNum .. "0"
        end
    end
    pigsShapesInfo.priority = tonumber(strNum)
    pigsShapesInfo.info = vecPigsShape
    return pigsShapesInfo
end

---
-- 重写 getSlotNodeWithPosAndType 方法
function CodeGameScreenCrazyBombMachine:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, iRow, iCol, isLastSymbol)

    if symbolType == self.m_bnBaseType then
        local callFun = cc.CallFunc:create(handler(self, self.setPlayAnimationName), {reelNode})
        self:runAction(callFun)
    end
    return reelNode
end

function CodeGameScreenCrazyBombMachine:setPlayAnimationName(sender, param)
    local symbolNode = param[1]
    symbolNode.p_reelDownRunAnima = "buling"
    symbolNode.p_reelDownRunAnimaSound = "CrazyBombSounds/sound_CrazyBomb_buling.mp3"
    if self.m_runSpinResultData.p_reSpinsTotalCount ~= nil and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        symbolNode.p_reelDownRunAnima = "buling2"
        symbolNode.p_reelDownRunAnimaSound = "CrazyBombSounds/sound_CrazyBomb_buling2.mp3"
    end
end

-- RespinView
function CodeGameScreenCrazyBombMachine:showRespinView(effectData)
    --先播放动画 再进入respin
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_goin_lightning.mp3")
    --可随机的普通信息
    local randomTypes = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    }

    --可随机的特殊信号
    local endTypes = {
        {type = self.m_bnBaseType, runEndAnimaName = "", bRandom = true}
    }

    --构造盘面数据

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        self:triggerReSpinCallFun(endTypes, randomTypes)
    else
        -- 由玩法触发出来， 而不是多个元素触发
        if self.m_runSpinResultData.p_reSpinCurCount == 0 then
            self.m_runSpinResultData.p_reSpinCurCount = self.m_iRespinTimes
        end
        self:triggerReSpinCallFun(endTypes, randomTypes)
    end
end

--触发respin
function CodeGameScreenCrazyBombMachine:triggerReSpinCallFun(endTypes, randomTypes)
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self.m_respinView:initCrazyBombMachine(self)
    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenCrazyBombMachine:setWheelTipNode(node)
    self.m_WheelTipNode = node
end

-- --结束移除小块调用结算特效
function CodeGameScreenCrazyBombMachine:reSpinEndAction()
    scheduler.performWithDelayGlobal(
        function()
            self.m_winFrame:updateLeftCount(0)

            self:playTriggerLight()
        end,
        1,
        self:getModuleName()
    )
end

function CodeGameScreenCrazyBombMachine:playTriggerLight()
    self:breakLittlePigShape()

    self.m_winFrame:setFadeOutAction()
end

function CodeGameScreenCrazyBombMachine:breakLittlePigShape()
    local function breakPig(posX, posY, width, height, area, cloumnIndex, rowIndex, shape)
        local data = {}
        data.width = width
        data.height = height
        data.num = self:BaseMania_getLineBet() * self.m_lineCount * self.m_vecMultipleTotalBet[area]
        data.shape = shape
        local golden = CrazyBombBrick:create()
        golden:initUI(data)
        self.m_respinView:addChild(golden, REEL_SYMBOL_ORDER.REEL_ORDER_2)
        golden:setPosition(posX, posY)
        local brick = {}
        -- golden:retain()
        brick.width = 1
        brick.node = golden
        brick.cloumnIndex = cloumnIndex
        brick.rowIndex = rowIndex
        self.m_vecCrazyBombBrick[#self.m_vecCrazyBombBrick + 1] = brick
        self.m_lightScore = self.m_lightScore + data.num
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
    end

    local delayTime = 0
    for i = 1, #self.m_vecSinglePig, 1 do
        local symbolNode = self.m_respinView:getRespinEndNode(self.m_vecSinglePig[i].iX, self.m_vecSinglePig[i].iY)
        delayTime = (i - 1) * 1.5 + 0.8
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_little_pig_break.mp3")

                symbolNode:runAnim("over")
                local spinenode = symbolNode:checkLoadCCbNode()
                spinenode.m_spineNode:registerSpineEventHandler(
                    function(event) --通过registerSpineEventHandler这个方法注册
                        if event.animation == "over" then --根据动作名来区分
                            if event.eventData.name == "show" then --根据帧事件来区分
                                -- self.m_BreakTu:setVisible(true)
                                -- self.m_BreakTu:runCsbAction("actionframe1",false,function(  )
                                --     self.m_BreakTu:setVisible(false)
                                -- end)

                                -- self:runCsbAction("doudong1")

                                symbolNode:setVisible(false)
                                if symbolNode:getChildByName("bg") then
                                    symbolNode:getChildByName("bg"):removeFromParent()
                                end

                                breakPig(symbolNode:getPositionX(), symbolNode:getPositionY(), 194, 158, 1, self.m_vecSinglePig[i].iX, self.m_vecSinglePig[i].iY, "1x1")
                            end
                        end
                    end,
                    sp.EventType.ANIMATION_EVENT
                )
            end,
            delayTime,
            self:getModuleName()
        )
    end

    table.sort(
        self.m_vecCurrShowShape,
        function(a, b)
            return a.area > b.area
        end
    )

    for i = #self.m_vecCurrShowShape, 1, -1 do
        local minCol = self.m_iReelColumnNum
        for j = 1, #self.m_vecCurrShowShape[i].pos, 1 do
            local pos = self.m_vecCurrShowShape[i].pos[j]
            minCol = math.min(minCol, pos.iY)
            self.m_vecCurrShowShape[i].order = minCol
        end
    end

    local littleShape = {}
    local twoPigsShape = {}
    local threePigsShape = {}
    local fourPigsShape = {}
    local sixPigsShape = {}
    for i = #self.m_vecCurrShowShape, 1, -1 do
        if self.m_vecCurrShowShape[i].area == 3 then
            local minCol = self.m_iReelColumnNum
            threePigsShape[#threePigsShape + 1] = self.m_vecCurrShowShape[i]
            table.remove(self.m_vecCurrShowShape, i)
        elseif self.m_vecCurrShowShape[i].area == 2 then
            twoPigsShape[#twoPigsShape + 1] = self.m_vecCurrShowShape[i]
            table.remove(self.m_vecCurrShowShape, i)
        elseif self.m_vecCurrShowShape[i].area == 4 then
            local minCol = self.m_iReelColumnNum
            fourPigsShape[#fourPigsShape + 1] = self.m_vecCurrShowShape[i]
            table.remove(self.m_vecCurrShowShape, i)
        elseif self.m_vecCurrShowShape[i].area == 6 then
            sixPigsShape[#sixPigsShape + 1] = self.m_vecCurrShowShape[i]
            table.remove(self.m_vecCurrShowShape, i)
        end
    end
    table.sort(
        twoPigsShape,
        function(a, b)
            return a.order < b.order
        end
    )

    table.sort(
        threePigsShape,
        function(a, b)
            return a.order < b.order
        end
    )

    table.insertto(littleShape, twoPigsShape)
    table.insertto(littleShape, threePigsShape)

    table.sort(
        fourPigsShape,
        function(a, b)
            return a.order > b.order
        end
    )

    table.sort(
        sixPigsShape,
        function(a, b)
            return a.order > b.order
        end
    )

    table.insertto(self.m_vecCurrShowShape, sixPigsShape)
    table.insertto(self.m_vecCurrShowShape, fourPigsShape)

    local tempDelayTime = delayTime
    if #littleShape > 0 then
        delayTime = 0
    end

    for i = 1, #littleShape, 1 do
        delayTime = tempDelayTime + i * 1.5
        if tempDelayTime == 0 then
            delayTime = (i - 1) * 1.5 + 0.8
        end
        local node = littleShape[i].node
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pig_break.mp3")

                node:runAnim("over")

                node.m_spineNode:registerSpineEventHandler(
                    function(event) --通过registerSpineEventHandler这个方法注册
                        if event.animation == "over" then --根据动作名来区分
                            if event.eventData.name == "show" then --根据帧事件来区分
                                -- self.m_BreakTu:setVisible(true)
                                -- self.m_BreakTu:runCsbAction("actionframe1",false,function(  )
                                --     self.m_BreakTu:setVisible(false)
                                -- end)
                                -- self:runCsbAction("doudong1")
                                local cloumnIndex = littleShape[i].pos[1].iX
                                local rowIndex = littleShape[i].pos[1].iY
                                for j = 2, #littleShape[i].pos, 1 do
                                    rowIndex = math.max(rowIndex, littleShape[i].pos[j].iY)
                                    cloumnIndex = math.min(cloumnIndex, littleShape[i].pos[j].iX)
                                end
                                node:setVisible(false)
                                if node:getChildByName("bg") then
                                    node:getChildByName("bg"):removeFromParent()
                                end
                                breakPig(node:getPositionX(), node:getPositionY(), node.m_rect.width, node.m_rect.height, littleShape[i].area, cloumnIndex, rowIndex, node.shape)
                            end
                        end
                    end,
                    sp.EventType.ANIMATION_EVENT
                )
            end,
            delayTime,
            self:getModuleName()
        )
    end
    -- end
    scheduler.performWithDelayGlobal(
        function()
            self:breakBiggerPigShape()
        end,
        delayTime + 2.8,
        self:getModuleName()
    )
end

function CodeGameScreenCrazyBombMachine:breakBiggerPigShape(params)
    if params then
        local winCoin = params * self:BaseMania_getLineBet() * self.m_lineCount
        local index = 0
        if params == 20 then
            index = 4
        elseif params == 100 then
            index = 3
        elseif params == 1000 then
            index = 2
        elseif params == 5000 then
            index = 1
        end
        if index ~= 0 then
            winCoin = self:BaseMania_getJackpotScore(index)
        end
        self.m_lightScore = self.m_lightScore + winCoin
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
        if index ~= 0 then
            gLobalSoundManager:setBackgroundMusicVolume(0.4)
            gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_2.mp3")
            self:showRespinJackpot(
                index,
                util_formatCoins(winCoin, 20),
                function()
                    gLobalSoundManager:setBackgroundMusicVolume(1)
                    self:breakBiggerPigShape()
                end
            )
            return
        end
    end

    if #self.m_vecCurrShowShape > 0 then
        local vecBrick = self.m_vecCurrShowShape[#self.m_vecCurrShowShape].vecBrick
        local result = self.m_vecCurrShowShape[#self.m_vecCurrShowShape].result
        self.m_vecCurrShowShape[#self.m_vecCurrShowShape].node:addPress(vecBrick, result)
        table.remove(self.m_vecCurrShowShape, #self.m_vecCurrShowShape)
    else
        self:respinGameOver()
    end
end

function CodeGameScreenCrazyBombMachine:respinGameOver()
    scheduler.performWithDelayGlobal(
        function()
            self:showRespinOverView()
            self.m_vecCurrShowShape = {}
            self.m_vecRunActionPig = {}
            self.m_vecRunActionPos = {}
            self.m_vecPigInfo = nil
            self.m_choiceTriggerRespin = false
            self.m_vecAnimationPig = {}
            self.m_vecRestorePigs = {}
            self.m_vecHidePigs = {}
            self.m_vecChangeShape = {}
            self.m_vecSinglePig = {}
        end,
        1.2,
        self:getModuleName()
    )
end

function CodeGameScreenCrazyBombMachine:respinOverResetBrick()
    for i = 1, #self.m_vecCrazyBombBrick, 1 do
        local data = self.m_vecCrazyBombBrick[i]
        local posX, posY = data.node:getPosition()
        local worldPos = data.node:getParent():convertToWorldSpace(cc.p(posX, posY))
        local nodePos = self:getReelParent(data.cloumnIndex):convertToNodeSpace(worldPos)
        data.node:retain()
        data.node:removeFromParent()
        if data.node.m_data ~= nil then
            local golden = CrazyBombBrick:create()
            data.node.m_data.num = data.node.m_data.num * self:BaseMania_getLineBet() * self.m_lineCount
            golden:initUI(data.node.m_data)
            golden:retain()
            data.node:release()
            data.node = nil
            data.node = golden
        end
        self:getReelParent(data.cloumnIndex):addChild(data.node, REEL_SYMBOL_ORDER.REEL_ORDER_4 * data.width)
        data.node:setPosition(nodePos)
        self:resetCloumnZorder(data.cloumnIndex)
    end
    -- if self.m_WheelTipNode ~= nil then
    --     local unitPos = cc.p(self.m_WheelTipNode:getPositionX(), self.m_WheelTipNode:getPositionY())
    --     unitPos = self.m_WheelTipNode:getParent():convertToWorldSpace(unitPos)
    --     self.m_WheelTipNode = util_createView("CodeCrazyBombSrc.CrazyBombWheelSymbolTip")
    --     self.m_WheelTipNode:runCsbAction("lunpan_idle",true)
    --     self:addChild(self.m_WheelTipNode, GAME_LAYER_ORDER.LAYER_ORDER_EFFECT)
    --     self.m_WheelTipNode:setPosition(unitPos)
    -- end
    self.m_vecCrazyBombBrick = {}
end

--- 自己写的判断结算
-- 与ReSpinReelDown 实现方式一样
function CodeGameScreenCrazyBombMachine:selfMakeReSpinReelDown()
    self:setGameSpinStage(STOP_RUN)

    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()

        --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        local wheelCoins = self:getJackPotCoins()
        local rsAddCoins = self.m_serverWinCoins - wheelCoins

        self:checkFeatureOverTriggerBigWin(rsAddCoins, GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    --继续
    self:runNextReSpinReel()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end

function CodeGameScreenCrazyBombMachine:showRespinJackpot(index, coins, func)
    local jackPotWinView = util_createView("CodeCrazyBombSrc.CrazyBombJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index, coins, self, func)
end

function CodeGameScreenCrazyBombMachine:showEffect_RespinOver(effectData)
    local wheelCoins = self:getJackPotCoins()
    local rsAddCoins = self.m_serverWinCoins - wheelCoins
    self:checkFeatureOverTriggerBigWin(rsAddCoins, GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    self:removeRespinNode()
    self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function CodeGameScreenCrazyBombMachine:showRespinOverView(effectData)
    local seq =
        cc.Sequence:create(
        cc.DelayTime:create(0.5),
        cc.CallFunc:create(
            function()
                util_setCsbVisible(self.m_winFrame, false)

                util_setCsbVisible(self.m_jackPotBar, true)
                self.m_BgRing_1:setVisible(false)
                self.m_BgRing_1:runCsbAction("actionframe", false)
                self.m_BgRing_2:setVisible(false)
                self.m_BgRing_2:runCsbAction("actionframe", false)
            end
        )
    )

    self:runAction(seq)

    local wheelCoins = self.m_serverWinCoins - self:getJackPotCoins()

    local strCoins = util_formatCoins(wheelCoins, 20)
    gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pop_win_1.mp3")
    local times = self.m_runSpinResultData.p_reSpinsTotalCount
    local view =
        self:showReSpinOver(
        times,
        strCoins,
        function()
            -- 自定义事件显示轮盘
            local data = self.m_runSpinResultData.p_rsExtraData

            if data and data.wheel and data.target then
                local WheelEffect = GameEffectData.new()
                WheelEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                WheelEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 2
                WheelEffect.p_selfEffectType = self.m_Wheel

                local pos = #self.m_gameEffects + 1

                if data.target == "FreeGame" or data.target == "Free Game" then
                    for k, v in pairs(self.m_gameEffects) do
                        if v.p_effectType == GameEffect.EFFECT_BONUS then
                            self.m_gameEffects[k].p_effectOrder = GameEffect.EFFECT_FREE_SPIN
                            self.m_gameEffects[k].p_effectType = GameEffect.EFFECT_FREE_SPIN
                            pos = k
                            break
                        end
                    end
                end

                if pos == #self.m_gameEffects + 1 then
                    self.m_gameEffects[pos] = WheelEffect
                    --TODO  后续考虑优化修改 , 检测是否有quest effect ， 将其位置信息放到quest 前面
                    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
                    if hasQuestEffect == true then
                        self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
                        local questEffect = GameEffectData:create()
                        questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
                        questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
                        self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
                    end
                else
                    table.insert(self.m_gameEffects, pos, WheelEffect)
                end

                gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_touch_view_btn.mp3")

                self:triggerReSpinOverCallFun(self.m_lightScore)
                self.m_lightScore = 0

                if data and data.wheel and data.target then
                else
                    self:resetMusicBg()
                end
            else
                self.m_machineBomb:setVisible(true)
                gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_thief_run.mp3")
                util_spinePlay(self.m_machineBomb, "actionframe")
                util_spineEndCallFunc(
                    self.m_machineBomb,
                    "actionframe",
                    function()
                        gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_touch_view_btn.mp3")

                        self:triggerReSpinOverCallFun(self.m_lightScore)
                        self.m_lightScore = 0
                        self:resetMusicBg()
                    end
                )

                util_spineFrameEvent(
                    self.m_machineBomb,
                    "actionframe",
                    "show",
                    function()
                        self:respinOver()
                        if self.m_runSpinResultData.p_freeSpinsTotalCount == nil or self.m_runSpinResultData.p_freeSpinsTotalCount == 0 then
                            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
                        else
                            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
                            util_setCsbVisible(self.m_winFrame, true)
                            self.m_winFrame:runCsbAction("freespinPays_start")
                        end
                    end
                )
            end
        end
    )
    local node = view:findChild("m_lb_coins")
    self:updateLabelSize({label = node, sx = 1.0, sy = 1.0}, 677)

    for i = 1, self.m_iReelColumnNum, 1 do
        local parent = self:getReelParent(i)
        local children = parent:getChildren()
        for j = 1, #children, 1 do
            local child = children[j]
            if child.p_symbolType ~= nil and child.p_symbolType == self.SYMBOL_BIG_WILD then
                child:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(self.SYMBOL_BIG_WILD, child)
            end
        end
    end
end

function CodeGameScreenCrazyBombMachine:cleanRespinGray()
    for iCol = 1, self.m_iReelColumnNum do --列
        local children = self:getReelParent(iCol):getChildren()
        for i = 1, #children, 1 do
            local child = children[i]
            if child.p_symbolType ~= nil and child.p_symbolType ~= self.m_bnBaseType then
                local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(child.m_ccbName)
                if imageName ~= nil then
                    child:spriteChangeImage(child.p_symbolImage, imageName)
                end
            end
        end
    end
end

function CodeGameScreenCrazyBombMachine:getJackPotCoins()
    local winLines = self.m_runSpinResultData.p_winLines
    local coins = 0
    for k, v in pairs(winLines) do
        if v.p_id < 0 then
            coins = v.p_amount
            return coins
        end
    end

    return coins
end

function CodeGameScreenCrazyBombMachine:respinOver()
    self:respinOverResetBrick()
    self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:removeRespinNode()
    self:cleanRespinGray()
end

function CodeGameScreenCrazyBombMachine:triggerReSpinOverCallFun(score)
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

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

    local wheelCoins = self:getJackPotCoins()

    if self.m_bProduceSlots_InFreeSpin then
        local addCoin = self.m_serverWinCoins
        local fsAddCoins = self:getLastWinCoin() - wheelCoins
        if fsAddCoins <= 0 then
            fsAddCoins = self:getLastWinCoin()
        end
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        if wheelCoins > 0 then
            globalData.slotRunData.lastWinCoin = 0
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {fsAddCoins, false, false})

        globalData.slotRunData.lastWinCoin = lastWinCoin
    else
        local norAddCoins = toLongNumber(globalData.userRunData.coinNum - wheelCoins)
        -- LongNumber
        if norAddCoins <= toLongNumber(0) then
            norAddCoins = globalData.userRunData.coinNum
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, norAddCoins)

        local coins = self.m_serverWinCoins - wheelCoins
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        if wheelCoins > 0 then
            globalData.slotRunData.lastWinCoin = 0
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})

        globalData.slotRunData.lastWinCoin = lastWinCoin
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
    else
        coins = self.m_serverWinCoins or 0
    end
    if self.postReSpinOverTriggerBigWIn then
        self:postReSpinOverTriggerBigWIn(coins)
    end

    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    -- 自定义事件显示轮盘
    local data = self.m_runSpinResultData.p_rsExtraData
    if data and data.wheel and data.target then
    else
        self:resetMusicBg(true)
    end

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

function CodeGameScreenCrazyBombMachine:showReSpinOver(times, coins, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    ownerlist["m_lb_num"] = util_formatCoins(times, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

function CodeGameScreenCrazyBombMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            if globalData.slotRunData.currSpinMode == RESPIN_MODE then
            else
                gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_enter.mp3")
                scheduler.performWithDelayGlobal(
                    function()
                        if self.m_showWheel then
                        else
                            self:resetMusicBg()
                            self:setMinMusicBGVolume()
                        end
                    end,
                    3,
                    self:getModuleName()
                )
            end
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenCrazyBombMachine:getSpinAction()
    --选择玩法时 置为repsin action  服务器不扣除bet
    if self.m_choiceTriggerRespin == true then
        self.m_choiceTriggerRespin = false
        return RESPIN
    else
        return BaseMachine.getSpinAction(self)
    end
end

-- 断线重连
function CodeGameScreenCrazyBombMachine:MachineRule_initGame(initSpinData)
    -- 自定义事件显示轮盘
    local data = self.m_runSpinResultData.p_rsExtraData

    if data and data.wheel and data.target then
        if data.target == "Feature" or data.target == "FreeGame" or data.target == "Free Game" then
            local WheelEffect = GameEffectData.new()
            WheelEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            WheelEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 2
            WheelEffect.p_selfEffectType = self.m_Wheel

            local pos = #self.m_gameEffects + 1
            for k, v in pairs(self.m_gameEffects) do
                if v.p_effectType == GameEffect.EFFECT_FREE_SPIN then
                    pos = k
                    break
                end
            end
            if pos == #self.m_gameEffects + 1 then
                self.m_gameEffects[pos] = WheelEffect
            else 
                table.insert(self.m_gameEffects, pos, WheelEffect)
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end
    end
end

-- 显示轮盘
function CodeGameScreenCrazyBombMachine:showWheelView(effectData)
    self.m_showWheel = true

    if self.m_WheelTipNode ~= nil then
        local scale = 9
        local endPos = cc.p(-68 * scale, 50 * scale)
        local moveTo = cc.MoveTo:create(1, endPos)
        local scaleTo = cc.ScaleTo:create(1, scale)
        local spawn = cc.Spawn:create(moveTo, scaleTo)

        local data = self.m_runSpinResultData.p_rsExtraData
        local wheel = util_createView("CodeCrazyBombSrc.CrazyBombWheelView", data)
        self:addChild(wheel, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
        wheel:setVisible(false)
        wheel:setScale(0.5)
        wheel:setPosition(display.width * 0.5, display.height * 0.5)
        wheel:findChild("CrazyBomb_wheel_zhizhen_2"):setVisible(false)
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_wheel_fly.mp3")
        local seq =
            cc.Sequence:create(
            spawn,
            cc.CallFunc:create(
                function()
                    self.m_WheelTipNode:setVisible(false)
                    wheel:setVisible(true)
                    wheel:runCsbAction("idle", true)
                end
            ),
            cc.DelayTime:create(0),
            cc.CallFunc:create(
                function()
                    -- local effect, act = util_csbCreate("Socre_CrazyBomb_lunpanguochangdonghua.csb")
                    -- self:addChild(effect, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
                    -- effect:setPosition(display.width * 0.5, display.height * 0.5)
                    -- util_csbPlayForKey(act, "animation0", false, function()
                    --     effect:removeFromParent()
                    -- end)
                    wheel:runAction(
                        cc.Sequence:create(
                            cc.ScaleTo:create(2, 3),
                            cc.CallFunc:create(
                                function()
                                    wheel:removeFromParent()
                                end
                            )
                        )
                    )
                    performWithDelay(
                        self,
                        function()
                            self:createWheelView(
                                function()
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                end
                            )
                            self.m_WheelTipNode:removeFromParent()
                            self.m_WheelTipNode = nil
                        end,
                        1.3
                    )

                    performWithDelay(
                        self,
                        function()
                            self:respinOver()
                            if self.m_runSpinResultData.p_freeSpinsTotalCount == nil or self.m_runSpinResultData.p_freeSpinsTotalCount == 0 then
                                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
                            else
                                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
                                util_setCsbVisible(self.m_winFrame, true)
                                self.m_winFrame:runCsbAction("freespinPays_start")
                            end
                        end,
                        2
                    )
                end
            )
        )
        self.m_WheelTipNode:runAction(seq)
    else
        self:createWheelView(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end
end

function CodeGameScreenCrazyBombMachine:freeSpinWildChange(effectData)
    local delayTime = 0
    for i = 1, #self.m_aFreeSpinWildArry, 1 do
        local temp = self.m_aFreeSpinWildArry[i]
        local iRow = temp.row
        if temp.direction == "up" then
            iRow = temp.row + 1 - 3
        end
        local iTempRow = {} --隐藏小块避免穿帮
        if iRow == -1 then
            iTempRow[1] = 2
            iTempRow[2] = 3
        elseif iRow == 0 then
            iTempRow[1] = 3
        elseif iRow == 2 then
            iTempRow[1] = 1
        elseif iRow == 3 then
            iTempRow[1] = 1
            iTempRow[2] = 2
        end
        local children = self:getReelParent(temp.col):getChildren()
        local node = self:getReelParent(temp.col):getChildByTag(self:getNodeTag(temp.col, iRow, SYMBOL_NODE_TAG))
        node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100)
        node:hideBigSymbolClip()
        node.p_rowIndex = 1
        local distance = (1 - iRow) * self.m_SlotNodeH
        local runTime = math.abs(distance) / 500
        delayTime = math.max(delayTime, runTime)
        local seq =
            cc.Sequence:create(
            cc.MoveBy:create(runTime, cc.p(0, distance)),
            cc.CallFunc:create(
                function()
                    for j = 1, #iTempRow, 1 do
                        self.m_runSpinResultData.p_reels[self.m_iReelRowNum - iTempRow[j] + 1][temp.col] = TAG_SYMBOL_TYPE.SYMBOL_WILD
                        local node = self:getReelParent(temp.col):getChildByTag(self:getNodeTag(temp.col, iTempRow[j], SYMBOL_NODE_TAG))
                        if node ~= nil then
                            node:setVisible(false)
                        end
                    end
                end
            )
        )
        node:runAction(seq)

        for j = 1, #iTempRow, 1 do
            local node = self:getReelParent(temp.col):getChildByTag(self:getNodeTag(temp.col, iTempRow[j], SYMBOL_NODE_TAG))
            if node ~= nil then
                local seq = cc.Sequence:create(cc.MoveBy:create(runTime, cc.p(0, distance)))
                node:runAction(seq)
            end
        end
    end

    gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_bigwild.mp3")
    scheduler.performWithDelayGlobal(
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        delayTime + 0.8,
        self:getModuleName()
    )
end

function CodeGameScreenCrazyBombMachine:reelDownNotifyPlayGameEffect()
    if self:checkHasGameEffectType(GameEffect.EFFECT_SPECIAL_RESPIN) then
        for i = #self.m_gameEffects, 1, -1 do
            if self.m_gameEffects[i].p_effectType == GameEffect.EFFECT_SPECIAL_RESPIN then
                self.m_gameEffects[i].p_effectType = GameEffect.EFFECT_RESPIN
                self.m_gameEffects[i].p_effectOrder = GameEffect.EFFECT_RESPIN
            elseif self.m_gameEffects[i].p_effectType == GameEffect.EFFECT_QUEST_DONE then
                --跳过quest任务完成处理
            else
                table.remove(self.m_gameEffects, i)
            end
        end
    end
    BaseMachine.reelDownNotifyPlayGameEffect(self)
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenCrazyBombMachine:levelFreeSpinEffectChange()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
    if self.m_winFrame:isVisible() == false then
        util_setCsbVisible(self.m_winFrame, true)
        self.m_winFrame:runCsbAction("freespinPays_start")
    end
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenCrazyBombMachine:levelFreeSpinOverChangeEffect(content)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
    self.m_winFrame:runCsbAction("freespinPays_over")
    util_setCsbVisible(self.m_winFrame, false)
end

-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCrazyBombMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.m_freeSpinWildChange then
        -- freeSpin wild 列 变化
        self:freeSpinWildChange(effectData)
    elseif effectData.p_selfEffectType == self.m_Wheel then
        self:showWheelView(effectData)
    end

    return true
end

function CodeGameScreenCrazyBombMachine:addSelfEffect()
    for i = #self.m_aFreeSpinWildArry, 1, -1 do
        table.remove(self.m_aFreeSpinWildArry, i)
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then --and #self.m_allLockNodeReelPos < 6
        for iCol = 1, self.m_iReelColumnNum do --列
            local tempRow = nil
            for iRow = self.m_iReelRowNum, 1, -1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_BIG_WILD then
                    tempRow = iRow
                else
                    break
                end
            end
            if tempRow ~= nil and tempRow ~= 1 then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "down"}
            end

            tempRow = nil
            for iRow = 1, self.m_iReelRowNum, 1 do --行
                if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_BIG_WILD then
                    tempRow = iRow
                else
                    break
                end
            end

            if tempRow ~= nil and tempRow ~= self.m_iReelRowNum then
                self.m_aFreeSpinWildArry[#self.m_aFreeSpinWildArry + 1] = {col = iCol, row = tempRow, direction = "up"}
            end
        end
    end
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and #self.m_aFreeSpinWildArry > 0 then
        local wildChangeEffect = GameEffectData.new()
        wildChangeEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        wildChangeEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        wildChangeEffect.p_selfEffectType = self.m_freeSpinWildChange
        self.m_gameEffects[#self.m_gameEffects + 1] = wildChangeEffect
    end
end

function CodeGameScreenCrazyBombMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.m_bnBaseType then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 120
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

function CodeGameScreenCrazyBombMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self:upateBetLevel()
    self.m_jackPotBar:updateJackpotInfo()
    local data = self.m_runSpinResultData.p_rsExtraData
    local hasFeature = self:checkHasFeature()

    if not hasFeature then
        performWithDelay(
            self,
            function()
                if self.m_betLevel == 0 then
                    self:showChoiceBetView()
                end
            end,
            0.2
        )
    end
end
--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenCrazyBombMachine:upateBetLevel()
    local minBet = self:getMinBet()

    self:updateHighLowBetLock(minBet)
end

function CodeGameScreenCrazyBombMachine:getMinBet()
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

function CodeGameScreenCrazyBombMachine:updateHighLowBetLock(minBet)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_clickBet = true
            self.m_betLevel = 1

            gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_hideBetIcon.mp3")
            self.m_betChoiceIcon:runCsbAction(
                "jiesuo",
                false,
                function()
                    if self.m_clickBet then
                        self.m_betChoiceIcon:setVisible(false)
                    end
                end
            )
        -- self.m_Button_1:setBright(false)
        -- self.m_Button_1:setTouchEnabled(false)
        -- gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_lowHighBetChange.mp3")
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_showBetIcon.mp3")

            self.m_betLevel = 0
            self.m_clickBet = false
            self.m_betChoiceIcon:setVisible(true)
            self.m_betChoiceIcon:runCsbAction(
                "lock",
                false,
                function()
                    if self.m_clickBet == false then
                        self.m_betChoiceIcon:runCsbAction("lockIdle", true)
                    end
                end
            )
        end
    end
end

function CodeGameScreenCrazyBombMachine:unlockHigherBet()
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self:getMinBet() then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end
function CodeGameScreenCrazyBombMachine:showChoiceBetView()
    self.highLowBetView = util_createView("CodeCrazyBombSrc.CrazyBombHighLowBetView", self)
    gLobalViewManager:showUI(self.highLowBetView)
end
function CodeGameScreenCrazyBombMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local num = params
            gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_brick_stop.mp3")

            self.m_BreakTu:setVisible(true)
            self.m_BreakTu:runCsbAction(
                "actionframe2",
                false,
                function()
                    self.m_BreakTu:setVisible(false)
                end
            )

            self:runCsbAction(
                "doudong2",
                false,
                function()
                    -- gLobalSoundManager:resumeBgMusic()
                    self:runCsbAction("animation0", true)
                    scheduler.performWithDelayGlobal(
                        function()
                            self:breakBiggerPigShape(num)
                        end,
                        0.8,
                        self:getModuleName()
                    )
                end
            )
        end,
        "breakBiggerPigShape"
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upateBetLevel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenCrazyBombMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end
function CodeGameScreenCrazyBombMachine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenCrazyBombMachine:requestSpinResult()
    self.m_curRequest = true
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

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
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self:getBetLevel()
    }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end
--------------------------
-- bigWheel 大转盘逻辑
-- 创建轮盘
function CodeGameScreenCrazyBombMachine:createWheelView(func)
    local triggeRespinOver = func

    self.m_wheelBg = util_createView("CodeCrazyBombSrc.CrazyBombWheelBg")
    -- wheelBg:setPosition(cc.p(display.width/2,display.height/2))
    self:findChild("bg_1"):addChild(self.m_wheelBg, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    self.m_wheelBg:runCsbAction("start")

    performWithDelay(
        self,
        function()
            self.m_bottomUI:setVisible(false)
            self.m_topUI:setVisible(false)

            self:resetMusicBg(nil, "CrazyBombSounds/music_CrazyBomb_wheel_bg.mp3")

            local data = self.m_runSpinResultData.p_rsExtraData
            self.m_whell = util_createView("CodeCrazyBombSrc.CrazyBombWheelView", data)
            self.m_whell:startAnimation()
            self.m_wheelBg:findChild("wheel"):addChild(self.m_whell)
            local callback = function()
                self.m_bottomUI:setVisible(true)
                self.m_topUI:setVisible(true)

                self:removeWheelView(
                    function()
                        if triggeRespinOver then
                            triggeRespinOver()
                        end
                        self.m_showWheel = nil
                        self:resetMusicBg()
                    end
                )

                -- 添加自定义事件
                local data = self.m_runSpinResultData.p_rsExtraData
                if data and data.target then
                    if data.target == "Feature" then -- or data.target == "FreeGame"
                        self.m_chooseRepin = true -- 自动spin请求数据,不消耗Bet
                        self.m_chooseRepinGame = true --选择respin
                    elseif data.target == "FreeGame" or data.target == "Free Game" then
                    else
                        if self.m_bProduceSlots_InFreeSpin then
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
                        else
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                            local wheelCoins = self:getJackPotCoins()
                            local coins = wheelCoins
                            local lastWinCoin = globalData.slotRunData.lastWinCoin
                            if wheelCoins > 0 then
                                globalData.slotRunData.lastWinCoin = 0
                            end
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})

                            globalData.slotRunData.lastWinCoin = lastWinCoin
                        end
                    end
                end
            end

            self.m_whell:initCallBack(callback)
            self.m_whell:initWheelBg(self.m_wheelBg, self)

            self.m_wheelJackpot = util_createView("CodeCrazyBombSrc.CrazyBombWheelTopBar")
            self.m_wheelBg:findChild("jackPot"):addChild(self.m_wheelJackpot)
            self.m_wheelJackpot:initMachine(self)
            self.m_wheelJackpot:updateJackpotInfo()
            self.m_wheelJackpot:initMachine(self)
            self.m_wheelJackpot:runCsbAction("start")
        end,
        0.5
    )
    util_setCsbVisible(self.m_wheelBg, true)
end

-- 移除转盘
function CodeGameScreenCrazyBombMachine:removeWheelView(func)
    self.m_wheelJackpot:setVisible(false)
    self.m_whell:setVisible(false)
    gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_wheel_disappear.mp3")
    self.m_wheelBg:runCsbAction(
        "over",
        false,
        function()
            if func then
                func()
            end

            self.m_wheelBg:removeFromParent()
            self.m_wheelBg = nil
            self.m_wheelJackpot = nil
            self.m_whell = nil
        end
    )
end

function CodeGameScreenCrazyBombMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function CodeGameScreenCrazyBombMachine:changeFindTipPos(index)
    local info = self.m_runSpinResultData.p_rsExtraData.shapes
    local posIndex = index

    if info then
        for k, v in pairs(info) do
            if v.icons then
                for j, sPos in pairs(v.icons) do
                    if sPos == posIndex then
                        posIndex = v.icons[#v.icons]
                        return posIndex
                    end
                end
            end
        end
    end

    return posIndex
end

function CodeGameScreenCrazyBombMachine:getTarSpPos(index)
    local symbolPos = self:changeFindTipPos(index)
    local fixPos = self:getRowAndColByPos(symbolPos)
    local targSpPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)

    return targSpPos
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenCrazyBombMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
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

function CodeGameScreenCrazyBombMachine:isShowChooseBetOnEnter()
    return not self:checkHasFeature() and self.m_betLevel == 0
end
function CodeGameScreenCrazyBombMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    BaseSlotoManiaMachine.slotReelDown(self)
    -- self.m_csbOwner["show_tip"]:removeAllChildren()
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCrazyBombMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false
end

function CodeGameScreenCrazyBombMachine:dealSmallReelsSpinStates()
    if self.m_chooseRepinGame then
        self.m_chooseRepinGame = false
    end

    CodeGameScreenCrazyBombMachine.super.dealSmallReelsSpinStates(self)
end

function CodeGameScreenCrazyBombMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        performWithDelay(
            self,
            function()
                self:requestSpinResult()
            end,
            0.5
        )
    else
        self:requestSpinResult()
    end

    self.m_isWaitingNetworkData = true

    self:setGameSpinStage(WAITING_DATA)
    -- 设置stop 按钮处于不可点击状态
    if not self.m_chooseRepinGame then
        if self:getCurrSpinMode() == RESPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false, true})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
        end
    end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function CodeGameScreenCrazyBombMachine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin =
                    scheduler.performWithDelayGlobal(
                    function(delay)
                        self:normalSpinBtnCall()
                    end,
                    0.5,
                    self:getModuleName()
                )
            end
        else
            if not self.m_chooseRepinGame then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
        end
    end
end

function CodeGameScreenCrazyBombMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenCrazyBombMachine.super.levelDeviceVibrate then
        CodeGameScreenCrazyBombMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenCrazyBombMachine
