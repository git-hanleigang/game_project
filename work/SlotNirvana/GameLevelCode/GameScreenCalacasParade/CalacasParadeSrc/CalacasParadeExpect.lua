--[[
    图标在快滚时 落地->待触发->循环idle
    和关卡csv配置的落地字段 (SymbolBulingAnim_90,1-buling) 关联 http://192.168.1.26/levels/j2u5o/jcim

    关卡创建:
        -- 图标期待
        self.m_symbolExpectCtr = util_createView("CalacasParadeSrc.CalacasParadeExpect", self)
    以下接口需要在关卡内的直接重写:
        CalacasParadeExpect:checkSymbolTypePlayTipAnima
    以下接口需要插入关卡内的指定位置:
        CalacasParadeExpect:MachineSpinBtnCall             -> xxx:MachineRule_SpinBtnCall
        CalacasParadeExpect:MachineResetReelRunDataCall    -> xxx:MachineRule_ResetReelRunData
        CalacasParadeExpect:MachineOneReelDownCall         -> xxx:slotOneReelDown
        CalacasParadeExpect:MachineSymbolBulingEndCall     -> xxx:symbolBulingEndCallBack
        
]]
local CalacasParadeExpect = class("CalacasParadeExpect")

function CalacasParadeExpect:initData_(_machine)
    self.m_machine = _machine

    self.m_reelRunCol             = 0                     --图标开始播放期待动画的列,棋盘开始快滚的前1列
    self.m_reelRunSymbolTypeList  = {                     --棋盘开始快滚的图标类型列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    }  
    self.m_idleSymbolTypeList     = {                     --循环idle类型的图标列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
        self.m_machine.SYMBOL_BonusCoins,
        self.m_machine.SYMBOL_BonusTicket_1,
        self.m_machine.SYMBOL_BonusTicket_2,
        self.m_machine.SYMBOL_BonusTicket_3,
        self.m_machine.SYMBOL_BonusTicket_4,
        self.m_machine.SYMBOL_SpecialBonus1,
        self.m_machine.SYMBOL_SpecialBonus2,
    }
end

-- 接口插入关卡内 xxx:MachineRule_SpinBtnCall
function CalacasParadeExpect:MachineSpinBtnCall()
    --每次spin重置数据
    self.m_reelRunCol = 0
end

-- 接口插入关卡内 xxx:MachineRule_ResetReelRunData
function CalacasParadeExpect:MachineResetReelRunDataCall(_bBonus)
    --计算本次快滚图标类型
    if _bBonus then
        self.m_reelRunSymbolTypeList  = {
            -- self.m_machine.SYMBOL_BonusCoins,
            self.m_machine.SYMBOL_BonusTicket_1,
            self.m_machine.SYMBOL_BonusTicket_2,
            self.m_machine.SYMBOL_BonusTicket_3,
            self.m_machine.SYMBOL_BonusTicket_4,
        }
    else
        self.m_reelRunSymbolTypeList  = {
            TAG_SYMBOL_TYPE.SYMBOL_SCATTER
        }
    end
end
function CalacasParadeExpect:isReelRunSymbolType(_symbolType)
    for i,_reelRunType in ipairs(self.m_reelRunSymbolTypeList) do
        if _symbolType == _reelRunType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:slotOneReelDown
function CalacasParadeExpect:MachineOneReelDownCall(_iCol)
    if self:getNextReelLongRunState(_iCol+1) then
        if self.m_reelRunCol == 0 then
            self.m_reelRunCol = _iCol
        end
    end
    if _iCol == self.m_machine.m_iReelColumnNum and 0 ~= self.m_reelRunCol then
        --停止所有期待
        self.m_reelRunCol = 0
        self:stopExpectAnim()
    else
        --循环idle图标
        local maxRow = self.m_machine.m_iReelRowNum
        for iRow=1,maxRow do
            local slotsNode = self.m_machine:getFixSymbol(_iCol, iRow, SYMBOL_NODE_TAG)
            if slotsNode and self:isLoopIdleSymbol(slotsNode.p_symbolType) and not self.m_machine:checkSymbolBulingAnimPlay(slotsNode) then
                self:playSymbolIdleAnim(slotsNode)
            end
        end
        --本列没有期待图标 但是下一列快滚时 之前列期待图标直接播动画
        if 0 ~= self.m_reelRunCol then
            local bHas = false
            local maxRow = self.m_machine.m_iReelRowNum
            for iRow=1,maxRow do
                local slotsNode = self.m_machine:getFixSymbol(_iCol, iRow, SYMBOL_NODE_TAG)
                if slotsNode and self:isReelRunSymbolType(slotsNode.p_symbolType) then
                    bHas = true
                    break
                end
            end
            if not bHas then
                self:playExpectAnim(_iCol-1, nil)
            end
        end
    end
end
--快滚检测 
function CalacasParadeExpect:getNextReelLongRunState(_iCol)
    if _iCol > self.m_machine.m_iReelColumnNum then
        return false
    end
    --之前的列和本列都设置了下一列快滚, 和 BaseMachine:slotOneReelDown 保持一致
    if self.m_machine:getNextReelIsLongRun(_iCol + 1) and 
        (self.m_machine:getGameSpinStage() ~= QUICK_RUN or self.m_machine.m_hasBigSymbol == true) then
        
        return true 
    end
    --本列设置了下一列快滚,并且本列设置了快滚为true, 和 BaseMachine:setReelLongRun 保持一致
    local reelRunData = self.m_machine.m_reelRunInfo[_iCol]
    if reelRunData:getNextReelLongRun() == true and 
        (self.m_machine:getGameSpinStage( ) ~= QUICK_RUN or self.m_machine.m_hasBigSymbol == true) then

        return true 
    end

    return false
end
--循环idle图标检测
function CalacasParadeExpect:isLoopIdleSymbol(_symbolType)
    for i,_idleSymbolType in ipairs(self.m_idleSymbolTypeList) do
        if _idleSymbolType == _symbolType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:symbolBulingEndCallBack
function CalacasParadeExpect:MachineSymbolBulingEndCall(_slotNode)
    if 0 ~= self.m_reelRunCol then
        --快滚时期待图标
        if self:isReelRunSymbolType(_slotNode.p_symbolType) then
            local iCol = _slotNode.p_cloumnIndex
            if iCol == self.m_reelRunCol then
                self:playExpectAnim(iCol, nil)
            elseif iCol > self.m_reelRunCol and iCol < self.m_machine.m_iReelColumnNum then
                local iRow = _slotNode.p_rowIndex
                self:playExpectAnim(iCol, iRow)
            end
        elseif self:isLoopIdleSymbol(_slotNode.p_symbolType) then
            self:playSymbolIdleAnim(_slotNode)
        end
    else
        if self:isLoopIdleSymbol(_slotNode.p_symbolType) then
            self:playSymbolIdleAnim(_slotNode)
        end
    end
end

--播放期待动画 
function CalacasParadeExpect:playExpectAnim(_iCol, _iRow)
    if not _iRow then
        local maxRow = self.m_machine.m_iReelRowNum
        for iCol=1,_iCol do
            for iRow=1,maxRow do
                local slotsNode = self.m_machine:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotsNode and self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                    self:playSymbolExpectAnim(slotsNode)
                end
            end
        end
    else
        local slotsNode = self.m_machine:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
        if slotsNode and self:isReelRunSymbolType(slotsNode.p_symbolType) then
            self:playSymbolExpectAnim(slotsNode)
        end
    end 
end
function CalacasParadeExpect:playSymbolExpectAnim(_slotsNode)
    --一个关卡有多个期待图标时让动效统一命名时间线即可
    local animName    = "idleframe3"
    local curAnimName = _slotsNode.m_currAnimName
    if _slotsNode.m_slotAnimaLoop and animName == curAnimName then
        return
    end
    _slotsNode:runAnim(animName, true)
end


--停止期待动画 
function CalacasParadeExpect:stopExpectAnim()
    local maxCol = self.m_machine.m_iReelColumnNum
    local maxRow = self.m_machine.m_iReelRowNum
    for iCol=1,maxCol do
        for iRow=1,maxRow do
            local slotsNode = self.m_machine:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotsNode and self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                self:playSymbolIdleAnim(slotsNode)
            end
        end
    end
end
--播放循环idle 临时小块创建后也可以调用
function CalacasParadeExpect:playSymbolIdleAnim(_slotsNode)
    --一个关卡有多个循环idle图标时让动效统一命名时间线即可
    local loopIdleName = "idleframe2"
    local symbolType = _slotsNode.p_symbolType or _slotsNode.m_symbolType
    if self.m_machine:isCalacasParadeBonus2(symbolType) then
        loopIdleName = "idleframe4"
    end
    if _slotsNode.m_slotAnimaLoop and loopIdleName == _slotsNode.m_currAnimName then
        return
    end

    _slotsNode:runMixAni(loopIdleName, true)
end

return CalacasParadeExpect