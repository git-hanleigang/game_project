--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMermaidConfig = class("LevelMermaidConfig", LevelConfigData)



function LevelMermaidConfig:parseSelfConfigData(colKey, colValue)
    


      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Fs_15_pro" then
          self.m_bnBasePro15 , self.m_bnBaseTotalWeight15 = self:parsePro(colValue)
      elseif colKey == "BN_Fs_234_pro" then
          self.m_bnBasePro234 , self.m_bnBaseTotalWeight234 = self:parsePro(colValue)
      elseif colKey == "BN_Rs_pro" then
          self.m_bnBaseProRs , self.m_bnBaseTotalWeightRs = self:parsePro(colValue)  
      end
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelMermaidConfig:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1] / 10
  end
  
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelMermaidConfig:getFS_15_FixSymbolPro( ) 
      local value = self:getValueByPros(self.m_bnBasePro15 , self.m_bnBaseTotalWeight15)
      return value[1] / 10
  end
  
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelMermaidConfig:getFS_234_FixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro234 , self.m_bnBaseTotalWeight234)
      return value[1] / 10
  end
  
  function LevelMermaidConfig:getRs_FixSymbolPro( )
  
      local value = self:getValueByPros(self.m_bnBaseProRs , self.m_bnBaseTotalWeightRs)
      return value[1] / 10
  end
  


return  LevelMermaidConfig