---
-- island
-- 2018年6月4日
-- CodeGameScreenLinkFishMachine.lua
--
-- 玩法：
--

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local CollectData = require "data.slotsdata.CollectData"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenLinkFishMachine = class("CodeGameScreenLinkFishMachine", BaseSlotoManiaMachine)

CodeGameScreenLinkFishMachine.m_lightScore = 0

-- 配置respin 结算时鱼飞行轨迹的 csb 文件
CodeGameScreenLinkFishMachine.m_chipFly1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 19
CodeGameScreenLinkFishMachine.m_chipFly2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 20
CodeGameScreenLinkFishMachine.m_chipFly3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 21
CodeGameScreenLinkFishMachine.m_chipFly4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 22
CodeGameScreenLinkFishMachine.m_chipFly5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 23
CodeGameScreenLinkFishMachine.m_chipFly6 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 24
CodeGameScreenLinkFishMachine.m_chipFly7 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 25
CodeGameScreenLinkFishMachine.m_chipFly8 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 26
CodeGameScreenLinkFishMachine.m_chipFly9 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 27

CodeGameScreenLinkFishMachine.FLY_COIN_TYPE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 40

-- 锁定两种信号类型，只是对应不同倍数
CodeGameScreenLinkFishMachine.m_bnBase1Type = 101
CodeGameScreenLinkFishMachine.m_bnBase2Type = 102

CodeGameScreenLinkFishMachine.SYMBOL_FIX_MINI = 103
CodeGameScreenLinkFishMachine.SYMBOL_FIX_MINOR = 104
CodeGameScreenLinkFishMachine.SYMBOL_FIX_MAJOR = 105

CodeGameScreenLinkFishMachine.m_isMachineBGPlayLoop = true
CodeGameScreenLinkFishMachine.m_bCanClickMap = nil
CodeGameScreenLinkFishMachine.m_bSlotRunning = nil
CodeGameScreenLinkFishMachine.m_vecFixWild = nil
CodeGameScreenLinkFishMachine.m_bIsBonusFreeGame = nil
CodeGameScreenLinkFishMachine.m_iBonusFreeTimes = nil

CodeGameScreenLinkFishMachine.m_vecBigLevel = {4, 8, 13, 19}
CodeGameScreenLinkFishMachine.m_iReelMinRow = 3

local RESPIN_BIG_REWARD_MULTIP = 5000
local RESPIN_BIG_REWARD_SYMBOL_NUM = 15
CodeGameScreenLinkFishMachine.m_winSoundsId = nil
CodeGameScreenLinkFishMachine.m_mapNodePos = nil
CodeGameScreenLinkFishMachine.FLY_COIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136
-- 构造函数
function CodeGameScreenLinkFishMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_lightScore = 0
    self.m_winSoundsId = nil
    self.m_bRespinStart = false

    self.m_jackpot_status = "Normal"
    self.m_isJackpotEnd = false
    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

function CodeGameScreenLinkFishMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("LinkFishConfig.csv", "LevelLinkFishConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function CodeGameScreenLinkFishMachine:scaleMainLayer()
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
        if display.height >= FIT_HEIGHT_MAX then
            mainScale = (FIT_HEIGHT_MAX - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            mainScale = mainScale + 0.05
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            if (display.height / display.width) >= 2 then
                self.m_gameBg:findChild("LinkFish_bg_zs1_14"):setScaleY(2.3)
                self.m_gameBg:findChild("LinkFish_bg_zs2_15"):setScaleY(2.3)
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 14)
            else
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 22)
            end
        elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        else
            mainScale = (display.height + 40 - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 25)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

function CodeGameScreenLinkFishMachine:initUI()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")

    self:findChild("respin_strip_node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self:findChild("respin_strip_node"):setVisible(false)
    self.m_winFrame = util_createView("CodeLinkFishSrc.LinkFishWinFrame")
    local targetNode = self:findChild("m_targetPos")
    targetNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    targetNode:addChild(self.m_winFrame)

    util_setCsbVisible(self.m_winFrame, false)

    self.m_jackPotBar = util_createView("CodeLinkFishSrc.LinkFishTopBar")
    self:findChild("m_jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    -- self:findChild("m_jackpot"):setVisible(false)

    self.m_PandaToFish = util_createView("CodeLinkFishSrc.LinkFishChangePandaToFish")
    self.m_PandaToFish:setVisible(false)
    self:addChild(self.m_PandaToFish, 10000)
    self.m_PandaToFish:setPosition(self:findChild("panda_to_fish"):getPosition())

    self.m_bonepanda, self.m_bonepandaAction = createBoneBody("LinkFish_top_panda_HuXi.csb", 1, 120) --_texture  骨骼动画文件路径
    self.m_pandeMagic = self.m_bonepanda -- util_createView("CodeLinkFishSrc.LinkFishFirePandaMagic")
    self.m_pandeMagic:setPosition(0, -55)
    mGotoFrameAndPlay(self.m_bonepanda, self.m_bonepandaAction, 1, 120, true)

    self:findChild("m_panda"):addChild(self.m_pandeMagic)
    -- self:findChild("m_panda"):setVisible(false)

    self.m_jackPotFishNum = util_createView("CodeLinkFishSrc.LinkFishJackPotNum",{machine = self})
    self:findChild("m_collect"):addChild(self.m_jackPotFishNum)
    util_setCsbVisible(self.m_jackPotFishNum, false)

    self.m_jackPotWin = util_createView("CodeLinkFishSrc.LinkFishJackpotWinCoin")
    self:findChild("m_collect"):addChild(self.m_jackPotWin)
    util_setCsbVisible(self.m_jackPotWin, false)

    self:initFreeSpinBar()
    --竖屏free spin 次数显示
    self.m_baseFreeSpinBar = util_createView("CodeLinkFishSrc.LinkFishFreeSpinBar")
    targetNode:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)

    self.m_bonusFreeGameBar = util_createView("CodeLinkFishSrc.LinkFishBnousFreeGameBar")
    targetNode:addChild(self.m_bonusFreeGameBar)
    self.m_bonusFreeGameBar:setPositionY(self.m_baseFreeSpinBar:getPositionY() + 90)
    self.m_bonusFreeGameBar:setVisible(false)

    self.m_respinStratBtn = util_createView("CodeLinkFishSrc.LinkFishRespinStartBtn")
    targetNode:addChild(self.m_respinStratBtn)
    util_setCsbVisible(self.m_respinStratBtn, false)
    self.m_respinStratBtn:initCallFunc(
        function()
            self:runNextReSpinReel()
        end
    )

    self.m_progress = util_createView("CodeLinkFishSrc.LinkFishBnousProgress")
    self:findChild("progress"):addChild(self.m_progress)

    self:findChild("Node_4x5"):setVisible(false)

    if display.height > FIT_HEIGHT_MAX then
        -- self.m_pandeMagic:setPositionY(self.m_pandeMagic:getPositionY() + posY * 0.5 )
        -- self.m_jackPotFishNum:setPositionY(self.m_jackPotFishNum:getPositionY() + posY * 0.5 )
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local nodeLunpan = self:findChild("Node_lunpan")
        nodeLunpan:setPositionY(nodeLunpan:getPositionY() - posY)
        local nodeCollect = self:findChild("m_collect")
        nodeCollect:setPositionY(nodeCollect:getPositionY() - posY)
        local nodePanda = self:findChild("m_panda")
        nodePanda:setPositionY(nodePanda:getPositionY() - posY)
        targetNode:setPositionY(targetNode:getPositionY() - posY)
        local nodeProgress = self:findChild("progress")
        nodeProgress:setPositionY(nodeProgress:getPositionY() - posY)
        local nodeMap = self:findChild("map")
        nodeMap:setPositionY(nodeMap:getPositionY() - posY)

        local nodeJackpot = self:findChild("m_jackpot")
        if (display.height / display.width) >= 2 then
            nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY + 18 - 85)
        else
            nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY - 85)
        end
    elseif display.height < FIT_HEIGHT_MIN then
        local nodeJackpot = self:findChild("m_jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - 5)
    end

    if globalData.slotRunData.isPortrait then
        local bangHeight = util_getBangScreenHeight()
        local nodeJackpot = self:findChild("m_jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - bangHeight)
    end

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet

            local soundIndex = 1
            local soundTime = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 3
            elseif winRate > 3 then
                soundIndex = 3
                soundTime = 3
            end
            local soundName = "LinkFishSounds/music_LinkFish_last_win_" .. soundIndex .. ".mp3"
            globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    -- gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
    --     -- 播放音效freespin
    --     gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_lightning_count_3.mp3")
    -- end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

--ReSpin结算改变UI状态
function CodeGameScreenLinkFishMachine:changeReSpinOverUI()
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinBar()
    end
end

function CodeGameScreenLinkFishMachine:initJackpotInfo(jackpotPool, lastBetId)
    self.m_jackPotBar:updateJackpotInfo()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenLinkFishMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LinkFish"
end

function CodeGameScreenLinkFishMachine:getNetWorkModuleName()
    return "PandaBlessV2"
end

function CodeGameScreenLinkFishMachine:getRespinView()
    return "CodeLinkFishSrc.LinkFishRespinView"
end

function CodeGameScreenLinkFishMachine:getRespinNode()
    return "CodeLinkFishSrc.LinkFishRespinNode"
end

-- 重写 getSlotNodeWithPosAndType 方法
function CodeGameScreenLinkFishMachine:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, iRow, iCol, isLastSymbol)

    -- symbolType == self.SYMBOL_FIX_CHIP or
    if symbolType == self.m_bnBase1Type or symbolType == self.m_bnBase2Type or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR then
        --下帧调用 才可能取到 x y值
        -- local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        -- reelNode:runAction(callFun)
        self:setSpecialNodeScore(nil, {reelNode})
    end
    return reelNode
end

function CodeGameScreenLinkFishMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
        return nil
    end

    local pos = self:getRowAndColByPos(idNode)
    local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if type < 1000 then
        if type ~= self.m_bnBase1Type and type ~= self.m_bnBase2Type then
            if score == 10 then
                score = "MINI"
            elseif score == 50 then
                score = "MINOR"
            elseif score == 150 then
                score = "MAJOR"
            end
        end
    end
    return score
end

function CodeGameScreenLinkFishMachine:setSpecialNodeScore(sender, parma)
    local symbolNode = parma[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --获取分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            local avgBet = self:getAvgbet()
            if avgBet then
                lineBet = avgBet
            end
            score = score * lineBet
            score = util_formatCoins(score, 3, false, true, true)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
            end
        end
        if symbolNode then
            symbolNode:runAnim("idleframe", true)
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            local avgBet = self:getAvgbet()
            if avgBet then
                lineBet = avgBet
            end
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3, false, true, true)
            if symbolNode then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
            end
        end
        if symbolNode then
            symbolNode:runAnim("idleframe", true)
        end
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenLinkFishMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.m_bnBase1Type or symbolType == self.m_bnBase2Type then
        return "Socre_LinkFish_Chip"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_LinkFish_Mini"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_LinkFish_Minor"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_LinkFish_Major"
    elseif symbolType == self.m_chipFly2 then
        return "Socre_LinkFish_Chip_Fly2"
    elseif symbolType == self.m_chipFly3 then
        return "Socre_LinkFish_Chip_Fly3"
    elseif symbolType == self.m_chipFly4 then
        return "Socre_LinkFish_Chip_Fly4"
    elseif symbolType == self.m_chipFly5 then
        return "Socre_LinkFish_Chip_Fly5"
    elseif symbolType == self.m_chipFly6 then
        return "Socre_LinkFish_Chip_Fly6"
    elseif symbolType == self.m_chipFly7 then
        return "Socre_LinkFish_Chip_Fly7"
    elseif symbolType == self.m_chipFly8 then
        return "Socre_LinkFish_Chip_Fly8"
    elseif symbolType == self.m_chipFly9 then
        return "Socre_LinkFish_Chip_Fly9"
    elseif symbolType == self.FLY_COIN_TYPE then
        return "Bonus_LinkFish_panda_fly"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenLinkFishMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.m_bnBase1Type, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.m_bnBase2Type, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MAJOR, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly6, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly7, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly8, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.m_chipFly9, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.FLY_COIN_TYPE, count = 2}
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenLinkFishMachine:setLockDataInfo()
    self.m_allLockNodeReelPos = {}
    for i = 1, #self.m_runSpinResultData.p_storedIcons do
        local iconInfo = self.m_runSpinResultData.p_storedIcons[i]
        self.m_allLockNodeReelPos[#self.m_allLockNodeReelPos + 1] = {iconInfo[1], iconInfo[2]}
    end
end

function CodeGameScreenLinkFishMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if self.m_bProduceSlots_InFreeSpin then
        if symbolType == self.m_bnBase1Type then
            score = self.m_configData:getBnFSPro1()
        elseif symbolType == self.m_bnBase2Type then
            score = self.m_configData:getBnFSPro2()
        end
    else
        if symbolType == self.m_bnBase1Type then
            score = self.m_configData:getBnBasePro1()
        elseif symbolType == self.m_bnBase2Type then
            score = self.m_configData:getBnBasePro2()
        end
    end

    return score
end

function CodeGameScreenLinkFishMachine:getChangeSymbolType(score)
    if score == 10 then
        return self.SYMBOL_FIX_MINI
    elseif score == 50 then
        return self.SYMBOL_FIX_MINOR
    elseif score == 150 then
        return self.SYMBOL_FIX_MAJOR
    else
        return nil
    end
end

--ReSpin开始改变UI状态
function CodeGameScreenLinkFishMachine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_jackPotFishNum, true)
    util_setCsbVisible(self.m_winFrame, true)
    -- util_setCsbVisible(self.m_pandeMagic,false)

    self.m_pandeMagic:setVisible(false)

    self:findChild("respin_strip_node"):setVisible(true)
    -- 如果是最大respin次数才停止
    if respinCount and respinCount == 3 then
        util_setCsbVisible(self.m_respinStratBtn, true)
        self.m_respinStratBtn:setAction(
            true,
            function()
            end
        )

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_SHOW_SPECIAL_SPIN) -- 显示特殊spin按钮
    end

    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_winFrame:updateLeftCount(respinCount)
    local storedIcons = #self.m_runSpinResultData.p_storedIcons
    self.m_jackPotFishNum:updateCollectNum(storedIcons)
    self.m_respinView:setUpdateCallFun(
        function()
            local nownNum = self.m_jackPotFishNum:getCollectNowNum()
            self.m_jackPotFishNum:updateCollectNum(nownNum + 1)
        end
    )
    self.m_respinView:setUpdateRespinNum(
        function()
            self.m_winFrame:updateLeftCount(3)
        end
    )
end

--ReSpin刷新数量
function CodeGameScreenLinkFishMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_winFrame:updateLeftCount(curCount)
end

function CodeGameScreenLinkFishMachine:getIsHaveMajor()
    for i = 1, #self.m_allLockNodeReelPos do
        local iconInfo = self.m_allLockNodeReelPos[i]
        if iconInfo[2] == 1000 then
            return true
        end
    end
    return false
end

function CodeGameScreenLinkFishMachine:addRepsinCountNum(num)
    self.m_reSpinsTotalCount = num + self.m_reSpinsTotalCount
    self.m_reSpinCurCount = num
end

function CodeGameScreenLinkFishMachine:getUnRespinNodePos()
    local lockPos = {}
    for i = 1, #self.m_allLockNodeReelPos do
        local idx = self.m_allLockNodeReelPos[i][1]
        lockPos[idx] = i
    end

    local unLockPos = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local reelIdx = self:getPosReelIdx(iRow, iCol)
            if lockPos[reelIdx] == nil then
                unLockPos[#unLockPos + 1] = {iX = iRow, iY = iCol}
            end
        end
    end
    return unLockPos
end

function CodeGameScreenLinkFishMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self, reelCol)

    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for k = 1, self.m_iReelRowNum do
            if self.m_stcValidSymbolMatrix[k][reelCol] == 101 or self.m_stcValidSymbolMatrix[k][reelCol] == 102 then
                isHaveFixSymbol = true
                break
            end
        end
        if isHaveFixSymbol == true then
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds(reelCol, "LinkFishSounds/music_LinkFish_fall_" .. reelCol .. ".mp3", "LinkFishFixSymbol")
            else
                gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_fall_" .. reelCol .. ".mp3")
            end
        end
    end
end

function CodeGameScreenLinkFishMachine:slotReelDown()
    BaseSlotoManiaMachine.slotReelDown(self)
    if self.m_bRespinStart == true then
        return
    end
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenLinkFishMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if (self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE) and self.m_bIsInBonusGame ~= true then
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
    end

    self.m_bSlotRunning = false
    if self.m_bRespinStart == true then
        return
    end
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenLinkFishMachine:levelFreeSpinEffectChange()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "change_freespin")
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenLinkFishMachine:levelFreeSpinOverChangeEffect()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "change_normal")
end
---------------------------------------------------------------------------

function CodeGameScreenLinkFishMachine:getIsBigLevel()
    for i = 1, #self.m_vecBigLevel, 1 do
        if self.m_vecBigLevel[i] == self.m_nodePos then
            return true
        end
    end
    return false
end

function CodeGameScreenLinkFishMachine:showEffect_Bonus(effectData)
    self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.currPosition
    if self.m_bonusReconnect ~= true then
        self.m_mapNodePos = self.m_nodePos
    else
        self.m_bonusReconnect = false
    end

    

    -- self:updateMapData(self.m_runSpinResultData.p_selfMakeData.map)

    local bonusGame = function()
        -- 播放震动
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "bonus")
        end

        local gameType = self.m_bonusData[self.m_nodePos].type
        if gameType == "SMALL" then
            performWithDelay(
                self,
                function()
                    self:clearCurMusicBg()
                    gLobalSoundManager:playSound("LinkFishSounds/sound_LinkFish_bonusgame_start.mp3", false)
                    performWithDelay(
                        self,
                        function()
                            self:resetMusicBg()
                        end,
                        3
                    )
                    self.m_bottomUI:showAverageBet()
                    self:bonusGameStart(
                        function()
                            -- self.m_currentMusicBgName = "LinkFishSounds/music_LinkFish_bonusgame_bgm.mp3"
                            -- self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
                            local bonusView = util_createView("CodeLinkFishSrc.LinkFishBnousGameLayer", self.m_nodePos)
                            bonusView:initViewData(
                                function(coins, extraGame)
                                    self:bonusGameOver(
                                        coins,
                                        extraGame,
                                        function()
                                            self:showBonusMap(
                                                function()
                                                    self:MachineRule_checkTriggerFeatures()
                                                    self:addNewGameEffect()
                                                    self.m_progress:resetProgress(
                                                        self.m_bonusData[self.m_nodePos + 1].levelID,
                                                        function()
                                                            effectData.p_isPlay = true
                                                            self:playGameEffect()
                                                            self.m_bottomUI:hideAverageBet()
                                                            -- self:resetMusicBg()
                                                        end
                                                    )
                                                end,
                                                self.m_nodePos
                                            )

                                            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(coins))
                                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                                        end
                                    )
                                    bonusView:removeFromParent()
                                end,
                                self
                            )
                            if globalData.slotRunData.machineData.p_portraitFlag then
                                bonusView.getRotateBackScaleFlag = function()
                                    return false
                                end
                            end
                            gLobalViewManager:showUI(bonusView)
                            -- self:addChild(bonusView, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
                            self.m_bottomUI:checkClearWinLabel()
                        end
                    )
                end,
                0
            )
        else
            if self.m_mapNodePos ~= self.m_nodePos then
                self.m_mapNodePos = self.m_nodePos
            end
            self:clearCurMusicBg()
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_iBonusFreeTimes = self.m_iFreeSpinTimes
            self.m_bIsBonusFreeGame = true
            gLobalSoundManager:playSound("LinkFishSounds/sound_LinkFish_bonusgame_start.mp3")
            local ownerlist = {}
            ownerlist["m_lb_num"] = self.m_iFreeSpinTimes
            local view =
                self:showDialog(
                "BonusFreeGame",
                ownerlist,
                function()
                    -- gLobalSoundManager:playSound("CharmsSounds/Charms_GuoChang.mp3")
                    -- function( )

                    -- 调用此函数才是把当前游戏置为freespin状态
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()

                    -- if self.m_nodePos == #self.m_bonusPath then
                    --     self.m_map:resetMapUI()
                    -- end
                    -- end
                end,
                BaseDialog.AUTO_TYPE_ONLY
            )

            performWithDelay(
                self,
                function()
                    self:bonusFreeGameInfo()
                    self:initFixWild()
                    globalData.slotRunData.lastWinCoin = 0
                    self.m_bottomUI:checkClearWinLabel()
                    self.m_bottomUI:showAverageBet()
                    self.m_progress:setVisible(false)
                end,
                1
            )

            for i = 1, 5 do
                view:findChild("extra_id_" .. i):setVisible(false)
                view:findChild("dui_" .. i):setVisible(false)
                view:findChild("cha_" .. i):setVisible(false)
                if i < 5 then
                    view:findChild("fix_wild_" .. i):setVisible(false)
                end
            end

            local info = self.m_bonusData[self.m_nodePos]
            view:findChild("fix_wild_" .. info.levelID):setVisible(true)
            for i = 1, #info.allGames, 1 do
                view:findChild("extra_id_" .. i):setVisible(true)
                local tittle = util_createView("CodeLinkFishSrc.LinkFishBnousExtraGamesTittle")
                view:findChild("extra_words_" .. i):addChild(tittle)
                tittle:unselected(info.allGames[i])
                view:findChild("cha_" .. i):setVisible(true)
                for j = 1, #info.extraGames, 1 do
                    if info.extraGames[j] == info.allGames[i] then
                        tittle:selected(info.allGames[i])
                        view:findChild("dui_" .. i):setVisible(true)
                        view:findChild("cha_" .. i):setVisible(false)
                        break
                    end
                end
            end
        end
    end

    performWithDelay(
        self,
        function()
            bonusGame()
        end,
        1
    )

    -- performWithDelay(self, function()
    --     self:showBonusMap(bonusGame, self.m_nodePos)
    -- end, 2)

    return true
end

function CodeGameScreenLinkFishMachine:initFixWild()
    local vecFixWild = nil
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.lockWild ~= nil then
        vecFixWild = self.m_runSpinResultData.p_selfMakeData.lockWild
    end
    if vecFixWild == nil then
        return
    end
    self:clearWinLineEffect()
    self:resetMaskLayerNodes()

    for i = 1, #vecFixWild, 1 do
        local fixPos = self:getRowAndColByPos(vecFixWild[i])
        local targSp = self:getReelParentChildNode(fixPos.iY, fixPos.iX)
        if not targSp then
            local colParent = self:getReelParent(fixPos.iY)
            local children = colParent:getChildren()
            for i = 1, #children, 1 do
                local child = children[i]
                if child.p_cloumnIndex == fixPos.iY and child.p_rowIndex == fixPos.iX then
                    targSp = child
                    break
                end
            end
        end
        if targSp then
            if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local wild = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
                targSp:getParent():addChild(wild)
                wild:setPosition(targSp:getPositionX(), targSp:getPositionY())
                wild.p_cloumnIndex = targSp.p_cloumnIndex
                wild.p_rowIndex = targSp.p_rowIndex
                wild.m_isLastSymbol = targSp.m_isLastSymbol
                wild:setTag(targSp:getTag())
                targSp:removeFromParent()
                local symbolType = targSp.p_symbolType
                self:pushSlotNodeToPoolBySymobolType(symbolType, targSp)
                targSp = nil
                targSp = wild
            end
            targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000)
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

            if self.m_vecFixWild == nil then
                self.m_vecFixWild = {}
            end
            self.m_vecFixWild[#self.m_vecFixWild + 1] = targSp
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
        end
    end
end

function CodeGameScreenLinkFishMachine:changeReelData()
    self:findChild("Node_4x5"):setVisible(false)
    self:findChild("Node_3x5"):setVisible(false)
    self:findChild("Node_" .. self.m_iReelRowNum .. "x5"):setVisible(true)
    if self.m_iReelRowNum == self.m_iReelMinRow then
        self.m_baseFreeSpinBar:setPositionY(0)
        self.m_bonusFreeGameBar:setPositionY(self.m_baseFreeSpinBar:getPositionY() + 90)
        self.m_stcValidSymbolMatrix[4] = nil
    else
        self.m_baseFreeSpinBar:setPositionY(self.m_SlotNodeH)
        self.m_bonusFreeGameBar:setPositionY(self.m_baseFreeSpinBar:getPositionY() + 90)
        if self.m_stcValidSymbolMatrix[4] == nil then
            self.m_stcValidSymbolMatrix[4] = {92, 92, 92, 92, 92}
        end
    end
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x,
                y = rect.y,
                width = rect.width,
                height = columnData.p_slotColumnHeight
            }
        )
    end
end

function CodeGameScreenLinkFishMachine:bonusFreeGameInfo()
    self.m_fsReelDataIndex = 1
    local info = self.m_bonusData[self.m_nodePos]
    local m4IsWild = false
    local isAddWild = false
    local isAddRow = false
    local isAddWheel = false
    local isDoubleWin = false
    for i = 1, #info.extraGames, 1 do
        local game = info.extraGames[i]
        if game == 2 or game == 12 or game == 17 then
            m4IsWild = true
        end
        if game == 6 then
            isDoubleWin = true
        end
        if game == 3 or game == 18 then
            isAddWild = true
        end
        if game == 11 then
            isAddRow = true
        end
        if game == 15 then
            isAddWheel = true
        end
    end
    if m4IsWild == true and isAddWild == true then
        self.m_fsReelDataIndex = 4
    elseif m4IsWild == true then
        self.m_fsReelDataIndex = 2
    elseif isAddWild == true then
        self.m_fsReelDataIndex = 3
    end

    if m4IsWild == true then
        self.m_bonusFreeGameBar:setVisible(true)
        self.m_bonusFreeGameBar:m4IsWild()
    end

    if isDoubleWin == true then
        self.m_bonusFreeGameBar:setVisible(true)
        self.m_bonusFreeGameBar:doubleWins()
    end

    if isAddRow == true then
        self.m_iReelRowNum = 4
        self:changeReelData()
    end

    if isAddWheel == true then
        self.m_jackPotBar:setVisible(false)
        self.m_bonusGameReel = util_createView("CodeLinkFishSrc.LinkFishBonusGameMachine")
        self:findChild("Node_Bonus_Game"):addChild(self.m_bonusGameReel)

        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_bonusGameReel.getRotateBackScaleFlag = function()
                return false
            end
        end

        if self.m_runSpinResultData.p_storedIcons ~= nil then
            self.m_bonusGameReel:setStoredIcons(self.m_runSpinResultData.p_storedIcons)
        end
        if self.m_runSpinResultData.p_selfMakeData.otherReel == nil then
            self.m_bonusGameReel:initSlotNode(self.m_runSpinResultData.p_reels)
        else
            self.m_bonusGameReel:initSlotNode(self.m_runSpinResultData.p_selfMakeData.otherReel.reels)
        end

        self.m_bonusGameReel:initFixWild(self.m_runSpinResultData.p_selfMakeData.lockWild)
        self.m_bonusGameReel:setFSReelDataIndex(self.m_fsReelDataIndex)

        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end
end

function CodeGameScreenLinkFishMachine:showEffect_FreeSpin(effectData)
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
        gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_trigger_fs.mp3")

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

function CodeGameScreenLinkFishMachine:triggerFreeSpinOverCallFun()
    self:checkQuestDoneGameEffect()
    BaseSlotoManiaMachine.triggerFreeSpinOverCallFun(self)
end
function CodeGameScreenLinkFishMachine:updateQuestDone()
    --TODO  后续考虑优化修改 , 检测是否有quest effect ， 将其位置信息放到quest 前面
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == true then
        self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
        local questEffect = GameEffectData:create()
        questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
        questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
        self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
    end
end
--检测是否可以增加quest 完成事件
function CodeGameScreenLinkFishMachine:checkQuestDoneGameEffect()
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

function CodeGameScreenLinkFishMachine:bonusGameStart(func)
    return self:showDialog(BaseDialog.DIALOG_TYPE_BONUS_START, nil, func)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenLinkFishMachine:bonusGameOver(coins, extraGame, func)
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("LinkFishSounds/sound_LinkFish_bonusgame_over.mp3", false)
    performWithDelay(
        self,
        function()
            self:resetMusicBg()
        end,
        2
    )

    if extraGame == nil then
        self:showDialog(BaseDialog.DIALOG_TYPE_BONUS_OVER, ownerlist, func)
    else
        local view = self:showDialog("BonusOver2", ownerlist, func)
        local tittle = util_createView("CodeLinkFishSrc.LinkFishBnousExtraGamesDialog", self.m_nodePos)
        view:findChild("Extra_Game"):addChild(tittle)
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenLinkFishMachine:showFreeSpinView(effectData)
    -- 停掉背景音乐
    self:clearCurMusicBg()

    -- gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_show_view.mp3")
    gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_show_view.mp3")

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinMore(
            self.m_runSpinResultData.p_freeSpinNewCount,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            true
        )
    else
        self:showFreeSpinStart(
            self.m_iFreeSpinTimes,
            function()
                gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_touch_view_btn.mp3")
                self.m_progress:setVisible(false)
                self:triggerFreeSpinCallFun()

                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end
end
function CodeGameScreenLinkFishMachine:showFreeSpinOverView()
    self:updateQuestDone()
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    if self.m_fsReelDataIndex ~= 0 then
        self.m_fsReelDataIndex = 0
    end
    if self.m_bIsBonusFreeGame == true then
        gLobalSoundManager:playSound("LinkFishSounds/sound_LinkFish_bonusgame_over.mp3")
        self.m_bIsBonusFreeGame = false
        local ownerlist = {}
        ownerlist["m_lb_num"] = self.m_iBonusFreeTimes
        ownerlist["m_lb_coins"] = strCoins
        local view =
            self:showDialog(
            "BonusFreeGameOver",
            ownerlist,
            function()
                self.m_PandaToFish:setVisible(true)
                self.m_PandaToFish:actionChange(
                    false,
                    function()
                        self.m_PandaToFish:setVisible(false)
                        self:showBonusMap(
                            function()
                                self:MachineRule_checkTriggerFeatures()
                                self:addNewGameEffect()

                                local index = nil
                                if self.m_nodePos < #self.m_bonusData then
                                    index = self.m_bonusData[self.m_nodePos + 1].levelID
                                else
                                    self.m_map:mapReset()
                                end
                                self.m_progress:resetProgress(
                                    index,
                                    function()
                                        self:triggerFreeSpinOverCallFun()
                                    end
                                )
                                -- self:resetMusicBg()
                            end,
                            self.m_nodePos
                        )
                    end
                )
                performWithDelay(
                    self,
                    function()
                        self.m_bonusFreeGameBar:setVisible(false)
                        self.m_bottomUI:hideAverageBet()
                        self.m_progress:setVisible(true)

                        if self.m_vecFixWild ~= nil and #self.m_vecFixWild > 0 then
                            for i = #self.m_vecFixWild, 1, -1 do
                                local symbol = self.m_vecFixWild[i]
                                if symbol then
                                    if symbol and symbol.updateLayerTag then
                                        symbol:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                                    end
                                    symbol:setVisible(false)
                                    symbol:removeFromParent()
                                    self:pushSlotNodeToPoolBySymobolType(symbol.p_symbolType, symbol)
                                end
                                table.remove(self.m_vecFixWild, i)
                            end
                        end

                        self:clearWinLineEffect()
                        self:resetMaskLayerNodes()

                        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.baseReels ~= nil then
                            self:removeAllReelsNode()
                        end
                        util_setCsbVisible(self.m_baseFreeSpinBar, false)
                        if self.m_iReelRowNum > self.m_iReelMinRow then
                            self.m_iReelRowNum = self.m_iReelMinRow
                            self:changeReelData()
                        end
                        if self.m_bonusGameReel ~= nil then
                            self.m_jackPotBar:setVisible(true)
                            self.m_bonusGameReel:removeFromParent()
                            self.m_bonusGameReel = nil
                        end

                        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.baseReels ~= nil then
                            self:createRandomReelsNode()
                        end
                    end,
                    1
                )
            end
        )
        local node = view:findChild("m_lb_coins")

        view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 632)
        for i = 1, 5 do
            view:findChild("extra_id_" .. i):setVisible(false)
            view:findChild("dui_" .. i):setVisible(false)
            view:findChild("cha_" .. i):setVisible(false)
        end

        local info = self.m_bonusData[self.m_nodePos]
        for i = 1, #info.allGames, 1 do
            view:findChild("extra_id_" .. i):setVisible(true)
            local tittle = util_createView("CodeLinkFishSrc.LinkFishBnousExtraGamesTittle")
            view:findChild("extra_words_" .. i):addChild(tittle)
            tittle:unselected(info.allGames[i])
            view:findChild("cha_" .. i):setVisible(true)
            for j = 1, #info.extraGames, 1 do
                if info.extraGames[j] == info.allGames[i] then
                    tittle:selected(info.allGames[i])
                    view:findChild("dui_" .. i):setVisible(true)
                    view:findChild("cha_" .. i):setVisible(false)
                    break
                end
            end
        end
    else
        gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_over_view.mp3")
        local view =
            self:showFreeSpinOver(
            strCoins,
            self.m_runSpinResultData.p_freeSpinsTotalCount,
            function()
                gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_touch_view_btn.mp3")
                self.m_progress:setVisible(true)
                self:triggerFreeSpinOverCallFun()
            end
        )
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_STATUS,false)
        local node = view:findChild("m_lb_coins")

        view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 632)
    end
end
local function getStructSymbolMulti(MainClass, iRow, iCol) --- 得到小块的分数 add by az on 11.20
    if MainClass.m_vecStructMultiple == nil then
        return 1 -- 如果没有定义这个字段就 返回1倍
    end
    for i = 1, #MainClass.m_vecStructMultiple do
        local multyInfo = MainClass.m_vecStructMultiple[i]
        if multyInfo[1] == iRow and multyInfo[2] == iCol then
            return multyInfo[3]
        end
    end
    return 1 --- 如果没有这个值也返回1倍
end

function CodeGameScreenLinkFishMachine:removeAllReelsNode()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

            if targSp then
                targSp:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end
        end
    end
    --bugly-21.12.01-这个地方需要清空一下 连线信号列表 不然操作已经被放入池子的信号会有问题
    self.m_lineSlotNodes = {}
end

function CodeGameScreenLinkFishMachine:createRandomReelsNode()
    self.m_runSpinResultData.p_reels = self.m_runSpinResultData.p_selfMakeData.baseReels
    local reels = {}
    for iRow = 1, 3 do
        reels[iRow] = self.m_runSpinResultData.p_selfMakeData.baseReels[#self.m_runSpinResultData.p_selfMakeData.baseReels - iRow + 1]
    end

    for iCol = 1, self.m_iReelColumnNum do
        local parentData = self.m_slotParents[iCol]
        local slotParent = parentData.slotParent

        for iRow = 1, 3 do
            local symbolType = reels[iRow][iCol]

            if symbolType then
                local newNode = self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, false)
                if newNode:getParent() then
                    print("qaq")
                end
                newNode:removeFromParent() -- 暂时补丁
                parentData.slotParent:addChild(newNode, REEL_SYMBOL_ORDER.REEL_ORDER_2, iCol * SYMBOL_NODE_TAG + iRow)
                newNode.m_symbolTag = SYMBOL_NODE_TAG
                newNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
                newNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                newNode.m_isLastSymbol = true
                newNode.m_bRunEndTarge = false
                local columnData = self.m_reelColDatas[iCol]
                newNode.p_slotNodeH = columnData.p_showGridH
                newNode:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                local halfNodeH = columnData.p_showGridH * 0.5
                newNode:setPositionY((iRow - 1) * columnData.p_showGridH + halfNodeH)
            end
        end
    end
end

-- --重写组织respinData信息
function CodeGameScreenLinkFishMachine:getRespinSpinData()
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

-- RespinView
function CodeGameScreenLinkFishMachine:showRespinView(effectData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_WIN_RESPIN)
    self.m_bRespinStart = true
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_enter_bonus.mp3")
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
        {type = self.m_bnBase1Type, runEndAnimaName = "", bRandom = true},
        {type = self.m_bnBase2Type, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "", bRandom = false}
    }

    local avgBet = self:getAvgbet()
    if avgBet then --显示平均bet
        self.m_bottomUI:showAverageBet()
        self.m_bottomUI:updateWinCount("")
    end

    --构造盘面数据
    scheduler.performWithDelayGlobal(
        function()
            scheduler.performWithDelayGlobal(
                function()
                    gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_trigger_respinSymbol.mp3")
                end,
                0.5,
                self:getModuleName()
            )
            self.m_bRespinStart = false
            self:setMaxMusicBGVolume()
            self:removeSoundHandler()
            if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
                self:triggerReSpinCallFun(endTypes, randomTypes)
            else
                -- 由玩法触发出来， 而不是多个元素触发
                if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                    self.m_runSpinResultData.p_reSpinCurCount = 3
                end
                self:triggerReSpinCallFun(endTypes, randomTypes)
            end
        end,
        2.5,
        self:getModuleName()
    )
end

function CodeGameScreenLinkFishMachine:initRespinView(endTypes, randomTypes)
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
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
                    if self.m_map:getMapIsShow() == true then
                        self:showBonusMap()
                    end
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    -- 如果是最大值就停止然后点击开始如果
                    if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinCurCount ~= 3 then
                        self:runNextReSpinReel()
                    end
                end
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

-- 重写Respinstar
function CodeGameScreenLinkFishMachine:showReSpinStart(func)
    self:clearCurMusicBg()

    self.m_PandaToFish:setVisible(true)
    self.m_PandaToFish:actionChange(
        false,
        function()
            self.m_PandaToFish:setVisible(false)
        end
    )
    performWithDelay(
        self,
        function()
            self.m_progress:setVisible(false)
        end,
        1
    )
    scheduler.performWithDelayGlobal(
        function()
            if not (globalData.slotRunData.currSpinMode == FREE_SPIN_MODE) then
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal_respin")
            else
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin_respin")
            end
        end,
        0.8,
        self:getModuleName()
    )
    scheduler.performWithDelayGlobal(
        function()
            if func then
                func()
            end
        end,
        1.2,
        self:getModuleName()
    )

    -- self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func,BaseDialog.AUTO_TYPE_ONLY)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

-- --结束移除小块调用结算特效
function CodeGameScreenLinkFishMachine:reSpinEndAction()
    scheduler.performWithDelayGlobal(
        function()
            self.m_winFrame:updateLeftCount(0)
            gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_spin_respin_RunOver.mp3")
            self:clearCurMusicBg()
            scheduler.performWithDelayGlobal(
                function()
                    self:playTriggerLight()
                end,
                2,
                self:getModuleName()
            )
        end,
        1,
        self:getModuleName()
    )
end

function CodeGameScreenLinkFishMachine:playTriggerLight(reSpinOverFunc)
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- gLobalSoundManager:stopBackgroudMusic()
    self:clearCurMusicBg()

    self.m_chipList = self.m_respinView:getAllCleaningNode()

    local nDelayTime = #self.m_chipList * (0.1 + 0.85)
    self:playChipCollectAnim()

    util_setCsbVisible(self.m_jackPotFishNum, false)
    util_setCsbVisible(self.m_winFrame, false)
    util_setCsbVisible(self.m_jackPotWin, true)
    -- self.m_jackPotWin:showCollectCoin(util_formatCoins(0,30))
end

function CodeGameScreenLinkFishMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        if #self.m_chipList >= 15 then
            local jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Grand
            self.m_lightScore = self.m_lightScore + jackpotScore
            self:showRespinJackpot(
                4,
                util_formatCoins(jackpotScore, 12),
                function()
                    self:playLightEffectEnd()
                end
            )
        else
            scheduler.performWithDelayGlobal(
                function()
                    self:playLightEffectEnd()
                end,
                0.1,
                self:getModuleName()
            )
        end
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(), chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol

    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = -1

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local avgBet = self:getAvgbet()
    if avgBet then
        lineBet = avgBet
    end

    if score ~= nil then
        if chipNode.p_symbolType == self.SYMBOL_FIX_MINI then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Mini
            addScore = jackpotScore + addScore ---self:BaseMania_getJackpotScore(4)
            nJackpotType = 1
        elseif chipNode.p_symbolType == self.SYMBOL_FIX_MINOR then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Minor
            addScore = jackpotScore + addScore ---self:BaseMania_getJackpotScore(3)
            nJackpotType = 2
        elseif chipNode.p_symbolType == self.SYMBOL_FIX_MAJOR then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Major
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif type(score) ~= "string" then
            addScore = score * lineBet
            
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function fishFlyEndJiesuan()
        if nJackpotType == -1 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim()
        else
            gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_show_view.mp3")

            self:showRespinJackpot(
                nJackpotType,
                util_formatCoins(jackpotScore, 12),
                function()
                    self.m_playAnimIndex = self.m_playAnimIndex + 1
                    self:playChipCollectAnim()
                end
            )
        end
    end
    -- 添加鱼飞行轨迹
    local function fishFly()
        local fishFly = util_createView("CodeLinkFishSrc.LinkFishFishFly")

        fishFly:setPosition(nodePos.x, nodePos.y)
        self.m_clipParent:addChild(fishFly, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        fishFly:initFish(nFixIdx)
        fishFly:runAnimByName("link_tip")

        gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_fish_fly.mp3")
        scheduler.performWithDelayGlobal(
            function()
                fishFly:removeFromParent()

                gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_respin_reward.mp3")
                self.m_jackPotWin:showCollectCoin(util_formatCoins(self.m_lightScore, 30))

                scheduler.performWithDelayGlobal(
                    function()
                        fishFlyEndJiesuan()
                    end,
                    1,
                    self:getModuleName()
                )
            end,
            1,
            self:getModuleName()
        )
    end

    chipNode:runAnim("begin_zhuan")
    chipNode:setLocalZOrder(10000 + self.m_playAnimIndex)
    local nBeginAnimTime = chipNode:getAniamDurationByName("begin_zhuan")

    scheduler.performWithDelayGlobal(
        function()
            fishFly()
        end,
        9 / 30,
        self:getModuleName()
    )

    scheduler.performWithDelayGlobal(
        function()
            -- chipNode:runIdleAnim()
            chipNode:runAnim("end", true)
        end,
        nBeginAnimTime,
        self:getModuleName()
    )
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenLinkFishMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    self.m_winSoundsId = nil
    if self.m_map:getMapIsShow() == true then
        self:showBonusMap()
    end
    self.m_bSlotRunning = true
    return false
end

function CodeGameScreenLinkFishMachine:beginReel()
    BaseSlotoManiaMachine.beginReel(self)

    if self.m_bonusGameReel ~= nil then
        self.m_bonusGameReel:beginReel()
    end
end

--开始滚动
function CodeGameScreenLinkFishMachine:startReSpinRun()
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
    else
        gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_spin_respin.mp3")
    end

    BaseSlotoManiaMachine.startReSpinRun(self)
end

----
--- 处理spin 成功消息
--
function CodeGameScreenLinkFishMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or (self:getIsBigLevel() == true and spinData.action == "FEATURE") then
        release_print("消息返回胡来了")

        if self.m_bonusGameReel ~= nil then
            local resultData = spinData.result.selfData.otherReel
            resultData.bet = 1
            self.m_bonusGameReel:netWorkCallFun(resultData)
        end

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end

-- lighting 完毕之后 播放动画
function CodeGameScreenLinkFishMachine:playLightEffectEnd()
    local cleaningNode = self.m_respinView:getFixSlotsNode()
    for i = 1, #cleaningNode do
        local lastNode = cleaningNode[i]
        lastNode:getCcbProperty("imgbg_1"):setVisible(true)
    end
    self:respinOver()
end

function CodeGameScreenLinkFishMachine:showRespinJackpot(index, coins, func)
    gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_show_view.mp3")
    local jackPotWinView = util_createView("CodeLinkFishSrc.LinkFishJackPotWinView",{machine = self})
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index, coins, self, func)
end

function CodeGameScreenLinkFishMachine:showRespinOverView(effectData)
    scheduler.performWithDelayGlobal(
        function()
            local seq =
                cc.Sequence:create(
                cc.DelayTime:create(0.5),
                cc.CallFunc:create(
                    function()
                        util_setCsbVisible(self.m_winFrame, false)

                        self.m_jackPotBar:setVisible(true)
                    end
                )
            )

            self:runAction(seq)
            local strCoins = util_formatCoins(self.m_lightScore, 50)
            gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_over_view.mp3")

            local view =
                self:showReSpinOver(
                strCoins,
                function()
                    -- util_setCsbVisible(self.m_fireworks,true)
                    -- self.m_fireworks:showFireEffect()

                    gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_touch_view_btn.mp3")
                    self:triggerReSpinOverCallFun(self.m_lightScore)
                    self.m_bottomUI:hideAverageBet()
                    self.m_lightScore = 0
                    self:resetMusicBg()
                    if not (globalData.slotRunData.currSpinMode == FREE_SPIN_MODE) then
                        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "respin_normal")
                        self.m_progress:setVisible(true)
                    else
                        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "respin_freespin")
                    end

                    -- scheduler.performWithDelayGlobal(function()
                    util_setCsbVisible(self.m_jackPotWin, false)
                    self.m_jackPotWin:showCollectCoin(util_formatCoins(0, 30))
                    -- util_setCsbVisible(self.m_pandeMagic,true)
                    self.m_pandeMagic:setVisible(true)
                    self:findChild("respin_strip_node"):setVisible(false)
                    -- end,0.5)
                    self.m_isRespinOver = true
                end
            )
            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 632)
        end,
        2,
        self:getModuleName()
    )
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenLinkFishMachine:operaEffectOver()
    CodeGameScreenLinkFishMachine.super.operaEffectOver(self)

    if self.m_isRespinOver then
        self.m_isRespinOver = false
        --公共jackpot
        local midReel = self:findChild("sp_reel_2")
        local size = midReel:getContentSize()
        local worldPos = util_convertToNodeSpace(midReel,self)
        worldPos.x = worldPos.x + size.width / 2
        worldPos.y = worldPos.y + size.height / 2
        if G_GetMgr(ACTIVITY_REF.CommonJackpot) then
            G_GetMgr(ACTIVITY_REF.CommonJackpot):playEntryFlyAction(worldPos,function()

            end)
        end
    end
    
end

-- 断线重连
function CodeGameScreenLinkFishMachine:MachineRule_initGame(spinData)
    -- if spinData.p_bonusStatus == "OPEN" and self.m_bonusPath[self.m_nodePos] ~= 0 then
    --     self.m_fsReelDataIndex = self.m_bonusPath[self.m_nodePos]
    --     self.m_progress:setVisible(false)
    -- end

    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_progress:setVisible(false)
    end

    if self:BaseMania_isTriggerCollectBonus() then
        if self.m_bonusData[self.m_nodePos].type == "BIG" and self.m_initSpinData.p_freeSpinsLeftCount and self.m_initSpinData.p_freeSpinsLeftCount > 0 then
            self:bonusFreeGameInfo()
            self:initFixWild()
            self.m_bIsBonusFreeGame = true
            self.m_progress:setVisible(false)
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_iBonusFreeTimes = self.m_iFreeSpinTimes
            self.m_bIsBonusFreeGame = true
            util_setCsbVisible(self.m_baseFreeSpinBar, true)
            self.m_bottomUI:showAverageBet()
            self:setCurrSpinMode(FREE_SPIN_MODE)
        else
            self.m_progress:setVisible(true)
        end
        self.m_mapNodePos = self.m_nodePos - 1
        self.m_bonusReconnect = true
        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        end
    end
end

function CodeGameScreenLinkFishMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == false then
        -- self:BaseMania_completeCollectBonus()
        -- self:updateCollect()
        self:playGameEffect()
        return
    end

    if featureData.p_status == "OPEN" then
        local bonusView = util_createView("CodeLinkFishSrc.LinkFishBnousGameLayer", self.m_nodePos)
        -- performWithDelay(self, function()
        --     self:clearCurMusicBg()
        --     self.m_currentMusicBgName = "LinkFishSounds/music_LinkFish_bonusgame_bgm.mp3"
        --     self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        -- end, 3)

        bonusView:resetView(
            featureData,
            (function(coins, extraGame)
                self:bonusGameOver(
                    coins,
                    extraGame,
                    function()
                        self:showBonusMap(
                            function()
                                self.m_bIsInBonusGame = false
                                self:MachineRule_checkTriggerFeatures()
                                self:addNewGameEffect()
                                self.m_progress:resetProgress(
                                    self.m_bonusData[self.m_nodePos + 1].levelID,
                                    function()
                                        self:resetMusicBg()
                                        self:playGameEffect()
                                    end
                                )
                            end,
                            self.m_nodePos
                        )

                        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(coins))
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                    end
                )
                bonusView:removeFromParent()

                self.m_progress:setVisible(true)
            end),
            self
        )
        if globalData.slotRunData.machineData.p_portraitFlag then
            bonusView.getRotateBackScaleFlag = function()
                return false
            end
        end
        gLobalViewManager:showUI(bonusView)
        -- self:addChild(bonusView, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
        self.m_bottomUI:checkClearWinLabel()
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
        self.m_mapNodePos = self.m_nodePos - 1
    end
end

function CodeGameScreenLinkFishMachine:MachineRule_checkTriggerFeatures()
    if self.m_fsReelDataIndex ~= 0 or self:getCurrSpinMode() == RESPIN_MODE then
        return
    end

    if self.m_runSpinResultData.p_features ~= nil and #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0

        local featureID = self.m_runSpinResultData.p_features[featureLen]
        table.remove(self.m_runSpinResultData.p_features, featureLen)
        -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的，
        -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
        if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
            featureID = SLOTO_FEATURE.FEATURE_FREESPIN
        end
        if featureID ~= 0 then
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                --发送测试特殊玩法
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)

                if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_newTrigger ~= true then
                    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                else
                    -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                    globalData.slotRunData.totalFreeSpinCount = 0
                    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                end

                globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes
            elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then -- 触发respin 玩法
                globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                if self:getCurrSpinMode() == RESPIN_MODE then
                else
                    local respinEffect = GameEffectData.new()
                    respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                    respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                    if globalData.slotRunData.iReSpinCount == 0 and #self.m_runSpinResultData.p_storedIcons == 15 then
                        respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                        respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                    end
                    self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                end
            elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                -- 添加 BonusEffect
                self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                --发送测试特殊玩法
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
            elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
            end
        end
    end
end

function CodeGameScreenLinkFishMachine:checkNetDataFeatures()
    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end

    local featureId = featureDatas[#featureDatas]
    table.remove(featureDatas, #featureDatas)
    if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
        -- self:sortGameEffects( )
        -- self:playGameEffect()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        -- 添加freespin effect
        local freeSpinEffect = GameEffectData.new()
        freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
        freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

        self.m_isRunningEffect = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

        for lineIndex = 1, #self.m_initSpinData.p_winLines do
            local lineData = self.m_initSpinData.p_winLines[lineIndex]
            local checkEnd = false
            for posIndex = 1, #lineData.p_iconPos do
                local pos = lineData.p_iconPos[posIndex]

                local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                local colIndex = pos % self.m_iReelColumnNum + 1

                local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    checkEnd = true
                    local lineInfo = self:getReelLineInfo()
                    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER

                    for addPosIndex = 1, #lineData.p_iconPos do
                        local posData = lineData.p_iconPos[addPosIndex]
                        local rowColData = self:getRowAndColByPos(posData)
                        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
                    end

                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                    self.m_reelResultLines = {}
                    self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                    break
                end
            end
            if checkEnd == true then
                break
            end
        end
        --更新fs次数ui 显示
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
    elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
    elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- respin 玩法一并通过respinCount 来进行判断处理
    elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        -- if self.m_initFeatureData.p_status=="CLOSED" then
        --     return
        -- end

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        -- 添加bonus effect
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

        self.m_isRunningEffect = true

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        for lineIndex = 1, #self.m_initSpinData.p_winLines do
            local lineData = self.m_initSpinData.p_winLines[lineIndex]
            local checkEnd = false
            for posIndex = 1, #lineData.p_iconPos do
                local pos = lineData.p_iconPos[posIndex]

                local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                local colIndex = pos % self.m_iReelColumnNum + 1

                local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    checkEnd = true
                    local lineInfo = self:getReelLineInfo()
                    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                    for addPosIndex = 1, #lineData.p_iconPos do
                        local posData = lineData.p_iconPos[addPosIndex]
                        local rowColData = self:getRowAndColByPos(posData)
                        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
                    end

                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                    self.m_reelResultLines = {}
                    self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                    break
                end
            end
            if checkEnd == true then
                break
            end
        end
    end
end

function CodeGameScreenLinkFishMachine:checkHasFeature()
    local hasFeature = false

    if self.m_initSpinData ~= nil and self.m_initSpinData.p_features ~= nil and #self.m_initSpinData.p_features > 0 then
        for i = 1, #self.m_initSpinData.p_features do
            local featureID = self.m_initSpinData.p_features[i]
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN or featureID == SLOTO_FEATURE.FEATURE_RESPIN then
                hasFeature = true
            end
        end
    end

    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN)
    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
    hasFeature = hasFeature or self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        hasFeature = true
    end

    if (self.m_initFeatureData ~= nil and self.m_initFeatureData.p_status == "OPEN") or self:BaseMania_isTriggerCollectBonus() then
        hasFeature = true
    end

    return hasFeature
end

function CodeGameScreenLinkFishMachine:addNewGameEffect()
    globalData.slotRunData.totalFreeSpinCount = (globalData.slotRunData.totalFreeSpinCount or 0) + self.m_iFreeSpinTimes
    local effectLen = #self.m_vecSymbolEffectType
    for i = 1, effectLen do
        local value = self.m_vecSymbolEffectType[i]
        local effectData = GameEffectData.new()
        effectData.p_effectType = value
        --                                effectData.p_effectData = data
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end

function CodeGameScreenLinkFishMachine:checkTriggerINFreeSpin()
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true or self.m_initSpinData.p_features[#self.m_initSpinData.p_features] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        return true
    end
    return BaseSlotoManiaMachine.checkTriggerINFreeSpin(self)
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenLinkFishMachine:initCloumnSlotNodesByNetData()
    BaseSlotoManiaMachine.initCloumnSlotNodesByNetData(self)

    self:initFixWild()
end

function CodeGameScreenLinkFishMachine:addSelfEffect()
    if self.m_iBetLevel == 1 and globalData.slotRunData.currSpinMode ~= RESPIN_MODE and globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if node then
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        if not self.m_collectList then
                            self.m_collectList = {}
                        end
                        self.m_collectList[#self.m_collectList + 1] = node
                    end
                end
            end
        end
    end

    if self.m_collectList and #self.m_collectList > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FLY_COIN_EFFECT

        --是否触发收集小游戏
        if self:BaseMania_isTriggerCollectBonus() then -- true or
            -- local selfEffect = GameEffectData.new()
            -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
            -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            -- selfEffect.p_selfEffectType = self.BONUS_GAME_EFFECT
            self.m_bHaveBonusGame = true
        end
    end
    self:updateQuestDone()
end

function CodeGameScreenLinkFishMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenLinkFishMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.FLY_COIN_EFFECT then
        self:collectPanda(effectData)
        self:updateQuestDone()
    end

    return true
end

function CodeGameScreenLinkFishMachine:collectPanda(effectData)
    local endPos = self.m_progress:getCollectPos()
    gLobalSoundManager:playSound("LinkFishSounds/sound_LinkFish_collect_panda.mp3")
    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local coins = self:getSlotNodeBySymbolType(self.FLY_COIN_TYPE)
        if i == 1 then
            coins.m_isLastSymbol = true
        end
        self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        coins:setScale(self.m_machineRootScale)
        coins:setPosition(newStartPos)

        local delayTime = 0
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true or self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            delayTime = 0.5
        end

        coins:runAnim("shouji")
        -- performWithDelay(self, function()
        if self.m_bHaveBonusGame ~= true and coins.m_isLastSymbol == true then
            performWithDelay(
                self,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                delayTime
            )
        end
        -- local particle = cc.ParticleSystemQuad:create("effect/Golden_Charms_Fly_gold.plist")
        -- coins:addChild(particle,10)
        -- particle:setPosition(0, 0)
        local pecent = self:getProgress(self:BaseMania_getCollectData())
        local bez = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        local callback = function()
            if coins.m_isLastSymbol == true then
                self.m_progress:updatePercent(pecent)
                -- gLobalSoundManager:playSound("CharmsSounds/sound_Charms_tramcar_move.mp3")
                if self.m_bHaveBonusGame == true and coins.m_isLastSymbol == true then
                    -- self:clearCurMusicBg()
                    performWithDelay(
                        self,
                        function()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                            self.m_bHaveBonusGame = false
                        end,
                        2.1
                    )
                end
            end
        end
        coins:runAction(
            cc.Sequence:create(
                bez,
                cc.CallFunc:create(
                    function()
                        callback()
                    end
                ),
                cc.CallFunc:create(
                    function()
                        -- particle:removeFromParent()
                        coins:removeFromParent()
                        local symbolType = coins.p_symbolType
                        self:pushSlotNodeToPoolBySymobolType(symbolType, coins)
                    end
                )
            )
        )
        -- end, 0.2)
        table.remove(self.m_collectList, i)
    end
end

function CodeGameScreenLinkFishMachine:BaseMania_updateCollect(addCount, index, totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

function CodeGameScreenLinkFishMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        self:BaseMania_updateCollect(addCount, 1, totalCount)
    end
end

function CodeGameScreenLinkFishMachine:BaseMania_initCollectDataList()
    --收集数组
    self.m_collectDataList = {}
    --默认总数

    self.m_collectDataList[1] = CollectData.new()
    self.m_collectDataList[1].p_collectTotalCount = 150
    self.m_collectDataList[1].p_collectLeftCount = 150
    self.m_collectDataList[1].p_collectCoinsPool = 0
    self.m_collectDataList[1].p_collectChangeCount = 0
end

function CodeGameScreenLinkFishMachine:requestSpinResult()
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
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenLinkFishMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin == nil or betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end
end

function CodeGameScreenLinkFishMachine:unlockHigherBet()
    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE
     then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenLinkFishMachine:showBonusMap(callback, nodePos)
    if (self.m_bCanClickMap == false or self.m_bSlotRunning == true) and callback == nil then
        return
    end
    self.m_bCanClickMap = false
    if self.m_map:getMapIsShow() == true then
        self.m_map:mapDisappear(
            function()
                self.m_bCanClickMap = true
            end
        )
    else
        self.m_map:mapAppear(
            function()
                self.m_bCanClickMap = true
                if callback ~= nil then
                    self.m_map:pandaMove(callback, self.m_bonusData, nodePos)
                end
            end
        )
        if callback ~= nil then
            self.m_map:setMapCanTouch(true)
        end
    end
end

function CodeGameScreenLinkFishMachine:initGameStatusData(gameData)
    if gameData.collect ~= nil then
        self.m_collectProgress = self:getProgress(gameData.collect[1])
    else
        self.m_collectProgress = 0
    end

    self.m_nodePos = gameData.gameConfig.extra.currPosition
    if self.m_nodePos == nil then
        self.m_nodePos = 0
    end
    self.m_mapNodePos = self.m_nodePos
    self:updateMapData(gameData.gameConfig.extra.map)

    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenLinkFishMachine:updateMapData(map)
    local vecSelectedID = {}
    local vecAllID = {}
    local bigLevelID = 1
    for i = 1, #map, 1 do
        local info = map[i]
        if info.type == "SMALL" then
            if info.selected == true then
                vecSelectedID[#vecSelectedID + 1] = info.position
            end
            vecAllID[#vecAllID + 1] = info.position
        elseif info.type == "BIG" then
            info.extraGames = {}
            info.allGames = {}
            info.levelID = bigLevelID
            bigLevelID = bigLevelID + 1
            for j = #vecSelectedID, 1, -1 do
                table.insert(info.extraGames, 1, vecSelectedID[j])
                table.remove(vecSelectedID, j)
            end
            for j = #vecAllID, 1, -1 do
                table.insert(info.allGames, 1, vecAllID[j])
                table.remove(vecAllID, j)
            end
        end
    end
    self.m_bonusData = map
end

function CodeGameScreenLinkFishMachine:getProgress(collect)
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

function CodeGameScreenLinkFishMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_enter.mp3")
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

function CodeGameScreenLinkFishMachine:onEnter()
    self:checkUpateDefaultBet()
    self:initTopCommonJackpotBar()
    self:updataJackpotStatus()
    

    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    
    self:updateBetLevel()
    
    self.m_progress:setPercent(self.m_collectProgress, self.m_bonusData[self.m_mapNodePos + 1].levelID)
    if self.m_iBetLevel == 1 then
        self.m_progress:idle()
    else
        self.m_progress:lock(self.m_iBetLevel)
    end
    self.m_jackPotBar:updateJackpotInfo()
    if self.m_map == nil then
        self.m_map = util_createView("CodeLinkFishSrc.LinkFishBnousMapScrollView", self.m_bonusData, self.m_mapNodePos)
        self:findChild("map"):addChild(self.m_map)

        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_map.getRotateBackScaleFlag = function()
                return false
            end
        end

        self.m_map:setVisible(false)
    end

    local hasFeature = self:checkHasFeature()
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not hasFeature then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_ONENTER)
    end
end

function CodeGameScreenLinkFishMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            --公共jackpot
            self:updataJackpotStatus(params)

            local perBetLevel = self.m_iBetLevel
            self:updateBetLevel()
            if perBetLevel > self.m_iBetLevel then
                -- self:showLowerBetIcon()
                self.m_progress:lock(self.m_iBetLevel)
            elseif perBetLevel < self.m_iBetLevel then
                self.m_progress:unlock(self.m_iBetLevel)
            -- gLobalSoundManager:playSound("FiveDragonSounds/sound_FiveDragon_unlock_highbet.mp3")
            -- self:hideLowerBetIcon()
            end
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

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showBonusMap()
        end,
        "SHOW_BONUS_MAP"
    )

    --公共jackpot活动结束
    gLobalNoticManager:addObserver(self,function(target, params)

        if params.name == ACTIVITY_REF.CommonJackpot then
            self.m_isJackpotEnd = true
            self:updataJackpotStatus()
        end

    end,ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function CodeGameScreenLinkFishMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearTitleNode()
    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearEntryNode()
end
-- 背景音乐点击spin后播放
function CodeGameScreenLinkFishMachine:normalSpinBtnCall()
    self.m_initFeatureData = nil
    BaseSlotoManiaMachine.normalSpinBtnCall(self)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
end

--bugly-21.12.01-列表内取出了 nil 的连线小块，# 的使用问题。
function CodeGameScreenLinkFishMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true

    -- 停掉背景音乐
    self:clearCurMusicBg()
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        for k,lineNode in pairs(self.m_lineSlotNodes) do
            --!!! 模仿上两个接口 判断一下这个信号是否由关卡本身操作过层级了，直接跳过
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
                local cloumnIndex = lineNode.p_cloumnIndex
                if cloumnIndex then
                    local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(lineNode:getPosition()))
                    local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
                    self:changeBaseParent(lineNode)
                    lineNode:setPosition(pos)
                    self.m_slotParents[cloumnIndex].slotParent:addChild(lineNode)
                end
            end
            
        end

        --!!!21.12.01 循环使用 # 取出的数组长度时会有异常,换为 pairs
        --[[
            报错的流程
            tab = { [1]=1,[2]=1,[3]=1 }
            tab[1] = nil
            length = #tab
            -- length = 3
            -- url: https://www.jianshu.com/p/1e8ab8fe55e4
        ]]
        -- 处理特殊信号
        -- local length = #childs
        -- for i = 1, length do
        --     local lineNode = childs[i]
        --     if nil ~= lineNode then
        --         --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
        --         local cloumnIndex = lineNode.p_cloumnIndex
        --         if cloumnIndex then
        --             local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(lineNode:getPosition()))
        --             local pos = self.m_slotParents[cloumnIndex].slotParent:convertToNodeSpace(posWorld)
        --             self:changeBaseParent(lineNode)
        --             lineNode:setPosition(pos)
        --             self.m_slotParents[cloumnIndex].slotParent:addChild(lineNode)
        --         end
        --     end
        -- end
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

function CodeGameScreenLinkFishMachine:getAvgbet()

    if self.m_initFeatureData and self.m_initFeatureData.p_data and self.m_initFeatureData.p_data.respin and self.m_initFeatureData.p_data.respin.extra then
        return self.m_initFeatureData.p_data.respin.extra.avgBet
    end

    local resExtraData = self.m_runSpinResultData.p_rsExtraData
    
    if resExtraData and resExtraData.avgBet then
        return resExtraData.avgBet
    end

    return nil
end

---
-- 处理spin 返回结果
function CodeGameScreenLinkFishMachine:spinResultCallFun(param)
    CodeGameScreenLinkFishMachine.super.spinResultCallFun(self,param)
    self.m_jackPotBar:resetCurRefreshTime()
end

function CodeGameScreenLinkFishMachine:updateReelGridNode(symbolNode)

end

-------------------------------------------------公共jackpot-----------------------------------------------------------------------

--[[
    更新公共jackpot状态
]]
function CodeGameScreenLinkFishMachine:updataJackpotStatus(params)
    local totalBetID = globalData.slotRunData:getCurTotalBet()

    self.m_jackpot_status = "Normal" -- "Mega" "Super"

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        self:updateJackpotBarMegaShow()
        return
    end

    if self.m_isJackpotEnd then
        self:updateJackpotBarMegaShow()
        return
    end


    if not mgr:isDownloadRes() then
        self:updateJackpotBarMegaShow()
        return
    end
    
    local data = mgr:getRunningData()
    if not data or not next(data) then
        self:updateJackpotBarMegaShow()
        return
    end

    local levelData = data:getLevelDataByBet(totalBetID)
    local levelName = levelData.p_name
    self.m_jackpot_status = levelName
    self:updateJackpotBarMegaShow()
end

function CodeGameScreenLinkFishMachine:updateJackpotBarMegaShow()
    self.m_jackPotBar:updateMegaShow()
end

function CodeGameScreenLinkFishMachine:getCommonJackpotValue(_status, _addTimes)
    _addTimes = math.floor(_addTimes)
    local value     = 0
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if _status == "Mega" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Mega)
        end
    elseif _status == "Super" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Super)
        end
    end

    return value
end

--[[
    新增顶栏和按钮
]]
function CodeGameScreenLinkFishMachine:initTopCommonJackpotBar()
    if not ACTIVITY_REF.CommonJackpot then
        return 
    end

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        return
    end

    local commonJackpotTitle = mgr:createTitleNode()

    if not commonJackpotTitle then
        return
    end
    self.m_commonJackpotTitle = commonJackpotTitle
    self:addChild(self.m_commonJackpotTitle, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    local titlePos = util_getConvertNodePos(self.m_topUI:findChild("TopUI_down"), self)
    local topSpSize = self.m_commonJackpotTitle:findChild("sp_Jackpot1"):getContentSize()
    titlePos.y = titlePos.y - topSpSize.height*0.3
    self.m_commonJackpotTitle:setPosition(titlePos)
    self.m_commonJackpotTitle:setScale(globalData.topUIScale)
end

return CodeGameScreenLinkFishMachine
