---
-- xcyy
-- 2018-12-18
-- HalosandHornsFsMiniMachine.lua
--
--
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local HalosandHornsFsMiniMachine = class("HalosandHornsFsMiniMachine", BaseSlotoManiaMachine)

HalosandHornsFsMiniMachine.m_baseReelRestRow = 3
HalosandHornsFsMiniMachine.m_currentReelRow = {5, 4, 3, 4, 6}
HalosandHornsFsMiniMachine.m_LinesReelRow = {5, 4, 3, 4, 6}
HalosandHornsFsMiniMachine.m_columnMaxReward = {"8", "30", "GRAND", "15", "6"}
HalosandHornsFsMiniMachine.m_columnMaxGame = {1, 1, 1, 1, 1}

HalosandHornsFsMiniMachine.DECLINE_REEL_COL_1_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 90
HalosandHornsFsMiniMachine.DECLINE_REEL_COL_2_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 89
HalosandHornsFsMiniMachine.DECLINE_REEL_COL_3_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 88
HalosandHornsFsMiniMachine.DECLINE_REEL_COL_4_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 87
HalosandHornsFsMiniMachine.DECLINE_REEL_COL_5_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 86

HalosandHornsFsMiniMachine.SYMBOL_ANGEL_10 = 9
HalosandHornsFsMiniMachine.SYMBOL_ANGEL_11 = 10
HalosandHornsFsMiniMachine.SYMBOL_ANGEL_12 = 11
HalosandHornsFsMiniMachine.SYMBOL_ANGEL_13 = 12
HalosandHornsFsMiniMachine.SYMBOL_ANGEL_14 = 13

HalosandHornsFsMiniMachine.SYMBOL_DEVIL_RISE = 94
HalosandHornsFsMiniMachine.SYMBOL_ANGEL_DECLINE = 95

HalosandHornsFsMiniMachine.m_reelBgBeginPercent = 33
HalosandHornsFsMiniMachine.m_reelBGAddPercent = math.floor(100 / 9)

HalosandHornsFsMiniMachine.m_reelJianTou_BeginPosY = 785
HalosandHornsFsMiniMachine.m_reelianTou_AddPosY = -80

HalosandHornsFsMiniMachine.m_reelJianTouBG_BeginPosY = 791
HalosandHornsFsMiniMachine.m_reelJianTouBG_AddPosY = -80

local reelClipAddSizeY = 38 -- 裁切轮子多出来多少px

HalosandHornsFsMiniMachine.m_clipNode_BeginSizeY = 240 + reelClipAddSizeY
HalosandHornsFsMiniMachine.m_clipNode_AddSizeY = 80

HalosandHornsFsMiniMachine.m_clipNode_BeginPosY = 824 - reelClipAddSizeY
HalosandHornsFsMiniMachine.m_clipNode_AddPosY = -80

HalosandHornsFsMiniMachine.m_clipControlNode_AddSizeY = 80
HalosandHornsFsMiniMachine.m_clipControlNode_BeginPosY = -1 + reelClipAddSizeY

HalosandHornsFsMiniMachine.m_maxMutilBonusTop = 10

HalosandHornsFsMiniMachine.BONUS_TOP_NODENAME = {"bonus_Node_1", "bonus_Node_2", "bonus_Node_Jp", "bonus_Node_3", "bonus_Node_4"}

HalosandHornsFsMiniMachine.BONUS_TOP_TYPE_JP = "GRAND"
HalosandHornsFsMiniMachine.BONUS_TOP_TYPE_END_GAME = "END_GAME"
HalosandHornsFsMiniMachine.BONUS_TOP_TYPE_COINS_ZI = "ZI"
HalosandHornsFsMiniMachine.BONUS_TOP_TYPE_COINS_LV = "LV"

HalosandHornsFsMiniMachine.DeclineSpeed = 0.1

HalosandHornsFsMiniMachine.ZhuZi_level_1 = 5
HalosandHornsFsMiniMachine.ZhuZi_level_2 = 6
HalosandHornsFsMiniMachine.ZhuZi_level_3 = 7

HalosandHornsFsMiniMachine.COL_1 = 1
HalosandHornsFsMiniMachine.COL_2 = 2
HalosandHornsFsMiniMachine.COL_3 = 3
HalosandHornsFsMiniMachine.COL_4 = 4
HalosandHornsFsMiniMachine.COL_5 = 5

HalosandHornsFsMiniMachine.m_top_bonus_reword_coins = 0
HalosandHornsFsMiniMachine.m_preFsWinCoins = 0

HalosandHornsFsMiniMachine.m_spinReelDownTime = 0.4

HalosandHornsFsMiniMachine.updateSpeed = 0.04

HalosandHornsFsMiniMachine.m_collectBonusPos = {} -- 播放topbonus 动画的位置

HalosandHornsFsMiniMachine.m_isOutLines = true

HalosandHornsFsMiniMachine.gameResumeFunc = nil
HalosandHornsFsMiniMachine.gameRunPause = nil
HalosandHornsFsMiniMachine.m_iReelMinRow = nil
HalosandHornsFsMiniMachine.m_iReelMaxRow = nil

HalosandHornsFsMiniMachine.m_triggerFirst = true --是否是第一次进入到升行游戏

-- 构造函数
function HalosandHornsFsMiniMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isOnceClipNode = false
    self.m_spinRestMusicBG = true
    self.m_bCreateResNode = false
    self.m_isOutLines = true

    self.m_iReelMinRow = 3
    self.m_iReelMaxRow = 9

    -- 小块，连线框，基础baseDialog弹板csb 根据实际帧率设置
    self.m_slotsAnimNodeFps = 30
    self.m_lineFrameNodeFps = 30
    self.m_baseDialogViewFps = 30

    self.m_pauseRef = 0
end

function HalosandHornsFsMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil
    self.m_machine = data.machine

    --init
    self:initGame()
end

function HalosandHornsFsMiniMachine:initGame()
    self.m_iReelMinRow = 3
    self.m_iReelMaxRow = 9

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function HalosandHornsFsMiniMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(self.m_iReelMaxRow, self.m_iReelColumnNum, TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function HalosandHornsFsMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "HalosandHorns"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function HalosandHornsFsMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function HalosandHornsFsMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ANGEL_10, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ANGEL_11, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ANGEL_12, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ANGEL_13, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ANGEL_14, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_DEVIL_RISE, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ANGEL_DECLINE, count = 2}

    return loadNode
end

---
-- 读取配置文件数据
--
function HalosandHornsFsMiniMachine:readCSVConfigData()
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelHalosandHornsFsReelConfig.lua")
    end
end

function HalosandHornsFsMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName .. "_tianshi"

    self:createCsbNode("HalosandHorns/GameScreenHalosandHorns_fg.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--[[
    @desc: 处理MINI轮子的初始化， 去掉了很多主轮子的内容
    time:2020-07-13 20:33:27
]]
function HalosandHornsFsMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()
    self.m_machineModuleName = self.m_moduleName

    self:initMachineCSB() -- 创建关卡csb信息

    self:updateBaseConfig() -- 更新关卡config.csv的配置信息
    self:updateMachineData() -- 更新滚动轮子指向、 以及更新每列的ReelColumnData
    self:initSymbolCCbNames() -- 更新最基础的信号名字
    self:initMachineData() -- 在BaseSlotoManiaMachine类里面实现

    self:drawReelArea() -- 绘制裁剪区域

    self:updateReelInfoWithMaxColumn() -- 计算最高的一列

    self:initReelEffect()

    self:slotsReelRunData(
        self.m_configData.p_reelRunDatas,
        self.m_configData.p_bInclScatter,
        self.m_configData.p_bInclBonus,
        self.m_configData.p_bPlayScatterAction,
        self.m_configData.p_bPlayBonusAction
    )

    self:initMiniReelUi()
end

function HalosandHornsFsMiniMachine:initMiniReelUi()
    self.m_jackPotBar = util_createView("CodeHalosandHornsSrc.HalosandHornsJackPotBarView", "Socre_HalosandHorns_jcakpot_4")
    self:findChild("jcakpot_Node"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)
    self.m_jackPotBar:runCsbAction("idleframe", true)

    self.m_jpBarJinBi = util_createAnimation("HalosandHorns_jcakpot_jinbi.csb")
    self.m_jackPotBar:findChild("Node_jinbi"):addChild(self.m_jpBarJinBi)
    self.m_jpBarJinBi:setVisible(false)

    self.m_jpBarAngel = util_spineCreate("Socre_HalosandHorns_jcakpot_2", true, true)
    self.m_jackPotBar:findChild("Node_Angel"):addChild(self.m_jpBarAngel)
    self.m_jpBarAngel:setVisible(false)

    self.m_jpBarAngel_1 = util_spineCreate("Socre_HalosandHorns_jcakpot_2_1", true, true)
    self.m_jackPotBar:findChild("Node_Angel_1"):addChild(self.m_jpBarAngel_1)
    self.m_jpBarAngel_1:setVisible(false)

    self.m_jpBarZi = util_createAnimation("HalosandHorns_jackpot_zi.csb")
    self.m_jackPotBar:findChild("Node_Angel_1"):addChild(self.m_jpBarZi)
    self.m_jpBarZi:setVisible(false)

    for iCol = 1, self.m_iReelColumnNum do
        self["AngelZhuZi_" .. iCol] = util_createAnimation("HalosandHorns_zhuzi_tianshi.csb")
        self:findChild("xianshu_" .. iCol):addChild(self["AngelZhuZi_" .. iCol])
        self["AngelZhuZi_" .. iCol]:runCsbAction("actionframe", true)

        self["zhizhen_tianshi_" .. iCol] = util_createAnimation("HalosandHorns_zhizhen_tianshi.csb")
        self:findChild("HalosandHorns_zhizhen_" .. iCol):addChild(self["zhizhen_tianshi_" .. iCol])
        self["zhizhen_tianshi_" .. iCol]:runCsbAction("idle", true)
        self:findChild("HalosandHorns_zhizhen_" .. iCol):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)

        self["m_updateReelBgNode_" .. iCol] = cc.Node:create()
        self:addChild(self["m_updateReelBgNode_" .. iCol])

        self["m_updateReelAniDeclineNode_" .. iCol] = cc.Node:create()
        self:addChild(self["m_updateReelAniDeclineNode_" .. iCol])
    end

    self:initReelUIPos()

    self:initBonusTopSymbol()
    self:findChild("HalosandHorns_wing_2_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    self:findChild("HalosandHorns_wing_2_2"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    self:findChild("jcakpot_Node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)

    self:restBonusTopZorder()
end

function HalosandHornsFsMiniMachine:restBonusTopZorder()
    for iCol = 1, self.m_iReelColumnNum do
        local nodeName = self.BONUS_TOP_NODENAME
        local parentTopNode = self:findChild(nodeName[iCol])
        parentTopNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 109 + iCol)
    end
end

function HalosandHornsFsMiniMachine:initMachineData()
    self:BaseMania_initCollectDataList()
    self.m_spinResultName = self.m_moduleName .. "_Datas"
    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()
    self:checkHasBigSymbol()
end

function HalosandHornsFsMiniMachine:normalSpinBtnCall()
end
function HalosandHornsFsMiniMachine:spinResultCallFun(param)
end
function HalosandHornsFsMiniMachine:calculateLastWinCoin()
end
function HalosandHornsFsMiniMachine:setCurrSpinMode(spinMode)
    self.m_currSpinMode = spinMode
end
function HalosandHornsFsMiniMachine:getCurrSpinMode()
    return self.m_currSpinMode
end
function HalosandHornsFsMiniMachine:setGameSpinStage(spinStage)
    self.m_currSpinStage = spinStage
end
function HalosandHornsFsMiniMachine:getGameSpinStage()
    return self.m_currSpinStage
end
function HalosandHornsFsMiniMachine:setLastWinCoin(winCoin)
    self.m_lastWinCoin = winCoin
end
function HalosandHornsFsMiniMachine:getLastWinCoin()
    return self.m_lastWinCoin
end
function HalosandHornsFsMiniMachine:reelDownNotifyChangeSpinStatus()
end
function HalosandHornsFsMiniMachine:enterGamePlayMusic()
    -- do nothing
end
function HalosandHornsFsMiniMachine:changeFreeSpinModeStatus()
    -- do nothing  mini 轮子不处理 freespin 的状态
end
function HalosandHornsFsMiniMachine:playEffectNotifyNextSpinCall()
end
function HalosandHornsFsMiniMachine:checkAddQuestDoneEffectType()
end
----------------------------- 玩法处理 -----------------------------------

function HalosandHornsFsMiniMachine:getSelfEffetZOrder(_iCol, _zoder)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local columnRow = fsExtraData.columnRows

    local endRow = columnRow[_iCol]
    local rewordType = self.m_columnMaxReward[_iCol]
    local zoder = _zoder

    return zoder
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function HalosandHornsFsMiniMachine:addSelfEffect()
    self.m_triggerFirst = true

    self.m_AniColNum = 0
    self.m_AniCurrNum = 0

    local pre = self.m_preFsWinCoins or 0
    self.m_top_bonus_reword_coins = pre

    self.m_updateSpecialCoins = false

    -- 结算顺序，由左向右结算钱，然后结算jackpot，最后结算bonus
    -- 信号触发的bonus，不会和顶部触发的bonus，同时触发

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local up = fsExtraData.up or {}
    local upRows = up.upRows or {0, 0, 0, 0, 0}
    if upRows[self.COL_1] ~= 0 then
        self.m_AniColNum = self.m_AniColNum + 1
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self:getSelfEffetZOrder(1, self.DECLINE_REEL_COL_1_EFFECT)
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.DECLINE_REEL_COL_1_EFFECT
    end

    if upRows[self.COL_2] ~= 0 then
        self.m_AniColNum = self.m_AniColNum + 1
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self:getSelfEffetZOrder(2, self.DECLINE_REEL_COL_2_EFFECT)
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.DECLINE_REEL_COL_2_EFFECT
    end

    if upRows[self.COL_3] ~= 0 then
        self.m_AniColNum = self.m_AniColNum + 1
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self:getSelfEffetZOrder(3, self.DECLINE_REEL_COL_3_EFFECT)
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.DECLINE_REEL_COL_3_EFFECT
    end

    if upRows[self.COL_4] ~= 0 then
        self.m_AniColNum = self.m_AniColNum + 1
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self:getSelfEffetZOrder(4, self.DECLINE_REEL_COL_4_EFFECT)
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.DECLINE_REEL_COL_4_EFFECT
    end

    if upRows[self.COL_5] ~= 0 then
        self.m_AniColNum = self.m_AniColNum + 1
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self:getSelfEffetZOrder(5, self.DECLINE_REEL_COL_5_EFFECT)
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.DECLINE_REEL_COL_5_EFFECT
    end
end

function HalosandHornsFsMiniMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.DECLINE_REEL_COL_1_EFFECT then
        self:playDeclineReelCol(effectData, self.COL_1)
    elseif effectData.p_selfEffectType == self.DECLINE_REEL_COL_2_EFFECT then
        self:playDeclineReelCol(effectData, self.COL_2)
    elseif effectData.p_selfEffectType == self.DECLINE_REEL_COL_3_EFFECT then
        self:playDeclineReelCol(effectData, self.COL_3)
    elseif effectData.p_selfEffectType == self.DECLINE_REEL_COL_4_EFFECT then
        self:playDeclineReelCol(effectData, self.COL_4)
    elseif effectData.p_selfEffectType == self.DECLINE_REEL_COL_5_EFFECT then
        self:playDeclineReelCol(effectData, self.COL_5)
    end

    return true
end

function HalosandHornsFsMiniMachine:getOneAniSymbol(_iCol, _iRow)
    local slotNode = nil
    if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[_iCol] ~= nil then
        local isBigSymbol = false
        local bigSymbolInfos = self.m_bigSymbolColumnInfo[_iCol]
        for k = 1, #bigSymbolInfos do
            local bigSymbolInfo = bigSymbolInfos[k]

            for changeIndex = 1, #bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == _iRow then
                    slotNode = self:getFixSymbol(_iCol, _iRow)
                    isBigSymbol = true
                    break
                end
            end
        end
        if isBigSymbol == false then
            slotNode = self:getFixSymbol(_iCol, _iRow)
        end
    else
        slotNode = self:getFixSymbol(_iCol, _iRow)
    end

    return slotNode
end

function HalosandHornsFsMiniMachine:getAniLastNodeList(_iCol, _declineSymbollRow)
    local lastNodeList = {}

    for iRow = 1, self.m_iReelMaxRow do
        if iRow > _declineSymbollRow then
            local symbolNode = self:getOneAniSymbol(_iCol, iRow)
            table.insert(lastNodeList, symbolNode)
        end
    end

    return lastNodeList
end

function HalosandHornsFsMiniMachine:updateAniLastNodeRowTag(_aniLastNodeList, _addRow)
    for i = 1, #_aniLastNodeList do
        local symbolNode = _aniLastNodeList[i]
        local row = symbolNode.p_rowIndex + _addRow
        self:updateSymbolRowTag(symbolNode, row)
    end
end

function HalosandHornsFsMiniMachine:updateSymbolRowTag(_symbolNode, _row)
    _symbolNode.p_rowIndex = _row
    _symbolNode:setTag(self:getNodeTag(_symbolNode.p_cloumnIndex, _symbolNode.p_rowIndex, SYMBOL_NODE_TAG))
end

function HalosandHornsFsMiniMachine:createOneSymbolNode(_symbolType, _rowIndex, _cloumnIndex)
    local columnData = self.m_reelColDatas[_cloumnIndex]
    local halfNodeH = columnData.p_showGridH * 0.5

    local changeRowIndex = _rowIndex

    local stepCount = 1
    -- 检测是否为长条模式
    if self.m_bigSymbolInfos and self.m_bigSymbolInfos[_symbolType] ~= nil then
        local symbolCount = self.m_bigSymbolInfos[_symbolType]
        changeRowIndex = changeRowIndex - symbolCount
    end

    local parentData = self.m_slotParents[_cloumnIndex]
    parentData.m_isLastSymbol = true

    local node = self:getSlotNodeWithPosAndType(_symbolType, changeRowIndex, _cloumnIndex, true)
    node.p_slotNodeH = columnData.p_showGridH

    node.p_showOrder = self:getBounsScatterDataZorder(_symbolType) - changeRowIndex

    if not node:getParent() then
        local slotParentBig = parentData.slotParentBig
        if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
            slotParentBig:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, _cloumnIndex * SYMBOL_NODE_TAG + changeRowIndex)
        else
            parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, _cloumnIndex * SYMBOL_NODE_TAG + changeRowIndex)
        end
    else
        node:setTag(_cloumnIndex * SYMBOL_NODE_TAG + changeRowIndex)
        node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
        node:setVisible(true)
    end

    node.p_symbolType = _symbolType
    node.p_reelDownRunAnima = parentData.reelDownAnima

    node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
    node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
    node:runIdleAnim()

    return node
end

function HalosandHornsFsMiniMachine:beginReel()
    self.m_isOutLines = false
    BaseSlotoManiaMachine.beginReel(self)
end

function HalosandHornsFsMiniMachine:createDeclineSymbolTimeLines(_declineSymbol)
    local currCol = _declineSymbol.p_cloumnIndex

    local declineSymbolBaoZha = self.m_clipParent:getChildByName("declineSymbolTimeLines")
    if declineSymbolBaoZha then
    else
        declineSymbolBaoZha = util_createAnimation("Socre_HalosandHorns_xianshu_1.csb")
        self.m_clipParent:addChild(declineSymbolBaoZha, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 9)
        declineSymbolBaoZha:setName("declineSymbolTimeLines")
    end

    declineSymbolBaoZha:setVisible(true)
    declineSymbolBaoZha:runCsbAction(
        "actionframe",
        false,
        function()
            declineSymbolBaoZha:setVisible(false)
        end
    )
    declineSymbolBaoZha:setPosition(util_getOneGameReelsTarSpPos(self, self:getPosReelIdx(_declineSymbol.p_rowIndex, _declineSymbol.p_cloumnIndex)))

    local linesNum = self:getCurrLinesNum()
    local str = tostring(linesNum)
    declineSymbolBaoZha:findChild("m_lines_num"):setString(str)
end

function HalosandHornsFsMiniMachine:beginDeclineAni()
    self.m_currAniRow = self.m_currAniRow + 1
    self.m_currAniIndex = self.m_currAniIndex + 1
    local symbolIndex = (self.m_iReelRowNum - self.m_currAniRow) + 1

    if self.m_currAniRow > self.m_endAniRow then
        if self.m_AniRndFunc then
            self.m_AniRndFunc()
        end

        return
    end

    local _symbolType = self.m_endRowReelData[self.m_currAniIndex]

    -- 移除停止行图标
    local currAniRowNode = self:getFixSymbol(self.m_currAniCol, symbolIndex)

    -- 修改上升图标以上的图标 tag p_rowIndex 大于rowIndex 的
    local aniLastNodelist = self:getAniLastNodeList(self.m_currAniCol, self.m_currDeclineSymbolRow)
    self:updateAniLastNodeRowTag(aniLastNodelist, -1)

    -- 创建底部拉出来的图标
    -- 长条不可能出现在升行图标的列
    local downSymbol = self:createOneSymbolNode(_symbolType, self.m_iReelRowNum, self.m_currAniCol)
    downSymbol:setPositionY(downSymbol:getPositionY() + self.m_SlotNodeH)

    local cutNum = self.m_DeclineSymbol.p_rowIndex

    local declineSymbolRow = (self.m_iReelRowNum + 1) - self.m_currAniRow

    local declineSymbolOldRow = self.m_DeclineSymbol.p_rowIndex
    -- 修改上升图标 tag p_rowIndex
    self:updateSymbolRowTag(self.m_DeclineSymbol, declineSymbolRow)

    table.insert(aniLastNodelist, downSymbol)

    local DeclineSymbolTime = 15 / 30 --self.DeclineSpeed * math.abs(cutNum)

    for i = 1, #aniLastNodelist do
        local node = aniLastNodelist[i]
        util_playMoveByAction(node, DeclineSymbolTime, cc.p(0, -self.m_SlotNodeH))
    end

    self:updateReelDeclineSymbol(
        self.m_DeclineSymbol,
        self.m_currAniCol,
        symbolIndex,
        DeclineSymbolTime,
        declineSymbolOldRow,
        function()
            self:moveDownCallFun(currAniRowNode)

            self:updateLinesNumFromRow(self.m_currAniCol, self.m_currAniRow)
            self:createDeclineSymbolTimeLines(self.m_DeclineSymbol)
            self:updateOneZhuZiLevel(self.m_currAniCol, self.m_currAniRow)

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(
                waitNode,
                function()
                    if self["declineSymbolMoveTuoWei" .. self.m_currAniCol] then
                        self["declineSymbolMoveTuoWei" .. self.m_currAniCol]:removeFromParent()
                        self["declineSymbolMoveTuoWei" .. self.m_currAniCol] = nil
                    end

                    self.m_currDeclineSymbolRow = self.m_DeclineSymbol.p_rowIndex

                    if self.m_currAniRow >= self.m_endAniRow then
                        self:beginDeclineAni()
                    else
                        local waitTime = 0.5
                        local waitNode = cc.Node:create()
                        self:addChild(waitNode)
                        performWithDelay(
                            waitNode,
                            function()
                                gLobalSoundManager:playSound("HalosandHornsSounds/HalosandHornsSounds_shenghang.mp3")

                                self.m_DeclineSymbol:runAnim("actionframe1")

                                self:beginDeclineAni()

                                waitNode:removeFromParent()
                            end,
                            waitTime
                        )
                    end

                    waitNode:removeFromParent()
                end,
                15 / 30
            )
        end
    )

    local declineSymbolMoveTuoWei = self["declineSymbolMoveTuoWei" .. self.m_currAniCol]
    if declineSymbolMoveTuoWei then
        declineSymbolMoveTuoWei:runCsbAction("actionframe")
    end

    local ReelUITime = DeclineSymbolTime - self.updateSpeed
    self:updateReelUI(self.m_currAniCol, self.m_currAniRow, ReelUITime)
end

function HalosandHornsFsMiniMachine:updateReelDeclineSymbol(_node, _iCol, _endRow, _time, declineSymbolOldRow, _func)
    self:createDeclineSymbolMoveTuoWei(_iCol)

    local currNode = _node
    local endIndex = self:getPosReelIdx(_endRow, _iCol)
    local endPos = util_getOneGameReelsTarSpPos(self, endIndex)

    local node_EndPosY = endPos.y
    local node_CurrentPosY = currNode:getPositionY()
    local nodeAddNum = (node_EndPosY - node_CurrentPosY) / (_time / self.updateSpeed)
    local nodeMove_isEnd = false

    local declineSymbolMoveTuoWei_CurrentPos = util_getPosByColAndRow(self, currNode.p_cloumnIndex, declineSymbolOldRow)
    local declineSymbolMoveTuoWeiEndY = util_getPosByColAndRow(self, currNode.p_cloumnIndex, _endRow).y
    local declineSymbolMoveTuoWeiAddNum = (declineSymbolMoveTuoWeiEndY - declineSymbolMoveTuoWei_CurrentPos.y) / (_time / self.updateSpeed)

    declineSymbolMoveTuoWeiAddNum = self.m_machine:GetPreciseDecimal(declineSymbolMoveTuoWeiAddNum, 11)

    local declineSymbolMoveTuoWei_isEnd = false

    local declineSymbolMoveTuoWei = self["declineSymbolMoveTuoWei" .. _iCol]
    if declineSymbolMoveTuoWei then
        declineSymbolMoveTuoWei:runCsbAction("idle")
        declineSymbolMoveTuoWei:setVisible(true)
        declineSymbolMoveTuoWei:setPosition(declineSymbolMoveTuoWei_CurrentPos)
    end

    local scheduleNode = self["m_updateReelAniDeclineNode_" .. _iCol]
    scheduleNode:stopAllActions()

    util_schedule(
        scheduleNode,
        function()
            local currNodePosY = currNode:getPositionY()
            if currNodePosY <= node_EndPosY then
                nodeMove_isEnd = true
                currNode:setPositionY(node_EndPosY)
            elseif currNodePosY > node_EndPosY then
                currNode:setPositionY(currNodePosY + nodeAddNum)
            end

            if declineSymbolMoveTuoWei then
                local currdeclineSymbolPosY = declineSymbolMoveTuoWei:getPositionY()
                if currdeclineSymbolPosY <= declineSymbolMoveTuoWeiEndY then
                    declineSymbolMoveTuoWei_isEnd = true
                    declineSymbolMoveTuoWei:setPositionY(declineSymbolMoveTuoWeiEndY)
                elseif currdeclineSymbolPosY > declineSymbolMoveTuoWeiEndY then
                    declineSymbolMoveTuoWei:setPositionY(currdeclineSymbolPosY + declineSymbolMoveTuoWeiAddNum)
                end
            else
                declineSymbolMoveTuoWei_isEnd = true
            end

            if nodeMove_isEnd and declineSymbolMoveTuoWei_isEnd then
                scheduleNode:stopAllActions()

                if _func then
                    _func()
                end
            end
        end,
        self.updateSpeed
    )
end

function HalosandHornsFsMiniMachine:getBonusAngelSymbolIndex(_col, _row)
    local currRow = (self.m_iReelRowNum - _row + 1)
    for iRow = currRow, self.m_iReelRowNum, 1 do
        local symbolType = self:getMatrixPosSymbolType(iRow, _col)
        if symbolType == self.SYMBOL_ANGEL_DECLINE then
            return self:getPosReelIdx(iRow, _col)
        end
    end
end

function HalosandHornsFsMiniMachine:playDeclineReelCol(effectData, _iCol)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local up = fsExtraData.up or {}
    local upRows = up.upRows or {0, 0, 0, 0, 0}
    local upRowNum = upRows[_iCol] or 0
    local upReels = up.upReels or {}
    local endRow = self.m_currentReelRow[_iCol] + upRowNum -- 因为轮盘时反的，所以真实的小块位置需要用 总行数减一下在加一
    local endRowReelData = upReels[_iCol]
    local iCol = _iCol
    local declineSymbolIndex = self:getBonusAngelSymbolIndex(_iCol, endRow) -- 天使升行位置
    local fixPos = self:getRowAndColByPos(declineSymbolIndex)
    local declineSymbollRow = fixPos.iX

    for iRow = 1, self.m_iReelMaxRow do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if targSp then
            -- release_print("targSp iCol:" .. iCol .. "iRow:" .. iRow .. "symbolType:" .. symbolType .. "targSp.symbolType:" .. targSp.p_symbolType)
            -- print("targSp iCol:" .. iCol .. "iRow:" .. iRow .. "symbolType:" .. symbolType .. "targSp.symbolType:" .. targSp.p_symbolType)
        else
            -- release_print("targSp获取不到 iCol:" .. iCol .. "iRow:" .. iRow .. "symbolType: " .. symbolType)
            -- print("targSp获取不到 iCol:" .. iCol .. "iRow:" .. iRow .. "symbolType: " .. symbolType)
            local symbolNode = self:createOneSymbolNode(symbolType, iRow, iCol)
            self:removeDeclineTuoWeiNode(symbolNode)
        end
    end

    local symbolNodeIndex = 0
    local childs = self.m_slotParents[iCol].slotParent:getChildren()
    for index = 1, #childs do
        local node = childs[index]
        if node.p_symbolType then
            symbolNodeIndex = symbolNodeIndex + 1
            -- release_print("node iCol:" .. node.p_cloumnIndex .. "iRow:" .. node.p_rowIndex .. "symbolType:" .. node.p_symbolType)
            -- print("node iCol:" .. node.p_cloumnIndex .. "iRow:" .. node.p_rowIndex .. "symbolType:" .. node.p_symbolType)
        end
    end

    -- release_print("symbolNodeIndex :" .. symbolNodeIndex)
    -- print("symbolNodeIndex :" .. symbolNodeIndex)

    self.m_currDeclineSymbolRow = declineSymbollRow
    self.m_currAniIndex = 0
    self.m_currAniCol = iCol
    self.m_currAniRow = endRow - upRowNum
    self.m_endAniRow = endRow
    self.m_endRowReelData = endRowReelData
    self.m_AniRndFunc = function()
        self.m_currentReelRow[_iCol] = endRow

        self:updateBonusTopSymbolIdleAnim(_iCol)

        -- 到位置后判断是否进入特殊玩法
        self:triggerOneColTopSymbolGame(
            function()
                self:restBonusTopZorder()

                self.m_DeclineSymbol = util_setClipReelSymbolToBaseParent(self, self.m_DeclineSymbol)

                self.m_currDeclineSymbolRow = nil
                self.m_currAniCol = nil
                self.m_currAniRow = nil
                self.m_endAniRow = nil
                self.m_AniRndFunc = nil
                self.m_DeclineSymbol = nil

                self.m_AniCurrNum = self.m_AniCurrNum + 1

                local waitTime = 0
                if self.m_AniCurrNum >= self.m_AniColNum then
                    waitTime = 0.5
                end

                local waitNode = cc.Node:create()
                self:addChild(waitNode)
                performWithDelay(
                    waitNode,
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                        waitNode:removeFromParent()
                    end,
                    waitTime
                )
            end,
            _iCol
        )
    end

    local waitTimes = 0.1
    if self.m_triggerFirst then
        self.m_triggerFirst = false
        waitTimes = 18 / 30
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            gLobalSoundManager:playSound("HalosandHornsSounds/HalosandHornsSounds_shenghang.mp3")

            -- 上升图标提层级
            self.m_DeclineSymbol = util_setSymbolToClipReel(self, iCol, declineSymbollRow, self.SYMBOL_ANGEL_DECLINE, 0)
            self.m_DeclineSymbol:runAnim("actionframe1")
            self:beginDeclineAni()

            waitNode:removeFromParent()
        end,
        waitTimes
    )
end

function HalosandHornsFsMiniMachine:updateColumnMaxReward(_iCol)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local columnMaxReward = fsExtraData.columnMaxReward
    local columnMaxGame = fsExtraData.columnMaxGame or {0, 0, 0, 0, 0}
    self.m_columnMaxReward[_iCol] = columnMaxReward[_iCol]
    self.m_columnMaxGame[_iCol] = columnMaxGame[_iCol]
end

function HalosandHornsFsMiniMachine:triggerOneColTopSymbolGame(_func, _iCol)
    local endRow = self.m_currentReelRow[_iCol]

    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}

    local coins = 0

    if endRow == self.m_iReelMaxRow then
        -- 触发集满玩法

        self.m_machine.m_waitTimeReelDown = self.m_spinReelDownTime

        --箭头触发动画
        self.m_DeclineSymbol:runAnim("actionframe2")
        local AniNode = self.m_DeclineSymbol:getCCBNode()
        util_spineEndCallFunc(
            AniNode.m_spineNode,
            "actionframe2",
            function()
            end
        )

        local rewordType = self.m_columnMaxReward[_iCol]

        local columnRow = fsExtraData.columnRows
        local restRow = columnRow[_iCol]
        self.m_currentReelRow[_iCol] = restRow
        self:updateColumnMaxReward(_iCol)

        local currCol = _iCol

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                --判断触发什么玩法

                local nodeName = self.BONUS_TOP_NODENAME
                local parentTopNode = self:findChild(nodeName[currCol])
                parentTopNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 104)

                local topBonusType = rewordType
                if currCol ~= 3 then
                    topBonusType = self["BonusTopSymbol_" .. currCol].m_type
                else
                end

                if topBonusType == self.BONUS_TOP_TYPE_END_GAME then
                    gLobalSoundManager:playSound("HalosandHornsSounds/HalosandHornsSounds_TopBonus_Free_End.mp3")

                    local totalBet = globalData.slotRunData:getCurTotalBet()
                    local endCoins = totalBet * tonumber(rewordType)
                    self:updateBottomUICoins(self.m_top_bonus_reword_coins, endCoins)

                    -- 结束
                    if self["BonusTopSymbol_" .. currCol] then
                        self["BonusTopSymbol_" .. currCol]:runCsbAction(
                            "actionframe",
                            false,
                            function()
                                if _func then
                                    _func()
                                end
                            end
                        )
                    end
                elseif topBonusType == self.BONUS_TOP_TYPE_JP then
                    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
                    local grandWinAmount = fsExtraData.grandWinCoins or 0
                    local endCoins = grandWinAmount

                    -- jackpot
                    self:showAngelJpRewordAnim(
                        endCoins,
                        function()
                            self:updateBottomUICoins(self.m_top_bonus_reword_coins, endCoins)

                            if _func then
                                _func()
                            end
                        end
                    )
                else
                    gLobalSoundManager:playSound("HalosandHornsSounds/HalosandHornsSounds_TopBonus_Normal_Coins.mp3")
                    -- 普通赢钱
                    table.insert(self.m_collectBonusPos, currCol)

                    if self["BonusTopSymbol_" .. currCol] then
                        self["BonusTopSymbol_" .. currCol]:runCsbAction("actionframe")

                        local startNode = self["BonusTopSymbol_" .. currCol]
                        local endNode = self.m_machine.m_bottomUI:findChild("win_txt")
                        self:showTopBonusCollect(
                            startNode,
                            endNode,
                            function()
                                local totalBet = globalData.slotRunData:getCurTotalBet()
                                local endCoins = totalBet * tonumber(rewordType)
                                self:updateBottomUICoins(self.m_top_bonus_reword_coins, endCoins)

                                if _func then
                                    _func()
                                end
                            end
                        )
                    end
                end

                waitNode:removeFromParent()
            end,
            15 / 30
        )
    else
        -- 没有触发集满玩法
        if _func then
            _func()
        end
    end
end

function HalosandHornsFsMiniMachine:slotReelDown()
    if self.m_machine then
        self.m_machine:FSReelDownNotify()
    end

    BaseSlotoManiaMachine.slotReelDown(self)
end

function HalosandHornsFsMiniMachine:addObservers()
    gLobalNoticManager:addObserver(self, self.quicklyStopReel, ViewEventType.QUICKLY_SPIN_EFFECT)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = self.m_pauseRef + 1

            Target:pauseMachine()
        end,
        ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = math.max(self.m_pauseRef - 1, 0)
            if self.m_pauseRef <= 0 then
                Target:resumeMachine()
            end
        end,
        ViewEventType.NOTIFY_RESUME_SLOTSMACHINE
    )
end

function HalosandHornsFsMiniMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function HalosandHornsFsMiniMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then -- 没有连线不更新钱
        return
    end

    local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0

    local isNotifyUpdateTop = false

    local coins = 0
    local specialCoins = self:getSpecialWinCoins()

    if specialCoins and specialCoins > 0 and self.m_updateSpecialCoins then
        local beiginCoins = fsWinCoin - (fsWinCoin - specialCoins)
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {fsWinCoin, isNotifyUpdateTop, nil, beiginCoins})
        globalData.slotRunData.lastWinCoin = lastWinCoin
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_machine.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end

    if self.m_updateSpecialCoins then
        self.m_updateSpecialCoins = false
    end
end

function HalosandHornsFsMiniMachine:getSpecialWinCoins()
    return self.m_top_bonus_reword_coins
end

function HalosandHornsFsMiniMachine:updateBottomUICoins(beiginCoins, currCoins, isNotifyUpdateTop)
    local endCoins = currCoins + beiginCoins
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {endCoins, isNotifyUpdateTop, nil, beiginCoins})
    globalData.slotRunData.lastWinCoin = lastWinCoin
    self.m_machine:showWinEffect()
    self.m_top_bonus_reword_coins = endCoins
    self.m_updateSpecialCoins = true
end

function HalosandHornsFsMiniMachine:getVecGetLineInfo()
    return self.m_runSpinResultData.p_winLines
end

function HalosandHornsFsMiniMachine:playEffectNotifyChangeSpinStatus()
    if self.m_machine then
        self.m_machine:FSReelShowSpinNotify()
    end
end

function HalosandHornsFsMiniMachine:quicklyStopReel(colIndex)
    if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
        BaseSlotoManiaMachine.quicklyStopReel(self, colIndex)
    end
end

function HalosandHornsFsMiniMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function HalosandHornsFsMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

-- 消息返回更新数据
function HalosandHornsFsMiniMachine:netWorkCallFun(spinResult)
    self.m_preFsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0

    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)

    self:updateNetWorkData()
end

function HalosandHornsFsMiniMachine:enterLevel()
    BaseSlotoManiaMachine.enterLevel(self)
end

function HalosandHornsFsMiniMachine:dealSmallReelsSpinStates()
end

-- 处理特殊关卡 遮罩层级
function HalosandHornsFsMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    local maxzorder = 0
    local zorder = 0
    for i = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder > maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

---

function HalosandHornsFsMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines
end

function HalosandHornsFsMiniMachine:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

function HalosandHornsFsMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function HalosandHornsFsMiniMachine:pauseMachine()
    self.gameRunPause = true
end

function HalosandHornsFsMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

---
-- 清空掉产生的数据
--
function HalosandHornsFsMiniMachine:clearSlotoData()
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

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

function HalosandHornsFsMiniMachine:restSelfGameEffects(restType)
    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects, 1 do
            local effectData = self.m_gameEffects[i]

            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_selfEffectType

                if effectType == restType then
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    return
                end
            end
        end
    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function HalosandHornsFsMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function HalosandHornsFsMiniMachine:clearCurMusicBg()
end

function HalosandHornsFsMiniMachine:getBonusOneTopSymbolType(_maxReward)
    if _maxReward == self.BonusTopSymbolType_Jp then
        return self.BonusTopSymbolType_Jp
    elseif _maxReward == self.BONUS_TOP_TYPE_END_GAME then
        return self.BONUS_TOP_TYPE_END_GAME
    else
        if tonumber(_maxReward) > self.m_maxMutilBonusTop then
            return self.BONUS_TOP_TYPE_COINS_LV
        else
            return self.BONUS_TOP_TYPE_COINS_ZI
        end
    end
end

function HalosandHornsFsMiniMachine:getMaxRewardType(_iCol)
    local maxReward = self.m_columnMaxReward[_iCol]
    local coins = self.m_columnMaxReward[_iCol]
    local endType = self.m_columnMaxGame[_iCol]
    if endType == 0 then -- 0：结束； 1：继续
        maxReward = self.BONUS_TOP_TYPE_END_GAME
    end

    return maxReward, coins
end

function HalosandHornsFsMiniMachine:updateBonusOneTopSymbol(_iCol)
    local nodeName = self.BONUS_TOP_NODENAME
    local parentNode = self:findChild(nodeName[_iCol])
    local maxReward, coins = self:getMaxRewardType(_iCol)

    local isAdd = false

    if self["BonusTopSymbol_" .. _iCol] then
        if self["BonusTopSymbol_" .. _iCol].m_type ~= self:getBonusOneTopSymbolType(maxReward) then
            isAdd = true
            self["BonusTopSymbol_" .. _iCol]:stopAllActions()
            self["BonusTopSymbol_" .. _iCol]:removeFromParent()
            self["BonusTopSymbol_" .. _iCol] = nil
        end
    else
        isAdd = true
    end

    if isAdd then
        if maxReward == self.BonusTopSymbolType_Jp then
            print("不创建--------")
        elseif maxReward == self.BONUS_TOP_TYPE_END_GAME then
            if isAdd then
                self["BonusTopSymbol_" .. _iCol] = util_createAnimation("Socre_HalosandHorns_bonus_4.csb")
                parentNode:addChild(self["BonusTopSymbol_" .. _iCol])
                self["BonusTopSymbol_" .. _iCol].m_type = self.BONUS_TOP_TYPE_END_GAME
                self["BonusTopSymbol_" .. _iCol].m_sign = maxReward
            end
        else
            if isAdd then
                if tonumber(maxReward) > self.m_maxMutilBonusTop then
                    self["BonusTopSymbol_" .. _iCol] = util_createAnimation("Socre_HalosandHorns_bonus_1.csb")
                    parentNode:addChild(self["BonusTopSymbol_" .. _iCol])
                    self["BonusTopSymbol_" .. _iCol].m_type = self.BONUS_TOP_TYPE_COINS_LV
                    self["BonusTopSymbol_" .. _iCol].m_sign = maxReward
                else
                    self["BonusTopSymbol_" .. _iCol] = util_createAnimation("Socre_HalosandHorns_bonus_2.csb")
                    parentNode:addChild(self["BonusTopSymbol_" .. _iCol])
                    self["BonusTopSymbol_" .. _iCol].m_type = self.BONUS_TOP_TYPE_COINS_ZI
                    self["BonusTopSymbol_" .. _iCol].m_sign = maxReward
                end
            end
        end

        self:updateBonusTopSymbolIdleAnim(_iCol)
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local lab_1 = self["BonusTopSymbol_" .. _iCol]:findChild("m_lb_coins_1")
    if lab_1 then
        lab_1:setVisible(false)
    end
    local lab_2 = self["BonusTopSymbol_" .. _iCol]:findChild("m_lb_coins_2")
    if lab_2 then
        lab_2:setString(util_formatCoins(totalBet * tonumber(coins), 3))
    end
end

function HalosandHornsFsMiniMachine:updateBonusTopSymbolIdleAnim(_iCol)
    if _iCol ~= self.COL_3 then
        if self.m_currentReelRow[_iCol] == 8 then
            self["BonusTopSymbol_" .. _iCol]:runCsbAction("idleframe1", true)
        else
            self["BonusTopSymbol_" .. _iCol]:runCsbAction("idleframe", true)
        end
    end
end

function HalosandHornsFsMiniMachine:initBonusTopSymbol()
    self.m_bonusTopJpAngelBg = util_createAnimation("Socre_HalosandHorns_jcakpot_2_bg.csb")
    self:findChild("bonus_Node_Jp"):addChild(self.m_bonusTopJpAngelBg)

    self.m_bonusTopJpAngel = util_spineCreate("Socre_HalosandHorns_jcakpot_2", true, true)
    self:findChild("bonus_Node_Jp"):addChild(self.m_bonusTopJpAngel)
    util_spinePlay(self.m_bonusTopJpAngel, "idleframe", true)
end

--[[
    ********************  
    reel轮上涨  
--]]
function HalosandHornsFsMiniMachine:initReelUIPos()
    for i = 1, #self.m_currentReelRow do
        local iCol = i
        local iRow = self.m_currentReelRow[i]

        self:updateReelUI(iCol, iRow, self.updateSpeed)
        self:updateOneZhuZiLevel(iCol, iRow)
    end
end

function HalosandHornsFsMiniMachine:updateReelUI(_iCol, _rowIndex, _time, _func)
    local reelBG = self:findChild("reel_BG_" .. _iCol)
    local reelBGTiao = self:findChild("reel_line_" .. _iCol)
    local jianTou = self:findChild("HalosandHorns_zhizhen_" .. _iCol)
    local jianTouDi = self:findChild("HalosandHorns_ui_" .. _iCol)
    local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + _iCol)
    local clipControlNode = clipNode:getChildByName("clipControlNode")

    local reelBg_EndPercent = self.m_reelBGAddPercent * _rowIndex
    local jianTou_EndPosY = self.m_reelJianTou_BeginPosY + self.m_reelianTou_AddPosY * (_rowIndex - 3)
    local jianTouBg_EndPosY = self.m_reelJianTouBG_BeginPosY + self.m_reelJianTouBG_AddPosY * (_rowIndex - 3)
    local clipNode_EndSizeY = self.m_clipNode_BeginSizeY + self.m_clipNode_AddSizeY * (_rowIndex - 3)
    local clipNode_EndPosY = self.m_clipNode_BeginPosY + self.m_clipNode_AddPosY * (_rowIndex - 3)
    local clipControlNode_EndPosY = self.m_clipControlNode_BeginPosY + self.m_clipControlNode_AddSizeY * (_rowIndex - self.m_iReelMaxRow)

    if _rowIndex == self.m_iReelMaxRow then
        reelBg_EndPercent = 100
        jianTou_EndPosY = jianTou_EndPosY + 10 -- 最后一次少移动10px
        jianTouBg_EndPosY = jianTouBg_EndPosY + 10 -- 最后一次少移动10px
    end

    local reelBg_CurrentPercent = reelBG:getPercent()
    local jianTou_CurrentPosY = jianTou:getPositionY()
    local jianTouBg_CurrentPosY = jianTouDi:getPositionY()
    local clipNode_CurrentRect = clipNode:getClippingRegion()
    local clipNode_CurrentPosY = clipNode:getPositionY()
    local clipControlNode_CurrentPosY = clipControlNode:getPositionY()

    local reelBgAddNum = (reelBg_EndPercent - reelBg_CurrentPercent) / (_time / self.updateSpeed)
    local jianTouAddNum = (jianTou_EndPosY - jianTou_CurrentPosY) / (_time / self.updateSpeed)
    local jianTouBgAddNum = (jianTouBg_EndPosY - jianTouBg_CurrentPosY) / (_time / self.updateSpeed)
    local clipNodeAddNum = (clipNode_EndSizeY - clipNode_CurrentRect.height) / (_time / self.updateSpeed)
    local clipNodePosYAddNum = (clipNode_EndPosY - clipNode_CurrentPosY) / (_time / self.updateSpeed)
    local clipControlNodeAddNum = (clipControlNode_EndPosY - clipControlNode_CurrentPosY) / (_time / self.updateSpeed)

    reelBgAddNum = self.m_machine:GetPreciseDecimal(reelBgAddNum, 11)
    jianTouAddNum = self.m_machine:GetPreciseDecimal(jianTouAddNum, 11)
    jianTouBgAddNum = self.m_machine:GetPreciseDecimal(jianTouBgAddNum, 11)
    clipNodeAddNum = self.m_machine:GetPreciseDecimal(clipNodeAddNum, 11)
    clipNodePosYAddNum = self.m_machine:GetPreciseDecimal(clipNodePosYAddNum, 11)
    clipControlNodeAddNum = self.m_machine:GetPreciseDecimal(clipControlNodeAddNum, 11)

    local reelBg_isEnd = false
    local reelBgTiao_isEnd = false
    local jianTou_isEnd = false
    local jianTouBg_isEnd = false
    local clipNode_isEnd = false
    local clipNode_PosY_isEnd = false
    local clipControlNode_isEnd = false

    local scheduleNode = self["m_updateReelBgNode_" .. _iCol]
    scheduleNode:stopAllActions()

    util_schedule(
        scheduleNode,
        function()
            local reelBGPercent = reelBG:getPercent()

            if reelBgAddNum <= 0 then
                if reelBGPercent <= reelBg_EndPercent then
                    reelBg_isEnd = true
                    reelBG:setPercent(reelBg_EndPercent)
                elseif reelBGPercent > reelBg_EndPercent then
                    reelBG:setPercent(reelBGPercent + reelBgAddNum)
                end
            else
                if reelBGPercent >= reelBg_EndPercent then
                    reelBg_isEnd = true
                    reelBG:setPercent(reelBg_EndPercent)
                elseif reelBGPercent < reelBg_EndPercent then
                    reelBG:setPercent(reelBGPercent + reelBgAddNum)
                end
            end

            if reelBGTiao then
                local reelBGTiaoPercent = reelBGTiao:getPercent()

                if reelBgAddNum <= 0 then
                    if reelBGTiaoPercent <= reelBg_EndPercent then
                        reelBgTiao_isEnd = true
                        reelBGTiao:setPercent(reelBg_EndPercent)
                    elseif reelBGTiaoPercent > reelBg_EndPercent then
                        reelBGTiao:setPercent(reelBGTiaoPercent + reelBgAddNum)
                    end
                else
                    if reelBGTiaoPercent >= reelBg_EndPercent then
                        reelBgTiao_isEnd = true
                        reelBGTiao:setPercent(reelBg_EndPercent)
                    elseif reelBGTiaoPercent < reelBg_EndPercent then
                        reelBGTiao:setPercent(reelBGTiaoPercent + reelBgAddNum)
                    end
                end
            else
                reelBgTiao_isEnd = true
            end

            local jianTouPosY = jianTou:getPositionY()

            if jianTouAddNum <= 0 then
                if jianTouPosY <= jianTou_EndPosY then
                    jianTou_isEnd = true
                    jianTou:setPositionY(jianTou_EndPosY)
                elseif jianTouPosY > jianTou_EndPosY then
                    jianTou:setPositionY(jianTouPosY + jianTouAddNum)
                end
            else
                if jianTouPosY >= jianTou_EndPosY then
                    jianTou_isEnd = true
                    jianTou:setPositionY(jianTou_EndPosY)
                elseif jianTouPosY < jianTou_EndPosY then
                    jianTou:setPositionY(jianTouPosY + jianTouAddNum)
                end
            end

            local jianTouBgPosY = jianTouDi:getPositionY()
            if jianTouBgAddNum <= 0 then
                if jianTouBgPosY <= jianTouBg_EndPosY then
                    jianTouBg_isEnd = true
                    jianTouDi:setPositionY(jianTouBg_EndPosY)
                elseif jianTouBgPosY > jianTouBg_EndPosY then
                    jianTouDi:setPositionY(jianTouBgPosY + jianTouBgAddNum)
                end
            else
                if jianTouBgPosY >= jianTouBg_EndPosY then
                    jianTouBg_isEnd = true
                    jianTouDi:setPositionY(jianTouBg_EndPosY)
                elseif jianTouBgPosY < jianTouBg_EndPosY then
                    jianTouDi:setPositionY(jianTouBgPosY + jianTouBgAddNum)
                end
            end

            local clipNodeRect = clipNode:getClippingRegion()
            if clipNodeAddNum <= 0 then
                if clipNodeRect.height <= clipNode_EndSizeY then
                    clipNode_isEnd = true
                    clipNode:setClippingRegion(
                        {
                            x = clipNodeRect.x,
                            y = clipNodeRect.y,
                            width = clipNodeRect.width,
                            height = clipNode_EndSizeY
                        }
                    )
                elseif clipNodeRect.height > clipNode_EndSizeY then
                    clipNode:setClippingRegion(
                        {
                            x = clipNodeRect.x,
                            y = clipNodeRect.y,
                            width = clipNodeRect.width,
                            height = clipNodeRect.height + clipNodeAddNum
                        }
                    )
                end
            else
                if clipNodeRect.height >= clipNode_EndSizeY then
                    clipNode_isEnd = true
                    clipNode:setClippingRegion(
                        {
                            x = clipNodeRect.x,
                            y = clipNodeRect.y,
                            width = clipNodeRect.width,
                            height = clipNode_EndSizeY
                        }
                    )
                elseif clipNodeRect.height < clipNode_EndSizeY then
                    clipNode:setClippingRegion(
                        {
                            x = clipNodeRect.x,
                            y = clipNodeRect.y,
                            width = clipNodeRect.width,
                            height = clipNodeRect.height + clipNodeAddNum
                        }
                    )
                end
            end

            local clipNodePosY = clipNode:getPositionY()
            if clipNodePosYAddNum <= 0 then
                if clipNodePosY <= clipNode_EndPosY then
                    clipNode_PosY_isEnd = true
                    clipNode:setPositionY(clipNode_EndPosY)
                elseif clipNodePosY > clipNode_EndPosY then
                    clipNode:setPositionY(clipNodePosY + clipNodePosYAddNum)
                end
            else
                if clipNodePosY >= clipNode_EndPosY then
                    clipNode_PosY_isEnd = true
                    clipNode:setPositionY(clipNode_EndPosY)
                elseif clipNodePosY < clipNode_EndPosY then
                    clipNode:setPositionY(clipNodePosY + clipNodePosYAddNum)
                end
            end

            local clipControlNodePosY = clipControlNode:getPositionY()
            if clipControlNodeAddNum >= 0 then
                if clipControlNodePosY >= clipControlNode_EndPosY then
                    clipControlNode_isEnd = true
                    clipControlNode:setPositionY(clipControlNode_EndPosY)
                elseif clipControlNodePosY < clipControlNode_EndPosY then
                    clipControlNode:setPositionY(clipControlNodePosY + clipControlNodeAddNum)
                end
            else
                if clipControlNodePosY <= clipControlNode_EndPosY then
                    clipControlNode_isEnd = true
                    clipControlNode:setPositionY(clipControlNode_EndPosY)
                elseif clipControlNodePosY > clipControlNode_EndPosY then
                    clipControlNode:setPositionY(clipControlNodePosY + clipControlNodeAddNum)
                end
            end

            if reelBg_isEnd and jianTou_isEnd and jianTouBg_isEnd and clipNode_isEnd and reelBgTiao_isEnd and clipNode_PosY_isEnd and clipControlNode_isEnd then
                scheduleNode:stopAllActions()
                if _func then
                    _func()
                end
            end
        end,
        self.updateSpeed
    )
end

function HalosandHornsFsMiniMachine:showAngelJpRewordAnim(coins, _func)
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "jackpot")
    end
    
    gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_AngelJpReword.mp3")

    self.m_bonusTopJpAngel:setVisible(false)

    util_spinePlay(self.m_jpBarAngel, "actionframe1")
    self.m_jpBarAngel:setVisible(true)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            self.m_bonusTopJpAngelBg:runCsbAction(
                "actionframe",
                false,
                function()
                    self.m_bonusTopJpAngelBg:runCsbAction("idleframe")
                end
            )

            util_spinePlay(self.m_jpBarAngel, "actionframe")

            performWithDelay(
                waitNode,
                function()
                    util_spinePlay(self.m_jpBarAngel, "actionframe2")

                    performWithDelay(
                        waitNode,
                        function()
                            self.m_jackPotBar:updateRewordCoins(coins)

                            self.m_jackPotBar:runCsbAction("actionframe")

                            self.m_jpBarZi:setVisible(true)
                            self.m_jpBarZi:runCsbAction("actionframe")

                            performWithDelay(
                                waitNode,
                                function()
                                    self.m_jpBarAngel_1:setVisible(true)

                                    util_spinePlay(self.m_jpBarAngel_1, "actionframe")

                                    local waitNode_1 = cc.Node:create()
                                    self:addChild(waitNode_1)
                                    performWithDelay(
                                        waitNode_1,
                                        function()
                                            self.m_jpBarJinBi:setVisible(true)
                                            self.m_jpBarJinBi:runCsbAction("actionframe")

                                            waitNode_1:removeFromParent()
                                        end,
                                        55 / 30
                                    )

                                    performWithDelay(
                                        waitNode,
                                        function()
                                            util_spinePlay(self.m_jpBarAngel_1, "over")

                                            performWithDelay(
                                                waitNode,
                                                function()
                                                    self.m_jackPotBar:runCsbAction(
                                                        "jiesuanover",
                                                        false,
                                                        function()
                                                            self.m_jackPotBar:setBoolShowReword(false)

                                                            self.m_jackPotBar:runCsbAction(
                                                                "show",
                                                                false,
                                                                function()
                                                                    self.m_jackPotBar:runCsbAction("idleframe", true)
                                                                end
                                                            )

                                                            self.m_jpBarAngel_1:setVisible(false)
                                                            self.m_bonusTopJpAngel:setVisible(true)
                                                            self.m_jpBarAngel:setVisible(false)

                                                            if _func then
                                                                _func()
                                                            end
                                                        end
                                                    )

                                                    self.m_jpBarZi:runCsbAction(
                                                        "over",
                                                        false,
                                                        function()
                                                            self.m_jpBarZi:setVisible(false)
                                                        end
                                                    )

                                                    self.m_jpBarJinBi:runCsbAction(
                                                        "over",
                                                        false,
                                                        function()
                                                            self.m_jpBarJinBi:setVisible(false)
                                                        end
                                                    )
                                                end,
                                                50 / 30
                                            )
                                        end,
                                        50 / 30
                                    )
                                end,
                                50 / 30
                            )
                        end,
                        30 / 30
                    )
                end,
                30 / 30
            )
        end,
        35 / 30
    )
end

function HalosandHornsFsMiniMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col, isLastSymbol)

    self:createDeclineTuoWeiNode(reelNode)

    return reelNode
end

function HalosandHornsFsMiniMachine:removeDeclineTuoWeiNode(_symbolNode)
    local declineTuoWeiNode = _symbolNode:getChildByName("angelDeclineTuoWei")
    if declineTuoWeiNode then
        declineTuoWeiNode:removeFromParent()
    end
end

function HalosandHornsFsMiniMachine:createDeclineTuoWeiNode(_symbolNode)
    if self.m_isOutLines then
        return
    end

    if _symbolNode then
        self:removeDeclineTuoWeiNode(_symbolNode)
        if _symbolNode.p_symbolType == self.SYMBOL_ANGEL_DECLINE then
            local declineTuoWei = util_createAnimation("HalosandHorns_tuoweiA.csb")
            _symbolNode:addChild(declineTuoWei, -10)
            declineTuoWei:findChild("Sprite_emo"):setVisible(false)
            declineTuoWei:setName("angelDeclineTuoWei")
            declineTuoWei:runCsbAction("idle", true)
        end
    end
end

function HalosandHornsFsMiniMachine:playCustomSpecialSymbolDownAct(slotNode)

    HalosandHornsFsMiniMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    if slotNode.p_symbolType == self.SYMBOL_ANGEL_DECLINE then
        local row = self.m_currentReelRow[slotNode.p_cloumnIndex]
        local currRow = self.m_maxMutilBonusTop - row
        if slotNode.p_rowIndex >= currRow then

            local soundPath = "HalosandHornsSounds/HalosandHornsSounds_TriggerBonusDown.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end


            slotNode:runAnim("buling")
        end

        local angelDeclineTuoWei = slotNode:getChildByName("angelDeclineTuoWei")
        if angelDeclineTuoWei then
            angelDeclineTuoWei:runCsbAction("actionframe")
        end
    end
end

function HalosandHornsFsMiniMachine:getCurrLinesNum()
    local linesNum = 1
    for iCol = 1, #self.m_LinesReelRow do
        local row = self.m_LinesReelRow[iCol]
        linesNum = linesNum * row
    end
    return linesNum
end

function HalosandHornsFsMiniMachine:updateLinesNumFromRow(_iCol, _iRow)
    self.m_LinesReelRow[_iCol] = _iRow

    local linesNum = 1
    for iCol = 1, #self.m_LinesReelRow do
        if iCol ~= _iCol then
            local row = self.m_LinesReelRow[iCol]
            linesNum = linesNum * row
        end
    end
    linesNum = linesNum * _iRow
    local str = util_AutoLineWrap(tostring(linesNum))

    self:findChild("HalosandHorns_m_lb_conis"):setString(str)
end

function HalosandHornsFsMiniMachine:updateLinesNum()
    local linesNum = 1
    for iCol = 1, #self.m_currentReelRow do
        local row = self.m_currentReelRow[iCol]
        self.m_LinesReelRow[iCol] = row
        linesNum = linesNum * row
    end

    local str = util_AutoLineWrap(tostring(linesNum))

    self:findChild("HalosandHorns_m_lb_conis"):setString(str)
end

function HalosandHornsFsMiniMachine:updateFsUI()
    local fsExtraData = self.m_machine.m_runSpinResultData.p_fsExtraData

    self.m_currentReelRow = fsExtraData.columnRows or {5, 4, 3, 4, 6}
    self.m_columnMaxReward = fsExtraData.columnMaxReward or {"8", "30", "GRAND", "15", "6"}
    self.m_columnMaxGame = fsExtraData.columnMaxGame or {0, 0, 0, 0, 0}

    -- 取消掉赢钱线的显示
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearWinLineEffect()

    self.m_collectBonusPos = {}
    -- 更新 顶部bonus信号
    util_spinePlay(self.m_bonusTopJpAngel, "idleframe", true)
    for iCol = 1, self.m_iReelColumnNum do
        if iCol ~= self.COL_3 then
            self:updateBonusOneTopSymbol(iCol)
            self:updateBonusTopSymbolIdleAnim(iCol)
        end
    end

    -- 更新 reel轮位置和显示区域
    for i = 1, #self.m_currentReelRow do
        local iCol = i
        local iRow = self.m_currentReelRow[i]
        self:updateReelUI(iCol, iRow, self.updateSpeed)
        self:updateOneZhuZiLevel(iCol, iRow)
    end

    -- 更新线数显示
    self:updateLinesNum()
end

---
--设置bonus scatter 层级
function HalosandHornsFsMiniMachine:getBounsScatterDataZorder(symbolType)
    return self.m_machine:getBounsScatterDataZorder(symbolType)
end

function HalosandHornsFsMiniMachine:updateOneZhuZiLevel(_iCol, _currRow)
    local ZhuZi = self["AngelZhuZi_" .. _iCol]

    if ZhuZi then
        ZhuZi:findChild("Node_fen"):setVisible(false)
        ZhuZi:findChild("Node_lan"):setVisible(false)
        ZhuZi:findChild("Node_hong"):setVisible(false)

        if _currRow == self.ZhuZi_level_1 then
            ZhuZi:findChild("Node_fen"):setVisible(true)
        elseif _currRow == self.ZhuZi_level_2 then
            ZhuZi:findChild("Node_lan"):setVisible(true)
        elseif _currRow >= self.ZhuZi_level_3 then
            ZhuZi:findChild("Node_hong"):setVisible(true)
        else
            print("全部不显示")
        end
    end
end

function HalosandHornsFsMiniMachine:showFreeSpinOverView()
    -- gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_over_fs.mp3")

    print("aaaaa")
end

function HalosandHornsFsMiniMachine:createDeclineSymbolMoveTuoWei(_iCol)
    self["declineSymbolMoveTuoWei" .. _iCol] = util_createAnimation("HalosandHorns_tuowei_tianshi_move.csb")
    self["declineSymbolMoveTuoWei" .. _iCol].p_IsMask = true
    self:getReelParent(_iCol):addChild(self["declineSymbolMoveTuoWei" .. _iCol], REEL_SYMBOL_ORDER.REEL_ORDER_4)
    self["declineSymbolMoveTuoWei" .. _iCol]:runCsbAction("idle")
    self["declineSymbolMoveTuoWei" .. _iCol]:setVisible(false)
end

--[[
    ********************  
    reel轮上涨  
--]]
function HalosandHornsFsMiniMachine:updateReelUIPosForSpin()
    for i = 1, #self.m_currentReelRow do
        local iCol = i
        local iRow = self.m_currentReelRow[i]

        self:updateReelUI(iCol, iRow, self.m_machine.m_waitTimeReelDown)
        self:updateOneZhuZiLevel(iCol, iRow)
    end

    self:updateLinesNum()
    self:updateTopBonusForSpin()
end

function HalosandHornsFsMiniMachine:updateReelUIPos()
    for i = 1, #self.m_currentReelRow do
        local iCol = i
        local iRow = self.m_currentReelRow[i]

        self:restReelUI(iCol, iRow)
        self:updateOneZhuZiLevel(iCol, iRow)
    end
end

function HalosandHornsFsMiniMachine:restReelUI(_iCol, _rowIndex)
    local reelBG = self:findChild("reel_BG_" .. _iCol)
    local reelBGTiao = self:findChild("reel_line_" .. _iCol)
    local jianTou = self:findChild("HalosandHorns_zhizhen_" .. _iCol)
    local jianTouDi = self:findChild("HalosandHorns_ui_" .. _iCol)
    local clipNode = self.m_clipParent:getChildByTag(CLIP_NODE_TAG + _iCol)
    local clipControlNode = clipNode:getChildByName("clipControlNode")

    local reelBg_EndPercent = self.m_reelBGAddPercent * _rowIndex
    local jianTou_EndPosY = self.m_reelJianTou_BeginPosY + self.m_reelianTou_AddPosY * (_rowIndex - 3)
    local jianTouBg_EndPosY = self.m_reelJianTouBG_BeginPosY + self.m_reelJianTouBG_AddPosY * (_rowIndex - 3)
    local clipNode_EndSizeY = self.m_clipNode_BeginSizeY + self.m_clipNode_AddSizeY * (_rowIndex - 3)
    local clipNode_EndPosY = self.m_clipNode_BeginPosY + self.m_clipNode_AddPosY * (_rowIndex - 3)
    local clipControlNode_EndPosY = self.m_clipControlNode_BeginPosY + self.m_clipControlNode_AddSizeY * (_rowIndex - self.m_iReelMaxRow)

    local reelBg_CurrentPercent = reelBG:getPercent()
    local jianTou_CurrentPosY = jianTou:getPositionY()
    local jianTouBg_CurrentPosY = jianTouDi:getPositionY()
    local clipNode_CurrentRect = clipNode:getClippingRegion()
    local clipNode_CurrentPosY = clipNode:getPositionY()
    local clipControlNode_CurrentPosY = clipControlNode:getPositionY()

    local reelBGPercent = reelBG:getPercent()
    reelBG:setPercent(reelBg_EndPercent)

    if reelBGTiao then
        reelBGTiao:setPercent(reelBg_EndPercent)
    end

    local jianTouPosY = jianTou:getPositionY()
    jianTou:setPositionY(jianTou_EndPosY)

    local jianTouBgPosY = jianTouDi:getPositionY()
    jianTouDi:setPositionY(jianTouBg_EndPosY)

    local clipNodeRect = clipNode:getClippingRegion()
    clipNode:setClippingRegion(
        {
            x = clipNodeRect.x,
            y = clipNodeRect.y,
            width = clipNodeRect.width,
            height = clipNode_EndSizeY
        }
    )

    local clipNodePosY = clipNode:getPositionY()
    clipNode:setPositionY(clipNode_EndPosY)

    local clipControlNodePosY = clipControlNode:getPositionY()
    clipControlNode:setPositionY(clipControlNode_EndPosY)
end

--绘制多个裁切区域
function HalosandHornsFsMiniMachine:drawReelArea()
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

        local clipControlNode = cc.Node:create()
        clipNode:addChild(clipControlNode)
        clipControlNode:setName("clipControlNode")

        clipControlNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)

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
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)
        
        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")

        
    end
end

function HalosandHornsFsMiniMachine:updateTopBonusForSpin()
    local isPlay = false

    for iCol = 1, self.m_iReelColumnNum do
        if iCol ~= self.COL_3 then
            local currIcol = iCol
            self:updateBonusOneTopSymbol(currIcol)
            if table_vIn(self.m_collectBonusPos, currIcol) then
                self["BonusTopSymbol_" .. iCol]:runCsbAction(
                    "show",
                    false,
                    function()
                        self:updateBonusTopSymbolIdleAnim(currIcol)
                    end
                )
                isPlay = true
            end
        end
    end

    if isPlay then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("HalosandHornsSounds/HalosandHornsSounds_spinShowTopBonus.mp3")
        end
    end

    self.m_collectBonusPos = {}
end

function HalosandHornsFsMiniMachine:showTopBonusCollect(_startNode, _endNode, _func)
    gLobalSoundManager:playSound("HalosandHornsSounds/music_HalosandHorns_rewordTop_Bonus_TianShi.mp3")

    _startNode:setVisible(false)

    local csbName = "Socre_HalosandHorns_bonus_1"
    if _startNode.m_type and _startNode.m_type == self.BONUS_TOP_TYPE_COINS_ZI then
        csbName = "Socre_HalosandHorns_bonus_2"
    end

    local tuoWei = util_createAnimation(csbName .. ".csb")
    self.m_machine:addChild(tuoWei, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    tuoWei:runCsbAction("actionframe")

    local lab_1 = _startNode:findChild("m_lb_coins_2")
    local lab_2 = tuoWei:findChild("m_lb_coins_2")
    local lab_3 = tuoWei:findChild("m_lb_coins_1")
    if lab_1 and lab_2 then
        lab_2:setString(lab_1:getString())
    end
    if lab_3 then
        lab_3:setVisible(false)
    end

    local worldPos = _startNode:getParent():convertToWorldSpace(cc.p(_startNode:getPosition()))
    local startPos = tuoWei:getParent():convertToNodeSpace(worldPos)
    tuoWei:setPosition(startPos)

    local worldPos = _endNode:getParent():convertToWorldSpace(cc.p(_endNode:getPosition()))
    local endPos = tuoWei:getParent():convertToNodeSpace(worldPos)

    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(1.4)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            _startNode:setVisible(true)
        end
    )

    actList[#actList + 1] = cc.MoveTo:create(0.5, endPos)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            if _func then
                _func()
            end
        end
    )
    local sq = cc.Sequence:create(actList)
    tuoWei:runAction(sq)
end

-- 初始化小块时 规避某个信号接口 （包含随机创建的两个函数，根据网络消息创建的函数）
function HalosandHornsFsMiniMachine:initSlotNodesExcludeOneSymbolType(symbolType, colIndex, reelDatas)
    if symbolType == self.SYMBOL_DEVIL_RISE or symbolType == self.SYMBOL_ANGEL_DECLINE then
        symbolType = 5
    end

    return symbolType
end

function HalosandHornsFsMiniMachine:checkIsAddLastWinSomeEffect()
    -- local notAdd  = false

    -- if #self.m_vecGetLineInfo == 0 then
    --     notAdd = true
    -- end

    -- local specialCoins =  self:getSpecialWinCoins()
    -- if specialCoins and specialCoins > 0 then
    --     notAdd = false
    -- end

    return false
end

function HalosandHornsFsMiniMachine:checkControlerReelType()
    return false
end


---
--添加连线动画
function HalosandHornsFsMiniMachine:addLineEffect()

    for i = 1, #self.m_reelResultLines do
        local lineValue = self.m_reelResultLines[i]
        if not lineValue.enumSymbolType then

            print("HalosandHornsFsMiniMachine ------- lineValue.enumSymbolType 为空")
            release_print("HalosandHornsFsMiniMachine ------- lineValue.enumSymbolType 为空")
            if lineValue.vecValidMatrixSymPos then
                print(json.encode(lineValue.vecValidMatrixSymPos))
                release_print(json.encode(lineValue.vecValidMatrixSymPos))
            else
                print("HalosandHornsFsMiniMachine ------- lineValue.vecValidMatrixSymPos 为空")
            end

            if lineValue.enumSymbolEffectType then
                print(" HalosandHornsFsMiniMachine enumSymbolEffectType________  ".. lineValue.enumSymbolEffectType )
                release_print(" HalosandHornsFsMiniMachine enumSymbolEffectType________  ".. lineValue.enumSymbolEffectType )
            else
                print("HalosandHornsFsMiniMachine ------- lineValue.enumSymbolEffectType 为空")
            end
            
        end
    end

    HalosandHornsFsMiniMachine.super.addLineEffect(self)
end

return HalosandHornsFsMiniMachine