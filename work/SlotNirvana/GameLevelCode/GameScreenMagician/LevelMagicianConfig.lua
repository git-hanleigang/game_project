--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于MiracleEgyptConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMagicianConfig = class("LevelMagicianConfig", LevelConfigData)

function LevelMagicianConfig:parseSelfConfigData(colKey, colValue)
    if colKey == "BN_Base_pro" then
        self.m_bnBasePro , self.m_bnBaseTotalWeight = self:parsePro(colValue)
    end
    
end
--[[
  time:2018-11-28 16:39:26
  @return: 返回中的倍数
]]
function LevelMagicianConfig:getBnBasePro()
    local value = self:getValueByPros(self.m_bnBasePro , self.m_bnBaseTotalWeight)
    return value[1]
end


return  LevelMagicianConfig