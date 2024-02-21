--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelGeminiJourneyConfig = class("LevelGeminiJourneyConfig", LevelConfigData)

LevelGeminiJourneyConfig.m_bnBasePro1 = nil
LevelGeminiJourneyConfig.m_bnBaseTotalWeight1 = nil

function LevelGeminiJourneyConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelGeminiJourneyConfig:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Base1_pro" then
            self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelGeminiJourneyConfig:getBnBasePro(type)
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
end

return  LevelGeminiJourneyConfig