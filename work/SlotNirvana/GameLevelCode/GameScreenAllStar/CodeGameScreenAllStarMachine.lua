---
-- island li
-- 2019年1月26日
-- CodeGameScreenAllStarMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenAllStarMachine = class("CodeGameScreenAllStarMachine", BaseSlotoManiaMachine)

CodeGameScreenAllStarMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenAllStarMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

CodeGameScreenAllStarMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenAllStarMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenAllStarMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

-- 特殊bonus
CodeGameScreenAllStarMachine.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
CodeGameScreenAllStarMachine.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
CodeGameScreenAllStarMachine.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14
CodeGameScreenAllStarMachine.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15

CodeGameScreenAllStarMachine.SYMBOL_FIX_GRAND = 109 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 16
CodeGameScreenAllStarMachine.SYMBOL_RespinOver = 110 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 17
CodeGameScreenAllStarMachine.SYMBOL_OneBonusOver = 111 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 18
CodeGameScreenAllStarMachine.SYMBOL_OneBonusStart = 112 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 19
CodeGameScreenAllStarMachine.SYMBOL_MID_LOCK_TIP = 113 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 19

CodeGameScreenAllStarMachine.SYMBOL_Bonus_Spin = 1000 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 19

CodeGameScreenAllStarMachine.SYMBOL_Blank = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7 -- 空信号

CodeGameScreenAllStarMachine.SYMBOL_Wild_2 = 111
CodeGameScreenAllStarMachine.SYMBOL_Wild_3 = 112

CodeGameScreenAllStarMachine.SYMBOL_Big_Wild = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE

CodeGameScreenAllStarMachine.m_chipList = nil
CodeGameScreenAllStarMachine.m_playAnimIndex = 0
CodeGameScreenAllStarMachine.m_lightScore = 0
CodeGameScreenAllStarMachine.m_betLevel = 0

CodeGameScreenAllStarMachine.m_BonusScore = 0

-- bonus 动画类型
CodeGameScreenAllStarMachine.m_BonusEffect = {}
CodeGameScreenAllStarMachine.m_BonusNetData = {}

-- 是否是在bonus游戏中(判断特殊状态免费spin)
CodeGameScreenAllStarMachine.m_InBonus = nil

-- 构造函数
function CodeGameScreenAllStarMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_betLevel = nil
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0

    self.m_InBonus = false
    self.m_BonusEffect = {}
    self.m_BonusNetData = {}
    self.m_BonusScore = 0
    self.m_curChangeBg = nil
    self.m_fadeInTime = 0.5

    self.m_showFistBg = false

    self.isHaveBigWild = false --是否有大wild，用于bonus下第一次播buling

    self.bonusIndex = 0

    self.beerGirlWildList = {} --用于存储啤酒女玩法中固定的wild

    --init
    self:initGame()
end

function CodeGameScreenAllStarMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("AllStarConfig.csv", "LevelAllStarConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function CodeGameScreenAllStarMachine:scaleMainLayer()
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
        print("AllStar 不是竖版")
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + 8)
        util_csbScale(self.m_gameBg.m_csbNode, mainScale)
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAllStarMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "AllStar"
end

function CodeGameScreenAllStarMachine:initUI()
    self:setLocalNodeZOrder()

    self:runCsbAction("normal")
    self:initGameBg()
    self.m_gameBg:runCsbAction("normal", true)

    self:findChild("reel_side"):setVisible(true)
    self:findChild("reel_side_rs"):setVisible(false)

    self:findChild("zhezhao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 99)
    self:findChild("zhezhao"):setVisible(true)
    self:findChild("reel_side"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 101)
    self:findChild("reel_side_rs"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 101)
    self:findChild("Jackpot"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100)

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_jackPotBar = util_createView("CodeAllStarSrc.AllStarJackPotBar")
    self:findChild("Jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    self.m_jackPotBar:setVisible(true)

    self.m_gameLogo = util_createView("CodeAllStarSrc.AllStarBonusGameLogoView")
    self:findChild("logo"):addChild(self.m_gameLogo)
    self.m_gameLogo:findChild("double_bet_lab"):setString("10X")
    self.m_gameLogo:setVisible(false)

    -- self:findChild("bar"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10000)
    -- self.m_respinBar = util_createView("CodeAllStarSrc.AllStarRespinbarView")
    -- self:findChild("bar"):addChild(self.m_respinBar)
    -- self.m_respinBar:setVisible(false)

    local node_bar = self.m_bottomUI:findChild("node_bar")
    self.m_respinBar = util_createView("CodeAllStarSrc.AllStarRespinbarView")
    node_bar:addChild(self.m_respinBar)
    self.m_respinBar:setPosition(0, 37)
    self.m_respinBar:setVisible(false)

    self.m_reelsFalsh = util_createView("CodeAllStarSrc.AllStarReelsFalshView")
    self:findChild("daban"):addChild(self.m_reelsFalsh)
    self.m_reelsFalsh:setVisible(false)

    self.m_bonusTipView = util_createView("CodeAllStarSrc.AllStarBonusTipView")
    self:addChild(self.m_bonusTipView, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 10)
    self.m_bonusTipView:setPosition(0, 0)
    self.m_bonusTipView:setVisible(false)

    self.m_AllStarFrameLayer = cc.Node:create() -- cc.c4f(0,0,0,255),
    self.m_AllStarFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_AllStarFrameLayer:setPosition(cc.p(0, 0))
    self:findChild("root"):addChild(self.m_AllStarFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 102, 1)

    self:findChild("daban"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 103)

    self:findChild("tishikuangzhezhao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100000)

    self.m_AllSatrGuoChangView = util_spineCreate("AllStar_Bonus_guochang", true, true) --过场
    self:addChild(self.m_AllSatrGuoChangView, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_AllSatrGuoChangView:setPosition(display.width / 2, display.height / 2)
    self.m_AllSatrGuoChangView:setVisible(false)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            self:winCoinsSounds(params)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenAllStarMachine:winCoinsSounds(params)
    if self.m_bIsBigWin and (not self.m_InBonus) then
        return
    end

    -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
    local winCoin = params[1]

    if winCoin == 0 or winCoin == nil then
        return
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = winCoin / totalBet
    local soundIndex = 2
    local soundTime = 2
    if winRate <= 1 then
        soundIndex = 1
        soundTime = 2
    elseif winRate > 1 and winRate <= 3 then
        soundIndex = 2
        soundTime = 2
    elseif winRate > 3 and winRate <= 6 then
        soundIndex = 3
        soundTime = 3
    elseif winRate > 6 then
        soundIndex = 3
        soundTime = 3
    end
    if self.m_InBonus then
        local soundName = self:getWinSoundPath(soundIndex)
        gLobalSoundManager:playSound(soundName)
    else
        local soundName = "AllStarSounds/music_AllStar_last_win_" .. soundIndex .. ".mp3"
        gLobalSoundManager:playSound(soundName)
    end
end

function CodeGameScreenAllStarMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            self:playEnterGameSound("AllStarSounds/music_AllStar_enter.mp3")
            self.m_showFistBg = true
            -- scheduler.performWithDelayGlobal(function (  )
            --     if not self.m_InBonus then
            --         self:resetMusicBg()
            --         -- self:setMinMusicBGVolume()
            --     end

            -- end,1.5,self:getModuleName())
        end,
        0.1,
        self:getModuleName()
    )
end

function CodeGameScreenAllStarMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false and self.m_InBonus ~= true then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:MachineRule_initLocalGame()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function CodeGameScreenAllStarMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    if self.m_InBonus == true then
        self:initRandomSlotNodes()
    else
        self:initCloumnSlotNodesByNetData()
    end
end

-- 断线重连
function CodeGameScreenAllStarMachine:MachineRule_initGame()
    self:updateLocalLevelsData()
end

function CodeGameScreenAllStarMachine:checkSpecialGame(isOutLineEnter)
    local iscreat = true
    if self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
            iscreat = false
        end

        if not isOutLineEnter then
            if self.m_runSpinResultData.p_features then
                for k, v in pairs(self.m_runSpinResultData.p_features) do
                    -- 触发respin那一次创建 顶部 下部 半格小块
                    if v == RESPIN_MODE then
                        iscreat = true
                        break
                    end
                end
            end
        end
    end

    return iscreat
end

function CodeGameScreenAllStarMachine:MachineRule_initLocalGame()
    local iscreat = self:checkSpecialGame(true)

    if iscreat then
        local slotParentDatas = self.m_slotParents

        for index = 1, #slotParentDatas do
            local parentData = slotParentDatas[index]
            local nodeTop = self:getFixSymbol(index, 3, SYMBOL_NODE_TAG)
            local nodeDown = self:getFixSymbol(index, 1, SYMBOL_NODE_TAG)
            local notCreateTop = false
            local notCreateDown = false
            if nodeTop.p_symbolType and nodeTop.p_symbolType ~= self.SYMBOL_Blank then
                notCreateTop = true
            end
            if nodeDown.p_symbolType and nodeDown.p_symbolType ~= self.SYMBOL_Blank then
                notCreateDown = true
            end
            self:createResNode(parentData, nodeTop, notCreateTop, notCreateDown, true)
        end
    end

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial
        if respinSpecial then
            local rsreels = respinSpecial.reels
            if rsreels then
                local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag

                if respinSpecialFinishFlag and respinSpecialFinishFlag == "0" then
                    self:initRespinReelsForBonus()

                    self:playOneBonusGameStart()
                end
            end
        end
    end

    self.m_bottomUI:setMachine(self)
end

---- lighting 断线重连时，随机转盘数据
function CodeGameScreenAllStarMachine:respinModeChangeSymbolType()
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        local storedIcons = self.m_initSpinData.p_storedIcons
        if storedIcons == nil or #storedIcons <= 0 then
            return
        end

        local function isInArry(iRow, iCol)
            for k = 1, #storedIcons do
                local fix = self:getRowAndColByPos(storedIcons[k][1])
                if fix.iX == iRow and fix.iY == iCol then
                    return true
                end
            end
            return false
        end

        for iRow = 1, #self.m_initSpinData.p_reels do
            local rowInfo = self.m_initSpinData.p_reels[iRow]
            for iCol = 1, #rowInfo do
                if isInArry(#self.m_initSpinData.p_reels - iRow + 1, iCol) == false then
                -- rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % 8
                end
            end
        end
    end
end

-- 继承底层respinView
function CodeGameScreenAllStarMachine:getRespinView()
    return "CodeAllStarSrc.AllStarRespinView"
end
-- 继承底层respinNode
function CodeGameScreenAllStarMachine:getRespinNode()
    return "CodeAllStarSrc.AllStarRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAllStarMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return "Socre_AllStar_bonus1"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_AllStar_bonus4"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_AllStar_bonus3"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_AllStar_bonus2"
    elseif symbolType == self.SYMBOL_Wild_2 then
        return "Socre_AllStar_wild2"
    elseif symbolType == self.SYMBOL_Wild_3 then
        return "Socre_AllStar_wild3x"
    elseif symbolType == self.SYMBOL_Blank then
        return "Socre_AllStar_Blank"
    elseif symbolType == self.SYMBOL_Big_Wild then
        return "Socre_AllStar_wild3"
    elseif symbolType == self.SYMBOL_MID_LOCK then
        return "Socre_AllStar_bonus5"
    elseif symbolType == self.SYMBOL_ADD_WILD then
        return "Socre_AllStar_bonus6"
    elseif symbolType == self.SYMBOL_TWO_LOCK then
        return "Socre_AllStar_bonus8"
    elseif symbolType == self.SYMBOL_Double_BET then
        return "Socre_AllStar_bonus7"
    end

    return nil
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenAllStarMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local score = nil
    local idNode = nil

    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil or score < 0 then
        return self:getRandomSymbolType()
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_MID_LOCK then
        score = "bonus"
    elseif symbolType == self.SYMBOL_ADD_WILD then
        score = "bonus"
    elseif symbolType == self.SYMBOL_TWO_LOCK then
        score = "bonus"
    elseif symbolType == self.SYMBOL_Double_BET then
        score = "bonus"
    end

    return score
end

function CodeGameScreenAllStarMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenAllStarMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            if score == 0 then
                score = 1
            end
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode.m_labUI then
                local lab = symbolNode.m_labUI:findChild("m_lb_score")
                if lab then
                    lab:setString(score)
                end
            end
        end
        if symbolNode then
            symbolNode:runAnim("idleframe", true)
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == 0 then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode.m_labUI then
                local lab = symbolNode.m_labUI:findChild("m_lb_score")
                if lab then
                    lab:setString(score)
                end
                symbolNode:runAnim("idleframe", true)
            end
        end
    end
end

function CodeGameScreenAllStarMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col, isLastSymbol)

    if reelNode.m_labUI then
        reelNode.m_labUI:removeFromParent()
        reelNode.m_labUI = nil
    end

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        reelNode.m_labUI = util_createAnimation("Socre_AllStar_bonus1_lab.csb")
        reelNode:addChild(reelNode.m_labUI, 100)

        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        self:runAction(callFun)
    end

    return reelNode
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAllStarMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_SYMBOL, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINI, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_MID_LOCK, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ADD_WILD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_TWO_LOCK, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Double_BET, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Wild_2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Wild_3, count = 2}

    return loadNode
end

-- 是不是 respinBonus小块
function CodeGameScreenAllStarMachine:isFixSymbol(symbolType)
    if
        symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_MID_LOCK or symbolType == self.SYMBOL_ADD_WILD or symbolType == self.SYMBOL_TWO_LOCK or symbolType == self.SYMBOL_Double_BET or
            symbolType == self.SYMBOL_FIX_MINI or
            symbolType == self.SYMBOL_FIX_MINOR or
            symbolType == self.SYMBOL_FIX_MAJOR
     then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenAllStarMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self, reelCol)

    local isplay = true
    local isHaveFixSymbol = false

    for iRow = 1, self.m_iReelRowNum do
        if self:isFixSymbol(self.m_stcValidSymbolMatrix[iRow][reelCol]) then
            isHaveFixSymbol = true
            local node = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:runAnim("buling")
                if node.m_labUI then
                    node.m_labUI:runCsbAction("buling")
                end
            end
        end
    end
    if self.m_InBonus then
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_Big_Wild then
                if self.isHaveBigWild == true then
                    targSp:runAnim(
                        "buling",
                        false,
                        function()
                            targSp:runAnim("idle", true)
                        end
                    )
                else
                end
            end
        end
    end

    if isHaveFixSymbol == true then
        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
            if isplay then
                -- respinbonus落地音效

                isplay = false
                local soundPath = "AllStarSounds/music_AllStar_FixNode_down.mp3"

                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds(reelCol, soundPath)
                else
                    gLobalSoundManager:playSound(soundPath)
                end
            end
        end
    end
end

function CodeGameScreenAllStarMachine:unlockHigherBet()
    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE
     then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    local minBet = self:getMinBet()
    if betCoin >= minBet then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= minBet then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenAllStarMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self.m_jackPotBar:updateJackpotInfo()
    self:upateBetLevel()
end

function CodeGameScreenAllStarMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

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
            self:unlockHigherBet()
        end,
        ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET
    )
end

function CodeGameScreenAllStarMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenAllStarMachine:getMinBet()
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

function CodeGameScreenAllStarMachine:updatJackPotLock(minBet)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1

            gLobalSoundManager:playSound("AllStarSounds/music_AllStar_bet_unlock.mp3")
            self.m_jackPotBar.m_LockGrand:runCsbAction(
                "over",
                false,
                function()
                    if self.m_betLevel == 1 then
                        self.m_jackPotBar.m_LockGrand:setVisible(false)
                    end
                end
            )
        else
            self.m_jackPotBar.m_LockGrand:setVisible(false)
        end
    else
        self.m_jackPotBar.m_LockGrand:setVisible(true)

        if self.m_betLevel == nil or self.m_betLevel == 1 then
            gLobalSoundManager:playSound("AllStarSounds/music_AllStar_bet_lock.mp3")
            self.m_betLevel = 0
            self.m_jackPotBar.m_LockGrand:runCsbAction("idle", true)
        end
    end

    local unlock_coins_lab = self.m_jackPotBar.m_LockGrand:findChild("unlock_coins")
    if unlock_coins_lab then
        unlock_coins_lab:setString(util_formatCoins(minBet, 3))
    end
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenAllStarMachine:upateBetLevel()
    local minBet = self:getMinBet()

    self:updatJackPotLock(minBet)
end

function CodeGameScreenAllStarMachine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenAllStarMachine:getSelfEffectList()
    local effectData = {}

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            local phase = respinSpecial.phase
            if phase then
                if phase == "over" then -- 单个bonus游戏结束返回respin页面
                    local overtype = respinSpecial.preType
                    if overtype then
                        local BonusData = {}
                        BonusData.GameType = tonumber(overtype)
                        BonusData.GameOrder = 0 --GameEffect.QUEST_COMPLETE_TIP

                        table.insert(effectData, BonusData)
                    end

                    local BonusData = {}
                    BonusData.GameType = tonumber(self.SYMBOL_OneBonusOver)
                    BonusData.GameOrder = GameEffect.QUEST_COMPLETE_TIP

                    table.insert(effectData, BonusData)
                end

                local spinLines = respinSpecial.spinLines
                if spinLines then
                    local BonusData = {}
                    BonusData.GameType = tonumber(self.SYMBOL_FIX_SYMBOL)
                    BonusData.GameOrder = GameEffect.QUEST_COMPLETE_TIP
                    table.insert(effectData, BonusData)
                end

                if phase == "over" or phase == "start" then -- 单个bonus游戏结束返回respin页面
                    local Begintype = respinSpecial.type

                    if Begintype then
                        local BonusData = {}
                        BonusData.GameType = tonumber(self.SYMBOL_OneBonusStart)
                        BonusData.GameOrder = GameEffect.QUEST_COMPLETE_TIP
                        table.insert(effectData, BonusData)
                    end
                end

                local Begintype = tonumber(respinSpecial.type)
                if Begintype then
                    local BonusData = {}
                    BonusData.GameType = tonumber(Begintype)
                    BonusData.GameOrder = GameEffect.QUEST_COMPLETE_TIP
                    if phase == "idel" then
                        BonusData.GameOrder = 0
                    end
                    table.insert(effectData, BonusData)
                end

                local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag
                if respinSpecialFinishFlag and respinSpecialFinishFlag == "1" then
                    local storedIcons = self.m_runSpinResultData.p_storedIcons
                    if #storedIcons == 9 and self:getBetLevel() == 1 then -- 全满了是Grand
                        local BonusData = {}
                        BonusData.GameType = tonumber(self.SYMBOL_FIX_GRAND)
                        BonusData.GameOrder = GameEffect.QUEST_COMPLETE_TIP
                        table.insert(effectData, BonusData)
                    end

                    local BonusData = {}
                    BonusData.GameType = tonumber(self.SYMBOL_RespinOver)
                    BonusData.GameOrder = GameEffect.QUEST_COMPLETE_TIP

                    table.insert(effectData, BonusData)
                end
            end
        end
    end
    return effectData
end

function CodeGameScreenAllStarMachine:delaySlotReelDown()
    if self.m_InBonus then
        self.isHaveBigWild = false
    end

    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:resetSlotsRunChangeData()

    -- 开始执行后续的逻辑 ， 暂时不考虑准备下一阶段的滚动内容
    self:heldOnAllScore()

    self:MachineRule_stopReelChangeData()

    --改变freespin状态
    self:changeFreeSpinModeStatus()

    -- 改变respin状态
    self:changeReSpinModeStatus()

    -- 添加自定义的effects
    self:addSelfEffect()

    self:calculateLastWinCoin()

    -- 添加特殊bonus的大赢
    self:addLastBonusOverWinSomeEffect()

    self:addLastWinSomeEffect()

    -- 保留本轮结果
    self:keepCurrentSpinData()

    self:checkRemoveBigMegaEffect()

    --添加连线动画
    self:addLineEffect()

    --刷新quest 并且尝试添加quest完成
    self:addQuestCompleteTipEffect()

    -- 添加活动赠送免费spin次数游戏事件
    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    --添加收集角标Effct
    self:addCollectSignEffect()

    --动画层级赋值
    self:setGameEffectOrder()

    self:sortGameEffects()

    if #self.m_gameEffects > 0 then
        -- 通知动画开始运行。
        self.m_isRunningEffect = true
    end

    for i = #self.m_vecSymbolEffectType, 1, -1 do
        table.remove(self.m_vecSymbolEffectType, i)
    end

    if self.m_InBonus then
        self.m_bottomUI:updateBetEnable(false)
    end

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenAllStarMachine:MachineRule_SpinBtnCall()
    self:stopLinesWinSound()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()

    if self.m_InBonus then
        for iCol = self.m_iReelColumnNum, 1, -1 do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_Big_Wild then
                    targSp:runAnim("idleframe")
                end
            end
        end
    end
    return false -- 用作延时点击spin调用
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAllStarMachine:addSelfEffect()
    local isRemoveQuest = false
    local BonusGameTypeList = self:getSelfEffectList()
    -- local
    for k, v in pairs(BonusGameTypeList) do
        local BonusGameType = v.GameType
        local BonusGameOrder = v.GameOrder
        isRemoveQuest = true
        if BonusGameType == self.SYMBOL_FIX_SYMBOL then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_MID_LOCK then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_ADD_WILD then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_TWO_LOCK then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_Double_BET then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_FIX_GRAND then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_RespinOver then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_OneBonusOver then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_OneBonusStart then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        elseif BonusGameType == self.SYMBOL_Bonus_Spin then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + k + BonusGameOrder
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = BonusGameType -- 动画类型
        end
    end
    if isRemoveQuest then
        --如果存在移除掉
        local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
        if hasQuestEffect == true then
            self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
        end
    end
end

--检测是否可以增加quest 完成事件
function CodeGameScreenAllStarMachine:checkQuestDoneGameEffect()
    -- cxc 2021年07月01日10:23:51 quest需要检查下有没有新手quest
    if self.afreshAddQuestDoneEffectType then
        self:afreshAddQuestDoneEffectType()
        return
    end
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not questConfig then
        return
    end
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == false then
        local questEffect = GameEffectData:create()
        questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
        questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
        self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAllStarMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.SYMBOL_FIX_SYMBOL then
        self:winNormalBonusEffect(effectData, 1)
    elseif effectData.p_selfEffectType == self.SYMBOL_MID_LOCK then
        self:MID_LOCK_BonusEffect(effectData)
    elseif effectData.p_selfEffectType == self.SYMBOL_ADD_WILD then
        self:ADD_WILD_BonusEffect(effectData)
    elseif effectData.p_selfEffectType == self.SYMBOL_TWO_LOCK then
        self:TWO_LOCK_BonusEffect(effectData)
    elseif effectData.p_selfEffectType == self.SYMBOL_Double_BET then
        self:Double_BET_BonusEffect(effectData)
    elseif effectData.p_selfEffectType == self.SYMBOL_FIX_GRAND then
        self:winJackPotBonusEffect(effectData)
    elseif effectData.p_selfEffectType == self.SYMBOL_RespinOver then
        self:respinOverBonusEffect(effectData)
        self:checkQuestDoneGameEffect()
    elseif effectData.p_selfEffectType == self.SYMBOL_OneBonusOver then
        performWithDelay(
            self,
            function()
                self:playOneBonusGameOver(effectData)
            end,
            0.5
        )
    elseif effectData.p_selfEffectType == self.SYMBOL_OneBonusStart then
        self:playOneBonusGameStart(effectData)
    elseif effectData.p_selfEffectType == self.SYMBOL_Bonus_Spin then
        self:playNextBonusSpin(effectData)
    end

    return true
end

function CodeGameScreenAllStarMachine:playNextBonusSpin(effectData)
    gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")

    gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)

    if effectData then
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function CodeGameScreenAllStarMachine:playOneBonusGameStart(effectData)
    local startFunc = function(Begintype)
        self:changeGameBg(Begintype, true)
        self.m_gameLogo:findChild("double_bet_lab"):setString("10X")
        self.m_gameLogo:setVisible(true)
        self.m_gameLogo:updateLogoImg(Begintype)

        local fadeTime = self.m_fadeInTime
        self.m_gameLogo:setCascadeOpacityEnabled(true)
        local fadeIn = cc.FadeIn:create(fadeTime)
        self.m_gameLogo:setOpacity(0)
        self.m_gameLogo:runAction(fadeIn)
        self.m_gameLogo:runCsbAction("idle1", true)

        if Begintype == self.SYMBOL_MID_LOCK then
            self.m_gameLogo:showTipTxt(1)
        end
        self.m_jackPotBar:runCsbAction(
            "over",
            false,
            function()
                self.m_jackPotBar:setVisible(false)
                self.m_respinView:setVisible(false)
            end
        )

        for iCol = 1, 3 do
            self:showAllBigWild(iCol)
        end

        self:createRandomReelsNode()

        --隐藏 盘面信息
        self:setReelSlotsNodeVisible(true)
        self:findChild("zhezhao"):setVisible(true)
        self:runCsbAction("normal")
        self.m_gameBg:runCsbAction("normal", true)

        self.isHaveBigWild = true

        self.m_respinBar:setVisible(false)

        self:findChild("reel_side"):setVisible(true)
        self:findChild("reel_side_rs"):setVisible(false)
    end

    local GMType = self.SYMBOL_MID_LOCK
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            local Begintype = tonumber(respinSpecial.type)
            if Begintype then
                GMType = Begintype

                local pos = tonumber(respinSpecial.position)
                local targSp = self:getChipNodeFroIndex(pos)

                if targSp then
                    targSp:runAnim(
                        "actionframe",
                        false,
                        function()
                            targSp:runAnim("idleframe")
                        end
                    )

                    if GMType == self.SYMBOL_MID_LOCK then
                        gLobalSoundManager:playSound("AllStarSounds/music_AllStar_Bonustriggert_MID_LOCK.mp3")
                    elseif GMType == self.SYMBOL_ADD_WILD then
                        performWithDelay(
                            self,
                            function()
                                gLobalSoundManager:playSound("AllStarSounds/music_AllStar_Bonustriggert_ADD_WILD.mp3")
                            end,
                            18 / 30
                        )
                    elseif GMType == self.SYMBOL_TWO_LOCK then
                        gLobalSoundManager:playSound("AllStarSounds/music_AllStar_Bonustriggert_TWO_LOCK.mp3")
                    elseif GMType == self.SYMBOL_Double_BET then
                        gLobalSoundManager:playSound("AllStarSounds/music_AllStar_Bonustriggert_Double_BET.mp3")
                    end
                end
            end
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    performWithDelay(
        self,
        function()
            self:showGuoChang(
                function()
                    if effectData then
                        local startGMType = GMType

                        startFunc(GMType)

                        if GMType ~= self.SYMBOL_Double_BET then
                            local soundPath = self:getLittleViewSound(GMType)
                            gLobalSoundManager:playSound(soundPath)
                        end

                        self.m_bonusTipView:setVisible(true)

                        self.m_bonusTipView:showViewFromType(GMType)

                        if GMType == self.SYMBOL_MID_LOCK then
                            self.m_bonusTipView:showTipTxt(1)
                        end

                        local startType = GMType

                        if startType == self.SYMBOL_Double_BET then
                            -- end,1.5)
                            -- performWithDelay(self,function (  )
                            if effectData then
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        else
                            self:findChild("tishikuangzhezhao"):setVisible(true)
                            self.m_bonusTipView:runCsbAction("auto", false)
                            performWithDelay(
                                self,
                                function()
                                    self.m_bonusTipView:setVisible(false)
                                    self:findChild("tishikuangzhezhao"):setVisible(false)
                                    if startType == self.SYMBOL_MID_LOCK then
                                        self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_MID_LOCK.mp3")
                                    elseif startType == self.SYMBOL_ADD_WILD then
                                        self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_ADD_WILD.mp3")
                                    elseif startType == self.SYMBOL_TWO_LOCK then
                                        self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_TWO_LOCK.mp3")
                                    elseif startType == self.SYMBOL_Double_BET then
                                        self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_Double_BET.mp3")
                                    end

                                    if effectData then
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end
                                end,
                                70 / 30
                            )
                        end
                    else
                        if effectData == nil then
                            startFunc(GMType)

                            if GMType == self.SYMBOL_MID_LOCK then
                                self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_MID_LOCK.mp3")
                            elseif GMType == self.SYMBOL_ADD_WILD then
                                self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_ADD_WILD.mp3")
                            elseif GMType == self.SYMBOL_TWO_LOCK then
                                self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_TWO_LOCK.mp3")
                            elseif GMType == self.SYMBOL_Double_BET then
                                self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_Double_BET.mp3")
                            end

                            performWithDelay(
                                self,
                                function()
                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
                                    self.m_bottomUI:updateBetEnable(false)

                                    gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")

                                    gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
                                end,
                                1
                            )
                        end
                    end
                end
            )
        end,
        35 / 30
    )

    local multiple = 30

    if effectData == nil then
        self:findChild("reel_side"):setVisible(false)
        self:findChild("reel_side_rs"):setVisible(true)

        self:runCsbAction("respin")

        local rsExtraData = self.m_runSpinResultData.p_rsExtraData
        if rsExtraData then
            local respinSpecial = rsExtraData.respinSpecial

            if respinSpecial then
                local totalWinAmount = respinSpecial.totalWinAmount
                self.m_BonusScore = totalWinAmount
                if respinSpecial.multiple then
                    multiple = tonumber(respinSpecial.multiple)
                end
            end
        end

        local coins = self.m_BonusScore
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
        globalData.slotRunData.lastWinCoin = lastWinCoin

        self:setReelSlotsNodeVisible(false)
        self:findChild("zhezhao"):setVisible(false)

        if multiple then
            self.m_gameLogo:findChild("double_bet_lab"):setString(multiple .. "X")
        end
    end
end

function CodeGameScreenAllStarMachine:playOneBonusGameOver(effectData)
    local waittime = 1

    self:clearCurMusicBg()

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            local endtype = tonumber(respinSpecial.preType)
            if endtype then
                if endtype == self.SYMBOL_MID_LOCK then
                    -- gLobalSoundManager:playSound("AllStarSounds/music_AllStar_bonus_over_MID_LOCK.mp3")
                    waittime = 1 + 2
                elseif endtype == self.SYMBOL_ADD_WILD then
                    -- gLobalSoundManager:playSound("AllStarSounds/music_AllStar_bonus_over_ADD_WILD.mp3")
                    waittime = 1 + 3
                elseif endtype == self.SYMBOL_TWO_LOCK then
                    -- gLobalSoundManager:playSound("AllStarSounds/music_AllStar_bonus_over_TWO_LOCK.mp3")
                    waittime = 1 + 2
                elseif endtype == self.SYMBOL_Double_BET then
                    waittime = 1 + 3
                -- gLobalSoundManager:playSound("AllStarSounds/music_AllStar_bonus_over_Double_BET.mp3")
                end
            end
        end
    end

    waittime = 1
    performWithDelay(
        self,
        function()
            self:changeGameBg(nil, false)
            self.m_respinView:setVisible(true)
            self.m_jackPotBar:setVisible(true)
            self.m_jackPotBar:runCsbAction(
                "start",
                false,
                function()
                    self.m_jackPotBar:runCsbAction("idle")
                end
            )

            local fadeOut = cc.FadeOut:create(self.m_fadeInTime)
            local callFun =
                cc.CallFunc:create(
                function(...)
                    self.m_gameLogo:setVisible(false)
                    self.m_gameLogo:runCsbAction("stop")
                end
            )
            local seq = cc.Sequence:create(fadeOut, callFun1, callFun)
            self.m_gameLogo:runAction(seq)

            for iCol = 1, 3 do
                self:UnLockSymbolForCol(iCol)
            end
            --清空所有创建的小块
            self:removeAllReelsNode()
            --清空固定wild列表
            self:removeWildList()
            self:stopAllActions()
            self:clearWinLineEffect()
            self:findChild("zhezhao"):setVisible(false)
            self:runCsbAction("respin")

            self.isHaveBigWild = false

            --隐藏 盘面信息
            self:setReelSlotsNodeVisible(false)

            self:findChild("reel_side"):setVisible(false)
            self:findChild("reel_side_rs"):setVisible(true)

            performWithDelay(
                self,
                function()
                    if effectData then
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                end,
                0.5
            )
        end,
        waittime
    )
end

function CodeGameScreenAllStarMachine:MID_LOCK_BonusTipEffect(effectData)
    local winLines = self.m_runSpinResultData.p_winLines

    if winLines and #winLines > 0 then
        local waitTime = 0
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData
        if rsExtraData then
            local respinSpecial = rsExtraData.respinSpecial

            if respinSpecial then
                local phase = respinSpecial.phase
                if phase then
                    if phase == "idel" then
                        local soundPath = self:getLittleViewSound(self.SYMBOL_Double_BET)
                        gLobalSoundManager:playSound(soundPath)

                        self.m_bonusTipView:setVisible(true)
                        self.m_bonusTipView:showViewFromType(self.SYMBOL_MID_LOCK)

                        self.m_bonusTipView:showTipTxt(2)
                    end
                end
            end
        end

        self.m_bonusTipView:runCsbAction(
            "auto",
            false,
            function()
                self.m_bonusTipView:setVisible(false)
                self.m_gameLogo:runCsbAction("stop")
                self.m_gameLogo:showTipTxt(2)
                self.m_gameLogo:runCsbAction("idle1", true)

                if effectData then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end
        )
    else
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
end

function CodeGameScreenAllStarMachine:MID_LOCK_BonusEffect(effectData)
    self.bonusIndex = 1
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial
        if respinSpecial then
            if respinSpecial.phase == "idel" then
                self:LockSymbolForCol(2)
            end
        end
    end

    if effectData then
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            0.1
        )
    end
end

--随机添加wild玩法
function CodeGameScreenAllStarMachine:ADD_WILD_BonusEffect(effectData)
    self.bonusIndex = 2
    local wildPos = {}
    local effectOrder = effectData.p_effectOrder

    if effectOrder then
        if effectOrder >= GameEffect.QUEST_COMPLETE_TIP then
            effectData.p_isPlay = true
            self:playGameEffect()
            return
        end
    end

    local time = 0.2
    local sumTime = 1

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            if respinSpecial.wildAddPosition then
                wildPos = respinSpecial.wildAddPosition
            end
        end
    end

    local sumTime = #wildPos * time + 0.5 + 2 / 3
    self:addWildPosSort(wildPos)
    --播放雷神触发
    self.m_gameLogo:spineNodeRunAct(2)
    performWithDelay(
        self,
        function()
            local startNode = self:findChild("leishen")
            local startPos = cc.p(startNode:getPositionX(), startNode:getPositionY())
            if wildPos and #wildPos > 0 then
                for k, v in pairs(wildPos) do
                    local posIndex = v
                    local fixPos = self:getRowAndColByPos(posIndex)
                    local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    local endPos = util_convertToNodeSpace(targSp, self)
                    performWithDelay(
                        self,
                        function()
                            --播放闪电粒子
                            self:runFlyLineAct(
                                startPos,
                                endPos,
                                function()
                                    if targSp then
                                        targSp:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                        if targSp.m_labUI then
                                            targSp.m_labUI:removeFromParent()
                                            targSp.m_labUI = nil
                                        end
                                        gLobalSoundManager:playSound("AllStarSounds/music_AllStar_add_wild_show.mp3")
                                        targSp:runAnim("add")
                                    end
                                end
                            )
                        end,
                        time * (k - 1)
                    )
                end
            end
        end,
        2 / 3
    )

    performWithDelay(
        self,
        function()
            local a = sumTime
            if effectData then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end,
        sumTime
    )
end

function CodeGameScreenAllStarMachine:TWO_LOCK_BonusEffect(effectData)
    self.bonusIndex = 4
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            if respinSpecial.phase == "idel" then
                self:LockSymbolForCol(1)
                self:LockSymbolForCol(3)
            end
        end
    end

    performWithDelay(
        self,
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        0.5
    )
end

function CodeGameScreenAllStarMachine:Double_BET_BonusEffect(effectData)
    self.bonusIndex = 3
    local multiple = 0
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local startNode = self:findChild("emo")
    local startPos = cc.p(startNode:getPositionX(), startNode:getPositionY())
    local endNode = self.m_bonusTipView:findChild("Node_effect")
    local endNewPos = util_convertToNodeSpace(endNode, self)
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial
        local effectType = effectData.p_effectOrder or 0
        local phase = respinSpecial.phase
        if respinSpecial and effectType > GameEffect.QUEST_COMPLETE_TIP then
            if phase then
                if phase ~= "idel" then
                    local dealytime = 1

                    self.m_bonusTipView:showViewFromType(self.SYMBOL_Double_BET)
                    self.m_gameLogo:spineNodeRunAct(3)
                    self.m_bonusTipView:runCsbAction(
                        "start",
                        false,
                        function()
                            self.m_bonusTipView:runCsbAction("idle", true)
                        end
                    )
                    self:findChild("tishikuangzhezhao"):setVisible(true)
                    performWithDelay(
                        self,
                        function()
                            local multiple = tonumber(respinSpecial.multiple)
                            local showTmes = 0

                            if multiple == 10 then
                                showTmes = 2
                            elseif multiple == 15 then
                                showTmes = 3
                            elseif multiple == 20 then
                                showTmes = 4
                            elseif multiple == 25 then
                                showTmes = 5
                            else
                                showTmes = 6
                            end

                            self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_Double_BET.mp3")
                            for i = 1, showTmes do
                                local index = i
                                performWithDelay(
                                    self,
                                    function()
                                        if index == showTmes then
                                            self.m_bonusTipView:runCsbAction("over")
                                            self.m_bonusTipView:setVisible(false)
                                            self:findChild("tishikuangzhezhao"):setVisible(false)

                                            if effectData then
                                                effectData.p_isPlay = true
                                                self:playGameEffect()
                                            end
                                        else
                                            local betList = {10, 15, 20, 25, 30}
                                            if index ~= 1 then
                                                self.m_gameLogo:spineNodeAct(3)

                                                performWithDelay(
                                                    self,
                                                    function()
                                                        self:runFlyLineAct(
                                                            startPos,
                                                            endNewPos,
                                                            function()
                                                                gLobalSoundManager:playSound("AllStarSounds/music_AllStar_showEffectBoom.mp3")
                                                                self.m_bonusTipView:setBoomNodeVisible(true)
                                                                gLobalSoundManager:playSound("AllStarSounds/music_AllStar_showMultiple.mp3")
                                                                self.m_bonusTipView:showBoomEffect()
                                                                performWithDelay(
                                                                    self,
                                                                    function()
                                                                        self.m_gameLogo:findChild("double_bet_lab"):setString(betList[i] .. "X")
                                                                        self.m_bonusTipView:showTipTxtForMulple(betList[i])
                                                                    end,
                                                                    0.1
                                                                )
                                                            end,
                                                            true
                                                        )
                                                    end,
                                                    14 / 30
                                                )
                                            else
                                                self.m_gameLogo:findChild("double_bet_lab"):setString(betList[i] .. "X")
                                                self.m_bonusTipView:showTipTxtForMulple(betList[i])

                                                self:runFlyLineAct(
                                                    startPos,
                                                    endNewPos,
                                                    function()
                                                        gLobalSoundManager:playSound("AllStarSounds/music_AllStar_showEffectBoom.mp3")
                                                        self.m_bonusTipView:setBoomNodeVisible(true)
                                                        gLobalSoundManager:playSound("AllStarSounds/music_AllStar_showMultiple.mp3")
                                                        self.m_bonusTipView:showBoomEffect()
                                                    end,
                                                    true
                                                )
                                            end
                                        end
                                        -- body
                                    end,
                                    (index - 1) * dealytime
                                )
                            end
                        end,
                        40 / 30
                    )
                else
                    self.m_gameLogo:findChild("double_bet_lab"):setString(tonumber(respinSpecial.multiple) .. "X")
                    self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_Double_BET.mp3")
                    if effectData then
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                end
            else
                self.m_gameLogo:findChild("double_bet_lab"):setString(tonumber(respinSpecial.multiple) .. "X")
                self:resetMusicBg(nil, "AllStarSounds/music_AllStar_bonusbg_Double_BET.mp3")
                if effectData then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            end
        else
            if effectData then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end
    end
end

function CodeGameScreenAllStarMachine:getChipNodeFroIndex(index)
    for k, v in pairs(self.m_chipList) do
        local pos = self:getPosReelIdx(v.p_rowIndex, v.p_cloumnIndex)
        if pos == index then
            return v
        end
    end
end

--[[
    @desc: 普通respin赢钱
    author:{author}
    time:2021-03-25 22:25:13
    --@effectData: 
    --@animIndex: 节点池索引
    @return:
]]
function CodeGameScreenAllStarMachine:winNormalBonusEffect(effectData, animIndex)
    local endFunction = function()
        if effectData then
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            local normalLines = respinSpecial.spinLines

            if (animIndex > #normalLines) then
                --结束
                endFunction()
                return
            end
            local dealyTime = 0.4
            local addScore = 0
            local index = normalLines[animIndex].icons[1] or 1
            local chipNode = self:getChipNodeFroIndex(index)

            if (chipNode) then
                local jpUiid = nil

                if chipNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                    local iCol = chipNode.p_cloumnIndex
                    local iRow = chipNode.p_rowIndex
                    -- 根据网络数据获得当前固定小块的分数
                    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
                    local lineBet = globalData.slotRunData:getCurTotalBet()

                    if score ~= nil then
                        if type(score) ~= "string" then
                            addScore = score * lineBet
                        end
                    end
                elseif (chipNode.p_symbolType == self.SYMBOL_FIX_MAJOR or chipNode.p_symbolType == self.SYMBOL_FIX_MINOR or chipNode.p_symbolType == self.SYMBOL_FIX_MINI) then
                    addScore, jpUiid = self:getJackPotScore(chipNode.p_symbolType)
                end

                self.m_BonusScore = self.m_BonusScore + addScore
                local curSpinCount = self.m_BonusScore

                self:playCoinWinEffectUI()

                local actionframeEndFunction = nil
                --jackPot弹板
                if (jpUiid) then
                    actionframeEndFunction = function()
                        self:showRespinJackpot(
                            jpUiid,
                            addScore,
                            function()
                                performWithDelay(
                                    self,
                                    function()
                                        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(curSpinCount))
                                        self:winNormalBonusEffect(effectData, animIndex + 1)
                                    end,
                                    0.5
                                )
                            end
                        )
                    end
                    gLobalSoundManager:playSound("AllStarSounds/music_AllStar_jackpot_collect.mp3")
                    chipNode:runAnim("actionframe", false, actionframeEndFunction)
                else
                    --音效-闪光-底部特效
                    gLobalSoundManager:playSound("AllStarSounds/music_AllStar_bonus_collect.mp3")
                    chipNode:runAnim("actionframe")
                    performWithDelay(
                        self,
                        function()
                            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(curSpinCount))
                            self:winNormalBonusEffect(effectData, animIndex + 1)
                        end,
                        0.4
                    )
                end
            end
        else
            endFunction()
        end
    else
        endFunction()
    end
end

function CodeGameScreenAllStarMachine:showRespinJackpot(index, coins, func)
    local actTime = 0
    local grandSoundId = nil
    if (index == 4) then
        self:runCsbAction("actionframe", true)
        self.m_jackPotBar:runCsbAction("actionframe", true)
        actTime = util_csbGetAnimTimes(self.m_jackPotBar.m_csbAct, "actionframe", 30)
        grandSoundId = gLobalSoundManager:playSound("AllStarSounds/music_AllStar_grand.mp3")
    end
    performWithDelay(
        self,
        function()
            self.m_jackPotBar:runCsbAction("idle", true)
            gLobalSoundManager:stopAudio(grandSoundId)
            grandSoundId = nil

            local overViewSoundId = nil

            if index == 1 then
                overViewSoundId = gLobalSoundManager:playSound("AllStarSounds/music_AllStar_jackpot_view_1.mp3")
            elseif index == 2 then
                overViewSoundId = gLobalSoundManager:playSound("AllStarSounds/music_AllStar_jackpot_view_2.mp3")
            elseif index == 3 then
                overViewSoundId = gLobalSoundManager:playSound("AllStarSounds/music_AllStar_jackpot_view_3.mp3")
            elseif index == 4 then
                overViewSoundId = gLobalSoundManager:playSound("AllStarSounds/music_AllStar_jackpot_view_4.mp3")
            end

            self.m_jackpotView = util_createView("CodeAllStarSrc.AllStarJackPotWinView", self)
            self:addChild(self.m_jackpotView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
            self.m_jackpotView:setPosition(0, 0)

            self.m_jackpotView:initCallFunc(
                coins,
                index,
                function()
                    if overViewSoundId then
                        gLobalSoundManager:stopAudio(overViewSoundId)
                        overViewSoundId = nil
                    end
                    if func then
                        func()
                    end
                end
            )
        end,
        actTime
    )
end

function CodeGameScreenAllStarMachine:getJackPotScore(playType)
    local jpCoinsid = 4
    local jpUiid = 4

    if playType == self.SYMBOL_FIX_GRAND then
        jpCoinsid = 1
        jpUiid = 4
    elseif playType == self.SYMBOL_FIX_MAJOR then
        jpCoinsid = 2
        jpUiid = 3
    elseif playType == self.SYMBOL_FIX_MINOR then
        jpCoinsid = 3
        jpUiid = 2
    elseif playType == self.SYMBOL_FIX_MINI then
        jpCoinsid = 4
        jpUiid = 1
    end

    local jackpotScore = self:BaseMania_getJackpotScore(jpCoinsid)

    -- 获取服务器jackpot钱数
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            local BonusLines = respinSpecial.lines
            if BonusLines then
                local jpType = playType
                if jpType == self.SYMBOL_FIX_GRAND then
                    jpType = 104
                end
                for k, v in pairs(BonusLines) do
                    local linesdata = v
                    if linesdata.type and linesdata.type == jpType then
                        if linesdata.amount then
                            jackpotScore = tonumber(linesdata.amount)
                        end

                        break
                    end
                end
            end
        end
    end

    return jackpotScore, jpUiid
end

-- JackPot
function CodeGameScreenAllStarMachine:winJackPotBonusEffect(effectData, playType)
    local playType = effectData.p_selfEffectType or self.SYMBOL_FIX_GRAND
    local jackpotScore = nil
    local jpUiid = nil

    jackpotScore, jpUiid = self:getJackPotScore(playType)

    self.m_BonusScore = self.m_BonusScore + jackpotScore

    local curSpinCount = self.m_BonusScore

    local effectOldData = effectData

    self:showRespinJackpot(
        jpUiid,
        jackpotScore,
        function()
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(curSpinCount))

            self:playCoinWinEffectUI()

            self.m_reelsFalsh:setVisible(true)
            self.m_reelsFalsh:runCsbAction(
                "show",
                false,
                function()
                    if effectOldData then
                        effectOldData.p_isPlay = true
                        self:playGameEffect()
                    end
                end
            )
        end
    )
end

----------respin相关
-- 根据本关卡实际小块数量填写
function CodeGameScreenAllStarMachine:getRespinRandomTypes()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        self.SYMBOL_FIX_SYMBOL,
        self.SYMBOL_FIX_MAJOR,
        self.SYMBOL_FIX_MINI,
        self.SYMBOL_FIX_MINOR,
        self.SYMBOL_MID_LOCK,
        self.SYMBOL_ADD_WILD,
        self.SYMBOL_TWO_LOCK,
        self.SYMBOL_Double_BET,
        self.SYMBOL_Blank
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenAllStarMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_MID_LOCK, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_ADD_WILD, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_TWO_LOCK, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_Double_BET, runEndAnimaName = "buling", bRandom = true}
    }

    return symbolList
end

function CodeGameScreenAllStarMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    if func then
        func()
    end
end

function CodeGameScreenAllStarMachine:showRespinView()
    self:findChild("zhezhao"):setVisible(false)

    --先播放动画 再进入respin
    self:clearCurMusicBg()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()

    local animTime = 1.5

    self.m_bottomUI:updateWinCount("")

    globalMachineController:playBgmAndResume("AllStarSounds/music_AllStar_bonus_trigger.mp3", 4, 0.4, 1)

    performWithDelay(
        self,
        function()
            self:findChild("reel_side"):setVisible(false)
            self:findChild("reel_side_rs"):setVisible(true)

            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end,
        animTime
    )
end

--ReSpin开始改变UI状态
function CodeGameScreenAllStarMachine:changeReSpinStartUI(respinCount)
    self.m_respinBar:runCsbAction("show")
    self.m_respinBar:setVisible(true)
    self.m_respinBar:updateTimes(respinCount)

    if respinCount == 3 then
        self.m_reelsFalsh:setVisible(true)
        self.m_reelsFalsh:runCsbAction(
            "show",
            false,
            function()
                self.m_reelsFalsh:setVisible(false)
            end
        )
    end

    self:changeReelsUI(true)
end

--ReSpin刷新数量
function CodeGameScreenAllStarMachine:changeReSpinUpdateUI(curCount)
    self.m_respinBar:runCsbAction("idle")
    self.m_respinBar:setVisible(true)
    self.m_respinBar:updateTimes(curCount)

    if curCount == 3 then
        self.m_reelsFalsh:setVisible(true)
        self.m_reelsFalsh:runCsbAction(
            "show",
            false,
            function()
                self.m_reelsFalsh:setVisible(false)
            end
        )
    end
end

-- --重写组织respinData信息
function CodeGameScreenAllStarMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i = 1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

--结束移除小块调用结算特效
function CodeGameScreenAllStarMachine:reSpinEndAction()
    self.m_respinBar:updateTimes(0)

    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()
    self.m_respinBar:runCsbAction(
        "over",
        false,
        function()
            self.m_respinBar:setVisible(false)
        end
    )
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()

    for k, v in pairs(self.m_chipList) do
        local node = v
        if node then
            node:runAnim("idleframe")
        end
    end

    self:updateLocalLevelsData()

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    -- 大于零说明有特殊玩法触发
    if rsExtraData then
        if self:getCurrSpinMode() == RESPIN_MODE then
            local respinSpecialFlag = rsExtraData.respinSpecialFlag
            if respinSpecialFlag and respinSpecialFlag == "0" then
                performWithDelay(
                    self,
                    function()
                        self:normalCollectBonus(1)
                    end,
                    1
                )
            else
                self:addSelfEffect()
                --动画层级赋值
                self:setGameEffectOrder()

                self:sortGameEffects()

                self:clearCurMusicBg()

                performWithDelay(
                    self,
                    function()
                        self:triggerReSpinOverCallFun(self.m_lightScore)
                        self.m_lightScore = 0
                    end,
                    1
                )
            end
        end
    else
        -- 没有特殊玩法直接执行普通收集respin结束
        if self:getCurrSpinMode() == RESPIN_MODE then
            performWithDelay(
                self,
                function()
                    self:normalCollectBonus(1)
                end,
                1
            )
        end
    end
end

--ReSpin结算改变UI状态
function CodeGameScreenAllStarMachine:changeReelsUI(isInRs)
    if isInRs then
        self:runCsbAction("normal_respin")
    else
        self:runCsbAction("respin_normal")
    end
end

function CodeGameScreenAllStarMachine:showBonusOverView(effectData, func)
    local overViewSoundId = gLobalSoundManager:playSound("AllStarSounds/music_AllStar_view.mp3")

    self.m_bonusOverView = util_createView("CodeAllStarSrc.AllStarBonusOverView")
    self:addChild(self.m_bonusOverView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_bonusOverView:setPosition(0, 0)

    local strCoins = util_formatCoins(self.m_serverWinCoins, 30)

    self.m_bonusOverView:initCallFunc(
        strCoins,
        function()
            if overViewSoundId then
                gLobalSoundManager:stopAudio(overViewSoundId)
                overViewSoundId = nil
            end

            self.m_BonusNetData = {}
            self.m_respinBar:setVisible(false)
            self.m_respinBar:runCsbAction("over")

            self:runCsbAction("normal")
            self.m_gameBg:runCsbAction("normal", true)
            self:clearCurMusicBg()
            self:resetMusicBg()

            local rsExtraData = self.m_runSpinResultData.p_rsExtraData

            -- 大于零说明有特殊玩法触发
            if rsExtraData then
                if rsExtraData.respinSpecialFlag and rsExtraData.respinSpecialFlag == "1" then
                    -- 检测大赢
                    self:checkFeatureOverTriggerBigWin(self.m_BonusScore, GameEffect.EFFECT_BONUS)
                end
            end

            -- 更新左上角赢钱
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
            self.m_BonusScore = 0

            if func then
                func()
            end

            self:findChild("reel_side"):setVisible(true)
            self:findChild("reel_side_rs"):setVisible(false)

            -- 通知respin结束
            self:removeRespinNode()

            self:updateLocalLevelsData()

            if effectData then
                performWithDelay(
                    self,
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    0.3
                )
            end
        end
    )
end

-- 结束respin收集
function CodeGameScreenAllStarMachine:respinOverBonusEffect(effectData)
    -- 通知respin结束

    self:stopAllActions()

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
    end

    performWithDelay(
        self,
        function()
            self:showBonusOverView(
                effectData,
                function()
                    self:findChild("zhezhao"):setVisible(true)
                end
            )
        end,
        1.5
    )
end

--------不扣除bet
function CodeGameScreenAllStarMachine:requestSpinResult()
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
        if self.m_InBonus ~= true then -- bonus 状态下也是免费
            self.m_topUI:updataPiggy(betCoin)
            isFreeSpin = false
        end
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

-- 下面这一堆只是为了bonus重连 的时候初始化respin最后一次结束的轮盘
-- 写他只是为了与底层区分开来
function CodeGameScreenAllStarMachine:initRespinReelsForBonus()
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )

    self.m_respinView:setOutLineBonus(true)

    local LinesView = util_createView("CodeAllStarSrc.AllStarRespinLinesView")
    self.m_respinView:addChild(LinesView, 1000)
    local pos = cc.p(self:getThreeReelsTarSpPos(4))
    LinesView:setPosition(pos)

    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)

    self.m_respinView:setVisible(true)

    self:initRespinViewForBonus(endTypes, randomTypes)
end

function CodeGameScreenAllStarMachine:initRespinViewForBonus(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:createRespinNodeInfoForBonus()

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
        end
    )

    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenAllStarMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if symbolType == self.SYMBOL_Big_Wild then
                symbolType = self:getRandomSymbolType()
            end

            if symbolType == self.SYMBOL_Blank then
                symbolType = self:getRandomSymbolType()
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
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

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenAllStarMachine:createRespinNodeInfoForBonus()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolTypeForBonus(iRow, iCol)

            if symbolType == self.SYMBOL_Big_Wild then
                symbolType = self:getRandomSymbolType()
            end

            if symbolType == self.SYMBOL_Blank then
                symbolType = self:getRandomSymbolType()
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
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

function CodeGameScreenAllStarMachine:getMatrixPosSymbolTypeForBonus(iRow, iCol) ----
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local respinSpecial = rsExtraData.respinSpecial

    if respinSpecial then
        local normalLines = respinSpecial.reels or {}
        local rowCount = #normalLines --(bonus初始化轮盘得用selfdate里边那个最后一次 的轮盘)
        for rowIndex = 1, rowCount do
            local rowDatas = normalLines[rowIndex]
            local colCount = #rowDatas

            for colIndex = 1, colCount do
                if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                    return rowDatas[colIndex]
                end
            end
        end
    end
end

function CodeGameScreenAllStarMachine:updateLocalLevelsData()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecialFlag = rsExtraData.respinSpecialFlag
        local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag
        if respinSpecialFlag and respinSpecialFlag == "1" then
            self.m_InBonus = true
        else
            self.m_InBonus = false
        end

        if respinSpecialFinishFlag and respinSpecialFinishFlag == "1" then
            self.m_InBonus = false
        end
    end
end

--[[
    @desc: 普通结算赢钱
    author:{author}
    time:2021-03-26 10:12:57
    --@animIndex: 节点池索引
    @return:
]]
function CodeGameScreenAllStarMachine:normalCollectBonus(animIndex)
    if (animIndex > #self.m_chipList) then
        --结束
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        if #storedIcons == 9 and self:getBetLevel() == 1 then -- 全满了是Grand
            local GrandScore, jpUiid = self:getJackPotScore(self.SYMBOL_FIX_GRAND)

            self:showRespinJackpot(
                4,
                GrandScore,
                function()
                    local grandWait = 2

                    self.m_BonusScore = self.m_BonusScore + GrandScore

                    self:playCoinWinEffectUI()

                    self.m_reelsFalsh:setVisible(true)
                    self.m_reelsFalsh:runCsbAction(
                        "show",
                        false,
                        function()
                        end
                    )

                    local curSpinCount = self.m_BonusScore
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(curSpinCount))

                    performWithDelay(
                        self,
                        function()
                            performWithDelay(
                                self,
                                function()
                                    self:showBonusOverView(
                                        nil,
                                        function()
                                            self:triggerReSpinOverCallFun(self.m_lightScore, true)
                                            performWithDelay(
                                                self,
                                                function()
                                                    self:playGameEffect()
                                                end,
                                                0.3
                                            )
                                            self:resetMusicBg(true)
                                            self.m_lightScore = 0
                                        end
                                    )
                                end,
                                0.5
                            )
                        end,
                        grandWait
                    )
                end
            )
        else
            performWithDelay(
                self,
                function()
                    self:showBonusOverView(
                        nil,
                        function()
                            self:findChild("zhezhao"):setVisible(true)

                            self:triggerReSpinOverCallFun(self.m_lightScore, true)
                            performWithDelay(
                                self,
                                function()
                                    self:playGameEffect()
                                end,
                                0.3
                            )
                            self:resetMusicBg(true)
                            self.m_lightScore = 0
                        end
                    )
                end,
                0.5
            )
        end

        return
    end

    local addScore = 0
    local chipNode = self.m_chipList[animIndex]
    if (chipNode) then
        local jpUiid = nil

        if chipNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
            local iCol = chipNode.p_cloumnIndex
            local iRow = chipNode.p_rowIndex
            -- 根据网络数据获得当前固定小块的分数
            local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
            local lineBet = globalData.slotRunData:getCurTotalBet()

            if score ~= nil then
                if type(score) ~= "string" then
                    addScore = score * lineBet
                end
            end
        elseif (chipNode.p_symbolType == self.SYMBOL_FIX_MAJOR or chipNode.p_symbolType == self.SYMBOL_FIX_MINOR or chipNode.p_symbolType == self.SYMBOL_FIX_MINI) then
            addScore, jpUiid = self:getJackPotScore(chipNode.p_symbolType)
        end

        self.m_BonusScore = self.m_BonusScore + addScore
        local curSpinCount = self.m_BonusScore

        self:playCoinWinEffectUI()
        -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(curSpinCount))

        local actionframeEndFunction = nil
        --jackPot弹板
        if (jpUiid) then
            actionframeEndFunction = function()
                self:showRespinJackpot(
                    jpUiid,
                    addScore,
                    function()
                        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(curSpinCount))
                        performWithDelay(
                            self,
                            function()
                                self:normalCollectBonus(animIndex + 1)
                            end,
                            0.5
                        )
                    end
                )
            end
            gLobalSoundManager:playSound("AllStarSounds/music_AllStar_jackpot_collect.mp3")
            chipNode:runAnim("actionframe", false, actionframeEndFunction)
        else
            --音效-闪光-底部特效
            gLobalSoundManager:playSound("AllStarSounds/music_AllStar_bonus_collect.mp3")
            chipNode:runAnim("actionframe")
            performWithDelay(
                self,
                function()
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(curSpinCount))
                    self:normalCollectBonus(animIndex + 1)
                end,
                0.4
            )
        end
    end
end

function CodeGameScreenAllStarMachine:initGameBg(...)
    -- body
    for i = 2, 10 do
        local name = "ClassicCash_bg_" .. i
        local img = self.m_gameBg:findChild(name)
        if img then
            img:setVisible(false)
        end
    end
end

function CodeGameScreenAllStarMachine:changeGameBg(Gmtype, isShow)
    local fadeTime = self.m_fadeInTime
    local delayTime = 0

    if self.m_curChangeBg then
        local img = self.m_curChangeBg
        img:setOpacity(255)
        local fadeOut = cc.FadeOut:create(fadeTime)
        local callFun =
            cc.CallFunc:create(
            function(...)
                img:setVisible(false)
                self.m_curChangeBg = nil

                if not isShow then
                    self.m_gameBg:runCsbAction(
                        "hide",
                        false,
                        function()
                        end
                    )
                end
            end
        )
        local seq = cc.Sequence:create(fadeOut, callFun)
        img:runAction(seq)
        delayTime = fadeTime
    end

    performWithDelay(
        self,
        function()
            local img = nil
            if self.SYMBOL_MID_LOCK == Gmtype then
                img = self.m_gameBg:findChild("ClassicCash_bg_5")
            elseif self.SYMBOL_ADD_WILD == Gmtype then
                img = self.m_gameBg:findChild("ClassicCash_bg_3")
            elseif self.SYMBOL_TWO_LOCK == Gmtype then
                img = self.m_gameBg:findChild("ClassicCash_bg_4")
            elseif self.SYMBOL_Double_BET == Gmtype then
                img = self.m_gameBg:findChild("ClassicCash_bg_2")
            else
                img = self.m_gameBg:findChild("ClassicCash_bg_1")
            end
            if (img) then
                if isShow then
                    self.m_gameBg:runCsbAction(
                        "show",
                        false,
                        function()
                            self.m_gameBg:runCsbAction("actionframe", true)
                        end
                    )
                end
                img:stopAllActions()
                img:setOpacity(0)
                img:setVisible(true)
                local fadeIn = cc.FadeIn:create(fadeTime)
                img:runAction(fadeIn)
            end
            self.m_curChangeBg = img
        end,
        delayTime
    )
end

-- 设置某列不参与滚动
function CodeGameScreenAllStarMachine:setOneReelsRunStates(col, isrun)
    if isrun then
        self.m_slotParents[col].isReeling = true
        self.m_slotParents[col].isResActionDone = false
    else
        self.m_slotParents[col].isReeling = false
        self.m_slotParents[col].isResActionDone = true
    end
end

function CodeGameScreenAllStarMachine:beginReel()
    if self.m_showFistBg and not self.m_InBonus then
        self:resetMusicBg()
        self.m_showFistBg = false
    end

    self:resetReelDataAfterReel()

    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local reelDatas = nil

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        else
            local Begintype = nil
            if self.m_InBonus == true then
                local rsExtraData = self.m_runSpinResultData.p_rsExtraData
                local FsReelDatasIndex = 0
                if rsExtraData then
                    local respinSpecial = rsExtraData.respinSpecial
                    if respinSpecial then
                        local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag
                        if respinSpecialFinishFlag and respinSpecialFinishFlag == "0" then
                            if respinSpecial.type then
                                Begintype = tonumber(respinSpecial.type)
                            end
                        end
                    end
                end
            end

            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
            -- 假滚修改
            if Begintype then
                if Begintype == self.SYMBOL_MID_LOCK then
                    reelDatas = self.m_configData:get_MID_LOCK_CloumnByColumnIndex(parentData.cloumnIndex)
                elseif Begintype == self.SYMBOL_ADD_WILD then
                    reelDatas = self.m_configData:get_ADD_WILD_CloumnByColumnIndex(parentData.cloumnIndex)
                elseif Begintype == self.SYMBOL_TWO_LOCK then
                    reelDatas = self.m_configData:get_TWO_LOCK_CloumnByColumnIndex(parentData.cloumnIndex)
                elseif Begintype == self.SYMBOL_Double_BET then
                    reelDatas = self.m_configData:get_Double_BET_CloumnByColumnIndex(parentData.cloumnIndex)
                end
            end
        end

        parentData.reelDatas = reelDatas

        --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
        if parentData.beginReelIndex == nil then
            parentData.beginReelIndex = util_random(1, #reelDatas)
        end

        self:checkReelIndexReason(parentData)

        parentData.isDone = false
        parentData.isResActionDone = false
        parentData.isReeling = false
        parentData.moveSpeed = self.m_configData.p_reelMoveSpeed
        parentData.isReeling = true
        self:createSlotNextNode(parentData)
        if self.m_configData.p_reelBeginJumpTime > 0 then
            --添加一个回弹效果
            local action0 = cc.JumpTo:create(self.m_configData.p_reelBeginJumpTime, cc.p(slotParent:getPositionX(), slotParent:getPositionY()), self.m_configData.p_reelBeginJumpHight, 1)

            local sequece =
                cc.Sequence:create(
                {
                    action0,
                    cc.CallFunc:create(
                        function()
                            self:registerReelSchedule()
                        end
                    )
                }
            )

            slotParent:runAction(sequece)
        else
            self:registerReelSchedule()
        end

        self:checkChangeClipParent(parentData)
    end
    self:checkChangeBaseParent()

    --- 某列不滚

    for i = 1, 3 do
        self:setOneReelsRunStates(i, true)
    end

    local effectData = {}

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag
            if respinSpecialFinishFlag and respinSpecialFinishFlag == "0" then
                local phase = respinSpecial.phase
                if phase then
                    local Begintype = tonumber(respinSpecial.type)
                    if phase == "idel" then -- 单个bonus游戏结束返回respin页面
                        if Begintype then
                            if Begintype == self.SYMBOL_MID_LOCK then
                                local isBigWild = true
                                for iRow = 1, self.m_iReelRowNum do
                                    local symbolType = self.m_stcValidSymbolMatrix[iRow][2]
                                    if symbolType ~= self.SYMBOL_Big_Wild then
                                        isBigWild = false
                                        break
                                    end
                                end
                                if isBigWild then
                                    -- 设置 中间列不滚动
                                    self:setOneReelsRunStates(2, false)
                                    --中间列小块播idle
                                    for i, v in ipairs(self.beerGirlWildList) do
                                        local node = self.beerGirlWildList[#self.beerGirlWildList]
                                        if node.p_symbolType == self.SYMBOL_Big_Wild then
                                            node:stopAllActions()
                                            node:runAnim("idle", true)
                                        end
                                    end
                                end
                            elseif Begintype == self.SYMBOL_TWO_LOCK then
                                local oneIsBigWild = true
                                for iRow = 1, self.m_iReelRowNum do
                                    local symbolType = self.m_stcValidSymbolMatrix[iRow][1]
                                    if symbolType ~= self.SYMBOL_Big_Wild then
                                        oneIsBigWild = false
                                        break
                                    end
                                end
                                if oneIsBigWild then
                                    -- 设置第1列不滚动
                                    self:setOneReelsRunStates(1, false)
                                end

                                local threeIsBigWild = true
                                for iRow = 1, self.m_iReelRowNum do
                                    local symbolType = self.m_stcValidSymbolMatrix[iRow][3]
                                    if symbolType ~= self.SYMBOL_Big_Wild then
                                        threeIsBigWild = false
                                        break
                                    end
                                end
                                if threeIsBigWild then
                                    -- 设置 第3列不滚动
                                    self:setOneReelsRunStates(3, false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenAllStarMachine:UnLockSymbolForCol(iCol)
    for iRow = self.m_iReelRowNum, 1, -1 do
        local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_Big_Wild then
            targSp:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            targSp:setVisible(false)
            targSp:runAnim("idleframe")
        end
    end
end

function CodeGameScreenAllStarMachine:showAllBigWild(iCol)
    for iRow = self.m_iReelRowNum, 1, -1 do
        local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_Big_Wild then
            targSp:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            targSp:setVisible(true)
            targSp:runAnim("idleframe")
        end
    end
end

function CodeGameScreenAllStarMachine:removeWildList()
    for i, v in ipairs(self.beerGirlWildList) do
        local node = self.beerGirlWildList[i]
        node:removeFromParent()
        if util_resetChildReferenceCount then
            util_resetChildReferenceCount(node)
        end
    end
    self.beerGirlWildList = {}
end

function CodeGameScreenAllStarMachine:LockSymbolForCol(iCol)
    for iRow = self.m_iReelRowNum, 1, -1 do
        local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_Big_Wild then
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local linePos = {}
            for i = 1, 3 do
                linePos[#linePos + 1] = {iX = i, iY = targSp.p_cloumnIndex}
            end

            table.insert(self.beerGirlWildList, targSp)
            local winLines = self.m_runSpinResultData.p_winLines
            if #winLines > 0 then
                targSp:runAnim("actionframe", true)
            end
        end
    end
end

function CodeGameScreenAllStarMachine:clearAllLocalLines()
    self.m_AllStarFrameLayer:removeAllChildren()
end

function CodeGameScreenAllStarMachine:showSpecialActLines(winLines)
    for k, v in pairs(winLines) do
        local lineId = v.iLineIdx
        local iLineSymbolNum = v.iLineSymbolNum
        if lineId then
            if lineId >= 0 and lineId < 9 then
                if iLineSymbolNum then
                    if iLineSymbolNum >= 3 then
                        local lines = util_createView("CodeAllStarSrc.AllStarLinesView", lineId)
                        lines:setTag(lineId)
                        self.m_AllStarFrameLayer:addChild(lines)
                        local pos = cc.p(self:getThreeReelsTarSpPos(4))
                        lines:setPosition(pos)
                    end
                end
            end
        end
    end

    local oldCoins = self.m_BonusScore or 0

    -- 每次播放赢钱线的时候刷新bonus赢钱
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            local totalWinAmount = respinSpecial.totalWinAmount
            self.m_BonusScore = totalWinAmount
            print("本轮一共的钱" .. self.m_BonusScore)

            -- bonus游戏结束如果 有普通bonus块先减去普通的，之后再播放 94 的动画时再加
            if respinSpecial.phase and respinSpecial.phase == "over" then
                local spinLines = respinSpecial.spinLines
                if spinLines then
                    for k, v in pairs(spinLines) do
                        local lines = v
                        self.m_BonusScore = self.m_BonusScore - lines.amount
                    end
                end

                print("去掉普通的钱" .. self.m_BonusScore)

                local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag
                if respinSpecialFinishFlag and respinSpecialFinishFlag == "1" then
                    local storedIcons = self.m_runSpinResultData.p_storedIcons
                    if #storedIcons == 9 and self:getBetLevel() == 1 then -- 全满了是Grand
                        local GrandScore, jpUiid = self:getJackPotScore(self.SYMBOL_FIX_GRAND)
                        print("grand  赢钱 " .. GrandScore)

                        self.m_BonusScore = self.m_BonusScore - GrandScore
                    end
                end
            end
        end
    end

    local coins = self.m_BonusScore
    local lastWinCoin = globalData.slotRunData.lastWinCoin

    if oldCoins > coins then
        print("--------")
    end

    globalData.slotRunData.lastWinCoin = 0
    local params = {}
    table.insert(params, coins - oldCoins)
    print("self.m_bottomUI:notifyUpdateWinLabel   3091")
    self:winCoinsSounds(params)
    self.m_bottomUI:notifyUpdateWinLabel(coins, false, true, oldCoins)
    globalData.slotRunData.lastWinCoin = lastWinCoin
end

function CodeGameScreenAllStarMachine:clearLineAndFrame()
    self:clearAllLocalLines()

    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end
end

function CodeGameScreenAllStarMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    print("showSpecialActLines-----")
    self:showSpecialActLines(winLines)

    if self.m_InBonus then
    else
        self:checkNotifyUpdateWinCoin()
    end

    self.m_lineSlotNodes = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end

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

function CodeGameScreenAllStarMachine:showEffect_LineFrame(effectData)
    self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    print("播放联系-----")
    self:showLineFrame()

    local waitTime = 0.1

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            local phase = respinSpecial.phase
            if phase == "over" then
                waitTime = 2
            end
        end
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        waitTime = 0.5
    end

    performWithDelay(
        self,
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        waitTime
    )

    return true
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function CodeGameScreenAllStarMachine:getThreeReelsTarSpPos(index)
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)

    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenAllStarMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenAllStarMachine:MachineRule_ResetReelRunData()
end

function CodeGameScreenAllStarMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_InBonus then
        local delayTime = 0.5
        if self.m_InBonus ~= true then
            delayTime = delayTime + self:getWinCoinTime()
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

function CodeGameScreenAllStarMachine:playEffectNotifyChangeSpinStatus()
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
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end

    if self.m_InBonus then
        self.m_bottomUI:updateBetEnable(false)
    end
end

function CodeGameScreenAllStarMachine:callSpinBtn()
    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_startSpinTime = nil
        end
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToAutospinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToAutospinReelRunLen()
            end
        end
    end

    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    if self.m_InBonus then
    else
        self:notifyClearBottomWinCoin()
    end

    local betCoin = self:getSpinCostCoins()
    local totalCoin = globalData.userRunData.coinNum

    -- freespin时不做钱的计算
    if self.m_InBonus ~= true and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and betCoin > totalCoin then
        --金币不足
        gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
        -- cxc 2023-12-05 15:57:06 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
        local checkOperaGuidePop = function()
            if tolua.isnull(self) then
                return
            end
            
            local betCoin = self:getSpinCostCoins() or toLongNumber(0)
            local totalCoin = globalData.userRunData.coinNum or 1
            if betCoin <= totalCoin then
                globalData.rateUsData:resetBankruptcyNoPayCount()
                self:showLuckyVedio()
                return
            end

            -- cxc 2023年12月02日13:57:48 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
            globalData.rateUsData:addBankruptcyNoPayCount()
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Bankruptcy", "BankruptcyNoPay_" .. globalData.rateUsData:getBankruptcyNoPayCount())
            if view then
                view:setOverFunc(util_node_handler(self, self.showLuckyVedio))
            else
                self:showLuckyVedio()
            end
        end
        gLobalPushViewControl:setEndCallBack(checkOperaGuidePop)
        
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        end
    else
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and self.m_InBonus ~= true then
            self:callSpinTakeOffBetCoin(betCoin)
        else
            self.m_spinNextLevel = globalData.userRunData.levelNum
            self.m_spinNextProVal = globalData.userRunData.currLevelExper
            self.m_spinIsUpgrade = false
        end

        --统计quest spin次数
        self:staticsQuestSpinData()

        self:spinBtnEnProc()

        self:setGameSpinStage(GAME_MODE_ONE_RUN)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
    end
    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end

local curWinType = 0
-- 增加赢钱后的 效果
function CodeGameScreenAllStarMachine:addLastBonusOverWinSomeEffect() -- add big win or mega win
    local overBonusWinCoins = 0

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial

        if respinSpecial then
            if respinSpecial.phase == "over" then
                if respinSpecial.preSpecialAmount then
                    overBonusWinCoins = respinSpecial.preSpecialAmount
                end
            end
        end
    end

    if overBonusWinCoins == 0 then
        return
    end

    if not self.m_InBonus then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    self.m_fLastWinBetNumRatio = overBonusWinCoins / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = overBonusWinCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = overBonusWinCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = overBonusWinCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = overBonusWinCoins
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

---
-- 增加赢钱后的 效果
function CodeGameScreenAllStarMachine:addLastWinSomeEffect() -- add big win or mega win
    if #self.m_vecGetLineInfo == 0 then
        return
    end

    local isEndBonus = false
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag

        if respinSpecialFinishFlag then
            if respinSpecialFinishFlag == "1" then
                isEndBonus = true
            end
        end
    end

    if self.m_InBonus or isEndBonus then
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
    curWinType = WinType.Normal
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

function CodeGameScreenAllStarMachine:getBottomUINode()
    return "CodeAllStarSrc.AllStarGameBottomNode"
end

--结束移除小块调用结算特效
function CodeGameScreenAllStarMachine:removeRespinNode()
    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local node = allEndNode[i]
        local targSp = self:getReelParent(node.p_cloumnIndex):getChildByTag(self:getNodeTag(node.p_cloumnIndex, node.p_rowIndex, SYMBOL_NODE_TAG))
        local addZOrder = 0

        if targSp then
            local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)

            if imageName ~= nil and not self:isFixSymbol(targSp.p_symbolType) then
                if imageName[1] then
                    local imgName = imageName[1]
                    node:removeAndPushCcbToPool()
                    if node.p_symbolImage == nil then
                        node.p_symbolImage = display.newSprite(imgName)
                        node:addChild(node.p_symbolImage)
                    else
                        node:spriteChangeImage(node.p_symbolImage, imgName)
                    end
                    node.p_symbolImage:setVisible(true)
                end
            end

            if self:isFixSymbol(targSp.p_symbolType) then
                addZOrder = 100
            end
            targSp:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end

        local symbolType = self.m_stcValidSymbolMatrix[node.p_rowIndex][node.p_cloumnIndex]

        if node.p_rowIndex == 2 then
            symbolType = self.SYMBOL_Blank
        else
            if symbolType == self.SYMBOL_Blank or symbolType == self.SYMBOL_Big_Wild then
                symbolType = self:getRandomSymbolType()
            end
        end

        local newNode = self:getSlotNodeWithPosAndType(symbolType, node.p_rowIndex, node.p_cloumnIndex, false)

        local posX, posY = node:getPosition()
        local worldPos = node:getParent():convertToWorldSpace(cc.p(posX, posY))
        local nodePos = self:getReelParent(node.p_cloumnIndex):convertToNodeSpace(worldPos)
        node:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)

        self:getReelParent(node.p_cloumnIndex):addChild(newNode, REEL_SYMBOL_ORDER.REEL_ORDER_2, node.p_cloumnIndex * SYMBOL_NODE_TAG + node.p_rowIndex)

        newNode.m_symbolTag = SYMBOL_NODE_TAG
        newNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
        newNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        newNode.m_isLastSymbol = false
        newNode.m_bRunEndTarge = false
        local columnData = self.m_reelColDatas[node.p_cloumnIndex]
        newNode.p_slotNodeH = columnData.p_showGridH
        newNode:setPosition(nodePos)
    end

    local slotParentDatas = self.m_slotParents
    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]
        local nodeTop = self:getFixSymbol(index, 3, SYMBOL_NODE_TAG)
        local nodeDown = self:getFixSymbol(index, 1, SYMBOL_NODE_TAG)
        local notCreateTop = false
        local notCreateDown = false
        if nodeTop.p_symbolType and nodeTop.p_symbolType ~= self.SYMBOL_Blank then
            notCreateTop = true
        end
        if nodeDown.p_symbolType and nodeDown.p_symbolType ~= self.SYMBOL_Blank then
            notCreateDown = true
        end
        self:createResNode(parentData, nodeTop, notCreateTop, notCreateDown, true)
    end

    self.m_respinView:removeFromParent()
    self.m_respinView = nil
end

---
-- 生成滚动序列
-- @param cloumGroupNums array 生成列对应组的数量 , 这个数量必须对应列的数量否则不执行
--
function CodeGameScreenAllStarMachine:produceReelSymbolList()
    if self.m_reelRunInfo == nil then
        return
    end

    local reelCount = #self.m_reelRunInfo -- 共有多少列信息

    if reelCount ~= self.m_iReelColumnNum then
        assert(false, "reelCount  ！= self.m_iReelColumnNum")
        return
    end
    local bottomResList = self.m_runSpinResultData.p_nextReel

    for cloumIndex = 1, reelCount, 1 do
        local columnDatas = self.m_reelSlotsList[cloumIndex]
        local parentData = self.m_slotParents[cloumIndex]
        local columnData = self.m_reelColDatas[cloumIndex]
        parentData.lastReelIndex = columnData.p_showGridCount -- 从最初起始开始滚动

        local nodeCount = self.m_reelRunInfo[cloumIndex]:getReelRunLen()
        -- local nodeList = {}
        for nodeIndex = 1, nodeCount do
            -- 由于初始创建了一组数据， 所以跨过第一组从后面开始
            if nodeIndex >= 1 and nodeIndex <= columnData.p_showGridCount then
                columnDatas[nodeIndex] = 0
            else
                local symbolType = self:getReelSymbolType(parentData) -- 根据规则随机产生信号
                -- 根据服务器传回来的数据获取 type ，检测是否是长条如果是长条不做处理 太麻烦了
                local bottomResType = nil
                if nodeIndex == nodeCount and bottomResList ~= nil and bottomResList[cloumIndex] ~= nil then
                    bottomResType = bottomResList[cloumIndex]
                    if self.m_bigSymbolInfos[bottomResType] ~= nil then
                        bottomResType = nil
                    end
                end
                if bottomResType ~= nil then
                    symbolType = bottomResType
                end

                if self.m_bigSymbolInfos[symbolType] ~= nil then
                    -- 大信号后面几个全部赋值为 symbolType  ******

                    if columnDatas[nodeIndex] == nil then
                        local addCount = self.m_bigSymbolInfos[symbolType]
                        local hasBigSymbol = false
                        for checkIndex = 1, addCount do -- 主要是判断后面是否有元素，如果有元素并且长度不足以放下长条元素则不再放置长条元素类型
                            local addedType = columnDatas[nodeIndex + checkIndex - 1]
                            if addedType ~= nil then
                                hasBigSymbol = true
                            end
                        end

                        if hasBigSymbol == false then -- 可以放置下长条元素，则直接将symbolType 赋值
                            for i = 1, addCount do
                                columnDatas[nodeIndex + i - 1] = symbolType
                            end
                        else
                            for i = 1, addCount do -- 这里是在补充非长条小块
                                local checkType = columnDatas[nodeIndex + i - 1]
                                if checkType == nil then
                                    local addType = self:getReelSymbolType(parentData)
                                    local index = 1
                                    if DEBUG == 2 then
                                    -- release_print("657 begin  %d" , addType)
                                    end
                                    while true do
                                        if self.m_bigSymbolInfos[addType] == nil then
                                            break
                                        end
                                        index = index + 1

                                        addType = self:getReelSymbolType(parentData)
                                    end
                                    if DEBUG == 2 then
                                    -- release_print("668 begin")
                                    end
                                    columnDatas[nodeIndex + i - 1] = addType
                                end
                            end -- end for i=1,addCount do
                        end
                    end -- end if columnDatas[nodeIndex] == nil then
                else
                    if columnDatas[nodeIndex] == nil then
                        columnDatas[nodeIndex] = symbolType
                    end
                end
            end
        end

        -- columnDatas[#columnDatas + 1] = nodeList
    end
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function CodeGameScreenAllStarMachine:getResNodeSymbolType(parentData, isOutLineEnter)
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
            if reelDatas == nil then
                reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
            end
        end
        local reelIndex = parentData.beginReelIndex or 1
        symbolType = reelDatas[reelIndex]

        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    local Begintype = nil
    -- if self.m_InBonus == true then
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local FsReelDatasIndex = 0
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial
        if respinSpecial then
            local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag

            if respinSpecialFinishFlag and respinSpecialFinishFlag == "0" then
                if respinSpecial.type and respinSpecial.phase then
                    if respinSpecial.phase == "idel" then
                        Begintype = tonumber(respinSpecial.type)
                    else
                        if tonumber(respinSpecial.preType) == self.SYMBOL_TWO_LOCK then
                            Begintype = tonumber(respinSpecial.preType)
                        end
                    end
                end
            elseif respinSpecialFinishFlag and respinSpecialFinishFlag == "1" then
                if respinSpecial.preType and respinSpecial.phase then
                    if respinSpecial.phase == "over" then
                        Begintype = tonumber(respinSpecial.preType)
                    end
                end
            end
        end
    end
    -- end

    -- 假滚修改
    if Begintype then
        if Begintype == self.SYMBOL_MID_LOCK then
            if colIndex == 2 then
                symbolType = self.SYMBOL_Blank
            end
        elseif Begintype == self.SYMBOL_TWO_LOCK then
            if colIndex == 1 or colIndex == 3 then
                symbolType = self.SYMBOL_Blank
            end
        end
    end

    if isOutLineEnter and symbolType == self.SYMBOL_Blank then
        symbolType = self:getRandomSymbolType()
    end

    return symbolType
end

--[[
    @desc: 获取滚动停止时下面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function CodeGameScreenAllStarMachine:getResDownNodeSymbolType(parentData, isOutLineEnter)
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_nextReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
            if reelDatas == nil then
                reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
            end
        end
        local reelIndex = parentData.beginReelIndex or 1
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    local Begintype = nil
    -- if self.m_InBonus == true then
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local FsReelDatasIndex = 0
    if rsExtraData then
        local respinSpecial = rsExtraData.respinSpecial
        if respinSpecial then
            local respinSpecialFinishFlag = rsExtraData.respinSpecialFinishFlag

            if respinSpecialFinishFlag and respinSpecialFinishFlag == "0" then
                if respinSpecial.type and respinSpecial.phase then
                    if respinSpecial.phase == "idel" then
                        Begintype = tonumber(respinSpecial.type)
                    else
                        if tonumber(respinSpecial.preType) == self.SYMBOL_TWO_LOCK then
                            Begintype = tonumber(respinSpecial.preType)
                        end
                    end
                end
            elseif respinSpecialFinishFlag and respinSpecialFinishFlag == "1" then
                if respinSpecial.preType and respinSpecial.phase then
                    if respinSpecial.phase == "over" then
                        Begintype = tonumber(respinSpecial.preType)
                    end
                end
            end
        end
    end
    -- end

    -- 假滚修改
    if Begintype then
        if Begintype == self.SYMBOL_MID_LOCK then
            if colIndex == 2 then
                symbolType = self.SYMBOL_Blank
            end
        elseif Begintype == self.SYMBOL_TWO_LOCK then
            if colIndex == 1 or colIndex == 3 then
                symbolType = self.SYMBOL_Blank
            end
        end
    end

    if symbolType == self.SYMBOL_Big_Wild then
        local LastYymbolType = self.m_stcValidSymbolMatrix[1][parentData.cloumnIndex]
        if LastYymbolType == self.SYMBOL_Big_Wild then
            symbolType = self.SYMBOL_Blank
        else
            symbolType = self:getRandomSymbolType()
        end
    end

    if isOutLineEnter and symbolType == self.SYMBOL_Blank then
        symbolType = self:getRandomSymbolType()
    end

    return symbolType
end

-----
---创建一行小块 用于一列落下时 上边条漏出空隙过大
function CodeGameScreenAllStarMachine:createResNode(parentData, lastNode, notCreateTop, notCreateDown, outLine)
    if self.m_bCreateResNode == false then
        return
    end

    local isOutLineEnter = outLine

    local rowIndex = parentData.rowIndex
    local addRandomNode = function()
        local symbolType = self:getResNodeSymbolType(parentData, isOutLineEnter)

        if self.m_bigSymbolInfos[symbolType] ~= nil then
            symbolType = self:getRandomSymbolType()
        end

        local slotParent = parentData.slotParent
        local columnData = self.m_reelColDatas[parentData.cloumnIndex]

        local node = self:getSlotNodeWithPosAndType(symbolType, columnData.p_showGridCount + 1, parentData.cloumnIndex, true)
        node.p_slotNodeH = columnData.p_showGridH
        node:setTag(-1)
        parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        local targetPosY = lastNode:getPositionY()

        local slotNodeH = columnData.p_showGridH

        if self.m_bigSymbolInfos[lastNode.p_symbolType] ~= nil then
            targetPosY = targetPosY + (self.m_bigSymbolInfos[lastNode.p_symbolType]) * slotNodeH
        else
            targetPosY = targetPosY + slotNodeH
        end
        -- node.
        node:setPosition(lastNode:getPositionX(), targetPosY)
        local order = 0

        if self.m_bigSymbolInfos[symbolType] ~= nil then
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 - node.p_rowIndex
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 - node.p_rowIndex
        end

        local iscreat = self:checkSpecialGame(isOutLineEnter)

        if iscreat then
            if node.p_symbolImage then
                node.p_symbolImage:setPositionY(-slotNodeH / 2)
            end
            local AnimationNode = node:getCCBNode()
            if AnimationNode then
                AnimationNode:setPositionY(-slotNodeH / 2)
            end

            if node.m_labUI then
                node.m_labUI:setPositionY(-slotNodeH / 2)
            end
        end

        slotParent:addChild(node, order)

        node:runIdleAnim()
    end

    local addDownRandomNode = function()
        local symbolType = self:getResDownNodeSymbolType(parentData, isOutLineEnter)

        if self.m_bigSymbolInfos[symbolType] ~= nil then
            symbolType = self:getRandomSymbolType()
        end

        local slotParent = parentData.slotParent
        local columnData = self.m_reelColDatas[parentData.cloumnIndex]

        local node = self:getSlotNodeWithPosAndType(symbolType, columnData.p_showGridCount + 1, parentData.cloumnIndex, true)
        node.p_slotNodeH = columnData.p_showGridH
        node:setTag(-1)
        parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        local targetPosY = lastNode:getPositionY()

        local slotNodeH = columnData.p_showGridH

        if self.m_bigSymbolInfos[lastNode.p_symbolType] ~= nil then
            targetPosY = targetPosY + (self.m_bigSymbolInfos[lastNode.p_symbolType]) * slotNodeH
        else
            targetPosY = targetPosY + slotNodeH
        end
        -- node.
        node:setPosition(lastNode:getPositionX(), targetPosY)
        local order = 0

        if self.m_bigSymbolInfos[symbolType] ~= nil then
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 - node.p_rowIndex
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 - node.p_rowIndex
        end

        if node.p_symbolImage then
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                node.p_symbolImage:setPositionY(-slotNodeH * 5.5)
            else
                local midSymbolType = self.m_stcValidSymbolMatrix[2][parentData.cloumnIndex]

                if midSymbolType == self.SYMBOL_Big_Wild then
                    node.p_isNeedChange = true
                    node.p_symbolImage:setPositionY(-slotNodeH * 4.5)
                else
                    node.p_symbolImage:setPositionY(-slotNodeH * 3.5)
                    if node.m_labUI then
                        node.m_labUI:setPositionY(-slotNodeH * 3.5)
                    end
                end
            end
        end
        local AnimationNode = node:getCCBNode()
        if AnimationNode then
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                AnimationNode:setPositionY(-slotNodeH * 5.5)
            else
                local midSymbolType = self.m_stcValidSymbolMatrix[2][parentData.cloumnIndex]

                if midSymbolType == self.SYMBOL_Big_Wild then
                    node.p_isNeedChange = true
                    AnimationNode:setPositionY(-slotNodeH * 4.5)
                else
                    AnimationNode:setPositionY(-slotNodeH * 3.5)
                end
            end
        end

        slotParent:addChild(node, order)

        node:runIdleAnim()
    end
    if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
        local bigSymbolCount = self.m_bigSymbolInfos[parentData.symbolType]
        if rowIndex > 1 and (rowIndex - 1) + bigSymbolCount > self.m_iReelRowNum then -- 表明跨过了 当前一组
            local iscreat = self:checkSpecialGame(isOutLineEnter)

            if iscreat then
                if notCreateDown then
                else
                    --表明跨组了 不创建小块
                    addDownRandomNode()
                end
            end
        else
            if notCreateTop then
            else
                --创建一个小块
                addRandomNode()
            end
        end
    else
        if notCreateTop then
        else
            --创建一个小块
            addRandomNode()
        end

        local iscreat = self:checkSpecialGame(isOutLineEnter)

        if iscreat then
            if notCreateDown then
            else
                --表明跨组了 不创建小块
                addDownRandomNode()
            end
        end
    end
end

---
-- 根据类型将节点放回到pool里面去
-- @param node 需要放回去的node ，在放回去时该清理的要清理完毕， 以免出现node 已经添加到了parent ，但是去除来后再addChild进去
--
function CodeGameScreenAllStarMachine:pushSlotNodeToPoolBySymobolType(symbolType, node)
    if node.m_labUI then
        node.m_labUI:removeFromParent()
        node.m_labUI = nil
    end

    if node then
        if node.p_symbolImage then
            node.p_symbolImage:setPositionY(0)
        end
        local AnimationNode = node:getCCBNode()
        if AnimationNode then
            AnimationNode:setPositionY(0)
        end
    end

    self.m_reelNodePool[#self.m_reelNodePool + 1] = node
    node:reset()
    node:stopAllActions()
end

function CodeGameScreenAllStarMachine:checkRestSlotNodePos()
    -- 还原reel parent 信息
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local posx, posy = slotParent:getPosition()
        slotParent:setPosition(0, 0) -- 还原位置信息

        local childs = slotParent:getChildren()
        --        printInfo("xcyy  剩余 child count %d", #childs)

        local lastType = nil
        local preRow = 0
        local maxLastNodePosY = nil
        local minLastNodePosY = nil

        local moveDis = nil
        for nodeIndex = 1, #childs do
            local childNode = childs[nodeIndex]
            if childNode.m_isLastSymbol == true then
                local childPosY = childNode:getPositionY()
                if maxLastNodePosY == nil then
                    maxLastNodePosY = childPosY
                elseif maxLastNodePosY < childPosY then
                    maxLastNodePosY = childPosY
                end

                if minLastNodePosY == nil then
                    minLastNodePosY = childPosY
                elseif minLastNodePosY > childPosY then
                    minLastNodePosY = childPosY
                end
                local columnData = self.m_reelColDatas[childNode.p_cloumnIndex]
                local nodeH = columnData.p_showGridH

                if self.m_bigSymbolInfos[childNode.p_symbolType] ~= nil then
                    -- childNode:setPositionY(nodeH * (childNode.p_rowIndex - 1) + nodeH * 0.5)
                    childNode:setPositionY(self.m_SlotNodeH * (childNode.p_rowIndex - 1) + self.m_SlotNodeH * 0.5)
                else
                    local addY = 0
                    if childNode.p_isNeedChange then
                        childNode.p_isNeedChange = nil
                        addY = nodeH

                        if childNode.p_symbolImage then
                            childNode.p_symbolImage:setPositionY(childNode.p_symbolImage:getPositionY() + addY)
                        end

                        local AnimationNode = childNode:getCCBNode()
                        if AnimationNode then
                            AnimationNode:setPositionY(AnimationNode:getPositionY() + addY)
                        end

                        if childNode.m_labUI then
                            childNode.m_labUI:setPositionY(AnimationNode:getPositionY() + addY)
                        end
                    end

                    childNode:setPositionY((nodeH * childNode.p_rowIndex - nodeH * 0.5))
                end

                if moveDis == nil then
                    moveDis = childPosY - childNode:getPositionY()
                end
            else
                --do nothing
            end

            childNode.m_isLastSymbol = false
        end

        --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
        local childs = slotParent:getChildren()
        for i = 1, #childs do
            local childNode = childs[i]
            if childNode.m_isLastSymbol == true then
                if childNode:getTag() < SYMBOL_NODE_TAG + BIG_SYMBOL_NODE_DIFF_TAG then
                    --将该节点放在 .m_clipParent
                    childNode:removeFromParent()
                    local posWorld = slotParent:convertToWorldSpace(cc.p(childNode:getPositionX(), childNode:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    childNode:setPosition(cc.p(pos.x, pos.y))
                    self.m_clipParent:addChild(childNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
                end
            end
        end

        -- printInfo(" xcyy %d  %d  ", parentData.cloumnIndex,parentData.symbolType)
        parentData:reset()
    end
end

--补丁找不到数据随机普通信号
function CodeGameScreenAllStarMachine:getRandomSymbolType()
    return math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, TAG_SYMBOL_TYPE.SYMBOL_SCORE_5)
end

--触发respin
function CodeGameScreenAllStarMachine:triggerReSpinCallFun(endTypes, randomTypes)
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

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
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)

    local LinesView = util_createView("CodeAllStarSrc.AllStarRespinLinesView")
    self.m_respinView:addChild(LinesView, 1000)
    local pos = cc.p(self:getThreeReelsTarSpPos(4))
    LinesView:setPosition(pos)

    self:initRespinView(endTypes, randomTypes)

    self.m_chipList = self.m_respinView:getAllCleaningNode()
    for k, v in pairs(self.m_chipList) do
        local node = v
        if node then
            local symbolType = node.p_symbolType
            if symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR then
                node:runAnim("idleframe", true)
            end
        end
    end
end

---
-- 显示赢钱掉落金币动画
function CodeGameScreenAllStarMachine:showEffect_NormalWin(effectData)
    performWithDelay(
        self,
        function()
            effectData.p_isPlay = true -- 临时写法
            self:playGameEffect()
        end,
        0.1
    )

    return true
end

function CodeGameScreenAllStarMachine:triggerReSpinOverCallFun(score, wait)
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

    local coins = nil

    if self.m_bProduceSlots_InFreeSpin then
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        coins = self:getLastWinCoin() or 0

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        coins = self.m_serverWinCoins or 0

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    if self.postReSpinOverTriggerBigWIn then
        self:postReSpinOverTriggerBigWIn(coins)
    end

    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()

    if not wait then
        self:playGameEffect()
    end
    --
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})

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

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenAllStarMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
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

function CodeGameScreenAllStarMachine:getRoandReelsData()
    local roandReelsData = {{}, {}, {}}
    local topRunData = {}
    local downRunData = {}

    for iCol = 1, self.m_iReelColumnNum do
        local colData = self.m_configData:get_ADD_WILD_CloumnByColumnIndex(iCol)
        local colDataIndex = math.random(1, #colData)
        for iRow = 1, 5 do
            if colDataIndex > #colData then
                colDataIndex = 1
            end

            local rowData = colData[colDataIndex]
            if iRow == 1 then
                table.insert(topRunData, rowData)
            elseif iRow == 5 then
                table.insert(downRunData, rowData)
            elseif iRow == 2 then
                table.insert(roandReelsData[1], rowData)
            elseif iRow == 3 then
                table.insert(roandReelsData[2], rowData)
            elseif iRow == 4 then
                table.insert(roandReelsData[3], rowData)
            end
            colDataIndex = colDataIndex + 1
        end
    end

    for k, v in pairs(topRunData) do
        if v == self.SYMBOL_FIX_SYMBOL then
            topRunData[k] = self:getRandomSymbolType()
        end
    end

    for k, v in pairs(downRunData) do
        if v == self.SYMBOL_FIX_SYMBOL then
            downRunData[k] = self:getRandomSymbolType()
        end
    end

    return topRunData, downRunData, roandReelsData
end

function CodeGameScreenAllStarMachine:removeAllReelsNode()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum + 1 do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

            if targSp then
                targSp:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end
        end
    end
end

function CodeGameScreenAllStarMachine:createRandomReelsNode()
    local topRunData, downRunData, roandReelsData = self:getRoandReelsData()
    self:removeAllReelsNode()

    -- dump(topRunData)
    -- dump(roandReelsData)
    -- dump(downRunData)

    for iCol = 1, self.m_iReelColumnNum do
        local parentData = self.m_slotParents[iCol]
        local slotParent = parentData.slotParent

        for iRow = 1, self.m_iReelRowNum do
            local symbolType = roandReelsData[iRow][iCol]

            if symbolType then
                local newNode = self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, false)

                local targSpPos = cc.p(self:getThreeReelsTarSpPos(4))

                parentData.slotParent:addChild(newNode, REEL_SYMBOL_ORDER.REEL_ORDER_2, iCol * SYMBOL_NODE_TAG + iRow)
                newNode.m_symbolTag = SYMBOL_NODE_TAG
                newNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
                newNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                newNode.m_isLastSymbol = false
                newNode.m_bRunEndTarge = false
                local columnData = self.m_reelColDatas[iCol]
                newNode.p_slotNodeH = columnData.p_showGridH
                newNode:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                local halfNodeH = columnData.p_showGridH * 0.5
                newNode:setPositionY((iRow - 1) * columnData.p_showGridH + halfNodeH)

                if newNode.p_symbolType and newNode.p_symbolType == self.SYMBOL_FIX_SYMBOL then
                    local score = math.random(1, 4)
                    local lineBet = globalData.slotRunData:getCurTotalBet()
                    score = score * lineBet
                    score = util_formatCoins(score, 3)
                    if newNode.m_labUI then
                        local lab = newNode.m_labUI:findChild("m_lb_score")
                        if lab then
                            lab:setString(score)
                        end
                    end
                end
            end
        end
    end

    self.m_runSpinResultData.p_nextReel = downRunData
    self.m_runSpinResultData.p_prevReel = topRunData

    local slotParentDatas = self.m_slotParents

    for index = 1, #slotParentDatas do
        local parentData = slotParentDatas[index]

        local slotParent = parentData.slotParent

        local child = slotParent:getChildren()

        for i, v in ipairs(child) do
            local node = v
            if node.p_rowIndex == 4 then
                node:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
            end
        end

        local nodeTop = self:getFixSymbol(index, 3, SYMBOL_NODE_TAG)
        local nodeDown = self:getFixSymbol(index, 1, SYMBOL_NODE_TAG)
        local notCreateTop = false
        local notCreateDown = false
        if nodeTop.p_symbolType and nodeTop.p_symbolType ~= self.SYMBOL_Blank then
            notCreateTop = true
        end
        if nodeDown.p_symbolType and nodeDown.p_symbolType ~= self.SYMBOL_Blank then
            notCreateDown = true
        end
        self:createResNode(parentData, nodeTop, notCreateTop, notCreateDown, true)
    end
end

function CodeGameScreenAllStarMachine:setLocalNodeZOrder()
    local name = {"logo", "Jackpot", "sp_reel_BG_Node", "sp_reel_0", "sp_reel_1", "sp_reel_2", "respin", "zhezhao", "reel_side", "reel_side_rs", "daban", "mulple", "bar"}
    for i = 1, #name do
        local node = self:findChild(name[i])
        if node then
            node:setLocalZOrder(i)
        end
    end
end

--增加过场弹板
function CodeGameScreenAllStarMachine:showGuoChang(func)
    gLobalSoundManager:playSound("AllStarSounds/AllStar_GuoChang.mp3")

    self.m_AllSatrGuoChangView:setVisible(true)

    util_spinePlay(self.m_AllSatrGuoChangView, "actionframe", false)
    performWithDelay(
        self,
        function()
            if func then
                func()
            end
        end,
        1.5
    )
end

--宙斯玩法：重新排序
function CodeGameScreenAllStarMachine:addWildPosSort(list)
    --从左到右排序 从上到下
    table.sort(
        list,
        function(a, b)
            local pos1 = self:getRowAndColByPos(a)
            local pos2 = self:getRowAndColByPos(b)

            if pos1.iY ~= pos2.iY then
                return pos1.iY > pos2.iY
            else
                return pos1.iX > pos2.iX
            end
        end
    )
end

--小恶魔玩法、宙斯玩法
function CodeGameScreenAllStarMachine:runFlyLineAct(startPos, endPos, func, type)
    --计算旋转角度
    local rotation = util_getAngleByPos(startPos, endPos)
    --计算两点之间距离
    local distance = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
    -- -- 创建粒子
    local flyNode = util_createAnimation("AllStar_Bonus6_trail.csb")
    if type then
        flyNode = util_createAnimation("Bonusshuoming_trail.csb")
    end
    self:addChild(flyNode, 10000)
    flyNode:setPosition(startPos)
    flyNode:setRotation(-rotation)
    flyNode:setScaleX(distance / 600)

    flyNode:runCsbAction(
        "actionframe",
        false,
        function()
            flyNode:removeFromParent()
        end
    )
    -- performWithDelay(self,function (  )
    if func then
        func()
    end
    -- end,0.3)
end

--[[
    @desc: 
    author:{author}
    time:2021-07-30 17:03:21
    @return:self.bonusIndex == 1:啤酒女
            self.bonusIndex == 2:宙斯
            self.bonusIndex == 3:小恶魔
            self.bonusIndex == 4:靴子猫
]]
function CodeGameScreenAllStarMachine:getWinSoundPath(soundIndex)
    local soundName = nil
    if self.bonusIndex == 1 then
        soundName = "AllStarSounds/music_AllStar_last_BeerGirl_win_" .. soundIndex .. ".mp3"
    elseif self.bonusIndex == 2 then
        soundName = "AllStarSounds/music_AllStar_last_Zeus_win_" .. soundIndex .. ".mp3"
    elseif self.bonusIndex == 3 then
        soundName = "AllStarSounds/music_AllStar_last_WickedBlaze_win_" .. soundIndex .. ".mp3"
    elseif self.bonusIndex == 4 then
        soundName = "AllStarSounds/music_AllStar_last_Puss_win_" .. soundIndex .. ".mp3"
    else
        soundName = "AllStarSounds/music_AllStar_last_win_" .. soundIndex .. ".mp3"
    end
    return soundName
end

function CodeGameScreenAllStarMachine:getLittleViewSound(bonusIndex)
    local soundPath = nil
    if bonusIndex == self.SYMBOL_MID_LOCK then
        soundPath = "AllStarSounds/music_AllStar_bonus_littleView_1.mp3"
    elseif bonusIndex == self.SYMBOL_ADD_WILD then
        soundPath = "AllStarSounds/music_AllStar_bonus_littleView_2.mp3"
    elseif bonusIndex == 3 then
        soundPath = "AllStarSounds/music_AllStar_bonus_littleView_3.mp3"
    elseif bonusIndex == self.SYMBOL_TWO_LOCK then
        soundPath = "AllStarSounds/music_AllStar_bonus_littleView_4.mp3"
    else
        soundPath = "AllStarSounds/music_AllStar_bonus_littleView_1.mp3"
    end
    return soundPath
end

return CodeGameScreenAllStarMachine
