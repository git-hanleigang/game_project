--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelAllStarConfig = class("LevelAllStarConfig", LevelConfigData)

LevelAllStarConfig.m_bnBasePro1 = nil
LevelAllStarConfig.m_bnBaseTotalWeight1 = nil

function LevelAllStarConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelAllStarConfig:parseSelfConfigData(colKey, colValue)
    
	if colKey == "BN_Base1_pro" then
	    self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	end
end
  --[[
	time:2018-11-28 16:39:26
	@return: 返回中的倍数
  ]]
function LevelAllStarConfig:getFixSymbolPro( )
	local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
	return value[1]
end
  

  
---
--获取Freespin情况下bonus假滚动数据
---@param 
function LevelAllStarConfig:get_MID_LOCK_CloumnByColumnIndex(columnIndex)
	local colKey = "respinCloumn_MID_LOCK_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end

---@param 
function LevelAllStarConfig:get_ADD_WILD_CloumnByColumnIndex(columnIndex)
	local colKey = "respinCloumn_ADD_WILD_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end
---@param 
function LevelAllStarConfig:get_TWO_LOCK_CloumnByColumnIndex(columnIndex)
	local colKey = "respinCloumn_TWO_LOCK_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end

---@param 
function LevelAllStarConfig:get_Double_BET_CloumnByColumnIndex(columnIndex)
	local colKey = "respinCloumn_Double_BET_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end

  



return  LevelAllStarConfig