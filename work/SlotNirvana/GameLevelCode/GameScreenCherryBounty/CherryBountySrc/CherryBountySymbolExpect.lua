--[[
    图标在快滚时 落地->待触发->循环idle
    和关卡csv配置的落地字段 (SymbolBulingAnim_90,1-buling) 关联 http://192.168.1.26/levels/j2u5o/jcim

    关卡创建:
        -- 图标期待
        self.m_symbolExpectCtr = util_createView("CherryBountySrc.CherryBountySymbolExpect", self)
    以下接口需要在关卡内的直接重写:
        CherryBountySymbolExpect:checkSymbolTypePlayTipAnima
    以下接口需要插入关卡内的指定位置:
        CherryBountySymbolExpect:MachineSpinBtnCall             -> xxx:MachineRule_SpinBtnCall
        CherryBountySymbolExpect:MachineResetReelRunDataCall    -> xxx:MachineRule_ResetReelRunData
        CherryBountySymbolExpect:MachineOneReelDownCall         -> xxx:slotOneReelDown
        CherryBountySymbolExpect:MachineSymbolBulingEndCall     -> xxx:symbolBulingEndCallBack
        
]]
local CherryBountySymbolExpect = class("CherryBountySymbolExpect")

function CherryBountySymbolExpect:initData_(_machine)
    self.m_machine = _machine

    self.m_reelRunCol             = 0                     --图标开始播放期待动画的列,棋盘开始快滚的前1列
    self.m_reelRunSymbolTypeList  = {                     --棋盘开始快滚的图标类型列表

    }  
    self.m_idleSymbolTypeList     = {                     --循环idle类型的图标列表
    
        -- TAG_SYMBOL_TYPE.SYMBOL_WILD,
        self.m_machine.SYMBOL_Bonus1,
        self.m_machine.SYMBOL_Bonus2,
        self.m_machine.SYMBOL_Bonus3,
    }
end

-- 接口插入关卡内 xxx:MachineRule_SpinBtnCall
function CherryBountySymbolExpect:MachineSpinBtnCall()
    --每次spin重置数据
    self.m_reelRunCol = 0
end

-- 接口插入关卡内 xxx:MachineRule_ResetReelRunData
function CherryBountySymbolExpect:MachineResetReelRunDataCall()



    
end
function CherryBountySymbolExpect:isReelRunSymbolType(_symbolType)
    for i,_reelRunType in ipairs(self.m_reelRunSymbolTypeList) do
        if _symbolType == _reelRunType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:slotOneReelDown
function CherryBountySymbolExpect:MachineOneReelDownCall(_iCol)
    if self:getNextReelLongRunState(_iCol) then
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
            local slotsNode = self.m_machine:getFixSymbol(_iCol, iRow)
            if slotsNode and self:isLoopIdleSymbol(slotsNode.p_symbolType) and not self.m_machine:checkSymbolBulingAnimPlay(slotsNode) then
                self:playSymbolIdleAnim(slotsNode)
            end
        end
    end
end
--快滚检测 
function CherryBountySymbolExpect:getNextReelLongRunState(_iCol)
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
function CherryBountySymbolExpect:isLoopIdleSymbol(_symbolType)
    for i,_idleSymbolType in ipairs(self.m_idleSymbolTypeList) do
        if _idleSymbolType == _symbolType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:symbolBulingEndCallBack
function CherryBountySymbolExpect:MachineSymbolBulingEndCall(_slotNode)
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
function CherryBountySymbolExpect:playExpectAnim(_iCol, _iRow)
    if not _iRow then
        local maxRow = self.m_machine.m_iReelRowNum
        for iCol=1,_iCol do
            for iRow=1,maxRow do
                local slotsNode = self.m_machine:getFixSymbol(iCol, iRow)
                if slotsNode and self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                    self:playSymbolExpectAnim(slotsNode)
                end
            end
        end
    else
        local slotsNode = self.m_machine:getFixSymbol(_iCol, _iRow)
        if slotsNode and self:isReelRunSymbolType(slotsNode.p_symbolType) then
            self:playSymbolExpectAnim(slotsNode)
        end
    end 
end
function CherryBountySymbolExpect:playSymbolExpectAnim(_slotsNode)
    local animName    = "actionframe1"
    local curAnimName = _slotsNode.m_currAnimName
    if _slotsNode.m_slotAnimaLoop and animName == curAnimName then
        return
    end
    _slotsNode:runAnim(animName, true)
end


--停止期待动画 
function CherryBountySymbolExpect:stopExpectAnim()
    local maxCol = self.m_machine.m_iReelColumnNum
    local maxRow = self.m_machine.m_iReelRowNum
    for iCol=1,maxCol do
        for iRow=1,maxRow do
            local slotsNode = self.m_machine:getFixSymbol(iCol, iRow)
            if slotsNode and self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                self:playSymbolIdleAnim(slotsNode)
            end
        end
    end
end
--播放循环idle
function CherryBountySymbolExpect:playSymbolIdleAnim(_slotsNode)
    local loopIdleName = "idleframe2"
    local bLoop        = true
    local curAnimName  = _slotsNode.m_currAnimName
    if _slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        _slotsNode:setIdleAnimName("idleframe2")
        _slotsNode.p_idleIsLoop = true
    end
    if bLoop == _slotsNode.m_slotAnimaLoop and loopIdleName == curAnimName then
        return
    end
    _slotsNode:runAnim(loopIdleName, bLoop)
end

return CherryBountySymbolExpect