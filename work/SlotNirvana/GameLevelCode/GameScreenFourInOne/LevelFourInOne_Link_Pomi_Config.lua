--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFourInOne_Link_Pomi_Config = class("LevelFourInOne_Link_Pomi_Config", LevelConfigData)

function LevelFourInOne_Link_Pomi_Config:ctor()
      LevelConfigData.ctor(self)
end


--- 专门滚动炸弹的轮盘
--获取6列普通情况下respin假滚动数据
---@param 
function LevelFourInOne_Link_Pomi_Config:get6ReelNormalRespinCloumnByColumnIndex(columnIndex)
      local colKey = "sixReel_respinCloumn_"..columnIndex

	return self[colKey]
end
  
---
--获取Freespin情况下6列respin假滚动数据
---@param 
function LevelFourInOne_Link_Pomi_Config:get6ReelNormalFreeSpinRespinCloumnByColumnIndex(columnIndex)
	local colKey = "freespinRespinCloumn_Boom_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:get6ReelNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end




function LevelFourInOne_Link_Pomi_Config:parseSelfConfigData(colKey, colValue)
    
	if colKey == "BN_Base1_pro" then
	    self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	end
  end
  --[[
	time:2018-11-28 16:39:26
	@return: 返回中的倍数
  ]]
  function LevelFourInOne_Link_Pomi_Config:getFixSymbolPro( )
	local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
	return value[1]
  end
  

return  LevelFourInOne_Link_Pomi_Config