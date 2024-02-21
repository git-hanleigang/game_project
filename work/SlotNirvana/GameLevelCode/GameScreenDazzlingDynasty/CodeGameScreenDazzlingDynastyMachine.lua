---
-- island li
-- 2019年1月26日
-- CodeGameScreenDazzlingDynastyMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenDazzlingDynastyMachine = class("CodeGameScreenDazzlingDynastyMachine", BaseSlotoManiaMachine)

CodeGameScreenDazzlingDynastyMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5
CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 6
CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7

--播放收集wild和bonus动画
CodeGameScreenDazzlingDynastyMachine.EFFECT_SELF_PLAYFLYBONUS = GameEffect.EFFECT_SELF_EFFECT + 1

CodeGameScreenDazzlingDynastyMachine.m_choiceTriggerRespin = nil
CodeGameScreenDazzlingDynastyMachine.m_bIsSelectCall = nil
CodeGameScreenDazzlingDynastyMachine.m_iSelectID = nil
CodeGameScreenDazzlingDynastyMachine.m_gameEffect = nil
CodeGameScreenDazzlingDynastyMachine.m_chooseRepin = nil

-- 构造函数
function CodeGameScreenDazzlingDynastyMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    --特殊小块初始化数量，为了在断线重连时下帧显示出来，否则创建的小块会隐藏
    self:__setSpecialSymbolCount(0)
    self:__setFreeSpinScore(0, false)
    --init
    self:initGame()
end

function CodeGameScreenDazzlingDynastyMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("DazzlingDynastyConfig.csv", "LevelDazzlingDynastyConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

function CodeGameScreenDazzlingDynastyMachine:initUI()
    self.m_chooseRepin = false
    self.m_choiceTriggerRespin = false

    self.coinNode = self:findChild("coins")

    self.jackPotLayer = self:findChild("Jackpot")

    self.jackPotLayer2 = self:findChild("Jackpot2")

    self.diamondCoins = self:findChild("Diamond_coins")

    self.freeSpinNode = self:findChild("freespin")

    -- local zhetang = self:findChild("zhedang")
    -- zhetang:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 100)

    self:runCsbAction("idleframe", true)

    local jackPotBar = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyJackPotBar")
    self.m_jackPotBar = jackPotBar
    self.jackPotLayer:addChild(jackPotBar)
    jackPotBar:initMachine(self)

    local goldMidTopUI = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyGoldMidTopUI")
    self.goldMidTopUI = goldMidTopUI
    self.coinNode:addChild(goldMidTopUI)

    local diamondUI = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyDiamondUI")
    self.m_diamondUI = diamondUI
    self.diamondCoins:addChild(diamondUI)

    local bonusFreeSpinBar = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyBonusFreeSpinBar")
    self.bonusFreeSpinBar = bonusFreeSpinBar
    self.freeSpinNode:addChild(bonusFreeSpinBar)

    local bonusTopUI = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyBonusTopUI")
    self.bonusTopUI = bonusTopUI
    bonusTopUI:setExtraInfo(self)
    self.jackPotLayer2:addChild(bonusTopUI)

    local freeSpinTopUI = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyFreeSpinTopUI")
    self.freeSpinTopUI = freeSpinTopUI
    freeSpinTopUI:setExtraInfo(self)
    self.jackPotLayer2:addChild(freeSpinTopUI)

    self:changeTopUIState()

    self:initFreeSpinBar() -- FreeSpinbar

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]
            local notPlaySound = params[4]
            --小游戏赢钱不播放音效
            if params[4] then
                return
            end

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 2
            if winRate <= 1 then
                soundIndex = 1
                soundTime = 1
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

            self.m_winSoundsId = globalMachineController:playBgmAndResume("DazzlingDynastySounds/music_DazzlingDynasty_last_win_" .. soundIndex .. ".mp3", soundTime, 0.4, 1)
            performWithDelay(
                self,
                function()
                    self.m_winSoundsId = nil
                end,
                soundTime
            )
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
    -- self:__adaptBgScale()
end

function CodeGameScreenDazzlingDynastyMachine:__adaptBgScale()
    -- local gameBg = self.m_gameBg
    -- local gameBgLayer = gameBg:findChild("Layer")
    -- local bg1 = gameBg:findChild("DazzlingDynasty_bg_8")
    -- local bg2 = gameBg:findChild("DazzlingDynasty_bg1_1")
    -- local bg1Size = bg1:getContentSize()
    -- local bg2Size = bg2:getContentSize()
    -- local deviceWidth, deviceHeight = display.width, display.height
    -- if deviceWidth > bg1Size.width then
    --     util_adaptBgScale(bg1)
    -- end
    -- if deviceWidth > bg2Size.width then
    --     util_adaptBgScale(bg2)
    -- end
end

function CodeGameScreenDazzlingDynastyMachine:__setSpecialSymbolCount(count)
    self.specialSymbolCount = count
end

function CodeGameScreenDazzlingDynastyMachine:__addSpecialSymbolCount(count)
    self:__setSpecialSymbolCount(self:getSpecialSymbolCount() + count)
end

function CodeGameScreenDazzlingDynastyMachine:getSpecialSymbolCount()
    return self.specialSymbolCount
end

function CodeGameScreenDazzlingDynastyMachine:__setFreeSpinScore(score, playAnimFlag)
    self.m_freeSpinScore = score
    if self.goldMidTopUI ~= nil then
        self.goldMidTopUI:setScore(score, playAnimFlag)
    end
end

function CodeGameScreenDazzlingDynastyMachine:__addFreeSpinScore(score)
    self:__setFreeSpinScore(self.m_freeSpinScore + score, true)
end

function CodeGameScreenDazzlingDynastyMachine:getFreeSpinScore()
    return self.m_freeSpinScore
end

function CodeGameScreenDazzlingDynastyMachine:scaleMainLayer()
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
        local ratio = display.height / display.width
        if ratio >= 768 / 1024 then
            mainScale = 0.85
        elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
            mainScale = 0.95 - 0.05 * ((ratio - 640 / 960) / (768 / 1024 - 640 / 960))
        end
        util_csbScale(self.m_machineNode, mainScale)
    end

    self.m_machineRootScale = mainScale
end

-- 断线重连
function CodeGameScreenDazzlingDynastyMachine:MachineRule_initGame()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenDazzlingDynastyMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "DazzlingDynasty"
end

-- 继承底层respinView
function CodeGameScreenDazzlingDynastyMachine:getRespinView()
    return "CodeDazzlingDynastySrc.DazzlingDynastyRespinView"
end
-- 继承底层respinNode
function CodeGameScreenDazzlingDynastyMachine:getRespinNode()
    return "CodeDazzlingDynastySrc.DazzlingDynastyRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenDazzlingDynastyMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_BONUS then
        return "Socre_DazzlingDynasty_Wild"
    elseif symbolType == self.SYMBOL_FIX_BONUS_LV1 then
        return "Socre_DazzlingDynasty_Bonus"
    elseif symbolType == self.SYMBOL_FIX_BONUS_LV2 then
        return "Socre_DazzlingDynasty_Bonus_green"
    elseif symbolType == self.SYMBOL_FIX_BONUS_LV3 then
        return "Socre_DazzlingDynasty_Bonus_yellow"
    elseif symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN then
        return "Socre_DazzlingDynasty_Bonus_AddSpin"
    elseif symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 then
        return "Socre_DazzlingDynasty_Bonus_greenAddSpin"
    elseif symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
        return "Socre_DazzlingDynasty_Bonus_yellowAddSpin"
    end

    return nil
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenDazzlingDynastyMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    for k, v in ipairs(storedIcons) do
        if v[1] == id then
            score = v[2]
        end
    end
    return score
end

function CodeGameScreenDazzlingDynastyMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_BONUS_LV1 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

function CodeGameScreenDazzlingDynastyMachine:getScoreInfoByPos(rowIndex, colIndex)
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(rowIndex, colIndex)) --获取分数（网络数据）
    return score ~= nil, score
end

-- 给respin小块进行赋值
function CodeGameScreenDazzlingDynastyMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local symbolType = symbolNode.p_symbolType

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local scoreFlag, score = self:getScoreInfoByPos(iRow, iCol)
        if scoreFlag then
            --respin更新分数
            local lbScore = symbolNode:getCcbProperty("m_lb_score")
            if lbScore == nil then
                return
            end
            local curSpinMode = self:getCurrSpinMode()
            local specialSymbolCount = self:getSpecialSymbolCount()

            local hasSpecialSymbol =
                symbolType == self.SYMBOL_FIX_BONUS_LV2 or symbolType == self.SYMBOL_FIX_BONUS_LV3 or symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3
            if curSpinMode == RESPIN_MODE then
                if hasSpecialSymbol then
                    if specialSymbolCount == 0 then
                        lbScore:setVisible(false)
                        if symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
                            local sprAddSpin = symbolNode:getCcbProperty("DazzlingDynasty_spin02_1")
                            sprAddSpin:setVisible(true)
                        end
                    elseif specialSymbolCount > 0 then
                        if symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
                            local sprAddSpin = symbolNode:getCcbProperty("DazzlingDynasty_spin02_1")
                            sprAddSpin:setVisible(false)
                        end
                        self:__addSpecialSymbolCount(-1)
                    end
                end
            elseif curSpinMode == FREE_SPIN_MODE then
                lbScore:setVisible(true)
            end
            lbScore:setString(score)
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolType) -- 获取随机分数（本地配置）
        if score ~= nil then
            --local lineBet = globalData.slotRunData:getCurTotalBet()
            --这块写死
            local lbScore = symbolNode:getCcbProperty("m_lb_score")
            if lbScore then
                lbScore:setString(score)
            end
        end
    end
end

function CodeGameScreenDazzlingDynastyMachine:initCloumnSlotNodesByNetData()
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()

    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP = true
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowNum then
                                -- body
                                isUP = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) + colIndex
            if self:isBonusSymbol(symbolType) then
                node.p_showOrder = node.p_showOrder + colIndex
            end

            parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end

    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    local runResultData = self.m_runSpinResultData.p_reels
    --统计下特殊信号的数量，防止下次进入关卡时创建的特殊信号会隐藏数字
    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolType = runResultData[i][j]
            if symbolType == self.SYMBOL_FIX_BONUS_LV2 or symbolType == self.SYMBOL_FIX_BONUS_LV3 or symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
                --基础轮盘和respinView两个
                self:__addSpecialSymbolCount(2)
            end
        end
    end

    self:initGridList()
end

function CodeGameScreenDazzlingDynastyMachine:randomSlotNodesByReel()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex + colIndex

            parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function CodeGameScreenDazzlingDynastyMachine:createSlotNextNode(parentData)
    BaseSlotoManiaMachine.createSlotNextNode(self, parentData)
    parentData.order = self:getBounsScatterDataZorder(parentData.symbolType) - parentData.rowIndex + parentData.cloumnIndex + parentData.symbolType
end

function CodeGameScreenDazzlingDynastyMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    symbolType = self:formatAddSpinSymbol(symbolType)

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:isBonusSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + symbolType
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + TAG_SYMBOL_TYPE.SYMBOL_SCATTER
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + symbolType
        end
    end
    return order
end

function CodeGameScreenDazzlingDynastyMachine:updateReelGridNode(node)
    if self:isBonusSymbol(node.p_symbolType) then
        self:setSpecialNodeScore(self, {node})
    -- local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {node})
    -- self:runAction(callFun)
    end
end
-- function CodeGameScreenDazzlingDynastyMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
--     local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col, isLastSymbol)

--     if self:isBonusSymbol(symbolType) then
--         --下帧调用 才可能取到 x y值
--         -- 给respinBonus小块进行赋值
--         local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
--         self:runAction(callFun)
--     end

--     return reelNode
-- end

function CodeGameScreenDazzlingDynastyMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenDazzlingDynastyMachine:getPreLoadSlotNodes()
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    local loadNode = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_ADDSPIN, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_ADDSPIN_LV2, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_ADDSPIN_LV3, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_LV1, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_LV2, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_LV3, count = 3}
    }
    return loadNode
end

function CodeGameScreenDazzlingDynastyMachine:__removeSymboSlotNode(nodeList, symbolType)
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenDazzlingDynastyMachine:isBonusSymbol(symbolType)
    if
        symbolType == self.SYMBOL_FIX_BONUS_LV1 or symbolType == self.SYMBOL_FIX_BONUS_LV2 or symbolType == self.SYMBOL_FIX_BONUS_LV3 or symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or
            symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3
     then
        return true
    end
    return false
end

function CodeGameScreenDazzlingDynastyMachine:formatAddSpinSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 then
        return self.SYMBOL_FIX_BONUS_LV2
    elseif symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
        return self.SYMBOL_FIX_BONUS_LV3
    end
    return symbolType
end

--播放特殊信号动画
function CodeGameScreenDazzlingDynastyMachine:__checkPlayDownBonusNodeAnim(reelCol)
    local reelRow = self.m_iReelRowNum
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode ~= RESPIN_MODE then
        local hasBonus = false
        for i = 1, reelRow do
            local symbolNode = self:getFixSymbol(reelCol, i, SYMBOL_NODE_TAG)
            if symbolNode then
                local symbolType = symbolNode.p_symbolType
                if symbolType == self.SYMBOL_FIX_BONUS_LV1 or symbolType == self.SYMBOL_FIX_BONUS_LV2 then
                    hasBonus = true
                    symbolNode:runAnim("buling", false)
                end
            end
        end
        if hasBonus then

            local soundPath =  "DazzlingDynastySounds/music_DazzlingDynasty_Bonus_Down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end

        end
    end
end

function CodeGameScreenDazzlingDynastyMachine:__handleCheckFreeBonusLv2Count(animCor)
    local curSpinMode = self:getCurrSpinMode()
    local reelRow = self.m_iReelRowNum
    local reelCol = self.m_iReelColumnNum
    if curSpinMode == FREE_SPIN_MODE then
        local bonusLv2Count = 0
        for i = 1, reelRow do
            for j = 1, reelCol do
                local symbolNode = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
                if symbolNode and symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS_LV2 then
                    bonusLv2Count = bonusLv2Count + 1
                end
            end
        end
        if bonusLv2Count >= 3 then
            self:__showFreeSpinMoreUI(animCor)
        end
    end
end

function CodeGameScreenDazzlingDynastyMachine:__playTriggerBonusNodeAnim(callBack)
    --[[
        local m_runSpinResultData = self.m_runSpinResultData
        local reels = m_runSpinResultData.p_reels
        local reelRow = self.m_iReelRowNum
        local reelColumn = self.m_iReelColumnNum
        for i = 1,reelRow do
            for j = 1,reelColumn do
                local symbolType = reels[i][j]
                if symbolType == self.SYMBOL_FIX_BONUS_LV1 then
                    local symbolNode = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
                    symbolNode:runAnim("actionframe")
                end
            end
        end
    ]]
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolNode = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
            if symbolNode ~= nil then
                local symbolType = symbolNode.p_symbolType
                if symbolType == self.SYMBOL_FIX_BONUS_LV1 then
                    symbolNode:runAnim(
                        "actionframe",
                        false,
                        function()
                            if callBack ~= nil then
                                callBack()
                                callBack = nil
                            end
                        end
                    )
                end
            end
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenDazzlingDynastyMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed  then
        if self:checkIsPlayReelDownSound( reelCol ) then
            if self:getGameSpinStage() == QUICK_RUN then
                if reelCol == self.m_iReelColumnNum then
                    gLobalSoundManager:playSound(self.m_reelDownSound)
                end
            else
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        if self.m_machineIndex == 1 and reelCol <= self.m_iCurrReelCol then
            if self:getGameSpinStage() == QUICK_RUN then
                if reelCol == self.m_iReelColumnNum then
                    gLobalSoundManager:playSound(self.m_reelDownSound)
                end
            else
                gLobalSoundManager:playSound(self.m_reelDownSound)
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

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    self:__checkPlayDownBonusNodeAnim(reelCol)
end

function CodeGameScreenDazzlingDynastyMachine:playCollectWildAnimation(hasWild, symbolNode, callBack)
    local curSpinMode = self:getCurrSpinMode()
    -- local diamondPosX, diamondPosY = self.m_diamondUI:getParent():getPosition()
    local rootParent = self.m_root:getParent()
    local diamondPos = self.m_diamondUI:getParent():convertToWorldSpace(cc.p(self.m_diamondUI:getPosition()))
    local pos = rootParent:convertToNodeSpace(cc.p(diamondPos.x, diamondPos.y))

    if curSpinMode == NORMAL_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
        local symbolType = nil
        if symbolNode then
            symbolType = symbolNode.p_symbolType
        end
        if symbolType and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            hasWild = true
            local flyDiamond = display.newSprite("#Common/DazzlingDynasty_Diamond2.png")
            flyDiamond:setScale(0.5)
            rootParent:addChild(flyDiamond, REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
            flyDiamond:setPosition(symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition())))
            flyDiamond:runAction(
                cc.Spawn:create(
                    cc.ScaleTo:create(0.5, 0.25),
                    cc.Sequence:create(
                        cc.MoveTo:create(0.5, cc.p(pos.x, pos.y)),
                        cc.CallFunc:create(
                            function(sender)
                                if callBack ~= nil then
                                    callBack()
                                end
                                sender:removeFromParent()
                            end
                        )
                    )
                )
            )
        end
    end
    return hasWild
end

function CodeGameScreenDazzlingDynastyMachine:playCollectFreeSpinScoreAnimation(animCor, rowIndex, colIndex, hasBonus, symbolNode, animCount)
    local curSpinMode = self:getCurrSpinMode()
    local rootParent = self.m_root:getParent()

    local goldPos = self.goldMidTopUI:getParent():convertToWorldSpace(cc.p(self.goldMidTopUI:getPosition()))
    local pos = rootParent:convertToNodeSpace(cc.p(goldPos.x, goldPos.y))

    local totalBet = globalData.slotRunData:getCurTotalBet()

    if curSpinMode == FREE_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
        local symbolType = symbolNode.p_symbolType
        if symbolType == self.SYMBOL_FIX_BONUS_LV2 then
            hasBonus = true
            animCount = animCount + 1
            local _, score = self:getScoreInfoByPos(rowIndex, colIndex)
            if not score then
                --先上有几个报错不知道为啥
                score = 1
            end
            -- 初始化 auto spin 触发的粒子效果
            local collectEffect = cc.ParticleSystemQuad:create("Effect/tx_lizi_shouji_mini.plist")
            rootParent:addChild(collectEffect, REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
            collectEffect:setScale(1.5)
            collectEffect:setPosition(symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition())))
            collectEffect:runAction(
                cc.Sequence:create(
                    cc.MoveTo:create(0.3, cc.p(pos.x, pos.y)),
                    cc.CallFunc:create(
                        function(sender)
                            sender:removeFromParent()
                            self:__addFreeSpinScore(totalBet / 60 * score)
                            performWithDelay(
                                self,
                                function()
                                    util_resumeCoroutine(animCor)
                                end,
                                0.5
                            )
                        end
                    )
                )
            )
        end
    end
    return hasBonus, animCount
end

function CodeGameScreenDazzlingDynastyMachine:__handleNormalSpinSlotReelDown(effectData)
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode == NORMAL_SPIN_MODE or curSpinMode == FREE_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
        local animCor = nil
        local diamondUI = self.m_diamondUI
        animCor =
            coroutine.create(
            function()
                local reelRow = self.m_iReelRowNum
                local reelColumn = self.m_iReelColumnNum
                local animCount = 0
                local hasWild = false
                local hasBonus = false
                for i = 1, reelColumn do
                    for j = reelRow, 1, -1 do
                        local symbolNode = self:getFixSymbol(i, j, SYMBOL_NODE_TAG)
                        --播放wild收集动画
                        hasWild =
                            self:playCollectWildAnimation(
                            hasWild,
                            symbolNode,
                            function()
                                if self.hasWildAnimation then
                                    self.hasWildAnimation = nil
                                    diamondUI:runCsbAction(
                                        "actionframe",
                                        false,
                                        function()
                                            diamondUI:runCsbAction("idle", true)
                                        end
                                    )
                                end
                            end
                        )
                        --播放freeSpin收集小块动画
                        hasBonus, animCount = self:playCollectFreeSpinScoreAnimation(animCor, j, i, hasBonus, symbolNode, animCount)
                    end
                end
                self.hasWildAnimation = hasWild
                if hasWild then
                    performWithDelay(
                        self,
                        function()
                            if self.triggerSmallGameFlag then
                                self:__returnToNormalSpinMode()
                                self:showBonusGame(
                                    function(extraData)
                                        self:playChangeEffect(
                                            function()
                                                self:__closeBonusGame()
                                                self:__checkTriggerOtherGame(extraData)
                                            end,
                                            nil
                                        )
                                    end
                                )
                            end
                        end,
                        2
                    )
                end
                if hasWild or hasBonus then
                    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Collect_Wild.mp3")
                end
                for i = 1, animCount do
                    coroutine.yield()
                end
                self:__handleCheckFreeBonusLv2Count(animCor)
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
        util_resumeCoroutine(animCor)
    end
end

function CodeGameScreenDazzlingDynastyMachine:calculateLastWinCoin()
    BaseSlotoManiaMachine.calculateLastWinCoin(self)
    --最后一次赢得中bonus
    local lastFreeSpinScore = 0
    local totalBet = globalData.slotRunData:getCurTotalBet()
    for i = 1, self.m_iReelRowNum do
        for j = self.m_iReelColumnNum, 1, -1 do
            local flag, score = self:getScoreInfoByPos(i, j)
            if flag then
                lastFreeSpinScore = lastFreeSpinScore + totalBet / 60 * score
            end
        end
    end
    local curSpinMode = self:getCurrSpinMode()
    --getFreeSpinScore动画统计的分数+最后一次网络发来的数据才是真实的数据
    local freeSpinScore = self:getFreeSpinScore() + lastFreeSpinScore
    local winCount = self.m_iOnceSpinLastWin
    if globalData.slotRunData.freeSpinCount == 0 and curSpinMode == FREE_SPIN_MODE and freeSpinScore > 0 then
        local disScore = self.m_iOnceSpinLastWin - freeSpinScore
        if disScore > 0 then
            winCount = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - freeSpinScore
            self.m_iOnceSpinLastWin = disScore
            self.isSubFreeSpinScore = true
        end
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenDazzlingDynastyMachine:levelFreeSpinEffectChange()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData ~= nil then
        local collectBonusMultiples = fsExtraData.collectBonusMultiples or 0
        local totalBet = globalData.slotRunData:getCurTotalBet()
        self:__setFreeSpinScore(collectBonusMultiples / 60 * totalBet, false)
    else
        self:__setFreeSpinScore(0, false)
    end
    if self.changeEffect == nil then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
        self.freeSpinTopUI:updateScore()
        self:changeTopUIState()
    end
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenDazzlingDynastyMachine:levelFreeSpinOverChangeEffect()
    self:__setFreeSpinScore(0, false)
end
---------------------------------------------------------------------------

function CodeGameScreenDazzlingDynastyMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
end

function CodeGameScreenDazzlingDynastyMachine:__showFreeSpinMoreUI(animCor)
    -- gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_custom_enter_fs.mp3")
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinMore(
            self.m_runSpinResultData.p_freeSpinNewCount,
            function()
                self.bonusFreeSpinBar:playCollectEffect()
                self:changeReSpinUpdateUI(globalData.slotRunData.freeSpinCount)
                util_resumeCoroutine(animCor)
            end,
            true
        )
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        coroutine.yield()
    end
end

-- 触发freespin结束时调用
function CodeGameScreenDazzlingDynastyMachine:showFreeSpinOverView()
    local freeSpinScore = self:getFreeSpinScore()
    local function callBack()
        local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
        local view =
            self:showFreeSpinOver(
            strCoins,
            self.m_runSpinResultData.p_freeSpinsTotalCount,
            function()
                -- 调用此函数才是把当前游戏置为freespin结束状态
                self:playChangeEffect(
                    function()
                        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
                        self:triggerFreeSpinOverCallFun()
                        self:changeTopUIState()
                    end,
                    nil
                )
            end
        )
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
        gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_freeSpin_Over.mp3")
    end
    if freeSpinScore > 0 then
        self:__flyBottomEffect(callBack, globalData.slotRunData.lastWinCoin, freeSpinScore)
    else
        callBack()
    end
end

function CodeGameScreenDazzlingDynastyMachine:showEffect_newFreeSpinOver()
    local freeSpinScore = self:getFreeSpinScore()
    if self.isSubFreeSpinScore then
        globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + freeSpinScore
        self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin + freeSpinScore
        self.isSubFreeSpinScore = nil
    end
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
    self:clearCurMusicBg()
    self:showFreeSpinOverView()
end

function CodeGameScreenDazzlingDynastyMachine:__flyBottomEffect(callBack, score, freeSpinScore)
    local curSpinMode = self:getCurrSpinMode()
    local rootParent = self.m_root:getParent()
    if score > 0 then
        local m_bottomUI = self.m_bottomUI
        local coinWinNode = m_bottomUI:getCoinWinNode()
        if coinWinNode ~= nil then
            local goldPos = self.goldMidTopUI:getParent():convertToWorldSpace(cc.p(self.goldMidTopUI:getPosition()))
            local pos = rootParent:convertToNodeSpace(cc.p(goldPos.x, goldPos.y))
            local effectLabel, effectLabelAct = util_csbCreate("DazzlingDynasty_coins_0.csb", true)
            util_csbPauseForIndex(effectLabelAct, 0)
            rootParent:addChild(effectLabel, REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
            local function getScoreLabel(node)
                local name = node:getName()
                if name == "m_lb_score" then
                    return node
                else
                    for k, v in ipairs(node:getChildren()) do
                        local n = getScoreLabel(v)
                        if n ~= nil then
                            return n
                        end
                    end
                end
            end
            local lbEffectScore = getScoreLabel(effectLabel)
            lbEffectScore:setString(util_formatCoins(score, 4))
            if freeSpinScore then
                lbEffectScore:setString(util_formatCoins(freeSpinScore, 4))
            else
                lbEffectScore:setString(util_formatCoins(score, 4))
            end
            -- collectEffect:setScale(1.5)
            effectLabel:setPosition(goldPos.x, goldPos.y)
            effectLabel:runAction(
                cc.Sequence:create(
                    cc.MoveTo:create(0.7, cc.p(coinWinNode:convertToWorldSpace(cc.p(0, 0)))),
                    cc.CallFunc:create(
                        function(sender)
                            sender:removeFromParent()
                            m_bottomUI:updateWinCount(util_getFromatMoneyStr(score))
                            self:playCoinWinEffectUI(
                                function()
                                    performWithDelay(self, callBack, 1)
                                end
                            )
                        end
                    )
                )
            )
        else
            m_bottomUI:updateWinCount(util_getFromatMoneyStr(score))
            performWithDelay(self, callBack, 1)
        end
        gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_goldDown.mp3")
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

--结束移除小块调用结算特效
function CodeGameScreenDazzlingDynastyMachine:reSpinEndAction()
    self:clearCurMusicBg()
    local midTopScore = self.goldMidTopUI:getScore()
    if midTopScore > 0 then
        performWithDelay(
            self,
            function()
                self:__flyBottomEffect(
                    function()
                        performWithDelay(self, handler(self, self.respinOver), 0.5)
                    end,
                    globalData.slotRunData.lastWinCoin
                )
            end,
            1
        )
    else
        self:respinOver()
    end
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenDazzlingDynastyMachine:getRespinRandomTypes()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2
    }

    --symbolList = nil -- 填写好后这行代码可以删除，只是为了报错提示修改

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenDazzlingDynastyMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_BONUS_LV1, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_FIX_BONUS_LV2, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_FIX_BONUS_LV3, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_FIX_BONUS_ADDSPIN_LV2, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_FIX_BONUS_ADDSPIN_LV3, runEndAnimaName = "", bRandom = false}
    }

    --symbolList = nil -- 填写好后这行代码可以删除，只是为了报错提示修改

    return symbolList
end

function CodeGameScreenDazzlingDynastyMachine:showEffect_Bonus(effectData)
    local runSpinResultData = self.m_runSpinResultData
    local selfMakeData = runSpinResultData.p_selfMakeData
    local freeSpinData = selfMakeData.triggerTimes_FREESPIN
    local respinData = selfMakeData.triggerTimes_RESPIN
    if selfMakeData and freeSpinData then
        if freeSpinData ~= nil then
            self.m_iFreeSpinTimes = freeSpinData.times
            self:changeReSpinUpdateUI(self.m_iFreeSpinTimes)
        end
        if self.m_bProduceSlots_InFreeSpin == false and respinData ~= nil then
            self.m_iRespinTimes = respinData.times
        end
    end
    return BaseSlotoManiaMachine.showEffect_Bonus(self, effectData)
end

function CodeGameScreenDazzlingDynastyMachine:__getBonusGameType(featureBonus)
    local bonusExtraData = self.m_runSpinResultData.p_bonusExtra
    local bonuses = featureBonus or bonusExtraData.bonuses
    local gameType = nil
    for k, v in ipairs(bonuses) do
        gameType = v
        if v == "pickBonus" then
            break
        end
    end
    return gameType
end

function CodeGameScreenDazzlingDynastyMachine:__closeBonusPopUpUI()
    if self.bonusPopUpUI ~= nil and self.bonusPopUpUI.close ~= nil then
        self.bonusPopUpUI:close()
        self.bonusPopUpUI = nil
    end
end

function CodeGameScreenDazzlingDynastyMachine:showBonusGameView(effectData)
    if effectData.p_effectType == GameEffect.EFFECT_BONUS then
        local gameType = self:__getBonusGameType(effectData.featureBonus)
        if gameType == "selectBonus" then
            local function createBonusUI()
                local bonusPopUpUI = util_createView("GameScreenDazzlingDynasty.CodeDazzlingDynastySrc.DazzlingDynastyBonusPopUpUI")
                self.bonusPopUpUI = bonusPopUpUI
                bonusPopUpUI:setExtraInfo(
                    self,
                    function(index)
                        self:sendSelectBonus(index)
                        self.m_bIsSelectCall = true
                        self.m_iSelectID = index
                        self.m_gameEffect = effectData
                    end
                )
                gLobalViewManager:showUI(bonusPopUpUI)
                gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_bonusSelect.mp3")
            end
            util_performWithDelay(
                self,
                function()
                    self:__playTriggerBonusNodeAnim(
                        function()
                            util_performWithDelay(self, createBonusUI, 1)
                        end
                    )
                end,
                0.5
            )

            self.freeSpinTopUI:updateScore()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
            gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Trigger_RespinBonus.mp3")
        elseif gameType == "pickBonus" then
            self.m_gameEffect = effectData
            if not self.triggerSmallGameFlag then
                if self.hasWildAnimation then
                    self.triggerSmallGameFlag = true
                else
                    self:__returnToNormalSpinMode()
                    self:showBonusGame(
                        function(extraData)
                            self:playChangeEffect(
                                function()
                                    self:__closeBonusGame()
                                    self:__checkTriggerOtherGame(extraData)
                                end,
                                nil
                            )
                        end
                    )
                end
            end
        end
    end
end

function CodeGameScreenDazzlingDynastyMachine:showBonusGame(func)
    self.triggerSmallGameFlag = false
    self.isInBonus = true
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    local diamondUI = self.m_diamondUI
    if not self.hasWildAnimation then
        diamondUI:runCsbAction("actionframe")
    end
    performWithDelay(
        self,
        function()
            if not self.hasWildAnimation then
                diamondUI:runCsbAction(
                    "actionframe",
                    false,
                    function()
                        diamondUI:runCsbAction("idle", true)
                        local bonusGame = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyBonusGame")
                        self.bonusGame = bonusGame
                        bonusGame:initViewData(self, func)
                        gLobalViewManager:showUI(bonusGame)
                        bonusGame:setVisible(false)
                        self:playBonusChangeEffect(
                            function()
                                bonusGame:setVisible(true)
                                gLobalSoundManager:playBgMusic("DazzlingDynastySounds/music_DazzlingDynasty_SmallGameBg.mp3")
                            end,
                            nil
                        )
                    end
                )
            else
                diamondUI:runCsbAction(
                    "actionframe",
                    false,
                    function()
                        diamondUI:runCsbAction(
                            "actionframe",
                            false,
                            function()
                                diamondUI:runCsbAction("idle", true)
                                local bonusGame = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyBonusGame")
                                self.bonusGame = bonusGame
                                bonusGame:initViewData(self, func)
                                gLobalViewManager:showUI(bonusGame)
                                bonusGame:setVisible(false)
                                self:playChangeEffect(
                                    function()
                                        bonusGame:setVisible(true)
                                        gLobalSoundManager:playBgMusic("DazzlingDynastySounds/music_DazzlingDynasty_SmallGameBg.mp3")
                                    end,
                                    nil
                                )
                            end
                        )
                    end
                )
            end
        end,
        24 / 30
    )
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Trigger_SmallGame.mp3")
end

function CodeGameScreenDazzlingDynastyMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    local initSpinData = self.m_initSpinData
    local initFeatureData = self.m_initFeatureData
    local triggerFlag = false
    if initFeatureData ~= nil then
        local initFeatureDataIn = initFeatureData.p_data
        triggerFlag = initFeatureDataIn ~= nil and initFeatureDataIn.respin ~= nil and initFeatureDataIn.respin.reSpinCurCount > 0 and initFeatureDataIn.respin.reSpinsTotalCount > 0
        if triggerFlag then
            initSpinData.p_reSpinsTotalCount = initFeatureDataIn.respin.reSpinsTotalCount
            initSpinData.p_reSpinCurCount = initFeatureDataIn.respin.reSpinCurCount
        end
    elseif initSpinData ~= nil then
        triggerFlag = initSpinData.p_reSpinsTotalCount ~= nil and initSpinData.p_reSpinsTotalCount > 0 and initSpinData.p_reSpinCurCount > 0
    end
    if triggerFlag then
        --手动添加freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        local reSpinEffect = GameEffectData.new()
        reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
        reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

        self.m_isRunningEffect = true

        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenDazzlingDynastyMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    local isInFs = false
    local initSpinData = self.m_initSpinData
    local initFeatureData = self.m_initFeatureData
    if not hasFreepinFeature then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        if initFeatureData ~= nil then
            local initFeatureDataIn = initFeatureData.p_data
            if (initFeatureDataIn ~= nil and initFeatureDataIn.freespin ~= nil and initFeatureDataIn.freespin.freeSpinsLeftCount > 0 and initFeatureDataIn.freespin.freeSpinsTotalCount > 0) then
                isInFs = true
                self.m_runSpinResultData.p_freeSpinsLeftCount = initFeatureDataIn.freespin.freeSpinsLeftCount
                self.m_runSpinResultData.p_freeSpinsTotalCount = initFeatureDataIn.freespin.freeSpinsTotalCount
            end
        elseif (initSpinData.p_freeSpinsTotalCount ~= nil and initSpinData.p_freeSpinsTotalCount > 0 and initSpinData.p_freeSpinsLeftCount > 0) then
            isInFs = true
        end
    end

    if isInFs == true then
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:changeReSpinUpdateUI(globalData.slotRunData.freeSpinCount)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        self:setCurrSpinMode(FREE_SPIN_MODE)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenDazzlingDynastyMachine:initFeatureInfo(spinData, featureData)
    local bonus = featureData.p_bonus
    if bonus ~= nil and bonus.extra then
        local bonusExtra = bonus.extra
        local pickTimes = bonusExtra.pickTimes
        if pickTimes ~= nil and pickTimes > 0 then
            local bonusGame = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyBonusGame")
            self.bonusGame = bonusGame
            self.isInBonus = true
            bonusGame:resetView(
                self,
                bonusExtra,
                function(extraData)
                    self:playChangeEffect(
                        function()
                            self:__closeBonusGame()
                            self:__checkTriggerOtherGame(extraData)
                        end,
                        nil
                    )
                end
            )
            gLobalSoundManager:playBgMusic("DazzlingDynastySounds/music_DazzlingDynasty_SmallGameBg.mp3")
            gLobalViewManager:showUI(bonusGame)
        else
            local bonus = bonusExtra.bonuses
            if bonus ~= nil and #bonus > 0 then
                local bonusGameEffect = GameEffectData.new()
                bonusGameEffect.featureBonus = bonus
                bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
                bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
                self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
                if bonus[1] ~= "selectBonus" then
                    self:__returnToNormalSpinMode()
                end
                --bugly 这个地方会和OnEnter()内重复调用，导致一个事件播两次
                -- self:playGameEffect()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
            end
        end
    end
end

function CodeGameScreenDazzlingDynastyMachine:__closeBonusGame()
    if self.bonusGame ~= nil then
        self.bonusGame:close()
        self.bonusGame = nil
        self.isInBonus = nil
    end
end

function CodeGameScreenDazzlingDynastyMachine:__returnToNormalSpinMode()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        if self.m_handerIdAutoSpin ~= nil then
            scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
            self.m_handerIdAutoSpin = nil
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
end

function CodeGameScreenDazzlingDynastyMachine:__checkTriggerOtherGame(extraData)
    local bonus = extraData.bonuses
    if bonus ~= nil and #bonus > 0 then
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.featureBonus = bonus
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
        if bonus[1] ~= "selectBonus" then
            self:__returnToNormalSpinMode()
        end
    end
    if self.m_gameEffect then
        self.m_gameEffect.p_isPlay = true
    end
    self:playGameEffect()
end

function CodeGameScreenDazzlingDynastyMachine:playChangeEffect(callBack, endCallBack)
    local changeEffect = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyChangeEffect")
    self.changeEffect = changeEffect
    changeEffect:setExtraInfo(self)
    changeEffect:setPosition(display.width / 2, display.height / 2)
    local function lEndCalLBack()
        gLobalSoundManager:resumeBgMusic()
        self:resetMusicBg()
        if endCallBack ~= nil then
            endCallBack()
        end
    end
    changeEffect:play(callBack, lEndCalLBack)
    gLobalViewManager:showUI(changeEffect)
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_ChangeBg.mp3")
    gLobalSoundManager:pauseBgMusic()
end
--触发bonus过场动画单独处理
function CodeGameScreenDazzlingDynastyMachine:playBonusChangeEffect(callBack, endCallBack)
    local changeEffect = util_createView("CodeDazzlingDynastySrc.DazzlingDynastyChangeEffect")
    self.changeEffect = changeEffect
    changeEffect:setExtraInfo(self)

    local function lEndCalLBack()
        gLobalSoundManager:resumeBgMusic()
        self:resetMusicBg()
        if endCallBack ~= nil then
            endCallBack()
        end
    end
    local diamondPos = cc.p(self.m_diamondUI:getPosition())
    local wordPos = self.m_diamondUI:getParent():convertToWorldSpace(diamondPos)
    local pos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(wordPos.x, wordPos.y))
    changeEffect:setPosition(pos.x, pos.y)
    gLobalViewManager:showUI(changeEffect)
    changeEffect:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.5, cc.p(display.width / 2, display.height / 2)),
            cc.CallFunc:create(
                function(sender)
                    sender:play(callBack, lEndCalLBack)
                end
            )
        )
    )
    -- changeEffect:setPosition(display.width / 2, display.height / 2)
    -- changeEffect:play(callBack, lEndCalLBack)

    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_ChangeBg.mp3")
    gLobalSoundManager:pauseBgMusic()
end

function CodeGameScreenDazzlingDynastyMachine:spinResultCallFun(param)
    BaseSlotoManiaMachine.spinResultCallFun(self, param)
    if self.m_bIsSelectCall then
        local m_iSelectID = self.m_iSelectID
        self:__returnToNormalSpinMode()
        if m_iSelectID == 1 then
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
            self:playChangeEffect(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "respin")
                    self:__closeBonusPopUpUI()
                    self:playGameEffect()
                end,
                nil
            )
        else
            globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
            globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes
            self:playChangeEffect(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
                    self:__closeBonusPopUpUI()
                    self:playGameEffect()
                    self:changeTopUIState()
                end,
                nil
            )
            self:triggerFreeSpinCallFun()
            if self.m_gameEffect then
                self.m_gameEffect.p_isPlay = true
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end
    end
    self.m_bIsSelectCall = false
end

function CodeGameScreenDazzlingDynastyMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    local curSpinMode = self:getCurrSpinMode()
    if self.m_bQuestComplete and curSpinMode ~= RESPIN_MODE and curSpinMode ~= FREE_SPIN_MODE then
        if curSpinMode == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end
    if curSpinMode == AUTO_SPIN_MODE or curSpinMode == FREE_SPIN_MODE then
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
    elseif curSpinMode == RESPIN_MODE then
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
        self:showRespinView()
    end
end

function CodeGameScreenDazzlingDynastyMachine:changeTopUIState()
    local spinMode = self:getCurrSpinMode()
    --正常模式
    if spinMode == NORMAL_SPIN_MODE then
        --respin
        self.m_jackPotBar:setVisible(true)
        self.diamondCoins:setVisible(true)
        self.bonusTopUI:setVisible(false)
        self.freeSpinTopUI:setVisible(false)
        self.goldMidTopUI:setVisible(false)
        self.bonusFreeSpinBar:setVisible(false)
    elseif spinMode == RESPIN_MODE then
        --freespin
        self.m_jackPotBar:setVisible(false)
        self.diamondCoins:setVisible(false)
        self.bonusTopUI:setVisible(true)
        self.freeSpinTopUI:setVisible(false)
        self.goldMidTopUI:setVisible(true)
        self.bonusFreeSpinBar:setVisible(true)
    elseif spinMode == FREE_SPIN_MODE then
        self.m_jackPotBar:setVisible(false)
        self.diamondCoins:setVisible(false)
        self.bonusTopUI:setVisible(false)
        self.freeSpinTopUI:setVisible(true)
        self.goldMidTopUI:setVisible(true)
        self.bonusFreeSpinBar:setVisible(true)
    end
end

function CodeGameScreenDazzlingDynastyMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    if self.changeEffect == nil then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "respin")
    end
    if func then
        func()
    end
    -- scheduler.performWithDelayGlobal(func, 1.2, self:getModuleName())
end

function CodeGameScreenDazzlingDynastyMachine:showRespinView(effectData)
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode ~= RESPIN_MODE then
        --先播放动画 再进入respin
        self:clearCurMusicBg()

        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes()

        --可随机的特殊信号
        local endTypes = self:getRespinLockTypes()

        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)
    end
end

function CodeGameScreenDazzlingDynastyMachine:reSpinReelDown(addNode)
    self.m_respinView:handleTriggerResult(
        function()
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                local isAddEffect = false
                for i = 1, #self.m_gameEffects do
                    local effectData = self.m_gameEffects[i]
                    if effectData.p_effectType == GameEffect.EFFECT_RESPIN then
                        isAddEffect = true
                        break
                    end
                end
                if isAddEffect == false then
                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    self.m_gameEffects[#self.m_gameEffects + 1] = delayEffect
                end
            end

            BaseSlotoManiaMachine.reSpinReelDown(self, addNode)
        end
    )
end

function CodeGameScreenDazzlingDynastyMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:showRespinOverView()
end

--播放respin放回滚轴后播放的提示动画
function CodeGameScreenDazzlingDynastyMachine:checkRespinChangeOverTip(node, endAnimaName, loop)
    node:runAnim("idleframe", false)
    if not self:isBonusSymbol(node.p_symbolType) and node.p_symbolType ~= self.SYMBOL_FIX_BONUS_ADDSPIN then
        local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
        if imageName ~= nil then
            local name = imageName[1]
            node:spriteChangeImage(node.p_symbolImage, name)
            if node.p_symbolImage then
                if imageName[4] then
                    node.p_symbolImage:setScale(imageName[4])
                end
            end
        end
    end
end

--触发respin
function CodeGameScreenDazzlingDynastyMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true
    self:changeTopUIState()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()

    local respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView = respinView
    respinView:setExtraInfo(self)
    respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenDazzlingDynastyMachine:initRespinView(endTypes, randomTypes)
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
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    self:runNextReSpinReel()
                end
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--ReSpin开始改变UI状态
function CodeGameScreenDazzlingDynastyMachine:changeReSpinStartUI(respinCount)
end

--ReSpin刷新数量
function CodeGameScreenDazzlingDynastyMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.bonusFreeSpinBar:setCount(curCount)
end

function CodeGameScreenDazzlingDynastyMachine:checkChangeFsCount()
    BaseSlotoManiaMachine.checkChangeFsCount(self)
    self:changeReSpinUpdateUI(globalData.slotRunData.freeSpinCount)
end

function CodeGameScreenDazzlingDynastyMachine:showRespinOverView(effectData)
    local midTopScore = self.goldMidTopUI:getScore()
    local strCoins = util_formatCoins(midTopScore, 11)
    local view =
        self:showReSpinOver(
        strCoins,
        function()
            self:playChangeEffect(
                function()
                    self:resetReSpinMode()
                    self:setReelSlotsNodeVisible(true)
                    self:changeTopUIState()
                    self:removeRespinNode()
                    self:playBonusAnim()
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
                end,
                function()
                    self:updateQuestDone()
                    self:triggerReSpinOverCallFun(midTopScore)
                end
            )
        end
    )
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_Respin_Result.mp3")
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
end

function CodeGameScreenDazzlingDynastyMachine:playBonusAnim()
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolNode = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
            if symbolNode and (symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS_LV1 or symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS_LV2 or symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS_LV3) then
                symbolNode:runAnim("actionframe1", true)
            end
        end
    end
end
--刷新quest 任务
function CodeGameScreenDazzlingDynastyMachine:updateQuestDone()
    --TODO  后续考虑优化修改 , 检测是否有quest effect ， 将其位置信息放到quest 前面
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == true then
        self:removeGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    end
    local questEffect = GameEffectData:create()
    questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
    questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
    self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
end

-- --重写组织respinData信息
function CodeGameScreenDazzlingDynastyMachine:getRespinSpinData()
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

function CodeGameScreenDazzlingDynastyMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow + iCol + self:formatAddSpinSymbol(symbolType)
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

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenDazzlingDynastyMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenDazzlingDynastyMachine:enterLevel()
    self:checkUpateDefaultBet()

    BaseSlotoManiaMachine.enterLevel(self)
end
function CodeGameScreenDazzlingDynastyMachine:initHasFeature()
    -- self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self:initCloumnSlotNodesByNetData()
end

function CodeGameScreenDazzlingDynastyMachine:initNoneFeature()
    if globalData.GameConfig:checkSelectBet() then
        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questConfig and questConfig.m_IsQuestLogin then
            --quest进入也使用服务器bet
        else
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest()then
                --quest进入也使用服务器bet
            else
                self.m_initBetId = -1
            end
        end
    end
    -- self:checkUpateDefaultBet()
    -- 直接使用 关卡bet 选择界面的bet 来使用
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    self:initRandomSlotNodes()
end

function CodeGameScreenDazzlingDynastyMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            if not self.isInBonus then
                gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_collect_EnterLevel.mp3")
            end
            scheduler.performWithDelayGlobal(
                function()
                    if not self.isInBonus then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
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

function CodeGameScreenDazzlingDynastyMachine:resetMusicBg(isMustPlayMusic)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self.isInBonus then
        return
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

function CodeGameScreenDazzlingDynastyMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenDazzlingDynastyMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
end

function CodeGameScreenDazzlingDynastyMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

-- ------------玩法处理 --

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenDazzlingDynastyMachine:MachineRule_network_InterveneSymbolMap()
end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenDazzlingDynastyMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenDazzlingDynastyMachine:addSelfEffect()
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode == NORMAL_SPIN_MODE or curSpinMode == FREE_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SELF_PLAYFLYBONUS -- 动画类型
    else
        self:checkTriggerOrInSpecialGame(
            function()
                self:reelsDownDelaySetMusicBGVolume()
            end
        )
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenDazzlingDynastyMachine:MachineRule_playSelfEffect(effectData)
    --收集wild和bonus信号
    if effectData.p_selfEffectType == self.EFFECT_SELF_PLAYFLYBONUS then
        self:__handleNormalSpinSlotReelDown(effectData)
    end
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenDazzlingDynastyMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenDazzlingDynastyMachine:MachineRule_InterveneReelList()
    local curSpinMode = self:getCurrSpinMode()
    --self.m_reelRunInfo 中存放轮盘滚动信息
    if curSpinMode == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    end
end

--------------------------------------------发送网络消息---------------------------------------
function CodeGameScreenDazzlingDynastyMachine:sendSelectBonus(index)
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end
--------------------------------------------发送网络消息---------------------------------------

function CodeGameScreenDazzlingDynastyMachine:playEffectNotifyChangeSpinStatus()
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
            if self.m_chooseRepinGame then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                self.m_chooseRepinGame = false
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
        end
    end
end

return CodeGameScreenDazzlingDynastyMachine
