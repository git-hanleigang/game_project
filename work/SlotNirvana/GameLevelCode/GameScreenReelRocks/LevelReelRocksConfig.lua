--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelReelRocksConfig = class("LevelReelRocksConfig", LevelConfigData)

LevelReelRocksConfig.m_bnBasePro1 = nil
LevelReelRocksConfig.m_bnBaseTotalWeight1 = nil

function LevelReelRocksConfig:ctor()
      LevelConfigData.ctor(self)
end




function LevelReelRocksConfig:parseSelfConfigData(colKey,colValue)
	if colKey == "BN_Base1_pro"  then
		self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	end
end

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelReelRocksConfig:getFixSymbolPro( )
	local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
	return value[1]
  end
  

return  LevelReelRocksConfig