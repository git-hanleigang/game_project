---
-- xcyy
-- 2018年5月11日
-- CodeGameScreenGoldenPigMachine.lua
--
-- 玩法： 法老金币
--

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseMachine = require "Levels.BaseMachine"
local GoldenBrick = require "CodeGoldenPigSrc.GoldenBrick"
local BaseDialog = util_require("Levels.BaseDialog")
local SendDataManager = require "network.SendDataManager"

local CodeGameScreenGoldenPigMachine = class("CodeGameScreenGoldenPigMachine", BaseSlotoManiaMachine)

CodeGameScreenGoldenPigMachine.m_iRespinTimes = 5
CodeGameScreenGoldenPigMachine.m_lightScore = 0
CodeGameScreenGoldenPigMachine.m_vecRunActionPos = nil
CodeGameScreenGoldenPigMachine.m_vecRunActionPig = nil
CodeGameScreenGoldenPigMachine.m_vecCurrShowShape = nil
CodeGameScreenGoldenPigMachine.m_vecSinglePig = nil
CodeGameScreenGoldenPigMachine.m_vecPigs = nil
CodeGameScreenGoldenPigMachine.m_vecPigInfo = nil

CodeGameScreenGoldenPigMachine.SYMBOL_BIG_WILD = 101
CodeGameScreenGoldenPigMachine.m_bnBaseType = 102

CodeGameScreenGoldenPigMachine.m_isMachineBGPlayLoop = true

CodeGameScreenGoldenPigMachine.m_vecMultipleTotalBet = {1, 3, 5}
CodeGameScreenGoldenPigMachine.m_vecFreeSpinTimes = {0, 0, 10, 15, 25}
CodeGameScreenGoldenPigMachine.m_vecRespinTimes = {0, 0, 5, 7, 10}

CodeGameScreenGoldenPigMachine.m_vecGoldenBrick = nil
CodeGameScreenGoldenPigMachine.m_choiceTriggerRespin = nil

CodeGameScreenGoldenPigMachine.m_aFreeSpinWildArry = nil
CodeGameScreenGoldenPigMachine.m_freeSpinWildChange = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenGoldenPigMachine.COLLECT_PIG = GameEffect.EFFECT_SELF_EFFECT - 2 -- 收集

CodeGameScreenGoldenPigMachine.m_vecHighProPos = nil
CodeGameScreenGoldenPigMachine.m_vecBigWild = nil
CodeGameScreenGoldenPigMachine.m_vecAnimationPig = nil
CodeGameScreenGoldenPigMachine.m_vecRestorePigs = nil
CodeGameScreenGoldenPigMachine.m_vecHidePigs = nil
CodeGameScreenGoldenPigMachine.m_vecChangeShape = nil
CodeGameScreenGoldenPigMachine.m_bIsChangeShape = nil

CodeGameScreenGoldenPigMachine.m_bIsSelectCall = nil
CodeGameScreenGoldenPigMachine.m_iSelectID = nil
CodeGameScreenGoldenPigMachine.m_gameEffect = nil

CodeGameScreenGoldenPigMachine.m_chooseRepin = nil

CodeGameScreenGoldenPigMachine.m_collectEffectData = nil -- 只用作收集是还原gameeffect

local RESPIN_BIG_REWARD_MULTIP = 2000
local RESPIN_BIG_REWARD_SYMBOL_NUM = 15

-- 构造函数
function CodeGameScreenGoldenPigMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_lightScore = 0
    self.m_collectEffectData = nil
    self.m_isBonusTrigger = false
    self.m_isFeatureOverBigWinInFree = true
    
    --init
    self:initGame()
end

function CodeGameScreenGoldenPigMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("GoldenPigConfig.csv", "LevelGoldenPigConfig.lua")

    self:setClipWidthRatio(5)

    --设置音效
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    self.m_scatterBulingSoundArry = {}
    self.m_scatterBulingSoundArry["auto"] = "GoldenPigSounds/sound_GoldenPig_scatter_auto.mp3"
    self.m_bonusBulingSoundArry = {}
    self.m_bonusBulingSoundArry["auto"] = "GoldenPigSounds/sound_GoldenPig_bonus_auto.mp3"

    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 13)
end

function CodeGameScreenGoldenPigMachine:initUI()
    self.m_winFrame = util_createView("CodeGoldenPigSrc.GoldenPigWinFrame")
    local targetNode = self:findChild("top")
    targetNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    targetNode:addChild(self.m_winFrame)

    util_setCsbVisible(self.m_winFrame, false)

    local data = {}
    data.machine = self
    self.m_jackPotBar = util_createView("CodeGoldenPigSrc.GoldenPigTopBar", data)
    self:findChild("m_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    self:initFreeSpinBar()

    -- util_setPositionPercent(self.m_csbNode,0.44)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end
            local index = util_random(1, 4)
            gLobalSoundManager:playSound("GoldenPigSounds/music_Chinese_last_win_" .. index .. ".mp3")
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
    self.m_vecGoldenBrick = {}
    self.m_vecPigInfo = nil
    self.m_aFreeSpinWildArry = {}
    self.m_vecHighProPos = {}
    self.m_vecAnimationPig = {}
    self.m_vecRestorePigs = {}
    self.m_vecHidePigs = {}
    self.m_vecChangeShape = {}
    self.m_bIsChangeShape = false
    self.m_chooseRepin = false
    self.m_specialBets = nil
    self.m_collectList = {} --收集物品列表
    self.m_collectBonusPosition = nil --当前收集关卡
    self.m_isSendStartCollect = false --开始收集玩法
    self.m_collectType = nil --收集玩法类型
    self.m_isShowCollect = true --是否显示收集
    self.m_isInFreeSpin = false
    self.m_initCollectLeftNum = 200
    self.m_initCollectTotalNum = 200

    local gameBg = self.m_gameBg
    local root = gameBg:findChild("root")
    local bg = gameBg:findChild("BG")
    local deviceWidth, deviceHeight = display.width, display.height
    local nodeContentSize = bg:getContentSize()
    local nodeWidth, nodeHeight = nodeContentSize.width, nodeContentSize.height
    local scaleY = deviceHeight / nodeHeight
    root:setScale(scaleY)
end

--ReSpin结算改变UI状态
function CodeGameScreenGoldenPigMachine:changeReSpinOverUI()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinBar()
    end
end

function CodeGameScreenGoldenPigMachine:initJackpotInfo(jackpotPool, lastBetId)
    self.m_jackPotBar:updateJackpotInfo()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGoldenPigMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "GoldenPig"
end

-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenGoldenPigMachine:getNetWorkModuleName()
    return "GoldenPigV2"
end

function CodeGameScreenGoldenPigMachine:getRespinView()
    return "CodeGoldenPigSrc.GoldenPigRespinView"
end

function CodeGameScreenGoldenPigMachine:getRespinNode()
    return "CodeGoldenPigSrc.GoldenPigRespinNode"
end

--统计quest
function CodeGameScreenGoldenPigMachine:MachineRule_afterNetWorkLineLogicCalculate()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGoldenPigMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.m_bnBaseType then
        return "goldpig_bg"
    elseif symbolType == self.SYMBOL_BIG_WILD then
        return "Socre_GoldenPig_Wild_1x3"
    end

    return nil
end

function CodeGameScreenGoldenPigMachine:getReelHeight()
    return 578
end

function CodeGameScreenGoldenPigMachine:getReelWidth()
    return 1120
end

function CodeGameScreenGoldenPigMachine:scaleMainLayer()
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
        local posChange = 20
        local ratio = display.height / display.width
        if ratio >= 768 / 1024 then
            mainScale = 0.85
        elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
            mainScale = 0.95 - 0.05 * ((ratio - 640 / 960) / (768 / 1024 - 640 / 960))
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale

        self.m_machineNode:setPositionY(mainPosY + posChange)
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGoldenPigMachine:getPreLoadSlotNodes()
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
function CodeGameScreenGoldenPigMachine:operaBigSymbolShowMask(childNode)
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
function CodeGameScreenGoldenPigMachine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_winFrame, true)
    self.m_winFrame:setFadeInAction()
    self.m_winFrame:updateLeftCount(respinCount)
    if self.m_runSpinResultData.p_freeSpinsTotalCount == nil or self.m_runSpinResultData.p_freeSpinsTotalCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal_change_respin")
    else
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin_change_respin")
    end
end

--ReSpin刷新数量
function CodeGameScreenGoldenPigMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_winFrame:updateLeftCount(curCount)
end

---respinFeature
function CodeGameScreenGoldenPigMachine:getRespinFeature(...)
    if self.m_reSpinCurCount == self.m_iRespinTimes then
        return {0, 3}
    end
    return {0}
end

function CodeGameScreenGoldenPigMachine:slotOneReelDown(reelCol)
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
            gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_bonus_auto.mp3")
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

function CodeGameScreenGoldenPigMachine:showEffect_FreeSpin(effectData)
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
        gLobalSoundManager:playSound("GoldenPigSounds/music_GoldenPig_trigger_fs.mp3")

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

function CodeGameScreenGoldenPigMachine:showFreatureChooseView(freeSpinNum, respinNum, func)
    local view = util_createView("CodeGoldenPigSrc.GoldenPigFeatureChooseView")
    performWithDelay(
        self,
        function()
            self.m_bottomUI:checkClearWinLabel()
        end,
        0.8
    )
    view:initViewData(freeSpinNum, respinNum, func)
    gLobalViewManager:showUI(view)

    --隐藏收集进度条
    self:isShowCollectProgress(false, true)
end

function CodeGameScreenGoldenPigMachine:showReSpinStart(func)
    self:clearCurMusicBg()

    -- self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func,BaseDialog.AUTO_TYPE_ONLY)
    -- gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_show_choose_layer.mp3")
    scheduler.performWithDelayGlobal(
        function()
            func()
        end,
        1.3,
        self:getModuleName()
    )

    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

function CodeGameScreenGoldenPigMachine:spinResultCallFun(param)
    BaseSlotoManiaMachine.spinResultCallFun(self, param)

    --收集监听消息
    if self.m_isSendStartCollect then
        self.m_isSendStartCollect = false
        self:collectFeatureResultCallFun(param)
    end

    if self.m_bIsSelectCall then
        if self.m_iSelectID == 1 then --  clock feature
            -- self:normalSpinBtnCall()
            self.m_iFreeSpinTimes = 0
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0
            self.m_bProduceSlots_InFreeSpin = false
            self.m_gameEffect.p_isPlay = true
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

            gLobalSoundManager:playSound("LinkCatSounds/music_linkCat_custom_enter_fs_2.mp3")
        end
    end
    self.m_bIsSelectCall = false
end

function CodeGameScreenGoldenPigMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    return false -- 用作延时点击spin调用
end
function CodeGameScreenGoldenPigMachine:slotReelDown()
    CodeGameScreenGoldenPigMachine.super.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end
function CodeGameScreenGoldenPigMachine:playEffectNotifyNextSpinCall()
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

-- function CodeGameScreenGoldenPigMachine:checkRemoveBigMegaEffect()
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

function CodeGameScreenGoldenPigMachine:showEffect_Bonus(effectData)
    self.m_isBonusTrigger = true
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

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusType = selfdata.bonusType
    if bonusType then
        local winAmount = self.m_runSpinResultData.p_winAmount or 0
        if winAmount > 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(winAmount))
        end

        --收集
        self:showBonusView(effectData)
    else
        --选择
        if self.m_runSpinResultData.p_selfMakeData then
            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes_FREESPIN.times
            if self.m_bProduceSlots_InFreeSpin == false then
                self.m_iRespinTimes = self.m_runSpinResultData.p_selfMakeData.triggerTimes_RESPIN.times
            end
        end

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
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenGoldenPigMachine:sendData(index)
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function CodeGameScreenGoldenPigMachine:showFreeSpinView(effectData)
    self.m_isInFreeSpin = true
    -- 界面选择回调
    local function chooseCallBack(index)
        self:sendData(index)
        self.m_bIsSelectCall = true
        self.m_iSelectID = index
        self.m_gameEffect = effectData

        if index == 1 then
            self.m_isInFreeSpin = false
        end
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

function CodeGameScreenGoldenPigMachine:showFreeSpinStart(num, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_ONLY)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenGoldenPigMachine:showFreeSpinOverView()
    self.m_isInFreeSpin = false

    performWithDelay(
        self,
        function()
            gLobalSoundManager:setBackgroundMusicVolume(0.4)
            gLobalSoundManager:playSound(
                "GoldenPigSounds/music_GoldenPig_freespin_over.mp3",
                false,
                function()
                    gLobalSoundManager:setBackgroundMusicVolume(1)
                end
            )

            local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 20)

            local view =
                self:showFreeSpinOver(
                strCoins,
                self.m_runSpinResultData.p_freeSpinsTotalCount,
                function()
                    gLobalSoundManager:playSound("GoldenPigSounds/music_GoldenPig_touch_view_btn.mp3")

                    self:triggerFreeSpinOverCallFun()
                end
            )
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_STATUS,false)
            local node = view:findChild("m_lb_coins")

            view:updateLabelSize({label = node}, 948)

            --显示收集进度条
            self:isShowCollectProgress(true, true)
        end,
        1.6
    )
end

function CodeGameScreenGoldenPigMachine:respinEnd()
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
function CodeGameScreenGoldenPigMachine:reSpinReelDown(addNode)
    --刷新quest计数
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self:updatePigShape()
        self:respinEnd()
        self:playPigsAnimation(
            function()
                BaseMachine.reSpinReelDown(self)
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

function CodeGameScreenGoldenPigMachine:runNextReSpinReel(_isGoldenPigStates)
    self:updatePigShape()
    self:playPigsAnimation(
        function()
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                self:reSpinReelDown()
                return
            end
            BaseMachine.runNextReSpinReel(self)

            if _isGoldenPigStates then
                self:setGameSpinStage(STOP_RUN)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
        end
    )
end

function CodeGameScreenGoldenPigMachine:playPigsAnimation(fuc)
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
        gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_pig_hide_show.mp3")
        for i = 1, #self.m_vecChangeShape, 1 do
            self.m_vecChangeShape[i].node:runAnim(
                "changstart",
                false,
                function()
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
                    symbolNode:runAnim("changstart", false)
                end
            end
            newPos.iX = newPos.iX / self.m_vecRunActionPig[i].area
            newPos.iY = newPos.iY / self.m_vecRunActionPig[i].area

            local newPig = self.m_vecAnimationPig[i]
            self.m_respinView:addChild(newPig, REEL_SYMBOL_ORDER.REEL_ORDER_2 + maxCol)
            newPig:setPosition(newPos.iX, newPos.iY)
            newPig:release()
            newPig:runAnim(
                "changover",
                false,
                function()
                    performWithDelay(
                        self,
                        function()
                            gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_buling.mp3")
                        end,
                        0.2
                    )

                    newPig:runAnim(
                        "buling",
                        false,
                        function()
                            newPig:runAnim("idleframe", true)
                            if i == #self.m_vecRunActionPig then
                                fuc()
                            end
                        end
                    )
                end
            )
        end

        for i = 1, #self.m_vecRestorePigs, 1 do
            local pos = self.m_vecRestorePigs[i]
            local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
            --self:getReelParent(pos.iX):getChildByTag(self:getNodeTag(pos.iX,  pos.iY, SYMBOL_NODE_TAG))
            symbolNode:runAnim(
                "changover",
                false,
                function()
                    symbolNode:runAnim("idleframe", true)
                end
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

function CodeGameScreenGoldenPigMachine:updatePigShape()
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
            local csbName = "GoldenPig_BonusBG_" .. self.m_vecRunActionPig[i].shape
            local data = {}
            data.csbName = csbName
            data.vecGoldenBrick = self.m_vecGoldenBrick
            data.cloumnIndex = self.m_vecRunActionPig[i].pos[1].iX
            data.rowIndex = self.m_vecRunActionPig[i].pos[1].iY
            data.width = self.m_vecRunActionPig[i].width
            for j = 2, #self.m_vecRunActionPig[i].pos do
                data.rowIndex = math.max(data.rowIndex, self.m_vecRunActionPig[i].pos[j].iY)
                data.cloumnIndex = math.min(data.cloumnIndex, self.m_vecRunActionPig[i].pos[j].iX)
            end
            local newPig = util_createView("CodeGoldenPigSrc.GoldenPigPigShape", data)
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

function CodeGameScreenGoldenPigMachine:getPigsShapesInfo(info, changePos)
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

function CodeGameScreenGoldenPigMachine:initPigsShapesInfo(vecPigsShape)
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

-- RespinView
function CodeGameScreenGoldenPigMachine:showRespinView(effectData)
    local delayTime = 1.5
    --说明是通过freespin来的 不收集 所以不延迟了
    if not self.m_isShowCollect then
        delayTime = 0
    end

    --触发respin 必然会触发收集(触发物是同一种)
    --想要收集完 消失收集条 进入respin玩法 所以加个等待
    performWithDelay(
        self,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

            --先播放动画 再进入respin
            self:clearCurMusicBg()
            gLobalSoundManager:playSound("GoldenPigSounds/music_GoldenPig_goin_lightning.mp3")
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

            --说明不是通过freespin来的 没被隐藏了
            if self.m_isShowCollect then
                --隐藏收集进度条
                self:isShowCollectProgress(false, true)
            end
        end,
        delayTime
    )
end

-- --结束移除小块调用结算特效
function CodeGameScreenGoldenPigMachine:reSpinEndAction()
    scheduler.performWithDelayGlobal(
        function()
            self.m_winFrame:updateLeftCount(0)

            self:playTriggerLight()
        end,
        1,
        self:getModuleName()
    )
end

function CodeGameScreenGoldenPigMachine:playTriggerLight()
    self:breakLittlePigShape()

    self.m_winFrame:setFadeOutAction()
end

function CodeGameScreenGoldenPigMachine:breakLittlePigShape()
    local function breakPig(posX, posY, width, height, area, cloumnIndex, rowIndex, shape)
        local data = {}
        data.width = width
        data.height = height
        data.num = self:BaseMania_getLineBet() * self.m_lineCount * self.m_vecMultipleTotalBet[area]
        data.shape = shape
        local golden = GoldenBrick:create()
        golden:initUI(data)
        self.m_respinView:addChild(golden, REEL_SYMBOL_ORDER.REEL_ORDER_2)
        golden:setPosition(posX, posY)
        local brick = {}
        -- golden:retain()
        brick.width = 1
        brick.node = golden
        brick.cloumnIndex = cloumnIndex
        brick.rowIndex = rowIndex
        self.m_vecGoldenBrick[#self.m_vecGoldenBrick + 1] = brick
        self.m_lightScore = self.m_lightScore + data.num
        -- self.m_iOnceSpinLastWin = self.m_lightScore
    end

    local delayTime = 0
    for i = 1, #self.m_vecSinglePig, 1 do
        local symbolNode = self.m_respinView:getRespinEndNode(self.m_vecSinglePig[i].iX, self.m_vecSinglePig[i].iY)
        delayTime = (i - 1) * 2.5 + 0.8
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_pig_break.mp3")

                symbolNode:runAnimFrame(
                    "over",
                    false,
                    "show",
                    function()
                        breakPig(symbolNode:getPositionX(), symbolNode:getPositionY(), 168, 144, 1, self.m_vecSinglePig[i].iX, self.m_vecSinglePig[i].iY, "1x1")
                    end,
                    function()
                        symbolNode:setVisible(false)
                    end
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
        delayTime = tempDelayTime + i * 2.5
        if tempDelayTime == 0 then
            delayTime = (i - 1) * 2.5 + 0.8
        end
        local node = littleShape[i].node
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_pig_break.mp3")
                node:runAnimFrame(
                    "over",
                    false,
                    "show",
                    function()
                        local cloumnIndex = littleShape[i].pos[1].iX
                        local rowIndex = littleShape[i].pos[1].iY
                        for j = 2, #littleShape[i].pos, 1 do
                            rowIndex = math.max(rowIndex, littleShape[i].pos[j].iY)
                            cloumnIndex = math.min(cloumnIndex, littleShape[i].pos[j].iX)
                        end

                        breakPig(node:getPositionX(), node:getPositionY(), node.m_rect.width, node.m_rect.height, littleShape[i].area, cloumnIndex, rowIndex, node.shape)
                    end,
                    function()
                        node:setVisible(false)
                    end
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

function CodeGameScreenGoldenPigMachine:breakBiggerPigShape(params)
    if params then
        local winCoin = params * self:BaseMania_getLineBet() * self.m_lineCount
        local index = 0
        if params == 20 then
            index = 4
        elseif params == 100 then
            index = 3
        elseif params == 1000 then
            index = 2
        elseif params == 2000 then
            index = 1
        end
        if index ~= 0 then
            winCoin = self:BaseMania_getJackpotScore(index)
        end
        self.m_lightScore = self.m_lightScore + winCoin
        if index ~= 0 then
            self:showRespinJackpot(
                index,
                winCoin,
                function()
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
        scheduler.performWithDelayGlobal(
            function()
                self:respinOverResetBrick()
                self:respinOver()
                self.m_vecCurrShowShape = {}
                self.m_vecRunActionPig = {}
                self.m_vecRunActionPos = {}
                self.m_vecGoldenBrick = {}
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
end

function CodeGameScreenGoldenPigMachine:respinOverResetBrick()
    for i = 1, #self.m_vecGoldenBrick, 1 do
        local data = self.m_vecGoldenBrick[i]
        local posX, posY = data.node:getPosition()
        local worldPos = data.node:getParent():convertToWorldSpace(cc.p(posX, posY))
        local nodePos = self:getReelParent(data.cloumnIndex):convertToNodeSpace(worldPos)
        data.node:retain()
        data.node:removeFromParent()
        if data.node.m_data ~= nil then
            local golden = GoldenBrick:create()
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
end

function CodeGameScreenGoldenPigMachine:showRespinJackpot(index, coins, func)
    gLobalSoundManager:setBackgroundMusicVolume(0.4)
    gLobalSoundManager:playSound(
        "GoldenPigSounds/music_GoldenPig_freespin_over.mp3",
        false,
        function()
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end
    )
    local jackPotWinView = util_createView("CodeGoldenPigSrc.GoldenPigJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self, index, coins, func)
end

function CodeGameScreenGoldenPigMachine:showRespinOverView(effectData)
    local seq =
        cc.Sequence:create(
        cc.DelayTime:create(0.5),
        cc.CallFunc:create(
            function()
                util_setCsbVisible(self.m_winFrame, false)

                self.m_jackPotBar:setVisible(true)

                if self.m_runSpinResultData.p_freeSpinsTotalCount == nil or self.m_runSpinResultData.p_freeSpinsTotalCount == 0 then
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "respin_change_normal")
                else
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "respin_change_freespin")
                    util_setCsbVisible(self.m_winFrame, true)
                    self.m_winFrame:runCsbAction("freespinPays_start")
                end

                if not self.m_isInFreeSpin then
                    --显示收集进度条

                    self:isShowCollectProgress(true, true)
                end
            end
        )
    )

    self:runAction(seq)
    local strCoins = util_formatCoins(self.m_serverWinCoins, 20)
    gLobalSoundManager:setBackgroundMusicVolume(0.4)
    gLobalSoundManager:playSound(
        "GoldenPigSounds/music_GoldenPig_freespin_over.mp3",
        false,
        function()
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end
    )

    local view =
        self:showReSpinOver(
        strCoins,
        function()
            -- util_setCsbVisible(self.m_fireworks,true)
            -- self.m_fireworks:showFireEffect()

            if self.m_iBetLevel == 1 then
                self.m_jackPotBar:findChild("jiesuoclick"):setVisible(true)
                self.m_jackPotBar:findChild("click"):setVisible(false)
            else
                self.m_jackPotBar:findChild("jiesuoclick"):setVisible(false)
                self.m_jackPotBar:findChild("click"):setVisible(true)
            end

            gLobalSoundManager:playSound("GoldenPigSounds/music_GoldenPig_touch_view_btn.mp3")
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg()
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node}, 948)

    for i = 1, self.m_iReelColumnNum, 1 do
        local parent = self:getReelParent(i)
        local children = parent:getChildren()
        for j = 1, #children, 1 do
            local child = children[j]
            if child.p_symbolType ~= nil and child.p_symbolType == self.SYMBOL_BIG_WILD then
                child:setVisible(false)
            end
        end
    end
end

function CodeGameScreenGoldenPigMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("GoldenPigSounds/music_GoldenPig_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    self:resetMusicBg()
                    self:setMinMusicBGVolume()
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenGoldenPigMachine:getSpinAction()
    --选择玩法时 置为repsin action  服务器不扣除bet
    if self.m_choiceTriggerRespin == true then
        self.m_choiceTriggerRespin = false
        return RESPIN
    else
        return BaseMachine.getSpinAction(self)
    end
end

--进关数据初始化
function CodeGameScreenGoldenPigMachine:initGameStatusData(gameData)
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)

    --只有第一次获取服务器数据
    if not self.m_collectBonusPosition then
        if gameData.gameConfig and gameData.gameConfig.extra then
            self.m_collectBonusPosition = gameData.gameConfig.extra.bonusPosition or 0
        else
            self.m_collectBonusPosition = 0
        end
    end

    if gameData.collect then
        self.m_initCollectLeftNum = gameData.collect[1].collectLeftCount
        self.m_initCollectTotalNum = gameData.collect[1].collectTotalCount
    end
end

-- 断线重连
function CodeGameScreenGoldenPigMachine:MachineRule_initGame(initSpinData)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_isInFreeSpin = true
    end

    if initSpinData.p_freeSpinsLeftCount == 0 and initSpinData.p_reSpinCurCount == 0 then
        if self.m_jackPotBar.m_tip then
            self.m_jackPotBar.m_tip:setVisible(true)
        end
    else
        if self.m_jackPotBar.m_tip then
            self.m_jackPotBar.m_tip:setVisible(false)
        end
    end

    if initSpinData.p_reSpinCurCount > 0 then
        self.m_jackPotBar:playLock()
        self.m_jackPotBar.m_isLock = true
    else
        self.m_jackPotBar:playIdle()
        self.m_jackPotBar.m_isLock = false
    end
end

function CodeGameScreenGoldenPigMachine:freeSpinWildChange(effectData)
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
    end

    gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_bigwild.mp3")
    scheduler.performWithDelayGlobal(
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        delayTime + 0.8,
        self:getModuleName()
    )
end

function CodeGameScreenGoldenPigMachine:reelDownNotifyPlayGameEffect()
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
function CodeGameScreenGoldenPigMachine:levelFreeSpinEffectChange()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
    util_setCsbVisible(self.m_winFrame, true)
    self.m_winFrame:runCsbAction("freespinPays_start")
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenGoldenPigMachine:levelFreeSpinOverChangeEffect(content)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin_change_normal")
    self.m_winFrame:runCsbAction("freespinPays_over")
end

-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGoldenPigMachine:MachineRule_playSelfEffect(effectData)
    -- freeSpin wild 列 变化
    if effectData.p_selfEffectType == self.m_freeSpinWildChange then
        self:freeSpinWildChange(effectData)
    elseif effectData.p_selfEffectType == self.COLLECT_PIG then
        self:collectPig(effectData)
    end

    return true
end

function CodeGameScreenGoldenPigMachine:addSelfEffect()
    --重置收集数据
    self.m_collectList = {}

    --只在 高bet && 普通玩法触发收集
    if self:isCanCollect() and self.m_isShowCollect and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE and globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    if node.p_symbolType == self.m_bnBaseType then
                        table.insert(self.m_collectList, node)
                    end
                end
            end
        end
    end
    if  self:isCanCollect() and #self.m_collectList > 0 then
        local collectEffect = GameEffectData.new()
        collectEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        collectEffect.p_effectOrder = self.COLLECT_PIG
        self.m_gameEffects[#self.m_gameEffects + 1] = collectEffect
        collectEffect.p_selfEffectType = self.COLLECT_PIG
    end

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
        wildChangeEffect.p_effectOrder = self.m_freeSpinWildChange
        wildChangeEffect.p_selfEffectType = self.m_freeSpinWildChange
        self.m_gameEffects[#self.m_gameEffects + 1] = wildChangeEffect
    end
end

function CodeGameScreenGoldenPigMachine:getBounsScatterDataZorder(symbolType)
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

function CodeGameScreenGoldenPigMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self.m_jackPotBar:updateJackpotInfo()

    --更新当前高低bet
    self:updateBet()

    --初始化收集进度
    self:initCollectProgress()
end

function CodeGameScreenGoldenPigMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local num = params
            gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_brick_stop.mp3")
            self:runCsbAction(
                "doudong",
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
            self:updateBet()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenGoldenPigMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

--收集动画
function CodeGameScreenGoldenPigMachine:collectPig(effectData)
    local tmpCollectList = self.m_collectList
    self.m_collectList = {}

    --判断是否完成当前小关收集进度
    --未到达小关 收集不影响spin按钮 可正常点击
    --达到小关进度 spin按钮不可点击 执行完再可点击
    local isNeedPlayGameEffect = false

    if self.m_runSpinResultData.p_collectNetData[1] then
        local curLeftNum = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        isNeedPlayGameEffect = curLeftNum == 0
    end

    if not isNeedPlayGameEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    if #tmpCollectList > 0 then
        gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_collect_collect_pig.mp3")

        local endPos = self.m_jackPotBar:getCollectStartPos()

        for i = 1, #tmpCollectList do
            local node = tmpCollectList[i]
            local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))

            --particle
            local flyParticleNode = cc.Node:create()
            local particle = cc.ParticleSystemQuad:create("effect/GoldenPig_TWlizi1.plist")
            particle:setPositionType(0)
            particle:setPosition(0, 0)
            particle:setScale(1.3)
            flyParticleNode:addChild(particle)
            flyParticleNode:setPosition(startPos)
            self:addChild(flyParticleNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)

            local actParDelay = cc.DelayTime:create(0.3)
            local actParBez = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
            local actParCallFun =
                cc.CallFunc:create(
                function()
                    particle:stopSystem()
                    flyParticleNode:removeFromParent()
                end
            )

            flyParticleNode:runAction(cc.Sequence:create(actParDelay, actParBez, actParCallFun))

            --pig
            local pig, act = util_csbCreate("GoldenPig_Pigshouji.csb")

            self:addChild(pig, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
            pig:setPosition(startPos)

            util_csbPlayForIndex(
                act,
                0,
                15,
                false,
                function()
                    local actDelay = cc.DelayTime:create(0.3)
                    local actBez = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
                    local actCallFun =
                        cc.CallFunc:create(
                        function()
                            util_csbPlayForIndex(
                                act,
                                15,
                                18,
                                false,
                                function()
                                    if i == #tmpCollectList then
                                        effectData.p_isPlay = true
                                        self:updateCollectProgress(isNeedPlayGameEffect)
                                    end

                                    pig:removeFromParent()
                                end
                            )
                        end
                    )

                    pig:runAction(cc.Sequence:create(actDelay, actBez, actCallFun))
                end
            )
        end
    else
        effectData.p_isPlay = true
        self:updateCollectProgress(isNeedPlayGameEffect)
    end
end

--跳转至开启收集最低bet
function CodeGameScreenGoldenPigMachine:updateBetToCanCollect()
    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE
     then
        return
    end

    if self.m_specialBets then
        local machineCurBetList = globalData.slotRunData.machineData:getMachineCurBetList()
        local lowBet = self.m_specialBets[1].p_totalBetValue

        for i = 1, #machineCurBetList do
            local betData = machineCurBetList[i]
            if betData.p_totalBetValue >= lowBet then
                globalData.slotRunData.iLastBetIdx = betData.p_betId
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
                break
            end
        end
    end
end

--高低bet
function CodeGameScreenGoldenPigMachine:updateBet()
    --只有第一次获取服务器数据
    if not self.m_specialBets then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local betCoin = self:BaseMania_getLineBet() * self.m_lineCount --globalData.slotRunData:getCurTotalBet()
    local beforeBetLevel = self.m_iBetLevel

    if betCoin == nil then
        self.m_iBetLevel = 0
    else
        if self.m_specialBets then
            self.m_iBetLevel = betCoin >= self.m_specialBets[1].p_totalBetValue and 1 or 0
        else
            self.m_iBetLevel = 0
        end
    end

    if beforeBetLevel ~= self.m_iBetLevel then
        self:setCollectProgressIsLock(self.m_iBetLevel == 0)
    end
end

--是否可以收集
function CodeGameScreenGoldenPigMachine:isCanCollect()
    return self.m_iBetLevel == 1
end

--收集是否锁定
function CodeGameScreenGoldenPigMachine:setCollectProgressIsLock(isLock)
    self.m_jackPotBar:showIsLock(isLock)
end

--初始化收集进度
function CodeGameScreenGoldenPigMachine:initCollectProgress()
    --self.m_collectBonusPosition 服务器返的从0开始 要+1
    self:updateCollectProgressPer(self.m_collectBonusPosition + 1, self.m_initCollectLeftNum, self.m_initCollectTotalNum, false, nil)

    if self:getCurrSpinMode() == RESPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        --隐藏收集进度条
        self:isShowCollectProgress(false, false)
    end
end

--更新收集进度(根据selfdata)
function CodeGameScreenGoldenPigMachine:updateCollectProgress(isNeedPlayGameEffect)
    if self.m_runSpinResultData.p_collectNetData[1] then
        local curLeftNum = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local curTotalNum = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount

        local callfunc = nil

        if isNeedPlayGameEffect then
            callfunc = function()
                self:playGameEffect()
            end
        end

        --self.m_collectBonusPosition 服务器返的从0开始 要+1
        self:updateCollectProgressPer(self.m_collectBonusPosition + 1, curLeftNum, curTotalNum, true, callfunc)
    end
end

--更新收集进度
function CodeGameScreenGoldenPigMachine:updateCollectProgressPer(curCollectIndex, curLeftNum, curTotalNum, isAnim, callBackFun)
    self.m_jackPotBar:setCollectProgressData(curCollectIndex, curLeftNum, curTotalNum, isAnim, callBackFun)
end

--重置收集进度
function CodeGameScreenGoldenPigMachine:resetCollectProgressPer()
    self.m_jackPotBar:resetCollectProgress()
end

--[[
    *******************
    收集玩法集满相关    
--]]
--添加收集小进度奖励界面
function CodeGameScreenGoldenPigMachine:addCollectStepView()
    local data = {}
    data.coins = self.m_runSpinResultData.p_winAmount
    data.callBackFun = function()
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_winAmount, true, true})
        globalData.slotRunData.lastWinCoin = lastWinCoin

        if self.m_collectEffectData then
            self.m_collectEffectData.p_isPlay = true
            self:playGameEffect()
            self.m_collectEffectData = nil
        end

        self:resetMusicBg()
    end

    local collectStepView = util_createView("CodeGoldenPigSrc.GoldenPigCollectStepView", data)
    gLobalViewManager:showUI(collectStepView)
end

--添加收集玩法界面
function CodeGameScreenGoldenPigMachine:addCollectGameLayer()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata then
        local data = {}
        --startPrice
        data.startPrice = selfdata.avgBet
        --奖励列表
        data.cellTable = selfdata.cellTable
        --预设玩家获得下标
        data.hitPositions = selfdata.hitPositions

        local collectGameLayer = util_createView("CodeGoldenPigSrc.GoldenPigCollectGame", data)
        collectGameLayer:initMachine(self)
        self:addChild(collectGameLayer, GAME_LAYER_ORDER.LAYER_ORDER_TOUCH_LAYER)
    end
end

--添加收集结束奖励界面
function CodeGameScreenGoldenPigMachine:addCollectOverView(callBackFun)
    if self.m_runSpinResultData.p_selfMakeData then
        local data = {}
        --startPrice
        data.startPrice = self.m_runSpinResultData.p_selfMakeData.avgBet
        --multip
        data.multip = 0
        --totalCoins
        data.coins = self.m_runSpinResultData.p_winAmount
        --回调
        data.callBackFun = function()
            self:resetCollectProgressPer()

            if callBackFun then
                callBackFun()
            end

            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_winAmount, true, true})
            globalData.slotRunData.lastWinCoin = lastWinCoin

            -- 通知bonus 结束， 以及赢钱多少
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS})

            if self.m_collectEffectData then
                self.m_collectEffectData.p_isPlay = true
                self:playGameEffect()
                self.m_collectEffectData = nil
            end

            self:resetMusicBg()
        end

        --奖励列表
        local cellTable = self.m_runSpinResultData.p_selfMakeData.cellTable
        --预设玩家获得下标
        local hitPositions = self.m_runSpinResultData.p_selfMakeData.hitPositions

        for i = 1, #hitPositions do
            local curRowDataList = cellTable[i]
            --hitPositions 从0开始
            local curRowIndex = hitPositions[i] + 1
            local curRowResult = curRowDataList[curRowIndex]

            if curRowResult.type == "allwin" then
                for j = 1, #curRowDataList do
                    local result = curRowDataList[j]
                    if result.type == "multi" then
                        data.multip = data.multip + result.value
                    end
                end
            elseif curRowResult.type == "multi" then
                data.multip = data.multip + curRowResult.value
            end
        end

        local collectOverView = util_createView("CodeGoldenPigSrc.GoldenPigCollectOverView", data)
        gLobalViewManager:showUI(collectOverView)
    end
end

function CodeGameScreenGoldenPigMachine:sendStartCollect(collectType)
    self.m_isSendStartCollect = true
    self.m_collectType = collectType
    local messageData = {}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function CodeGameScreenGoldenPigMachine:receiveStartCollect()
    if self.m_runSpinResultData.p_selfMakeData then
        --更新收集小进度
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.bonusPosition then
            self.m_collectBonusPosition = self.m_runSpinResultData.p_selfMakeData.bonusPosition
        end

        if self.m_collectType == "simple" then
            self:addCollectStepView()
        elseif self.m_collectType == "feature" then
            self:addCollectGameLayer()
        end
    else
        if self.m_collectEffectData then
            self.m_collectEffectData.p_isPlay = true
            self:playGameEffect()
            self.m_collectEffectData = nil
        end
    end
end

-- 只用作收集玩法发消息
function CodeGameScreenGoldenPigMachine:collectFeatureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        local serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果

        globalData.userRate:pushCoins(serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            -- 更新控制类数据
            self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)

            self:receiveStartCollect()
        end
    else
        -- 处理消息请求错误情况
        --TODO 佳宝 给与弹板玩家提示。。
        gLobalViewManager:showReConnect(true)
    end
end

function CodeGameScreenGoldenPigMachine:showBonusView(effectData)
    self.m_collectEffectData = effectData
    local collectType = self.m_runSpinResultData.p_selfMakeData.bonusType
    self:sendStartCollect(collectType)
end

--根据当前玩法状态设置收集进度条显隐及奖池位置
function CodeGameScreenGoldenPigMachine:isShowCollectProgress(isShow, isAnim)
    self.m_isShowCollect = isShow
    self.m_jackPotBar:isShowCollectProgress(isShow, isAnim)
end


function CodeGameScreenGoldenPigMachine:dealSmallReelsSpinStates( )

    if self.m_chooseRepinGame then
        self.m_chooseRepinGame = false
    end

    CodeGameScreenGoldenPigMachine.super.dealSmallReelsSpinStates(self )

end

function CodeGameScreenGoldenPigMachine:requestSpinReusltData()
    local time = xcyy.SlotsUtil:getMilliSeconds()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        performWithDelay(self,function()
            self:requestSpinResult()
        end,0.5)
    else
        self:requestSpinResult() 
    end

    self.m_isWaitingNetworkData = true
    
    self:setGameSpinStage( WAITING_DATA )
    -- 设置stop 按钮处于不可点击状态
    if not self.m_chooseRepinGame  then
        if self:getCurrSpinMode() == RESPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Spin,false,true})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Stop,false,true})
        end
    end
    

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function CodeGameScreenGoldenPigMachine:playEffectNotifyChangeSpinStatus( )
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                                        {SpinBtn_Type.BtnType_Auto,true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
            {SpinBtn_Type.BtnType_Auto,true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
                    self:normalSpinBtnCall()
                end, 0.5,self:getModuleName())
            end
        else
            if not self.m_chooseRepinGame  then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,true})
            end
            
        end
    end
end

function CodeGameScreenGoldenPigMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenGoldenPigMachine.super.levelDeviceVibrate then
        CodeGameScreenGoldenPigMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenGoldenPigMachine
