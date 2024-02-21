--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local PowerUpConfig2 = class("PowerUpConfig2", LevelConfigData)

function PowerUpConfig2:ctor()
      LevelConfigData.ctor(self)
end

---
---@param
function PowerUpConfig2:getHighCloumnByColumnIndex(columnIndex)
	local colKey = "reel_cloumn_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end

return  PowerUpConfig2