--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMagicLadyConfig = class("LevelMagicLadyConfig", LevelConfigData)


function LevelMagicLadyConfig:parseSelfConfigData(colKey, colValue)
	if colKey == "BN_Base1_pro" then
	    self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end
--获取假滚bonus显示的倍数
function LevelMagicLadyConfig:getFixSymbolPro()
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end

return  LevelMagicLadyConfig