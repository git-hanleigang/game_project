---
-- island li
-- 2019年1月26日
-- CodeGameScreenWildGorillaMachine.lua
--
-- 玩法：
-- FIX IOS 139

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenWildGorillaMachine = class("CodeGameScreenWildGorillaMachine", BaseNewReelMachine)

CodeGameScreenWildGorillaMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWildGorillaMachine.SYMBOL_BONUS_LINK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- bonus
CodeGameScreenWildGorillaMachine.SYMBOL_BONUS_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenWildGorillaMachine.SYMBOL_BONUS_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenWildGorillaMachine.SYMBOL_BONUS_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenWildGorillaMachine.SYMBOL_BONUS_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11

CodeGameScreenWildGorillaMachine.SYMBOL_WILD_2 = 201 ---wild x2
CodeGameScreenWildGorillaMachine.SYMBOL_WILD_3 = 202 ---wild x3
CodeGameScreenWildGorillaMachine.SYMBOL_WILD_5 = 203 ---wild x5

CodeGameScreenWildGorillaMachine.BONUS_WIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
-- 构造函数
function CodeGameScreenWildGorillaMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_isOnceClipNode = false
    self.m_spinRestMusicBG = true
    self.m_iReelMaxRow = 6 --最大显示行数
    self.m_iNormalRow = 3 --常态显示行数
    self.m_bAddRow = false --是否有升行
    self.m_iAddShowRow = 4 --现在显示的行数主要用于轮盘的升降
    self.m_iNowRow = 4 --现在显示的行数
    self.m_scatterNum = 0
    self.m_wildNum = 0
    self.m_nowBottomCoins = 0
    self.m_bonusSymBolFrameList = {} --bonus 遮罩框
    self.m_avgBet = 0
    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

function CodeGameScreenWildGorillaMachine:initGame()
    --初始化基本数据
    self.m_configData = gLobalResManager:getCSVLevelConfigData("WildGorillaConfig.csv", "LevelWildGorillaConfig.lua")
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
function CodeGameScreenWildGorillaMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WildGorilla"
end

function CodeGameScreenWildGorillaMachine:initUI()
    self.m_reelRunSound = "WildGorillaSounds/sound_WildGorilla_fast_run.mp3"
    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    self.m_WildGorillaView = util_createView("CodeWildGorillaSrc.WildGorillaJackPotBarView")
    self.m_WildGorillaView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_WildGorillaView)

    self.m_fsTip = util_createView("CodeWildGorillaSrc.WildGorillaFreeSpinTipView")
    self:findChild("Node_fs"):addChild(self.m_fsTip)
    self.m_fsTip:showTips()

    self.m_Logo = util_spineCreate("WildGorilla_logo", true, true)
    self:findChild("Node_logo"):addChild(self.m_Logo)
    util_spinePlay(self.m_Logo, "idleframe", true)

    self.m_reelFire = util_createAnimation("WildGorilla_Hshenglun.csb")
    self:findChild("Huo"):addChild(self.m_reelFire, 1, 1)
    self.m_reelFire:setVisible(false)

    self.m_guochang = util_spineCreate("WildGorilla_guochang", true, true)
    self:addChild(self.m_guochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    self.m_guochang:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochang:setVisible(false)

    local bgNode = self.m_gameBg:findChild("freeNode")
    self.m_freeIdle = util_spineCreate("WildGorilla_freebg", true, true)
    bgNode:addChild(self.m_freeIdle)
    util_spinePlay(self.m_freeIdle, "actionframe", true)

    local bgNode = self.m_gameBg:findChild("baseNode")
    self.m_baseIdle = util_spineCreate("WildGorilla_bsbg", true, true)
    bgNode:addChild(self.m_baseIdle)
    util_spinePlay(self.m_baseIdle, "actionframe", true)

    local daXingXingNode = self:findChild("daXingXingNode")
    self.m_daXingXing = util_spineCreate("WildGorilla_juese", true, true)
    daXingXingNode:addChild(self.m_daXingXing)
    util_spinePlay(self.m_daXingXing, "idleframe", true)
    self.m_daXingXing:setVisible(false)
end

--过场动画
function CodeGameScreenWildGorillaMachine:playTransitionEffect(_actionName, _funcEnd)
    util_spinePlay(self.m_guochang, _actionName, false)
    -- 动画结束
    util_spineEndCallFunc(
        self.m_guochang,
        _actionName,
        function()
            if _funcEnd then
                _funcEnd()
            end
        end
    )
end
--初始freespin tips
function CodeGameScreenWildGorillaMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_tishiban")
    self.m_baseFreeSpinBar = util_createView("CodeWildGorillaSrc.WildGorillaFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end

function CodeGameScreenWildGorillaMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_enter.mp3")
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenWildGorillaMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

            
    self.m_touchSpinLayer:setPositionY(self.m_touchSpinLayer:getPositionY() - self.m_SlotNodeH / 4 ) 

end

function CodeGameScreenWildGorillaMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
                return
            end

            if self.m_bIsBigWin then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
            elseif winRate > 3 then
                soundIndex = 3
            end

            local soundTime = soundIndex
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = "WildGorillaSounds/sound_WildGorilla_last_win" .. soundIndex .. ".mp3"
            if self:isHaveBonusWinCoins() then
                soundName = "WildGorillaSounds/sound_WildGorilla_bonus_win.mp3"
            end
            self.m_winSoundsId, self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenWildGorillaMachine:scaleMainLayer()
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

    if globalData.slotRunData.isPortrait then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
        end
        local bangHeight = util_getBangScreenHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - bangHeight)
    end

    if display.height / display.width == 1024 / 768 then
        mainScale = 0.70
    end

    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
end

--是否有Bonus赢钱
function CodeGameScreenWildGorillaMachine:isHaveBonusWinCoins()
    local isHave = false
    if self:isTriggerAddRow() then
        for iRow = 2, self.m_iNowRow do
            local node = self:getFixSymbol(3, iRow, SYMBOL_NODE_TAG)
            if node then
                local symbolType = node.p_symbolType
                if self:isBonusSymbolByType(symbolType) then
                    isHave = true
                    break
                end
            end
        end
    end
    return isHave
end

function CodeGameScreenWildGorillaMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    if self.m_updateReelHeightID then
        scheduler.unscheduleGlobal(self.m_updateReelHeightID)
        self.m_updateReelHeightID = nil
    end
    scheduler.unschedulesByTargetName(self:getModuleName())
end

--绘制多个裁切区域
function CodeGameScreenWildGorillaMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边

    local prePosX = -1

    --计算第一列和第三列高度差
    local reelNode1 = self:findChild("sp_reel_0")
    local reel1PosY = reelNode1:getPositionY()

    local reelNode3 = self:findChild("sp_reel_2")
    local reel3PosY = reelNode3:getPositionY()

    self.m_ReelOffY = reel1PosY - reel3PosY

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
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000)
        else
            local reelHight = reelSize.height

            if i >= 3 then
                reelHight = reelSize.height - 3 * reelSize.height / 6 + self.m_ReelOffY * 2 + 2
            else
                reelHight = reelSize.height - 2 * reelSize.height / 5
            end
            clipNode =
                cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelHight
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)

        --添加黑色遮罩
        -- local maskNode = cc.Node:create()
        -- local maskReelLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 200))
        -- maskReelLayer:setPositionX(reelSize.width / 2)
        -- maskReelLayer:setContentSize(reelSize.width, reelSize.height + 400)
        -- maskReelLayer:setVisible(false)
        -- maskNode:addChild(maskReelLayer)
        -- slotParentNode:addChild(maskNode, REEL_SYMBOL_ORDER.REEL_ORDER_2)
        -- table.insert(self.m_maskReelLayer, maskNode)
        -- maskNode:setVisible(false)

        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)
        local reelNode = cc.Node:create()
        reelNode:addChild(slotParentNode)
        clipNode:addChild(reelNode)
        if i >= 3 then
            slotParentNode:setContentSize(reelSize.width * 2, reelSize.height + self.m_ReelOffY * 2)
            local offY = reelSize.height / 6 - self.m_ReelOffY
            reelNode:setPositionY(reelNode:getPositionY() - offY)
        else
            local GridH = reelSize.height / 5
            reelNode:setPositionY(reelNode:getPositionY() - GridH)
        end

        local parentData = SlotParentData:new()
        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
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
    
        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, ( 3*4 +2 ) * slotH/6/4 )) --把一个图标分成四份
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)
        
        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")

    end
end

-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
function CodeGameScreenWildGorillaMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local rowCount = self.m_iReelMaxRow
        --columnData.p_showGridCount --#self.m_initSpinData.p_reels
        local rowNum = self.m_iReelMaxRow
        --columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType)

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH
            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end
            node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:runIdleAnim()
            rowIndex = rowIndex - 1
        end -- end while
    end
    self:initGridList()
end

function CodeGameScreenWildGorillaMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)

            symbolType = self:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2
            end
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            --            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end
-- 返回自定义信号类型对应ccbi，
function CodeGameScreenWildGorillaMachine:MachineRule_GetSelfCCBName(symbolType)
    if self.SYMBOL_BONUS_LINK == symbolType then
        return "Socre_WildGorilla_link"
    elseif self.SYMBOL_BONUS_MINI == symbolType then
        return "Socre_WildGorilla_link"
    elseif self.SYMBOL_BONUS_MINOR == symbolType then
        return "Socre_WildGorilla_link"
    elseif self.SYMBOL_BONUS_MAJOR == symbolType then
        return "Socre_WildGorilla_link"
    elseif self.SYMBOL_BONUS_GRAND == symbolType then
        return "Socre_WildGorilla_link"
    elseif self.SYMBOL_WILD_2 == symbolType then
        return "Socre_WildGorilla_wild_x2"
    elseif self.SYMBOL_WILD_3 == symbolType then
        return "Socre_WildGorilla_wild_x3"
    elseif self.SYMBOL_WILD_5 == symbolType then
        return "Socre_WildGorilla_wild_x5"
    end
    return nil
end

function CodeGameScreenWildGorillaMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(self.m_iReelMaxRow, self.m_iReelColumnNum, TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
end
----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenWildGorillaMachine:MachineRule_initGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_bBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            if selfData.triggerFreeGame then
                local num = selfData.triggerFreeGame
                if num > 0 then
                    num = num - 1
                else
                    num = 0
                end
                self.m_fsTip:showFreeSpinCount(num)
                self:setChangeReelRowInfo()
                --断线时刚好碰上升轮
                if self.m_bAddRow == true then
                    if self.m_iAddShowRow > 3 then
                        self.m_Logo:setVisible(false)

                        self:runCsbAction("idle_" .. self.m_iAddShowRow)
                        self:changeReelLength(1, self.m_iAddShowRow)
                    end
                end
            end
        else
            self.m_fsTip:setVisible(false)
            if selfData.triggerFreeGame then
                local num = selfData.triggerFreeGame
                self.m_fsTip:showFreeSpinCount(num)
                local num = selfData.triggerFreeGame
                if num == 5 then
                    self.m_bottomUI:showAverageBet()
                    self.m_baseFreeSpinBar:runCsbAction("idle1")
                    if selfData.avgBet and selfData.avgBet > 0 then
                        self.m_avgBet = selfData.avgBet
                    end
                else
                    self.m_baseFreeSpinBar:runCsbAction("idle2")
                end
            end
        end
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
    else
        if selfData.triggerFreeGame then
            local num = selfData.triggerFreeGame
            if num == 5 then
                num = 0
            end
            self.m_fsTip:showFreeSpinCount(num)
        end
    end
end

function CodeGameScreenWildGorillaMachine:playLogoShowOrHide(_actionName, _func)
    util_spinePlay(self.m_Logo, _actionName, false)
    util_spineEndCallFunc(
        self.m_Logo,
        _actionName,
        function()
            if _func then
                _func()
            end
        end
    )
end

--单列滚动停止回调
function CodeGameScreenWildGorillaMachine:slotOneReelDown(reelCol)
    BaseNewReelMachine.slotOneReelDown(self, reelCol)
    self:playSymbolBuling(reelCol)
    self:playWildTriggerEffect(reelCol)
end

--添加金边
function CodeGameScreenWildGorillaMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    --三种长滚 做了三个动画
    local runName = "run"
    if self.m_iNowRow == 5 then
        runName = "run1"
    elseif self.m_iNowRow == 6 then
        runName = "run2"
    end
    util_csbPlayForKey(reelAct, runName, true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenWildGorillaMachine:playSymbolBuling(reelCol)
    local rowNum = 4
    if reelCol > 2 then
        rowNum = self.m_iNowRow
    end
    local bonusNum = 0
    for iRow = rowNum, 2, -1 do
        local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if targSp then
            local symbolType = targSp.p_symbolType
            if self:isBonusSymbolByType(symbolType) then
                if self:isNeedPlayBonusBuling(reelCol) then
                    self:addBonusSymbolFrame(targSp)
                    targSp:runAnim("buling")
                    bonusNum = bonusNum + 1
                --添加bonus遮罩框
                end
            elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self.m_scatterNum = self.m_scatterNum + 1
                if reelCol <= 3 or (self.m_scatterNum >= 2 and reelCol == 4) or (self.m_scatterNum > 2 and reelCol > 4) then
                    targSp = self:setSymbolToClipReel(reelCol, iRow, symbolType)
                    targSp:runAnim("buling")

                    local soundPath = "WildGorillaSounds/sound_WildGorilla_Scatter_ground.mp3"
                    if self.playBulingSymbolSounds then
                        self:playBulingSymbolSounds( reelCol,soundPath )
                    else
                        gLobalSoundManager:playSound(soundPath)
                    end
                    
                end
            elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                --只在freespin下变化 只出现在前两列
                if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE and reelCol <= 2 then
                    self:changeWildSymbol(reelCol)
                else
                    self.m_wildNum = self.m_wildNum + 1
                    if self.m_wildNum == reelCol then
                        self:setSymbolToClipReel(reelCol, iRow, symbolType)
                        targSp:runAnim("buling")

                        local soundPath = "WildGorillaSounds/sound_WildGorilla_wild_ground.mp3"
                        if self.playBulingSymbolSounds then
                            self:playBulingSymbolSounds( reelCol,soundPath )
                        else
                            gLobalSoundManager:playSound(soundPath)
                        end

                    end
                end
            end
        end
    end
    if bonusNum > 0 then

        local soundPath = "WildGorillaSounds/sound_WildGorilla_bonus_ground.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end
end

--添加bonus遮罩框
function CodeGameScreenWildGorillaMachine:addBonusSymbolFrame(_targSp)
    local symbolFrame = util_createAnimation("WildGorilla_bonusidle.csb")
    local slotParent = _targSp:getParent()
    local posWorld = slotParent:convertToWorldSpace(cc.p(_targSp:getPositionX(), _targSp:getPositionY()))
    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
    self.m_clipParent:addChild(symbolFrame, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    symbolFrame:setPosition(cc.p(pos.x, pos.y))
    symbolFrame:runCsbAction(
        "start",
        false,
        function()
            symbolFrame:runCsbAction("idle", true)
        end
    )
    self.m_bonusSymBolFrameList[#self.m_bonusSymBolFrameList + 1] = symbolFrame
end

function CodeGameScreenWildGorillaMachine:isNeedPlayBonusBuling(_col)
    local isHave = false
    if self:isTriggerAddRow() then
        local iRow = self.m_iNowRow
        for iCol = 3, _col do
            isHave = false
            for row = 2, iRow do
                local symbolType = self:getSymbolTypeForNetData(iCol, row)
                if self:isBonusSymbolByType(symbolType) then
                    isHave = true
                end
            end
            if isHave == false then
                break
            end
        end
    end
    return isHave
end

function CodeGameScreenWildGorillaMachine:isWildSymbolType(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD_2 or symbolType == self.SYMBOL_WILD_3 or symbolType == self.SYMBOL_WILD_5 then
        return true
    end
    return false
end

--升轮需在第二列停止后播放效果
function CodeGameScreenWildGorillaMachine:playWildTriggerEffect(reelCol)
    if self.m_bAddRow and reelCol == 2 then
        gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_wild_trigger.mp3")
        self.m_bonusTriSoundsId = gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_trigger_bonus.mp3")
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        self.m_reelFire:setVisible(true)
        util_spinePlay(self.m_daXingXing, "actionframe", true)
        self.m_reelFire:runCsbAction(
            "idleframe",
            false,
            function()
                if self.m_iAddShowRow > 3 then
                    print("CodeGameScreenWildGorillaMachine==============================3_" .. self.m_iAddShowRow)
                    self:runCsbAction("3_" .. self.m_iAddShowRow)
                    if self.m_iAddShowRow == 4 then
                        gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_fire3to4.mp3")
                    else
                        gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_fire3to5.mp3")
                    end
                    self:changeReelLength(1, self.m_iAddShowRow)
                    self:playLogoShowOrHide(
                        "over",
                        function()
                            self.m_Logo:setVisible(false)
                        end
                    )
                    print("CodeGameScreenWildGorillaMachine ==============================上升")

                    self.m_reelFire:runCsbAction(
                        "3_" .. self.m_iAddShowRow,
                        false,
                        function()
                            self.m_reelFire:runCsbAction("idle" .. self.m_iAddShowRow, true)
                        end
                    )
                else
                    self.m_reelFire:runCsbAction("idle3", true)
                end
            end
        )
    elseif self.m_bAddRow and reelCol == 4 then
        self:setMaxMusicBGVolume()
        if self.m_bonusTriSoundsId then
            gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_bonus_over.mp3")
            gLobalSoundManager:stopAudio(self.m_bonusTriSoundsId)
            self.m_bonusTriSoundsId = nil
        end
    elseif self.m_bAddRow and reelCol == 5 then
        if self.m_iAddShowRow > 3 then
            self.m_reelFire:runCsbAction(self.m_iAddShowRow .. "over", false)
        else
            self.m_reelFire:runCsbAction("3over", false)
        end

        util_spinePlay(self.m_daXingXing, "idleframe", true)
    end
end

--freespin下wild 变为x2,x3,x5
function CodeGameScreenWildGorillaMachine:changeWildSymbol(reelCol)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.wildMultiple then
        local rowNum = 4
        for iRow = 2, rowNum do
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    local changeType = self:getChangeWildType()
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, changeType), changeType)
                    self:setSymbolToClipReel(reelCol, iRow, symbolType)
                    self.m_wildNum = self.m_wildNum + 1
                    targSp:runAnim("buling", false)
                    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_wild_ground.mp3")
                end
            end
        end
    end
end

function CodeGameScreenWildGorillaMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder

        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        --bonus 特殊处理
        local preX = targSp:getPositionX()
        local preY = targSp:getPositionY()
        local preLayerTag = targSp.p_layerTag
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        if self:isBonusSymbolByType(_type) or _type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            targSp.p_preParent = slotParent
            targSp.p_preX = preX
            targSp.p_preY = preY
            targSp.p_preLayerTag = preLayerTag
        end
        local linePos = {}
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = true
        targSp:setLinePos(linePos)
    end
    return targSp
end

--获取wild变换类型
function CodeGameScreenWildGorillaMachine:getChangeWildType()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.wildMultiple then
        if selfData.wildMultiple == 2 then
            return self.SYMBOL_WILD_2
        elseif selfData.wildMultiple == 3 then
            return self.SYMBOL_WILD_3
        elseif selfData.wildMultiple == 5 then
            return self.SYMBOL_WILD_5
        end
    end
end
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWildGorillaMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    self:playLogoShowOrHide(
        "over",
        function()
            self.m_Logo:setVisible(false)
        end
    )
    self.m_daXingXing:setVisible(true)
    gLobalNoticManager:postNotification(
        ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,
        "free",
        false,
        function()
            local par1 = self.m_gameBg:findChild("lizi1")
            local par2 = self.m_gameBg:findChild("lizi2")
            par1:setPositionType(0)
            par1:resetSystem()
            par2:setPositionType(0)
            par2:resetSystem()
        end
    )
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWildGorillaMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    self.m_Logo:setVisible(true)
    self:playLogoShowOrHide("show")
    self.m_daXingXing:setVisible(false)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "base")
end
---------------------------------------------------------------------------

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenWildGorillaMachine:showFreeSpinView(effectData)
    self:stopLinesWinSound()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_tips_show.mp3")
            local view =
                self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
            local normalNode = view:findChild("texi_2")
            local superNode = view:findChild("texi_4")
            if selfData.triggerSupperFree then
                normalNode:setVisible(false)
                superNode:setVisible(true)
            else
                normalNode:setVisible(true)
                superNode:setVisible(false)
            end
        else
            self.m_guochang:setVisible(true)
            gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_guochang_close.mp3")
            self:playTransitionEffect(
                "actionframe",
                function()
                    util_spinePlay(self.m_guochang, "idleframe", true)
                    self.m_fsTip:setVisible(false)
                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                    self:showFreeSpinBar()
                    if selfData.triggerSupperFree then
                        self.m_bottomUI:showAverageBet()
                        self.m_baseFreeSpinBar:runCsbAction("idle1")
                        if selfData.avgBet and selfData.avgBet > 0 then
                            self.m_avgBet = selfData.avgBet
                        end
                    else
                        self.m_baseFreeSpinBar:runCsbAction("idle2")
                    end
                    self:levelFreeSpinEffectChange()
                end
            )
            gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_tips_show.mp3")
            local view =
                self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                function()
                    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_guochang_open.mp3")
                    self:playTransitionEffect(
                        "actionframe2",
                        function()
                            self.m_guochang:setVisible(false)
                        end
                    )
                end
            )
        end
    end
    self:playScatterTrigger()
    --  延迟
    performWithDelay(
        self,
        function()
            if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                showFSView()
            else
                if selfData.triggerFreeGame then
                    local num = selfData.triggerFreeGame
                    self.m_fsTip:updataFreeSpinCount(num)
                end
                performWithDelay(
                    self,
                    function()
                        showFSView()
                    end,
                    1.5
                )
            end
        end,
        3.5
    )
end

function CodeGameScreenWildGorillaMachine:showFreeSpinStart(num, func, startfun)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local FreeSpinStartStr = "WildGorilla/FreeSpinStart.csb"
    if selfData.triggerSupperFree then
        FreeSpinStartStr = "WildGorilla/SuperFreeSpinStart.csb"
    end
    local view = util_createView("CodeWildGorillaSrc.WildGorillaFreeSpinStart", {csbName = FreeSpinStartStr, fsCounts = num})
    view:setFunCall(func, startfun)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)

    return view
end

function CodeGameScreenWildGorillaMachine:playScatterTrigger()
    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_FreeSpin_trigger.mp3")
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 2, self.m_iNowRow do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    targSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if not targSp then
                        targSp = self:setSymbolToClipReel(iCol, iRow, symbolType)
                    end
                    targSp:runAnim("actionframe", false)
                end
            end
        end
    end
end

function CodeGameScreenWildGorillaMachine:showFreeSpinOverView()
    self:stopLinesWinSound()
    --过场
    self.m_guochang:setVisible(true)
    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_guochang_close.mp3")
    self:playTransitionEffect(
        "actionframe",
        function()
            util_spinePlay(self.m_guochang, "idleframe", true)
            self:hideFreeSpinBar()
            self:levelFreeSpinOverChangeEffect()
            self:changeNormalReel()
            self.m_fsTip:setVisible(true)
            self.m_bottomUI:hideAverageBet()
        end
    )
    --显示弹板
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_freespin_over.mp3")
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:triggerFreeSpinOverCallFun()
        end,
        function()
            gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_guochang_open.mp3")
            self:playTransitionEffect(
                "actionframe2",
                function()
                    self.m_guochang:setVisible(false)
                end
            )
        end
    )
    local normalNode = view:findChild("texi_2")
    local superNode = view:findChild("texi_3")
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.triggerSupperFree then
        normalNode:setVisible(false)
        superNode:setVisible(true)
        self.m_fsTip:resetFreeSpinCount()
    else
        normalNode:setVisible(true)
        superNode:setVisible(false)
    end
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 560)
end

function CodeGameScreenWildGorillaMachine:showFreeSpinOver(strCoins, num, func, startfun)
    local view = util_createView("CodeWildGorillaSrc.WildGorillaFreeSpinOver", {coins = strCoins, fsCounts = num})
    view:setFunCall(func, startfun)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function() return false end
    end
    gLobalViewManager:showUI(view)

    return view
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWildGorillaMachine:MachineRule_SpinBtnCall()
    self.m_fsTip:hideTips()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    self:stopLinesWinSound()
    for i = 1, #self.m_bonusSymBolFrameList do
        local frame = self.m_bonusSymBolFrameList[i]
        frame:removeFromParent()
    end
    self.m_bonusSymBolFrameList = {}
    self.m_scatterNum = 0
    self.m_wildNum = 0
    self.m_nowBottomCoins = 0
    return false -- 用作延时点击spin调用
end

function CodeGameScreenWildGorillaMachine:slotReelDown()
    BaseNewReelMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenWildGorillaMachine:playEffectNotifyNextSpinCall()
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenWildGorillaMachine:getBaseReelGridNode()
    return "CodeWildGorillaSrc.WildGorillaSlotsNode"
end

function CodeGameScreenWildGorillaMachine:isBonusSymbolByType(symbolType)
    if
        self.SYMBOL_BONUS_LINK == symbolType or self.SYMBOL_BONUS_MINI == symbolType or self.SYMBOL_BONUS_MINOR == symbolType or self.SYMBOL_BONUS_MAJOR == symbolType or
            self.SYMBOL_BONUS_GRAND == symbolType
     then
        return true
    end
    return false
end

-- 添加关卡中触发的玩法
function CodeGameScreenWildGorillaMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.hasBonusWin then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BONUS_WIN_EFFECT
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWildGorillaMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.BONUS_WIN_EFFECT then
        self:playShowBonusWinEffect(effectData)
    end
    return true
end

--bonus 收集赢钱效果
function CodeGameScreenWildGorillaMachine:playShowBonusWinEffect(effectData)
    self.m_effectData = effectData
    --获取bonus数据
    self.m_collectList = {}
    local isHave = false
    for iCol = 3, self.m_iReelColumnNum do
        isHave = false
        for iRow = self.m_iNowRow, 2, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                local symbolType = node.p_symbolType
                if self:isBonusSymbolByType(symbolType) then
                    local nodeData = {}
                    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                    local reelsIndex = self:getPosReelIdx(iRow, iCol)
                    local winCoins = self:getWinCoinsNum(reelsIndex)
                    nodeData.startPos = startPos
                    nodeData.symbolType = symbolType
                    nodeData.node = node
                    nodeData.winCoins = winCoins
                    self.m_collectList[#self.m_collectList + 1] = nodeData
                    isHave = true
                end
            end
        end
        if isHave == false then
            break
        end
    end
    --初始化 数据
    if self.m_bProduceSlots_InFreeSpin == true then --如果在freespin里有赢钱线
        self.m_nowBottomCoins = globalData.slotRunData.lastWinCoin - self.m_runSpinResultData.p_winAmount
    else
        self.m_nowBottomCoins = 0
    end
    self.m_playAnimIndex = 1
    --开始收集
    scheduler.performWithDelayGlobal(
        function()
            self:playCollectAnim()
        end,
        1,
        self:getModuleName()
    )
end

function CodeGameScreenWildGorillaMachine:isJackpotType(symbolType)
    if self.SYMBOL_BONUS_MINI == symbolType or self.SYMBOL_BONUS_MINOR == symbolType or self.SYMBOL_BONUS_MAJOR == symbolType or self.SYMBOL_BONUS_GRAND == symbolType then
        return true
    end
    return false
end

function CodeGameScreenWildGorillaMachine:playCollectAnim()
    if self.m_playAnimIndex > #self.m_collectList then
        return
    end
    local data = self.m_collectList[self.m_playAnimIndex]
    local startPos = data.startPos
    local winCoins = data.winCoins
    local endWorldPos = self.m_bottomUI:getCoinWinNode():getParent():convertToWorldSpace(cc.p(self.m_bottomUI:getCoinWinNode():getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
    local node = data.node
    local frame = self.m_bonusSymBolFrameList[self.m_playAnimIndex]
    frame:setVisible(false)

    --变暗
    if not tolua.isnull(node) then
        node = self:setSymbolToClipReel(node.p_cloumnIndex, node.p_rowIndex, node.p_symbolType)
        node:changeBonusLabParent()
        node:runAnim("jiesuan", false)
    end

    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_bonus_collect.mp3")
    if self:isJackpotType(node.p_symbolType) then
        scheduler.performWithDelayGlobal(
            function()
                self:showBonusWinJackpot(node.p_symbolType, winCoins)
            end,
            0.5,
            self:getModuleName()
        )
    else
        -- 添加飞行轨迹
        local effectLabel = self:ceateParticleEffect(winCoins)
        effectLabel:setScale(self.m_machineRootScale)
        effectLabel:setPosition(startPos.x, startPos.y)
        self:addChild(effectLabel, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
        local action_time = 12 / 30
        local delay = cc.DelayTime:create(11 / 30)
        local action = cc.MoveTo:create(action_time, cc.p(endPos.x, endPos.y + 25))
        local call_set =
            cc.CallFunc:create(
            function(sender)
                scheduler.performWithDelayGlobal(
                    function()
                        sender:removeFromParent()
                    end,
                    4 / 30,
                    self:getModuleName()
                )
                self:updataBottomCoins(winCoins)
            end
        )
        local seq = cc.Sequence:create(delay, action, call_set)
        effectLabel:runAction(seq)
        scheduler.performWithDelayGlobal(
            function()
                self:playNextBonusCollect()
            end,
            20 / 30,
            self:getModuleName()
        )
    end
end

function CodeGameScreenWildGorillaMachine:ceateParticleEffect(_coins)
    local effectLabel = util_createAnimation("WildGorilla_Bonus_collect.csb")
    local particle1 = effectLabel:findChild("Particle_1")
    local lab = effectLabel:findChild("BitmapFontLabel_5")
    num = util_formatCoins(_coins, 3)
    lab:setString(num)
    particle1:setPositionType(0)
    particle1:setDuration(1)
    effectLabel:runCsbAction("jiesuanfei")
    return effectLabel
end

function CodeGameScreenWildGorillaMachine:showBonusWinJackpot(_jackPotType, _winCoins)
    local jackPotType = _jackPotType
    local coins = _winCoins
    self:showJackpotWin(
        jackPotType,
        coins,
        function()
            self:updataBottomCoins(_winCoins)
            self:playNextBonusCollect()
        end
    )
end

--刷洗底部赢钱
function CodeGameScreenWildGorillaMachine:updataBottomCoins(_winCoins)
    self:playCoinWinEffectUI()
    self.m_nowBottomCoins = self.m_nowBottomCoins + _winCoins
    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_nowBottomCoins))
end

--播放bonus 收集效果
function CodeGameScreenWildGorillaMachine:playNextBonusCollect()
    if self.m_playAnimIndex == #self.m_collectList then
        scheduler.performWithDelayGlobal(
            function()
                if self.m_effectData then
                    self.m_effectData.p_isPlay = true
                    self:playGameEffect()
                    self.m_effectData = nil
                end
            end,
            0.5,
            self:getModuleName()
        )
        return
    end
    self.m_playAnimIndex = self.m_playAnimIndex + 1
    self:playCollectAnim()
end

function CodeGameScreenWildGorillaMachine:getPosReelIdx(iRow, iCol)
    local index = (self.m_iReelMaxRow - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

--获取bonus对应点数
function CodeGameScreenWildGorillaMachine:getPointNum(reelsIndex)
    local num = 1
    local storeIcons = self.m_runSpinResultData.p_storedIcons
    if storeIcons and type(storeIcons) == "table" then
        for k, v in pairs(storeIcons) do
            local data = v
            if reelsIndex == data[1] then
                num = data[2]
                break
            end
        end
    end
    return num
end

--获取bonus对应点数
function CodeGameScreenWildGorillaMachine:getWinCoinsNum(reelsIndex)
    local winNum = 1
    local iconWin = self.m_runSpinResultData.p_selfMakeData.iconWin
    if iconWin and type(iconWin) == "table" then
        for k, v in pairs(iconWin) do
            local data = v
            if reelsIndex == data[1] then
                winNum = data[2]
                break
            end
        end
    end
    return winNum
end

-- 处理spin 返回结果
function CodeGameScreenWildGorillaMachine:checkOperaSpinSuccess(param)
    if param[1] == true then
        local spinData = param[2]
        
        local freeGameCost = spinData.freeGameCost
        if freeGameCost then
            self.m_rewaedFSData = freeGameCost
        end

        if spinData.action == "SPIN" then
            release_print("消息返回胡来了")

            self:operaSpinResultData(param)

            self:operaUserInfoWithSpinResult(param)

            self:setChangeReelRowInfo()

            dump(self.m_runSpinResultData.p_reels)
            self:updateNetWorkData()
            --如果有升行 不可点快停
            if self.m_bAddRow then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            end
            gLobalNoticManager:postNotification("TopNode_updateRate")
        end
    end
end

--获取改变行数的数据
function CodeGameScreenWildGorillaMachine:setChangeReelRowInfo()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.hasWild and selfData.showRows then
        local maxRow = 3
        for i, v in ipairs(selfData.showRows) do
            if v > maxRow then
                maxRow = v
            end
        end
        self.m_bAddRow = true
        self.m_iAddShowRow = maxRow
        if maxRow == 4 then
            self.m_iNowRow = 5
        elseif maxRow == 5 then
            self.m_iNowRow = 6
        end
    end

end

--升行处理
function CodeGameScreenWildGorillaMachine:changeReelLength(direction, _addRow)
    for i = 3, self.m_iReelColumnNum do
        self:changeReelRowNum(i, self.m_iReelMaxRow, true)
    end
    for i = 3, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelMaxRow
        columnData:updateShowColCount(self.m_iReelMaxRow)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelMaxRow
    end

    local endHeight
    if direction > 0 then
        direction = 1
        local _row = _addRow
        endHeight = _row * self.m_SlotNodeH + self.m_ReelOffY
    else
        direction = -1
        endHeight = self.m_iNormalRow * self.m_SlotNodeH + self.m_ReelOffY * 2 + 2
    end

    local hightNode = self:findChild("topNode")
    local bottomNode = self:findChild("bottomNode")
    local posBY = bottomNode:getPositionY()
    if self.m_updateReelHeightID then
        scheduler.unscheduleGlobal(self.m_updateReelHeightID)
        self.m_updateReelHeightID = nil
    end
    self.m_updateReelHeightID =
        scheduler.scheduleUpdateGlobal(
        function(delayTime)
            local distance = 0
            local posHY = hightNode:getPositionY()
            local hight = posHY - posBY
            if direction > 0 then
                if hight >= endHeight then
                    hight = endHeight
                    scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                end
            else
                if hight <= endHeight then
                    hight = endHeight
                    scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                end
            end
            for i = 3, 5 do
                local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + i)
                local rect = clipNode:getClippingRegion()
                clipNode:setClippingRegion(
                    {
                        x = rect.x,
                        y = rect.y,
                        width = rect.width,
                        height = hight
                    }
                )
            end
        end
    )

end

function CodeGameScreenWildGorillaMachine:beginReel()
    self:changeNormalReel()
    BaseNewReelMachine.beginReel(self)
end

--轮盘切换 变回 3x5
function CodeGameScreenWildGorillaMachine:changeNormalReel()
    if self.m_bAddRow then
        self.m_waitChangeReelTime = 1
        self:resetScatterLayer()
        self:clearWinLineEffect()
        self:changeReelLength(-1)

        self.m_reelFire:setVisible(false)
        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            if not self.m_Logo:isVisible() then
                self.m_Logo:setVisible(true)
                self:playLogoShowOrHide("show")
            end
        end
        -- print("CodeGameScreenWildGorillaMachine ==============================下降")
        local str = self.m_iAddShowRow .. "_3"
        self.m_bAddRow = false
        self.m_iNowRow = 4
        self:runCsbAction(
            str,
            false,
            function()
                self.m_waitChangeReelTime = nil
            end
        )

    end
end

function CodeGameScreenWildGorillaMachine:getRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = self.m_iReelMaxRow - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenWildGorillaMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
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

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        --  连线框上移
        if symPosData.iY >= 3 then
            posY = posY - columnData.p_showGridH + self.m_ReelOffY
        else
            posY = posY - columnData.p_showGridH
        end
        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

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
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
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

-- 显示所有的连线框
--
function CodeGameScreenWildGorillaMachine:showAllFrame(winLines)
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
            -- end
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen()

                local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
                local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
                --连线框上移
                if symPosData.iY >= 3 then
                    posY = posY - columnData.p_showGridH + self.m_ReelOffY
                else
                    posY = posY - columnData.p_showGridH
                end
                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(cc.p(posX, posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end

function CodeGameScreenWildGorillaMachine:showJackpotWin(jackPot, coins, func)
    gLobalSoundManager:playSound("WildGorillaSounds/sound_WildGorilla_tips_show.mp3")
    local jackPotWinView = util_createView("CodeWildGorillaSrc.WildGorillaJackPotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(jackPot, coins, func)
end

--设置长滚信息
function CodeGameScreenWildGorillaMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local wildNum = 0
    local longRunIndex = 0
    local bWildRunLong = false

    local runLongLen = 0
    for col = 1, iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        if bRunLong == true or bWildRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen
            if bWildRunLong == true then
                runLen = self:getWildLongRunLen(col, longRunIndex)
            else
                runLen = self:getLongRunLen(col, longRunIndex)
            end
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
            runLongLen = runLen
        end
        if bWildRunLong == false and col > 3 and self:isTriggerAddRow() then
            --如果bonus不连续了恢复正常滚动 不再快滚
            reelRunData:setReelRunLen(runLongLen + 12 + (col - 3) * 3)
        end
        if self:isTriggerAddRow() and col == 2 then
            --如果前两列有连续的wild 第二列滚动在原有基础上在加6
            local len = reelRunData:getReelRunLen()
            reelRunData:setReelRunLen(len + 6)
        end

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col, bonusNum, bRunLong)
        if col >= 2 then
            bWildRunLong = self:getWildEffectInfo(col, bWildRunLong)
        end
    end --end  for col=1,iColumn do
end

function CodeGameScreenWildGorillaMachine:getWildLongRunLen(col, index)
    local len = 0

    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight
    local runTime = self.m_configData.p_reelLongRunTime
    if self.m_iNowRow == 5 then
        runTime = self.m_configData.p_reelLongRunTime + 0.5
    elseif self.m_iNowRow == 6 then
        local dealyTime = 0.5
        if col == 3 then
            dealyTime = 1.0
        end
        runTime = self.m_configData.p_reelLongRunTime + dealyTime
    end

    local reelCount = (runTime * self.m_configData.p_reelLongRunSpeed) / colHeight
    len = lastColLens + math.floor(reelCount) * columnData.p_showGridCount --速度x时间 / 列高

    return len
end

--是否触发增行效果
function CodeGameScreenWildGorillaMachine:isTriggerAddRow()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.hasWild and selfData.showRows then
        return true
    end
    return false
end

function CodeGameScreenWildGorillaMachine:getWildEffectInfo(_col, _bWildLong)
    local isRunlong = false
    if self:isTriggerAddRow() then
        if _col == 2 then
            return true
        end
        for iRow = 2, self.m_iNowRow do
            local symbolType = self:getSymbolTypeForNetData(_col, iRow)
            if self:isBonusSymbolByType(symbolType) then
                isRunlong = true
            end
        end
    end
    if _col >= 3 and _bWildLong == false then
        isRunlong = false
    end
    return isRunlong
end

--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}
--设置bonus scatter 信息
function CodeGameScreenWildGorillaMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount
    if column <= 2 then
        iRow = 4
    else
        iRow = self.m_iNowRow
    end
    for row = 2, iRow do
        if self:getSymbolTypeForNetData(column, row, runLen) == symbolType then
            local bPlaySymbolAnima = bPlayAni

            allSpecicalSymbolNum = allSpecicalSymbolNum + 1

            if bRun == true then
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)
            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效

                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return allSpecicalSymbolNum, bRunLong
end

--设置bonus scatter 层级
function CodeGameScreenWildGorillaMachine:getBounsScatterDataZorder(symbolType)
    local order = 0
    order = BaseNewReelMachine.getBounsScatterDataZorder(self, symbolType)
    if self:isBonusSymbolByType(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10
    end
    return order
end

--设置最后停止的小块上bonus对应的点数
function CodeGameScreenWildGorillaMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType

    if self:isBonusSymbolByType(symbolType) then
        local callFun =
            cc.CallFunc:create(
            function()
                node:createBonusLab()
                if symbolType == self.SYMBOL_BONUS_LINK then
                    self:setSpecialNodeScore(nil, {node})
                end
            end,
            {node}
        )
        self:runAction(callFun)
    end
end

-- 给respin小块进行赋值
function CodeGameScreenWildGorillaMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local totalBet = globalData.slotRunData:getCurTotalBet()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if selfData and selfData.triggerFreeGame and selfData.triggerFreeGame == 5 then
            if selfData.avgBet and selfData.avgBet > 0 then
                totalBet = selfData.avgBet --Average
            end
        end
    end
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
            score = score * totalBet
            score = util_formatCoins(score, 3)
            if symbolNode then
                symbolNode:setBonusLabNum(score)
                symbolNode:runAnim("idleframe")
            end
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil then
                if score == nil then
                    score = 1
                end
                score = score * totalBet
                score = util_formatCoins(score, 3)
                if symbolNode then
                    symbolNode:setBonusLabNum(score)
                end
            end
        end
    end
end

function CodeGameScreenWildGorillaMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_BONUS_LINK then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenWildGorillaMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil

    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    if score == nil then
        score = self.m_configData:getFixSymbolPro()
    end
    return score
end

function CodeGameScreenWildGorillaMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    if self.m_nowBottomCoins > 0 then
        if self.m_bProduceSlots_InFreeSpin == true then
            self.m_iOnceSpinLastWin = globalData.slotRunData.lastWinCoin - self.m_nowBottomCoins
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop, true, self.m_nowBottomCoins})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

function CodeGameScreenWildGorillaMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end
    local symbolType = slotNode.p_symbolType

    if self:isBonusSymbolByType(symbolType) and nodeParent == self.m_clipParent then
        --数字也要换层级
        local showOrder = self:getBounsScatterDataZorder(symbolType) - slotNode.p_rowIndex
        slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + showOrder + 20)
        slotNode:changeBonusLabParent(1)
    else
        slotNode.p_preParent = nodeParent
        slotNode.p_preX = slotNode:getPositionX()
        slotNode.p_preY = slotNode:getPositionY()
        if nodeParent == self.m_clipParent then
            slotNode.p_showOrder = self:getClipParentChildShowOrder(slotNode)
        else
            slotNode.p_showOrder = slotNode:getLocalZOrder()
        end

        slotNode.p_preLayerTag = slotNode.p_layerTag

        local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
        pos = self.m_clipParent:convertToNodeSpace(pos)
        slotNode:setPosition(pos.x, pos.y)
        util_changeNodeParent(self.m_clipParent, slotNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    end

    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

function CodeGameScreenWildGorillaMachine:resetScatterLayer()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 2, self.m_iNowRow do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                local symbolType = targSp.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local preParent = targSp.p_preParent
                    if preParent ~= nil and preParent ~= self.m_clipParent then
                        targSp.p_layerTag = targSp.p_preLayerTag
                        local nZOrder = targSp.p_showOrder
                        util_changeNodeParent(preParent, targSp, nZOrder)
                        targSp:setPosition(targSp.p_preX, targSp.p_preY)
                    end
                end
            end
        end
    end
end

function CodeGameScreenWildGorillaMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                local symbolType = lineNode.p_symbolType
                if self:isBonusSymbolByType(symbolType) then
                    if preParent ~= lineNode:getParent() then
                        util_changeNodeParent(preParent, lineNode, nZOrder)
                        lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                    end
                    --bonus 字切换父节点
                    if self:isBonusSymbolByType(symbolType) then
                        lineNode:changeBonusLabParent()
                    end
                else
                    util_changeNodeParent(preParent, lineNode, nZOrder)
                    lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                end

                lineNode:runIdleAnim()
            end
        end
    end
end

function CodeGameScreenWildGorillaMachine:initGameStatusData(gameData)
    BaseNewReelMachine.initGameStatusData(self, gameData)
    self.m_avgBet = 0
    if param and param[1] then
        local spinData = param[2]
        if spinData.result then
            if spinData.result then
                if spinData.result.avgBet then
                    self.m_avgBet = spinData.result.avgBet
                end
            end
        end
    end
end
---
-- 处理spin 返回结果
function CodeGameScreenWildGorillaMachine:spinResultCallFun(param)
    BaseNewReelMachine.spinResultCallFun(self, param)

    self.m_avgBet = 0
    if param and param[1] then
        local spinData = param[2]
        if spinData.result then
            if spinData.result then
                if spinData.result.avgBet then
                    self.m_avgBet = spinData.result.avgBet
                end
            end
        end
    end
end

--jakpot 切换使用平均bet
function CodeGameScreenWildGorillaMachine:BaseMania_updateJackpotScore(index, totalBet)
    if not totalBet then
        totalBet = globalData.slotRunData:getCurTotalBet()
    end

    if self.m_avgBet ~= 0 then
        totalBet = self.m_avgBet
    end

    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] then
        return 0
    end
    local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index], true, totalBet)

    return totalScore
end

return CodeGameScreenWildGorillaMachine
