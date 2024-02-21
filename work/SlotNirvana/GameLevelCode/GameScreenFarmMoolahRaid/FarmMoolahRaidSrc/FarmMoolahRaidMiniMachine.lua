---
-- xcyy
-- 2018-12-18
-- FarmMoolahRaidMiniMachine.lua
--
--

local miniSlotReelMachine = require "FarmMoolahRaidSrc.miniSlotReelMachine"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local FarmMoolahRaidMiniMachine = class("FarmMoolahRaidMiniMachine", miniSlotReelMachine)
local GameEffectData = require "data.slotsdata.GameEffectData"

FarmMoolahRaidMiniMachine.m_machineIndex = nil -- csv 文件模块名字
FarmMoolahRaidMiniMachine.gameResumeFunc = nil
FarmMoolahRaidMiniMachine.gameRunPause = nil
FarmMoolahRaidMiniMachine.COLLECT_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 10

-- 构造函数
function FarmMoolahRaidMiniMachine:ctor()
    miniSlotReelMachine.ctor(self)
    self.m_isInitSlotsNode = true
end

function FarmMoolahRaidMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_machine = data.parent
    self.m_reelId = data.reelId
    self.m_maxReelIndex = data.maxReelIndex
    self.m_csbPath = data.csbPath
    self.m_buffs = data.buffs
    self.m_lockd = data.lock
    self:preaseJ(tonumber(self.m_buffs[4].value))
    self.m_lockWildList = {}
    --init
    self:initGame()
end

function FarmMoolahRaidMiniMachine:preaseJ(value)

    if value == 1 then
        self.m_posJ = {8}
    elseif value == 2 then
        self.m_posJ = {8,7}
    elseif value == 3 then
        self.m_posJ = {8,7,6}
    elseif value == 4 then
        self.m_posJ = {8,7,6,5}
    else
        self.m_posJ = {}
    end
end

function FarmMoolahRaidMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function FarmMoolahRaidMiniMachine:MachineRule_newInitGame()
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FarmMoolahRaidMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FarmMoolahRaid"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FarmMoolahRaidMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = self.m_machine:MachineRule_GetSelfCCBName(symbolType)

    return ccbName
end

---
-- 读取配置文件数据
--
function FarmMoolahRaidMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
end


function FarmMoolahRaidMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    self:createCsbNode("FarmMoolahRaid_qipan.csb")

    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

function FarmMoolahRaidMiniMachine:initMachine()
    self.m_moduleName = self:getModuleName()

    miniSlotReelMachine.initMachine(self)
end

----------------------------- 玩法处理 -----------------------------------

function FarmMoolahRaidMiniMachine:addSelfEffect()
    if self.m_randoms and #self.m_randoms > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_WILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_WILD_EFFECT -- 动画类型
    end
end

function FarmMoolahRaidMiniMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_WILD_EFFECT then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        performWithDelay(self,function()
            self:playCollectEffect(effectData)
        end,0.5)
    end
    return true
end

function FarmMoolahRaidMiniMachine:playCollectEffect(effectData)
    --替换低级图标
    self.m_changW = {}
    for i,v in ipairs(self.m_randoms) do
        self:creatWild(tonumber(v))
    end
    if self.m_machineIndex == 1 then
        gLobalSoundManager:playSound("FarmMoolahRaidSounds/sound_FarmMoolah_luodi.mp3")
    end
    performWithDelay(self,function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end,0.7)
end

function FarmMoolahRaidMiniMachine:creatWild(posIndex)
    local fixPos = self:getRowAndColByPos(posIndex)
    local iRow,iCol = fixPos.iX,fixPos.iY
    local symbolNode = self:getFixSymbol(iCol, iRow)
    if symbolNode then
        symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
        local showOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
        symbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 - symbolNode.p_rowIndex + showOrder)
        symbolNode:runAnim("start",false,function()
            if symbolNode.betScore then
                    local symbol_node = symbolNode:checkLoadCCbNode()
                    local spine = symbol_node.m_spineNode
                    util_spineRemoveBindNode(spine,symbolNode.betScore)
                    symbolNode.betScore = nil
            end
            self:addLableNode(symbolNode,self.m_betc,true)
            symbolNode:runAnim("idleframe",true)
        end)
    end
end

function FarmMoolahRaidMiniMachine:onEnter()
    miniSlotReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function FarmMoolahRaidMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function FarmMoolahRaidMiniMachine:insterReelResultLines()
    miniSlotReelMachine.insterReelResultLines(self)
end

function FarmMoolahRaidMiniMachine:reelDownNotifyChangeSpinStatus() 
    
end

function FarmMoolahRaidMiniMachine:reelDownNotifyPlayGameEffect()
    miniSlotReelMachine.reelDownNotifyPlayGameEffect(self)
end

function FarmMoolahRaidMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_machine:setFsAllRunDown(1)
end

function FarmMoolahRaidMiniMachine:quicklyStopReel(colIndex)
    miniSlotReelMachine.quicklyStopReel(self, colIndex)
end

function FarmMoolahRaidMiniMachine:showLineFrame()
    miniSlotReelMachine.showLineFrame(self)
end

function FarmMoolahRaidMiniMachine:onExit()
    miniSlotReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function FarmMoolahRaidMiniMachine:removeObservers()
    miniSlotReelMachine.removeObservers(self)
end

function FarmMoolahRaidMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

function FarmMoolahRaidMiniMachine:beginMiniReel()
    self.m_isInitSlotsNode = false
    
    miniSlotReelMachine.beginReel(self)
    self:clearK()
end

function FarmMoolahRaidMiniMachine:clearK()
    if self.m_lockWildList and #self.m_lockWildList > 0 then
        for i,symbol in ipairs(self.m_lockWildList) do
            if symbol.betScore then
                symbol.betScore:setVisible(false)
            end
            symbol:runAnim("idleframe2",true)
            local showOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            symbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_3 - symbol.p_rowIndex + showOrder)
        end
    end
end

function FarmMoolahRaidMiniMachine:updateReelGridNode(symblNode)
    local buff2 = self.m_buffs[1]
    if not buff2 or tonumber(buff2.value) == 0 then
        return
    end
    if self:isJKSymbol(symblNode.p_symbolType) then
        if symblNode.newsp then
            symblNode.newsp:setVisible(true)
        else
            local sprite = util_createSprite("FarmMoolahRaidCommon/RocketPup_WXN_zhujiemian_tubiaokuang.png")
            symblNode:addChild(sprite)
            symblNode.newsp = sprite
        end
    else
        if symblNode.newsp then
            symblNode.newsp:setVisible(false)
        end
    end
end


-- function FarmMoolahRaidMiniMachine:checkNotifyUpdateWinCoin(_symbol)
    
-- end

function FarmMoolahRaidMiniMachine:isJKSymbol(_symbol)
    local isf = false
    for i,v in ipairs(self.m_posJ) do
        if v == _symbol then
            isf = true
            break
        end
    end
    return isf
end

-- 消息返回更新数据
function FarmMoolahRaidMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)

    local selfData = spinResult.selfData or {}
    -- if selfData.SLOT2_STICKY and #selfData.SLOT2_STICKY > 0 then
    --     self:initFsLockWild(selfData.SLOT2_STICKY)
    -- end
    if selfData.SLOT2_COIN and tonumber(selfData.SLOT2_COIN) > 0 then
        self.m_betc = tonumber(selfData.SLOT2_COIN)
    end
    if selfData.SLOT2_RANDOM and #selfData.SLOT2_RANDOM > 0 then
        self.m_randoms = selfData.SLOT2_RANDOM
    end
    self.m_changW = {}
    self:updateNetWorkData()  
end

function FarmMoolahRaidMiniMachine:enterLevel()
end

function FarmMoolahRaidMiniMachine:enterLevelMiniSelf()
    miniSlotReelMachine.enterLevel(self)
end

function FarmMoolahRaidMiniMachine:dealSmallReelsSpinStates()
    self.m_machine:setFsAllSpinStates(1)
end

-- 轮盘停止回调(自己实现)
function FarmMoolahRaidMiniMachine:setDownCallFunc(func)
    self.m_reelDownCallback = func
end

function FarmMoolahRaidMiniMachine:playEffectNotifyNextSpinCall()
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end

-- 处理特殊关卡 遮罩层级
function FarmMoolahRaidMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
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
--设置bonus scatter 层级
function FarmMoolahRaidMiniMachine:getBounsScatterDataZorder(symbolType)
    return self.m_machine:getBounsScatterDataZorder(symbolType)
end

function FarmMoolahRaidMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines
end

function FarmMoolahRaidMiniMachine:checkGameResumeCallFun()
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

function FarmMoolahRaidMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FarmMoolahRaidMiniMachine:pauseMachine()
    self.gameRunPause = true
end

function FarmMoolahRaidMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

function FarmMoolahRaidMiniMachine:initRandomSlotNodes()
    self.m_initGridNode = true
    self:randomSlotNodes()
    self:initGridList()
end

function FarmMoolahRaidMiniMachine:addLineEffect()
    FarmMoolahRaidMiniMachine.super.addLineEffect(self)
    self:creatWildLabel()
end

function FarmMoolahRaidMiniMachine:isLoakWild(iCol,iRow)
    local pos = self:getPosReelIdx(iRow, iCol)
    local isf = false
    for i,v in ipairs(self.m_lockd) do
        if tonumber(pos) == tonumber(v) then
            isf = true
            break
        end
    end
    return isf
end

function FarmMoolahRaidMiniMachine:creatWildLabel()
   for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow)
            if symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                if symbol.betScore then
                    local symbol_node = symbol:checkLoadCCbNode()
                    local spine = symbol_node.m_spineNode
                    util_spineRemoveBindNode(spine,symbol.betScore)
                    symbol.betScore = nil
                end
                self:addLableNode(symbol,self.m_betc,self:isLoakWild(iCol, iRow))
            end
        end
    end
    if self.m_lockWildList and #self.m_lockWildList > 0 then
        for i,symbol in ipairs(self.m_lockWildList) do
            if symbol.betScore then
                symbol.betScore:setVisible(true)
            else
                self:addLableNode(symbol,self.m_betc,true)
            end
        end
    end
end

---
-- 清空掉产生的数据
--
function FarmMoolahRaidMiniMachine:clearSlotoData()
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

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function FarmMoolahRaidMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function FarmMoolahRaidMiniMachine:clearCurMusicBg()
end

function FarmMoolahRaidMiniMachine:playReelDownSound(_iCol, _path)
    if self.m_reelId == 1 then
        FarmMoolahRaidMiniMachine.super.playReelDownSound(self, _iCol, "FarmMoolahRaidSounds/music_FarmMoolahRaid_Reel_stop.mp3")
    end
end

function FarmMoolahRaidMiniMachine:slotOneReelDown(reelCol)
    FarmMoolahRaidMiniMachine.super.slotOneReelDown(self, reelCol)
end


function FarmMoolahRaidMiniMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function FarmMoolahRaidMiniMachine:getBaseReelsTarSpPos(index)
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos = self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)
    return targSpPos
end
---固定wild
function FarmMoolahRaidMiniMachine:initFsLockWild()
    if #self.m_lockWildList > 0 then
    else
        if self.m_lockd and #self.m_lockd > 0 then
            if self.m_machineIndex == 1 then
                gLobalSoundManager:playSound("FarmMoolahRaidSounds/sound_FarmMoolah_addwild.mp3")
            end
            for k, v in pairs(self.m_lockd) do
                local pos = tonumber(v)
                local fixPos = self:getRowAndColByPos(pos)
                self:addLockWild(fixPos)
            end
        end
    end
end

function FarmMoolahRaidMiniMachine:addLockWild(posIndex, _addSign)
    local wild = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    local iRow,iCol = posIndex.iX,posIndex.iY
    local pos1 = self:getPosReelIdx(posIndex.iX, posIndex.iY)
    local pos = util_getOneGameReelsTarSpPos(self,pos1 ) 
    wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
    self.m_clipParent:addChild(wild, REEL_SYMBOL_ORDER.REEL_ORDER_3 + 100000 - 1, SYMBOL_FIX_NODE_TAG + 1)
    wild.p_cloumnIndex = posIndex.iY
    wild.p_rowIndex = posIndex.iX
    wild.p_oh = 100
    wild:setPosition(pos.x, pos.y)
    local showOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
    wild:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_3 - iRow + showOrder)
    --wild:setTag(self:getNodeTag(wild.p_cloumnIndex, wild.p_rowIndex, SYMBOL_FIX_NODE_TAG+1))
    local linePos = {}
    linePos[#linePos + 1] = {iX = iRow, iY = iCol}
    wild:setLinePos(linePos)
    wild:runAnim("start2",false,function()
        wild:runAnim("idleframe2", true)
    end)
    wild:setLineAnimName("actionframe2")
    wild:setIdleAnimName("idleframe2")
    self.m_lockWildList[#self.m_lockWildList + 1] = wild
end

--wild添加挂点数字
function FarmMoolahRaidMiniMachine:addLableNode(_wild,_bet,_flag)
    local symbol_node = _wild:checkLoadCCbNode()
    local spine = symbol_node.m_spineNode
    -- if not spine then
    --     return
    -- end
    local node, act = util_csbCreate("FarmMoolahRaid_SymbolCoin.csb")
    local label = util_getChildByName(node,"m_lb_coins")
    local coins = globalData.slotRunData:getCurTotalBet() * _bet
    label:setString(util_formatCoins(coins, 3))
    util_spinePushBindNode(spine,"shuzi",node)
    _wild.betScore = node
    if not _flag then
        _wild:runAnim("idleframe",true)
    end
end

function FarmMoolahRaidMiniMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    -- 切换图层
    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    util_changeNodeParent(self.m_clipParent, slotNode, self:getMaskLayerSlotNodeZorder(slotNode) + slotNode.p_showOrder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

return FarmMoolahRaidMiniMachine
