-- FIX IOS 139 1
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelTrainYourDragonConfig = class("LevelTrainYourDragonConfig", LevelConfigData)


function LevelTrainYourDragonConfig:parseSelfConfigData(colKey, colValue)
	if colKey == "BN_Base1_pro" then
	    self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end
--获取假滚bonus显示的倍数
function LevelTrainYourDragonConfig:getFixSymbolPro()
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end

return  LevelTrainYourDragonConfig