--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelRioPinballConfig = class("LevelRioPinballConfig", LevelConfigData)

function LevelRioPinballConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	return self:getNormalReelDatasByColumnIndex(columnIndex)
end

return  LevelRioPinballConfig