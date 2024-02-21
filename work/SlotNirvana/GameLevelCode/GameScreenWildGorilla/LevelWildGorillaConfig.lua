local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelWildGorillaConfig = class("LevelWildGorillaConfig", LevelConfigData)
-- FIX IOS 139
function LevelWildGorillaConfig:ctor()
    LevelConfigData.ctor(self)
end

function LevelWildGorillaConfig:parseSelfConfigData(colKey, colValue)
    if colKey == "BN_Base1_pro" then
        self.m_bnBasePro1, self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end

function LevelWildGorillaConfig:getFixSymbolPro()
    local value = self:getValueByPros(self.m_bnBasePro1, self.m_bnBaseTotalWeight1)
    return value[1]
end

return LevelWildGorillaConfig
