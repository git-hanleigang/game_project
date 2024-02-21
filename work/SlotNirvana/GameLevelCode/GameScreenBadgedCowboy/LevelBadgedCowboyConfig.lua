--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelBadgedCowboyConfig = class("LevelBadgedCowboyConfig", LevelConfigData)

LevelBadgedCowboyConfig.m_bnBasePro1 = nil
LevelBadgedCowboyConfig.m_bnBaseTotalWeight1 = nil

function LevelBadgedCowboyConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelBadgedCowboyConfig:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Base1_pro" then
            self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Base2_pro" then
            self.m_bnBasePro2 , self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
      end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelBadgedCowboyConfig:getBnBasePro(type)
      if type == 1 then
            local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
            return value[1]
      else
            local value = self:getValueByPros(self.m_bnBasePro2 , self.m_bnBaseTotalWeight2)
            return value[1]
      end
      
end

return  LevelBadgedCowboyConfig
