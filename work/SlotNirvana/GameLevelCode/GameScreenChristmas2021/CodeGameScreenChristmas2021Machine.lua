---
-- xcyy
-- 2018年5月11日
-- CodeGameScreenChristmas2021Machine.lua

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseMachine = require "Levels.BaseMachine"
local Christmas2021Brick = require "Christmas2021Src.Christmas2021Brick"
local BaseDialog = util_require("Levels.BaseDialog")
local SendDataManager = require "network.SendDataManager"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenChristmas2021Machine = class("CodeGameScreenChristmas2021Machine", BaseSlotoManiaMachine)

CodeGameScreenChristmas2021Machine.m_iRespinTimes = 5
CodeGameScreenChristmas2021Machine.m_lightScore = 0
CodeGameScreenChristmas2021Machine.m_vecRunActionPos = nil
CodeGameScreenChristmas2021Machine.m_vecRunActionPig = nil
CodeGameScreenChristmas2021Machine.m_vecCurrShowShape = nil
CodeGameScreenChristmas2021Machine.m_vecSinglePig = nil
CodeGameScreenChristmas2021Machine.m_vecPigs = nil
CodeGameScreenChristmas2021Machine.m_vecPigInfo = nil

CodeGameScreenChristmas2021Machine.SYMBOL_RS_SCORE_BLANK = 100 --空小块
CodeGameScreenChristmas2021Machine.SYMBOL_BONUS_LINK = 102

CodeGameScreenChristmas2021Machine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

CodeGameScreenChristmas2021Machine.m_isMachineBGPlayLoop = true

CodeGameScreenChristmas2021Machine.m_vecMultipleTotalBet = {1, 3, 5}

CodeGameScreenChristmas2021Machine.m_vecCrazyBombBrick = nil
CodeGameScreenChristmas2021Machine.m_choiceTriggerRespin = nil

CodeGameScreenChristmas2021Machine.m_vecHighProPos = nil
CodeGameScreenChristmas2021Machine.m_vecBigWild = nil
CodeGameScreenChristmas2021Machine.m_vecAnimationPig = nil
CodeGameScreenChristmas2021Machine.m_vecRestorePigs = nil
CodeGameScreenChristmas2021Machine.m_vecHidePigs = nil
CodeGameScreenChristmas2021Machine.m_vecChangeShape = nil
CodeGameScreenChristmas2021Machine.m_bIsChangeShape = nil

CodeGameScreenChristmas2021Machine.m_bIsSelectCall = nil
CodeGameScreenChristmas2021Machine.m_iSelectID = nil
CodeGameScreenChristmas2021Machine.m_gameEffect = nil

CodeGameScreenChristmas2021Machine.m_chooseRepin = nil
CodeGameScreenChristmas2021Machine.m_clickBet = nil
CodeGameScreenChristmas2021Machine.m_isQuitStop = false -- free下快停
CodeGameScreenChristmas2021Machine.m_bonusNumTri = 6 -- 触发bonus玩法的数量
CodeGameScreenChristmas2021Machine.m_changeWildList = {} -- free玩法变wild 快停的时候 如果已经有变成的wild 保存下
CodeGameScreenChristmas2021Machine.m_playFlySound = {1, 2, 3, 4, 5} --扔雪球音效ID

local CHOOSE_INDEX = {
    CHOOSE_FREESPIN = 1,
    CHOOSE_RESPIN = 0
}

local L_ABS = math.abs

-- 构造函数
function CodeGameScreenChristmas2021Machine:ctor()
    CodeGameScreenChristmas2021Machine.super.ctor(self)
    self.m_lightScore = 0
    self.m_spinRestMusicBG = true
    --快滚音效
    self.m_reelRunSound = "Christmas2021Sounds/sound_Christmas2021_QuickHit_reel.mp3"

    self.m_isBonusTrigger = false

    --init
    self:initGame()
end

function CodeGameScreenChristmas2021Machine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("Christmas2021Config.csv", "LevelChristmas2021Config.lua")

    self:setClipWidthRatio(5)

    --设置音效
    --初始化基本数据
    self:initMachine(self.m_moduleName)

    --设置轮盘样式 根据关卡盘面(与CSV表中设置对应) 后接参数(进入函数可以看到)可以设置bonus scatter等特殊元素是否参与长滚
    --self:slotsReelRunData( {15, 21, 27, 33, 39} )

    self.m_scatterBulingSoundArry = {}
    for i = 1, self.m_iReelColumnNum do
        local soundPath = "Christmas2021Sounds/sound_Christmas2021_scatter_down.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenChristmas2021Machine:initUI()
    self.m_gameBg:runCsbAction("bace", true)

    -- 过场
    self.m_GuoChangBg = util_createAnimation("Christmas2021_free_guochang.csb")
    self:findChild("guochang"):addChild(self.m_GuoChangBg)
    self.m_GuoChangBg:setVisible(false)

    self.m_guochang = util_spineCreate("Christmas2021_free_guochang", true, true)
    self.m_guochang:setVisible(false)
    self.m_GuoChangBg:findChild("Node_spine"):addChild(self.m_guochang)

    -- jackpot
    self.m_jackPotBar = util_createView("Christmas2021Src.Christmas2021JackpotBar")
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    -- 男女角色
    self.m_boyNode = util_spineCreate("Socre_Christmas2021_nanhai", true, true)
    self.m_boyNode:setVisible(false)
    self:findChild("Node_boy"):addChild(self.m_boyNode)

    self.m_girlNode = util_spineCreate("Socre_Christmas2021_nvhai", true, true)
    self.m_girlNode:setVisible(false)
    self:findChild("Node_girl"):addChild(self.m_girlNode)

    -- free次数条 respin次数条
    self:initFreeSpinBar()

    -- 棋盘遮罩
    self.m_qipanDark = util_createAnimation("Christmas2021_reel_dark_free.csb")
    self:findChild("dark_Node"):addChild(self.m_qipanDark)
    self.m_qipanDark:setVisible(false)

    self.m_qipanDark1 = util_createAnimation("Christmas2021_reel_dark.csb")
    self.m_clipParent:addChild(self.m_qipanDark1, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10)
    self.m_qipanDark1:runCsbAction("idle", false)
    self.m_qipanDark1:setVisible(false)

    -- 挂载雪花
    self.m_xueHua_node = cc.Node:create()
    self.m_clipParent:addChild(self.m_xueHua_node, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 9)

    --主要挂载free下遮罩上wild的节点
    self.m_wild_node = cc.Node:create()
    self.m_wild_node:setPosition(display.width * 0.5, display.height * 0.5)
    self:findChild("wildNode"):addChild(self.m_wild_node)

    --主要会挂载一些动效相关的节点 雪球
    self.m_role_node = cc.Node:create()
    self.m_role_node:setPosition(display.width * 0.5, display.height * 0.5)
    self:findChild("root_ui"):addChild(self.m_role_node, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)

    -- 棋盘粒子先隐藏
    self:findChild("lizi"):setVisible(false)
    self:findChild("lizi2"):setVisible(false)
    self:findChild("lizi3"):setVisible(false)
    for i = 1, 12 do
        self:findChild("Particle_" .. i):stopSystem()
    end

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
                local soundName = nil
                if self.m_bProduceSlots_InFreeSpin then
                    soundName = "Christmas2021Sounds/sound_Christmas2021_last_win_free_" .. index .. ".mp3"
                else
                    soundName = "Christmas2021Sounds/sound_Christmas2021_last_win_" .. index .. ".mp3"
                end
                self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
            end
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    self.m_choiceTriggerRespin = false
    self.m_vecRunActionPos = {}
    self.m_vecRunActionPig = {}
    self.m_vecCurrShowShape = {}
    self.m_vecSinglePig = {}
    self.m_vecPigs = {}
    self.m_vecCrazyBombBrick = {}
    self.m_vecPigInfo = nil
    self.m_vecHighProPos = {}
    self.m_vecAnimationPig = {}
    self.m_vecRestorePigs = {}
    self.m_vecHidePigs = {}
    self.m_vecChangeShape = {}
    self.m_bIsChangeShape = false
    self.m_chooseRepin = false
end

--ReSpin结算改变UI状态
function CodeGameScreenChristmas2021Machine:changeReSpinOverUI()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinBar()
    end
end

-- jackpot
function CodeGameScreenChristmas2021Machine:initJackpotInfo(jackpotPool, lastTotalBet)
    self.m_jackPotBar:updateJackpotInfo()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenChristmas2021Machine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Christmas2021"
end

function CodeGameScreenChristmas2021Machine:getRespinView()
    return "Christmas2021Src.Christmas2021RespinView"
end

function CodeGameScreenChristmas2021Machine:getRespinNode()
    return "Christmas2021Src.Christmas2021RespinNode"
end

--小块
function CodeGameScreenChristmas2021Machine:getBaseReelGridNode()
    return "Christmas2021Src.Christmas2021SlotsNode"
end

--统计quest
function CodeGameScreenChristmas2021Machine:MachineRule_afterNetWorkLineLogicCalculate()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenChristmas2021Machine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_Christmas2021_bonus"
    elseif symbolType == self.SYMBOL_BONUS_LINK then
        return "Socre_Christmas2021_bonus_1x1"
    elseif symbolType == self.SYMBOL_RS_SCORE_BLANK then
        return "Socre_Christmas2021_xuehua"
    end
    return nil
end

function CodeGameScreenChristmas2021Machine:getReelWidth()
    if display.width < 1370 then
        return 1430
    else
        return 1200
    end
end

function CodeGameScreenChristmas2021Machine:initMachineBg()
    local gameBg = util_createView("Christmas2021Src.Christmas2021GameMachineBG")
    local bgNode = self:findChild("bg")
    if not bgNode then
        bgNode = self:findChild("gameBg")
        if not bgNode then
            bgNode = self:findChild("gamebg")
        end
    end
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end

-- 适配
function CodeGameScreenChristmas2021Machine:scaleMainLayer()
    CodeGameScreenChristmas2021Machine.super.scaleMainLayer(self)
    local ratio = display.height / display.width
    local root_ui_scale = 1
    if ratio >= 768 / 1024 then
        local mainScale = 0.74
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 15)
    elseif ratio < 640 / 960 and ratio >= 768 / 1228 then
        local mainScale = 0.87 - 0.06 * ((ratio - 768 / 1228) / (640 / 960 - 768 / 1228))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end
end

-- 次数条
function CodeGameScreenChristmas2021Machine:initFreeSpinBar()
    -- FreeSpinbar
    self.m_FreespinBarView = util_createView("Christmas2021Src.Christmas2021FreespinBarView")
    self:findChild("Node_freeandrespincishu"):addChild(self.m_FreespinBarView)
    self.m_FreespinBarView:setVisible(false)

    -- respinber
    self.m_RespinBarView = util_createView("Christmas2021Src.Christmas2021RespinBerView")
    self:findChild("Node_freeandrespincishu"):addChild(self.m_RespinBarView)
    self.m_RespinBarView:setVisible(false)
end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenChristmas2021Machine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenChristmas2021Machine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BONUS, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BONUS_LINK, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_RS_SCORE_BLANK, count = 2}

    return loadNode
end

----------------------------- 玩法处理 ----------------------------------

--ReSpin开始改变UI状态
function CodeGameScreenChristmas2021Machine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_RespinBarView, true)
    self.m_RespinBarView:updateLeftCount(respinCount)

    self.m_gameBg:runCsbAction(
        "bace_respin",
        false,
        function()
            self.m_gameBg:runCsbAction("respin", true)
        end
    )
end

--ReSpin刷新数量
function CodeGameScreenChristmas2021Machine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_RespinBarView:updateLeftCount(curCount)
end

-- 过场
function CodeGameScreenChristmas2021Machine:playChangeGuoChang(func1, func2)
    self.m_GuoChangBg:setVisible(true)
    self.m_guochang:setVisible(true)

    self.m_GuoChangBg:findChild("Particle_1"):resetSystem()
    self.m_GuoChangBg:findChild("Particle_2"):resetSystem()
    self.m_GuoChangBg:findChild("Particle_4"):resetSystem()

    gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_guochang.mp3")
    self.m_GuoChangBg:runCsbAction("actionframe", false)

    util_spinePlay(self.m_guochang, "actionframe", false)
    util_spineEndCallFunc(
        self.m_guochang,
        "actionframe",
        function()
            self.m_guochang:setVisible(false)
            self.m_GuoChangBg:setVisible(false)
            if func2 then
                func2()
            end
        end
    )

    self:waitWithDelay(
        nil,
        function()
            if func1 then
                func1()
            end
        end,
        270 / 60
    )
end
---------------------------------------------------------------------------

-- 二选一界面
function CodeGameScreenChristmas2021Machine:showFreatureChooseView(freeSpinNum, respinNum, func)
    local view = util_createView("Christmas2021Src.Christmas2021FeatureChooseView")

    self:waitWithDelay(
        nil,
        function()
            self.m_bottomUI:checkClearWinLabel()
        end,
        0.8
    )
    view:initViewData(
        self,
        freeSpinNum,
        respinNum,
        func,
        function()
            self:levelFreeSpinEffectChange()
        end
    )
    -- self:addChild(view, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
    gLobalViewManager:showUI(view)
end

--spin结果
function CodeGameScreenChristmas2021Machine:spinResultCallFun(param)
    CodeGameScreenChristmas2021Machine.super.spinResultCallFun(self, param)
    if self.m_bIsSelectCall then
        if self.m_iSelectID == CHOOSE_INDEX.CHOOSE_RESPIN then --  clock feature
            -- self:normalSpinBtnCall()
            self.m_currentMusicBgName = self:getReSpinMusicBg()
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)

            self.m_iFreeSpinTimes = 0
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0
            self.m_bProduceSlots_InFreeSpin = false
            if self.m_gameEffect then
                self.m_gameEffect.p_isPlay = true
            end

            self.m_choiceTriggerRespin = true
            self.m_chooseRepin = true
            self:playGameEffect()
        else
            self.m_isBonusTrigger = false
            globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
            globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes
            self.m_iOnceSpinLastWin = 0
            self:triggerFreeSpinCallFun()
            self.m_FreespinBarView:setVisible(true)
            self.m_gameEffect.p_isPlay = true
            self:playGameEffect()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end
    end
    self.m_bIsSelectCall = false
end

function CodeGameScreenChristmas2021Machine:playEffectNotifyNextSpinCall()
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

function CodeGameScreenChristmas2021Machine:showEffect_Bonus(effectData)
    self.m_isBonusTrigger = true
    if self.m_runSpinResultData.p_selfMakeData then
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_selfMakeData.freespinTimes
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_iRespinTimes = self.m_runSpinResultData.p_selfMakeData.respinTimes
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
        performWithDelay(
            self,
            function()
                self:showBonusAndScatterLineTip(
                    scatterLineValue,
                    function()
                        self:showFreeSpinView(effectData)
                    end
                )
                scatterLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
                -- 播放提示时播放音效
                self:playScatterTipMusicEffect()
            end,
            0.2
        )
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
    return true
end

-- 点击二选一界面 发送消息
function CodeGameScreenChristmas2021Machine:sendData(index)
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

function CodeGameScreenChristmas2021Machine:showFreeSpinView(effectData)
    if effectData.p_effectType == GameEffect.EFFECT_FREE_SPIN then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:triggerFreeSpinCallFun()
        self.m_FreespinBarView:setVisible(true)
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
                end,
                0.8,
                self:getModuleName()
            )
        end
    end
end

-- freespin玩法 结束界面
function CodeGameScreenChristmas2021Machine:showFreeSpinOverView()
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_freespin_win.mp3")

            local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 20)

            local view =
                self:showFreeSpinOver(
                strCoins,
                self.m_runSpinResultData.p_freeSpinsTotalCount,
                function()
                    self.m_FreespinBarView:setVisible(false)
                    self:triggerFreeSpinOverCallFun()
                end
            )

            local node = view:findChild("m_lb_coins")

            view:updateLabelSize({label = node, sx = 0.55, sy = 0.55}, 828)
        end,
        1.6
    )
end

-- respin 结束
function CodeGameScreenChristmas2021Machine:respinEnd()
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

function CodeGameScreenChristmas2021Machine:reSpinReelDown(addNode)
    --刷新quest计数
    self:updateQuestUI()
    -- 合图提前达到最大 服务器直接把p_reSpinCurCount次数 给成0 结束
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self:updatePigShape()
        self:respinEnd()
        self:playPigsAnimation(
            function()
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

function CodeGameScreenChristmas2021Machine:runNextReSpinReel(_isCrazyBombStates)
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

-- respin滚动停止 进行合图
function CodeGameScreenChristmas2021Machine:playPigsAnimation(fuc)
    local vecShapes = self.m_runSpinResultData.p_rsExtraData.shapes

    if #vecShapes == 0 then
        self:waitWithDelay(
            nil,
            function()
                fuc()
            end,
            0.5
        )
        return
    end

    if self.m_bIsChangeShape then
        for i = 1, #self.m_vecChangeShape, 1 do
            self.m_vecChangeShape[i].node:runAnim(
                "over",
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
            if self.m_vecChangeShape[i].node:getChildByName("bg") then
                self.m_vecChangeShape[i].node:getChildByName("bg"):runCsbAction(
                    "over",
                    false,
                    function()
                        self.m_vecChangeShape[i].node:getChildByName("bg"):removeFromParent()
                    end
                )
            end
        end

        for i = 1, #self.m_vecRunActionPig, 1 do
            local newPos = {iX = 0, iY = 0}
            local maxCol = 0
            -- 合图之前的位置 小块坐标
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
                        "over",
                        false,
                        function()
                        end
                    )
                    if symbolNode:getChildByName("bg") then
                        symbolNode:getChildByName("bg"):runCsbAction(
                            "over",
                            false,
                            function()
                                symbolNode:getChildByName("bg"):removeFromParent()
                            end
                        )
                    end
                    --清除在respinView上面放着的 底板
                    if self.m_respinView:getChildByName("bg" .. (symbolNode.p_cloumnIndex + 5 * (symbolNode.p_rowIndex - 1))) then
                        self.m_respinView:getChildByName("bg" .. (symbolNode.p_cloumnIndex + 5 * (symbolNode.p_rowIndex - 1))):runCsbAction(
                            "over",
                            false,
                            function()
                                self.m_respinView:getChildByName("bg" .. (symbolNode.p_cloumnIndex + 5 * (symbolNode.p_rowIndex - 1))):removeFromParent()
                            end
                        )
                    end
                end
            end
            newPos.iX = newPos.iX / self.m_vecRunActionPig[i].area
            newPos.iY = newPos.iY / self.m_vecRunActionPig[i].area

            local newPig = self.m_vecAnimationPig[i]
            newPig:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + maxCol)
            -- self.m_respinView:addChild(newPig,REEL_SYMBOL_ORDER.REEL_ORDER_2 + maxCol)
            newPig:setPosition(newPos.iX, newPos.iY)
            local indexNum = i
            newPig:setVisible(false)
            if newPig:getChildByName("bg") then
                newPig:getChildByName("bg"):setVisible(false)
            end
            local sound_name = "Christmas2021Sounds/sound_Christmas2021_to_big.mp3"

            if indexNum == #self.m_vecRunActionPig then
                self:waitWithDelay(
                    nil,
                    function()
                        gLobalSoundManager:playSound(sound_name)
                    end,
                    0.2
                )
            end

            self:waitWithDelay(
                nil,
                function()
                    newPig:setVisible(true)
                    if newPig:getChildByName("bg") then
                        newPig:getChildByName("bg"):setVisible(true)
                        newPig:getChildByName("bg"):runCsbAction("start", false)
                    end

                    newPig:runAnim(
                        "show",
                        false,
                        function()
                            newPig:runAnim("idleframe", true)
                            if indexNum == #self.m_vecRunActionPig then
                                fuc()
                            end
                        end
                    )
                end,
                0.4
            )
        end

        -- 处理的是 本来是大图 合图之后产生的小图
        for i = 1, #self.m_vecRestorePigs, 1 do
            local pos = self.m_vecRestorePigs[i]
            local symbolNode = self.m_respinView:getRespinEndNode(pos.iX, pos.iY)
             --self:getReelParent(pos.iX):getChildByTag(self:getNodeTag(pos.iX,  pos.iY, SYMBOL_NODE_TAG))
            symbolNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self:getPosByColRow(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex))
            self:waitWithDelay(
                nil,
                function()
                    self.m_respinView:createRespinNodeBg(symbolNode, cc.p(symbolNode:getPositionX(), symbolNode:getPositionY()), 2)
                    self.m_respinView:getChildByName("bg" .. (symbolNode.p_cloumnIndex + 5 * (symbolNode.p_rowIndex - 1))):runCsbAction("start", false)
                    symbolNode:runAnim(
                        "show",
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
            self:waitWithDelay(
                nil,
                function()
                    fuc()
                end,
                0.5
            )
        end
    else
        self:waitWithDelay(
            nil,
            function()
                fuc()
            end,
            0.5
        )
    end
end

-- 根据行列得到自定义的 pos位置
function CodeGameScreenChristmas2021Machine:getPosByColRow(col, row)
    if row == 1 then
        row = 3
    elseif row == 3 then
        row = 1
    end
    return (row - 1) * self.m_iReelRowNum + col
end

-- 拿到数据之后 处理需要合图的数据
function CodeGameScreenChristmas2021Machine:updatePigShape()
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
        pig.shape = vecShapes[i].height .. "x" .. vecShapes[i].width
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

    -- 有变化的大图信息
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
        if self.m_vecPigInfo.priority ~= pigsShapesInfo.priority then
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
            -- local csbName = self.m_vecRunActionPig[i].shape
            local data = {}
            data.shape = self.m_vecRunActionPig[i].shape
            data.vecCrazyBombBrick = self.m_vecCrazyBombBrick
            data.cloumnIndex = self.m_vecRunActionPig[i].pos[1].iX
            data.rowIndex = self.m_vecRunActionPig[i].pos[1].iY
            data.width = self.m_vecRunActionPig[i].width
            for j = 2, #self.m_vecRunActionPig[i].pos do
                data.rowIndex = math.max(data.rowIndex, self.m_vecRunActionPig[i].pos[j].iY)
                data.cloumnIndex = math.min(data.cloumnIndex, self.m_vecRunActionPig[i].pos[j].iX)
            end
            data.m_machine = self
            local newPig = util_createView("Christmas2021Src.Christmas2021PigShape", data)
            self.m_respinView:addChild(newPig)
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

function CodeGameScreenChristmas2021Machine:getPigsShapesInfo(info, changePos)
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

function CodeGameScreenChristmas2021Machine:initPigsShapesInfo(vecPigsShape)
    local pigsShapesInfo = {}
    local strNum = ""
    for i = 1, 5, 1 do
        local num
        if i <= #vecPigsShape then
            strNum = strNum .. vecPigsShape[i].area..vecPigsShape[i].position
        else
            strNum = strNum .. "0"
        end
    end
    pigsShapesInfo.priority = tonumber(strNum)
    pigsShapesInfo.info = vecPigsShape
    return pigsShapesInfo
end

-- bonus落地动画 提层
function CodeGameScreenChristmas2021Machine:playCustomSpecialSymbolDownAct(slotNode)
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        if slotNode.p_symbolType == self.SYMBOL_BONUS then
            if self:getIsPlayBonusBuling(slotNode) then
                local symbolNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_BONUS, 0)

                -- self:playScatterBonusSound(slotNode)
                symbolNode:runAnim("buling")
            end
        end
    end
end

-- 策划要求 bonus没有触发可能性时 不播放buling
function CodeGameScreenChristmas2021Machine:getIsPlayBonusBuling(slotNode)
    local bonusNumSiCol = 0 -- 前四列bonus数量
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == self.SYMBOL_BONUS then
                if iCol < self.m_iReelColumnNum then
                    bonusNumSiCol = bonusNumSiCol + 1
                end
            end
        end
    end
    -- 前四列必定播放
    if slotNode.p_cloumnIndex <= (self.m_iReelColumnNum - 1) then
        return true
    else
        if bonusNumSiCol < (self.m_bonusNumTri - self.m_iReelRowNum) then
            return false
        else
            return true
        end
    end
end

-- RespinView
function CodeGameScreenChristmas2021Machine:showRespinView(effectData)
    -- 把落地已经 提层的先还原
    self:checkChangeBaseParent()

    --播放触发动画
    local curBonusList = {}
    local curList = {} -- 除了bonus的其他图标
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS or node.p_symbolType == self.SYMBOL_BONUS_LINK then
                    local bonusOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
                    local symbolNode = util_setSymbolToClipReel(self, iCol, iRow, node.p_symbolType, 0)
                    curBonusList[#curBonusList + 1] = node
                else
                    curList[#curList + 1] = node
                end

                local newKong = util_createAnimation("Socre_Christmas2021_xuehua.csb")
                local startPosWord = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                local startPos = self.m_xueHua_node:convertToNodeSpace(startPosWord)
                newKong:setPosition(startPos)
                self.m_xueHua_node:addChild(newKong)
                self.m_xueHua_node:setVisible(false)
            end
        end
    end

    -- 其他图标 渐隐消失
    for i, _node in ipairs(curList) do
        -- 渐隐效果
        util_nodeFadeIn(_node, 0.3, 255, 0, nil, nil)
    end
    self:waitWithDelay(
        nil,
        function()
            self.m_xueHua_node:setVisible(true)
        end,
        0.3
    )

    self:showColorLayer()

    -- 播放提示时播放音效
    self:playBonusTipMusicEffect()

    -- bonus玩法 触发动画
    for i, _bonusNode in ipairs(curBonusList) do
        _bonusNode:runAnim(
            "actionframe",
            false,
            function()
                _bonusNode:runAnim("idleframe", true)
            end
        )
    end

    --可随机的普通信息
    local randomTypes = {
        self.SYMBOL_BONUS_LINK,
        self.SYMBOL_RS_SCORE_BLANK
    }

    --可随机的特殊信号
    local endTypes = {
        {type = self.SYMBOL_BONUS_LINK, runEndAnimaName = "", bRandom = true}
        -- {type = self.SYMBOL_RS_SCORE_BLANK, runEndAnimaName = "", bRandom = true},
    }

    performWithDelay(
        self,
        function()
            self:showReSpinStartView(
                function()
                    self:checkChangeBaseParent()
                    --构造盘面数据

                    self:triggerReSpinCallFun(endTypes, randomTypes)

                    -- performWithDelay(self,function (  )
                    self.m_xueHua_node:removeAllChildren()

                    for i, _node in ipairs(curList) do
                        -- 渐隐效果
                        util_nodeFadeIn(_node, 0.1, 0, 255, nil, nil)
                    end
                    -- end,2)
                end
            )
        end,
        2
    )
end

function CodeGameScreenChristmas2021Machine:showReSpinStartView(func)
    -- 二选一触发的respin 不显示开始弹板
    if self.m_runSpinResultData.p_rsExtraData.kind and self.m_runSpinResultData.p_rsExtraData.kind == "SELECT" then
        self:hideColorLayer(
            function()
                self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)

                if func then
                    func()
                end
            end
        )

        return
    end

    self:clearCurMusicBg()
    gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_respinStart.mp3")

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self.m_bottomUI:checkClearWinLabel()

    self:showDialog(
        BaseDialog.DIALOG_TYPE_RESPIN_START,
        nil,
        function()
            self:playChangeGuoChang(
                function()
                    self:hideColorLayer(
                        function()
                            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)

                            if func then
                                func()
                            end
                        end
                    )
                end
            )
        end
    )
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

--触发respin
function CodeGameScreenChristmas2021Machine:triggerReSpinCallFun(endTypes, randomTypes)
    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()
    self:checkChangeBaseParent()

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

-- base进入到respin 94要变成102
function CodeGameScreenChristmas2021Machine:triggerChangeRespinNodeInfo(respinNodeInfo)
    if respinNodeInfo and #respinNodeInfo > 0 then
        for i, v in ipairs(respinNodeInfo) do
            if v.Type == self.SYMBOL_BONUS or v.Type == self.SYMBOL_BONUS_LINK then
                v.Type = self.SYMBOL_BONUS_LINK
            else
                v.Type = self.SYMBOL_RS_SCORE_BLANK
            end
        end
    end
end

-- --结束移除小块调用结算特效
function CodeGameScreenChristmas2021Machine:reSpinEndAction()
    scheduler.performWithDelayGlobal(
        function()
            self.m_RespinBarView:updateLeftCount(0)

            -- gLobalSoundManager:fadeOutBgMusic()
            -- self:waitWithDelay( nil, function()
            --     gLobalSoundManager:stopFadeBgMusic()
            --     self:clearCurMusicBg()
            -- end, 1)
            self:playTriggerLight()
        end,
        1,
        self:getModuleName()
    )
end

function CodeGameScreenChristmas2021Machine:playTriggerLight()
    self:breakLittlePigShape()

    self.m_touchSpinLayer:setVisible(false)
end

function CodeGameScreenChristmas2021Machine:breakLittlePigShape()
    local function breakPig(posX, posY, width, height, area, cloumnIndex, rowIndex, shape)
        local data = {}
        data.width = width
        data.height = height
        data.num = self:BaseMania_getLineBet() * self.m_lineCount * self.m_vecMultipleTotalBet[area]
        data.shape = shape

        -- 把这几个信号置空
        for symbolType = 120, 124 do
            if self.m_reelAnimNodePool[symbolType] and #self.m_reelAnimNodePool[symbolType] > 0 then
                for i, _node in ipairs(self.m_reelAnimNodePool[symbolType]) do
                    if not tolua.isnull(_node) then
                        _node:clear()
                        _node:removeAllChildren()
                        _node:release()
                    end
                end
            end
            self.m_reelAnimNodePool[symbolType] = nil
        end

        local golden = Christmas2021Brick:create()
        golden:initUI(data)

        self.m_respinView:addChild(golden, REEL_SYMBOL_ORDER.REEL_ORDER_2)
        golden:setPosition(posX, posY)
        golden:runAnim(
            "actionframe",
            false,
            function()
                golden:runAnim("idleframe", true)
            end
        )
        local brick = {}
        brick.width = 1
        brick.node = golden
        brick.cloumnIndex = cloumnIndex
        brick.rowIndex = rowIndex
        brick.data = data
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
                gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_brick_change_gold.mp3")

                symbolNode:runAnim("actionframe1", false)
                local spinenode = symbolNode:checkLoadCCbNode()
                spinenode.m_spineNode:registerSpineEventHandler(
                    function(event) --通过registerSpineEventHandler这个方法注册
                        if event.animation == "actionframe1" then --根据动作名来区分
                            if event.eventData.name == "show" then --根据帧事件来区分
                                -- symbolNode:setVisible(false)
                                if symbolNode:getChildByName("bg") then
                                    symbolNode:getChildByName("bg"):removeFromParent()
                                end
                                if self.m_respinView:getChildByName("bg" .. (symbolNode.p_cloumnIndex + 5 * (symbolNode.p_rowIndex - 1))) then
                                    self.m_respinView:getChildByName("bg" .. (symbolNode.p_cloumnIndex + 5 * (symbolNode.p_rowIndex - 1))):removeFromParent()
                                end

                                breakPig(symbolNode:getPositionX(), symbolNode:getPositionY(), 220, 160, 1, self.m_vecSinglePig[i].iX, self.m_vecSinglePig[i].iY, "1x1")
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
        delayTime = tempDelayTime + 0.8 + (i - 1) * 1.5
        if tempDelayTime == 0 then
            delayTime = (i - 1) * 1.5 + 0.8
        end
        local node = littleShape[i].node
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_brick_change_gold.mp3")

                node:runAnim("actionframe1", false)

                node.m_spineNode:registerSpineEventHandler(
                    function(event) --通过registerSpineEventHandler这个方法注册
                        if event.animation == "actionframe1" then --根据动作名来区分
                            if event.eventData.name == "show" then --根据帧事件来区分
                                local cloumnIndex = littleShape[i].pos[1].iX
                                local rowIndex = littleShape[i].pos[1].iY
                                for j = 2, #littleShape[i].pos, 1 do
                                    rowIndex = math.max(rowIndex, littleShape[i].pos[j].iY)
                                    cloumnIndex = math.min(cloumnIndex, littleShape[i].pos[j].iX)
                                end
                                -- node:setVisible(false)
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
        delayTime + 1.5,
        self:getModuleName()
    )
end

function CodeGameScreenChristmas2021Machine:breakBiggerPigShape(params)
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
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
        if index ~= 0 then
            gLobalSoundManager:setBackgroundMusicVolume(0.4)
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

function CodeGameScreenChristmas2021Machine:respinGameOver()
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

function CodeGameScreenChristmas2021Machine:respinOverResetBrick()
    for i = 1, #self.m_vecCrazyBombBrick, 1 do
        local data = self.m_vecCrazyBombBrick[i]
        local posX, posY = data.node:getPosition()
        local worldPos = data.node:getParent():convertToWorldSpace(cc.p(posX, posY))
        local nodePos = self:getReelBigParent(data.cloumnIndex):convertToNodeSpace(worldPos)

        -- 把这几个信号置空
        for symbolType = 120, 124 do
            if self.m_reelAnimNodePool[symbolType] and #self.m_reelAnimNodePool[symbolType] > 0 then
                for i, _node in ipairs(self.m_reelAnimNodePool[symbolType]) do
                    if not tolua.isnull(_node) then
                        _node:clear()
                        _node:removeAllChildren()
                        _node:release()
                    end
                end
            end
            self.m_reelAnimNodePool[symbolType] = nil
        end

        local golden = self:getSlotNodeBySymbolType(100)
        data.node:removeFromParent()
        data.node = nil

        local goldenNew = Christmas2021Brick:create()
        if data.data.isMulti then
            data.data.num = data.data.num * globalData.slotRunData:getCurTotalBet()
        end
        goldenNew:initUI(data.data)

        goldenNew:runAnim("idleframe", true)
        -- 将糖果放在空小块上面
        golden:addChild(goldenNew, 100)
        golden.m_tangGuoNode = goldenNew
        golden.p_slotNodeH = data.data.height

        self:getReelParent(data.cloumnIndex):addChild(golden, REEL_SYMBOL_ORDER.REEL_ORDER_4 * data.width)
        golden:setPosition(nodePos)
        self:resetCloumnZorder(data.cloumnIndex)
    end

    self.m_vecCrazyBombBrick = {}
end

--- 自己写的判断结算
-- 与ReSpinReelDown 实现方式一样
function CodeGameScreenChristmas2021Machine:selfMakeReSpinReelDown()
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

--中奖jackpot
function CodeGameScreenChristmas2021Machine:showRespinJackpot(index, coins, func)
    local jackPotWinView = util_createView("Christmas2021Src.Christmas2021JackPotWinView", self)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index, coins, func)
end

function CodeGameScreenChristmas2021Machine:showEffect_RespinOver(effectData)
    local wheelCoins = self:getJackPotCoins()
    local rsAddCoins = self.m_serverWinCoins - wheelCoins
    self:checkFeatureOverTriggerBigWin(rsAddCoins, GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    self:removeRespinNode()
    --self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function CodeGameScreenChristmas2021Machine:showRespinOverView(effectData)
    gLobalSoundManager:fadeOutBgMusic()
    self:waitWithDelay(
        nil,
        function()
            gLobalSoundManager:stopFadeBgMusic()
            self:clearCurMusicBg()
        end,
        1
    )

    util_setCsbVisible(self.m_RespinBarView, false)

    local wheelCoins = self.m_serverWinCoins - self:getJackPotCoins()

    local strCoins = util_formatCoins(wheelCoins, 20)
    gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_respin_win.mp3")
    local times = self.m_runSpinResultData.p_reSpinsTotalCount
    local view =
        self:showReSpinOver(
        times,
        strCoins,
        function()
            performWithDelay(
                self,
                function()
                    self:triggerReSpinOverCallFun(self.m_lightScore)
                    self.m_lightScore = 0
                    self:resetMusicBg()
                end,
                0.5
            )
        end
    )

    local node = view:findChild("m_lb_coins")
    self:updateLabelSize({label = node, sx = 0.55, sy = 0.55}, 828)

    self.m_touchSpinLayer:setVisible(true)

    self:respinOver()
    for iCol = 1, self.m_iReelColumnNum do
        local reelParent = self:getReelParent(iCol)
        util_setCascadeOpacityEnabledRescursion(reelParent, true)
        reelParent:setOpacity(0)
    end
    if self.m_runSpinResultData.p_freeSpinsTotalCount == nil or self.m_runSpinResultData.p_freeSpinsTotalCount == 0 then
        self.m_gameBg:runCsbAction("bace", true)
    else
        self.m_gameBg:runCsbAction("free", true)
    end

    self:changeReSpinOverUI()

    for iCol = 1, self.m_iReelColumnNum do
        local reelParent = self:getReelParent(iCol)
        util_playFadeInAction(reelParent, 0.2, nil)
    end
end

function CodeGameScreenChristmas2021Machine:cleanRespinGray()
    for iCol = 1, self.m_iReelColumnNum do --列
        local children = self:getReelParent(iCol):getChildren()
        for i = 1, #children, 1 do
            local child = children[i]
            if child.p_rowIndex and child.p_rowIndex < 4 then
                local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(self:getSymbolCCBNameByType(self, math.random(4, 8)))
                if imageName ~= nil then
                    child:spriteChangeImage(child.p_symbolImage, imageName[1])
                end
            end
        end
    end
end

function CodeGameScreenChristmas2021Machine:getJackPotCoins()
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

function CodeGameScreenChristmas2021Machine:respinOver()
    self:respinOverResetBrick()
    self:setReelSlotsNodeVisible(true)

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    self:removeRespinNode()
    self:cleanRespinGray()
end

function CodeGameScreenChristmas2021Machine:triggerReSpinOverCallFun(score)
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
    -- self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

function CodeGameScreenChristmas2021Machine:showReSpinOver(times, coins, func)
    self:checkChangeBaseParent()
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    ownerlist["m_lb_num"] = util_formatCoins(times, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

-- 进入关卡音效
function CodeGameScreenChristmas2021Machine:enterGamePlayMusic()
    self:playEnterGameSound("Christmas2021Sounds/music_Christmas2021_enter.mp3")
end

-- 断线重连
function CodeGameScreenChristmas2021Machine:MachineRule_initGame(initSpinData)
    local data = self.m_runSpinResultData.p_rsExtraData
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_FreespinBarView:setVisible(true)
    end
    if self.m_runSpinResultData.p_features[2] and self.m_runSpinResultData.p_features[2] == 3 then
        if self.m_runSpinResultData.p_reSpinsTotalCount == 0 and self.m_runSpinResultData.p_reSpinCurCount == 0 then
            self.m_chooseRepin = true
            self:playEffectNotifyNextSpinCall()
        end
    end
end

--free玩法 扔雪球
function CodeGameScreenChristmas2021Machine:freeSpinWildChange(_fun)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData.addWild and #fsExtraData.addWild > 0 then
        if self.m_isQuitStop then
            return
        end

        local addWild = {}
        addWild[1] = {}
        addWild[2] = {}
        -- 把数据分成左右 两部分
        for i, pos in ipairs(fsExtraData.addWild) do
            local fixPos = self:getRowAndColByPos(pos)
            if fixPos.iY > 3 then --四五列男孩扔
                table.insert(addWild[1], pos)
            elseif fixPos.iY < 3 then --一二列女孩扔
                table.insert(addWild[2], pos)
            end
        end

        for i, pos in ipairs(fsExtraData.addWild) do
            local fixPos = self:getRowAndColByPos(pos)
            if fixPos.iY == 3 then -- 第三列男女分
                if #addWild[1] - #addWild[2] >= 0 then
                    table.insert(addWild[2], pos)
                else
                    table.insert(addWild[1], pos)
                end
            end
        end

        local funCallBack = function(rolePos, wildPos, isLast, isFrist)
            local funDelayCallBack = function(nodeName)
                local startPosWord = self:findChild(nodeName):getParent():convertToWorldSpace(cc.p(self:findChild(nodeName):getPosition()))
                local startPos = self.m_role_node:convertToNodeSpace(startPosWord)

                local fixPos = self:getRowAndColByPos(wildPos)
                local endPosWord = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
                local endPos = self.m_role_node:convertToNodeSpace(endPosWord)
                local xueQiu = util_createAnimation("Christmas2021_addwild_trail.csb")
                self.m_role_node:addChild(xueQiu)
                xueQiu:setPosition(startPos)

                for i = 1, 4 do
                    xueQiu:findChild("Particle_" .. i):setDuration(500) --设置拖尾时间(生命周期)
                    xueQiu:findChild("Particle_" .. i):setPositionType(0)
                    xueQiu:findChild("Particle_" .. i):resetSystem()
                end

                local actionList = {}
                actionList[#actionList + 1] = cc.BezierTo:create(12 / 30, {cc.p(startPos.x, startPos.y + 150), cc.p(endPos.x, startPos.y + 300), endPos})
                actionList[#actionList + 1] =
                    cc.CallFunc:create(
                    function()
                        xueQiu:findChild("Christmas2021_xueqiu"):setVisible(false)
                        -- scheduler.performWithDelayGlobal(function()
                        --     xueQiu:removeFromParent()
                        -- end, 0.5, self.m_role_node)
                        self:waitWithDelay(
                            self.m_role_node,
                            function()
                                xueQiu:removeFromParent()
                            end,
                            0.5
                        )

                        local newWild = util_spineCreate("Socre_Christmas2021_Wild", true, true)
                        newWild:setPosition(endPos)
                        self.m_wild_node:addChild(newWild)
                        gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_change_wild.mp3")

                        util_spinePlay(newWild, "actionframe1", false)
                        table.insert(self.m_changeWildList, wildPos)
                    end
                )
                xueQiu:runAction(cc.Sequence:create(actionList))
            end

            local roleNode = self.m_girlNode
            local nodeName = "Node_2"
            if rolePos == 1 then --左右两个角色 1代表左边的 2代表右边的
                roleNode = self.m_boyNode
                nodeName = "Node_1"
            end
            if isFrist then
                util_spinePlay(roleNode, "actionframe", false)
                if isLast then
                    util_spineEndCallFunc(
                        roleNode,
                        "actionframe",
                        function()
                            util_spinePlay(roleNode, "tao", false)
                            util_spineEndCallFunc(
                                roleNode,
                                "tao",
                                function()
                                    util_spinePlay(roleNode, "idle", true)
                                end
                            )
                        end
                    )
                end
                self:waitWithDelay(
                    self.m_role_node,
                    function()
                        funDelayCallBack(nodeName)
                    end,
                    16 / 30
                )
            else
                util_spinePlay(roleNode, "tao", false)
                util_spineEndCallFunc(
                    roleNode,
                    "tao",
                    function()
                        util_spinePlay(roleNode, "actionframe", false)
                        if isLast then
                            util_spineEndCallFunc(
                                roleNode,
                                "actionframe",
                                function()
                                    util_spinePlay(roleNode, "tao", false)
                                    util_spineEndCallFunc(
                                        roleNode,
                                        "tao",
                                        function()
                                            util_spinePlay(roleNode, "idle", true)
                                        end
                                    )
                                end
                            )
                        end
                        self:waitWithDelay(
                            self.m_role_node,
                            function()
                                funDelayCallBack(nodeName)
                            end,
                            16 / 30
                        )
                    end
                )
            end
        end

        self:waitWithDelay(
            self.m_role_node,
            function()
                local totalTime = 0
                self.m_boyNode:setVisible(true)
                self.m_girlNode:setVisible(true)
                gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_role_start.mp3")

                util_spinePlay(self.m_boyNode, "start", false)
                util_spinePlay(self.m_girlNode, "start", false)
                util_spineEndCallFunc(
                    self.m_girlNode,
                    "start",
                    function()
                        util_spinePlay(self.m_girlNode, "idle", true)
                    end
                )
                util_spineEndCallFunc(
                    self.m_boyNode,
                    "start",
                    function()
                        util_spinePlay(self.m_boyNode, "idle", true)
                        local totalTime = 0
                        for i, posTable in pairs(addWild) do
                            for index, _pos in ipairs(posTable) do
                                local timeDelay = 0
                                if i == 1 then
                                    if index == 1 then
                                        timeDelay = 0
                                    elseif index == 2 then
                                        timeDelay = (self.m_boyNode:getAnimationDurationTime("actionframe")) * (index - 1)
                                    else
                                        timeDelay =
                                            (self.m_boyNode:getAnimationDurationTime("actionframe") + self.m_boyNode:getAnimationDurationTime("tao")) * (index - 1) -
                                            self.m_boyNode:getAnimationDurationTime("tao")
                                    end
                                else
                                    if index == 1 then
                                        timeDelay = 0.3
                                    elseif index == 2 then
                                        timeDelay = (self.m_girlNode:getAnimationDurationTime("actionframe")) * (index - 1) + 0.3
                                     --男女扔雪球间隔0.3秒
                                    else
                                        timeDelay =
                                            (self.m_girlNode:getAnimationDurationTime("actionframe") + self.m_girlNode:getAnimationDurationTime("tao")) * (index - 1) + 0.3 -
                                            self.m_girlNode:getAnimationDurationTime("tao")
                                     --男女扔雪球间隔0.3秒
                                    end
                                end

                                totalTime = timeDelay > totalTime and timeDelay or totalTime
                                self:waitWithDelay(
                                    self.m_role_node,
                                    function()
                                        if funCallBack then
                                            -- 第一次扔雪球 播放一次
                                            if timeDelay == 0 or #addWild[1] == 0 then
                                                local random = math.random(1, #self.m_playFlySound)
                                                gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_xueqiu_fly" .. self.m_playFlySound[random] .. ".mp3")

                                                if #self.m_playFlySound == 1 then
                                                    self.m_playFlySound = {1, 2, 3, 4, 5}
                                                else
                                                    table.remove(self.m_playFlySound, random)
                                                end
                                            end

                                            funCallBack(i, _pos, index == #posTable, index == 1)
                                        end
                                    end,
                                    timeDelay
                                )
                            end
                        end

                        self:waitWithDelay(
                            self.m_role_node,
                            function()
                                self:waitWithDelay(
                                    self.m_role_node,
                                    function()
                                        --男女角色 消失
                                        self:freeRoleHide()
                                    end,
                                    totalTime + self.m_girlNode:getAnimationDurationTime("actionframe")
                                )

                                self:waitWithDelay(
                                    self.m_role_node,
                                    function()
                                        if _fun then
                                            _fun()
                                        end
                                    end,
                                    totalTime + 2
                                )
                            end,
                            0.1
                        )
                    end
                )
            end,
            0.1
        )
    else
        if _fun then
            _fun()
        end
    end
end

-- free下角色消失
function CodeGameScreenChristmas2021Machine:freeRoleHide()
    --男女角色 消失
    gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_role_over.mp3")
    util_spinePlay(self.m_boyNode, "over", false)
    util_spineEndCallFunc(
        self.m_boyNode,
        "over",
        function()
            self.m_boyNode:setVisible(false)
        end
    )

    util_spinePlay(self.m_girlNode, "over", false)
    util_spineEndCallFunc(
        self.m_girlNode,
        "over",
        function()
            self.m_girlNode:setVisible(false)
        end
    )
end

function CodeGameScreenChristmas2021Machine:reelDownNotifyPlayGameEffect()
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
function CodeGameScreenChristmas2021Machine:levelFreeSpinEffectChange()
    self.m_gameBg:runCsbAction("free", true)
    self:changeReelBg(true)
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenChristmas2021Machine:levelFreeSpinOverChangeEffect(content)
    self.m_gameBg:runCsbAction("bace", true)
    util_setCsbVisible(self.m_RespinBarView, false)
    self:changeReelBg(false)
end

-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenChristmas2021Machine:MachineRule_playSelfEffect(effectData)
    return true
end

function CodeGameScreenChristmas2021Machine:addSelfEffect()
end

function CodeGameScreenChristmas2021Machine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    elseif symbolType == self.SYMBOL_BONUS_LINK then
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

function CodeGameScreenChristmas2021Machine:onEnter()
    CodeGameScreenChristmas2021Machine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    self.m_jackPotBar:updateJackpotInfo()
end

function CodeGameScreenChristmas2021Machine:addObservers()
    CodeGameScreenChristmas2021Machine.super.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local num = params

            scheduler.performWithDelayGlobal(
                function()
                    self:breakBiggerPigShape(num)
                end,
                0.8,
                self:getModuleName()
            )

            self:shakeNode()
        end,
        "breakBiggerPigShape"
    )
end

function CodeGameScreenChristmas2021Machine:onExit()
    CodeGameScreenChristmas2021Machine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    if self.m_bgSoundId then
        gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
    scheduler.unschedulesByTargetName(self:getModuleName())
end

-- function CodeGameScreenChristmas2021Machine:getBetLevel( )
--     return 0
-- end

function CodeGameScreenChristmas2021Machine:requestSpinResult()
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
        jackpot = self.m_jackpotList
    }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end
--------------------------

function CodeGameScreenChristmas2021Machine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    local world_pos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    return world_pos
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenChristmas2021Machine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
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
        -- gLobalSoundManager:stopAudio(self.m_currentMusicId)
        gLobalSoundManager:stopBgMusic()
        self.m_currentMusicId = nil
    end
end

function CodeGameScreenChristmas2021Machine:isShowChooseBetOnEnter()
    return not self:checkHasFeature()
end

function CodeGameScreenChristmas2021Machine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    CodeGameScreenChristmas2021Machine.super.slotReelDown(self)
    if self.m_bProduceSlots_InFreeSpin then
        -- 滚动停止 遮罩消失
        -- self.m_qipanDark:runCsbAction("over",false,function()
        --     -- self.m_qipanDark:setVisible(false)
        -- end)
        -- self.m_bottomUI:getSpinBtn():isShowQuickStopBtn(false) -- 隐藏快停按钮
        -- 清理掉遮罩上的 wild
        self.m_wild_node:removeAllChildren()

        self.m_isQuitStop = false
    end
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenChristmas2021Machine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false
end

function CodeGameScreenChristmas2021Machine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    self:showFreeSpinOverView()
    gLobalSoundManager:fadeOutBgMusic()
end

function CodeGameScreenChristmas2021Machine:showFreeSpinOver(coins, num, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenChristmas2021Machine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(
        function()
            callFun()
        end,
        util_max(2, animTime),
        self:getModuleName()
    )
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenChristmas2021Machine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode == nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            slotNode:runAnim("actionframe")
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

function CodeGameScreenChristmas2021Machine:changeReelBg(isFree)
    self:findChild("Node_base_reel"):setVisible(false == isFree)
    self:findChild("Node_free_reel"):setVisible(isFree)
end

-- 延时函数
function CodeGameScreenChristmas2021Machine:waitWithDelay(parent, endFunc, time)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(
        waitNode,
        function()
            if endFunc then
                endFunc()
            end

            waitNode:removeFromParent()
            waitNode = nil
        end,
        time
    )
end

--震动
function CodeGameScreenChristmas2021Machine:shakeNode()
    local changePosY = 15
    local changePosX = 7.5
    local actionList2 = {}
    local oldPos = cc.p(self:findChild("root_ui"):getPosition())

    actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x - changePosX, oldPos.y + changePosY))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
    local seq2 = cc.Sequence:create(actionList2)
    --self.m_gameBg:runAction(seq2)
    self:findChild("root_ui"):runAction(seq2)

    self:findChild("lizi"):setVisible(true)
    self:findChild("lizi2"):setVisible(true)
    self:findChild("lizi3"):setVisible(true)

    gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_shake.mp3")

    self:runCsbAction("actionframe1", false)
    for i = 1, 12 do
        self:findChild("Particle_" .. i):resetSystem()
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenChristmas2021Machine:specialSymbolActionTreatment(node)
    -- print("dada")

    if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --修改小块层级
        local scatterOrder = self:getBounsScatterDataZorder(node.p_symbolType) - node.p_rowIndex
        local symbolNode = util_setSymbolToClipReel(self, node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER, 0)
        local linePos = {}
        linePos[#linePos + 1] = {iX = symbolNode.p_rowIndex, iY = symbolNode.p_cloumnIndex}
        symbolNode:setLinePos(linePos)
        symbolNode:runAnim(
            "buling",
            false,
            function()
                symbolNode:runAnim("idleframe", true)
            end
        )
    end
end

function CodeGameScreenChristmas2021Machine:initRespinView(endTypes, randomTypes)
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
                    -- self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
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

function CodeGameScreenChristmas2021Machine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    if self.m_bProduceSlots_InFreeSpin then
        -- self:dealSmallReelsSpinStates()
        -- self.m_bottomUI:getSpinBtn():resetStopBtnTouch()  --重置下stop按钮的点击状态

        self:freeSpinWildChange(
            function()
                self:produceSlots()

                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end

                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end
        )
    else
        self:produceSlots()

        local isWaitOpera = self:checkWaitOperaNetWorkData()
        if isWaitOpera == true then
            return
        end

        self.m_isWaitingNetworkData = false
        self:operaNetWorkData() -- end
    end
end

function CodeGameScreenChristmas2021Machine:beginReel()
    CodeGameScreenChristmas2021Machine.super.beginReel(self)
    -- free玩法 棋盘开始滚动显示遮罩
    if self.m_bProduceSlots_InFreeSpin then
        self.m_qipanDark:setVisible(true)
        self.m_qipanDark:runCsbAction(
            "start",
            false,
            function()
                self.m_qipanDark:runCsbAction("idle", true)
            end
        )
        self.m_changeWildList = {}
    end
end

--压暗层
function CodeGameScreenChristmas2021Machine:showColorLayer()
    self.m_qipanDark1:setVisible(true)
    self.m_qipanDark1:runCsbAction(
        "start",
        false,
        function()
            self.m_qipanDark1:runCsbAction("idle", true)
        end
    )
end

function CodeGameScreenChristmas2021Machine:hideColorLayer(_fun)
    self.m_qipanDark1:runCsbAction(
        "over",
        false,
        function()
            if _fun then
                _fun()
            end
        end
    )
end

-- 每个reel条滚动到底
function CodeGameScreenChristmas2021Machine:slotOneReelDown(reelCol)
    if self.m_bProduceSlots_InFreeSpin and reelCol == 1 then
        -- 滚动停止 遮罩消失
        self.m_qipanDark:runCsbAction(
            "over",
            false,
            function()
                -- self.m_qipanDark:setVisible(false)
            end
        )
    end

    local m_BonusNum = 0
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if targSp then
            local symbolType = targSp.p_symbolType
            if symbolType == self.SYMBOL_BONUS and self:getIsPlayBonusBuling(targSp) then
                m_BonusNum = m_BonusNum + 1
            -- local bonusOrder = self:getBounsScatterDataZorder(targSp.p_symbolType) - targSp.p_rowIndex
            -- local symbolNode = util_setSymbolToClipReel(self,targSp.p_cloumnIndex, targSp.p_rowIndex, self.SYMBOL_BONUS,bonusOrder)
            -- symbolNode:runAnim("buling")
            end
        end
    end
    if m_BonusNum > 0 then
        -- respinbonus落地音效
        gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_bonus_down.mp3")
    end

    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    self:playReelDownSound(reelCol, self.m_reelDownSound)

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        self:triggerLongRunChangeBtnStates()
    end

    return isTriggerLongRun
end

function CodeGameScreenChristmas2021Machine:reelSchedulerCheckColumnReelDown(parentData, parentY, slotParent, halfH)
    local timeDown = 0
    --
    --停止reel
    if L_ABS(parentY - parentData.moveDistance) < 0.1 then -- 浮点数精度问题
        if parentData.isDone ~= true then
            timeDown = 0
            if self.m_bClickQuickStop ~= true or self.m_iBackDownColID == parentData.cloumnIndex then
                parentData.isDone = true
            elseif self.m_bClickQuickStop == true and self:getGameSpinStage() ~= QUICK_RUN then
                return
            end

            local quickStopDistance = 0
            if self:getGameSpinStage() == QUICK_RUN or self.m_bClickQuickStop == true then
                quickStopDistance = self.m_quickStopBackDistance
            end
            slotParent:stopAllActions()
            self:slotOneReelDown(parentData.cloumnIndex)
            slotParent:setPosition(cc.p(slotParent:getPositionX(), parentData.moveDistance - quickStopDistance))

            local slotParentBig = parentData.slotParentBig
            if slotParentBig then
                slotParentBig:stopAllActions()
                slotParentBig:setPosition(cc.p(slotParentBig:getPositionX(), parentData.moveDistance - quickStopDistance))
                self:removeNodeOutNode(slotParentBig, true, halfH, parentData.cloumnIndex)
            end

            local childs = slotParent:getChildren()
            if slotParentBig then
                local newChilds = slotParentBig:getChildren()
                for i = 1, #newChilds do
                    childs[#childs + 1] = newChilds[i]
                end
            end

            -- release_print("滚动结束 .." .. 1)
            --移除屏幕下方的小块
            self:removeNodeOutNode(slotParent, true, halfH, parentData.cloumnIndex)
            local speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
            if slotParentBig then
                local seq = cc.Sequence:create(speedActionTable)
                slotParentBig:runAction(seq:clone())
            end

            timeDown = timeDown + (addTime + 0.1) -- 这里补充0.1 主要是因为以免计算出来的结果不够一帧的时间， 造成 action 执行和stop reel 有误差

            local tipSlotNoes = nil
            local nodeParent = parentData.slotParent
            local nodes = nodeParent:getChildren()
            if slotParentBig then
                local nodesBig = slotParentBig:getChildren()
                for i = 1, #nodesBig do
                    nodes[#nodes + 1] = nodesBig[i]
                end
            end
            tipSlotNoes = {}
            for i = 1, #nodes do
                local slotNode = nodes[i]
                local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

                if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
                    --播放关卡中设置的小块效果
                    self:playCustomSpecialSymbolDownAct(slotNode)

                    if self:checkSymbolTypePlayTipAnima(slotNode.p_symbolType) then
                        if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                            tipSlotNoes[#tipSlotNoes + 1] = slotNode
                        else
                            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                                slotNode:runAnim("idleframe", true)
                            end
                        end

                    --                            break
                    end
                --                        end
                end
            end -- end for i=1,#nodes

            if tipSlotNoes ~= nil then
                local nodeParent = parentData.slotParent
                for i = 1, #tipSlotNoes do
                    local slotNode = tipSlotNoes[i]

                    self:playScatterBonusSound(slotNode)
                    slotNode:runAnim("buling")
                    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
                    self:specialSymbolActionTreatment(slotNode)
                end -- end for
            end

            self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

            local actionFinishCallFunc =
                cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_bClickQuickStop == true then
                        self:quicklyStopReel(parentData.cloumnIndex)
                    end
                    print("滚动彻底停止了")
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end
            )

            speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

            slotParent:runAction(cc.Sequence:create(speedActionTable))
            timeDown = timeDown + self.m_reelDownAddTime
        end
    end -- end if L_ABS(parentY - parentData.moveDistance) < 0.1

    return timeDown
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenChristmas2021Machine:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    if not self.m_bIsSelectCall then
        self:playEffectNotifyChangeSpinStatus()
    end

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenChristmas2021Machine:initGameStatusData(gameData)
    CodeGameScreenChristmas2021Machine.super.initGameStatusData(self, gameData)

    if gameData.feature ~= nil then
        self.m_runSpinResultData:parseResultData(gameData.feature, self.m_lineDataPool, self.m_symbolCompares)
        self.m_initSpinData = self.m_runSpinResultData
    end
end

function CodeGameScreenChristmas2021Machine:levelDeviceVibrate(_vibrateType, _sFeature)
    if ("respin" == _sFeature and self.m_isBonusTrigger) or "free" == _sFeature then
        self.m_isBonusTrigger = false
        return
    end
    if CodeGameScreenChristmas2021Machine.super.levelDeviceVibrate then
        CodeGameScreenChristmas2021Machine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenChristmas2021Machine
