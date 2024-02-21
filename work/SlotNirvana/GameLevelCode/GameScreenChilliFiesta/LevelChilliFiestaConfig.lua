--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:22:02
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelChilliFiestaConfig = class("LevelChilliFiestaConfig", LevelConfigData)

LevelChilliFiestaConfig.m_bnBasePro1 = nil
LevelChilliFiestaConfig.m_bnBaseTotalWeight1 = nil

LevelChilliFiestaConfig.m_bnFakePro1 = nil
LevelChilliFiestaConfig.m_bnFakeTotalWeight1 = nil

LevelChilliFiestaConfig.m_bnFeaturePro1 = nil
LevelChilliFiestaConfig.m_bnFeatureTotalWeight1 = nil

function LevelChilliFiestaConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelChilliFiestaConfig:parseSelfConfigData(colKey, colValue)

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
function LevelChilliFiestaConfig:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
end
  
function LevelChilliFiestaConfig:getFixSymbolFake( )
      local value = self:getValueByPros(self.m_bnFakePro1 , self.m_bnFakeTotalWeight1)
      return value[1]
end
  
function LevelChilliFiestaConfig:getFixSymbolFeature( )
      local value = self:getValueByPros(self.m_bnFeaturePro1 , self.m_bnFeatureTotalWeight1)
      return value[1]
end

return  LevelChilliFiestaConfig