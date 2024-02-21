--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPudgyPandaConfig = class("LevelPudgyPandaConfig", LevelConfigData)

function LevelPudgyPandaConfig:ctor()
	LevelPudgyPandaConfig.super.ctor(self)
end

--需要提高层级的类型
function LevelPudgyPandaConfig:checkSpecialSymbol(symbolType)
	if not symbolType then
		return false
	end
	
	if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
		return false
	end

	if not self.p_specialSymbolList or #self.p_specialSymbolList== 0 then
		return false
	end
	--配置的特殊层级信号
	for i=1,#self.p_specialSymbolList do
		if self.p_specialSymbolList[i] == symbolType then
			return true
		end
	end
	return false
end

return LevelPudgyPandaConfig
