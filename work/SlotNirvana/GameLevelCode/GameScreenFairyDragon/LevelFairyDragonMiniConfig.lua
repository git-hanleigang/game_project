--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFairyDragonMiniConfig = class("LevelFairyDragonMiniConfig", LevelConfigData)
LevelFairyDragonMiniConfig.m_betLeveIndex = 1

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelFairyDragonMiniConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    if self.m_betLeveIndex == 0 then
        colKey = "reel_cloumn_1_"..columnIndex
    end
    return self[colKey]
end

function LevelFairyDragonMiniConfig:setBaseMachineBetLevel( level )
    self.m_betLeveIndex = level
end

return  LevelFairyDragonMiniConfig