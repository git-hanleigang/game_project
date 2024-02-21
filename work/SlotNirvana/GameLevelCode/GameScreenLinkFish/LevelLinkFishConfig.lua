--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-08 14:11:47
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelLinkFishConfig = class("LevelLinkFishConfig", LevelConfigData)

function LevelLinkFishConfig:ctor()
    LevelConfigData.ctor(self)
end

function LevelLinkFishConfig:parseSelfConfigData(colKey, colValue)
    
      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Base2_pro" then
          self.m_bnBasePro2, self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
      elseif colKey == "BN_Free1_pro" then
              self.m_bnFsPro1 , self.m_bnFsTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Free2_pro" then
              self.m_bnFsPro2, self.m_bnFsTotalWeight2 = self:parsePro(colValue)
      
      end
      
  end
  
  
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelLinkFishConfig:getBnBasePro1( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelLinkFishConfig:getBnBasePro2( )
      local value = self:getValueByPros(self.m_bnBasePro2, self.m_bnBaseTotalWeight2)
      return value[1]
  end
  
  
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelLinkFishConfig:getBnFSPro1( )
      local value = self:getValueByPros(self.m_bnFsPro1 , self.m_bnFsTotalWeight1)
      return value[1]
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelLinkFishConfig:getBnFSPro2( )
      local value = self:getValueByPros(self.m_bnFsPro2, self.m_bnFsTotalWeight2)
      return value[1]
  end
  


return  LevelLinkFishConfig