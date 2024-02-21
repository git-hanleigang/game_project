--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelDemonessFairConfig = class("LevelDemonessFairConfig", LevelConfigData)

LevelDemonessFairConfig.m_bnBasePro1 = nil
LevelDemonessFairConfig.m_bnBaseTotalWeight1 = nil

LevelDemonessFairConfig.m_bnBasePro2 = nil
LevelDemonessFairConfig.m_bnBaseTotalWeight2 = nil

function LevelDemonessFairConfig:ctor()
	LevelConfigData.ctor(self)
end

function LevelDemonessFairConfig:parseSelfConfigData(colKey, colValue)
	if colKey == "BN_Base1_pro" then
		self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	elseif colKey == "BN_Base2_pro" then
		self.m_bnBasePro2 , self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
	end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelDemonessFairConfig:getBnBasePro(_isRepeat)
	local value
	if _isRepeat then
		value = self:getValueByPros(self.m_bnBasePro2 , self.m_bnBaseTotalWeight2)
	else
		value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
	end
	return value[1]
end

return  LevelDemonessFairConfig
