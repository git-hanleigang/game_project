--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于HowlingMoonConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFourInOne_Link_ChilliFiesta_Config = class("LevelFourInOne_Link_ChilliFiesta_Config", LevelConfigData)



function LevelFourInOne_Link_ChilliFiesta_Config:parseSelfConfigData(colKey, colValue)

      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end
      if colKey == "BN_Base1_fake" then
          self.m_bnFakePro1 , self.m_bnFakeTotalWeight1 = self:parsePro(colValue)
      end
      if colKey == "BN_Base1_feature" then
          self.m_bnFeaturePro1 , self.m_bnFeatureTotalWeight1 = self:parsePro(colValue)
      end
  
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelFourInOne_Link_ChilliFiesta_Config:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end
  
  function LevelFourInOne_Link_ChilliFiesta_Config:getFixSymbolFake( )
      local value = self:getValueByPros(self.m_bnFakePro1 , self.m_bnFakeTotalWeight1)
      return value[1]
  end
  
  function LevelFourInOne_Link_ChilliFiesta_Config:getFixSymbolFeature( )
      local value = self:getValueByPros(self.m_bnFeaturePro1 , self.m_bnFeatureTotalWeight1)
      return value[1]
  end

return  LevelFourInOne_Link_ChilliFiesta_Config