--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-08 12:28:45
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelGoldlExpressConfig = class("LevelGoldlExpressConfig", LevelConfigData)

LevelGoldlExpressConfig.m_bnBasePro1 = nil
LevelGoldlExpressConfig.m_bnBaseTotalWeight1 = nil

function LevelGoldlExpressConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelGoldlExpressConfig:parseSelfConfigData(colKey, colValue)

      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
  
      elseif colKey == "BN_Base2_pro" then
          self.m_bnBasePro2, self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
      end

  end
  
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelGoldlExpressConfig:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end
  
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelGoldlExpressConfig:getBnBasePro1( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelGoldlExpressConfig:getBnBasePro2( )
      local value = self:getValueByPros(self.m_bnBasePro2, self.m_bnBaseTotalWeight2)
      return value[1]
  end


return  LevelGoldlExpressConfig