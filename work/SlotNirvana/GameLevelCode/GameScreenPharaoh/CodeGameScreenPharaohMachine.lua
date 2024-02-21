---
-- xcyy
-- 2018年5月11日
-- CodeGameScreenPharaohMachine.lua
--
-- 玩法： 法老金币
--
local BaseMachine = require "Levels.BaseMachine"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = require "Levels.BaseDialog"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local CodeGameScreenPharaohMachine = class("CodeGameScreenPharaohMachine", BaseSlotoManiaMachine)
--定义成员变量

--定义关卡特有的信号类型 以下为参考， 从TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1开始
--GameScreenQgodMachine.SYMBOL_TYPE_FLY_GOLD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

CodeGameScreenPharaohMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenPharaohMachine.SYMBOL_3X3_BIG_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenPharaohMachine.SYMBOL_SECOND_BIG_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenPharaohMachine.SYMBOL_THREE_BIG_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4

CodeGameScreenPharaohMachine.SYMBOL_JACKPOT1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5
CodeGameScreenPharaohMachine.SYMBOL_JACKPOT2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 6
CodeGameScreenPharaohMachine.SYMBOL_JACKPOT3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7
CodeGameScreenPharaohMachine.SYMBOL_JACKPOT4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenPharaohMachine.SYMBOL_RASE = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9

CodeGameScreenPharaohMachine.SYMBOL_FIX_SYMBOL = 101
CodeGameScreenPharaohMachine.SYMBOL_3X3_BIG_SYMBOL = 102
CodeGameScreenPharaohMachine.SYMBOL_3X3_BIG_CHIP = 103
CodeGameScreenPharaohMachine.SYMBOL_FIX_CHIP = 104
CodeGameScreenPharaohMachine.SYMBOL_FIX_GRAND = 105
CodeGameScreenPharaohMachine.SYMBOL_FIX_MAJOR = 106
CodeGameScreenPharaohMachine.SYMBOL_FIX_MINOR = 107
CodeGameScreenPharaohMachine.SYMBOL_FIX_MINI = 108

CodeGameScreenPharaohMachine.SYMBOL_SECOND_BIG_SYMBOL = 109
CodeGameScreenPharaohMachine.SYMBOL_THREE_BIG_SYMBOL = 110

local SPECIAL_SYMBOL_TYPE_1 = 93
local SPECIAL_SYMBOL_TYPE_2 = 94

local RESPIN_BIG_REWARD_MULTIP = 200000
local RESPIN_BIG_REWARD_SYMBOL_NUM = 15

CodeGameScreenPharaohMachine.m_animNameIds = nil
CodeGameScreenPharaohMachine.m_endType = nil
CodeGameScreenPharaohMachine.m_wildContinusPos = nil
CodeGameScreenPharaohMachine.m_changeBigSymbolEffect = nil
CodeGameScreenPharaohMachine.ID_COMPARE_INFO = nil
CodeGameScreenPharaohMachine.m_dalyHideMask = nil
CodeGameScreenPharaohMachine.m_respinEndNodes = nil
CodeGameScreenPharaohMachine.m_nowPlayNode = nil
CodeGameScreenPharaohMachine.m_playSpeicalSymbolSoundCol = nil

CodeGameScreenPharaohMachine.m_bTriggerRespin = nil
CodeGameScreenPharaohMachine.m_allLockNodeReelPos = nil
CodeGameScreenPharaohMachine.m_addLockNodeReelPos = nil

CodeGameScreenPharaohMachine.m_totleMoonNumCount = nil

--freespin 中大图占位使用
local BIGSYMBOL_REMOVE_LIST = {1, 2, 3, 6, 7, 8, 11, 13}
-- 构造函数
function CodeGameScreenPharaohMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_endType = self.SYMBOL_FIX_CHIP
    self.m_changeBigSymbolEffect = GameEffect.EFFECT_SELF_EFFECT - 1

    self.m_isFeatureOverBigWinInFree = true
    
    --init
    self:initGame()
    self:resetSpecialSoundPlayCol()
end

function CodeGameScreenPharaohMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("PharaohConfig.csv", "LevelPharaohConfig.lua")

    self.m_animNameIds = {9, 11, 0, 1, 2, 3, 4, 5, 6, 7, 8}

    self.m_lightScore = 0
    --启用jackpot
    self:BaseMania_jackpotEnable()

    self.MACHINE_NODE_SACLE = 1

    self.m_RESPIN_WAIT_TIME = 3

    self.m_respinEndSound = {}
  

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    self.m_hasBigSymbol = false
    for i=1,self.m_iReelColumnNum  do
        self.m_respinEndSound[#self.m_respinEndSound  + 1] = "PharaohSounds/music_Pharaoh_fall_"..i..".mp3"
    end
end

function CodeGameScreenPharaohMachine:getNetWorkModuleName()
    return "WolfGold"
end

function CodeGameScreenPharaohMachine:getRespinView()
    return "CodePharaohSrc.PharaohRespinView"
end

function CodeGameScreenPharaohMachine:getRespinNode()
    return "Levels.RespinNode"
end

function CodeGameScreenPharaohMachine:checkGameRunPause()
    if self:checkFsFrist() then
        return false
    end
    if globalData.slotRunData.gameRunPause == true then
        return true
    else
        return false
    end
end

function CodeGameScreenPharaohMachine:checkFsFrist()
    local totalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    local curCount = self.m_runSpinResultData.p_freeSpinsLeftCount or -1
    if totalCount == 0 then
        return false
    elseif totalCount == curCount then
        return true
    end
end

function CodeGameScreenPharaohMachine:initUI(data)
    self.m_jackPotBar = util_createView("CodePharaohSrc.PharaohJackpotBar", self)
    self.m_csbOwner["jackpotLayer"]:addChild(self.m_jackPotBar)
    -- self.m_jackPotBar:setVisible(false)
    self.m_jackPotBar:setPosition(0, 0 - 27)

    self.m_reSpinBar = util_createView("CodePharaohSrc.PharaohReSpinBar")
    local pX, pY = self.m_jackPotBar:getPosition()
    self.m_reSpinBar:setPosition(0, 0 - 45)

    self.m_csbOwner["jackpotLayer"]:addChild(self.m_reSpinBar)
    self.m_reSpinBar:setVisible(false)

    self.m_fsMask = self.m_csbOwner["m_freespin_mask"]
    self.m_fsMask:setVisible(false)

    self:initFreeSpinBar()

    util_setPositionPercent(self.m_csbNode, 0.495)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "idle")

   
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end
        local index = util_random(1,3)
        gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_last_win".. index .. ".mp3")
        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        -- 播放音效freespin
        gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_lightning_count_3.mp3")
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function CodeGameScreenPharaohMachine:initJackpotInfo(jackpotPool, lastBetId)
    self.m_jackPotBar:updateJackpotInfo()
end
--是否是freespin中触发的respin
function CodeGameScreenPharaohMachine:isFsRespin()
    if self.m_bProduceSlots_InFreeSpin and globalData.slotRunData.currSpinMode == RESPIN_MODE then
        return true
    end
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPharaohMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Pharaoh"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPharaohMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil
    -- if symbolType == self.SYMBOL_FIX_SYMBOL then
    --     ccbName = "Socre_Pharaoh_Special_1"
    -- elseif symbolType == self.SYMBOL_3X3_BIG_SYMBOL then
    --     ccbName = "Socre_Pharaoh_BigSymbol"
    -- -- ccbName = "Socre_Pharaoh_Special_Rase"
    -- end

    -- if symbolType == self.SYMBOL_SECOND_BIG_SYMBOL then
    --     ccbName = "Socre_Pharaoh_Special_Wild2"
    -- elseif symbolType == self.SYMBOL_THREE_BIG_SYMBOL then
    --     ccbName = "Socre_Pharaoh_Special_Wild3"
    -- elseif symbolType == self.SYMBOL_JACKPOT1 then
    --     ccbName = "Socre_Pharaoh_Special_Jackpot1"
    -- elseif symbolType == self.SYMBOL_JACKPOT2 then
    --     ccbName = "Socre_Pharaoh_Special_Jackpot2"
    -- elseif symbolType == self.SYMBOL_JACKPOT3 then
    --     ccbName = "Socre_Pharaoh_Special_Jackpot3"
    -- elseif symbolType == self.SYMBOL_JACKPOT4 then
    --     ccbName = "Socre_Pharaoh_Special_Jackpot4"
    -- elseif symbolType == self.SYMBOL_RASE then
    --     ccbName = "Socre_Pharaoh_Special_Rase"
    -- end


    if symbolType == self.SYMBOL_FIX_CHIP then
        ccbName = "Socre_Pharaoh_Special_1"
    elseif symbolType == self.SYMBOL_3X3_BIG_SYMBOL then
        ccbName = "Socre_Pharaoh_BigSymbol"
    elseif symbolType >= 1000 then
        ccbName = "Socre_Pharaoh_BigSymbol"
    elseif symbolType == self.SYMBOL_FIX_SYMBOL then
        ccbName = "Socre_Pharaoh_Special_Rase"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        ccbName = "Socre_Pharaoh_Special_Jackpot3"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        ccbName = "Socre_Pharaoh_Special_Jackpot2"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        ccbName = "Socre_Pharaoh_Special_Jackpot1"
    elseif symbolType == self.SYMBOL_SECOND_BIG_SYMBOL then
        ccbName = "Socre_Pharaoh_Special_Wild2"
    elseif symbolType == self.SYMBOL_THREE_BIG_SYMBOL then
        ccbName = "Socre_Pharaoh_Special_Wild3"
    end


    return ccbName
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPharaohMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine:getPreLoadSlotNodes()
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_CHIP, count = 3}
    loadNode[#loadNode + 2] = {symbolType = self.SYMBOL_3X3_BIG_SYMBOL, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SECOND_BIG_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_THREE_BIG_SYMBOL, count = 2}

    return loadNode
end


-- 重写 getSlotNodeBySymbolType 方法
function CodeGameScreenPharaohMachine:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
    local symbolTypeTmp = symbolType
    
    if symbolType == SPECIAL_SYMBOL_TYPE_2 or
    symbolType == SPECIAL_SYMBOL_TYPE_1
    then
        symbolTypeTmp = self.SYMBOL_FIX_CHIP
    end

    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolTypeTmp,iRow,iCol,isLastSymbol)

    -- symbolType == self.SYMBOL_FIX_CHIP or 
    if 
    symbolType == self.SYMBOL_FIX_CHIP or 
    symbolType == SPECIAL_SYMBOL_TYPE_2 or
    symbolType == SPECIAL_SYMBOL_TYPE_1
    then
        --下帧调用 才可能取到 x y值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        reelNode:runAction(callFun)
    end
    -- or symbolType == self.SYMBOL_3X3_BIG_SYMBOL
    if symbolType >= 1000  then
        --特殊处理
        reelNode.m_reelTop = (1.5) * self.m_SlotNodeH
        reelNode.m_reelBottom = (1.5) * self.m_SlotNodeH
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialBigNode), {reelNode})
        reelNode:runAction(callFun)
    end

    if symbolType == self.SYMBOL_3X3_BIG_SYMBOL then

        local callFun = cc.CallFunc:create(handler(self, self.setSpecialBigNodeJp), {reelNode})
        reelNode:runAction(callFun)
    end

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if
            symbolType ~= self.SYMBOL_FIX_SYMBOL and symbolType ~= self.SYMBOL_3X3_BIG_SYMBOL and
                symbolType ~= self.SYMBOL_FIX_CHIP and
                symbolType ~= self.SYMBOL_3X3_BIG_CHIP
         then
            reelNode:setColor(cc.c3b(255, 0, 0))
        end
    end
    return reelNode
end

function CodeGameScreenPharaohMachine:setSpecialBigNodeJp(sender, parma)
    local symbolNode = parma[1]

    if symbolNode.m_isLastSymbol == true then
        local iCol = symbolNode.p_cloumnIndex
        local iRow = symbolNode.p_rowIndex

        -- --获取分数
        local symbolId = self:getSpinResultReelsType(iCol, iRow)
        if symbolId == nil then
            return 
        end
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))

        local animName, idleName = self:getBsAnimNameByTypeJp(score)
        symbolNode:runAnim(idleName)
        symbolNode:setLineAnimName(animName)
        symbolNode:setIdleAnimName(idleName)

        local index = 1
        if score == "MINI" then
            symbolNode:runAnim("idleframe_mini")
            index = 1
        elseif score == "MINOR" then
            symbolNode:runAnim("idleframe_minor")
            index = 2
        elseif score == "MAJOR" then
            symbolNode:runAnim("idleframe_major")
            index = 3
        else
            symbolNode:runAnim("idleframe_grand")
            index = 4
        end
        self:setPlayAnimationName(symbolNode, index, true)
    else    

        if  xcyy.SlotsUtil:getArc4Random() % 2 == 0 then
            symbolNode:runAnim("idleframe_mini")
        else
            symbolNode:runAnim("idleframe_minor")
        end
    end
end

function CodeGameScreenPharaohMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
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

    -- if type < 1000 then
        if score == 10 then
            score = "MINI"
        elseif score == 20 then
            score = "MINOR"
        elseif score == 100 then
            score = "MAJOR"
        elseif score == 1000 then
            score = "GRAND"
        end
    -- end
    return score
end

function CodeGameScreenPharaohMachine:setSpecialNodeScore(sender, parma)
    local symbolNode = parma[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iCol ~= nil and iRow <= rowCount  and symbolNode.m_isLastSymbol == true then 
        --获取分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))

        local index = 0
        if type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                if symbolNode:getCcbProperty("score_lab") then
                    symbolNode:getCcbProperty("score_lab"):setString(score)
                end
                
                symbolNode:runAnim("idleframe")
            end
            
            index = 5
        else
            if score == "MINI" then
                symbolNode:runAnim("jackpot_1")
                index = 1
            elseif score == "MINOR" then
                symbolNode:runAnim("jackpot_2")
                index = 2
            elseif score == "MAJOR" then
                symbolNode:runAnim("jackpot_3")
                index = 3
            else
                symbolNode:runAnim("jackpot_4")
                index = 4
            end
        end
        self:setPlayAnimationName(symbolNode, index)

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        if score == 10 then
            score = "MINI"
        elseif score == 20 then
            score = "MINOR"
        elseif score == 100 then
            score = "MAJOR"
        elseif score == 1000 then
            score = "GRAND"
        end
        if type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                if symbolNode:getCcbProperty("score_lab") then
                    symbolNode:getCcbProperty("score_lab"):setString(score)
                end
                
                symbolNode:runAnim("idleframe")
            end
            index = 5
        else
            if score == "MINI" then
                symbolNode:runAnim("jackpot_1")
                index = 1
            elseif score == "MINOR" then
                symbolNode:runAnim("jackpot_2")
                index = 2
            elseif score == "MAJOR" then
                symbolNode:runAnim("jackpot_3")
                index = 3
            else
                symbolNode:runAnim("jackpot_4")
                index = 4
            end
        end
        self:setPlayAnimationName(symbolNode, index)
    end
end


function CodeGameScreenPharaohMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes
    local idleName = nil
    local bigSymbolNode = nil
    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- 如果是大信号记录下当前的时间线
        if lineNode.p_symbolType == self.SYMBOL_3X3_BIG_SYMBOL then
            local symbolId = self:getSpinResultReelsType(lineNode.p_cloumnIndex, lineNode.p_rowIndex)
            local _, curIdleName = self:getBsAnimNameByType(symbolId)
            idleName = curIdleName

            bigSymbolNode = lineNode
            break
        end
    end
    BaseMachine.resetMaskLayerNodes(self)

    if bigSymbolNode ~= nil then
        bigSymbolNode:runAnim(idleName)
    end
end

function CodeGameScreenPharaohMachine:setSpecialBigNode(sender, parma)
    local symbolNode = parma[1]

    if symbolNode.m_isLastSymbol == true then
        local iCol = symbolNode.p_cloumnIndex
        local iRow = symbolNode.p_rowIndex

        -- --获取分数
        local symbolId = self:getSpinResultReelsType(iCol, iRow)
        if symbolId == 1000 then
           local a = 100
        end
        if symbolId == nil then
            return 
        end
        local storedIcons = self.m_runSpinResultData.p_storedIcons
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))

        local animName, idleName = self:getBsAnimNameByType(symbolId)
        symbolNode:runAnim(idleName)
        symbolNode:setLineAnimName(animName)
        symbolNode:setIdleAnimName(idleName)
        
        -- local index = 0
        --获取分数
        if score ~= nil then
            local index = 5
            local animID = 10
            if score == "MINI" then
                animID = 12
                index = 1
            elseif score == "MINOR" then
                animID = 13
                index = 2
            elseif score == "MAJOR" then
                animID = 14
                index = 3
            elseif score == "GRAND" then
                animID = 15
                index = 4
            end
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if type(score) ~= "string" then
                score = score * lineBet
                score = util_formatCoins(score, 3)
                if symbolNode:getCcbProperty("score_lab") then
                    symbolNode:getCcbProperty("score_lab"):setString(score)
                end
            end

            local idleName = "action" .. animID
            local animName = animID .. "_actionframe"
            symbolNode:runAnim(idleName)
            symbolNode:setLineAnimName(animName)
            symbolNode:setIdleAnimName(idleName)

            self:setPlayAnimationName(symbolNode, index, true)
        else
            symbolNode.m_bInLine = true
            local linePos = {}

            for colIndex = 2, 4 do
                for rowIndex = 1, self.m_iReelRowNum do
                    linePos[#linePos + 1] = {iX = rowIndex, iY = colIndex}
                end
            end
            symbolNode:setLinePos(linePos)
        end
    else
        local type = symbolNode.p_symbolType - 1000
        if type == 10 then
                        --滚动中的特殊块 随便给数据吧？
            local score = self.m_configData:getBnFreePro()
            
            if score == 10 then
                type = 12
            elseif score == 20 then
                type = 13
            elseif score == 100 then
                type = 14
            end

            local idleName = "action" .. type
            local animName = type .. "_actionframe"
            symbolNode:runAnim(idleName)
            symbolNode:setLineAnimName(animName)
            symbolNode:setIdleAnimName(idleName)

            local lineBet = globalData.slotRunData:getCurTotalBet()
            local score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode:getCcbProperty("score_lab") then
                symbolNode:getCcbProperty("score_lab"):setString(score)
            end
        else
            local animName, idleName = self:getBsAnimNameByType(symbolNode.p_symbolType)
            symbolNode:runAnim(idleName)
            symbolNode:setLineAnimName(animName)
            symbolNode:setIdleAnimName(idleName)

        end

    end
end

-- slotNode.p_reelDownRunAnimaSound
function CodeGameScreenPharaohMachine:setPlayAnimationName(symbolNode, index, isBigSymbol)
    local indexName = {
        "jackpot_1_actionframe",
        "jackpot_2_actionframe",
        "jackpot_3_actionframe",
        "jackpot_4_actionframe",
        "idleframe_actionframe"
    }
    if isBigSymbol then
        indexName = {
            "action12_actionframe1",
            "action13_actionframe1",
            "action14_actionframe1",
            "action15_actionframe1",
            "action10_actionframe1"
        }
    end
    if index == 0 then
        return
    end
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        local iCol = symbolNode.p_cloumnIndex
        local iRow = symbolNode.p_rowIndex
        if iRow ~= nil and iCol ~= nil then
            local nIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + (iCol - 1)
            local storedIcons = self.m_runSpinResultData.p_storedIcons
            for k = 1, #storedIcons do
                if storedIcons[k] == nIdx then
                    symbolNode.p_reelDownRunAnima = indexName[index]
                    return
                end
            end
        end
        symbolNode.p_reelDownRunAnima = nil
    else
        if self:isSetSpecialSoundPlay(symbolNode.p_cloumnIndex) == true then
            symbolNode.p_reelDownRunAnimaSound =
                "PharaohSounds/music_Pharaoh_fall_" .. symbolNode.p_cloumnIndex .. ".mp3"
        end
        -- symbolNode.p_reelDownRunAnima = indexName[index]

        -- if index == 5 and isBigSymbol then
        --     symbolNode.p_reelDownRunAnimaTimes = 0.7
        -- end
    end
end
function CodeGameScreenPharaohMachine:resetSpecialSoundPlayCol()
    self.m_playSpeicalSymbolSoundCol = {}
    for i = 1, self.m_iReelColumnNum do
        self.m_playSpeicalSymbolSoundCol[#self.m_playSpeicalSymbolSoundCol + 1] = false
    end
end

function CodeGameScreenPharaohMachine:isSetSpecialSoundPlay(colNum)
    if self.m_playSpeicalSymbolSoundCol[colNum] == false then
        self.m_playSpeicalSymbolSoundCol[colNum] = true
        return true
    else
        return false
    end
end

----------------------------- LocalGame数据生成处理 ----------------------

function CodeGameScreenPharaohMachine:getClientWinCoins()
    local winGetLines = self.m_vecGetLineInfo
    local lineLen = #winGetLines

    local clientWinCoins = 0 -- 客户端计算出来的钱， 暂时保留用来与服务器端进行对比
    for i = 1, lineLen, 1 do
        local enumLineInfo = winGetLines[i]

        if enumLineInfo.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then --and enumLineInfo.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN
            local llTheSymbolWin =
                self:getSymbolWinRate(enumLineInfo, enumLineInfo.enumSymbolType, enumLineInfo.iLineSymbolNum)

            llTheSymbolWin = llTheSymbolWin * enumLineInfo.iLineMulti  * enumLineInfo.iLineSelfMulti--*= 当前得分线的倍数！

            clientWinCoins = clientWinCoins + llTheSymbolWin * globalData.slotRunData:getCurTotalBet()
        --            end
        end -- end if
    end -- end for
    return clientWinCoins
end
local function getStructSymbolMulti(MainClass, iRow, iCol) --- 得到小块的分数 add by az on 11.20
    if MainClass.m_vecStructMultiple ==nil then
        return 1 -- 如果没有定义这个字段就 返回1倍
    end
    for i=1,#MainClass.m_vecStructMultiple do
        local multyInfo = MainClass.m_vecStructMultiple[i]
        if multyInfo[1] == iRow and multyInfo[2] == iCol then
            return multyInfo[3]
        end
    end
    return 1 --- 如果没有这个值也返回1倍
end


--筛选出freepsinNode
CodeGameScreenPharaohMachine.p_levelTriggerReSpinCount = 0
function CodeGameScreenPharaohMachine:getIsTriggerRepsin()
    
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_stcValidSymbolMatrix[1][3] == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            -- print("freespin respin!!!")
            return true
        end
    else

        local num = 0
        local bn2Num = 0
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
               if self.m_stcValidSymbolMatrix[iRow][iCol] > 100 then
                  num = num + 1
               end
          
            end 
        end
        if num >= 6 then
            self.p_levelTriggerReSpinCount = self.p_levelTriggerReSpinCount + 1
            if BASE_TRIGGER_FEATURE_SYMBOL[num] == nil then
                BASE_TRIGGER_FEATURE_SYMBOL[num] = 1
            else
                BASE_TRIGGER_FEATURE_SYMBOL[num] = BASE_TRIGGER_FEATURE_SYMBOL[num] + 1
            end

            return true
        end
    end
    return false
end

function CodeGameScreenPharaohMachine:getRepsinTotleCount()
    local fixNum = 0
    for i=1,#self.m_runSpinResultData.p_storedIcons do
        fixNum = fixNum + 1
    end
    return fixNum
end

function CodeGameScreenPharaohMachine:getIsHaveMajor()
    for i=1,#self.m_allLockNodeReelPos do
        local iconInfo = self.m_allLockNodeReelPos[i]
        if iconInfo[2] == 1000 then
            return true
        end
    end
    return false
end

function CodeGameScreenPharaohMachine:setLockDataInfo()      
    self.m_allLockNodeReelPos = {}
    for i=1,#self.m_runSpinResultData.p_storedIcons do
        local iconInfo = self.m_runSpinResultData.p_storedIcons[i]
        self.m_allLockNodeReelPos[#self.m_allLockNodeReelPos + 1] = {iconInfo[1], iconInfo[2]}
    end
end

function CodeGameScreenPharaohMachine:getRandom()      
end



function CodeGameScreenPharaohMachine:getRespinRandomScore()

    if self.m_bProduceSlots_InFreeSpin then
        local randomIndx = self.m_configData:getBnFreeFeatureNormalPro( )
        if self.FREE_BN_FEATURE_BALL[randomIndx] == nil then
            self.FREE_BN_FEATURE_BALL[randomIndx] = 0
        end
        self.FREE_BN_FEATURE_BALL[randomIndx] =  self.FREE_BN_FEATURE_BALL[randomIndx] + 1

        local Score = nil
        if randomIndx == 1 then
            Score = self.m_configData:getBnFreeFeaturePro()

            if FREE_BN_FEATURE[Score] == nil then
                FREE_BN_FEATURE[Score] = 0
            end
            FREE_BN_FEATURE[Score] = FREE_BN_FEATURE[Score] + 1
        end
        return Score
    else
        local hasMajor = self:getIsHaveMajor()
        local randomIndx = self.m_configData:getBnBaseFeatureNormalPro( )
        if self.BASE_BN_FEATURE[randomIndx] == nil then
            self.BASE_BN_FEATURE[randomIndx] = 0
        end
        self.BASE_BN_FEATURE[randomIndx] =  self.BASE_BN_FEATURE[randomIndx] + 1
        local Score = nil
        if hasMajor then

            if randomIndx == 1 then
                Score = self.m_configData:getBnBaseFeaturePro()
            end

        else

            if randomIndx == 1 then
                Score = self.m_configData:getBnBaseFeaturePro()
            elseif randomIndx == 2 then
                Score = 1000
            end

        end
        return Score
    end

end 

function CodeGameScreenPharaohMachine:addRepsinCountNum( num)
    self.m_reSpinsTotalCount = num + self.m_reSpinsTotalCount
    self.m_reSpinCurCount = num
end

function CodeGameScreenPharaohMachine:randomRespinAddRespinSymbol()

            --不能填满
    if #self.m_allLockNodeReelPos == 14 then
        return        
    end

    local unLockPos = self:getUnRespinNodePos()
    randomShuffle(unLockPos)
    local bAddNewRespinSymbol = false
    for i=1,#unLockPos do
       local score = self:getRespinRandomScore()
       if score ~= nil then

            local randomIdx = xcyy.SlotsUtil:getArc4Random() % #unLockPos + 1
            local pos = unLockPos[randomIdx]
            local idx = self:getPosReelIdx(pos.iX, pos.iY)
            self.m_allLockNodeReelPos[# self.m_allLockNodeReelPos + 1] = {idx, score}
            self.m_addLockNodeReelPos[# self.m_addLockNodeReelPos + 1] = {idx, score}
            self.m_stcValidSymbolMatrix[pos.iX][pos.iY] = self.SYMBOL_FIX_CHIP
            if not bAddNewRespinSymbol then
                bAddNewRespinSymbol = true
            end 
            table.remove( unLockPos, randomIdx)
            --不能填满
            if #self.m_allLockNodeReelPos == 14 then
                break
            end

       end
    end

    if bAddNewRespinSymbol then
        self:addRepsinCountNum(3)
    end
end

function CodeGameScreenPharaohMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType == SPECIAL_SYMBOL_TYPE_1 then

        score = self.m_configData:getBnBasePro1()

    elseif symbolType == SPECIAL_SYMBOL_TYPE_2 then

        score = self.m_configData:getBnBasePro2()
    end
    return score
end

--转换jp信号
function CodeGameScreenPharaohMachine:transformSpicalSymbol()
    local bonusScore = nil
    for iCol = 1,self.m_iReelColumnNum do

        for iRow = 1,self.m_iReelRowNum do
            
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]

            if symbolType == SPECIAL_SYMBOL_TYPE_1 then
                --随机信号
                local score = self:randomDownRespinSymbolScore(symbolType)
                self.m_stcValidSymbolMatrix[iRow][iCol] = 104
                local idx = self:getPosReelIdx(iRow, iCol)
                
                self.m_allLockNodeReelPos[#self.m_allLockNodeReelPos + 1] = {idx, score}

                if self.m_bTriggerRespin then
                    self.m_addLockNodeReelPos[#self.m_addLockNodeReelPos + 1] = {idx, score}
                end

            elseif symbolType == SPECIAL_SYMBOL_TYPE_2 then
                self.m_bn2Num = self.m_bn2Num + 1
                local score = self:randomDownRespinSymbolScore(symbolType)
                self.m_stcValidSymbolMatrix[iRow][iCol] = 104
                local idx = self:getPosReelIdx(iRow, iCol)

                self.m_allLockNodeReelPos[#self.m_allLockNodeReelPos + 1] = {idx, score}

                if self.m_bTriggerRespin then
                    self.m_addLockNodeReelPos[#self.m_addLockNodeReelPos + 1] = {idx, score}
                end
            elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then

                if bonusScore == nil then
                    bonusScore = self.m_configData:getBnFreePro()
                end
            
                local idx = self:getPosReelIdx(iRow, iCol)
                self.m_allLockNodeReelPos[#self.m_allLockNodeReelPos + 1] = {idx, bonusScore}

                if self.m_bTriggerRespin then
                    self.m_addLockNodeReelPos[#self.m_addLockNodeReelPos + 1] = {idx, bonusScore}
                end
            end
        end 

    end
end

CodeGameScreenPharaohMachine.fsRespin = {}

function CodeGameScreenPharaohMachine:getUnRespinNodePos()

    local lockPos = {}
    for i=1,#self.m_allLockNodeReelPos do
        local idx = self.m_allLockNodeReelPos[i][1]
        lockPos[idx] = i
    end

    local unLockPos = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local reelIdx = self:getPosReelIdx(iRow, iCol)
            if lockPos[reelIdx] == nil then
                unLockPos[#unLockPos + 1] = {iX = iRow, iY = iCol}
            end
        end
    end
    return unLockPos
end


function CodeGameScreenPharaohMachine:getLocalGameReSpinStoredIcons(...)
    local addLockNodeReelPos = {}
    
    for i=1,#self.m_addLockNodeReelPos do
        local values = self.m_addLockNodeReelPos[i]
        addLockNodeReelPos[#addLockNodeReelPos + 1] =  {values[1], values[2]}
    end
    return addLockNodeReelPos
end

---
-- 计算连线后设置需要移除的线类型
function CodeGameScreenPharaohMachine:MachineRule_localGame_setRmoveLineType(removeLineType)
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        --repsin下没钱
        self.m_vecGetLineInfo = {}
    end
end

function CodeGameScreenPharaohMachine:MachineRule_localGame_ctrlOnceBigMegaWin()  --  大赢控制
    self.m_bIsBigWinCtrl = true
end

---respinFeature
function CodeGameScreenPharaohMachine:getRespinFeature(...)
    if self.m_reSpinCurCount == 3 then
        return {0,3}
    end
    return {0}
end
------------------------------------------------------------------------

----------------------------- 玩法处理 -----------------------------------
---
-- 盘面数据生成之后 计算连线前
-- 改变轮盘数据

function CodeGameScreenPharaohMachine:checkPosInLine(pos)
    for i = 1, #self.m_runSpinResultData.p_winLines do
        local winLine = self.m_runSpinResultData.p_winLines[i]
        for j = 1, #winLine.p_iconPos do
            local posInLine = self:getRowAndColByPos(winLine.p_iconPos[j])
            if posInLine.iX == pos.iX and posInLine.iY == pos.iY then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenPharaohMachine:MachineRule_network_InterveneSymbolMap()
    self.m_wildContinusPos = {}
    --获取所有相邻的wild 坐标合集
    for iCol = 1, self.m_iReelColumnNum do
        local seriesPos = {}
        for iRow = 1, self.m_iReelRowNum do
            if self.m_stcValidSymbolMatrix[iRow][iCol] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local checkPos = {iX = iRow, iY = iCol}
                local inLine = self:checkPosInLine(checkPos)
                if inLine == true then
                    -- 第一个添加进来的或者与上一个相邻则添加到被检索列表
                    if #seriesPos == 0 or seriesPos[#seriesPos].iX + 1 == iRow then
                        seriesPos[#seriesPos + 1] = checkPos
                    end
                end
            end
        end -- end for row

        if #seriesPos == 1 then
            seriesPos[1] = 0
        elseif #seriesPos >= 2 then
            self.m_wildContinusPos[#self.m_wildContinusPos + 1] = {
                iX = seriesPos[1].iX,
                iY = seriesPos[#seriesPos].iY,
                len = #seriesPos
            }
        end
    end -- end for column

    -- printInfo("xcyy wild count = : %d", #self.m_wildContinusPos)
end


--- 
-- 数据生成之后
-- 改变轮盘ui块生成列表 (可以作用于贴长条等 特殊显示逻辑中)
function CodeGameScreenPharaohMachine:MachineRule_InterveneReelList()
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPharaohMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPharaohMachine:MachineRule_SpinBtnCall()
    -- self:showFreeSpinOver(12000000,12,function(  )
    --     -- body
    -- end)
    gLobalSoundManager:setBackgroundMusicVolume(1)
    return false
end

---
-- 轮盘停止时调用
-- 改变轮盘滚动后的数据等
function CodeGameScreenPharaohMachine:MachineRule_stopReelChangeData()
    self:resetSpecialSoundPlayCol()
    self:heldOnAllScore()
    -- node:runAnim("buling")
    --判断是否进入fs
    self:setCreateResNode()
end

function CodeGameScreenPharaohMachine:setCreateResNode()
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)
    --如果有fs
    if bHasFsEffect and self.m_bProduceSlots_InFreeSpin == false then
        --freespin
        self.m_bCreateResNode = false
    end

    --用于断线重连时
    if self.m_bProduceSlots_InFreeSpin == true and self.m_bCreateResNode == true then
        self.m_bCreateResNode = false
    end

    if bHasFsEffect == false and globalData.slotRunData.freeSpinCount == 0 and self.m_bProduceSlots_InFreeSpin == true then
        --freespinover
        self.m_bCreateResNode = true
    end

end

---
-- 添加关卡中触发的玩法
--

---
-- 获取大信号的line动画名称， 根据symbolType
--
-- CodeGameScreenPharaohMachine.SYMBOL_FIX_SYMBOL = 101
-- CodeGameScreenPharaohMachine.SYMBOL_3X3_BIG_SYMBOL = 102
-- CodeGameScreenPharaohMachine.SYMBOL_3X3_BIG_CHIP = 103
-- CodeGameScreenPharaohMachine.SYMBOL_FIX_CHIP = 104
-- CodeGameScreenPharaohMachine.SYMBOL_FIX_GRAND = 105
-- CodeGameScreenPharaohMachine.SYMBOL_FIX_MAJOR = 106
-- CodeGameScreenPharaohMachine.SYMBOL_FIX_MINOR = 107
-- CodeGameScreenPharaohMachine.SYMBOL_FIX_MINI = 108
function CodeGameScreenPharaohMachine:getBsAnimNameByType(symblType)
    local type = symblType - 1000
    if type == 92 then
        type = 11
    elseif type == 90 then
        type = 9
    elseif type == 102 or type == 103 then
        type = 10
    end

    local idleAnimName = "action" .. type
    local animName = "action" .. type .. "_actionframe"
    if type == 0 then
        local a = 1
    end
    return animName, idleAnimName
end

function CodeGameScreenPharaohMachine:getBsAnimNameByTypeJp(score)
    local animName = nil
    local idleAnimName = nil

    if score == "MINI" then
        animName = "action12"
        idleAnimName = "action12_actionframe"
    elseif score == "MINOR" then
        animName = "action13"
        idleAnimName = "action13_actionframe"
    end

    return animName, idleAnimName
end

function CodeGameScreenPharaohMachine:addSelfEffect()
    self.m_jackPotBar:updateJackpotInfo()
    if #self.m_wildContinusPos > 0 then -- 触发了小格子变化大格子effect
        self.m_preWildContinusPos = self.m_wildContinusPos
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_selfEffectType = self.m_changeBigSymbolEffect
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPharaohMachine:MachineRule_playSelfEffect(effectData)
    for i = 1, #self.m_preWildContinusPos do
        local wildChangeData = self.m_preWildContinusPos[i]
        local bigWild = nil

        local changeMusic = nil
        if wildChangeData.len == 2 then
            -- bigWild:showBigSymbolClip(-self.m_SlotNodeH * 0.5 + 2,self.m_SlotNodeW,self.m_SlotNodeH * 2 )
            changeMusic = "PharaohSounds/music_Pharaoh_wild_change.mp3"
            bigWild = self:getSlotNodeWithPosAndType(self.SYMBOL_SECOND_BIG_SYMBOL,wildChangeData.iX,wildChangeData.iY)
        elseif wildChangeData.len == 3 then
            changeMusic = "PharaohSounds/music_Pharaoh_wild_change.mp3"
            bigWild = self:getSlotNodeWithPosAndType(self.SYMBOL_THREE_BIG_SYMBOL,wildChangeData.iX,wildChangeData.iY)
        end

        -- bigWild.p_cloumnIndex = wildChangeData.iY
        -- bigWild.p_rowIndex = wildChangeData.iX
        bigWild.m_bInLine = true

        local linePos = {}
        for lineRowIndex = 1, wildChangeData.len do
            linePos[#linePos + 1] = {
                iX = wildChangeData.iX + (lineRowIndex - 1),
                iY = wildChangeData.iY
            }
        end

        bigWild:setLinePos(linePos)

        local targSp = self:getFixSymbol(wildChangeData.iY, wildChangeData.iX, SYMBOL_NODE_TAG)

        local reelParent = self:getReelParent(wildChangeData.iY)

        -- bigWild:setLocalZOrder(wildChangeData.len + targSp:getLocalZOrder())
        -- bigWild:setTag(targSp:getTag())
        reelParent:addChild(bigWild, wildChangeData.len + targSp:getLocalZOrder(), targSp:getTag())
        bigWild:setPosition(targSp:getPositionX(), targSp:getPositionY())

        bigWild:runAnim("actionframe2")

        gLobalSoundManager:playSound(changeMusic)
    end

    --2秒后播放下轮动画
    scheduler.performWithDelayGlobal(
        function(delay)
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end,
        2,
        self:getModuleName()
    )

    return true
end

function CodeGameScreenPharaohMachine:getReelHeight()
    return 633 - 30
end

function CodeGameScreenPharaohMachine:getReelWidth()
    return 1050
end

function CodeGameScreenPharaohMachine:scaleMainLayer()
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
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        local  posChange = 25
        -- if self.m_isPadScale then
        --     posChange = 25
        --     mainScale = mainScale + 0.05
        -- else
        --     posChange = 25
        -- end
        -- local ratio = display.height/display.width
        -- if  ratio >= 768/1024 then
        --     mainScale = 0.90
        -- elseif ratio < 768/1024 and ratio >= 640/960 then
        --     mainScale = 0.95 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        -- end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale

        self.m_machineNode:setPositionY(mainPosY + posChange)
    end
    
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenPharaohMachine:levelFreeSpinEffectChange()
    self.m_hasBigSymbol = true              --长条快停

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_STATUS,true)
    self.m_jackPotBar:changeFreeSpin()
    self:runCsbAction("freespin")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
    self.m_fsMask:setVisible(true)
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenPharaohMachine:levelFreeSpinOverChangeEffect(content)
    self.m_hasBigSymbol = false             --普通快停

    self.m_jackPotBar:changeNormal()
    self:runCsbAction("normal")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
    self.m_fsMask:setVisible(true)
    self.m_dalyHideMask = true
    local targSp = self:getReelParent(3):getChildByTag(self:getNodeTag(3, 1, SYMBOL_NODE_TAG))
    if targSp and targSp.p_symbolType == self.SYMBOL_3X3_BIG_SYMBOL then
        targSp:getCcbProperty("m_bigbg"):setVisible(true)
    end
    -- self:slotsReelRunData( {4,6,8,10,12} )
end

function CodeGameScreenPharaohMachine:showFreeSpinView(effectData)

    self:clearCurMusicBg()
    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_frame.mp3")

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinMoreAutoNomal(
            self.m_runSpinResultData.p_freeSpinNewCount,
            function()
                self:resetMusicBg(true)  
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    else
        self:showFreeSpinStart(
            self.m_iFreeSpinTimes,
            function()

                -- 切换到freespin 模式下的列信息
                self:changeReelDataBySpinMode(1)
                
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end
end

function CodeGameScreenPharaohMachine:changeReelDataBySpinMode( spinModeType )
    if spinModeType == 1 then
        local columnData = self.m_reelColDatas[3]
        columnData:updateShowColCount(1)

        columnData = self.m_reelColDatas[2]
        columnData:updateShowColCount(0)

        columnData = self.m_reelColDatas[4]
        columnData:updateShowColCount(0)

        self:slotsReelRunData({15, 18, 7, 24, 27})  -- 将第三列设置为行的整倍数，因为每行都是一个占满行的大信号
    elseif spinModeType == 2 then
        local columnData = self.m_reelColDatas[3]
        columnData:updateShowColCount(self.m_iReelRowNum)

        columnData = self.m_reelColDatas[2]
        columnData:updateShowColCount(self.m_iReelRowNum)

        columnData = self.m_reelColDatas[4]
        columnData:updateShowColCount(self.m_iReelRowNum)

        self:slotsReelRunData({15, 18, 21, 24, 27})
    end
end


function CodeGameScreenPharaohMachine:showFreeSpinOverView()
    -- 由于 freespin时， 2，4列不参与滚动， 所以最后阶段需要补偿最后一个格子用于滚动处理
    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_freespin_over.mp3")

    local view=self:showFreeSpinOver(
        globalData.slotRunData.lastWinCoin,
        globalData.slotRunData.totalFreeSpinCount,
        function()
            self:changeReelDataBySpinMode(2)

            self:triggerFreeSpinOverCallFun()
        end
    )
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},710)
end


function CodeGameScreenPharaohMachine:MachineRule_initGame( initSpinData )
    self:setCreateResNode()
    
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE  then

        self:changeFreeSpinReelData()
        self:changeReelDataBySpinMode(1)

    end

end

function CodeGameScreenPharaohMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1)
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
    or self.m_hasBigSymbol == true
    )
    then
        self:creatReelRunAnimation(reelCol + 1)
    end


    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            if self.m_bProduceSlots_InFreeSpin == true and (reelCol == 2 or reelCol == 4) then
        
            else
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        if self.m_bProduceSlots_InFreeSpin == true and (reelCol == 2 or reelCol == 4) then
        
        else
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
    end


    -- if  self:getGameSpinStage() ~= QUICK_RUN  then
    
    -- end

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

function CodeGameScreenPharaohMachine:slotReelDown()
    BaseMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenPharaohMachine:playEffectNotifyNextSpinCall()
    BaseMachineGameEffect.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

---------------------------------------------------------------------------

function CodeGameScreenPharaohMachine:onEnter()

    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self.m_jackPotBar:updateJackpotInfo()
    
end


function CodeGameScreenPharaohMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_goin.mp3")

            scheduler.performWithDelayGlobal(
                function()
                    self:resetMusicBg()
                    self:reelsDownDelaySetMusicBGVolume() 
                end,
                4,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end


function CodeGameScreenPharaohMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

    -- 如果需要改变父类事件监听函数，则在此处修改(具体哪些监听看父类的addObservers)
end

function CodeGameScreenPharaohMachine:onExit()

    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenPharaohMachine:removeObservers()
    BaseSlotoManiaMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end


function CodeGameScreenPharaohMachine:beginReel()
    BaseSlotoManiaMachine.beginReel(self)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_slotParents[2].isReeling = false
        self.m_slotParents[4].isReeling = false

        self.m_slotParents[2].isResActionDone = true
        self.m_slotParents[4].isResActionDone = true
        
    end
    scheduler.performWithDelayGlobal(
        function()
            if self.m_dalyHideMask then
                self.m_dalyHideMask = false
                self.m_fsMask:setVisible(false)
            end
        end,
        self.m_configData.p_reelResTime,
        self:getModuleName()
    )
end

function CodeGameScreenPharaohMachine:getClipWidthRatio(colIndex)
    if colIndex == 3 then
        return 1.5
    else
        return self.m_clipWidtRatio or 1
    end
end
function CodeGameScreenPharaohMachine:initCloumnSlotNodesByNetData()
    BaseSlotoManiaMachine.initCloumnSlotNodesByNetData(self)
    local rowDatas = self.m_initSpinData.p_reels[3]
    local symbolType = rowDatas[3]

    local function removeNode(node)
        node:setVisible(true)
        node:removeFromParent()
        local symbolType = node.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, node)
    end

    --大图
    if symbolType == self.SYMBOL_3X3_BIG_SYMBOL or symbolType == self.SYMBOL_3X3_BIG_CHIP then
        local node2 = self:getReelParent(2):getChildByTag(self:getNodeTag(2, 1, SYMBOL_NODE_TAG))
        removeNode(node2)
        local node4 = self:getReelParent(4):getChildByTag(self:getNodeTag(4, 1, SYMBOL_NODE_TAG))
        removeNode(node4)
        local node3 = self:getReelParent(3):getChildByTag(self:getNodeTag(3, 1, SYMBOL_NODE_TAG))
        node3.m_isLastSymbol = true
    end
end

--创建闪电
function CodeGameScreenPharaohMachine:createLight()
    self:clearLight()
    self.m_VegasCashLight = util_createView("CodePharaohSrc.PharaohLight")
    gLobalViewManager.p_ViewLayer:addChild(self.m_VegasCashLight)
end

--销毁闪电
function CodeGameScreenPharaohMachine:clearLight()
    if self.m_VegasCashLight then
        self.m_VegasCashLight:removeFromParent()
        self.m_VegasCashLight = nil
    end
end

--触发播放闪电特效
function CodeGameScreenPharaohMachine:playTriggerLight(func)
    self:createLight()
    self.m_lightIndex = 1
    self.m_lightScore = 0
    self.m_lightFunc = function()
        if self.clearLight then
            self:clearLight()
        end
        if func then
            func(self.m_lightScore)
        end
    end
    local allFixPos = self.m_runSpinResultData.p_storedIcons
    if allFixPos ~= nil then
        self:triggerLight()
    else
        if self.m_lightFunc then
            self.m_lightFunc()
            self.m_lightFunc = nil
        end
    end
end

--respin循环播放闪电条件判断
function CodeGameScreenPharaohMachine:triggerLight()
    local allFixPos = self.m_runSpinResultData.p_storedIcons
    --大图特殊处理
    if self:isFsRespin() then
        allFixPos = {}
        -- local newlist={0,5,10,1,6,11,2,7,12,3,8,13,4,9,14}
        for i = 1, #self.m_runSpinResultData.p_storedIcons do
            local value = self.m_runSpinResultData.p_storedIcons[i]
            if value ~= 12 then
                -- value=newlist[value+1]
                local isAddPos = true
                for j = 1, #BIGSYMBOL_REMOVE_LIST do
                    if BIGSYMBOL_REMOVE_LIST[j] == value then
                        isAddPos = false
                        break
                    end
                end
                if isAddPos then
                    allFixPos[#allFixPos + 1] = value
                end
            end
        end
        allFixPos[#allFixPos + 1] = 12
    end

    if self.m_lightIndex <= #allFixPos then
        local fixPos = self:getRowAndColByPos(allFixPos[self.m_lightIndex])
        self:triggerLightForPos(fixPos.iX, fixPos.iY)
        self.m_lightIndex = self.m_lightIndex + 1
    else
        if self.m_runSpinResultData.p_storedIcons and #self.m_runSpinResultData.p_storedIcons >= 15 then
            self.isGrandJackpot = true
            local jackpotScore = self:BaseMania_getJackpotScore(1)
            self.m_lightScore = self.m_lightScore + jackpotScore
            self:showRespinJackpot(
                4,
                util_formatCoins(jackpotScore, 30),
                function()
                    self.isGrandJackpot = false
                    if self.m_lightFunc then
                        self.m_lightFunc()
                        self.m_lightFunc = nil
                    end
                end
            )
        else
            if self.isGrandJackpot then
                return
            end
            if self.m_lightFunc then
                self.m_lightFunc()
                self.m_lightFunc = nil
            end
        end
    end
end

--逐条闪电播放 JackPot播放 分数更新
-- function CodeGameScreenPharaohMachine:triggerLightForPos(iX, iY)
--     local symbolId = self:getSpinResultReelsType(iY, iX)
--     local specialNodeInfo = symbolId
--     local score
--     local isJackpot = 0
--     local jackpotScore = 0
--     local commonScore = 0
--     local lineBet = self:BaseMania_getLineBet()
--     if specialNodeInfo ~= nil then
--         score = specialNodeInfo.value
--         if type(score) ~= "string" then
--             commonScore = specialNodeInfo.value * lineBet
--         elseif score == "MAJOR" then
--             jackpotScore = self:BaseMania_getJackpotScore(2)
--             isJackpot = 3
--         elseif score == "MINOR" then
--             jackpotScore = self:BaseMania_getJackpotScore(3)
--             isJackpot = 2
--         elseif score == "MINI" then
--             jackpotScore = self:BaseMania_getJackpotScore(4)
--             isJackpot = 1
--         end
--     end

--     local addScore = jackpotScore + commonScore
--     self.m_lightScore = self.m_lightScore + addScore
--     local strScore = util_formatCoins(self.m_lightScore, 30)
--     local postCoins = self.m_lightScore

--     local targSp = self.m_clipParent:getChildByTag(self:getNodeTag(iY, iX, SYMBOL_NODE_TAG))
--     local posEndWorldPos = nil
--     if targSp ~= nil then
--         posEndWorldPos =  self.m_clipParent:convertToWorldSpace(cc.p(targSp:getPosition()))
--     else 
--         -- targSp = self:getReelParent(iY):getChildByTag(self:getNodeTag(iY, iX, SYMBOL_NODE_TAG))
--         targSp = self:getReelParent(iY):getChildByTag(self:getNodeTag(iY, iX, SYMBOL_NODE_TAG))
        
--         if targSp == nil then
--             local worldPos  = self:getReelPos(iY)

--             posEndWorldPos = cc.p(worldPos.x + self.m_SlotNodeW * 0.5,worldPos.y + (iX - 0.5) * self.m_SlotNodeH)
--         else
--             posEndWorldPos = self:getReelParent(iY):convertToWorldSpace(cc.p(targSp:getPosition()))
--         end


--     end 
--     if self:isFsRespin() then
--         if self.m_bigSymbolInfos[targSp.p_symbolType] ~= nil then
--             posEndWorldPos.y=posEndWorldPos.y+self.m_SlotNodeH
--         end
--     end

--     local startPos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(posEndWorldPos)
--     -- local endPos=cc.p(display.cx,self.m_fReelHeigth * 0.5 + 360)
--     local endPos = self.m_reSpinBar:getParent():convertToWorldSpace(cc.p(self.m_reSpinBar:getPosition()))
--     endPos = cc.pAdd(endPos, cc.p(0, 20))
--     local parentData = self.m_slotParents[iY]
--     local slotParent = parentData.slotParent
--     local slotNode = self.m_clipParent:getChildByTag(self:getNodeTag(iY, iX, SYMBOL_NODE_TAG))

--     if slotNode == nil then
--         slotNode = self:getReelParent(iY):getChildByTag(self:getNodeTag(iY, iX, SYMBOL_NODE_TAG))
--     end

--     slotNode:runAnim("actionframe1")

--     if self.m_VegasCashLight and self.m_VegasCashLight.triggerLight then
--         self.m_VegasCashLight:triggerLight(startPos, endPos)
--         local delayTime = 0.4

--         scheduler.performWithDelayGlobal(
--             function()
--                 if isJackpot == 0 then
--                     if util_random(1, 2) == 1 then 
--                         gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_1.mp3")
--                     else 
--                         gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_2.mp3")
--                     end
--                 else 
--                     gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_3.mp3")
--                 end
    
--             end,
--             delayTime,
--             self:getModuleName()
--         )

--         scheduler.performWithDelayGlobal(
--             function()
--                 self.m_reSpinBar:toAction("jiesuan2")
--                 self.m_reSpinBar:updateWinCount(strScore)
--             end,
--             delayTime + 0.5,
--             self:getModuleName()
--         )

--         scheduler.performWithDelayGlobal(
--             function()
--                 if isJackpot == 0 then
--                     self:triggerLight()
--                 else
--                     self:showRespinJackpot(
--                         isJackpot,
--                         util_formatCoins(jackpotScore, 30),
--                         function()
--                             self:triggerLight()
--                         end
--                     )
--                 end
--             end,
--             delayTime + 1.2,
--             self:getModuleName()
--         )
--     end
-- end

--
function CodeGameScreenPharaohMachine:respinTip()
    
end 

-- RespinView
function CodeGameScreenPharaohMachine:showRespinView(effectData)




    --可随机的普通信息
    local randomTypes = 
    { TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
      TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
      TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
      TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
      TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
      TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
      TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
      TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
      TAG_SYMBOL_TYPE.SYMBOL_SCORE_1}       

    --可随机的特殊信号 
    local endTypes = 
    {
        {type = self.SYMBOL_FIX_CHIP, runEndAnimaName = "", bRandom = false},
        {type = 93, runEndAnimaName = "", bRandom = true},
        {type = 94, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_3X3_BIG_SYMBOL, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_3X3_BIG_CHIP, runEndAnimaName = "", bRandom = false},
    }

    --构造盘面数据
    performWithDelay(self,function()
    --先播放动画 再进入respin
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_goin_lightning.mp3")
        if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
            self:triggerReSpinCallFun(endTypes, randomTypes)
        else
        -- 由玩法触发出来， 而不是多个元素触发
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                self.m_runSpinResultData.p_reSpinCurCount = 3
             end
            self:triggerReSpinCallFun(endTypes, randomTypes)
    end   
     
    end
    ,0.2)

end

function CodeGameScreenPharaohMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    globalData.slotRunData.currSpinMode = RESPIN_MODE
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    --转换storeicons 
    local storeIcons = {}
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    for i=1,#storedIcons do
        local pos = self:getRowAndColByPos(storedIcons[i][1])
        storeIcons[#storeIcons + 1] = {iX = pos.iX,iY = pos.iY, score = storedIcons[i][2]}
    end
    self.m_respinView:setStoreIcons(storeIcons)
    self:initRespinView(endTypes, randomTypes)
end

--重写组织respinData信息
function CodeGameScreenPharaohMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end


function CodeGameScreenPharaohMachine:playRespinViewShowSound()
    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_frame.mp3")
end

-- function CodeGameScreenPharaohMachine:triggerReSpinCreateNode( iRow,iCol )
--     --获取界面上的小块坐标
--     local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow,SYMBOL_NODE_TAG))

--     -- 根据类型， 改变 node 的csb类型
--     if targSp ~= nil then

--         local symbolId = self:getSpinResultReelsType(iCol, iRow)
--         local specialNodeInfo = self:getIDCompares(symbolId)

--         if specialNodeInfo ~= nil then

--             local symbolValue = specialNodeInfo.value

--             if symbolValue == "MINI" then
--                 targSp:changeCCBByName("Socre_Pharaoh_Special_Jackpot1",self.SYMBOL_JACKPOT1)
--             elseif symbolValue == "MINOR" then
--                 targSp:changeCCBByName("Socre_Pharaoh_Special_Jackpot2",self.SYMBOL_JACKPOT2)
--             elseif symbolValue == "MAJOR" then
--                 targSp:changeCCBByName("Socre_Pharaoh_Special_Jackpot3",self.SYMBOL_JACKPOT3)
--             else

--                 local scoreValue = targSp:getCcbProperty("score_lab"):getString()

--                 targSp:changeCCBByName("Socre_Pharaoh_Special_Rase",self.SYMBOL_FIX_SYMBOL)

--                 targSp:getCcbProperty("score_lab"):setString(scoreValue)

--             end

--         end
--     end

--     BaseMachine.triggerReSpinCreateNode(self,iRow,iCol)
-- end

function CodeGameScreenPharaohMachine:showRespinOverView(effectData)
    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_over_win.mp3")    

    local view=self:showReSpinOver(
        self.m_serverWinCoins,
        function()
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
        end
    )
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},710)
end

function CodeGameScreenPharaohMachine:showRespinJackpot(index, coins, func)
    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_jackpotwinframe.mp3")
    local jackPotWinView = util_createView("CodePharaohSrc.PharaohJackPotWinView")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index, coins, self, func)
end

-- function CodeGameScreenPharaohMachine:runNextReSpinReel()
--     if self.m_waitReSpinRunTime then
--         scheduler.performWithDelayGlobal(function()
--             BaseMachine.runNextReSpinReel(self)
--             self.m_waitReSpinRunTime=nil
--         end, self.m_waitReSpinRunTime)
--     else
--         BaseMachine.runNextReSpinReel(self)
--     end
-- end

function CodeGameScreenPharaohMachine:triggerChangeRespinNodeInfo(respinNodeInfo)
    --中间三列不能滚
    if self:isFsRespin() then
        for iCol=2,4 do
            for iRow=1,3 do
                for i=1,#respinNodeInfo do
                    local nodeInfo = respinNodeInfo[i]
                    if nodeInfo.ArrayPos.iX == iRow and nodeInfo.ArrayPos.iY == iCol then
                        nodeInfo.status = RESPIN_NODE_STATUS.LOCK

                        if iRow ~= 1 or  iCol ~= 3 then
                            print("Chinoiserie "..iCol.." "..iRow)
                            nodeInfo.bCleaning = false
                            nodeInfo.isVisible = false
                        end
                    end
                end
            end
        end
    end


    self.m_respinView:setCallFun(function(col, row)
        return  self:getSpinResultReelsType(col, row)
     end, function(symbolId )
        return symbolId
     end)
end

function CodeGameScreenPharaohMachine:reSpinEndAction()
    self.m_respinEndNodes = {}
    self.m_lightScore = 0
    self.m_respinEndNodes = self.m_respinView:getAllCleaningNode()
    
    if self:isFsRespin() then
        for i=1, #self.m_respinEndNodes do
            local node = self.m_respinEndNodes[i]
            if node.p_rowIndex == 1 and node.p_cloumnIndex == 3 then
                table.remove( self.m_respinEndNodes, i)
                self.m_respinEndNodes[#self.m_respinEndNodes + 1] = node
                break
            end
        end
    end

    self:reSpinShowWait()

    performWithDelay(self,function()
        self:playCleaningNextRepinNode()  
    end,1)
end

function CodeGameScreenPharaohMachine:playCleaningNextRepinNode()
    if #self.m_respinEndNodes == 0 then
        --gand jp 
        if self.m_runSpinResultData.p_storedIcons and #self.m_runSpinResultData.p_storedIcons >= 15 then
            local jackpotScore = self:BaseMania_getJackpotScore(1)
            self.m_lightScore = self.m_lightScore + jackpotScore
            self:showRespinJackpot(
                4,
                util_formatCoins(jackpotScore, 30),
                function()
                    self:respinOver()
                end
            )
        else 
            self:respinOver()
        end
        return
    end
    self.m_nowPlayNode =  self.m_respinEndNodes[1]
    table.remove(self.m_respinEndNodes, 1)
    self:createLight()
    self:triggerLightForPos()
end

function CodeGameScreenPharaohMachine:playCleaningAnima()

    if self.m_nowPlayNode.p_symbolType >= 1000 then
        local animID = 10
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(self.m_nowPlayNode.p_rowIndex ,self.m_nowPlayNode.p_cloumnIndex))
        if score == "MINI" then
            animID = 12
        elseif score == "MINOR" then
            animID = 13
        elseif score == "MAJOR" then
            animID = 14
        elseif score == "GRAND" then
            animID = 15
        end
        local animaName = "action"..animID.."_actionframe"
        self.m_nowPlayNode:runAnim(animaName, false)
    else
        
        local symbolId = self:getSpinResultReelsType(self.m_nowPlayNode.p_cloumnIndex, self.m_nowPlayNode.p_rowIndex)
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(self.m_nowPlayNode.p_rowIndex ,self.m_nowPlayNode.p_cloumnIndex))
        local animaName = nil

        if score ~= nil then
            if type(score) ~= "string" then
                animaName = "idleframe_actionframe"
            else
                if score == "MINI" then
                      animaName = "jackpot_1_actionframe"
                elseif score == "MINOR" then
                      animaName = "jackpot_2_actionframe"
                elseif score == "MAJOR" then
                      animaName = "jackpot_3_actionframe"
                else
                      animaName = "jackpot_4_actionframe"
                end
            end
        end

        if animaName ~= nil then
            self.m_nowPlayNode:runAnim(animaName, false)
        end
    end
end

--逐条闪电播放 JackPot播放 分数更新
function CodeGameScreenPharaohMachine:triggerLightForPos()
    local symbolId = self:getSpinResultReelsType(self.m_nowPlayNode.p_cloumnIndex, self.m_nowPlayNode.p_rowIndex)
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(self.m_nowPlayNode.p_rowIndex ,self.m_nowPlayNode.p_cloumnIndex))
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0

    local lineBet = self:BaseMania_getLineBet() * self.m_lineCount
    
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "MAJOR" then
            jackpotScore = self:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            isJackpot = 3
        elseif score == "MINOR" then
            jackpotScore =  self:BaseMania_getJackpotScore(3)
            addScore =jackpotScore + addScore                  ---self:BaseMania_getJackpotScore(3)
            isJackpot = 2
        elseif score == "MINI" then
            jackpotScore = self:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                      ---self:BaseMania_getJackpotScore(4)
            isJackpot = 1
        end
    end

    self.m_lightScore = self.m_lightScore + addScore
    local strScore = util_formatCoins(self.m_lightScore, 30)
    local postCoins = self.m_lightScore
    
    local posEndWorldPos = self.m_nowPlayNode:getParent():convertToWorldSpace(cc.p(self.m_nowPlayNode:getPosition()))
    
    if self:isFsRespin() then
        -- if self.m_bigSymbolInfos[self.m_nowPlayNode.p_symbolType] ~= nil then
        --     posEndWorldPos.y=posEndWorldPos.y+self.m_SlotNodeH
        -- end
    end

    local startPos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(posEndWorldPos)
    -- local endPos=cc.p(display.cx,self.m_fReelHeigth * 0.5 + 375)
    local endPos = self.m_reSpinBar:getParent():convertToWorldSpace(cc.p(self.m_reSpinBar:getPosition()))


    self:playCleaningAnima()
    if self.m_VegasCashLight and self.m_VegasCashLight.triggerLight then
        self.m_VegasCashLight:triggerLight(startPos,endPos)

        
        scheduler.performWithDelayGlobal(function()
            if isJackpot == 0 then
                if util_random(1, 2) == 1 then 
                    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_1.mp3")
                else 
                    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_2.mp3")
                end
            else 
                gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_linghtning_3.mp3")
            end

        end,0.1,self:getModuleName())

        scheduler.performWithDelayGlobal(function()
            self.m_reSpinBar:toAction("jiesuan2")
            self.m_reSpinBar:updateWinCount(strScore)

        end,0.3,self:getModuleName())

        scheduler.performWithDelayGlobal(function()
            if isJackpot == 0 then
                self:playCleaningNextRepinNode()
            else
                self:showRespinJackpot(isJackpot, util_formatCoins(jackpotScore,30), function()
                    self:playCleaningNextRepinNode()
                end)
            end
        end,0.4,self:getModuleName())
    end
end


--如果是大图隐藏中心图片
function CodeGameScreenPharaohMachine:reSpinFixHideBigSymbol(node, targSp)
    if targSp.p_symbolType == self.SYMBOL_3X3_BIG_SYMBOL then
        node:setVisible(false)
    end
end
--ReSpin开始改变UI状态
function CodeGameScreenPharaohMachine:changeReSpinStartUI(curCount)
    --播放respin北京音乐
    self:clearCurMusicBg()
    gLobalSoundManager:playBgMusic("PharaohSounds/music_Pharaoh_lightning_bg.mp3")
    
    self.m_reSpinBar:setVisible(true)
    self.m_reSpinBar:toAction("3show")
    self.m_reSpinBar:updateLeftCount(curCount)
    self.m_jackPotBar:setVisible(false)
end

--ReSpin刷新数量
function CodeGameScreenPharaohMachine:changeReSpinUpdateUI(curCount)
    if curCount == 3 then
        gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_lightning_count_3.mp3")

        self.m_reSpinBar:toAction("3show")
    end
    print("当前展示位置信息  %d ", curCount)
    self.m_reSpinBar:updateLeftCount(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenPharaohMachine:changeReSpinOverUI()
    self.m_reSpinBar:setVisible(false)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
    end
    self.m_reSpinBar:updateWinCount(0)
    self.m_jackPotBar:setVisible(true)
end
--开始算分之前 提示ReSpin结束
function CodeGameScreenPharaohMachine:reSpinShowWait(waitTime)
    gLobalSoundManager:stopBgMusic( )
    gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_freespin_over.mp3")

    self.m_reSpinBar:updateLeftCount(0)
    performWithDelay(
        self,
        function()
            self.m_reSpinBar:toAction("jiesuan")
            self.m_reSpinBar:updateWinCount(0)
        end,
        1
    )
end

function CodeGameScreenPharaohMachine:showEffect_FreeSpin(effectData)
    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end


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
        self:showBonusAndScatterLineTip(scatterLineValue,function()
            -- self:visibleMaskLayer(true,true)
            self:showFreeSpinView(effectData)
        end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue

        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()

    elseif self.m_bProduceSlots_InFreeSpin then 
        gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_goin_lightning.mp3")

       local targSp = self:getReelParent(3):getChildByTag(self:getNodeTag(3, 1, SYMBOL_NODE_TAG))
       local animaName = "action9_actionframe"
       targSp:runAnim(animaName, false)
       local animTime = targSp:getAniamDurationByName(animaName)
        --2秒后播放下轮动画
        scheduler.performWithDelayGlobal(
            function(delay)
                self:showFreeSpinView(effectData)
            end,
            animTime,
            self:getModuleName()
        )
    else 
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end


function CodeGameScreenPharaohMachine:showAllFrame(winLines)

    -- 根据frame 数量进行清理
    local inLineFrames = {}
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

            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            -- end

        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s","")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i=1,frameNum do

            local symPosData = lineValue.vecValidMatrixSymPos[i]


            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then

                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen( )

                local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5

                local showGridH = columnData.p_showGridH 
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    showGridH = self.m_reelColDatas[1].p_showGridH 
                end
                local posY = showGridH * symPosData.iX - showGridH * 0.5 + columnData.p_slotColumnPosY

                local node = self:getFrameWithPool(lineValue,symPosData)
                node:setPosition(cc.p(posX,posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)

            end

        end
    end

end

function CodeGameScreenPharaohMachine:showLineFrameByIndex(winLines,frameIndex)

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
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

            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end

        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i=1,frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
        local showGridH = columnData.p_showGridH 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            showGridH = self.m_reelColDatas[1].p_showGridH 
        end
        local posY = showGridH * symPosData.iX - showGridH * 0.5 + columnData.p_slotColumnPosY
        
        local node = nil
        if i <=  hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue,symPosData)
        end
        node:setPosition(cc.p(posX,posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
               self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe",true)
        else
            node:runAnim("actionframe",true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end

    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

return CodeGameScreenPharaohMachine
