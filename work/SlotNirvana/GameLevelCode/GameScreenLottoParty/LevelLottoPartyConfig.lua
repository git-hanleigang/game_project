local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelLottoPartyConfig = class("LevelLottoPartyConfig", LevelConfigData)

function LevelLottoPartyConfig:ctor()
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
function LevelLottoPartyConfig:getNormalReelDatasByColumnIndex(columnIndex)
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

--
function LevelLottoPartyConfig:getRunLongDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn_1_" .. columnIndex
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

function LevelLottoPartyConfig:setMysterSymbol(symbolTypeList)
    self.m_mysterList = symbolTypeList
end

return LevelLottoPartyConfig
