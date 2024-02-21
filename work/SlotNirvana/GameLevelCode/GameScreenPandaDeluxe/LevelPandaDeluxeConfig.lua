--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPandaDeluxeConfig = class("LevelPandaDeluxeConfig", LevelConfigData)

LevelPandaDeluxeConfig.m_betLevel = 1

LevelPandaDeluxeConfig.m_freeSpinType = 0

function LevelPandaDeluxeConfig:setBetLevel( betLevel )
    self.m_betLevel = betLevel


end

function LevelPandaDeluxeConfig:setFreeSpinType( freeSpinType )
    self.m_freeSpinType = freeSpinType
end

function LevelPandaDeluxeConfig:getChangedList(  )

    
    --[[
        最高bet 不变
        第二高  0信号+5
        第三高  0~1信号+5
        第四高  0~2信号+5
        最低      0~3信号+5
    ]]

    local list = {}

    if self.m_betLevel == 1 then
        list = {0,1,2,3}
    elseif self.m_betLevel == 2 then
        list = {0,1,2}
    elseif self.m_betLevel == 3 then
        list = {0,1}
    elseif self.m_betLevel == 4 then
        list = {0}
    elseif self.m_betLevel == 5 then
        list = {}
    end

    return list
end

function LevelPandaDeluxeConfig:isInList(array,value )
    for i=1,#array do
        if array[i] == value then
            
            return true
        end
    end
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelPandaDeluxeConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    
    local baseChangedList = self:getChangedList( )

    local reelDatas =  {}
    
    for i=1,#self[colKey] do
        local symbolType = self[colKey][i]
        if self:isInList(baseChangedList,symbolType ) then
            symbolType = symbolType + 5
        end
        
        table.insert(reelDatas,symbolType) 
    end


    return reelDatas
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelPandaDeluxeConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

	local reelDatas = {}
    
    for i=1,#self[colKey] do
       local symbolType = self[colKey][i]

        if symbolType == 96 then
            symbolType = self.m_freeSpinType
        end

        table.insert(reelDatas,symbolType) 
    end


    return reelDatas
end



return  LevelPandaDeluxeConfig