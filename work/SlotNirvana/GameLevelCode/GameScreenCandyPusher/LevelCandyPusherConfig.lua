local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelCandyPusherConfig = class("LevelCandyPusherConfig", LevelConfigData)

function LevelCandyPusherConfig:ctor()
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
function LevelCandyPusherConfig:getNormalReelDatasByColumnIndex(columnIndex)
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
function LevelCandyPusherConfig:getRunLongDatasByColumnIndex(columnIndex)
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

function LevelCandyPusherConfig:setMysterSymbol(symbolTypeList)
    self.m_mysterList = symbolTypeList
end

function LevelCandyPusherConfig:changeSpecialSymbolList(index)
    if index == 0 then  --normal
        self.p_specialSymbolList = {90,94}
    elseif index == 1 then  --free第一次
        self.p_specialSymbolList = {94}
    end
end

return LevelCandyPusherConfig
