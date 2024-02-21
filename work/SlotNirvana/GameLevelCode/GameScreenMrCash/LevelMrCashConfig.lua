--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMrCashConfig = class("LevelMrCashConfig", LevelConfigData)

function LevelMrCashConfig:ctor()
    LevelConfigData.ctor(self)
    ---
    self.m_mysterList = {}
    for i = 1, 5 do
        self.m_mysterList[i] = -1
    end
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelMrCashConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn" .. columnIndex

    local rundata = {}

    local mysterType = self.m_mysterList[columnIndex]
    if mysterType ~= -1 then
        for i = 1, #self[colKey] do
            local symbolType = mysterType
            table.insert(rundata, symbolType)
        end
        return rundata
    else
        return self[colKey]
    end
end

function LevelMrCashConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
  

    local rundata = {}

    local mysterType = self.m_mysterList[columnIndex]
    if mysterType ~= -1 then
        for i = 1, #self[colKey] do
            local symbolType = mysterType
            table.insert(rundata, symbolType)
        end
        return rundata
    else
        return self[colKey]
    end
end


--
function LevelMrCashConfig:getRunLongDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn" .. columnIndex
    local rundata = {}

    local mysterType = self.m_mysterList[columnIndex]
    if mysterType ~= -1 then
        for i = 1, #self[colKey] do
            local symbolType = mysterType
            table.insert(rundata, symbolType)
        end
        return rundata
    else
        return self[colKey]
    end
end

function LevelMrCashConfig:setMysterSymbol(symbolTypeList)
    self.m_mysterList = symbolTypeList
end

return LevelMrCashConfig
