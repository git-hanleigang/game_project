---
-- island li
-- 2019年1月26日
-- GameScreenEgyptClassicSlots.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local GameScreenEgyptClassicSlots = class("GameScreenEgyptClassicSlots", BaseSlotoManiaMachine)

GameScreenEgyptClassicSlots.SYMBOL_CLASSIC_SCORE_WILD = 95
GameScreenEgyptClassicSlots.SYMBOL_CLASSIC_SCORE_7 = 10
GameScreenEgyptClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_3 = 11
GameScreenEgyptClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_2 = 12
GameScreenEgyptClassicSlots.SYMBOL_CLASSIC_SCORE_BAR_1 = 13
GameScreenEgyptClassicSlots.SYMBOL_CLASSIC_SCORE_CHERRY = 14

GameScreenEgyptClassicSlots.SYMBOL_CLASSIC_SCORE_EMPTY = 100

GameScreenEgyptClassicSlots.Classic_GameStates_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10 -- 自定义动画的标识

GameScreenEgyptClassicSlots.Classic_Wheel_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 11 -- 自定义动画的标识

GameScreenEgyptClassicSlots.m_isPlayWinSound = nil
GameScreenEgyptClassicSlots.m_winSoundTime = 1.5
GameScreenEgyptClassicSlots.m_classicIndex = nil
GameScreenEgyptClassicSlots.m_levelGetAnimNodeCallFun = nil
GameScreenEgyptClassicSlots.m_levelPushAnimNodeCallFun = nil
GameScreenEgyptClassicSlots.m_currReelWinCoin = nil

function GameScreenEgyptClassicSlots:initData_(data)
    self.m_parent = data.parent
    self.m_callFunc = data.func
    self.paytable = data.paytable
    self.m_iBetLevel = data.betlevel
    self.m_classicIndex = data.col
    self.m_spinTimes = data.spinTimes
    self.m_currReelWinCoin = 0
    self:initGame()
end

function GameScreenEgyptClassicSlots:enterGamePlayMusic()
end
function GameScreenEgyptClassicSlots:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("Egypt_ClassicConfig.csv", "LevelEgyptClassicConfig.lua")

    --初始化基本数据
    self:initMachine()
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}

    self.m_winCoinNode = util_createView("CodeEgyptSrc.EgyptClassicWinCoin")
    self:findChild("kuang"):addChild(self.m_winCoinNode)
    self.m_winCoinNode:setVisible(false)

    local selected, act = util_csbCreate("Egypt_Classical_win.csb")
    util_csbPlayForKey(act, "win", true)
    self.m_selectedEffect = selected
    self.m_selectedEffect:setVisible(false)
    self:findChild("jackpotBg1"):addChild(self.m_selectedEffect)
end
--默认按钮监听回调
function GameScreenEgyptClassicSlots:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- self.m_spinBtn:setVisible(false)

    -- self:normalSpinBtnCall()
    --respin
end

function GameScreenEgyptClassicSlots:initMachine()
    self.m_moduleName = self:getModuleName()
    self.m_machineModuleName = self.m_moduleName

    -- globalData.slotRunData.gameModuleName = self.m_moduleName
    -- globalData.slotRunData.gameNetWorkModuleName = self:getNetWorkModuleName()
    -- globalData.slotRunData.lineCount = self.m_lineCount

    self:createCsbNode("Egypt_Classical.csb")

    for i = 1, 5, 1 do
        if i ~= self.m_classicIndex then
            self:findChild("ClassicalH" .. i):setVisible(false)
            self:findChild("Egypt_logo_" .. i):setVisible(false)
            self:findChild("Egypt_kuang_" .. i):setVisible(false)
        end
    end

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
    self:updateBaseConfig()
    self:updateMachineData()

    self:initMachineData()
    -- self:initSymbolCCbNames()

    self:drawReelArea()

    self:updateReelInfoWithMaxColumn()
    self:initReelEffect()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )
end

---
-- 读取配置文件数据
--
function GameScreenEgyptClassicSlots:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function GameScreenEgyptClassicSlots:initMachineData()
    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName .. "_Datas"

    globalData.slotRunData.gameModuleName = self.m_moduleName

    -- 设置bet index

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()

    -- 配置全局信息，供外部使用
    self.m_levelGetAnimNodeCallFun = function(symbolType, ccbName)
        return self:getAnimNodeFromPool(symbolType, ccbName)
    end
    self.m_levelPushAnimNodeCallFun = function(animNode, symbolType)
        self:pushAnimNodeToPool(animNode, symbolType)
    end

    self:checkHasBigSymbol()
end

function GameScreenEgyptClassicSlots:LittleByLittleChangeBgMusic(time, callback)
    local volume = 0
    gLobalSoundManager:setBackgroundMusicVolume(volume)

    self.m_selfSsoundGlobalId =
        scheduler.scheduleGlobal(
        function()
            if volume >= 1 then
                volume = 1
            end
            volume = volume + 1 / time
            print("curSOund" .. volume)
            gLobalSoundManager:setBackgroundMusicVolume(volume)
            if volume >= 1 then
                if self.m_selfSsoundGlobalId ~= nil then
                    scheduler.unscheduleGlobal(self.m_selfSsoundGlobalId)
                    self.m_selfSsoundGlobalId = nil
                end
            end
        end,
        1 / 30
    )
end
function GameScreenEgyptClassicSlots:LittleByLittleChangeBgMusic2(time, callback)
    local volume = 1
    gLobalSoundManager:setBackgroundMusicVolume(volume)

    self.m_selfSsoundGlobalId =
        scheduler.scheduleGlobal(
        function()
            if volume <= 0 then
                volume = 0
            end
            volume = volume - 1 / time

            gLobalSoundManager:setBackgroundMusicVolume(volume)
            if volume <= 0 then
                if self.m_selfSsoundGlobalId ~= nil then
                    scheduler.unscheduleGlobal(self.m_selfSsoundGlobalId)
                    self.m_selfSsoundGlobalId = nil
                end
            end
        end,
        1 / 30
    )
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenEgyptClassicSlots:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Egypt_Classic"
end

function GameScreenEgyptClassicSlots:getNetWorkModuleName()
    return self.m_parent:getNetWorkModuleName()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenEgyptClassicSlots:MachineRule_GetSelfCCBName(symbolType)
    if self.SYMBOL_CLASSIC_SCORE_WILD == symbolType then
        return "Socre_Egypt_Classical_wild" .. self.m_classicIndex
    elseif self.SYMBOL_CLASSIC_SCORE_7 == symbolType then
        return "Socre_Egypt_Classical_7"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_3 == symbolType then
        return "Socre_Egypt_Classical_3bar"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_2 == symbolType then
        return "Socre_Egypt_Classical_2bar"
    elseif self.SYMBOL_CLASSIC_SCORE_BAR_1 == symbolType then
        return "Socre_Egypt_Classical_bar"
    elseif self.SYMBOL_CLASSIC_SCORE_CHERRY == symbolType then
        return "Socre_Egypt_Classical_L1"
    elseif self.SYMBOL_CLASSIC_SCORE_EMPTY == symbolType then
        return "Socre_Egypt_Classical_Empty"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function GameScreenEgyptClassicSlots:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_WILD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_7, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_BAR_1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_SCORE_CHERRY, count = 2}

    return loadNode
end

function GameScreenEgyptClassicSlots:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
    -- if self.m_nowPlayCol then
    --     local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
    --     if data[self.m_nowPlayCol] < 1 then

    --     end
    -- end
    --
    if self.m_runSpinResultData.p_winLines[1] ~= nil then
        local index = self.m_runSpinResultData.p_winLines[1].p_id
        local winNode = self:findChild("win_" .. index)
        self.m_selectedEffect:setVisible(true)
        self.m_selectedEffect:setPosition(cc.p(winNode:getPosition()))
        self.m_selectedEffect:setScaleX(winNode:getScaleX())
    end
    if self.m_spinSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_spinSoundId)
        self.m_spinSoundId = nil
    end
end

function GameScreenEgyptClassicSlots:reelDownNotifyChangeSpinStatus()
end

function GameScreenEgyptClassicSlots:showLineFrame()
    local winLines = self.m_reelResultLines

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                -- self:clearFrames_Fun()

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

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
                if frameIndex > #winLines then
                    frameIndex = 1
                end
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showAllFrame(winLines) -- 播放全部线框

        showLienFrameByIndex()
    else
        -- 播放一条线线框
        self:showLineFrameByIndex(winLines, 1)
        frameIndex = 2
        if frameIndex > #winLines then
            frameIndex = 1
        end

        showLienFrameByIndex()
    end
end

function GameScreenEgyptClassicSlots:callSpinBtn()
    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    self:spinBtnEnProc()

    self:setGameSpinStage(GAME_MODE_ONE_RUN)

    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end

function GameScreenEgyptClassicSlots:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    if self.m_winCoinNode:isVisible() == false then
        local delayTime = 0
        if self.m_runSpinResultData.p_selfMakeData.classicJackpot ~= nil then
            delayTime = 2
        end
        performWithDelay(
            self,
            function()
                self:findChild("Egypt_logo_" .. self.m_classicIndex):setVisible(false)
                self.m_winCoinNode:setVisible(true)
            end,
            delayTime
        )
    end

    -- local showWinCoins = 0
    local lastWinCoin = self.m_currReelWinCoin
    -- if self.m_runSpinResultData then
    --     if self.m_runSpinResultData.p_resWinCoins then
    --         showWinCoins = self.m_runSpinResultData.p_resWinCoins
    --     end
    -- end
    self.m_currReelWinCoin = self.m_currReelWinCoin + self.m_runSpinResultData.p_winAmount
    self.m_winCoinNode:updateWinCoin(lastWinCoin, self.m_currReelWinCoin)
    -- if self.m_parent:getInFreespin() == true then
    --     self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
    -- else
    self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
    -- end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_winAmount, false})
end

function GameScreenEgyptClassicSlots:playGameEffect()
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == true then
        self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    end
    BaseMachineGameEffect.playGameEffect(self)
end
--绘制多个裁切区域
function GameScreenEgyptClassicSlots:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self:findChild("sp_reel_0"):getParent()
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
        local high = reelSize.height / 4
        reelSize.height = reelSize.height + high

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
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

        local slotParentNode = cc.Layer:create() -- cc.LayerColor:create(cc.c4f(r,g,b,200))  --

        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY - high * 0.5)
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
    end
end

---
-- 获取最高的那一列
--
function GameScreenEgyptClassicSlots:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0

    local iColNum = self.m_iReelColumnNum
    --    local maxHeightColumnIndex = iColNum
    for iCol = 1, iColNum, 1 do
        -- local colNodeName = "reel_unit"..(iCol - 1)
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))

        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(reelNode:getPositionX(), reelNode:getPositionY())
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = reelSize.height

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height
            self.m_fReelWidth = reelSize.width
        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / 4

    for iCol = 1, iColNum, 1 do
        -- self.m_reelColDatas[iCol].p_slotColumnPosY = self.m_reelColDatas[iCol].p_slotColumnPosY - 0.5 * self.m_SlotNodeH
        self.m_reelColDatas[iCol].p_slotColumnHeight = self.m_reelColDatas[iCol].p_slotColumnHeight + self.m_SlotNodeH
    end

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = self.m_iReelRowNum -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

----
--- 处理spin 成功消息
--
function GameScreenEgyptClassicSlots:checkOperaSpinSuccess(param)
    local spinData = param[2]

    if spinData.action == "SPIN" then
        globalData.seqId = spinData.sequenceId
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果

        --发送测试赢钱数
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN, self.m_serverWinCoins)

        globalData.userRate:pushCoins(self.m_serverWinCoins)

        release_print("消息返回胡来了")

        spinData.result.selfData.classic.bet = spinData.result.bet
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spinData.result.selfData.classic, self.m_lineDataPool)

        local preLevel = globalData.userRunData.levelNum
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        if self.m_spinIsUpgrade == true then
            local sendData = {}

            local betCoin = globalData.slotRunData:getCurTotalBet()

            sendData.exp = betCoin * self.m_expMultiNum

            -- 存储一下VIP的原始等级
            self.m_preVipLevel = globalData.userRunData.vipLevel
            self.m_preVipPoints = globalData.userRunData.vipPoints
        end

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

---
-- 处理spin 返回结果
function GameScreenEgyptClassicSlots:spinResultCallFun(param)
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverDelayTime

    if param[1] == true then -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else -- 处理spin失败
        self:checkOpearSpinFaild(param)
    end
end

function GameScreenEgyptClassicSlots:requestSpinResult()
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

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, false, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function GameScreenEgyptClassicSlots:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex, self.m_nowPlayCol)

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function GameScreenEgyptClassicSlots:beginReel()
    BaseSlotoManiaMachine.beginReel(self)
    if self.m_nowPlayCol then
        local data = self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts
        if data[self.m_nowPlayCol] > 0 then
            data[self.m_nowPlayCol] = data[self.m_nowPlayCol] - 1
            -- local oldCol = self.m_nowPlayCol
            -- self:checkChangeIndex()
            self:updateOldBar(false)
        -- self:spinChangeJackpotBarState(self.m_nowPlayCol)
        end
    end
end

function GameScreenEgyptClassicSlots:reelSchedulerHanlder(delayTime)
    if (self:getGameSpinStage() ~= GAME_MODE_ONE_RUN and self:getGameSpinStage() ~= QUICK_RUN) or self:checkGameRunPause() then
        return
    end

    -- slotReelTime = slotReelTime  + delayTime
    -- if slotReelTime < reelDelayTime then
    --     return
    -- end
    -- reelDelayTime = util_random(8,30) / 100
    -- slotReelTime = 0

    if self.m_reelDownAddTime > 0 then
        self.m_reelDownAddTime = self.m_reelDownAddTime - delayTime
    else
        self.m_reelDownAddTime = 0
    end
    local timeDown = 0
    local slotParentDatas = self.m_slotParents

    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]
        local slotParent = parentData.slotParent
        -- if parentData.cloumnIndex == 1 then
        -- 	printInfo(" %d ", parentData.tag)
        -- end
        local columnData = self.m_reelColDatas[index]
        local halfH = columnData.p_showGridH * 0.5

        local parentY = slotParent:getPositionY()
        if parentData.isDone == false then
            local cloumnMoveStep = self:getColumnMoveDis(parentData, delayTime)
            local newParentY = slotParent:getPositionY() - cloumnMoveStep
            if self.m_isWaitingNetworkData == false then
                if newParentY < parentData.moveDistance then
                    newParentY = parentData.moveDistance
                end
            end

            -- if index == 3 thenx
            --     print("")
            -- end
            slotParent:setPositionY(newParentY)
            parentY = newParentY
            local childs = slotParent:getChildren()
            local zOrder, preY = self:reelSchedulerCheckRemoveNodes(childs, halfH, parentY, index)
            self:reelSchedulerCheckAddNode(parentData, zOrder, preY, halfH, parentY, slotParent)
        end

        if self.m_isWaitingNetworkData == false then
            timeDown = self:reelSchedulerCheckColumnReelDown(parentData, parentY, slotParent, halfH)
        end
    end -- end for

    local isAllReelDone = function()
        for index = 1, #slotParentDatas do
            if slotParentDatas[index].isResActionDone == false then
                -- if slotParentDatas[index].isDone == false then

                return false
            end
        end
        return true
    end

    if isAllReelDone() == true then
        if self.m_reelScheduleDelegate ~= nil then
            self.m_reelScheduleDelegate:unscheduleUpdate()
        end
        self:slotReelDown()

        -- 先写在这里 之后写到 回弹结束里面去
        --加入回弹

        -- scheduler.performWithDelayGlobal(
        --     function()
        --         self:slotReelDown()
        --     end,
        --     timeDown,
        --     self:getModuleName()
        -- )

        --        end,timeDown)
        self.m_reelDownAddTime = 0
    end
end

function GameScreenEgyptClassicSlots:requestSpinReusltData()
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
    -- if self:getCurrSpinMode() == RESPIN_MODE then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --     {SpinBtn_Type.BtnType_Spin,false})
    -- else
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --     {SpinBtn_Type.BtnType_Stop,false})
    -- end

    local time1 = xcyy.SlotsUtil:getMilliSeconds()
    print((time1 - time) .. "发送消息消耗时间")
end

function GameScreenEgyptClassicSlots:dealSmallReelsSpinStates()
    -- do nothing
end

function GameScreenEgyptClassicSlots:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function GameScreenEgyptClassicSlots:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    if self.m_isPlayWinSound then
        return
    else
        self.m_isPlayWinSound = true
    end
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end
            if self.m_runSpinResultData.p_selfMakeData.classicJackpot ~= nil then
                return
            end
            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 6 then
                soundIndex = 2
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 3
            end

            local soundName = "EgyptSounds/sound_classic_lastwin_" .. soundIndex .. ".mp3"
            local winSoundsId = gLobalSoundManager:playSound(soundName, false)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function GameScreenEgyptClassicSlots:gameStart()
    gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_classic_move.mp3")
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
            performWithDelay(
                self,
                function()
                    local random = math.random(1, 3)
                    self.m_spinSoundId = gLobalSoundManager:playSound("EgyptSounds/sound_classic_spin_" .. random .. ".mp3")
                    self:normalSpinBtnCall()
                    self.m_parent:changeRespinNum(self.m_classicIndex)
                end,
                1
            )
        end
    )
end

function GameScreenEgyptClassicSlots:gameOver(func)
    self.m_parent:showBonusWinCoin(self.m_currReelWinCoin)
    gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_classic_move.mp3")
    self:runCsbAction(
        "over",
        false,
        function()
            if func then
                func()
            end
        end
    )
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function GameScreenEgyptClassicSlots:MachineRule_SpinBtnCall()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_spinTimes = self.m_spinTimes - 1
    return false
end

function GameScreenEgyptClassicSlots:playEffectNotifyNextSpinCall()
    if self.m_runSpinResultData.p_selfMakeData.classicJackpot ~= nil then
        gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_triger_jackpot.mp3")
        performWithDelay(
            self,
            function()
                self.m_parent:showJackpotView(
                    self.m_runSpinResultData.p_selfMakeData.classicJackpot,
                    self.m_runSpinResultData.p_winAmount,
                    function()
                        performWithDelay(
                            self,
                            function()
                                if self.m_spinTimes > 0 then
                                    self.m_selectedEffect:setVisible(false)
                                    self.m_parent:changeRespinNum(self.m_classicIndex)
                                    local random = math.random(1, 3)
                                    self.m_spinSoundId = gLobalSoundManager:playSound("EgyptSounds/sound_classic_spin_" .. random .. ".mp3")
                                    self:normalSpinBtnCall()
                                else
                                    performWithDelay(
                                        self,
                                        function()
                                            self.m_selectedEffect:setVisible(false)
                                            self:gameOver(self.m_callFunc)
                                        end,
                                        1
                                    )
                                end
                            end,
                            1
                        )
                    end
                )
            end,
            2
        )
    else
        performWithDelay(
            self,
            function()
                if self.m_spinTimes > 0 then
                    self.m_selectedEffect:setVisible(false)
                    self.m_parent:changeRespinNum(self.m_classicIndex)
                    local random = math.random(1, 3)
                    self.m_spinSoundId = gLobalSoundManager:playSound("EgyptSounds/sound_classic_spin_" .. random .. ".mp3")
                    self:normalSpinBtnCall()
                else
                    performWithDelay(
                        self,
                        function()
                            self.m_selectedEffect:setVisible(false)
                            self:gameOver(self.m_callFunc)
                        end,
                        1
                    )
                end
            end,
            2.5
        )
    end
end

function GameScreenEgyptClassicSlots:playEffectNotifyChangeSpinStatus()
end

function GameScreenEgyptClassicSlots:showLineFrameByIndex(winLines, frameIndex)
end

function GameScreenEgyptClassicSlots:checkFeatureOverTriggerBigWin(winAmonut, feature)
    if winAmonut == nil then
        return
    end
end

function GameScreenEgyptClassicSlots:addLastWinSomeEffect() -- add big win or mega win
    if #self.m_vecGetLineInfo == 0 then
        return
    end
end

function GameScreenEgyptClassicSlots:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    self:clearSlotoData()
    globalData.userRate:leaveLevel()
    scheduler.unschedulesByTargetName("BaseSlotoManiaMachine")

    BaseMachineGameEffect.onExit(self) -- 必须调用不予许删除
    --停止背景音乐
    gLobalSoundManager:stopBgMusic()

    self:removeObservers()
    self:clearFrameNodes()
    self:clearSlotNodes()

    -- 卸载金边
    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]
        if reelNode:getParent() ~= nil then
            reelNode:removeFromParent()
        end

        reelNode:release()
        reelAct:release()

        self.m_reelRunAnima[i] = v
    end

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:unscheduleUpdate()
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end

    if self.m_respinNodeInfo ~= nil and #self.m_respinNodeInfo > 0 then
        for k = 1, #self.m_respinNodeInfo do
            local node = self.m_respinNodeInfo[k].node
            if not tolua.isnull(node) then
                node:removeFromParent()
            end
        end
    end
    self.m_respinNodeInfo = {}

    self:removeSoundHandler()

    --离开，清空
    gLobalActivityManager:clear()

    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    self:clearSlotoData()
    globalData.userRate:leaveLevel()
    scheduler.unschedulesByTargetName("BaseSlotoManiaMachine")
end

function GameScreenEgyptClassicSlots:getSymbolCCBNameByType(MainClass, symbolType)
    local ccbName = nil
    local selfCcbName = MainClass:MachineRule_GetSelfCCBName(symbolType)
    if selfCcbName ~= nil then
        ccbName = selfCcbName
    end
    -- print("getSymbolCCBNameByType="..symbolType)
    if not ccbName then
        print("getSymbolCCBNameByccbName=error")
    else
        -- print("getSymbolCCBNameByccbName="..ccbName)
    end
    return ccbName
end

function GameScreenEgyptClassicSlots:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    reelNode.p_levelPushAnimNodeCallFun = self.m_levelPushAnimNodeCallFun
    reelNode.p_levelGetAnimNodeCallFun = self.m_levelGetAnimNodeCallFun

    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)

    return reelNode
end

--小块
function GameScreenEgyptClassicSlots:getBaseReelGridNode()
    return "CodeEgyptSrc.EgyptClassicSlotsNode"
end

function GameScreenEgyptClassicSlots:clearSlotoData()
    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then
        for i = #self.m_lineDataPool, 1, -1 do
            self.m_lineDataPool[i] = nil
        end
    end
end

-- 设置下落后动画
function GameScreenEgyptClassicSlots:setPlayAnimationName(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local nIdx = -1

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iCol ~= nil then
        nIdx = self:getPosReelIdx(iRow, iCol)
    end
    if symbolNode:getCcbProperty("multipx2") ~= nil then
        symbolNode:getCcbProperty("multipx2"):setVisible(false)
    end
    if symbolNode:getCcbProperty("multipx3") ~= nil then
        symbolNode:getCcbProperty("multipx3"):setVisible(false)
    end
    if symbolNode:getCcbProperty("multipx5") ~= nil then
        symbolNode:getCcbProperty("multipx5"):setVisible(false)
    end

    local vecWillMultiplies = nil
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.wildMultiplies ~= nil then
        vecWillMultiplies = self.m_runSpinResultData.p_selfMakeData.wildMultiplies
    end
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true and vecWillMultiplies ~= nil and #vecWillMultiplies > 0 then
        if symbolNode:getCcbProperty("multipx" .. vecWillMultiplies[tostring(nIdx)]) ~= nil then
            symbolNode:getCcbProperty("multipx" .. vecWillMultiplies[tostring(nIdx)]):setVisible(true)
        end
    elseif symbolNode.p_symbolType ~= nil then
        local vecMultip = {2, 3, 5}
        local rand = math.random(1, 3)
        if symbolNode:getCcbProperty("multipx" .. vecMultip[rand]) ~= nil then
            symbolNode:getCcbProperty("multipx" .. vecMultip[rand]):setVisible(true)
        end
    end
end

function GameScreenEgyptClassicSlots:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, iRow, iCol, isLastSymbol)

    if self.m_classicIndex == 5 and symbolType == self.SYMBOL_CLASSIC_SCORE_WILD then
        local callFun = cc.CallFunc:create(handler(self, self.setPlayAnimationName), {reelNode})
        self:runAction(callFun)
    end

    return reelNode
end

function GameScreenEgyptClassicSlots:setLastWinCoin(winCoin)
    globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + winCoin
end

function GameScreenEgyptClassicSlots:checkControlerReelType()
    return false
end

return GameScreenEgyptClassicSlots
