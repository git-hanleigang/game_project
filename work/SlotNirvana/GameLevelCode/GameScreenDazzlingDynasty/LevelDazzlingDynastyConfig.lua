--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 16:17:25
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelDazzlingDynastyConfig = class("LevelDazzlingDynastyConfig", LevelConfigData)

LevelDazzlingDynastyConfig.m_bnBasePro1 = nil
LevelDazzlingDynastyConfig.m_bnBaseTotalWeight1 = nil

function LevelDazzlingDynastyConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelDazzlingDynastyConfig:parseSelfConfigData(colKey, colValue)
    
      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end
end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
function LevelDazzlingDynastyConfig:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
end


return  LevelDazzlingDynastyConfig