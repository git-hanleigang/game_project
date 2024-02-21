local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelWheelOfRomanceConfig = class("LevelWheelOfRomanceConfig", LevelConfigData)
LevelWheelOfRomanceConfig.m_mystery = 0

LevelWheelOfRomanceConfig.MYSTERY_TYPE  = 97

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelWheelOfRomanceConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn" .. columnIndex


    local rundata = {}

    for i = 1, #self[colKey] do
        local symbolType = self[colKey][i] 
        if symbolType == self.MYSTERY_TYPE then
            symbolType = self.m_mystery
        end
        table.insert(rundata, symbolType)
    end
  
    return rundata
end

--
function LevelWheelOfRomanceConfig:getRunLongDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn_1_" .. columnIndex
    local rundata = {}

    local rundata = {}

    for i = 1, #self[colKey] do
        local symbolType = self[colKey][i] 
        if symbolType == self.MYSTERY_TYPE then
            symbolType = self.m_mystery
        end
        table.insert(rundata, symbolType)
    end
    return rundata
end

function LevelWheelOfRomanceConfig:setMysterSymbol(_mystery)
    self.m_mystery = _mystery
end

return LevelWheelOfRomanceConfig
