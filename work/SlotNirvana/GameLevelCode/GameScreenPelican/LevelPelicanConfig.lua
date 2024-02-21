--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:22:02
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPelicanConfig = class("LevelPelicanConfig", LevelConfigData)

LevelPelicanConfig.m_bnBasePro1 = nil
LevelPelicanConfig.m_bnBaseTotalWeight1 = nil

function LevelPelicanConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelPelicanConfig:parseSelfConfigData(colKey, colValue)

      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end

end


--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelPelicanConfig:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
end
  


return  LevelPelicanConfig