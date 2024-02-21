--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelThorConfig = class("LevelThorConfig", LevelConfigData)

function LevelThorConfig:getBonusReelDatasByColumnIndex(columnIndex)

	local colKey ="reel_cloumn1" .. columnIndex
	return self[colKey]
end


return  LevelThorConfig