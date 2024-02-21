--[[
    图标在快滚时 落地->待触发->循环idle
    和关卡csv配置的落地字段 (SymbolBulingAnim_90,1-buling) 关联 http://192.168.1.26/levels/j2u5o/jcim

    关卡创建:
        self.m_symbolExpectCtr = util_createView("CodeStarryFestSrc.StarryFestSymbolExpect", self)
    以下接口需要在关卡内的直接重写:
        StarryFestSymbolExpect:checkSymbolTypePlayTipAnima
    以下接口需要插入关卡内的指定位置:
        StarryFestSymbolExpect:MachineSpinBtnCall             -> xxx:MachineRule_SpinBtnCall
        StarryFestSymbolExpect:MachineResetReelRunDataCall    -> xxx:MachineRule_ResetReelRunData
        StarryFestSymbolExpect:MachineOneReelDownCall         -> xxx:slotOneReelDown
        StarryFestSymbolExpect:MachineSymbolBulingEndCall     -> xxx:symbolBulingEndCallBack
        
]]
local StarryFestSymbolExpect = class("StarryFestSymbolExpect")

function StarryFestSymbolExpect:initData_(_machine)
    self.m_machine = _machine

    self.m_reelRunCol             = 0                     --图标开始播放期待动画的列,棋盘开始快滚的前1列
    self.m_reelRunSymbolTypeList  = {                     --棋盘开始快滚的图标类型列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    }  
    self.m_idleSymbolTypeList     = {                     --循环idle类型的图标列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
        self.m_machine.SYMBOL_SCORE_BONUS_1,
        self.m_machine.SYMBOL_SCORE_BONUS_2,
    }
end

-- 接口在关卡内直接重写
--[[
function StarryFestSymbolExpect:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
]]

-- 接口插入关卡内 xxx:MachineRule_SpinBtnCall
function StarryFestSymbolExpect:MachineSpinBtnCall()
    --每次spin重置数据
    self.m_reelRunCol = 0
end

-- 接口插入关卡内 xxx:MachineRule_ResetReelRunData
function StarryFestSymbolExpect:MachineResetReelRunDataCall()
    --计算本次快滚图标类型
    self.m_reelRunSymbolTypeList  = {
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
    }
end
function StarryFestSymbolExpect:isReelRunSymbolType(_symbolType)
    for i,_reelRunType in ipairs(self.m_reelRunSymbolTypeList) do
        if _symbolType == _reelRunType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:slotOneReelDown
function StarryFestSymbolExpect:MachineOneReelDownCall(_iCol)
    performWithDelay(self.m_machine.m_scWaitNode, function()
        if self:getNextReelLongRunState(_iCol) then
            self.m_reelRunCol = _iCol
            self:playExpectAnim(_iCol, nil)
        else
            if _iCol == self.m_machine.m_iReelColumnNum and 0 ~= self.m_reelRunCol then
                --停止所有期待
                self.m_reelRunCol = 0
                self:stopExpectAnim()
            end
        end
    end, 0.1)
end
--快滚检测 
function StarryFestSymbolExpect:getNextReelLongRunState(_iCol)
    --之前的列和本列都设置了下一列快滚, 和 BaseMachine:slotOneReelDown 保持一致
    if self.m_machine:getNextReelIsLongRun(_iCol + 1) and self.m_machine:getGameSpinStage() ~= QUICK_RUN then
        return true 
    end
    --本列设置了下一列快滚,并且本列设置了快滚为true, 和 BaseMachine:setReelLongRun 保持一致
    local reelRunData = self.m_machine.m_reelRunInfo[_iCol]
    if reelRunData:getNextReelLongRun() == true and self.m_machine:getGameSpinStage( ) ~= QUICK_RUN then
        return true 
    end

    return false
end
--循环idle图标检测
function StarryFestSymbolExpect:isLoopIdleSymbol(_symbolType)
    for i,_idleSymbolType in ipairs(self.m_idleSymbolTypeList) do
        if _idleSymbolType == _symbolType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:symbolBulingEndCallBack
function StarryFestSymbolExpect:MachineSymbolBulingEndCall(_slotNode)
    if self:isLoopIdleSymbol(_slotNode.p_symbolType) then
        self:playSymbolIdleAnim(_slotNode)
    end
end

--播放期待动画 
function StarryFestSymbolExpect:playExpectAnim(_iCol, _iRow)
    if not _iRow then
        local maxRow = self.m_machine.m_iReelRowNum
        for iCol=1,_iCol do
            for iRow=1,maxRow do
                local slotsNode = self.m_machine:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                    self:playSymbolExpectAnim(slotsNode)
                end
            end
        end
    else
        local slotsNode = self.m_machine:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
        if self:isReelRunSymbolType(slotsNode.p_symbolType) then
            self:playSymbolExpectAnim(slotsNode)
        end
    end 
end
function StarryFestSymbolExpect:playSymbolExpectAnim(_slotsNode)
    --一个关卡有多个期待图标时让动效统一命名时间线即可
    local animName    = "idleframe3"
    local curAnimName = _slotsNode.m_currAnimName
    if _slotsNode.m_slotAnimaLoop and animName == curAnimName then
        return
    end

    --spine混合
    --[[
        local ccbNode = _slotsNode:checkLoadCCbNode()
        util_spineMix(ccbNode.m_spineNode, curAnimName, animName, 0.2)
    ]]
    _slotsNode:runAnim(animName, true)
end


--停止期待动画 
function StarryFestSymbolExpect:stopExpectAnim()
    local maxCol = self.m_machine.m_iReelColumnNum
    local maxRow = self.m_machine.m_iReelRowNum
    for iCol=1,maxCol do
        for iRow=1,maxRow do
            local slotsNode = self.m_machine:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                self:playSymbolIdleAnim(slotsNode)
            end
        end
    end
end
--播放循环idle
function StarryFestSymbolExpect:playSymbolIdleAnim(_slotsNode)
    --一个关卡有多个循环idle图标时让动效统一命名时间线即可
    if _slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        _slotsNode:runAnim("idleframe2", true)
    elseif _slotsNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS_1 then
        _slotsNode:runAnim("idleframe2", true)
    elseif _slotsNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BONUS_2 then
        _slotsNode:runAnim("idleframe2", true)
    end
end

return StarryFestSymbolExpect