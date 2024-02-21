--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelTurkeyDayConfig = class("LevelTurkeyDayConfig", LevelConfigData)

function LevelTurkeyDayConfig:ctor()
	LevelConfigData.ctor(self)
end

function LevelTurkeyDayConfig:getNormalReelDatasByColumnIndexScatter(columnIndex)
	local colKey = "reel_cloumn1_"..columnIndex
	return self[colKey]
end

return LevelTurkeyDayConfig
