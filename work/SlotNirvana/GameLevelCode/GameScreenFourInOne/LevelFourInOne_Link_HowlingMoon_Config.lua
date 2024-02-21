--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于HowlingMoonConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFourInOne_Link_HowlingMoon_Config = class("LevelFourInOne_Link_HowlingMoon_Config", LevelConfigData)
LevelFourInOne_Link_HowlingMoon_Config.m_repsinSocrePro = nil
LevelFourInOne_Link_HowlingMoon_Config.m_repsinTotleWeight = nil

function LevelFourInOne_Link_HowlingMoon_Config:ctor()
      LevelConfigData.ctor(self)
end

function LevelFourInOne_Link_HowlingMoon_Config:parseSelfConfigData(colKey,colValue) 
    if colKey == "repsinSocrePro" then
        self.m_repsinSocrePro, self.m_repsinTotleWeight = self:parsePro(colValue)
    elseif colKey == "BN_Base1_pro" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end

function LevelFourInOne_Link_HowlingMoon_Config:getRepsinScorePro()
    return  self.m_repsinSocrePro
end

function LevelFourInOne_Link_HowlingMoon_Config:getRespinRunningScore() 
      local value = self:getValueByPros(self.m_repsinSocrePro, self.m_repsinTotleWeight)
      return value[1]
end

  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelFourInOne_Link_HowlingMoon_Config:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end

return  LevelFourInOne_Link_HowlingMoon_Config