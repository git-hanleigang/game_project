local LevelConfigData = require("data.slotsdata.LevelConfigData")
local SoaringWealthConfig = class("SoaringWealthConfig", LevelConfigData)

function SoaringWealthConfig:ctor()
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
function SoaringWealthConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local curShowRow = self.m_machine.m_curShowRow
    local colKey = string.format("reel_cloumn_%d_%d", curShowRow, columnIndex)

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

---
-- 获取freespin model 对应的reel 列数据
--
function SoaringWealthConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
    local curShowRow = self.m_machine.m_curShowRow
	local colKey = string.format("freespinModeId_%d_%d",curShowRow,columnIndex)

	return self[colKey]
end

function SoaringWealthConfig:setMainMachine(_machine)
    self.m_machine = _machine
end

function SoaringWealthConfig:setMysterSymbol(symbolTypeList)
    self.m_mysterList = symbolTypeList
end

return SoaringWealthConfig
