--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local StarryFestConfig = class("StarryFestConfig", LevelConfigData)

StarryFestConfig.m_bnBasePro1 = nil
StarryFestConfig.m_bnBaseTotalWeight1 = nil

StarryFestConfig.m_bnBasePro2 = nil
StarryFestConfig.m_bnBaseTotalWeight2 = nil

StarryFestConfig.m_bnFreePro1 = nil
StarryFestConfig.m_bnFreeTotalWeight1 = nil

StarryFestConfig.m_bnFreePro2 = nil
StarryFestConfig.m_bnFreeTotalWeight2 = nil

StarryFestConfig.m_bnSpecialPro1 = nil
StarryFestConfig.m_bnSpecialTotalWeight1 = nil

StarryFestConfig.m_bnSpecialPro2 = nil
StarryFestConfig.m_bnSpecialTotalWeight2 = nil

function StarryFestConfig:ctor()
      LevelConfigData.ctor(self)
end


function StarryFestConfig:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Base1_pro" then
            self.m_bnBasePro1, self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Base2_pro" then
            self.m_bnBasePro2, self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
      elseif colKey == "BN_Free1_pro" then
            self.m_bnFreePro1 , self.m_bnFreeTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Free2_pro" then
            self.m_bnFreePro2 , self.m_bnFreeTotalWeight2 = self:parsePro(colValue)
      elseif colKey == "BN_Special1_pro" then
            self.m_bnSpecialPro1 , self.m_bnSpecialTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Special2_pro" then
            self.m_bnSpecialPro2 , self.m_bnSpecialTotalWeight2 = self:parsePro(colValue)
      end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
-- 0：基础玩法权重；1：free和一级特殊玩法；2：二级特殊玩法
function StarryFestConfig:getBnBasePro(_playType)
      local value = self:getValueByPros(self.m_bnBasePro1, self.m_bnBaseTotalWeight1)
      if _playType == 1 then
            value = self:getValueByPros(self.m_bnFreePro1, self.m_bnFreeTotalWeight1)
      elseif _playType == 2 then
            value = self:getValueByPros(self.m_bnSpecialPro1, self.m_bnSpecialTotalWeight1)
      end
      local isJackpot = false
      local mul = value[1]
      if mul and mul == 100 then
            isJackpot = true
            mul = self:getCurJackpotType(_playType)
      end
      return isJackpot, mul
end

function StarryFestConfig:getCurJackpotType(_playType)
      local value = self:getValueByPros(self.m_bnBasePro2, self.m_bnBaseTotalWeight2)
      if _playType == 1 then
            value = self:getValueByPros(self.m_bnFreePro2, self.m_bnFreeTotalWeight2)
      elseif _playType == 2 then
            value = self:getValueByPros(self.m_bnSpecialPro2, self.m_bnSpecialTotalWeight2)
      end
      return value[1]
end

function StarryFestConfig:getNormalReelDatasByColumnIndexSpecial_1(columnIndex)
      local colKey = "bonus_reel_cloumn"..columnIndex
      return self[colKey]
end

function StarryFestConfig:getNormalReelDatasByColumnIndexSpecial_2(columnIndex)
      local colKey = "special_reel_cloumn"..columnIndex
      return self[colKey]
end

return  StarryFestConfig
