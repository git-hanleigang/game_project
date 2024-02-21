--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local ScarabChestConfig = class("ScarabChestConfig", LevelConfigData)

ScarabChestConfig.m_bnBasePro = nil
ScarabChestConfig.m_bnBaseTotalWeight = nil

function ScarabChestConfig:ctor()
	ScarabChestConfig.super.ctor(self)
end

function ScarabChestConfig:parseSelfConfigData(colKey, colValue)
	if colKey == "BN_Base_pro" then
		self.m_bnBasePro, self.m_bnBaseTotalWeight = self:parsePro(colValue)
	end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function ScarabChestConfig:getBnBasePro()
	local value = self:getValueByPros(self.m_bnBasePro , self.m_bnBaseTotalWeight)
	return value[1]
end

return ScarabChestConfig
