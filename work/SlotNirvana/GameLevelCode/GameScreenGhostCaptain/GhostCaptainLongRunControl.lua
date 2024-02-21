--[[
    快滚模块化 start
    *******************************************************************
]]
local GhostCaptainLongRunControl = class("GhostCaptainLongRunControl")

function GhostCaptainLongRunControl:initData_(_machine)
    self.m_machine = _machine
    self.m_curLongRunData = nil
    -- 类型枚举
    self.Enum_LongRunId = {
        ["1toMaxCol"] = "1toMaxCol", -- 任意列都会出（每列只出一个）
        ["135"] = "135", -- 只出现135（每列只出一个）
        ["234"] = "234", -- 只出现234（每列只出一个）
        ["anyNumAnyWhere"] = "anyNumAnyWhere", -- 任意列都会出（每列出现会出现多个）
        ["anyNumContinuity"] = "anyNumContinuity", -- 任意列都会出，并且必须得从左到右每一列至少出现一个（以列的判断基础下连续出现）
        ["mustRun"] = "mustRun" -- 这种类型是为了处理不依托于任何条件下，必然开始从某列快滚从某列结束的情况，例如从第一列就开始快滚
    }
end

-- 可以用这个接口来快速调快滚计算的假数据
function GhostCaptainLongRunControl:getUsingReels()
    return self.usingReels
end

function GhostCaptainLongRunControl:setUsingReels(_reels)
    self.usingReels = _reels
end

function GhostCaptainLongRunControl:getLongRunInfoFromReel(_symbolTypes, _LegitimateCol, _LegitimateNum, _isContinuity)
    local reelDatas = self:getUsingReels()
    local symbolNum = 0
    local info = {}
    info.startCol = 1
    info.endCol = self.m_machine.m_iReelRowNum
    info.LegitimatePos = {}
    info.LegitimateCol = _LegitimateCol
    info.LegitimateNum = _LegitimateNum
    info.longRun = false
    local isContinuity = true
    for index = 1, #_LegitimateCol do
        local iCol = _LegitimateCol[index]
        local isHave = false
        for iRow = 1, self.m_machine.m_iReelRowNum do
            local symbolType = reelDatas[iRow][iCol]
            if table_vIn(_symbolTypes, symbolType) then
                symbolNum = symbolNum + 1
                if symbolNum == _LegitimateNum and iCol < self.m_machine.m_iReelColumnNum then
                    info.startCol = iCol
                    info.longRun = true
                end
                table.insert(info.LegitimatePos, {["iRow"] = iRow, ["iCol"] = iCol, ["symbolType"] = symbolType})
                isHave = true
            end
        end
        info.endCol = iCol
        if _isContinuity and not isHave then
            break
        end
    end
    return info
end

function GhostCaptainLongRunControl:getLongRun1toMaxColInfos(_symbolTypes, _legitimateNum)
    -- 默认规则，一列只出同一个类型中的一个，两个以上开始快滚
    local legitimateCol = {}
    for iCol = 1, self.m_machine.m_iReelColumnNum do
        table.insert(legitimateCol, iCol)
    end
    local legitimateNum = _legitimateNum or 2
    local info = self:getLongRunInfoFromReel(_symbolTypes, legitimateCol, legitimateNum)
    return info
end

function GhostCaptainLongRunControl:getLongRun135ColInfos(_symbolTypes, _legitimateNum)
    -- 默认规则，一列只出同一个类型中的一个，两个以上开始快滚
    local legitimateCol = {1, 3, 5}
    local legitimateNum = _legitimateNum or 2
    local info = self:getLongRunInfoFromReel(_symbolTypes, legitimateCol, legitimateNum)
    if not info.longRun then
        for i=#info.LegitimatePos,1,-1 do
            local posInfo = info.LegitimatePos[i]
            if posInfo.iCol == 3 then
                table.remove( info.LegitimatePos, i )
            end
        end
    else
        info.startCol = 4
    end
    info.unlegitimateCol = {2,4} 
    return info
end

function GhostCaptainLongRunControl:getLongRun234ColInfos(_symbolTypes, _legitimateNum)
    -- 默认规则，一列只出同一个类型中的一个，两个以上开始快滚
    local legitimateCol = {2, 3, 4}
    local legitimateNum = _legitimateNum or 2
    local info = self:getLongRunInfoFromReel(_symbolTypes, legitimateCol, legitimateNum)
    return info
end

function GhostCaptainLongRunControl:getLongRunAnyNumAnyWhereInfos(_symbolTypes, _legitimateNum)
    -- 默认规则，无论任何位置任何条件只要出现规定个数(默认四个)以上后，下一列就快滚
    local legitimateCol = {}
    for iCol = 1, self.m_machine.m_iReelColumnNum do
        table.insert(legitimateCol, iCol)
    end
    local legitimateNum = _legitimateNum or 4
    local info = self:getLongRunInfoFromReel(_symbolTypes, legitimateCol, legitimateNum)
    return info
end

function GhostCaptainLongRunControl:getLongRunAnyNumContinuityInfos(_symbolTypes, _legitimateNum)
    -- 默认规则，从左到右连续出现规定个数(默认四个)以上后，下一列就快滚，必须不能列中断出现
    local legitimateCol = {}
    for iCol = 1, self.m_machine.m_iReelColumnNum do
        table.insert(legitimateCol, iCol)
    end
    local legitimateNum = _legitimateNum or 4
    local info = self:getLongRunInfoFromReel(_symbolTypes, legitimateCol, legitimateNum, true)
    return info
end

function GhostCaptainLongRunControl:getLongRunMustRunInfos(_symbolTypes, _legitimateNum, _musRunInfos)
    -- 默认规则，从左到右连续出现规定个数(默认四个)以上后，下一列就快滚，必须不能列中断出现
    local legitimateCol = {}
    for iCol = _musRunInfos.startCol, _musRunInfos.endCol do
        table.insert(legitimateCol, iCol)
    end
    local legitimateNum = _legitimateNum or 0
    local info = self:getLongRunInfoFromReel(_symbolTypes, legitimateCol, legitimateNum)
    info.startCol = _musRunInfos.startCol
    info.endCol = _musRunInfos.endCol
    info.LegitimateCol = legitimateCol
    info.LegitimateNum = legitimateNum
    info.longRun = true
    return info
end

function GhostCaptainLongRunControl:getLongRunStartAndEndColFromId(_longRunId, _symbolTypes, _legitimateNum, _musRunInfos)
    local infos = {}
    if _longRunId == self.Enum_LongRunId["1toMaxCol"] then
        infos = self:getLongRun1toMaxColInfos(_symbolTypes, _legitimateNum)
    elseif _longRunId == self.Enum_LongRunId["135"] then
        infos = self:getLongRun135ColInfos(_symbolTypes, _legitimateNum)
    elseif _longRunId == self.Enum_LongRunId["234"] then
        infos = self:getLongRun234ColInfos(_symbolTypes, _legitimateNum)
    elseif _longRunId == self.Enum_LongRunId["anyNumAnyWhere"] then
        infos = self:getLongRunAnyNumAnyWhereInfos(_symbolTypes, _legitimateNum)
    elseif _longRunId == self.Enum_LongRunId["anyNumContinuity"] then
        infos = self:getLongRunAnyNumContinuityInfos(_symbolTypes, _legitimateNum)
    elseif _longRunId == self.Enum_LongRunId["mustRun"] then
        infos = self:getLongRunMustRunInfos(_symbolTypes, _legitimateNum, _musRunInfos)
    end

    return infos
end

function GhostCaptainLongRunControl:getLongRunStartAndEndCol(_longRunConfigs)
    local longRunData = {}
    local longRunInfos = {}
    longRunData.startCol = 1
    longRunData.endCol = self.m_machine.m_iReelColumnNum
    longRunData.LegitimatePos = {}
    longRunData.LegitimateColRunId = {}
    longRunData.unlegitimateCol = {}
    longRunData.longRun = false
    for index = 1, #_longRunConfigs do
        local cfg = _longRunConfigs[index]
        local longRunId = cfg["longRunId"]
        local symbolTypes = cfg["symbolType"]
        local legitimateNum = cfg["legitimateNum"] -- 可以不传入，有默认值
        local musRunInfos = cfg["musRunInfos"] -- musRun类型独有参数，其他类型不用处理
        local infos = self:getLongRunStartAndEndColFromId(longRunId, symbolTypes, legitimateNum, musRunInfos)
        infos.longRunId = longRunId
        if table_length(infos) > 0 then
            table.insert(longRunInfos, infos)
        end
    end

    local isHaveAllLongRun = false
    for index = 1, #longRunInfos do
        local longRunInfo = longRunInfos[index]
        longRunData.startCol = util_max(longRunData.startCol, longRunInfo.startCol)
        longRunData.endCol = util_min(longRunData.endCol, longRunInfo.endCol)
        -- 处理不参与快滚的列
        if not longRunInfo.unlegitimateCol or table_length(longRunInfo.unlegitimateCol) == 0 then
            isHaveAllLongRun = true
        end
        if isHaveAllLongRun then
            longRunData.unlegitimateCol = {} -- 但凡有一个整列快滚的，那么就意味着每一列都需要有快滚框，增加滚动长度
        else
            -- 把所有情况的不参与快滚展示的列进行去重存储
            for i=1,#longRunInfo.unlegitimateCol do
                if not table_vIn(longRunData.unlegitimateCol,longRunInfo.unlegitimateCol[i]) then
                    table.insert( longRunData.unlegitimateCol, longRunInfo.unlegitimateCol[i] )
                end
            end
        end
        if longRunInfo.longRun then
            -- 本轮是否有快滚
            longRunData.longRun = true
        end
        for i = 1, #longRunInfo.LegitimatePos do
            local posInfo = longRunInfo.LegitimatePos[i]
            table.insert(longRunData.LegitimatePos, posInfo)
            local LegitimateColRunId = longRunData.LegitimateColRunId
            if not LegitimateColRunId[tostring(posInfo.iCol)] then
                LegitimateColRunId[tostring(posInfo.iCol)] = {}
            end
            if not table_vIn(LegitimateColRunId[tostring(posInfo.iCol)], longRunInfo.longRunId) then
                table.insert(LegitimateColRunId[tostring(posInfo.iCol)], longRunInfo.longRunId)
            end
        end
    end

    self:setCurLongRunData(longRunData)
end

function GhostCaptainLongRunControl:setLongRunLenAndStates()
    local longRunData = self:getCurLongRunData()
    local startCol = longRunData.startCol
    local endCol = longRunData.endCol
    local LegitimatePos = longRunData.LegitimatePos
    local longRun = longRunData.longRun
    local unlegitimateCol = longRunData.unlegitimateCol or {} -- 不播快滚框的列
    -- 设置快滚的小块落地状态
    for i = 1, #LegitimatePos do
        local posInfo = LegitimatePos[i]
        local iCol = posInfo.iCol
        local iRow = posInfo.iRow
        local reelRunData = self.m_machine.m_reelRunInfo[iCol]
        if iCol <= 3 then
            reelRunData:addPos(iRow, iCol, true)
        else
            if iCol == 4 then
                local scatterNum = self:getScatterNumByCol(3)
                if scatterNum > 0 then
                    reelRunData:addPos(iRow, iCol, true)
                else
                    reelRunData:addPos(iRow, iCol, false)
                end
            elseif iCol == 5 then
                local scatterNum = self:getScatterNumByCol(4)
                if scatterNum > 1 then
                    reelRunData:addPos(iRow, iCol, true)
                else
                    reelRunData:addPos(iRow, iCol, false)
                end
            end
        end
    end

    -- 有预告中奖不快滚
    if not longRun or self.m_machine.b_gameTipFlag then
        -- 本轮没有快滚直接返回不做数据处理
        return
    end

    local getBaseRunlen = function(_lastColLens, _colHeight, _columnData,_norAdd)
        local cutTime = 0.2
        -- 不参与快滚的列只滚动cutTime秒的距离
        local reelCount =  self.m_machine.m_configData.p_reelLongRunSpeed * cutTime / _colHeight
        local runLen = _lastColLens + math.floor(reelCount) * _columnData.p_showGridCount --速度x时间 / 列高
        return runLen
    end 

    local getLongRunlen = function(_lastColLens, _colHeight, _columnData,_norAdd)
        local reelCount = (self.m_machine.m_configData.p_reelLongRunTime * self.m_machine.m_configData.p_reelLongRunSpeed) / _colHeight
        local runLen = nil
        if _norAdd then
            -- 不参与快滚的列
            runLen = getBaseRunlen(_lastColLens, _colHeight, _columnData)
        else
            runLen = _lastColLens + math.floor(reelCount) * _columnData.p_showGridCount --速度x时间 / 列高
        end
        
        return runLen
    end

    -- 设置快滚状态和长度
    for iCol = startCol, self.m_machine.m_iReelColumnNum do
        local reelRunData = self.m_machine.m_reelRunInfo[iCol]
        local columnData = self.m_machine.m_reelColDatas[iCol]
        local colHeight = columnData.p_slotColumnHeight
        local runLen = reelRunData:getReelRunLen()
        if iCol == startCol then
            self.m_machine.m_reelRunInfo[iCol]:setNextReelLongRun(true)
            if startCol == 1 then
                runLen = getLongRunlen(0, colHeight, columnData)
            end
        elseif iCol > startCol and iCol <= endCol then
            local lastReelRunInfo = self.m_machine.m_reelRunInfo[iCol - 1]
            local lastColLens = lastReelRunInfo:getReelRunLen()
            if table_vIn(unlegitimateCol,iCol) then
                runLen = getLongRunlen(lastColLens, colHeight, columnData,true)
                self.m_machine.m_reelRunInfo[iCol]:setReelLongRun(false)
            else
                runLen = getLongRunlen(lastColLens, colHeight, columnData)
                self.m_machine.m_reelRunInfo[iCol]:setReelLongRun(true)
            end
            
        elseif iCol > endCol then
            local lastReelRunInfo = self.m_machine.m_reelRunInfo[iCol - 1]
            local lastColLens = lastReelRunInfo:getReelRunLen()
            runLen = getBaseRunlen(lastColLens, colHeight, columnData)
            self.m_machine.m_reelRunInfo[iCol]:setReelLongRun(false)
        end

        if next(self.m_machine.m_reelSlotsList) then
            local columnSlotsList = self.m_machine.m_reelSlotsList[iCol]  -- 提取某一列所有内容
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            local iRow = columnData.p_showGridCount
            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        end
        

        reelRunData:setReelRunLen(runLen)
    end

    if startCol == 1 then
        self:setFirstColBeginLongRun()
    end
end

function GhostCaptainLongRunControl:setCurLongRunData(_longRunData)
    self.m_curLongRunData = _longRunData
end

function GhostCaptainLongRunControl:getCurLongRunData()
    return self.m_curLongRunData
end

function GhostCaptainLongRunControl:clearCurLongRunData()
    self.m_curLongRunData = {}
end

--[[
    @desc: 设置当前滚动速度为快滚的速度，然后显示第一列的快滚框
        如何使用：
            1、这个接口如果有需求在点击spin后消息返回前就显示快滚框并且开始快滚时调用
            2、这个接口与mustRun类型是成对出现的，消息返回后必须要处理一下滚动数据
            3、按照提示方式设置getLongRunStartAndEndCol的mustRun快滚配置处理
]]
function GhostCaptainLongRunControl:setFirstColBeginLongRun()
    for i = 1, self.m_machine.m_iReelColumnNum do
        --添加金边
        if i == 1 then
            self.m_machine:creatReelRunAnimation(1)
        end
        --后面列加速移动
        local parentData = self.m_machine.m_slotParents[i]
        parentData.moveSpeed = self.m_machine.m_configData.p_reelLongRunSpeed
    end
end

--[[  快滚模块化 end
    *******************************************************************
]]
--[[  快滚模块化 Tips
    *******************************************************************
    -------------思路
    1、根据不同的规则去获得 快滚的开始列和结束列，有效区域内的小块位置、信号信息
    2、根据得出的信息去处理 machine类m_reelRunInfo 的滚动长度，小块落地信息
    *******************************************************************

]]

function GhostCaptainLongRunControl:getScatterNumByCol(_col)
    local scatterNum = 0
    for iRow = 1, self.m_machine.m_iReelRowNum do
        for iCol = 1, _col do
            local symbolType = self.usingReels[iRow][iCol]
            if symbolType == 90 then
                scatterNum = scatterNum + 1
            end
        end
    end
    return scatterNum
end
return GhostCaptainLongRunControl
