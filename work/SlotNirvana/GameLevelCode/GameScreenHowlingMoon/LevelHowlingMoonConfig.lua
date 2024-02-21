--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于HowlingMoonConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelHowlingMoonConfig = class("LevelHowlingMoonConfig", LevelConfigData)
LevelHowlingMoonConfig.m_repsinSocrePro = nil
LevelHowlingMoonConfig.m_repsinTotleWeight = nil

function LevelHowlingMoonConfig:ctor()
      LevelConfigData.ctor(self)
end

function LevelHowlingMoonConfig:parseSelfConfigData(colKey,colValue) 
      if colKey == "repsinSocrePro" then
            self.m_repsinSocrePro, self.m_repsinTotleWeight = self:parsePro(colValue)
      end
end

function LevelHowlingMoonConfig:getRepsinScorePro()
    return  self.m_repsinSocrePro
end

function LevelHowlingMoonConfig:getRespinRunningScore() 
      local value = self:getValueByPros(self.m_repsinSocrePro, self.m_repsinTotleWeight)
      return value[1]
end


return  LevelHowlingMoonConfig