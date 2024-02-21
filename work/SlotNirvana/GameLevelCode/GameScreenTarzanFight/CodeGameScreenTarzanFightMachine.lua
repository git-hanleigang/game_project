--
-- 泰山关卡
-- Author:{author}
-- Date: 2018-12-22 12:26:51
--

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseMachine = require "Levels.BaseMachine"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenTarzanFightMachine = class("CodeGameScreenTarzanFightMachine", BaseSlotoManiaMachine)

CodeGameScreenTarzanFightMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenTarzanFightMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenTarzanFightMachine.TARZAN_FIGHT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3
CodeGameScreenTarzanFightMachine.TARZAN_SHOW_HIT_LINE_FRAME = GameEffect.EFFECT_SELF_EFFECT - 4
CodeGameScreenTarzanFightMachine.TARZAN_FIGHT_LINE_SYMBOL_TYPE = 200

CodeGameScreenTarzanFightMachine.m_TriggerFSCount = 100000 -- 触发时  fs 次数
CodeGameScreenTarzanFightMachine.m_changeScList = nil -- normal 下 将scatter 改变为 H1记录的位置
CodeGameScreenTarzanFightMachine.m_littleSymbolArray = nil -- 记录下freeSpin下的顶部小信号
CodeGameScreenTarzanFightMachine.m_littleSymbolSize = nil -- 记录下freeSpin下的顶部小信号大小
CodeGameScreenTarzanFightMachine.m_littleSymbolBeginPosNode = nil
CodeGameScreenTarzanFightMachine.m_littleSymbolEndPosNode = nil
CodeGameScreenTarzanFightMachine.m_viewAction = 1
CodeGameScreenTarzanFightMachine.m_spineAction = 2
CodeGameScreenTarzanFightMachine.m_littleSymbolNetData = nil -- 记录下freeSpin下的顶部小信号网络数据
CodeGameScreenTarzanFightMachine.m_littleSymbolOnceScore = nil -- 记录下freeSpin下的顶部小信号网络数据

CodeGameScreenTarzanFightMachine.m_littleSymbolScaleSize = nil -- 顶部小信号缩放尺寸
CodeGameScreenTarzanFightMachine.m_littleSymbolSpinYPos = nil -- 顶部spin小信号Y移动距离
CodeGameScreenTarzanFightMachine.m_littleSymbolScoreImgArray = nil -- 顶部spin小信号分数图片数组
CodeGameScreenTarzanFightMachine.m_FreeSpinOverFullStates = nil -- 顶部spin小信号分数图片数组
CodeGameScreenTarzanFightMachine.m_FreeSpinTimes = nil -- 顶部spin小信号分数图片数组
CodeGameScreenTarzanFightMachine.m_fullSymbolNum = nil -- 顶部spin小信号最大个数
CodeGameScreenTarzanFightMachine.m_scatterWinAmount = nil -- scatter 产生的赢钱线

CodeGameScreenTarzanFightMachine.m_winSoundsId = nil

function CodeGameScreenTarzanFightMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_freeSpinOverDelayTime = 0
    self.m_winSoundsId = nil
    self.m_isFeatureOverBigWinInFree = true

    self:initGame()
end

function CodeGameScreenTarzanFightMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("TarzanFightConfig.csv", "LevelTarzanFightConfig.lua")

    self.m_changeScList = nil
    self.m_littleSymbolArray = {}
    self.m_littleSymbolNetData = {}
    self.m_littleSymbolOnceScore = 0
    self.m_littleSymbolScaleSize = 0.43
    self.m_littleSymbolSpinYPos = 0
    self.m_littleSymbolScoreImgArray = {}
    self.m_FreeSpinOverFullStates = false
    self.m_FreeSpinTimes = 0
    self.m_fullSymbolNum = 17
    self.m_topSymbolMoveSounds = {}
    self.m_scaleLocalMainSize = -0.20
    self.m_beginFight = nil
    -- 中奖音效
    self.m_winPrizeSounds = {}
    for i = 1, 4 do
        self.m_winPrizeSounds[#self.m_winPrizeSounds + 1] = "TarzanFightSounds/music_TarzanFight_WinPrize_" .. i .. ".mp3"
    end
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            local winAmonut = params[1]
            if type(winAmonut) == "number" then
                local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
                local winRatio = winAmonut / lTatolBetNum
                local soundName = nil
                local soundTime = 2
                if winRatio > 0 then
                    if winRatio <= 1 then
                        soundName = self.m_winPrizeSounds[1]
                    elseif winRatio > 1 and winRatio <= 3 then
                        soundName = self.m_winPrizeSounds[2]
                    elseif winRatio > 3 and winRatio <= 5 then
                        soundName = self.m_winPrizeSounds[3]
                        soundTime = 3
                    elseif winRatio > 5 then
                        soundName = self.m_winPrizeSounds[4]
                        soundTime = 3
                    end

                -- 赢钱线飞金币规则
                -- self:flyCoinsForScore(winAmonut)
                end

                if soundName ~= nil then
                    self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
                end
            end
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    -- 小信号移动音效
    for i = 1, 4 do
        self.m_topSymbolMoveSounds[#self.m_topSymbolMoveSounds + 1] = "TarzanFightSounds/TarzanFight_top_symbol_move_" .. i .. ".mp3"
    end
    -- 小信号被打音效
    self.m_topSymbolAnimalSounds = {
        "TarzanFightSounds/TarzanFight_renyaun.mp3",
        "TarzanFightSounds/TarzanFight_shizi.mp3",
        "TarzanFightSounds/TarzanFight_xiang.mp3",
        "TarzanFightSounds/TarzanFight_eyu.mp3"
    }
end

function CodeGameScreenTarzanFightMachine:hideLocalReels()
    -- self.m_root:setOpacity(0)
    local speed = 0.3

    scheduler.performWithDelayGlobal(
        function()
            local seq = cc.Sequence:create(cc.FadeOut:create(speed))
            self.m_root:runAction(seq)
            self:setReelSlotsNodeVisible(false)
            self:setLineSlotsNodeVisible(false)
            self.m_slotEffectLayer:setVisible(false)
        end,
        speed,
        self:getModuleName()
    )
end

function CodeGameScreenTarzanFightMachine:setLineSlotsNodeVisible(states)
    -- 连线 SlotNode
    local nodeLen = #self.m_lineSlotNodes
    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        if lineNode ~= nil then -- TODO 补丁
            lineNode:setVisible(states)
        end
    end
end

function CodeGameScreenTarzanFightMachine:showLocalReels()
    local speed = 0.3
    self:setReelSlotsNodeVisible(false)
    scheduler.performWithDelayGlobal(
        function()
            local seq = cc.Sequence:create(cc.FadeIn:create(speed))
            self.m_root:runAction(seq)

            scheduler.performWithDelayGlobal(
                function()
                    self:setReelSlotsNodeVisible(true)
                    self:setLineSlotsNodeVisible(true)
                    self.m_slotEffectLayer:setVisible(true)
                end,
                speed,
                self:getModuleName()
            )
        end,
        speed,
        self:getModuleName()
    )
end

function CodeGameScreenTarzanFightMachine:initUI(data)
    -- self:initFreeSpinBar()
    -- self:findChild(" ")
    self.m_TzrzanFightReelsHide = util_createView("CodeTarzanFightSrc.TzrzanFightReelsHide")
    self:findChild("hide_node"):addChild(self.m_TzrzanFightReelsHide)
    self.m_TzrzanFightReelsHide:setVisible(true)

    self.m_BgWater = util_createView("CodeTarzanFightSrc.TzrzanFightBgWater")
    self.m_gameBg:findChild("node_pubu"):addChild(self.m_BgWater)
    self.m_BgWater:setVisible(false)

    self:findChild("node_little_symbol"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    self.m_flyCoinsNode = cc.Node:create()
    self:findChild("node_little_symbol"):getParent():addChild(self.m_flyCoinsNode)
    self.m_flyCoinsNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    self.m_flyScoreCoinsNode = cc.Node:create()
    self:findChild("node_little_symbol"):getParent():addChild(self.m_flyScoreCoinsNode)
    self.m_flyScoreCoinsNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    self.m_littleSymbolBeginPosNode = self:findChild("symbol_pos2")
    self.m_littleSymbolEndPosNode = self:findChild("symbol_pos1")
    self.m_littleSymbolSize = (self.m_littleSymbolBeginPosNode:getPositionX() - self.m_littleSymbolEndPosNode:getPositionX()) / 16

    self.m_tzrzanFlayAction = util_createView("CodeTarzanFightSrc.TzrzanFlayAction")
    self:addChild(self.m_tzrzanFlayAction, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    -- local pos = cc.p(self.m_tzrzanFlayAction:getPosition())
    -- self.m_tzrzanFlayAction:setPositionY(pos.y - 40)
    self.m_tzrzanFlayAction:setVisible(false)

    self:findChild("node_little_symbol_Score"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    for i = 1, 4 do
        local scoreImg = util_createView("CodeTarzanFightSrc.TzrzanFightScore")
        scoreImg:setVisible(false)
        scoreImg:showOneTxtImg(i)
        self:findChild("node_little_symbol_Score"):addChild(scoreImg, 100)
        table.insert(self.m_littleSymbolScoreImgArray, scoreImg)
    end
end

function CodeGameScreenTarzanFightMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end
-- 整理网络数据
function CodeGameScreenTarzanFightMachine:sortNetDataToLocalData(netdata)
    local data = {}
    table.sort(
        netdata,
        function(a, b)
            return a < b
        end
    )
    data = netdata

    data[#data + 1] = 0

    return data
end

-- 断线重连
function CodeGameScreenTarzanFightMachine:MachineRule_initGame(initSpinData)
    -- self.p_fsExtraData = data.freespin.extra
    if self.m_runSpinResultData.p_freeSpinsTotalCount then
        self.m_FreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinsLeftCount
        self:updateFreeSpinTimes()
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:changeBgToFreeSpin()

        self:scaleMainLayer(self.m_scaleLocalMainSize)
        self:changeFreeSpinReelData()

        if initSpinData.p_fsExtraData and initSpinData.p_fsExtraData.littleSymbolNetData then
            local data = self:sortNetDataToLocalData(initSpinData.p_fsExtraData.littleSymbolNetData)
            self.m_littleSymbolNetData = data
            for k, v in pairs(data) do
                -- 创建小块
                self:createSymbolInFs(v)
                self:restSymbolZorder()
                self:initLittleTopSymbolPos()
                --顶部分数
                local Score = self:getOneSymbolScoreImgNewScore(v)
                -- self:setOneSymbolAllScoreImgPos()
                self:setOneSymbolScoreImgScore(v, Score)
                self:showOneSymbolScoreImg(v)
                self:setAllSymbolScoreImgZorder()
                self:palyOneSymbolScoreImgAction(v, "show")
            end
        end
    end
end

function CodeGameScreenTarzanFightMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("TarzanFightSounds/music_TarzanFight_goin.mp3")

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

function CodeGameScreenTarzanFightMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    if self.m_flyScoreCoinsNode then
        self.m_flyScoreCoinsNode:removeAllChildren()
    end

    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenTarzanFightMachine:getModuleName()
    return "TarzanFight"
end
---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenTarzanFightMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_TarzanFight_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_TarzanFight_11"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_TarzanFight_Scatter"
    end

    return nil
end

function CodeGameScreenTarzanFightMachine:getReelHeight()
    return 540
end

function CodeGameScreenTarzanFightMachine:getReelWidth()
    return 1150
end

function CodeGameScreenTarzanFightMachine:scaleMainLayer(scaleSize)
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
        local ratio = display.height/display.width
        if ratio >= 768 / 1024 then
            mainScale = 0.85
        elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
            mainScale = 0.90 - 0.05 * ((ratio - 640 / 960) / (768 / 1024 - 640 / 960))
        end

        if scaleSize then
            mainScale = mainScale + scaleSize
            if self.m_isPadScale then
                mainScale = mainScale + 0.05
            end
        end

        local posChange = 0
        if scaleSize and scaleSize ~= 0 then
            posChange = 3
        else
            posChange = 58
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + posChange - 10)
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenTarzanFightMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine:getPreLoadSlotNodes()
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 2}
    loadNode[#loadNode + 2] = {symbolType = self.SYMBOL_SCORE_11, count = 2}

    return loadNode
end

--[[
    @desc: 自定义动画
    time:2018-12-26 11:35:37
    @return:
]]
function CodeGameScreenTarzanFightMachine:addSelfEffect()
    if self.m_bProduceSlots_InFreeSpin == true then
        -- 判断是否触发泰山打动画
        local tarzanCount = self:getSymbolCountWithReelResult(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
        if tarzanCount > 0 then
            if #self.m_littleSymbolArray ~= 0 then -- 初次触发fs 时不可能有值， 一定为0
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.TARZAN_FIGHT_EFFECT
            end
        end

        -- 判断是否有赢钱线 , 单独触发hit 怪兽时需要触发赢钱变化
        if #self.m_vecGetLineInfo == 0 and self.m_littleSymbolOnceScore > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.TARZAN_SHOW_HIT_LINE_FRAME
        end
    end
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenTarzanFightMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.TARZAN_FIGHT_EFFECT then
        -- 飞信号模块
        self:flySymbolModel(effectData)
    elseif effectData.p_selfEffectType == self.TARZAN_SHOW_HIT_LINE_FRAME then
        -- 如果freespin 未结束，不通知左上角玩家钱数量变化
        local isNotifyUpdateTop = true
        if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE then
            isNotifyUpdateTop = false
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})

        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true
end

function CodeGameScreenTarzanFightMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    self:isCanflyScoreCoins(isNotifyUpdateTop)
end

-- 检测是否飞赢钱金币
function CodeGameScreenTarzanFightMachine:isCanflyScoreCoins(isNotifyUpdateTop)
    local flyCoins = false
    for k, v in pairs(self.m_vecGetLineInfo) do
        if v.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            flyCoins = true
        end
    end

    if flyCoins then
        self:flyCoinsForScore(self.m_iOnceSpinLastWin)
        self.updateScoreScheduleID =
            scheduler.performWithDelayGlobal(
            function()
                self:winCoinsLabAction()

                scheduler.unscheduleGlobal(self.updateScoreScheduleID)
                self.updateScoreScheduleID = nil

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
            end,
            1.5,
            self:getModuleName()
        )
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end
-- 大赢赢钱线 分拨飞
function CodeGameScreenTarzanFightMachine:flyBigLinesCoins(showType)
    -- 大赢 分拨飞
    local coinsflytimes = 4
    local witetimes = 1
    for i = 1, coinsflytimes do
        if i == 1 then
            self.updateBigScoreScheduleID_1 =
                scheduler.performWithDelayGlobal(
                function()
                    scheduler.unscheduleGlobal(self.updateBigScoreScheduleID_1)
                    self.updateBigScoreScheduleID_1 = nil

                    self:symbolFlyForScore(showType)
                end,
                witetimes * i - 1,
                self:getModuleName()
            )
        elseif i == 2 then
            self.updateBigScoreScheduleID_2 =
                scheduler.performWithDelayGlobal(
                function()
                    scheduler.unscheduleGlobal(self.updateBigScoreScheduleID_2)
                    self.updateBigScoreScheduleID_2 = nil

                    self:symbolFlyForScore(showType)
                end,
                witetimes * i - 1,
                self:getModuleName()
            )
        elseif i == 3 then
            self.updateBigScoreScheduleID_3 =
                scheduler.performWithDelayGlobal(
                function()
                    scheduler.unscheduleGlobal(self.updateBigScoreScheduleID_3)
                    self.updateBigScoreScheduleID_3 = nil

                    self:symbolFlyForScore(showType)
                end,
                witetimes * i - 1,
                self:getModuleName()
            )
        elseif i == 4 then
            self.updateBigScoreScheduleID_4 =
                scheduler.performWithDelayGlobal(
                function()
                    scheduler.unscheduleGlobal(self.updateBigScoreScheduleID_4)
                    self.updateBigScoreScheduleID_4 = nil

                    self:symbolFlyForScore(showType)
                end,
                witetimes * i - 1,
                self:getModuleName()
            )
        end
    end
end

-- 普通赢钱飞金币
function CodeGameScreenTarzanFightMachine:flyCoinsForScore(score)
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = score / lTatolBetNum
    local showType = nil
    local showBigWins = false
    if winRatio > 0 then
        if winRatio <= 2 then
            showType = 3
        elseif winRatio > 2 and winRatio <= 4 then
            showType = 2
        elseif winRatio > 4 and winRatio <= 8 then
            showType = 1
        else
            -- showBigWins = true （暂时去掉大赢赢钱分拨飞金币）
            showType = 1
        end
    end

    if showType then -- and self.m_bProduceSlots_InFreeSpin ~= true
        -- 根据类型播放飞金币效果
        if #self.m_vecGetLineInfo == 0 and self.m_littleSymbolOnceScore > 0 then
            -- 只有小怪兽得分的时候不飞金币
        else
            if showBigWins then
                -- 大赢赢钱线 分拨飞
                self:flyBigLinesCoins(showType)
            else
                self:symbolFlyForScore(showType)
            end
        end
    end
end

function CodeGameScreenTarzanFightMachine:symbolFlyForScore(showType)
    for k, v in pairs(self.m_vecGetLineInfo) do
        if v.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if type(v.vecValidMatrixSymPos) == "table" then
                for kk, vv in pairs(v.vecValidMatrixSymPos) do
                    local iconPos = self:getPosReelIdx(vv.iX, vv.iY)
                    local pos = self:getAllSymbolPos()[iconPos] -- self:findChild("node_little_symbol_flyCoins"):getPosition()

                    self:flyScoreCoins(showType, cc.p(pos), 2)
                end
            end
        end
    end
end
-- 获得泰山最大打击次数
function CodeGameScreenTarzanFightMachine:gethigtTopSymbolMaxTimes()
    local higtMaxTimes = 0
    local mathTable = {0, 0, 0, 0}

    for k, v in pairs(self.m_littleSymbolArray) do
        if v.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
            mathTable[1] = 1
        elseif v.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
            mathTable[2] = 1
        elseif v.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
            mathTable[3] = 1
        elseif v.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
            mathTable[4] = 1
        end
    end
    for k, v in pairs(mathTable) do
        if v == 1 then
            higtMaxTimes = higtMaxTimes + 1
        end
    end

    return higtMaxTimes
end

function CodeGameScreenTarzanFightMachine:getReelsSymbol9(higtMaxTimes)
    local m_stcValidSymbol9 = {}
    local tarzanNum = 0
    -- 存储上 允许打击的信号九
    for j = 1, self.m_iReelColumnNum, 1 do
        for i = 1, self.m_iReelRowNum, 1 do
            local symbolType = self.m_stcValidSymbolMatrix[i][j]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                tarzanNum = tarzanNum + 1
                if tarzanNum <= higtMaxTimes then
                    local symbolNode = self:getReelParent(j):getChildByTag(self:getNodeTag(j, i, SYMBOL_NODE_TAG))
                    table.insert(m_stcValidSymbol9, symbolNode)
                end
            end
        end
    end

    return m_stcValidSymbol9
end
-- 小信号玩法动画泰山打模块
function CodeGameScreenTarzanFightMachine:TarzanFightSymbolModel(effectData, time) -- time是小信号飞行完的时间
    local timenum2 = 0
    local m_stcValidSymbol9 = {}
    local SymbolIndex = 1

    performWithDelay(
        self,
        function()
            local higtMaxTimes = self:gethigtTopSymbolMaxTimes()
            local tarzanNum = 0

            -- 获得reels上的信号九
            m_stcValidSymbol9 = self:getReelsSymbol9(higtMaxTimes)

            -- 开始击打动画
            for k, v in pairs(m_stcValidSymbol9) do
                performWithDelay(
                    self,
                    function()
                        local stcValidSymbol9Reels = m_stcValidSymbol9[SymbolIndex]
                        m_stcValidSymbol9[SymbolIndex]:runAnim(
                            "battle",
                            false,
                            function()
                            end
                        ) -- 播放reels泰山打击动画

                        local node = self:createOneActionSymbol(m_stcValidSymbol9[SymbolIndex], "battle")

                        -- 开始击打
                        local downTime = 0.5
                        for k, v in pairs(self.m_littleSymbolArray) do
                            if v.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                                local symbolType_9 = v.symbolSpr
                                symbolType_9:playAction(
                                    "battle2",
                                    false,
                                    function()
                                        symbolType_9:playAction("idle2", true)
                                    end
                                ) -- 播放顶部泰山打击动画

                                -- 移除相应的小信号
                                performWithDelay(
                                    self,
                                    function()
                                        gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_taishang_fight.mp3")
                                        local moveSymbolNum = 0
                                        local maxSymbolType = self:getLittleSymbolArrayMaxType()
                                        for i = #self.m_littleSymbolArray, 1, -1 do
                                            local symbol = self.m_littleSymbolArray[i]
                                            if symbol.symbolType == maxSymbolType then
                                                moveSymbolNum = moveSymbolNum + 1

                                                -- 播放某个某个小信号分数图片的动画
                                                local symbolType = symbol.symbolType
                                                local symbolSpr = symbol.symbolSpr
                                                local SymbolplayNum = moveSymbolNum
                                                performWithDelay(
                                                    self,
                                                    function()
                                                        if SymbolplayNum == 1 then
                                                            self:palyOneSymbolScoreImgAction(
                                                                symbol.symbolType,
                                                                "end",
                                                                false,
                                                                function()
                                                                    self:hideOneSymbolScoreImg(symbolType)
                                                                end
                                                            )
                                                        end
                                                        symbolSpr:hideSpine()
                                                        symbolSpr:playAction(
                                                            "fight",
                                                            false,
                                                            function()
                                                                local type = 3
                                                                if symbol.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
                                                                    type = 1
                                                                elseif symbol.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
                                                                    type = 2
                                                                elseif symbol.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
                                                                    type = 3
                                                                elseif symbol.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
                                                                    type = 3
                                                                end

                                                                -- 根据类型播放飞金币效果
                                                                self:flyCoins(type, cc.p(symbolSpr:getPosition()))
                                                                -- 小怪兽掉落动画
                                                                self:downSymblos(
                                                                    symbolSpr,
                                                                    downTime,
                                                                    function()
                                                                        symbolSpr:removeFromParent()
                                                                    end
                                                                )
                                                            end
                                                        )
                                                        table.remove(self.m_littleSymbolArray, i)
                                                        gLobalSoundManager:playSound(self.m_topSymbolAnimalSounds[symbolType])
                                                    end,
                                                    moveSymbolNum * 0.1
                                                )
                                            end
                                        end

                                        -- 打击完信号九
                                        local symbolSpr9 = v.symbolSpr
                                        performWithDelay(
                                            self,
                                            function()
                                                local oldPos = symbolSpr9:getPositionX()
                                                local newPos = cc.p(oldPos + self.m_littleSymbolSize * moveSymbolNum, symbolSpr9:getPositionY())
                                                -- symbolSpr9:playAction("idle2",true)
                                                self:actionMoveTo(
                                                    symbolSpr9,
                                                    0.5,
                                                    newPos,
                                                    function()
                                                    end
                                                )
                                            end,
                                            downTime * 2 + moveSymbolNum * 0.1
                                        )
                                    end,
                                    0.3
                                )
                            end
                        end

                        SymbolIndex = SymbolIndex + 1
                        -- 击打次数处于最后一轮
                        if SymbolIndex > #m_stcValidSymbol9 then
                            -- 结束打击状态
                            performWithDelay(
                                self,
                                function()
                                    effectData.p_isPlay = true
                                    self:playGameEffect()

                                    self:winCoinsLabAction()
                                end,
                                3.5
                            )
                        end
                    end,
                    timenum2 * 3
                )

                timenum2 = timenum2 + 1
            end
        end,
        time * 1 + 0.5
    )
end
-- 小信号玩法动画飞行模块
function CodeGameScreenTarzanFightMachine:flySymbolModel(effectData)
    local timenum1 = 1
    local symbolNum = 0
    local animalTypeArray = {}

    -- 获得小怪兽信息数组和数量
    animalTypeArray, symbolNum = self:getAllLittleMonsterInReels()

    -- 信号类型从1到n排序，
    table.sort(
        animalTypeArray,
        function(a, b)
            return a.symbolType < b.symbolType
        end
    )

    --算出本轮 最大飞行的个数
    if (symbolNum + #self.m_littleSymbolArray) < self.m_fullSymbolNum then
        symbolNum = self.m_fullSymbolNum
    else
        symbolNum = self.m_fullSymbolNum - #self.m_littleSymbolArray
    end

    local symbolCheckNum = 0 -- 结束索引
    for k, v in pairs(animalTypeArray) do
        local symbolType = v.symbolType

        symbolCheckNum = symbolCheckNum + 1

        -- 开始播放飞行动画
        performWithDelay(
            self,
            function()
                -- 创建小怪兽
                local pos = cc.p(self:getFlayEndPos(symbolType))
                local endPos = pos
                local index = self:getNewSymbolIndex(symbolType) -- 获取新添小怪兽在存储数组的位置
                self:createSymbolInFs(symbolType, index) -- 根据位置索引创建小怪兽
                self.m_littleSymbolArray[index].symbolSpr:setPosition(pos) -- 设置小怪兽位置
                local littleMonster = self.m_littleSymbolArray[index].symbolSpr
                littleMonster:setVisible(false)
                self:restSymbolZorder() -- 重置所有小怪兽Zorder
                self:restLittleTopSymbolYPos() -- 重置所有小怪兽Y坐标

                gLobalSoundManager:playSound(self.m_topSymbolMoveSounds[symbolType])

                --幻影动画
                local symbolNode = self:getReelParent(v.j):getChildByTag(self:getNodeTag(v.j, v.i, SYMBOL_NODE_TAG))
                local worldPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
                local startPos = self.m_root:convertToNodeSpace(worldPos)
                local csbPath = self:getFlaySymbolCsbPath(symbolType)
                local func = function()
                    littleMonster:setVisible(true)
                    symbolNode:runAnim("idleframe")
                    -- 顶部分数小图片
                    local Score = self:getOneSymbolScoreImgNewScore(symbolType)
                    self:setOneSymbolScoreImgScore(symbolType, Score)
                    self:showOneSymbolScoreImg(symbolType)
                    self:setAllSymbolScoreImgZorder()
                    self:palyOneSymbolScoreImgAction(symbolType, "show")
                end
                self:flySymblos(startPos, endPos, func, csbPath)
            end,
            timenum1 * 1
        )

        -- 重置所有小分数图片的位置
        performWithDelay(
            self,
            function()
                self:setOneSymbolAllScoreImgPos()
            end,
            timenum1 * 1 + 0.1
        )

        -- 结束击打状态判断
        if symbolCheckNum >= symbolNum then -- 是填充满的状态 小怪兽>16
            performWithDelay(
                self,
                function()
                    local symbolSpr = nil
                    for k, v in pairs(self.m_littleSymbolArray) do
                        if v.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                            symbolSpr = v.symbolSpr
                        end
                    end
                    symbolSpr:setVisible(false)
                    -- 下落动画
                    self:downHeroSymblos(
                        symbolSpr,
                        1,
                        function()
                            symbolSpr:removeFromParent()
                            -- 直接结束
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end,
                timenum1 * 1 + 1
            )
            return
        end

        timenum1 = timenum1 + 1
    end

    if self.m_FreeSpinOverFullStates then
        -- print("这把小怪兽>16，泰山打击动画模块不播放")
    else
        -- 泰山打模块
        self:TarzanFightSymbolModel(effectData, timenum1) --
    end
end
-- 返回所有 需要被击打的小怪兽的位置和数量
function CodeGameScreenTarzanFightMachine:getAllLittleMonsterInReels()
    local animalTypeArray = {}
    local symbolNum = 0
    for j = 1, self.m_iReelColumnNum, 1 do
        for i = 1, self.m_iReelRowNum, 1 do
            local symbolType = self.m_stcValidSymbolMatrix[i][j]

            if
                symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 or
                    symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5
             then
                symbolNum = symbolNum + 1
                local symbolTypeArray = {}
                symbolTypeArray.symbolType = symbolType
                symbolTypeArray.j = j
                symbolTypeArray.i = i

                table.insert(animalTypeArray, symbolTypeArray)
            end
        end
    end

    return animalTypeArray, symbolNum
end
-- 获取当前战斗小信号最小的信号类型
function CodeGameScreenTarzanFightMachine:getLittleSymbolArrayMaxType()
    local maxSymbol = 0

    for k, v in pairs(self.m_littleSymbolArray) do
        if v.symbolType ~= 0 and v.symbolType >= maxSymbol then
            maxSymbol = v.symbolType
        end
    end

    return maxSymbol
end

-- 获取上方小信号的位置
function CodeGameScreenTarzanFightMachine:getFlayEndPos(symbolType)
    local pos = nil
    for k, v in pairs(self.m_littleSymbolArray) do
        if v.symbolType >= symbolType and not pos then
            pos = cc.p(v.symbolSpr:getPosition())
        end
        if pos then
            local oldPos = v.symbolSpr:getPositionX()
            local newPos = cc.p(oldPos - self.m_littleSymbolSize, v.symbolSpr:getPositionY())
            self:actionMoveTo(v.symbolSpr, 0.1, newPos)
        end
    end

    if pos == nil then
        local symbolTypeInfo = self.m_littleSymbolArray[#self.m_littleSymbolArray]
        pos = cc.p(symbolTypeInfo.symbolSpr:getPosition())

        local oldPos = symbolTypeInfo.symbolSpr:getPositionX()
        local newPos = cc.p(oldPos - self.m_littleSymbolSize, symbolTypeInfo.symbolSpr:getPositionY())
        self:actionMoveTo(symbolTypeInfo.symbolSpr, 0.1, newPos)
    end

    return pos
end
-- 重置Zorder
function CodeGameScreenTarzanFightMachine:restSymbolZorder()
    for k, v in pairs(self.m_littleSymbolArray) do
        v.symbolSpr:setLocalZOrder(k * 10)
    end
end
-- 获取新创建小信号的位置
function CodeGameScreenTarzanFightMachine:getNewSymbolIndex(symbolType)
    local index = nil
    for k, v in pairs(self.m_littleSymbolArray) do
        if v.symbolType >= symbolType and not index then
            index = k
        end
    end
    if index == nil then
        index = #self.m_littleSymbolArray
    end
    return index
end

-- 开始fs下泰山开打动画
function CodeGameScreenTarzanFightMachine:beginChangeFightState(colIdx, rowIdx)
    self.m_beginFight = true

    -- 击打fs状态
    self:runCsbAction("fs_idle", true)

    local symbolNode = self:getReelParent(colIdx):getChildByTag(self:getNodeTag(colIdx, rowIdx, SYMBOL_NODE_TAG))

    if symbolNode then
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( symbolNode.p_cloumnIndex,"TarzanFightSounds/sound_TarzanFight_Tarzan_show.mp3" )
        else
            gLobalSoundManager:playSound("TarzanFightSounds/sound_TarzanFight_Tarzan_show.mp3")
        end
        
        symbolNode:runAnim(
            "buling",
            false,
            function()
                symbolNode:runAnim("idle", true)
            end
        )

        self:createOneActionSymbol(symbolNode, "buling")
    end
end
-- 开始fs下泰山开打动画
function CodeGameScreenTarzanFightMachine:beginChangeMonsterFightState()
    if self.m_beginFight then
        for colIdx = 1, self.m_iReelColumnNum, 1 do
            for rowIdx = 1, self.m_iReelRowNum, 1 do
                local symbolNode = self:getReelParent(colIdx):getChildByTag(self:getNodeTag(colIdx, rowIdx, SYMBOL_NODE_TAG))
                if symbolNode then
                    local symbolType = self.m_stcValidSymbolMatrix[rowIdx][colIdx]
                    if
                        symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 or
                            symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5
                     then
                        symbolNode:runAnim("idle", true)
                    end
                end
            end
        end
    end
end
-- 重置fs下泰山开打动画
function CodeGameScreenTarzanFightMachine:changeFightState()
    -- 普通fs状态
    self:runCsbAction("Freespin")

    for j = 1, self.m_iReelColumnNum, 1 do
        for i = 1, self.m_iReelRowNum, 1 do
            local symbolType = self.m_stcValidSymbolMatrix[i][j]

            if
                symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 or
                    symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 or
                    symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5
             then
                local symbolNode = self:getReelParent(j):getChildByTag(self:getNodeTag(j, i, SYMBOL_NODE_TAG))

                if symbolNode then
                    symbolNode:runAnim("idleframe")
                end
            end
        end
    end
end
-- 单列滚动结束调用
function CodeGameScreenTarzanFightMachine:checkOneReelDown(reelCol)
    for iRow = 1, self.m_iReelRowNum, 1 do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            self:beginChangeFightState(reelCol, iRow)
        end
    end

    self:beginChangeMonsterFightState()
end
-- 单列滚动结束调用
function CodeGameScreenTarzanFightMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self, reelCol)

    if self.m_bProduceSlots_InFreeSpin == true then
        -- 判断是否触发泰山打动画
        self:checkOneReelDown(reelCol)
    end
end

--[[
    @desc: 根据赢钱线的类型， 返回最终赢钱线的类型
    time:2018-12-27 21:42:12
    @return:
]]
function CodeGameScreenTarzanFightMachine:getWinLineSymboltType(winLineData, lineInfo)
    local iconsPos = winLineData.p_iconPos
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    local isNineSymbol = false
    for posIndex = 1, #iconsPos do
        local posData = iconsPos[posIndex]

        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData -- 连线元素的 pos信息

        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            enumSymbolType = symbolType
        end

        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            isNineSymbol = true
        end
    end
    if isNineSymbol == true then
        enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9
    end

    return enumSymbolType
end

--[[
    @desc: 检测是否获胜结束
    time:2019-01-03 20:51:03
]]
function CodeGameScreenTarzanFightMachine:checkOverIsWin()
    if #self.m_littleSymbolNetData == 1 and self.m_littleSymbolNetData[1] == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        globalData.slotRunData.freeSpinCount = 0

        return true
    end

    return false
end
--[[
    @desc: 检测是否失败结束
    time:2019-01-03 20:51:16
]]
function CodeGameScreenTarzanFightMachine:checkOverIsFaild()
    local isFullOver = false

    if #self.m_littleSymbolNetData >= self.m_fullSymbolNum then -- 因为得包括 泰山 所以是17个
        globalData.slotRunData.freeSpinCount = 0
        isFullOver = true
    end
    return isFullOver
end

function CodeGameScreenTarzanFightMachine:checkChangeFsCount()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount ~= nil and globalData.slotRunData.freeSpinCount > 0 then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        globalData.userRate:pushFreeSpinCount(1)
    end
end

-- 重置小信号网络数据
function CodeGameScreenTarzanFightMachine:restHitNetData(isFullOver)
    if isFullOver then -- 如果是填满状态的结束 那就移除元素到还剩17位
        -- dump(self.m_littleSymbolNetData,"填满删除")
        local cutIndex = #self.m_littleSymbolNetData - self.m_fullSymbolNum
        -- print("填满删除 cutIndex "..cutIndex)
        for i = #self.m_littleSymbolNetData, 1, -1 do
            if i <= cutIndex then
                table.remove(self.m_littleSymbolNetData, i)
            end
        end
    else -- 如果不是填满状态的freeSpin结束
        -- 正常移除数据
        local symbolNum_9 = self:getSymbolCountWithReelResult(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
        for i = 1, symbolNum_9 do
            local maxSymbol = 0
            if #self.m_littleSymbolNetData == 1 and self.m_littleSymbolNetData[1] == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                break
            end
            for i = #self.m_littleSymbolNetData, 1, -1 do
                if self.m_littleSymbolNetData[i] ~= 0 and self.m_littleSymbolNetData[i] > maxSymbol then
                    maxSymbol = self.m_littleSymbolNetData[i]
                end
            end

            for i = #self.m_littleSymbolNetData, 1, -1 do
                if maxSymbol == self.m_littleSymbolNetData[i] then
                    table.remove(self.m_littleSymbolNetData, i)
                end
            end
        end
    end
end
function CodeGameScreenTarzanFightMachine:isInArray(type, array)
    local isNotIn = true
    for k, v in pairs(array) do
        if v == type then
            isNotIn = false
            break
        end
    end

    return isNotIn
end

function CodeGameScreenTarzanFightMachine:MachineRule_afterNetWorkLineLogicCalculate()
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_littleSymbolNetData = self:sortNetDataToLocalData(self.m_runSpinResultData.p_fsExtraData.littleSymbolNetData)

        local isWinOver = self:checkOverIsWin()
        if isWinOver == true then
            globalData.slotRunData.freeSpinCount = 0
        else
            local isFaildOver = self:checkOverIsFaild()
            if isFaildOver == true then
                globalData.slotRunData.freeSpinCount = 0
            end
        end

        self:updateHitSymbolScore()
    end
end

function CodeGameScreenTarzanFightMachine:updateHitSymbolScore()
    if self.m_runSpinResultData.p_fsExtraData ~= nil and self.m_runSpinResultData.p_fsExtraData.wins ~= nil and #self.m_runSpinResultData.p_fsExtraData.wins == 0 then
        self.m_littleSymbolOnceScore = 0

        for k, v in pairs(self.m_runSpinResultData.p_fsExtraData.wins) do
            self.m_littleSymbolOnceScore = self.m_littleSymbolOnceScore + v
        end

        for i = 1, #self.m_runSpinResultData.p_fsExtraData.wins do
            self.m_littleSymbolOnceScore = self.m_littleSymbolOnceScore + self.m_runSpinResultData.p_fsExtraData.wins[i]
        end
    else
        self.m_littleSymbolOnceScore = 0
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenTarzanFightMachine:levelFreeSpinEffectChange(isShowAction)
end

function CodeGameScreenTarzanFightMachine:changeBgToFreeSpin()
    self:runCsbAction("ToFreeSpin")
    local objectOne = {}
    objectOne[1] = "change_freespin"
    objectOne[2] = false
    objectOne[3] = function()
        self.m_BgWater:setVisible(true)
        self.m_BgWater:playAction(true)
    end
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, objectOne)
end

function CodeGameScreenTarzanFightMachine:addLastWinSomeEffect()
    BaseMachine.addLastWinSomeEffect(self)
    if self.m_bProduceSlots_InFreeSpin == true then
        -- 处于 fs feature 玩法中 不触发bigwin  和 megawin
        self:removeEffectByType(GameEffect.EFFECT_MEGAWIN)
        self:removeEffectByType(GameEffect.EFFECT_BIGWIN)
    end
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenTarzanFightMachine:levelFreeSpinOverChangeEffect(content)
end

-- 创建顶部小信号
function CodeGameScreenTarzanFightMachine:createSymbolInFs(symbolType, index)
    local symbolpath = nil
    local symbolSpr = nil
    local actionType = nil

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        symbolpath = "Socre_TarzanFight_9"
        symbolSpr = util_createView("CodeTarzanFightSrc.TzrzanFightSymbol", symbolpath, TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
        actionType = self.m_viewAction
        symbolSpr:setSymbolPosition(cc.p(-80, 10))
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        symbolpath = "Socre_TarzanFight_8"
        symbolSpr = util_createView("CodeTarzanFightSrc.TzrzanFightSymbol", symbolpath, TAG_SYMBOL_TYPE.SYMBOL_SCORE_8)
        actionType = self.m_viewAction
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        symbolpath = "Socre_TarzanFight_7"
        symbolSpr = util_createView("CodeTarzanFightSrc.TzrzanFightSymbol", symbolpath, TAG_SYMBOL_TYPE.SYMBOL_SCORE_7)
        actionType = self.m_viewAction
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        symbolpath = "Socre_TarzanFight_6"
        symbolSpr = util_createView("CodeTarzanFightSrc.TzrzanFightSymbol", symbolpath, TAG_SYMBOL_TYPE.SYMBOL_SCORE_6)
        actionType = self.m_viewAction
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
        symbolpath = "Socre_TarzanFight_5"
        symbolSpr = util_createView("CodeTarzanFightSrc.TzrzanFightSymbol", symbolpath, TAG_SYMBOL_TYPE.SYMBOL_SCORE_5)
        actionType = self.m_viewAction
    end

    -- util_spinePlay(spNode, "animation", false)
    symbolSpr:setScale(self.m_littleSymbolScaleSize)
    self:findChild("node_little_symbol"):addChild(symbolSpr)
    local symbolinfo = {}
    symbolinfo.symbolType = symbolType
    symbolinfo.symbolSpr = symbolSpr
    symbolinfo.actionType = actionType
    if index then
        table.insert(self.m_littleSymbolArray, index, symbolinfo)
    else
        self.m_littleSymbolArray[#self.m_littleSymbolArray + 1] = symbolinfo
    end
end

-- 根据index显示某个小信号
function CodeGameScreenTarzanFightMachine:showOneSymbolFromIndex(index)
    for k, v in pairs(self.m_littleSymbolArray) do
        if k == index then
            v.symbolSpr:setVisible(true)
        end
    end
end
-- 根据index隐藏某个小信号
function CodeGameScreenTarzanFightMachine:hideOneSymbolFromIndex(index)
    for k, v in pairs(self.m_littleSymbolArray) do
        if k == index then
            v.symbolSpr:setVisible(false)
        end
    end
end
-- 根据type显示某类小信号
function CodeGameScreenTarzanFightMachine:showOneSymbolFromSymbolType(symbolType)
    for k, v in pairs(self.m_littleSymbolArray) do
        if v.symbolType == symbolType then
            v.symbolSpr:setVisible(true)
        end
    end
end
-- 根据type隐藏某类小信号
function CodeGameScreenTarzanFightMachine:hideOneSymbolFromSymbolType(symbolType)
    for k, v in pairs(self.m_littleSymbolArray) do
        if v.symbolType == symbolType then
            v.symbolSpr:setVisible(false)
        end
    end
end

-- ---- 获取 FlaySymbolCsbPath
function CodeGameScreenTarzanFightMachine:getFlaySymbolCsbPath(symbolType)
    local csbpath = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        csbpath = "Socre_TarzanFight_9"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        csbpath = "Socre_TarzanFight_8.csb"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        csbpath = "Socre_TarzanFight_7.csb"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        csbpath = "Socre_TarzanFight_6.csb"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
        csbpath = "Socre_TarzanFight_5.csb"
    end
    return csbpath
end
-- 初始化顶部小信号位置
function CodeGameScreenTarzanFightMachine:initLittleTopSymbolPos()
    for k, v in pairs(self.m_littleSymbolArray) do
        v.symbolSpr:setPositionX(self.m_littleSymbolBeginPosNode:getPositionX() - self.m_littleSymbolSize * k + self.m_littleSymbolSize * 0.5)

        if v.actionType == self.m_spineAction then
            v.symbolSpr:setPositionY(self.m_littleSymbolBeginPosNode:getPositionY() + self.m_littleSymbolSpinYPos)
        else
            v.symbolSpr:setPositionY(self.m_littleSymbolBeginPosNode:getPositionY())
        end
    end
    self:setOneSymbolAllScoreImgPos()
end

function CodeGameScreenTarzanFightMachine:restLittleTopSymbolYPos()
    for k, v in pairs(self.m_littleSymbolArray) do
        if v.actionType == self.m_spineAction then
            v.symbolSpr:setPositionY(self.m_littleSymbolBeginPosNode:getPositionY() + self.m_littleSymbolSpinYPos)
        else
            v.symbolSpr:setPositionY(self.m_littleSymbolBeginPosNode:getPositionY())
        end
    end
end

-- c----------处理小信号分数图片 -------
-- 隐藏所有 小信号分数图片
function CodeGameScreenTarzanFightMachine:hideAllSymbolScoreImg()
    for k, v in pairs(self.m_littleSymbolScoreImgArray) do
        v:setVisible(false)
    end
end

function CodeGameScreenTarzanFightMachine:setAllSymbolScoreImgZorder()
    for k, v in pairs(self.m_littleSymbolScoreImgArray) do
        v:setLocalZOrder(k * 100)
    end
end

-- 隐藏某个 小信号分数图片
function CodeGameScreenTarzanFightMachine:hideOneSymbolScoreImg(symboltype)
    for k, v in pairs(self.m_littleSymbolScoreImgArray) do
        if k == symboltype then
            v:setVisible(false)
            v:setPosition(cc.p(2000, 2000))
        end
    end
end

-- 显示某个小信号分数图片
function CodeGameScreenTarzanFightMachine:showOneSymbolScoreImg(symboltype)
    for k, v in pairs(self.m_littleSymbolScoreImgArray) do
        if symboltype == k then
            v:setVisible(true)
        end
    end
end
-- 获取新位置
function CodeGameScreenTarzanFightMachine:getOneSymbolScoreImgNewXPos(symboltype)
    local ScoreImgXPos = self.m_littleSymbolBeginPosNode:getPositionX()
    -- for k,v in pairs(self.m_littleSymbolArray) do
    --     if v.symbolType == symboltype then
    --       if ScoreImgXPos>v.symbolSpr:getPositionX() then
    --             ScoreImgXPos = v.symbolSpr:getPositionX()
    --       end
    --     end
    -- end
    local ScoreImgXPosArray = {}
    for k, v in pairs(self.m_littleSymbolArray) do
        if v.symbolType == symboltype then
            table.insert(ScoreImgXPosArray, v.symbolSpr:getPositionX())
        end
    end
    if #ScoreImgXPosArray == 1 then
        ScoreImgXPos = ScoreImgXPosArray[1]
    else
        ScoreImgXPos = (ScoreImgXPosArray[1] + ScoreImgXPosArray[#ScoreImgXPosArray]) / 2
    end

    return ScoreImgXPos
end

-- 获取当前钱数
function CodeGameScreenTarzanFightMachine:getOneSymbolScoreImgNewScore(symboltype)
    local ScoreImgNum = 0
    local score = 0
    for k, v in pairs(self.m_littleSymbolArray) do
        if v.symbolType == symboltype then
            ScoreImgNum = ScoreImgNum + 1
        end
    end

    score = self.m_configData:getHitScoreBySymbolType(symboltype, ScoreImgNum)

    return score
end
-- 设置所有小信号分数图片位置
function CodeGameScreenTarzanFightMachine:setOneSymbolAllScoreImgPos()
    for k, v in pairs(self.m_littleSymbolArray) do
        local posX = self:getOneSymbolScoreImgNewXPos(v.symbolType)
        self:setOneSymbolScoreImgPos(v.symbolType, posX)
    end
end

-- 设置某个小信号分数图片位置
function CodeGameScreenTarzanFightMachine:setOneSymbolScoreImgPos(symboltype, posX)
    for k, v in pairs(self.m_littleSymbolScoreImgArray) do
        if symboltype == k then
            v:setPosition(cc.p(posX, self.m_littleSymbolBeginPosNode:getPositionY() + 55))
        end
    end
end
-- 播放某个某个小信号分数图片的动画
function CodeGameScreenTarzanFightMachine:palyOneSymbolScoreImgAction(symboltype, name, isloop, func)
    for k, v in pairs(self.m_littleSymbolScoreImgArray) do
        if symboltype == k then
            v:showOneTxtImg(symboltype)
            v:playShowAction(name, isloop, func)
        end
    end
end
-- 设置某个小信号分数图片的分数
function CodeGameScreenTarzanFightMachine:setOneSymbolScoreImgScore(symboltype, score)
    for k, v in pairs(self.m_littleSymbolScoreImgArray) do
        if symboltype == k then
            v:setOneTxtScore(symboltype, score)
        end
    end
end

-- 更新freeSpin次数
function CodeGameScreenTarzanFightMachine:updateFreeSpinTimes()
    self:findChild("m_lb_coins_left"):setString(self.m_FreeSpinTimes)
    self:findChild("m_lb_coins_right"):setString(self.m_FreeSpinTimes)
end
---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenTarzanFightMachine:MachineRule_SpinBtnCall()
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_FreeSpinTimes = self.m_FreeSpinTimes + 1
        self:updateFreeSpinTimes()
        self:changeFightState()
    end
    self.m_beginFight = nil
    self.m_flyCoinsNode:removeAllChildren()

    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE then
        isNotifyUpdateTop = false
    end
    -- 移除非大赢飞机币
    if self.updateScoreScheduleID then
        self:winCoinsLabAction()
        scheduler.unscheduleGlobal(self.updateScoreScheduleID)
        self.updateScoreScheduleID = nil
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end

    -- 移除大赢分拨飞金币延时函数
    self:unSelfScheduleGlobalForBigFlyCoins()

    -- gLobalSoundManager:stopAudio(self.m_winSoundsId)
    gLobalSoundManager:setBackgroundMusicVolume(1)
    -- self.m_winSoundsId = nil

    return false
end

function CodeGameScreenTarzanFightMachine:unSelfScheduleGlobalForBigFlyCoins()
    local isPost = false
    if self.updateBigScoreScheduleID_1 then
        scheduler.unscheduleGlobal(self.updateBigScoreScheduleID_1)
        self.updateBigScoreScheduleID_1 = nil
        isPost = true
    end
    if self.updateBigScoreScheduleID_2 then
        scheduler.unscheduleGlobal(self.updateBigScoreScheduleID_2)
        self.updateBigScoreScheduleID_2 = nil
        isPost = true
    end
    if self.updateBigScoreScheduleID_3 then
        scheduler.unscheduleGlobal(self.updateBigScoreScheduleID_3)
        self.updateBigScoreScheduleID_3 = nil
        isPost = true
    end
    if self.updateBigScoreScheduleID_4 then
        scheduler.unscheduleGlobal(self.updateBigScoreScheduleID_4)
        self.updateBigScoreScheduleID_4 = nil
        isPost = true
    end

    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE then
        isNotifyUpdateTop = false
    end

    if isPost then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

-- --------------fs 开始  结束界面  -----------
-- 创建 FsStartView
function CodeGameScreenTarzanFightMachine:createFsStartView(effectData)
    for i = 1, 4 do
        self:createSymbolInFs(i)
    end
    self:createSymbolInFs(0)
    self:initLittleTopSymbolPos()

    for i = 1, 4 do
        local Score = self:getOneSymbolScoreImgNewScore(i)
        self:setOneSymbolAllScoreImgPos()
        self:setOneSymbolScoreImgScore(i, Score)
    end
    for i = 1, 5 do
        -- 根据type隐藏某类小信号
        self:hideOneSymbolFromSymbolType(i - 1)
    end

    self.m_FreeSpinTimes = 0
    self:updateFreeSpinTimes()

    self.m_TzrzanFightReelsHide:playAction1(false)
    self:findChild("hide_panel"):setScale(self.m_machineRootScale)
    self:hideLocalReels()

    performWithDelay(
        self,
        function()
            performWithDelay(
                self,
                function()
                    self:scaleMainLayer(self.m_scaleLocalMainSize)
                end,
                0.5
            )

            gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_show.mp3")
            self.m_tzrzanFlayAction:setRootScale(self.m_machineRootScale)
            self.m_tzrzanFlayAction:setVisible(true)
            self.m_tzrzanFlayAction:playAction(
                false,
                function()
                    self:changeBgToFreeSpin()

                    self.m_TzrzanFightReelsHide:playAction(false)
                    self:findChild("hide_panel"):setScale(self.m_machineRootScale)
                    self:showLocalReels()

                    performWithDelay(
                        self,
                        function()
                            gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_star_view.mp3")
                        end,
                        0.5
                    )

                    self.m_tzrzanFlayAction:setVisible(false)

                    self.m_FreeSpinStartView = util_createView("CodeTarzanFightSrc.TarzanFightFreeSpinStart", self)
                    gLobalViewManager:showUI(self.m_FreeSpinStartView)
                    self.m_FreeSpinStartView:setMachineFlaySymbol(self.m_littleSymbolArray)
                    self.m_FreeSpinStartView:setCallBackFun(
                        function()
                            performWithDelay(
                                self,
                                function()
                                    performWithDelay(
                                        self,
                                        function()
                                            self:triggerFreeSpinCallFun()
                                            effectData.p_isPlay = true
                                            self:playGameEffect()
                                        end,
                                        0.5
                                    )
                                end,
                                0.5
                            )
                        end
                    )
                end
            )
        end,
        0.7
    )
end

function CodeGameScreenTarzanFightMachine:showLucklyView()
    self:showDialog("FreeSpinStart_lucky_you", nil, nil, BaseDialog.AUTO_TYPE_ONLY)
end

function CodeGameScreenTarzanFightMachine:getOneSymbolNum(symbolType)
    local num = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            if self.m_runSpinResultData.p_reels[iRow][iCol] == symbolType then
                num = num + 1
            end
        end
    end
    return num
end

function CodeGameScreenTarzanFightMachine:showFreeSpinView(effectData)
    self:clearCurMusicBg()
    local witeTime = 0.01
    local tarzanCount = self:getOneSymbolNum(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    if tarzanCount < 3 then
        gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_trigger_fs_rodom.mp3")
        witeTime = 1.5
    end

    performWithDelay(
        self,
        function()
            if tarzanCount < 4 then
                gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_open_view.mp3")
                self:showLucklyView()
                performWithDelay(
                    self,
                    function()
                        self:createFsStartView(effectData)
                    end,
                    2
                )
            else
                self:createFsStartView(effectData)
            end
        end,
        witeTime
    )
end

function CodeGameScreenTarzanFightMachine:showFreeSpinOverView()
    local time = 1.5
    if #self.m_littleSymbolArray >= self.m_fullSymbolNum then
        time = 0.1
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    performWithDelay(
        self,
        function()
            if self.m_littleSymbolArray and #self.m_littleSymbolArray >= self.m_fullSymbolNum then -- 失败（泰山被击落）
                gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_open_view.mp3")
            else
                gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_open_win_view.mp3")
            end

            self.m_FreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            local view =
                self:showFreeSpinOver(
                globalData.slotRunData.lastWinCoin,
                self.m_FreeSpinTimes,
                function()
                    self.m_TzrzanFightReelsHide:playAction1(false)
                    self:findChild("hide_panel"):setScale(self.m_machineRootScale)
                    self:hideLocalReels()

                    performWithDelay(
                        self,
                        function()
                            performWithDelay(
                                self,
                                function()
                                    self:restAnimalAction()
                                    self:scaleMainLayer(0)
                                    --self:changeFightState()
                                    self:hideAllSymbolScoreImg()
                                    self:findChild("node_little_symbol"):removeAllChildren()
                                    self.m_littleSymbolArray = {}
                                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "nomal")
                                end,
                                0.5
                            )

                            performWithDelay(
                                self,
                                function()
                                    self.m_TzrzanFightReelsHide:playAction(false)
                                    self:findChild("hide_panel"):setScale(self.m_machineRootScale)
                                    self:showLocalReels()
                                end,
                                0.7
                            )

                            self:runCsbAction("ToNomore")

                            self.m_BgWater:setVisible(false)
                            self.m_BgWater:playAction(false)

                            performWithDelay(
                                self,
                                function()
                                    self:triggerFreeSpinOverCallFun()
                                end,
                                1.5
                            )

                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

                            gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_leaf_close.mp3")
                            self.m_tzrzanFlayAction:setVisible(true)
                            self.m_tzrzanFlayAction:playEndAction(
                                false,
                                function()
                                    self.m_tzrzanFlayAction:setVisible(false)
                                    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                                end
                            )
                        end,
                        0.7
                    )
                end
            )

            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node}, 630)
        end,
        0.1 + time
    )
end

function CodeGameScreenTarzanFightMachine:restAnimalAction()
    for j = 1, self.m_iReelColumnNum, 1 do
        for i = 1, self.m_iReelRowNum, 1 do
            local symbolType = self.m_stcValidSymbolMatrix[i][j]

            if
                symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 or
                    symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 or
                    symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5
             then
                local symbolNode = self:getReelParent(j):getChildByTag(self:getNodeTag(j, i, SYMBOL_NODE_TAG))

                if symbolNode then
                    symbolNode:runAnim("idleframe")
                end
            end
        end
    end
end

-- -----------------  动作类方法  --------------
-- movetoaction
function CodeGameScreenTarzanFightMachine:actionMoveTo(node, time, endpos, func)
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(time, cc.p(endpos))
    if func then
        actionList[#actionList + 1] =
            cc.CallFunc:create(
            function()
                func()
            end
        )
    end
    node:runAction(cc.Sequence:create(actionList))
end
--[[
    @desc: 飞信号方法
    author:{author}
    time:2018-12-26 11:32:59
]]
function CodeGameScreenTarzanFightMachine:flySymblos(startPos, endPos, func, csbPath)
    local flyNode = cc.Node:create()
    -- flyNode:setOpacity()
    self:findChild("node_little_symbol"):addChild(flyNode, 30000) -- 是否添加在最上层
    local time = 0.05
    local count = 5
    local flyTime = 0.3
    for i = 1, count do
        self:runFlySymblosAction(flyNode, time * i, flyTime, startPos, endPos, i, csbPath)
    end
    performWithDelay(
        flyNode,
        function()
            if func then
                func()
            end
            flyNode:removeFromParent()
        end,
        flyTime + time * count
    )
end

function CodeGameScreenTarzanFightMachine:runFlySymblosAction(flyNode, time, flyTime, startPos, endPos, index, csbPath)
    local actionList = {}
    local opacityList = {185, 145, 105, 65, 25, 1, 1, 1, 1, 1}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node
    if csbPath == "Socre_TarzanFight_9" then
        node = util_spineCreate("Socre_TarzanFight_9", true, true)
        -- self:addChild( self.m_spineAction)
        if node then
            util_spinePlay(node, "idle", false)
        end
    else
        node, csbAct = util_csbCreate(csbPath)
        util_csbPlayForKey(csbAct, "idle")
    end
    -- node:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(node, true)
    node:setOpacity(opacityList[index])
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            --     node:setVisible(true)
            node:runAction(cc.ScaleTo:create(flyTime, self.m_littleSymbolScaleSize))
        end
    )
    flyNode:addChild(node, 6 - index)
    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, cc.p(endPos))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:setLocalZOrder(index)
        end
    )

    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenTarzanFightMachine:downSymblos(symbolSpr, downTime, func)
    gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_top_symbol_down.mp3")

    local flyNode = cc.Node:create()
    -- flyNode:setOpacity()
    self:findChild("node_little_symbol"):addChild(flyNode, 30000) -- 是否添加在最上层
    local pos = cc.p(symbolSpr:getPosition())
    symbolSpr:runAction(cc.MoveTo:create(downTime, cc.p(pos.x, -100)))
    -- local newHeight = symbolSpr:getContentSize().height*self.m_littleSymbolScaleSize
    -- local spanTime = downTime/(pos.y/newHeight)
    schedule(
        flyNode,
        function()
            self:runDownSymblosAction(flyNode, cc.p(symbolSpr:getPosition()))
        end,
        0.03
    )
    performWithDelay(
        flyNode,
        function()
            self:addWaterEff(
                flyNode,
                cc.p(pos.x, 0),
                function()
                    if func then
                        func()
                    end
                    flyNode:removeFromParent()
                end
            )
        end,
        downTime
    )
end

function CodeGameScreenTarzanFightMachine:runDownSymblosAction(flyNode, pos)
    local node, csbAct = util_csbCreate("Socre_TarzanFight_fire.csb")
    util_csbPlayForKey(csbAct, "idle", true)

    node:setScale(self.m_littleSymbolScaleSize)
    flyNode:addChild(node)
    node:setPosition(pos)
    util_setCascadeOpacityEnabledRescursion(node, true)
    node:setOpacity(200)
    node:runAction(cc.FadeOut:create(0.35))
end

function CodeGameScreenTarzanFightMachine:addWaterEff(flyNode, pos, func)
    local node, csbAct = util_csbCreate("TarzanFight/shuihua.csb")
    util_csbPlayForKey(csbAct, "idle", false, func)

    flyNode:addChild(node)
    node:setPosition(pos)
end

function CodeGameScreenTarzanFightMachine:downHeroSymblos(symbolSpr, downTime, func)
    local flyNode = cc.Node:create()
    self:findChild("node_little_symbol"):addChild(flyNode, 30000) -- 是否添加在最上层
    local startPos = cc.p(symbolSpr:getPosition())
    local endPos = cc.p(startPos.x, -100)
    symbolSpr:runAction(cc.MoveTo:create(downTime, endPos))
    local time = 0.05
    local count = 5
    local flyTime = downTime - 0.1
    for i = 1, count do
        self:runDownHeroSymblosAction(flyNode, time * i, flyTime, startPos, endPos, i, "Socre_TarzanFight_9")
    end
    gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_top_symbol_hero_mover.mp3")

    performWithDelay(
        flyNode,
        function()
            self:addWaterEff(
                flyNode,
                cc.p(startPos.x, 0),
                function()
                    if func then
                        func()
                    end
                    flyNode:removeFromParent()
                end
            )
        end,
        downTime
    )
end

function CodeGameScreenTarzanFightMachine:runDownHeroSymblosAction(flyNode, time, flyTime, startPos, endPos, index, csbPath)
    local actionList = {}
    local opacityList = {185, 145, 105, 65, 25, 1, 1, 1, 1, 1}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node
    if csbPath == "Socre_TarzanFight_9" then
        node = util_spineCreate("Socre_TarzanFight_9", true, true)
        -- self:addChild( self.m_spineAction)
        if node then
            util_spinePlay(node, "idle", false)
        end
    else
        node, csbAct = util_csbCreate(csbPath)
        util_csbPlayForKey(csbAct, "idle")
    end

    node:setScale(self.m_littleSymbolScaleSize)
    util_setCascadeOpacityEnabledRescursion(node, true)
    node:setOpacity(opacityList[index])
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            --     node:setVisible(true)
        end
    )
    flyNode:addChild(node, 6 - index)
    node:setPosition(cc.p(startPos.x - 30, startPos.y))

    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, cc.p(endPos.x - 30, endPos.y))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:setLocalZOrder(index)
        end
    )

    node:runAction(cc.Sequence:create(actionList))
end

--type 1金 2银 3铜
function CodeGameScreenTarzanFightMachine:flyScoreCoins(type, startPos, couNum)
    local flyNode = cc.Node:create()
    self.m_flyScoreCoinsNode:addChild(flyNode, 30000) -- 是否添加在最上层
    local time = 0.1
    local count = 5
    if couNum then
        count = couNum
    end
    local flyTime = 1.5
    local endPos = flyNode:convertToNodeSpace(cc.p(display.cx, 0))
    performWithDelay(
        flyNode,
        function()
            for i = 1, count do
                performWithDelay(
                    flyNode,
                    function()
                        gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_top_symbol_coins.mp3")
                    end,
                    0.1 * i
                )
            end
        end,
        0.2
    )

    for i = 1, count do
        local newPos = cc.p(startPos.x + math.random(-100, 100), startPos.y)
        self:runFlyScoreCoinsAction(type, flyNode, time * i, flyTime, cc.p(endPos.x + math.random(-10, 10), 0), newPos)
    end
    performWithDelay(
        flyNode,
        function()
            if flyNode then
                flyNode:removeFromParent()
                flyNode = nil
            end
        end,
        flyTime + time * count
    )
end

function CodeGameScreenTarzanFightMachine:runFlyScoreCoinsAction(type, flyNode, time, flyTime, endPos, startPos)
    local path
    if type == 1 then
        path = "Coins/Coins1.csb"
    elseif type == 2 then
        path = "Coins/Coins2.csb"
    else
        path = "Coins/Coins3.csb"
    end
    local node, csbAct = util_csbCreate(path)
    util_csbPlayForKey(csbAct, "idle", true)

    flyNode:addChild(node)
    node:setScale(1)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time / 2)
    node:setVisible(false)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:setVisible(true)
            node:runAction(cc.RotateTo:create(flyTime, math.random(-720, 720)))
        end
    )

    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            local scaleLIst = {}
            scaleLIst[#scaleLIst + 1] = cc.ScaleTo:create(flyTime * 7 / 10, 1.5)
            scaleLIst[#scaleLIst + 1] = cc.ScaleTo:create(flyTime * 3 / 10, 1)
            node:runAction(cc.Sequence:create(scaleLIst))
        end
    )

    node:setPosition(startPos)

    local angle = 75
    local height = 10
    local radian = angle * math.pi / 180
    local q1x = startPos.x + (endPos.x - startPos.x) / 4
    local q1 = cc.p(q1x, height + startPos.y + math.cos(radian) * q1x)
    local q2x = startPos.x + (endPos.x - startPos.x) / 2.0
    local q2 = cc.p(q2x * 1.2, height + startPos.y + math.cos(radian) * q2x)
    actionList[#actionList + 1] = cc.EaseInOut:create(cc.BezierTo:create(flyTime, {q1, q2, endPos}), 1)

    node:runAction(cc.Sequence:create(actionList))
end

--type 1金 2银 3铜
function CodeGameScreenTarzanFightMachine:flyCoins(type, startPos, couNum)
    local flyNode = cc.Node:create()
    self.m_flyCoinsNode:addChild(flyNode, 30000) -- 是否添加在最上层
    local time = 0.05
    local count = 5
    if couNum then
        count = couNum
    end
    local flyTime = 2.5
    local endPos = flyNode:convertToNodeSpace(cc.p(display.cx, 0))
    performWithDelay(
        flyNode,
        function()
            for i = 1, count do
                performWithDelay(
                    flyNode,
                    function()
                        gLobalSoundManager:playSound("TarzanFightSounds/TarzanFight_top_symbol_coins.mp3")
                    end,
                    0.1 * i
                )
            end
        end,
        0.5
    )

    for i = 1, count do
        local newPos = cc.p(startPos.x + math.random(-50, 50), math.random(-100, 100))
        self:runFlyCoinsAction(type, flyNode, time * i, flyTime, cc.p(endPos.x + math.random(-10, 10), 0), newPos)
    end
    performWithDelay(
        flyNode,
        function()
            if flyNode then
                flyNode:removeFromParent()
                flyNode = nil
            end
        end,
        flyTime + time * count
    )
end

function CodeGameScreenTarzanFightMachine:runFlyCoinsAction(type, flyNode, time, flyTime, startPos, endPos)
    local path
    if type == 1 then
        path = "Coins/Coins1.csb"
    elseif type == 2 then
        path = "Coins/Coins2.csb"
    else
        path = "Coins/Coins3.csb"
    end
    local node, csbAct = util_csbCreate(path)
    util_csbPlayForKey(csbAct, "idle", true)

    flyNode:addChild(node)
    node:setScale(1)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    node:setVisible(false)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:setVisible(true)
            node:runAction(cc.RotateTo:create(flyTime, math.random(-720, 720)))
        end
    )
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            local scaleLIst = {}
            scaleLIst[#scaleLIst + 1] = cc.ScaleTo:create(flyTime * 3 / 10, 1.5)
            scaleLIst[#scaleLIst + 1] = cc.ScaleTo:create(flyTime * 7 / 10, 1)
            node:runAction(cc.Sequence:create(scaleLIst))
        end
    )

    node:setPosition(startPos)
    local angle = 45
    local height = 80
    local radian = angle * math.pi / 180
    local q1x = startPos.x + (endPos.x - startPos.x) / 4
    local q1 = cc.p(q1x, height + startPos.y + math.cos(radian) * q1x)
    local q2x = startPos.x + (endPos.x - startPos.x) / 2.0
    local q2 = cc.p(q2x, height + startPos.y + math.cos(radian) * q2x)
    actionList[#actionList + 1] = cc.EaseInOut:create(cc.BezierTo:create(flyTime, {q1, q2, endPos}), -1)
    node:runAction(cc.Sequence:create(actionList))
end

-- 获得所有小块的位置坐标
function CodeGameScreenTarzanFightMachine:getAllSymbolPos()
    local symbolPosInfo = {}

    -- 存储上 允许打击的信号九
    for iCol = 1, self.m_iReelColumnNum, 1 do
        for iRow = 1, self.m_iReelRowNum, 1 do
            local columnData = self.m_reelColDatas[iCol]
            local height = columnData.p_showGridH

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            pos.y = pos.y + (iRow - 0.5) * height * self.m_machineRootScale

            local iconPos = self:getPosReelIdx(iRow, iCol)
            symbolPosInfo[iconPos] = pos
        end
    end

    return symbolPosInfo
end

function CodeGameScreenTarzanFightMachine:winCoinsLabAction()
    -- local winScore = self.m_iOnceSpinLastWin
    -- if winScore == nil then
    --     winScore = 0
    -- end

    -- local totalBet = globalData.slotRunData:getCurTotalBet()
    -- local winRate = self.m_iOnceSpinLastWin / totalBet
    -- local showTime = 1
    -- if winRate <= 1 then
    --     showTime = 0.8
    -- elseif winRate > 1 and winRate <= 3 then
    --     showTime = 1.5
    -- elseif winRate > 3 and winRate <= 5 then
    --     showTime = 1.5
    -- elseif winRate > 5 then
    --     showTime = 2
    -- end

    -- local time1 = showTime * 15 / 100
    -- local time2 = showTime * 15 / 100
    -- local time3 = showTime * 70 / 100
    -- local action1 = cc.ScaleTo:create(time1, 1.5)
    -- local action2 = cc.ScaleTo:create(time2, 1)
    -- local action3 = cc.DelayTime:create(time3)
    -- self.m_bottomUI:findChild("font_last_win_value"):runAction(cc.Sequence:create(action1, action3, action2))
end

function CodeGameScreenTarzanFightMachine:createOneActionSymbol(endNode, actionName)
    if not endNode or not endNode.m_ccbName then
        return
    end

    local fatherNode = endNode
    endNode:setVisible(false)

    local node
    if endNode.m_ccbName == "Socre_TarzanFight_9" then
        node = util_spineCreate("Socre_TarzanFight_9", true, true)
    else
        node = util_createAnimation(endNode.m_ccbName .. ".csb")
    end

    local removeNode = function()
        node:removeFromParent()
    end
    local func = function()
        if fatherNode then
            fatherNode:setVisible(true)
        end
        if node then
            node:setVisible(false)
            scheduler.performWithDelayGlobal(
                function()
                    if removeNode then
                        removeNode()
                    end
                end,
                0.1,
                self:getModuleName()
            )
        end
    end
    if endNode.m_ccbName == "Socre_TarzanFight_9" then
        util_spinePlay(node, actionName, isloop)
        util_spineEndCallFunc(
            node,
            actionName,
            function()
                if func then
                    func()
                end
            end
        )
    else
        node:playAction(actionName, true, func)
    end

    -- node:setScale(self.m_machineRootScale)
    -- local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    -- local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    -- self:addChild(node , REEL_SYMBOL_ORDER.REEL_ORDER_1 + endNode.p_rowIndex)
    -- node:setPosition(pos)

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("node_little_symbol"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    self:findChild("node_little_symbol"):addChild(node, 1000 + endNode.p_rowIndex)
    node:setPosition(pos)

    return node
end


function CodeGameScreenTarzanFightMachine:getBottomUINode()
    return "CodeTarzanFightSrc.TzrzanFightGameBottomNode"
end

function CodeGameScreenTarzanFightMachine:getMaxContinuityScatterCol()
    local maxColIndex = 1
    local SymbolNum = 0
    local col4SymbolNum = 0

    for iCol = 2, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                SymbolNum = SymbolNum + 1

                if iCol == 4 then
                    col4SymbolNum = col4SymbolNum + 1
                end
            end
        end
    end

    if SymbolNum < 4 then
        if SymbolNum == 1 then
            maxColIndex = 2
        elseif SymbolNum == 2 then
            if col4SymbolNum == 1 then
                maxColIndex = 2
            else
                maxColIndex = 3
            end
        else
            if col4SymbolNum == 2 then
                maxColIndex = 2
            else
                maxColIndex = 3
            end
        end
    else
        maxColIndex = 4
    end

    return maxColIndex
end

-- 特殊信号下落时播放的音效
function CodeGameScreenTarzanFightMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil

        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end
            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1

            if slotNode.p_cloumnIndex > self:getMaxContinuityScatterCol() then
                return
            end

            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            end
        end

        if soundPath then
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( iCol,soundPath,slotNode.p_symbolType )
            else
                gLobalSoundManager:playSound(soundPath)
            end
        end
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenTarzanFightMachine:specialSymbolActionTreatment(node)
    if not node then
        return
    end

    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if node.p_cloumnIndex > self:getMaxContinuityScatterCol() then
            node:runAnim("idleframe")
        end
    end
end

-- 去除 scatter 显示 fiveofkind

function CodeGameScreenTarzanFightMachine:lineLogicWinLines()
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if #winLines > 0 then
        self:compareScatterWinLines(winLines)

        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()

            local enumSymbolType = self:getWinLineSymboltType(winLineData, lineInfo)

            if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
                if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
                elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                end
            end

            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())

            if lineInfo.iLineSymbolNum >= 5 then
                if enumSymbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isFiveOfKind = true
                end
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end
    end

    return isFiveOfKind
end

function CodeGameScreenTarzanFightMachine:slotReelDown()
    BaseMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenTarzanFightMachine:normalSpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    BaseSlotoManiaMachine.normalSpinBtnCall(self)
end

return CodeGameScreenTarzanFightMachine
