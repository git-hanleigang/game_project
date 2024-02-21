
local JuicyHolidayLongRunControl = class("JuicyHolidayLongRunControl")


--[[
    初始数据
    --参数列表
    params = {
        machine = self,
        symbolList = {
            {
                symbolTypeList = {TAG_SYMBOL_TYPE.SYMBOL_SCATTER}, --可触发的信号值
                triggerCount = 3    --触发所需数量
            }
        }
    }
]]
function JuicyHolidayLongRunControl:initData_(params)
    self.m_machine = params.machine
    self.m_symbolList = params.symbolList
    self.longRunStatus = {}
end


--[[
    检测是否触发快滚

    lockNodesInfo格式
    lockNodesInfo = {
        ["90"] = 1
    }
    无固定图标玩法时该参数可为空
]]
function JuicyHolidayLongRunControl:checkTriggerLongRun(lockNodesInfo)
    self.longRunStatus = {}
    --预告中奖时不触发快滚
    if self.m_machine.b_gameTipFlag then
        return
    end

    if not lockNodesInfo then
        lockNodesInfo = {}
    end

    
    for index = 1,#self.m_symbolList do
        local triggerCfg = self.m_symbolList[index]
        self:checkLongRunBySymbolType(triggerCfg,lockNodesInfo)
    end
end

--[[
    根据信号值检测是否触发快滚
]]
function JuicyHolidayLongRunControl:checkLongRunBySymbolType(triggerCfg,lockNodesInfo)
    local symbolTypeList = triggerCfg.symbolTypeList
    local triggerCount = triggerCfg.triggerCount
    local symbolCount = 0
    --计算锁定图标的数量
    for index = 1,#symbolTypeList do
        local symbolType = symbolTypeList[index]
        local lockCount = lockNodesInfo[tostring(symbolType)] or 0
        symbolCount  = symbolCount + lockCount
    end

    --锁定的图标达到快滚的条件
    if symbolCount >= triggerCount - 1 then
        --从第一列开始快滚
        self:setFirstColBeginLongRun()
        return
    end

    local isTriggerType = function(list,symbolType)
        for index = 1,#symbolTypeList do
            if symbolType == list[index] then
                return true
            end
        end

        return false
    end

    --是否已触发快滚
    local isLongRun = false

    local reels = self.m_machine.m_stcValidSymbolMatrix
    for iCol = 1,self.m_machine.m_iReelColumnNum do
        for iRow = 1,#reels do
            --没有触发快滚时,检测目标信号值数量
            if not isLongRun then
                if isTriggerType(symbolTypeList,reels[iRow][iCol]) then
                    symbolCount  = symbolCount + 1
                end
                --达到快滚条件
                if symbolCount >= triggerCount - 1 then
                    --设置快滚状态
                    self:setLongRunInfo(iCol)
                end
            else --已经触发快滚后,则后面的列必定快滚,此时不需要计算信号值数量了,直接设置快滚状态即可
                self:setLongRunInfo(iCol)
            end
            
        end
    end
end

--[[
    设置快滚状态
]]
function JuicyHolidayLongRunControl:setLongRunInfo(colIndex)
    --已经是快滚状态的列不需要再次设置
    if self.longRunStatus[colIndex] then
        return
    end
    self.longRunStatus[colIndex] = true
    --由于传入的列数是已停止的列,所以设置状态是应该设置下一列的状态
    local reelRunData = self.m_machine.m_reelRunInfo[colIndex]
    if self.m_machine:getInScatterShowCol(colIndex + 1) then
        reelRunData:setNextReelLongRun(true)
    end

    if colIndex < self.m_machine.m_iReelColumnNum then
        local nextReelRunData = self.m_machine.m_reelRunInfo[colIndex + 1]

        local runLen = self.m_machine:getLongRunLen(colIndex + 1)
        nextReelRunData:setReelRunLen(runLen)

        if self.m_machine.m_baseReelNodes then
            local reelNode = self.m_machine.m_baseReelNodes[colIndex + 1]
            reelNode:setRunLen(runLen)
        end
    end
    
end

--[[
    设置第一列开始快滚
]]
function JuicyHolidayLongRunControl:setFirstColBeginLongRun()

    local reelRunData = self.m_machine.m_reelRunInfo[1]
    --设置第一列的滚动长度
    local runLen = self.m_machine:getLongRunLen(1)
    reelRunData:setReelRunLen(runLen)
    if self.m_machine.m_baseReelNodes then
        local reelNode = self.m_machine.m_baseReelNodes[1]
        reelNode:setRunLen(runLen)
    end

    for iCol = 1, self.m_machine.m_iReelColumnNum do
        --添加金边
        if iCol == 1 then
            self.m_machine:creatReelRunAnimation(1)
        end
        --后面列加速移动
        local parentData = self.m_machine.m_slotParents[iCol]
        parentData.moveSpeed = self.m_machine.m_configData.p_reelLongRunSpeed

        if self.m_machine.m_baseReelNodes then
            local reelNode = self.m_machine.m_baseReelNodes[iCol]
            reelNode:changeReelMoveSpeed(parentData.moveSpeed)
        end

        self:setLongRunInfo(iCol)
    end
end

return JuicyHolidayLongRunControl
