--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMiningManiaConfig = class("LevelMiningManiaConfig", LevelConfigData)

LevelMiningManiaConfig.m_bnBonusPro2 = nil
LevelMiningManiaConfig.m_bnBonusTotalWeight2 = nil

LevelMiningManiaConfig.m_bnBonusPro3 = nil
LevelMiningManiaConfig.m_bnBonusTotalWeight3 = nil

LevelMiningManiaConfig.m_bnBonusPro4 = nil
LevelMiningManiaConfig.m_bnBonusTotalWeight4 = nil

function LevelMiningManiaConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelMiningManiaConfig:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Bonus2_pro" then
            self.m_bnBonusPro2, self.m_bnBonusTotalWeight2 = self:parsePro(colValue)
      elseif colKey == "BN_Bonus3_pro" then
            self.m_bnBonusPro3, self.m_bnBonusTotalWeight3 = self:parsePro(colValue)
      elseif colKey == "BN_Bonus4_pro" then
            self.m_bnBonusPro4, self.m_bnBonusTotalWeight4 = self:parsePro(colValue)
      end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回bonus2的倍数
]]
function LevelMiningManiaConfig:getBnBonusPro2(type)
      local value = self:getValueByPros(self.m_bnBonusPro2 , self.m_bnBonusTotalWeight2)
      return value[1]
end

--[[
    time:2018-11-28 16:39:26
    @return: 返回bonus3的类型
]]
function LevelMiningManiaConfig:getBnBonusPro3(type)
      local value = self:getValueByPros(self.m_bnBonusPro3 , self.m_bnBonusTotalWeight3)
      local jackpotType = "Mini"
      if value[1] == 10 then
            jackpotType = "Mini"
      elseif value[1] == 20 then
            jackpotType = "Minor"
      elseif value[1] == 100 then
            jackpotType = "Major"
      elseif value[1] == 1000 then
            jackpotType = "Grand"
      end
      return jackpotType
end

--[[
    time:2018-11-28 16:39:26
    @return: 返回bonus4的次数
]]
function LevelMiningManiaConfig:getBnBonusPro4(type)
      local value = self:getValueByPros(self.m_bnBonusPro4 , self.m_bnBonusTotalWeight4)
      return value[1]
end

return  LevelMiningManiaConfig
