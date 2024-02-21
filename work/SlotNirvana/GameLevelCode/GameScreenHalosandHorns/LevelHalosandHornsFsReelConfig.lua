--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelHalosandHornsFsReelConfig = class("LevelHalosandHornsFsReelConfig", LevelConfigData)

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelHalosandHornsFsReelConfig:getNormalReelDatasByColumnIndex(columnIndex)
	local colKey = "freespinModeId_0_"..columnIndex

	return self[colKey]
end

  
return  LevelHalosandHornsFsReelConfig