---
-- island li
-- 2019年1月26日
-- CodeGameScreenPomiMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = require "Levels.BaseMachine"

local CodeGameScreenPomiMachine = class("CodeGameScreenPomiMachine", BaseSlotoManiaMachine)

CodeGameScreenPomiMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenPomiMachine.m_respinLittleNodeSize = 2

CodeGameScreenPomiMachine.SYMBOL_FIX_Reel_Up = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 16
CodeGameScreenPomiMachine.SYMBOL_FIX_Double_bet = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14

CodeGameScreenPomiMachine.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
CodeGameScreenPomiMachine.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenPomiMachine.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenPomiMachine.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

CodeGameScreenPomiMachine.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE

CodeGameScreenPomiMachine.m_betLevel = nil -- betlevel 0 1 2

CodeGameScreenPomiMachine.m_respinEffectList = {}
CodeGameScreenPomiMachine.m_runNextRespinFunc = nil
CodeGameScreenPomiMachine.m_respinReelsShowRow = 3

CodeGameScreenPomiMachine.m_chipList = nil
CodeGameScreenPomiMachine.m_playAnimIndex = 0
CodeGameScreenPomiMachine.m_lightScore = 0

local FIT_HEIGHT_MAX = 1281
local FIT_HEIGHT_MIN = 1136

local RESPIN_ROW_COUNT = 6
local NORMAL_ROW_COUNT = 3

-- 构造函数
function CodeGameScreenPomiMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_betLevel = nil
    self.isInBonus = false
    self.m_bIsRespinOver = false
    self.m_bRespinNodeAnimation = false

    self.m_jackpot_status = "Normal"
    self.m_isJackpotEnd = false
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenPomiMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("PomiConfig.csv", "LevelPomiConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

--绘制多个裁切区域
function CodeGameScreenPomiMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
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

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
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
        self.m_slotEffectLayer:setOpacity(255)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(255)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)

        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")
    end
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenPomiMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        if i < 2 then
            soundPath = "PomiSounds/music_Pomi_Scatter_Down_1.mp3"
        elseif i == 2 then
            soundPath = "PomiSounds/music_Pomi_Scatter_Down_2.mp3"
        else
            soundPath = "PomiSounds/music_Pomi_Scatter_Down_3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenPomiMachine:changeViewNodePos()
    for i = 1, self.m_iReelColumnNum do
        local pos = i - 1

        self:findChild("reel_bg_" .. pos):setContentSize(128, 348)
    end

    if display.height >= FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5

        self:findChild("Pomi_reel_lines_2"):setPositionY(self:findChild("Pomi_reel_lines_2"):getPositionY() - posY)
        self:findChild("Pomi_reel_lines_1"):setPositionY(self:findChild("Pomi_reel_lines_1"):getPositionY() - posY)

        for i = 1, self.m_iReelColumnNum do
            local pos = i - 1
            self:findChild("sp_reel_" .. pos):setPositionY(self:findChild("sp_reel_" .. pos):getPositionY() - posY)
            self:findChild("reel_bg_" .. pos):setPositionY(self:findChild("reel_bg_" .. pos):getPositionY() - posY)
        end

        self:findChild("freespinbar"):setPositionY(self:findChild("freespinbar"):getPositionY() - posY)
        self:findChild("respinbar"):setPositionY(self:findChild("respinbar"):getPositionY() - posY)
        self:findChild("respinLines"):setPositionY(self:findChild("respinLines"):getPositionY() - posY)
        self:findChild("Panel_2"):setPositionY(self:findChild("Panel_2"):getPositionY() - posY)

        self:findChild("bgChangeAct"):setPositionY(self:findChild("bgChangeAct"):getPositionY() - posY)

        local nodeJackpot = self:findChild("Jackpot")

        if (display.height / display.width) >= 2 then
            nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY - 130)
        else
            nodeJackpot:setPositionY(nodeJackpot:getPositionY() + posY - 110)
        end
    elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
        local nodeJackpot = self:findChild("Jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - 30)
    else
        local nodeJackpot = self:findChild("Jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - 30)
    end

    if globalData.slotRunData.isPortrait then
        local bangHeight = util_getBangScreenHeight()
        local nodeJackpot = self:findChild("Jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - bangHeight)

        local bangDownHeight = util_getSaveAreaBottomHeight()
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - bangDownHeight)
    end
end

function CodeGameScreenPomiMachine:scaleMainLayer()
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
            mainScale = (FIT_HEIGHT_MAX + 120 - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            -- mainScale = mainScale + 0.05
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            if (display.height / display.width) >= 2 then
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 58)
            else
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 58)
            end
        elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height + 48 - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 29)
        else
            mainScale = (display.height + 45 - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 31)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    self.m_respinBarPosY = self:findChild("respinbar"):getPositionY()

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
end

function CodeGameScreenPomiMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar

    self:createLocalAnimation()

    -- jackpotbar
    self.m_jackPorBar = util_createView("CodePomiSrc.PomiJackPotBarView")
    self:findChild("Jackpot"):addChild(self.m_jackPorBar)
    self.m_jackPorBar:initMachine(self)

    self.m_PomiFreespinBarView = util_createView("CodePomiSrc.PomiFreespinBarView")
    self:findChild("freespinbar"):addChild(self.m_PomiFreespinBarView)
    self.m_baseFreeSpinBar = self.m_PomiFreespinBarView
    self.m_baseFreeSpinBar:setVisible(false)

    self.m_PomiRespinBarView = util_createView("CodePomiSrc.PomiRespinBarView")
    self:findChild("respinbar"):addChild(self.m_PomiRespinBarView)
    self.m_PomiRespinBarView:initMachine(self)
    self.m_PomiRespinBarView:setVisible(false)

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        self.m_gameBg:runCsbAction("idleframe", true)

        self.m_gameBg:findChild("Pomi_bg1"):setVisible(false)
        self.m_gameBg:findChild("Pomi_bg2"):setVisible(true)
    else
        self.m_gameBg:runCsbAction("animation0", true)
        self.m_gameBg:findChild("Pomi_bg1"):setVisible(true)
        self.m_gameBg:findChild("Pomi_bg2"):setVisible(false)
    end

    -- 过场
    self.m_GuoChangView = util_createView("CodePomiSrc.PomiFireBallArrayView")
    self.m_root:addChild(self.m_GuoChangView, -1)
    self.m_GuoChangView:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_GuoChangView:setVisible(false)

    -- 过场
    self.m_GuoChangView2 = util_createView("CodePomiSrc.PomiFIrMoreBallActionView")
    self:addChild(self.m_GuoChangView2, 99999999)
    self.m_GuoChangView2:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_GuoChangView2:setVisible(false)

    self:findChild("bgChangeAct"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self.m_bgChangeAct = util_createView("CodePomiSrc.PomiBgChangeActView")
    self:findChild("bgChangeAct"):addChild(self.m_bgChangeAct)
    self.m_bgChangeAct:setVisible(false)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin or self.m_bIsRespinOver then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
                soundTime = 3
            end

            local soundName = "PomiSounds/music_Pomi_last_win_" .. soundIndex .. ".mp3"
            local winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

-- 断线重连
function CodeGameScreenPomiMachine:MachineRule_initGame()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPomiMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Pomi"
end

-- 继承底层respinView
function CodeGameScreenPomiMachine:getRespinView()
    return "CodePomiSrc.PomiRespinView"
end
-- 继承底层respinNode
function CodeGameScreenPomiMachine:getRespinNode()
    return "CodePomiSrc.PomiRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPomiMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_FIX_SYMBOL then
        return "Socre_Pomi_Bonus_Num"
    elseif symbolType == self.SYMBOL_FIX_GRAND then
        return "Socre_Pomi_Bonus_Grand"
    elseif symbolType == self.SYMBOL_FIX_MAJOR then
        return "Socre_Pomi_Bonus_Major"
    elseif symbolType == self.SYMBOL_FIX_MINOR then
        return "Socre_Pomi_Bonus_Minor"
    elseif symbolType == self.SYMBOL_FIX_MINI then
        return "Socre_Pomi_Bonus_Mini"
    elseif symbolType == self.SYMBOL_FIX_Reel_Up then
        return "Socre_Pomi_reel_up"
    elseif symbolType == self.SYMBOL_FIX_Double_bet then
        return "Socre_Pomi_DoubleBet"
    end

    return nil
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenPomiMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
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

    if idNode then
        local pos = self:getRowAndColByPos(idNode)
        local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        if symbolType == self.SYMBOL_FIX_MINI then
            score = "MINI"
        elseif symbolType == self.SYMBOL_FIX_MINOR then
            score = "MINOR"
        elseif symbolType == self.SYMBOL_FIX_MAJOR then
            score = "MAJOR"
        elseif symbolType == self.SYMBOL_FIX_GRAND then
            score = "GRAND"
        end

        if type(score) == "number" and score < 0 then
            -- 安全保护
            score = nil
        end
    end

    return score
end

function CodeGameScreenPomiMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

function CodeGameScreenPomiMachine:getSpecialNodeBetNum(iCol, iRow)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local index = self:getPosReelIdx(iRow, iCol)
    local bet = nil
    if rsExtraData then
        local multiple = rsExtraData.multiple

        if multiple then
            for k, v in pairs(multiple) do
                local posIndex = v.position
                if index == posIndex then
                    if v.mult then
                        bet = v.mult

                        return bet
                    end
                end
            end
        end
    end

    return bet
end

-- 给respin小块进行赋值
function CodeGameScreenPomiMachine:setSpecialNodeBet(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if symbolNode and symbolNode.p_symbolType then
        local bet = math.random(1, 3)
        if iCol and iRow then
            bet = self:getSpecialNodeBetNum(iCol, iRow) or math.random(1, 3)
        end

    --    local lab =  symbolNode:getCcbProperty("m_lb_bet")
    --    if lab then
    --         lab:setString("X"..bet)
    --    end
    end
end

function CodeGameScreenPomiMachine:changeFixSocreForDoubleBetGame(posIndex, score)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local backScore = score
    if rsExtraData then
        local multiple = rsExtraData.multiple
        if multiple then
            for k, v in pairs(multiple) do
                local multipleData = v
                local bet = multipleData.mult
                local multPositionList = multipleData.multPosition
                if multPositionList then
                    for kk, netpos in pairs(multPositionList) do
                        if netpos == posIndex then
                            backScore = score / bet
                        end
                    end
                end
            end
        end
    end

    return backScore
end

-- 给respin小块进行赋值
function CodeGameScreenPomiMachine:setSpecialNodeScore(sender, param)
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
        local posIndex = self:getPosReelIdx(iRow, iCol)
        local score = self:getReSpinSymbolScore(posIndex) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            score = score * lineBet
            if score < 0 then
                print("1212121")
            end

            local lb = symbolNode:getCcbProperty("m_lb_score")
            local lb1 = symbolNode:getCcbProperty("m_lb_score1")

            score = self:changeFixSocreForDoubleBetGame(posIndex, score)

            if lb then
                if (score / lineBet) >= 5 then
                    lb:setVisible(false)
                    lb1:setVisible(true)
                else
                    lb:setVisible(true)
                    lb1:setVisible(false)
                end

                score = util_formatCoins(score, 3)

                lb:setString(score)
                lb1:setString(score)
            end
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            if score == nil then
                score = 1
            end

            score = score * lineBet
            local lb = symbolNode:getCcbProperty("m_lb_score")
            local lb1 = symbolNode:getCcbProperty("m_lb_score1")

            if lb then
                if (score / lineBet) >= 5 then
                    lb:setVisible(false)
                    lb1:setVisible(true)
                else
                    lb:setVisible(true)
                    lb1:setVisible(false)
                end

                score = util_formatCoins(score, 3)

                lb:setString(score)
                lb1:setString(score)
            end
        end
    end
end

function CodeGameScreenPomiMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col, isLastSymbol)

    if symbolType == self.SYMBOL_FIX_SYMBOL then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        self:runAction(callFun)
    end

    if symbolType == self.SYMBOL_FIX_Double_bet then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeBet), {reelNode})
        self:runAction(callFun)
    end

    return reelNode
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPomiMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_GRAND, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_MINI, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_Reel_Up, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_Double_bet, count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenPomiMachine:isFixSymbol(symbolType)
    if
        symbolType == self.SYMBOL_FIX_SYMBOL or symbolType == self.SYMBOL_FIX_MINI or symbolType == self.SYMBOL_FIX_MINOR or symbolType == self.SYMBOL_FIX_MAJOR or symbolType == self.SYMBOL_FIX_GRAND or
            symbolType == self.SYMBOL_FIX_Reel_Up or
            symbolType == self.SYMBOL_FIX_Double_bet
     then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenPomiMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
        self:setReelDownSoundId(reelCol, self.m_reelDownSoundPlayed)
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:setVisible(false)
            reelEffectNode[1]:setOpacity(255)
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    local isplay = true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        local isHaveSpecialFixSymbol = false
        local curRow = RESPIN_ROW_COUNT
        if self.m_runSpinResultData.p_reels then
            curRow = #self.m_runSpinResultData.p_reels
        end

        for k = 1, curRow do
            local endNode = self:getFixSymbol(reelCol, k, SYMBOL_NODE_TAG)

            if endNode then
                if endNode and endNode.p_symbolType then
                    if self:isFixSymbol(endNode.p_symbolType) then
                        endNode:runAnim(
                            "buling",
                            false,
                            function()
                                if endNode.p_symbolType then
                                    endNode:runAnim("idle", true)
                                end
                            end
                        )

                        if endNode.p_symbolType == self.SYMBOL_FIX_Reel_Up or endNode.p_symbolType == self.SYMBOL_FIX_Double_bet then
                            isHaveSpecialFixSymbol = true
                        else
                            isHaveFixSymbol = true
                        end
                    end
                end
            end
        end
        if isplay then
            if isHaveFixSymbol == true then
                -- respinbonus落地音效

                local soundPath = "PomiSounds/music_Pomi_Bonus_down_base.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds(reelCol, soundPath)
                else
                    gLobalSoundManager:playSound(soundPath)
                end
            elseif isHaveSpecialFixSymbol == true then
                local soundPath = "PomiSounds/music_Pomi_Bonus_down_Special.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds(reelCol, soundPath)
                else
                    gLobalSoundManager:playSound(soundPath)
                end
            end
            isplay = false
        end
    end
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenPomiMachine:levelFreeSpinEffectChange()
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenPomiMachine:levelFreeSpinOverChangeEffect()
end
---------------------------------------------------------------------------

-- 触发freespin时调用
function CodeGameScreenPomiMachine:showFreeSpinView(effectData)
    self.isInBonus = true

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("PomiSounds/music_Pomi_common_viewOpen.mp3")
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            gLobalSoundManager:playSound("PomiSounds/music_Pomi_common_viewOpen.mp3")

            self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    performWithDelay(
                        self,
                        function()
                            self:GuoChangAct(
                                "idleframe",
                                function()
                                    self:triggerFreeSpinCallFun()

                                    self:bgImgChange()

                                    effectData.p_isPlay = true
                                    self:playGameEffect()
                                end
                            )
                        end,
                        1
                    )
                end
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        0.5
    )
end

-- 触发freespin结束时调用
function CodeGameScreenPomiMachine:showFreeSpinOverView()
    self.m_baseFreeSpinBar:setVisible(false)

    gLobalSoundManager:playSound("PomiSounds/music_Pomi_freespin_end.mp3")

    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("PomiSounds/music_Pomi_common_viewOpen.mp3")

            local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
            local view =
                self:showFreeSpinOver(
                strCoins,
                self.m_runSpinResultData.p_freeSpinsTotalCount,
                function()
                    self:GuoChangAct(
                        "idleframe",
                        function()
                            -- 调用此函数才是把当前游戏置为freespin结束状态
                            self:triggerFreeSpinOverCallFun()

                            self:bgImgChange()
                        end
                    )
                end
            )
            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
        end,
        4
    )
end

function CodeGameScreenPomiMachine:showRespinJackpot(index, coins, func)
    gLobalSoundManager:playSound("PomiSounds/music_Pomi_common_viewOpen.mp3")

    local jackPotWinView = util_createView("CodePomiSrc.PomiJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self, index, coins, func)
end

-- 结束respin收集
function CodeGameScreenPomiMachine:playLightEffectEnd()
    self:showRespinOverView()
end

function CodeGameScreenPomiMachine:getEndChip()
    return self.m_chipList
end

function CodeGameScreenPomiMachine:playChipCollectAnim()
    local m_chipList = self:getEndChip()

    if self.m_playAnimIndex > #m_chipList then
        scheduler.performWithDelayGlobal(
            function()
                self:playLightEffectEnd()
            end,
            0.1,
            self:getModuleName()
        )

        return
    end

    local chipNode = m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(), chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol

    -- 根据网络数据获得当前固定小块的分数
    local scoreIndx = self:getPosReelIdx(iRow, iCol)
    local score = self:getReSpinSymbolScore(scoreIndx)

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()

    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Grand or 0
            addScore = jackpotScore + addScore
            nJackpotType = 1
        elseif score == "MAJOR" then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Major or 0
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif score == "MINOR" then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Minor or 0
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif score == "MINI" then
            jackpotScore = self.m_runSpinResultData.p_jackpotCoins.Mini or 0
            addScore = jackpotScore + addScore
            nJackpotType = 4
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function fishFlyEndJiesuan()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim()
        else
            self:showRespinJackpot(
                nJackpotType,
                util_formatCoins(jackpotScore, 50),
                function()
                    self.m_playAnimIndex = self.m_playAnimIndex + 1
                    self:playChipCollectAnim()
                end
            )
        end
    end

    -- 添加鱼飞行轨迹
    local function fishFly()
        gLobalSoundManager:playSound("PomiSounds/music_Pomi_Bonus_collect_coins.mp3")

        chipNode:runAnim(
            "jiesuan",
            false,
            function()
                chipNode:runAnim("idle", true)
            end
        )
        local noverAnimTime = chipNode:getAniamDurationByName("jiesuan")

        self:playCoinWinEffectUI()

        if self.m_bProduceSlots_InFreeSpin then
            local coins = self.m_lightScore
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        else
            local coins = self.m_lightScore
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        end

        scheduler.performWithDelayGlobal(
            function()
                fishFlyEndJiesuan()
            end,
            0.4,
            self:getModuleName()
        )
    end

    fishFly()
end

--结束移除小块调用结算特效
function CodeGameScreenPomiMachine:reSpinEndAction()
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("PomiSounds/music_Pomi_respin_end.mp3")

    self.m_bIsRespinOver = true

    performWithDelay(
        self,
        function()
            -- 播放收集动画效果
            self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
            self.m_playAnimIndex = 1

            -- 获得所有固定的respinBonus小块
            self.m_chipList = self.m_respinView:getAllCleaningNode()

            self.m_PomiRespinBarView:setVisible(false)

            self:playChipCollectAnim()
        end,
        2
    )
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenPomiMachine:getRespinRandomTypes()
    local symbolList = {
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

    return symbolList
end

function CodeGameScreenPomiMachine:showReSpinStart(func, func2)
    self:clearCurMusicBg()
    self.isInBonus = true

    gLobalSoundManager:playSound("PomiSounds/music_Pomi_common_viewOpen.mp3")

    local CallFunc = function()
        self:GuoChangAct(
            "idleframe",
            function()
                if func then
                    func()
                end

                self:bgImgChange()
            end,
            function()
                if func2 then
                    func2()
                end
            end
        )
    end

    self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, CallFunc)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenPomiMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_GRAND, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_SYMBOL, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_MAJOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_MINI, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_MINOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_Reel_Up, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_FIX_Double_bet, runEndAnimaName = "", bRandom = true}
    }

    return symbolList
end

function CodeGameScreenPomiMachine:showRespinView()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_WIN_RESPIN)
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()

    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("PomiSounds/music_Pomi_Trigger_Respin.mp3")

            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp and targSp.p_symbolType then
                        if self:isFixSymbol(targSp.p_symbolType) then
                            targSp:runAnim(
                                "actionframe",
                                false,
                                function()
                                    targSp:runAnim(
                                        "actionframe",
                                        false,
                                        function()
                                            targSp:runAnim("idle", true)
                                        end
                                    )
                                end
                            )
                        end
                    end
                end
            end
        end,
        1
    )

    self.m_iReelRowNum = RESPIN_ROW_COUNT
    self:respinChangeReelGridCount(RESPIN_ROW_COUNT)

    performWithDelay(
        self,
        function()
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
        end,
        6
    )
end

function CodeGameScreenPomiMachine:chnangeRespinBg()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local minRow = rsExtraData.rows
        if minRow then
            self:changeReelsBg(minRow)
            self:changeRespinLines(minRow)
            self.m_PomiRespinLinesView:setVisible(true)
            self.m_respinReelsShowRow = minRow
        end
    end
end

--ReSpin开始改变UI状态
function CodeGameScreenPomiMachine:changeReSpinStartUI(respinCount)
    self.m_PomiRespinBarView:setVisible(true)
    self.m_PomiRespinBarView:updateRespinLeftTimnes(respinCount, false)

    self.m_baseFreeSpinBar:setVisible(false)

    self:chnangeRespinBg()
    local Node_Mini = self.m_jackPorBar:findChild("Node_Mini")
    local Node_Minior = self.m_jackPorBar:findChild("Node_Minior")
    Node_Mini:setVisible(false)
    Node_Minior:setVisible(false)
end

--ReSpin刷新数量
function CodeGameScreenPomiMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_PomiRespinBarView:setVisible(true)
    self.m_PomiRespinBarView:updateRespinLeftTimnes(curCount, true)
end

--ReSpin结算改变UI状态
function CodeGameScreenPomiMachine:changeReSpinOverUI()
    self.m_PomiRespinBarView:setVisible(false)
    self:changeReelsBg(3)
    if self.m_PomiRespinLinesView then
        self.m_PomiRespinLinesView = nil
    end

    self.m_respinReelsShowRow = 3

    local Node_Mini = self.m_jackPorBar:findChild("Node_Mini")
    local Node_Minior = self.m_jackPorBar:findChild("Node_Minior")
    Node_Mini:setVisible(true)
    Node_Minior:setVisible(true)

    if self.m_bProduceSlots_InFreeSpin then
        self.m_baseFreeSpinBar:setVisible(true)
    end
end

function CodeGameScreenPomiMachine:triggerReSpinOverCallFun(score)
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
        coins = self:getLastWinCoin() or 0
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
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
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
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

--播放respin放回滚轴后播放的提示动画
function CodeGameScreenPomiMachine:checkRespinChangeOverTip(node, endAnimaName, loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    end
    if node.p_symbolType and self:isFixSymbol(node.p_symbolType) then
        node:runAnim("over", true)
    else
        node:runAnim("idleframe")
    end
end

function CodeGameScreenPomiMachine:showRespinOverView(effectData)
    self.m_bIsRespinOver = false
    self.m_bRespinNodeAnimation = true
    gLobalSoundManager:playSound("PomiSounds/music_Pomi_common_viewOpen.mp3")

    local strCoins = util_formatCoins(self.m_serverWinCoins, 11)
    local view =
        self:showReSpinOver(
        strCoins,
        function()
            self:GuoChangAct(
                "idleframe",
                function()
                    -- 更新游戏内每日任务进度条 -- r
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                    self:respinChangeReelGridCount(NORMAL_ROW_COUNT)
                    self.m_iReelRowNum = NORMAL_ROW_COUNT

                    self:triggerReSpinOverCallFun(self.m_lightScore)
                    self.m_lightScore = 0
                    self:resetMusicBg()

                    self:bgImgChange( )

                    self.m_isRespinOver = true
            
        end ,function(  )
            self:setReelSlotsNodeVisible(true)
            self:removeRespinNode()
            self:changeReSpinOverUI()
        end)

        
    end)
    -- gLobalSoundManager:playSound("PomiSounds/music_Pomi_linghtning_over_win.mp3")
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 518)
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenPomiMachine:operaEffectOver()
    CodeGameScreenPomiMachine.super.operaEffectOver(self)

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

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPomiMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.isInBonus = false
    self.m_bIsRespinOver = false

    return false -- 用作延时点击spin调用
end

function CodeGameScreenPomiMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("PomiSounds/music_Pomi_enter.mp3")

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

function CodeGameScreenPomiMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self:checkUpateDefaultBet()
    self:initTopCommonJackpotBar()
    self:updataJackpotStatus()
    

    BaseSlotoManiaMachine.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    self:upateBetLevel()

    local hasFeature = self:checkHasFeature()
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not hasFeature then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_ONENTER)
    end
end

function CodeGameScreenPomiMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
        
        --公共jackpot
        self:updataJackpotStatus(params)
    end,ViewEventType.NOTIFY_BET_CHANGE)

    --公共jackpot活动结束
    gLobalNoticManager:addObserver(self,function(target, params)

        if params.name == ACTIVITY_REF.CommonJackpot then
            self.m_isJackpotEnd = true
            self:updataJackpotStatus()
        end

    end,ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function CodeGameScreenPomiMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    if self.m_ReelsBgActHandlerID then
        scheduler.unscheduleGlobal(self.m_ReelsBgActHandlerID)
        self.m_ReelsBgActHandlerID = nil
    end

    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearTitleNode()
    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearEntryNode()
end

--接收到数据开始停止滚动
function CodeGameScreenPomiMachine:checkSpecialSymbolType(iCol, iRow)
    local SymbolType = nil

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    if rsExtraData then
        local addSignalPosition = rsExtraData.addSignalPosition

        if addSignalPosition then
            for k, v in pairs(addSignalPosition) do
                local posIndex = v
                local fixPos = self:getRowAndColByPos(posIndex)
                if (fixPos.iX == iRow) and (fixPos.iY == iCol) then
                    -- 升行图标本地转换
                    SymbolType = self.SYMBOL_FIX_Reel_Up
                    return SymbolType
                end
            end
        end

        local multiple = rsExtraData.multiple
        if multiple then
            for k, v in pairs(multiple) do
                local posIndex = v.position
                local fixPos = self:getRowAndColByPos(posIndex)
                if (fixPos.iX == iRow) and (fixPos.iY == iCol) then
                    -- 翻倍图标本地转换
                    SymbolType = self.SYMBOL_FIX_Double_bet
                    return SymbolType
                end
            end
        end
    end

    return SymbolType
end

function CodeGameScreenPomiMachine:getRespinReelsButStored(storedInfo)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            local type = self:getMatrixPosSymbolType(iRow, iCol)
            local a = self:getPosReelIdx(iRow, iCol)
            local specialType = self:checkSpecialSymbolType(iCol, iRow)
            if specialType then
                type = specialType
            end

            if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
            end
        end
    end
    return reelData
end

-- --重写组织respinData信息
function CodeGameScreenPomiMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i = 1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        local specialType = self:checkSpecialSymbolType(pos.iY, pos.iX)
        if specialType then
            type = specialType
        end

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

-- ------------玩法处理 --

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenPomiMachine:MachineRule_network_InterveneSymbolMap()
end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenPomiMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPomiMachine:addSelfEffect()
    -- 自定义动画创建方式
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPomiMachine:MachineRule_playSelfEffect(effectData)
    -- if effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then

    --

    -- end

    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPomiMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenPomiMachine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenPomiMachine:requestSpinResult()
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
    local messageData = {msg = MessageDataType.MSG_SPIN_PROGRESS, data = self.m_collectDataList, jackpot = self.m_jackpotList, betLevel = self:getBetLevel()}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenPomiMachine:updatJackPotLock(minBet)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1
        else
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0
        end
    end
end

function CodeGameScreenPomiMachine:getMinBet()
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

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenPomiMachine:upateBetLevel()
    local minBet = self:getMinBet()

    self:updatJackPotLock(minBet)
end

-- --------respin

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenPomiMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10 - iRow
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

function CodeGameScreenPomiMachine:getPosReelIdx(iRow, iCol)
    local iReelRow = #self.m_runSpinResultData.p_reels

    local index = (iReelRow - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

function CodeGameScreenPomiMachine:respinChangeReelGridCount(count)
    for i = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end

---- lighting 断线重连时，随机转盘数据
function CodeGameScreenPomiMachine:respinModeChangeSymbolType()
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        if self.m_runSpinResultData.p_reSpinCurCount > 0 then
            self.m_iReelRowNum = RESPIN_ROW_COUNT
            self:respinChangeReelGridCount(RESPIN_ROW_COUNT)
        else
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
                        rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % 8
                    end
                end
            end
        end
    end
end
---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenPomiMachine:initCloumnSlotNodesByNetData()
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false
        local beginIndex = 1
        if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
            if self.m_runSpinResultData.p_reSpinCurCount > 0 then
                beginIndex = 4 --  断线的时候respin  只从 后三行数据读取，初始化轮盘
            end
        end

        while rowIndex >= beginIndex do
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

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType)

            -- parentData.slotParent:addChild(node,
            -- REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder)
                node:setVisible(true)
            end

            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            -- node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end
end

function CodeGameScreenPomiMachine:getRespinAddNum()
    local num = 0
    if self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        num = 3
        return num
    end
    return num
end

--- respin下 6行的情况
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function CodeGameScreenPomiMachine:getRowAndColByPosForSixRow(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = RESPIN_ROW_COUNT - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

function CodeGameScreenPomiMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    self:runNextReSpinReel()
                    if self.m_respinReelsShowRow >= RESPIN_ROW_COUNT then
                        self.m_respinView:changeNodeRunningData()
                    end
                end,
                function()
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    --隐藏 盘面信息
                    self:setReelSlotsNodeVisible(false)
                    self.m_respinView:setVisible(true)
                end
            )
        end
    )

    self.m_respinView:setVisible(false)
end

--触发respin
function CodeGameScreenPomiMachine:triggerReSpinCallFun(endTypes, randomTypes)
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
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self.m_respinView:initMachine(self)

    self.m_PomiRespinLinesView = util_createView("CodePomiSrc.PomiRespinLinesView")
    self.m_PomiRespinLinesView:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    self.m_respinView:addChild(self.m_PomiRespinLinesView, 101)
    self.m_PomiRespinLinesView:setVisible(false)
    self.m_PomiRespinLinesView:setPosition(cc.p(self:findChild("respinLines"):getPosition()))

    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenPomiMachine:checkTriggerRespin()
    local features = self.m_runSpinResultData.p_features

    for k, v in pairs(features) do
        if v == 3 then
            return true
        end
    end

    return false
end

function CodeGameScreenPomiMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(6, 5, TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

--开始下次ReSpin
function CodeGameScreenPomiMachine:runNextReSpinReel()
    if globalData.slotRunData.gameRunPause then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end

    self.m_respinView:updateShowSlotsRespinNode()

    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end

function CodeGameScreenPomiMachine:changeRespinLines(minRow)
    if self.m_PomiRespinLinesView then
        for i = 6, 1, -1 do
            local name = "Panel_" .. i
            local line = self.m_PomiRespinLinesView:findChild(name)
            if line then
                if i <= minRow then
                    line:setVisible(true)
                else
                    line:setVisible(false)
                end
            end
        end
    end
end

function CodeGameScreenPomiMachine:changeReelsBgAct(minRow, time, changeY)
    if minRow < 3 then
        minRow = 3
    end

    local addSizeY = math.ceil(changeY / (time * 100))
    local addNowY = 0
    local lastSizeY = (minRow - 1) * changeY

    self.m_ReelsBgActHandlerID =
        scheduler.scheduleGlobal(
        function(delayTime)
            addNowY = addNowY + addSizeY

            if addNowY > changeY then
                addNowY = changeY
            end

            for i = 1, 5 do
                local nodeName = "reel_bg_" .. i - 1
                local bg_Y = self:findChild(nodeName):getContentSize()
                self:findChild(nodeName):setContentSize(128, bg_Y.height + addSizeY)
            end

            self:findChild("Panel_2"):setContentSize(670, self:findChild("Panel_2"):getContentSize().height + addSizeY)
            self:findChild("respinbar"):setPositionY(self:findChild("respinbar"):getPositionY() + addSizeY)

            if addNowY >= changeY then
                self:changeReelsBg(minRow)
                self:changeRespinLines(minRow)
                if self.m_respinReelsShowRow >= RESPIN_ROW_COUNT then
                    self.m_respinView:changeNodeRunningData()
                end
                if self.m_ReelsBgActHandlerID then
                    scheduler.unscheduleGlobal(self.m_ReelsBgActHandlerID)
                    self.m_ReelsBgActHandlerID = nil
                end
            end
        end,
        0.01
    )
end

function CodeGameScreenPomiMachine:changeReelsBg(minRow)
    if minRow < 3 then
        minRow = 3
    end

    local baseY = 348
    local addY = (baseY / 3) * (minRow - 3)
    local newY = baseY + addY
    local panelY = 358 + addY

    for i = 1, 5 do
        local nodeName = "reel_bg_" .. i - 1
        self:findChild(nodeName):setContentSize(128, newY)
    end

    self:findChild("Panel_2"):setContentSize(670, panelY)

    local basePosY = self.m_respinBarPosY or 583
    local addPosY = basePosY + addY
    self:findChild("respinbar"):setPositionY(addPosY)
end

---判断结算
function CodeGameScreenPomiMachine:reSpinReelDown(addNode)
    -- respin所有滚动结束
    self.m_runNextRespinFunc = function()
        BaseSlotoManiaMachine.reSpinReelDown(self, addNode)

        self.m_runNextRespinFunc = nil
    end

    self:addRespinGameEffect()

    performWithDelay(
        self,
        function()
            self:playRespinEffect()
        end,
        1.3
    )
end

function CodeGameScreenPomiMachine:addRespinGameEffect()
    -- 全部停止播放升行或者翻倍动画
    -- 先升行在翻倍
    -- 存储上respin动画序列
    self.m_respinEffectList = {}

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    if rsExtraData then
        local addSignalPosition = rsExtraData.addSignalPosition

        if addSignalPosition then
            for k, v in pairs(addSignalPosition) do
                local effectData = {}
                effectData.m_isplay = false
                effectData.m_playType = self.SYMBOL_FIX_Reel_Up
                effectData.m_index = k
                table.insert(self.m_respinEffectList, effectData)
            end
        end

        local multiple = rsExtraData.multiple
        if multiple then
            for k, v in pairs(multiple) do
                local effectData = {}
                effectData.m_isplay = false
                effectData.m_playType = self.SYMBOL_FIX_Double_bet
                effectData.m_index = k
                table.insert(self.m_respinEffectList, effectData)
            end
        end
    end
end

function CodeGameScreenPomiMachine:playRespinEffect()
    if self.m_respinEffectList == nil or #self.m_respinEffectList == 0 then
        if self.m_runNextRespinFunc then
            self.m_runNextRespinFunc()
        end
        return
    end

    for k, v in pairs(self.m_respinEffectList) do
        local effectData = v

        if effectData.m_isplay == false then
            if effectData.m_playType == self.SYMBOL_FIX_Reel_Up then
                self:respinEffect_ReelUp(effectData)
            elseif effectData.m_playType == self.SYMBOL_FIX_Double_bet then
                self:respinEffect_DoubleBset(effectData)
            end

            break
        end

        -- 所有动画时间已经全部播放完毕
        if k == #self.m_respinEffectList and effectData.m_isplay == true then
            if self.m_runNextRespinFunc then
                self.m_runNextRespinFunc()
            end

            return
        end
    end
end

function CodeGameScreenPomiMachine:getCleaningRespinFixSymbol(index)
    local nodeList = self.m_respinView:getAllCleaningNode()
    local node = nil
    for k, v in pairs(nodeList) do
        local node = v

        local nodeIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex)
        if index == nodeIndex then
            node = v
            return node
        end
    end
    return node
end

function CodeGameScreenPomiMachine:getRespinFixSymbol(index)
    local nodeList = self.m_respinView.m_respinNodes
    local node = nil
    for k, v in pairs(nodeList) do
        local node = v

        local nodeIndex = self:getPosReelIdx(node.p_rowIndex, node.p_colIndex)
        if index == nodeIndex then
            node = v
            return node
        end
    end
    return node
end

function CodeGameScreenPomiMachine:respinEffect_ReelUp(effectData)
    effectData.m_isplay = true

    self.m_respinReelsShowRow = self.m_respinReelsShowRow + 1

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local waitTime = 0
    if rsExtraData then
        local addSignalPosition = rsExtraData.addSignalPosition

        if addSignalPosition then
            for k, v in pairs(addSignalPosition) do
                if k == effectData.m_index then
                    local posIndex = v
                    local fixPos = self:getRowAndColByPos(posIndex)
                    local tarSp = self:getRespinFixSymbol(posIndex) -- self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    if tarSp and tarSp.m_lastNode then
                        gLobalSoundManager:playSound("PomiSounds/music_Pomi_reelsUP_Trigger.mp3")

                        tarSp.m_lastNode:runAnim(
                            "actionframe",
                            false,
                            function()
                                tarSp.m_lastNode:runAnim("idle", true)
                            end
                        )
                        waitTime = 2 + 1.4 + 1

                        performWithDelay(
                            self,
                            function()
                                gLobalSoundManager:playSound("PomiSounds/music_Pomi_ReelsUp_action.mp3")

                                local oldPos = cc.p(self:getPosition())

                                local actid = self:beginShake()

                                self.m_bgChangeAct:setVisible(true)
                                self.m_bgChangeAct:showOneActImg(self.m_respinReelsShowRow)
                                self.m_bgChangeAct:runCsbAction(
                                    "start",
                                    false,
                                    function()
                                        self.m_bgChangeAct:runCsbAction("idle", true)
                                    end,
                                    30
                                )

                                local time = 1

                                if self.m_respinReelsShowRow == 4 then
                                    time = 0.6
                                elseif self.m_respinReelsShowRow == 5 then
                                    time = 0.6
                                elseif self.m_respinReelsShowRow == 6 then
                                    time = 0.6
                                end

                                performWithDelay(
                                    self,
                                    function()
                                        self:changeReelsBgAct(self.m_respinReelsShowRow, 0.16, 116)
                                    end,
                                    time
                                )

                                self.m_gameBg:runCsbAction(
                                    "actionframe",
                                    false,
                                    function()
                                        self.m_gameBg:runCsbAction("idleframe", true)
                                    end
                                )

                                performWithDelay(
                                    self,
                                    function()
                                        self.m_respinView:updateShowSlotsRespinNodeForRow(self.m_respinReelsShowRow)
                                    end,
                                    1.8
                                )

                                performWithDelay(
                                    self,
                                    function()
                                        self:stopAction(actid)
                                        self:setPosition(oldPos)
                                    end,
                                    2
                                )

                                performWithDelay(
                                    self,
                                    function()
                                        local lab = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                        local lab1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                        local score = self:getReSpinSymbolScore(posIndex)
                                        local changeSymbolType = self.SYMBOL_FIX_SYMBOL

                                        if lab then
                                            local lineBet = globalData.slotRunData:getCurTotalBet()

                                            if score and type(score) == "number" then
                                                self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 5)

                                                score = self:changeFixSocreForDoubleBetGame(posIndex, score)
                                                local labtxt = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                                local labtxt1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                                if score >= 5 then
                                                    labtxt:setVisible(false)
                                                    labtxt1:setVisible(true)
                                                else
                                                    labtxt:setVisible(true)
                                                    labtxt1:setVisible(false)
                                                end
                                                score = score * lineBet
                                                labtxt:setString(util_formatCoins(score, 3))
                                                labtxt1:setString(util_formatCoins(score, 3))
                                            elseif score and type(score) == "string" then
                                                if score == "MINI" then
                                                    changeSymbolType = self.SYMBOL_FIX_MINI
                                                    self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 4)
                                                elseif score == "MINOR" then
                                                    changeSymbolType = self.SYMBOL_FIX_MINOR
                                                    self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 3)
                                                elseif score == "MAJOR" then
                                                    changeSymbolType = self.SYMBOL_FIX_MAJOR
                                                    self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 2)
                                                elseif score == "GRAND" then
                                                    changeSymbolType = self.SYMBOL_FIX_GRAND
                                                    self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 1)
                                                end
                                            end
                                        end

                                        gLobalSoundManager:playSound("PomiSounds/music_Pomi_specialToBonus.mp3")

                                        tarSp.m_lastNode:runAnim("qiehuan", false)

                                        performWithDelay(
                                            self,
                                            function()
                                                tarSp.m_lastNode:changeCCBByName(self:getSymbolCCBNameByType(self, changeSymbolType), changeSymbolType)
                                                local changedlab = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                                local changedlab1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                                local lineBet = globalData.slotRunData:getCurTotalBet()

                                                if changedlab then
                                                    if (score / lineBet) >= 5 then
                                                        changedlab:setVisible(false)
                                                        changedlab1:setVisible(true)
                                                    else
                                                        changedlab:setVisible(true)
                                                        changedlab1:setVisible(false)
                                                    end
                                                    changedlab:setString(util_formatCoins(score, 3))
                                                    changedlab1:setString(util_formatCoins(score, 3))
                                                end

                                                tarSp.m_lastNode:runAnim("idle", true)
                                            end,
                                            1.4
                                        )
                                    end,
                                    2 + 1.4 + 0.5
                                )
                            end,
                            1
                        )
                    end

                    break
                end
            end
        end
    end

    performWithDelay(
        self,
        function()
            self.m_bgChangeAct:runCsbAction(
                "over",
                false,
                function()
                    self.m_bgChangeAct:setVisible(false)
                end,
                30
            )
        end,
        waitTime
    )

    performWithDelay(
        self,
        function()
            self:playRespinEffect()
        end,
        0.5 + waitTime + 1.4 + 0.5
    )
end

function CodeGameScreenPomiMachine:showSpecialSymbolNodeImg(Node, index)
    local nameList = {"Pomi_grand", "Pomi_major", "Pomi_minor", "Pomi_mini", "m_lb_score", "m_lb_score1"}
    for k, v in pairs(nameList) do
        local symbolimg = Node:getCcbProperty(v)
        if k == index then
            if symbolimg then
                symbolimg:setVisible(true)
            end
        else
            if symbolimg then
                symbolimg:setVisible(false)
            end
        end
    end

    local lab = Node:getCcbProperty("m_lb_score1")
    if index == 5 then
        if lab then
            lab:setVisible(true)
        end
    else
        if lab then
            lab:setVisible(false)
        end
    end
end

function CodeGameScreenPomiMachine:respinEffect_DoubleBset(effectData)
    effectData.m_isplay = true

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local waitTime = 0
    if rsExtraData then
        local multiple = rsExtraData.multiple

        if multiple then
            for k, v in pairs(multiple) do
                if k == effectData.m_index then
                    local posIndex = v.position
                    local multiplePosList = v.multPosition

                    local fixPos = self:getRowAndColByPos(posIndex)
                    local tarSp = self:getRespinFixSymbol(posIndex) -- self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    if tarSp and tarSp.m_lastNode then
                        local oldPos = nil
                        local actid = nil
                        waitTime = 1.1 + 1.3 + 2 + 1.5
                        local multipleTime = 0
                        if multiplePosList and #multiplePosList > 0 then
                            multipleTime = (#multiplePosList * 0.2 + 0.7)
                            waitTime = waitTime + (#multiplePosList * 0.2 + 0.7)
                        end
                        table.sort(multiplePosList)

                        gLobalSoundManager:playSound("PomiSounds/music_Pomi_DoubleBet_Trigger.mp3")

                        local DoubleBetFir = util_createView("CodePomiSrc.PomiDoubleBetActView", posIndex, multiplePosList)
                        self.m_root:addChild(DoubleBetFir, 99998)

                        if globalData.slotRunData.machineData.p_portraitFlag then
                            DoubleBetFir.getRotateBackScaleFlag = function()
                                return false
                            end
                        end

                        DoubleBetFir:runCsbAction(
                            "show",
                            false,
                            function()
                                DoubleBetFir:runCsbAction("idle", true)
                            end
                        )

                        DoubleBetFir:setPosition(util_getConvertNodePos(tarSp.m_lastNode, DoubleBetFir))

                        tarSp.m_lastNode:runAnim(
                            "actionframe",
                            false,
                            function()
                                tarSp.m_lastNode:runAnim("idle", true)
                                oldPos = cc.p(self:getPosition())

                                actid = self:beginShake()
                            end
                        )

                        performWithDelay(
                            self,
                            function()
                                gLobalSoundManager:playSound("PomiSounds/music_Pomi_DoubleBet_shake.mp3")

                                self.m_gameBg:runCsbAction("actionframe")
                                performWithDelay(
                                    self,
                                    function()
                                        if multiplePosList and #multiplePosList > 0 then
                                            self:CreatFireBall(multiplePosList, 0.7)
                                        end
                                    end,
                                    1.1
                                )

                                performWithDelay(
                                    self,
                                    function()
                                        self.m_gameBg:runCsbAction("idleframe", true)

                                        performWithDelay(
                                            self,
                                            function()
                                                if multiplePosList then
                                                    local index = 0
                                                    for k, v in pairs(multiplePosList) do
                                                        local addBetposIndex = v
                                                        local addBetFixPos = self:getRowAndColByPos(addBetposIndex)
                                                        local addBetTarSp = self:getCleaningRespinFixSymbol(addBetposIndex)

                                                        if addBetTarSp and addBetTarSp then
                                                            performWithDelay(
                                                                self,
                                                                function()
                                                                    local firBall = util_createView("CodePomiSrc.PomiFireBallView")
                                                                    self.m_root:addChild(firBall, 99999)
                                                                    local pos = util_getConvertNodePos(addBetTarSp, firBall)
                                                                    firBall:setPosition(cc.p(pos))
                                                                    firBall:runCsbAction(
                                                                        "animation0",
                                                                        false,
                                                                        function()
                                                                            firBall:removeFromParent()
                                                                            firBall = nil
                                                                        end
                                                                    )
                                                                    performWithDelay(
                                                                        self,
                                                                        function()
                                                                            gLobalSoundManager:playSound("PomiSounds/music_Pomi_DoubleBet_action.mp3")

                                                                            addBetTarSp:runAnim(
                                                                                "change",
                                                                                false,
                                                                                function()
                                                                                    addBetTarSp:runAnim("idle", true)
                                                                                end
                                                                            )
                                                                            local addBetlab = addBetTarSp:getCcbProperty("m_lb_score")

                                                                            local addBetlab1 = addBetTarSp:getCcbProperty("m_lb_score1")

                                                                            local addBetscore = self:getReSpinSymbolScore(addBetposIndex)
                                                                            if addBetlab then
                                                                                local addBetlineBet = globalData.slotRunData:getCurTotalBet()

                                                                                if addBetscore and type(addBetscore) == "number" then
                                                                                    addBetscore = addBetscore * addBetlineBet

                                                                                    if (addBetscore / addBetlineBet) >= 5 then
                                                                                        addBetlab:setVisible(false)
                                                                                        addBetlab1:setVisible(true)
                                                                                    else
                                                                                        addBetlab:setVisible(true)
                                                                                        addBetlab1:setVisible(false)
                                                                                    end

                                                                                    performWithDelay(
                                                                                        self,
                                                                                        function()
                                                                                            addBetlab:setString(util_formatCoins(addBetscore, 3))
                                                                                            addBetlab1:setString(util_formatCoins(addBetscore, 3))
                                                                                        end,
                                                                                        0.25
                                                                                    )
                                                                                end
                                                                            end
                                                                        end,
                                                                        0.3
                                                                    )
                                                                end,
                                                                0.2 * index
                                                            )
                                                        end

                                                        index = index + 1
                                                    end
                                                end
                                            end,
                                            0.3
                                        )
                                    end,
                                    1.5
                                )
                            end,
                            2
                        )

                        performWithDelay(
                            self,
                            function()
                                DoubleBetFir:runCsbAction(
                                    "over",
                                    false,
                                    function()
                                        DoubleBetFir:removeFromParent()
                                    end
                                )

                                self.m_GuoChangView:stopParticle()
                                self.m_GuoChangView:setVisible(false)

                                if actid then
                                    self:stopAction(actid)
                                end

                                if oldPos then
                                    self:setPosition(oldPos)
                                end
                            end,
                            1.1 + 2 + 1.5 + multipleTime
                        )

                        performWithDelay(
                            self,
                            function()
                                local lab = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                local lab1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                local score = self:getReSpinSymbolScore(posIndex)
                                local changeSymbolType = self.SYMBOL_FIX_SYMBOL
                                if lab then
                                    local lineBet = globalData.slotRunData:getCurTotalBet()
                                    lab:setString("")
                                    lab1:setString("")
                                    if score and type(score) == "number" then
                                        self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 5)

                                        score = self:changeFixSocreForDoubleBetGame(posIndex, score)

                                        score = score * lineBet

                                        if (score / lineBet) >= 5 then
                                            lab:setVisible(false)
                                            lab1:setVisible(true)
                                        else
                                            lab:setVisible(true)
                                            lab1:setVisible(false)
                                        end

                                        lab:setString(util_formatCoins(score, 3))
                                        lab1:setString(util_formatCoins(score, 3))
                                    elseif score and type(score) == "string" then
                                        if score == "MINI" then
                                            changeSymbolType = self.SYMBOL_FIX_MINI
                                            self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 4)
                                        elseif score == "MINOR" then
                                            changeSymbolType = self.SYMBOL_FIX_MINOR
                                            self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 3)
                                        elseif score == "MAJOR" then
                                            changeSymbolType = self.SYMBOL_FIX_MAJOR
                                            self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 2)
                                        elseif score == "GRAND" then
                                            changeSymbolType = self.SYMBOL_FIX_GRAND
                                            self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 1)
                                        end
                                    end
                                end

                                gLobalSoundManager:playSound("PomiSounds/music_Pomi_specialToBonus.mp3")

                                tarSp.m_lastNode:runAnim(
                                    "qiehuan",
                                    false,
                                    function()
                                        tarSp.m_lastNode:changeCCBByName(self:getSymbolCCBNameByType(self, changeSymbolType), changeSymbolType)
                                        local changedlab = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                        local changedlab1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                        local lineBet = globalData.slotRunData:getCurTotalBet()

                                        if changedlab then
                                            if (score / lineBet) >= 5 then
                                                changedlab:setVisible(false)
                                                changedlab1:setVisible(true)
                                            else
                                                changedlab:setVisible(true)
                                                changedlab1:setVisible(false)
                                            end
                                            changedlab:setString(util_formatCoins(score, 3))
                                            changedlab1:setString(util_formatCoins(score, 3))
                                        end

                                        tarSp.m_lastNode:runAnim("idle", true)
                                    end
                                )
                            end,
                            0.5 + waitTime
                        )
                    end
                end

                break
            end
        end
    end

    performWithDelay(
        self,
        function()
            self:playRespinEffect()
        end,
        1 + waitTime
    )
end

function CodeGameScreenPomiMachine:beginShake()
    local oldPos = cc.p(self:getPosition())

    local action =
        self:shakeOneNodeForever(
        oldPos,
        self,
        function()
        end
    )

    return action
end

function CodeGameScreenPomiMachine:shakeOneNodeForever(oldPos, node, func)
    local changePosY = math.random(3, 5)
    local actionList2 = {}
    actionList2[#actionList2 + 1] =
        cc.CallFunc:create(
        function()
            if func then
                func()
            end
            -- changePosY = math.random( 130,300 )
        end
    )
    actionList2[#actionList2 + 1] = cc.MoveTo:create(0.05, cc.p(oldPos.x, oldPos.y - changePosY))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(0.05, cc.p(oldPos.x, oldPos.y + changePosY))
    local seq2 = cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    node:runAction(action)
    return action
end

function CodeGameScreenPomiMachine:CreatFireBall(posList, time)
    self.m_GuoChangView:setVisible(true)
    self.m_GuoChangView:playParticle()
end

function CodeGameScreenPomiMachine:GuoChangAct(animation, func, func2)
    gLobalSoundManager:playSound("PomiSounds/music_Pomi_GuoChang.mp3")

    local oldPos = cc.p(self:getPosition())
    local actid = self:beginShake()
    self.m_slotEffectLayer:setVisible(false)
    util_playFadeOutAction(self.m_root, 0.6)

    performWithDelay(
        self,
        function()
            if func2 then
                func2()
            end

            self.m_gameBg:runCsbAction(
                "actionframe",
                false,
                function()
                    self.m_GuoChangView2:setVisible(true)

                    self.m_gameBg:runCsbAction(animation, true)

                    self.m_GuoChangView2:playParticle()

                    self.m_GuoChangView2:runCsbAction(
                        "animation0",
                        false,
                        function()
                            self.m_GuoChangView2:stopParticle()
                            self.m_GuoChangView2:setVisible(false)
                            self:stopAction(actid)
                            self:setPosition(oldPos)
                            util_playFadeInAction(self.m_root, 0.6)

                            performWithDelay(
                                self,
                                function()
                                    self.m_slotEffectLayer:setVisible(true)

                                    if func then
                                        func()
                                    end
                                end,
                                1.1
                            )
                        end,
                        45
                    )
                end
            )
        end,
        1.1
    )
end

function CodeGameScreenPomiMachine:lineLogicEffectType(winLineData, lineInfo, iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData, lineInfo)

    local validLineSymNum = self.m_validLineSymNum

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        validLineSymNum = 2
    end

    if iconsPos ~= nil and #iconsPos >= validLineSymNum then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

function CodeGameScreenPomiMachine:createLocalAnimation()
    local pos = cc.p(self.m_bottomUI.m_normalWinLabel:getPosition())

    self.m_respinEndActiom = util_createView("CodePomiSrc.PomiViewWinCoinsAction")
    self.m_bottomUI.m_normalWinLabel:getParent():addChild(self.m_respinEndActiom, 99999)
    self.m_respinEndActiom:setPosition(cc.p(pos.x - 8, pos.y))

    self.m_respinEndActiom:setVisible(false)
end

function CodeGameScreenPomiMachine:initMachineBg()
    local gameBg = util_createView("CodePomiSrc.PomiGameBGView")
    self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end

function CodeGameScreenPomiMachine:bgImgChange()
    self.m_gameBg:findChild("Pomi_bg1"):setVisible(true) --
    self.m_gameBg:findChild("Pomi_bg2"):setVisible(true)

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE then
        -- self.m_gameBg:runCsbAction("animation0",true)
        util_playFadeOutAction(self.m_gameBg:findChild("Pomi_bg1"), 0.5)
        util_playFadeInAction(self.m_gameBg:findChild("Pomi_bg2"), 0.5)
        self.m_gameBg:findChild("Pomi_bg2"):setOpacity(0)
    else
        self.m_gameBg:runCsbAction("animation0", true)
        util_playFadeOutAction(self.m_gameBg:findChild("Pomi_bg2"), 0.5)
        util_playFadeInAction(self.m_gameBg:findChild("Pomi_bg1"), 0.5)

        self.m_gameBg:findChild("Pomi_bg1"):setOpacity(0)
    end
end

-- 背景音乐点击spin后播放
function CodeGameScreenPomiMachine:normalSpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()

    BaseMachine.normalSpinBtnCall(self)
end

function CodeGameScreenPomiMachine:slotReelDown()
    BaseMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenPomiMachine:playEffectNotifyNextSpinCall()
    self:setMaxMusicBGVolume()

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
        if self.m_bRespinNodeAnimation == true then
            delayTime = 2
            self.m_bRespinNodeAnimation = false
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
end

function CodeGameScreenPomiMachine:randomSlotNodesByReel()
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
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            -- parentData.slotParent:addChild(node,
            -- node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder - rowIndex)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)

            if self:isFixSymbol(symbolType) then
                node:runAnim("idle", true)
            end
        end
    end
end

function CodeGameScreenPomiMachine:randomSlotNodes()
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            -- parentData.slotParent:addChild(node,
            -- node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder - rowIndex)
                node:setVisible(true)
            end

            --            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)

            if self:isFixSymbol(symbolType) then
                node:runAnim("idle", true)
            end
        end
    end
end

--进关时的初始化数据  底层的数据读取一点都不统一
function CodeGameScreenPomiMachine:initGameStatusData(gameData)
    CodeGameScreenPomiMachine.super.initGameStatusData(self,gameData)

end

---
-- 处理spin 返回结果
function CodeGameScreenPomiMachine:spinResultCallFun(param)
    CodeGameScreenPomiMachine.super.spinResultCallFun(self,param)
    self.m_jackPorBar:resetCurRefreshTime()
end

function CodeGameScreenPomiMachine:updateReelGridNode(symbolNode)
    if symbolNode.p_symbolType == self.SYMBOL_FIX_GRAND then
        symbolNode:getCcbProperty("node_grand"):setVisible(self.m_jackpot_status == "Normal")
        symbolNode:getCcbProperty("node_mega"):setVisible(self.m_jackpot_status == "Mega")
        symbolNode:getCcbProperty("node_super"):setVisible(self.m_jackpot_status == "Super")
    end
end


-------------------------------------------------公共jackpot-----------------------------------------------------------------------

--[[
    更新公共jackpot状态
]]
function CodeGameScreenPomiMachine:updataJackpotStatus(params)
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

function CodeGameScreenPomiMachine:updateJackpotBarMegaShow()
    self.m_jackPorBar:updateMegaShow()
end

function CodeGameScreenPomiMachine:getCommonJackpotValue(_status, _addTimes)
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
function CodeGameScreenPomiMachine:initTopCommonJackpotBar()
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

return CodeGameScreenPomiMachine
