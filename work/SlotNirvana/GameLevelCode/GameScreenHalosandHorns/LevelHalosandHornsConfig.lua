--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelHalosandHornsFsReelConfig = class("LevelHalosandHornsFsReelConfig", LevelConfigData)


---
-- 获取freespin model 对应的reel 列数据
--
function LevelHalosandHornsFsReelConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	local colKey = string.format("reel_cloumn",columnIndex)

	return self[colKey]
end

return  LevelHalosandHornsFsReelConfig