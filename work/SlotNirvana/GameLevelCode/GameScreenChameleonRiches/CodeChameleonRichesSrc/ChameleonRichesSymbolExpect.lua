--[[
    图标在快滚时 落地->待触发->循环idle
    和关卡csv配置的落地字段 (SymbolBulingAnim_90,1-buling) 关联 http://192.168.1.26/levels/j2u5o/jcim

    关卡创建:
        self.m_symbolExpectCtr = util_createView("CodeChameleonRichesSrc.ChameleonRichesSymbolExpect", self)
    以下接口需要在关卡内的直接重写:
        ChameleonRichesSymbolExpect:checkSymbolTypePlayTipAnima
    以下接口需要插入关卡内的指定位置:
        ChameleonRichesSymbolExpect:MachineSpinBtnCall             -> xxx:MachineRule_SpinBtnCall
        ChameleonRichesSymbolExpect:MachineResetReelRunDataCall    -> xxx:MachineRule_ResetReelRunData
        ChameleonRichesSymbolExpect:MachineOneReelDownCall         -> xxx:slotOneReelDown
        ChameleonRichesSymbolExpect:MachineSymbolBulingEndCall     -> xxx:symbolBulingEndCallBack
        
]]
local ChameleonRichesSymbolExpect = class("ChameleonRichesSymbolExpect")

function ChameleonRichesSymbolExpect:initData_(_machine)
    self.m_machine = _machine

    self.m_reelRunCol             = 0                     --图标开始播放期待动画的列,棋盘开始快滚的前1列
    self.m_reelRunSymbolTypeList  = {                     --棋盘开始快滚的图标类型列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    }  
    self.m_idleSymbolTypeList     = {                     --循环idle类型的图标列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    }
    self.m_isPlayExpectAni = false

end

-- 接口在关卡内直接重写
--[[
function ChameleonRichesSymbolExpect:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
]]

-- 接口插入关卡内 xxx:MachineRule_SpinBtnCall
function ChameleonRichesSymbolExpect:MachineSpinBtnCall()
    --每次spin重置数据
    self.m_reelRunCol = 0
end

-- 接口插入关卡内 xxx:MachineRule_ResetReelRunData
function ChameleonRichesSymbolExpect:MachineResetReelRunDataCall()
    --计算本次快滚图标类型
    self.m_reelRunSymbolTypeList  = {
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
        self.m_machine.SYMBOL_SCATTER_1,
        self.m_machine.SYMBOL_SCATTER_2
    }
end
function ChameleonRichesSymbolExpect:isReelRunSymbolType(_symbolType)
    for i,_reelRunType in ipairs(self.m_reelRunSymbolTypeList) do
        if _symbolType == _reelRunType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:slotOneReelDown
function ChameleonRichesSymbolExpect:MachineOneReelDownCall(_iCol)
    if self:getNextReelLongRunState(_iCol) then
        if self.m_reelRunCol == 0 then
            self.m_reelRunCol = _iCol
        end
    end
    if _iCol == self.m_machine.m_iReelColumnNum and self.m_isPlayExpectAni then
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
    end
end
--快滚检测 
function ChameleonRichesSymbolExpect:getNextReelLongRunState(_iCol)
    --之前的列和本列都设置了下一列快滚, 和 BaseMachine:slotOneReelDown 保持一致
    if self.m_machine:isPlayExpect(_iCol) and 
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
function ChameleonRichesSymbolExpect:isLoopIdleSymbol(_symbolType)
    for i,_idleSymbolType in ipairs(self.m_idleSymbolTypeList) do
        if _idleSymbolType == _symbolType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:symbolBulingEndCallBack
function ChameleonRichesSymbolExpect:MachineSymbolBulingEndCall(_slotNode)
    if self.m_machine:getGameSpinStage( ) == QUICK_RUN then
        return
    end
    if 0 ~= self.m_reelRunCol then
        --快滚时期待图标
        if self:isReelRunSymbolType(_slotNode.p_symbolType) then
            local iCol = _slotNode.p_cloumnIndex
            if iCol == self.m_reelRunCol then
                self:playExpectAnim(iCol, nil)
            elseif iCol > self.m_reelRunCol and iCol < self.m_machine.m_iReelColumnNum then
                local iRow = _slotNode.p_rowIndex
                self:playExpectAnim(iCol, iRow)
            elseif self:isLoopIdleSymbol(_slotNode.p_symbolType) then
                self:playSymbolIdleAnim(_slotNode)
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
function ChameleonRichesSymbolExpect:playExpectAnim(_iCol, _iRow)
    self.m_isPlayExpectAni = true
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

    --固定图标播期待
    local lockScatters = self.m_machine.m_lockScatterSymbols
    for k,lockNode in pairs(lockScatters) do
        if not lockNode.m_aniName or lockNode.m_aniName ~= "idleframe3_1" and lockNode.m_aniName ~= "idleframe3_2" then
            lockNode.m_aniName = "idleframe3_1"
            util_spineMix(lockNode, "idleframe2", "idleframe3_1", 0.2)
            util_spinePlay(lockNode,"idleframe3_1")
            util_spineEndCallFunc(lockNode,"idleframe3_1",function()
                lockNode.m_aniName = "idleframe3_1"
                util_spinePlay(lockNode,"idleframe3_2",true)
            end)
        end
    end

    local lockScatterWild = self.m_machine.m_scatterWildSymbols
    for k,symbolNode in pairs(lockScatterWild) do
        self:playSymbolExpectAnim(symbolNode)
    end
end
function ChameleonRichesSymbolExpect:playSymbolExpectAnim(_slotsNode)
    --一个关卡有多个期待图标时让动效统一命名时间线即可
    local curAnimName = _slotsNode.m_currAnimName
    if _slotsNode.m_slotAnimaLoop and ("idleframe3_1" == curAnimName or "idleframe3_2" == curAnimName) then
        return
    end

    --spine混合
    --[[
        local ccbNode = _slotsNode:checkLoadCCbNode()
        util_spineMix(ccbNode.m_spineNode, curAnimName, animName, 0.2)
    ]]
    _slotsNode:runMixAni("idleframe3_1",false,function()
        _slotsNode:runMixAni("idleframe3_2",true)
    end)
end


--停止期待动画 
function ChameleonRichesSymbolExpect:stopExpectAnim()
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

    local lockScatterWild = self.m_machine.m_scatterWildSymbols
    for k,symbolNode in pairs(lockScatterWild) do
        self:playSymbolExpectAnim(symbolNode)
    end

    --固定图标停止播期待
    local lockScatters = self.m_machine.m_lockScatterSymbols
    for k,lockNode in pairs(lockScatters) do
        if not lockNode.m_aniName or lockNode.m_aniName ~= "idleframe3_3" and lockNode.m_aniName ~= "idleframe2" then
            lockNode.m_aniName = "idleframe3_3"
            util_spineMix(lockNode, "idleframe3_2", "idleframe3_3", 0.4)
            util_spinePlay(lockNode,"idleframe3_3")
            util_spineEndCallFunc(lockNode,"idleframe3_3",function()
                lockNode.m_aniName = "idleframe2"
                util_spinePlay(lockNode,"idleframe2",true)
            end)
        end
    end
end
--播放循环idle
function ChameleonRichesSymbolExpect:playSymbolIdleAnim(_slotsNode)
    --一个关卡有多个循环idle图标时让动效统一命名时间线即可
    local bLoop        = true
    local curAnimName  = _slotsNode.m_currAnimName
    if curAnimName == "buling" then
        _slotsNode:runMixAni("idleframe2",true)
        return
    end

    if bLoop == _slotsNode.m_slotAnimaLoop and ("idleframe3_3" == curAnimName or "idleframe2" == curAnimName) then
        return
    end

    --spine混合
    --[[
        local ccbNode = _slotsNode:checkLoadCCbNode()
        util_spineMix(ccbNode.m_spineNode, curAnimName, loopIdleName, 0.2)
    ]]
    _slotsNode:runMixAni("idleframe3_3",false,function()
        _slotsNode:runMixAni("idleframe2",true)
    end)
end

return ChameleonRichesSymbolExpect