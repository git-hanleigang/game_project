--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-08 14:33:22
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPharaohConfig = class("LevelPharaohConfig", LevelConfigData)


function LevelPharaohConfig:ctor()
    LevelConfigData.ctor(self)
end



function LevelPharaohConfig:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Free_pro" then
          self.m_bnFreePro , self.m_bnFreeTotalWeight = self:parsePro(colValue)
      elseif colKey == "BN_Free_feature_pro" then
          self.m_bnFreeFeaturePro , self.m_bnFreeFeatureTotalWeight = self:parsePro(colValue)
      elseif colKey == "BN_Free_feature_last_pro" then
          self.m_bnFreeFeatureLastPro = util_string_split(colValue,";", true)
          self.m_bnFreeFeatureLastTotalWeight = 0
          for i=1,#self.m_bnFreeFeatureNormalPro do
              self.m_bnFreeFeatureLastTotalWeight = self.m_bnFreeFeatureLastTotalWeight + 
                                          self.m_bnFreeFeatureNormalPro[i] 
          end
      elseif colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Base2_pro" then
          self.m_bnBasePro2, self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
      elseif colKey == "BN_Base_feature_pro" then
          self.m_bnBaseFeaturePro, self.m_bnBaseFeatureTotalWeight = self:parsePro(colValue)
      elseif colKey == "BN_Base_feature_normal_pro" then
          self.m_bnBaseFeatureNormalPro = util_string_split(colValue,";", true)
          self.m_bnBaseFeatureNormalTotalWeight = 0
          for i=1,#self.m_bnBaseFeatureNormalPro do
              self.m_bnBaseFeatureNormalTotalWeight = self.m_bnBaseFeatureNormalTotalWeight + 
                                          self.m_bnBaseFeatureNormalPro[i] 
          end
      end
      
  end
  
  
  function LevelPharaohConfig:getBnFreePro( )
      local value = self:getValueByPros(self.m_bnFreePro , self.m_bnFreeTotalWeight)
      return value[1]
  end
  function LevelPharaohConfig:getBnFreeFeaturePro( )
      local value = self:getValueByPros(self.m_bnFreeFeaturePro , self.m_bnFreeFeatureTotalWeight)
      return value[1]
  end
  
  function LevelPharaohConfig:getBnFreeFeatureNormalPro( )
  
      local index = self:getValueByPro(self.m_bnFreeFeatureNormalPro , self.m_bnFreeFeatureNormalTotalWeight)
      
      return index
  end
  
  
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelPharaohConfig:getBnBasePro1( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelPharaohConfig:getBnBasePro2( )
      local value = self:getValueByPros(self.m_bnBasePro2, self.m_bnBaseTotalWeight2)
      return value[1]
  end
  
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelPharaohConfig:getBnBaseFeaturePro( )
      local value = self:getValueByPros(self.m_bnBaseFeaturePro, self.m_bnBaseFeatureTotalWeight)
      return value[1]
  end
  
  function LevelPharaohConfig:getBnBaseFeatureNormalPro( )
  
      local index = self:getValueByPro(self.m_bnBaseFeatureNormalPro , self.m_bnBaseFeatureNormalTotalWeight)
      
      return index
  end



return  LevelPharaohConfig