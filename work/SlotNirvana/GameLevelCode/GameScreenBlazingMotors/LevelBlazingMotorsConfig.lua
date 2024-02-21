--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelBlazingMotorsConfig = class("LevelBlazingMotorsConfig", LevelConfigData)

function LevelBlazingMotorsConfig:ctor()
      LevelConfigData.ctor(self)
end

---
--获取普通情况下respin假滚动数据
---@param
function LevelBlazingMotorsConfig:getNormalRespinCloumnByColumnIndex(columnIndex)
	local colKey = "respinCloumn_"..columnIndex
	return self[colKey]
end

---
--获取Freespin情况下respin假滚动数据
---@param
function LevelBlazingMotorsConfig:getNormalFreeSpinRespinCloumnByColumnIndex(columnIndex)
	local colKey = "freespinRespinCloumn_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end





return  LevelBlazingMotorsConfig