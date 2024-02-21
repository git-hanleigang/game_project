
local JollyFactorySymbolExpect = class("JollyFactorySymbolExpect")

function JollyFactorySymbolExpect:initData_(params)
    self.m_machine = params.machine

    self.m_symbolList = params.symbolList

    self.m_bulingEndSymbols = {}
    self.m_isReelDown = false
end

-- 接口插入关卡内 xxx:slotOneReelDown
function JollyFactorySymbolExpect:MachineOneReelDownCall(colIndex,specialList)
    if colIndex == 1 then
        self.m_bulingEndSymbols = {}
        self.m_isReelDown = false
    elseif colIndex == 5 then
        self.m_isReelDown = true
    end
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
function JollyFactorySymbolExpect:checkIsExpectSymbol(symbolType)
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
function JollyFactorySymbolExpect:MachineSymbolBulingEndCall(symbolNode)
    if tolua.isnull(symbolNode) or not self:checkIsExpectSymbol(symbolNode.p_symbolType) then
        return
    end
    local symbolTag = self.m_machine:getNodeTag(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, SYMBOL_NODE_TAG)
    self.m_bulingEndSymbols[tostring(symbolTag)] = true
    --触发快滚时,除了最后一列,播完落地直接播期待
    if symbolNode.p_cloumnIndex < self.m_machine.m_iReelColumnNum and self.m_machine.m_isLongRun then
        self:playSymbolExpectAnim(symbolNode)
    else
        self:playSymbolIdleAnim(symbolNode)
    end
end

function JollyFactorySymbolExpect:playSymbolExpectAnim(_slotsNode)
    if tolua.isnull(_slotsNode) or self.m_isReelDown then
        return
    end
    --一个关卡有多个期待图标时让动效统一命名时间线即可
    local animName    = self:getAniName(_slotsNode.p_symbolType,false)
    local curAnimName = _slotsNode.m_currAnimName
    local symbolTag = self.m_machine:getNodeTag(_slotsNode.p_cloumnIndex, _slotsNode.p_rowIndex, SYMBOL_NODE_TAG)
    if not self.m_bulingEndSymbols[tostring(symbolTag)] or animName == "" or animName == curAnimName then
        return
    end

    local symbolTag = self.m_machine:getNodeTag(_slotsNode.p_cloumnIndex, _slotsNode.p_rowIndex, SYMBOL_NODE_TAG)

    --spine混合
    _slotsNode:runMixAni(animName, true)
end

--[[
    获取对应的动画时间线
]]
function JollyFactorySymbolExpect:getAniName(symbolType,isIdle)
    for k,data in pairs(self.m_symbolList) do
        local list = data.symbolTypeList
        for index,triggerType in pairs(list) do
            if triggerType == symbolType then
                if isIdle then
                    return data.idleAni
                else
                    return data.expectAni
                end
                
            end
        end
    end
    return ""
end

--播放循环idle
function JollyFactorySymbolExpect:playSymbolIdleAnim(_slotsNode)
    --没播完落地的等播完落地再播idle
    local symbolTag = self.m_machine:getNodeTag(_slotsNode.p_cloumnIndex, _slotsNode.p_rowIndex, SYMBOL_NODE_TAG)
    if not self.m_bulingEndSymbols[tostring(symbolTag)] or  tolua.isnull(_slotsNode) then
        return
    end
    --一个关卡有多个循环idle图标时让动效统一命名时间线即可
    local loopIdleName = self:getAniName(_slotsNode.p_symbolType,true)
    local curAnimName  = _slotsNode.m_currAnimName
    if loopIdleName == "" or loopIdleName == curAnimName then
        return
    end

    --spine混合
    _slotsNode:runMixAni(loopIdleName, true)
end

return JollyFactorySymbolExpect