--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-08 14:45:56
--


local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPussConfig = class("LevelPussConfig", LevelConfigData)


function LevelPussConfig:parseSelfConfigData(colKey, colValue)
    
      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelPussConfig:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end
  

return  LevelPussConfig