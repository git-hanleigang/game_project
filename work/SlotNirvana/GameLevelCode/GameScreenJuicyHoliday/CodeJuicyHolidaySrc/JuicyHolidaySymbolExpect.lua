
local JuicyHolidaySymbolExpect = class("JuicyHolidaySymbolExpect")

function JuicyHolidaySymbolExpect:initData_(params)
    self.m_machine = params.machine

    self.m_symbolList = params.symbolList
end

-- 接口插入关卡内 xxx:slotOneReelDown
function JuicyHolidaySymbolExpect:MachineOneReelDownCall(colIndex,specialList)
    if self.m_machine.m_isLongRun and colIndex < self.m_machine.m_iReelColumnNum then
        for key,list in pairs(specialList) do
            local symbolType = tonumber(key)
            if self:checkIsExpectSymbol(symbolType) then
                for index,symbolNode in ipairs(list) do
                    --触发快滚时,本列的小块在播完落地后直接播期待,所以不需要在此处做处理
                    if symbolNode.p_cloumnIndex < colIndex then
                        self:playSymbolExpectAnim(symbolNode)
                    end
                    
                end
            end
        end
    elseif colIndex == self.m_machine.m_iReelColumnNum then
        for key,list in pairs(specialList) do
            for index,symbolNode in ipairs(list) do
                --最后一列的播完落地直接接idle
                if symbolNode.p_cloumnIndex < self.m_machine.m_iReelColumnNum then
                    self:playSymbolIdleAnim(symbolNode)
                end
                
            end
        end
    end
end

--[[
    检测是否为触发信号
]]
function JuicyHolidaySymbolExpect:checkIsExpectSymbol(symbolType)
    for k,data in pairs(self.m_symbolList) do
        local list = data.symbolTypeList
        for index,triggerType in pairs(list) do
            if triggerType == symbolType then
                return true
            end
        end
    end
    return false
end



-- 接口插入关卡内 xxx:symbolBulingEndCallBack
function JuicyHolidaySymbolExpect:MachineSymbolBulingEndCall(symbolNode)
    --触发快滚时,除了最后一列,播完落地直接播期待
    if symbolNode.p_cloumnIndex < self.m_machine.m_iReelColumnNum and self.m_machine.m_isLongRun then
        self:playSymbolExpectAnim(symbolNode)
    else
        self:playSymbolIdleAnim(symbolNode)
    end
end

function JuicyHolidaySymbolExpect:playSymbolExpectAnim(_slotsNode)
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
    _slotsNode:runMixAni(animName, true)
end

--播放循环idle
function JuicyHolidaySymbolExpect:playSymbolIdleAnim(_slotsNode)
    --一个关卡有多个循环idle图标时让动效统一命名时间线即可
    local loopIdleName = "idleframe2"
    local bLoop        = true
    local curAnimName  = _slotsNode.m_currAnimName
    if bLoop == _slotsNode.m_slotAnimaLoop and loopIdleName == curAnimName then
        return
    end

    --spine混合
    --[[
        local ccbNode = _slotsNode:checkLoadCCbNode()
        util_spineMix(ccbNode.m_spineNode, curAnimName, loopIdleName, 0.2)
    ]]
    _slotsNode:runMixAni(loopIdleName, true)
end

return JuicyHolidaySymbolExpect