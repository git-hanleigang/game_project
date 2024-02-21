--[[
    图标在快滚时 落地->待触发->循环idle
    和关卡csv配置的落地字段 (SymbolBulingAnim_90,1-buling) 关联 http://192.168.1.26/levels/j2u5o/jcim

    关卡创建:
        self.m_symbolExpectCtr = util_createView("CodeScarabChestSrc.ScarabChestSymbolExpect", self)
    以下接口需要在关卡内的直接重写:
        ScarabChestSymbolExpect:checkSymbolTypePlayTipAnima
    以下接口需要插入关卡内的指定位置:
        ScarabChestSymbolExpect:MachineSpinBtnCall             -> xxx:MachineRule_SpinBtnCall
        ScarabChestSymbolExpect:MachineResetReelRunDataCall    -> xxx:MachineRule_ResetReelRunData
        ScarabChestSymbolExpect:MachineOneReelDownCall         -> xxx:slotOneReelDown
        ScarabChestSymbolExpect:MachineSymbolBulingEndCall     -> xxx:symbolBulingEndCallBack
        
]]
local ScarabChestSymbolExpect = class("ScarabChestSymbolExpect")

function ScarabChestSymbolExpect:initData_(_machine)
    self.m_machine = _machine

    self.m_reelRunCol             = 0                     --图标开始播放期待动画的列,棋盘开始快滚的前1列
    self.m_reelRunSymbolTypeList  = {                     --棋盘开始快滚的图标类型列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    }  
    self.m_idleSymbolTypeList     = {                     --循环idle类型的图标列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
        TAG_SYMBOL_TYPE.SYMBOL_WILD,
        self.m_machine.SYMBOL_SCORE_SPECIAL_WILD,
        self.m_machine.SYMBOL_SCORE_JACKPOT_MINOR,
        self.m_machine.SYMBOL_SCORE_JACKPOT_MAJOR,
        self.m_machine.SYMBOL_SCORE_JACKPOT_GRAND
    }
end

-- 接口在关卡内直接重写
--[[
function ScarabChestSymbolExpect:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
]]

-- 接口插入关卡内 xxx:MachineRule_SpinBtnCall
function ScarabChestSymbolExpect:MachineSpinBtnCall()
    --每次spin重置数据
    self.m_reelRunCol = 0
end

-- 接口插入关卡内 xxx:MachineRule_ResetReelRunData
function ScarabChestSymbolExpect:MachineResetReelRunDataCall()
    --计算本次快滚图标类型
    self.m_reelRunSymbolTypeList  = {
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    }
end
function ScarabChestSymbolExpect:isReelRunSymbolType(_symbolType)
    for i,_reelRunType in ipairs(self.m_reelRunSymbolTypeList) do
        if _symbolType == _reelRunType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:slotOneReelDown
function ScarabChestSymbolExpect:MachineOneReelDownCall(_iCol)
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
function ScarabChestSymbolExpect:getNextReelLongRunState(_iCol)
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
function ScarabChestSymbolExpect:isLoopIdleSymbol(_symbolType)
    for i,_idleSymbolType in ipairs(self.m_idleSymbolTypeList) do
        if _idleSymbolType == _symbolType then
            return true
        end
    end
    return false
end

-- 接口插入关卡内 xxx:symbolBulingEndCallBack
function ScarabChestSymbolExpect:MachineSymbolBulingEndCall(_slotNode)
    local isPlay = true
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and _slotNode.m_currAnimName == "idleframe2" then
        isPlay = false
    end
    if self:isLoopIdleSymbol(_slotNode.p_symbolType) then
        self:playSymbolIdleAnim(_slotNode, isPlay)
    end
end

--播放期待动画 
function ScarabChestSymbolExpect:playExpectAnim(_iCol, _iRow)
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
function ScarabChestSymbolExpect:playSymbolExpectAnim(_slotsNode)
    --一个关卡有多个期待图标时让动效统一命名时间线即可
    local animName    = "idleframe2"
    local curAnimName = _slotsNode.m_currAnimName
    if _slotsNode.m_slotAnimaLoop and animName == curAnimName then
        return
    end

    --spine混合
    --[[
        local ccbNode = _slotsNode:checkLoadCCbNode()
        util_spineMix(ccbNode.m_spineNode, curAnimName, animName, 0.2)
    ]]
    _slotsNode:runMixAni(animName, true)
end


--停止期待动画 
function ScarabChestSymbolExpect:stopExpectAnim()
    local maxCol = self.m_machine.m_iReelColumnNum
    local maxRow = self.m_machine.m_iReelRowNum
    for iCol=1,maxCol do
        for iRow=1,maxRow do
            local slotsNode = self.m_machine:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotsNode and self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                self:playSymbolIdleAnim(slotsNode, true)
            end
        end
    end
end
--播放循环idle
function ScarabChestSymbolExpect:playSymbolIdleAnim(_slotsNode, _isPlay)
    --一个关卡有多个循环idle图标时让动效统一命名时间线即可
    if _slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and _isPlay then
        _slotsNode:runAnim("idleframe1", true)
    elseif _slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        _slotsNode:runAnim("idleframe1", true)
    elseif _slotsNode.p_symbolType == self.m_machine.SYMBOL_SCORE_SPECIAL_WILD then
        _slotsNode:runAnim("idleframe1", true)
    elseif _slotsNode.p_symbolType == self.m_machine.SYMBOL_SCORE_JACKPOT_MINOR
     or _slotsNode.p_symbolType == self.m_machine.SYMBOL_SCORE_JACKPOT_MAJOR
     or _slotsNode.p_symbolType == self.m_machine.SYMBOL_SCORE_JACKPOT_GRAND then
        _slotsNode:runAnim("idleframe1", true)
    end
end

return ScarabChestSymbolExpect