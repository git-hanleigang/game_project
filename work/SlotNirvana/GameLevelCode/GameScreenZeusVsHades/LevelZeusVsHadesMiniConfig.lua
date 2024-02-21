
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelZeusVsHadesMiniConfig = class("LevelZeusVsHadesMiniConfig", LevelConfigData)

LevelZeusVsHadesMiniConfig.m_replaceSignal = nil

--设置假滚96号替换成的id
function LevelZeusVsHadesMiniConfig:setReplaceSignal(peplaceType)
    self.m_replaceSignal = peplaceType
end

-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelZeusVsHadesMiniConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn" .. columnIndex
    local rundata = {}
    for i = 1, #self[colKey] do
        local symbolType = self[colKey][i]
        if symbolType == 96 then
            symbolType = self.m_replaceSignal
        end
        if symbolType ~= nil then
            table.insert(rundata, symbolType)
        end
    end
    return rundata
end
return  LevelZeusVsHadesMiniConfig