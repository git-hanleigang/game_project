local PublicConfig = require "CherryBountyPublicConfig"
local CherryBountyReSpinView = class("CherryBountyReSpinView", util_require("Levels.RespinView"))

local ReSpinUiOrder = {
    Floor              = 0,
    ReSpinNode         = 1,
    Frame              = 50,
    SpecialReSpinNode  = REEL_SYMBOL_ORDER.REEL_ORDER_2,
    TriggerReSpinNode  = REEL_SYMBOL_ORDER.REEL_ORDER_2_2-100,
    EFFECT             = REEL_SYMBOL_ORDER.REEL_ORDER_3,
}

--重写-初始化时 附加ui
function CherryBountyReSpinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_bSuper = self.m_machine:isCherryBountySuperReSpin()
    if self.m_bSuper then
        machineColmn = self.m_machine.SuperReSpinCol
    end
    CherryBountyReSpinView.super.initRespinElement(self, machineElement, machineRow, machineColmn, startCallFun)
    self:initReSpinOtherUi()
    self:resetAllReSpinLockSymbolOrder()
end
--附加ui
function CherryBountyReSpinView:initReSpinOtherUi()
    --底板
    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local dibanCsb = util_createAnimation("CherryBounty_respin_diban.csb")
            self:addChild(dibanCsb, ReSpinUiOrder.Floor)
            local reSpinNode = self:getRespinNode(iRow, iCol)   
            dibanCsb:setPosition(util_getConvertNodePos(reSpinNode, self))
        end
    end
    --边框
    self.m_reSpinFrame = util_createAnimation("CherryBounty_respin_frame.csb")
    self:addChild(self.m_reSpinFrame, ReSpinUiOrder.Frame)
    local framePos = util_convertToNodeSpace(self.m_machine:findChild("Node_respinFrame"), self)
    self.m_reSpinFrame:setPosition(framePos)
    self.m_reSpinFrame:findChild("frame_5"):setVisible(not self.m_bSuper)
    self.m_reSpinFrame:findChild("frame_7"):setVisible(self.m_bSuper)
end

--重写-创建的bonus直接播循环idle
function CherryBountyReSpinView:createRespinNode(_symbol, status)
    CherryBountyReSpinView.super.createRespinNode(self, _symbol, status)
    if self:getTypeIsEndType(_symbol.p_symbolType) then
        _symbol:runAnim("idleframe2", true)
    end
end

--重写-滚动开始
function CherryBountyReSpinView:startMove()
    self:resetReSpinBulingSound()
    self.m_bQuickStopReelDown = false
    self.m_bBonus3Buling = false
    self:stopReSpinExpectAnim()
    self:playReSpinReelRunAnim()
    CherryBountyReSpinView.super.startMove(self)
end

--重写-回弹开始播放落地
function CherryBountyReSpinView:respinNodeEndBeforeResCallBack(_symbol)
    CherryBountyReSpinView.super.respinNodeEndBeforeResCallBack(self, _symbol)
    local symbolType = _symbol.p_symbolType
    if self:getTypeIsEndType(symbolType) then
        self:setReSpinLockSymbolOrder(_symbol, true)
        _symbol:runAnim("buling", false, function()
            _symbol:runAnim("idleframe2", true)
        end)
        self:playReSpinSymbolBulingSound(_symbol)
        --bonus3 或者 当前为最后一个bonus落地
        if symbolType == self.m_machine.SYMBOL_Bonus3 or self.m_reelRunCsb then
            self.m_machine:playCherryBountyReelShakeAnim(18/30)
        end
    end
end
--落地音效-区分'快停状态' '落地信号'
function CherryBountyReSpinView:playReSpinSymbolBulingSound(_symbol)
    local symbolType = _symbol.p_symbolType
    local soundName  = nil
    if symbolType == self.m_machine.SYMBOL_Bonus1 then
        soundName  = "CherryBountySounds/sound_CherryBounty_Bonus1_buling.mp3"
    elseif symbolType == self.m_machine.SYMBOL_Bonus2 then
        soundName  = "CherryBountySounds/sound_CherryBounty_Bonus2_buling.mp3"
    elseif symbolType == self.m_machine.SYMBOL_Bonus3 then
        soundName  = "CherryBountySounds/sound_CherryBounty_Bonus3_buling.mp3"
        if not self.m_bBonus3Buling then
            self.m_bBonus3Buling = true
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpinBonus3_buling)
        end
    end
    if soundName then
        self:playReSpinBulingSound(_symbol.p_cloumnIndex, soundName)
    end
end
--落地音效-重置
function CherryBountyReSpinView:resetReSpinBulingSound()
    self.m_quickStopBulingSound = {}
    self.m_commonBulingSound = {}
    for iCol=1,self.m_machineCol do
        self.m_commonBulingSound[iCol] = {}
    end
end
--落地音效-播放
function CherryBountyReSpinView:playReSpinBulingSound(_iCol, _soundName)
    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        if not self.m_quickStopBulingSound[_soundName] then
            self.m_quickStopBulingSound[_soundName] = true
            gLobalSoundManager:playSound(_soundName)
        end
    else
        local colBulingData = self.m_commonBulingSound[_iCol]
        local bHas = colBulingData[_soundName]
        if not bHas then
            colBulingData[_soundName] = true
            gLobalSoundManager:playSound(_soundName)
        end
    end
end

--重写-回弹结束
function CherryBountyReSpinView:runNodeEnd(_symbol)
    if _symbol then
        if self:getTypeIsEndType(_symbol.p_symbolType) then
            self:setReSpinLockSymbolOrder(_symbol, false)
        end
    end
    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
        self:stopReSpinExpectAnim()
        self:stopReSpinReelRunAnim()
        self:playReSpinExpectAnim()
        self:playReSpinFullUpSound()
    end
end
--重写-单列停止
function CherryBountyReSpinView:oneReelDown(_iCol)
    if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        if not self.m_bQuickStopReelDown then
            self.m_bQuickStopReelDown = true
            gLobalSoundManager:playSound(self.m_machine.m_reelDownSound)
        end
    else
        gLobalSoundManager:playSound(self.m_machine.m_quickStopReelDownSound)
    end
end
--全满音效
function CherryBountyReSpinView:playReSpinFullUpSound()
    if not self.m_bFullUp then
        local symbolList = self:getReSpinSymbolList({}, self.m_machine.SYMBOL_ReSpinBlank)
        if #symbolList <= 0 then
            self.m_bFullUp = true
            gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpin_fullUp)
        end
    end
end
--期待效果
function CherryBountyReSpinView:playReSpinExpectAnim()
    local symbolList = self:getReSpinSymbolList({}, self.m_machine.SYMBOL_ReSpinBlank)
    --空图标数量不为1 不播
    local bExpect = 1==#symbolList
    if not bExpect then
        return
    end
    --最后一次spin 不播
    local curTimes = self.m_machine.m_runSpinResultData.p_reSpinCurCount
    if curTimes <= 1 then
        return
    end
    --已经开始播放了
    if self.m_expectCsb then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpin_expect)

    self.m_expectCsb = util_createAnimation("CherryBounty_respin_tx.csb")
    self:addChild(self.m_expectCsb, ReSpinUiOrder.EFFECT)
    local symbol = symbolList[1]
    local pos = util_getConvertNodePos(symbol, self)
    self.m_expectCsb:setPosition(pos)
    self.m_expectCsb:runCsbAction("actionframe", true)
end
function CherryBountyReSpinView:stopReSpinExpectAnim(_bReelRun)
    if self.m_expectCsb and self.m_expectCsb:isVisible() then
        local curTimes = self.m_machine.m_runSpinResultData.p_reSpinCurCount
        if _bReelRun or curTimes < 1 then
            self.m_expectCsb:setVisible(false)
        end
    end
end
--快滚效果
function CherryBountyReSpinView:playReSpinReelRunAnim()
    local symbolList = self:getReSpinSymbolList({}, self.m_machine.SYMBOL_ReSpinBlank)
    local bReelRun = 1==#symbolList
    if not bReelRun then
        return
    end
    local curTimes    = self.m_machine.m_runSpinResultData.p_reSpinCurCount
    if 1 ~= curTimes then
        return
    end
    self:stopReSpinExpectAnim(true)

    if not self.m_reelRunCsb then
        self.m_reelRunCsb = util_createAnimation("CherryBounty_respin_tx_kg.csb")
        self:addChild(self.m_reelRunCsb, ReSpinUiOrder.EFFECT + 1)
    else
        self.m_reelRunCsb:setVisible(true)
    end
    local symbol = symbolList[1]
    local pos = util_getConvertNodePos(symbol, self)
    self.m_reelRunCsb:setPosition(pos)
    self.m_reelRunCsb:runCsbAction("actionframe", true)
    self:playReSpinReelRunSound()
end
function CherryBountyReSpinView:stopReSpinReelRunAnim()
    if self.m_reelRunCsb and self.m_reelRunCsb:isVisible() then
        self.m_reelRunCsb:setVisible(false)
    end
    self:stopReSpinReelRunSound()
end
--快滚音效
function CherryBountyReSpinView:playReSpinReelRunSound()
    if not self.m_reelRunSoundId then
        self.m_reelRunSoundId = gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_ReSpin_reelRun, true)
    end
end
function CherryBountyReSpinView:stopReSpinReelRunSound()
    if self.m_reelRunSoundId then
        gLobalSoundManager:stopAudio(self.m_reelRunSoundId)
        self.m_reelRunSoundId = nil
    end
end

--重写-获取所有最终停止信号 (只获取前5列)
function CherryBountyReSpinView:getAllEndSlotsNode()
    local endSlotNode = {}
    for i,_node in ipairs(self:getChildren()) do
        if _node:getTag() == self.REPIN_NODE_TAG  then
            endSlotNode[#endSlotNode + 1] =  _node
        end
    end
    for i,_repsinNode in ipairs(self.m_respinNodes) do
        if _repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            endSlotNode[#endSlotNode + 1] =  _repsinNode:getLastNode()
        end
    end
    if self.m_machine:isCherryBountySuperReSpin() then
        --舍弃两边 保留中间 列数-1
        for _index=#endSlotNode,1,-1 do
            local symbol = endSlotNode[_index]
            if symbol.p_cloumnIndex < 2 or symbol.p_cloumnIndex > 6 then
                symbol:removeFromParent(false)
                self.m_machine:pushSlotNodeToPoolBySymobolType(symbol.p_symbolType, symbol)
                table.remove(endSlotNode, _index)
            else
                symbol.p_cloumnIndex = symbol.p_cloumnIndex-1
            end
        end
    end
    return endSlotNode
end
--工具-重置所有固定图标的层级
function CherryBountyReSpinView:resetAllReSpinLockSymbolOrder()
    local symbolList = self:getReSpinSymbolList({}, self.m_machine.SYMBOL_Bonus1)
    self:getReSpinSymbolList(symbolList, self.m_machine.SYMBOL_Bonus2)
    self:getReSpinSymbolList(symbolList, self.m_machine.SYMBOL_Bonus3)
    for i,_symbol in ipairs(symbolList) do
        self:setReSpinLockSymbolOrder(_symbol, false)
    end
end

--工具-将一个图标提升到固定层级
function CherryBountyReSpinView:setReSpinSymbolLock(_symbol)
    local iCol = _symbol.p_cloumnIndex
    local iRow = _symbol.p_rowIndex
    local reSpinNode = self:getRespinNode(iRow, iCol)
    local curStatus = reSpinNode:getRespinNodeStatus()
    local worldPos = _symbol:getParent():convertToWorldSpace(cc.p(_symbol:getPosition()))
    local nodePos  = self:convertToNodeSpace(worldPos)
    util_changeNodeParent(self, _symbol, 0)
    self:setReSpinLockSymbolOrder(_symbol, false)
    _symbol:setTag(self.REPIN_NODE_TAG)
    _symbol:setPosition(nodePos)
    reSpinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
end
--工具-设置固定图标的层级
function CherryBountyReSpinView:setReSpinLockSymbolOrder(_symbol, _bTrigger)
    local iCol = _symbol.p_cloumnIndex
    local iRow = _symbol.p_rowIndex
    local baseOrder = ReSpinUiOrder.SpecialReSpinNode
    if _bTrigger then
        baseOrder = ReSpinUiOrder.TriggerReSpinNode
    end
    local order = baseOrder + iCol * 10 - iRow
    _symbol:setLocalZOrder(order)
end
--工具-获取信号小块
function CherryBountyReSpinView:getReSpinSymbolNode(iX, iY)
    local symbolNode = nil
    local childs = self:getChildren()
    for i,node in ipairs(childs) do
        if node:getTag() == self.REPIN_NODE_TAG  then
            if iX == node.p_rowIndex and iY == node.p_cloumnIndex then
                return node
            end
        end
    end
    local reSpinNode = self:getRespinNode(iX, iY)
    if reSpinNode and reSpinNode.m_lastNode then
        return reSpinNode.m_lastNode
    end
    return nil
end
--工具-获取信号列表
function CherryBountyReSpinView:getReSpinSymbolList(_symbolList, _symbolType)
    for iCol=1,self.m_machineColmn do
        for iRow=1,self.m_machineRow do
            local symbol = self:getReSpinSymbolNode(iRow, iCol)
            if _symbolType == symbol.p_symbolType then
                table.insert(_symbolList, symbol)
            end
        end
    end
    return _symbolList
end


return CherryBountyReSpinView