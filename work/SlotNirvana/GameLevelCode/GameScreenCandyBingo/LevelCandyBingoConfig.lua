--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelCandyBingoConfig = class("LevelCandyBingoConfig", LevelConfigData)

function LevelCandyBingoConfig:ctor()
      LevelConfigData.ctor(self)
end

---
--获取普通情况下respin假滚动数据
---@param 
function LevelCandyBingoConfig:getNormalRespinCloumnByColumnIndex(columnIndex)
	local colKey = "reel_cloumn"..columnIndex
	local data = self[colKey]

	for k,v in pairs(data) do
            if k % 4 == 0 then
                local type = self:getNormalRespinCloumnByColumnIndex_Two(columnIndex)
                table.insert( data, type )
            end
	end

	return data
end
  
---
--获取Freespin情况下respin假滚动数据
---@param 
function LevelCandyBingoConfig:getNormalFreeSpinRespinCloumnByColumnIndex(columnIndex)
	local colKey = "freespinModeId_0_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	for k,v in pairs(data) do
            if k % 4 == 0 then
                local type = self:getNormalFreeSpinRespinCloumnByColumnIndex_Two(columnIndex)
                table.insert( data, type )
            end
	end

	return data
end

function LevelCandyBingoConfig:getNormalFreeSpinRespinCloumnByColumnIndex_Two(columnIndex)
	local colKey = "freespinModeId_0_"..columnIndex.."_2"
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	local index = math.random( 1, #data )
	local type = data[index]

	return type
end

---
--获取普通情况下respin假滚动数据
---@param 
function LevelCandyBingoConfig:getNormalRespinCloumnByColumnIndex_Two(columnIndex)
	local colKey = "reel_cloumn"..columnIndex.."_2"
	local data = self[colKey]
	local index = math.random( 1, #data )
	local type = data[index]


	return type
end

  



return  LevelCandyBingoConfig