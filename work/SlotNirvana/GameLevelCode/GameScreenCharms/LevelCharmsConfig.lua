--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelCharmsConfig = class("LevelCharmsConfig", LevelConfigData)

LevelCharmsConfig.m_bnBasePro1 = nil
LevelCharmsConfig.m_bnBaseTotalWeight1 = nil

function LevelCharmsConfig:ctor()
      LevelConfigData.ctor(self)
end


--- 专门滚动炸弹的轮盘
--获取普通情况下respin假滚动数据
---@param 
function LevelCharmsConfig:getBoomNormalRespinCloumnByColumnIndex(columnIndex)
      local colKey = "respinCloumn_Boom_"..columnIndex

	return self[colKey]
end
  
---
--获取Freespin情况下respin假滚动数据
---@param 
function LevelCharmsConfig:getBoomNormalFreeSpinRespinCloumnByColumnIndex(columnIndex)
	local colKey = "freespinRespinCloumn_Boom_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end

function LevelCharmsConfig:parseSelfConfigData(colKey,colValue)
	if colKey == "BN_Base1_pro"  then
		self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	end
end

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelCharmsConfig:getFixSymbolPro( )
	local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
	return value[1]
  end
  

return  LevelCharmsConfig