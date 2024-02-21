--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于PoseidonConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPoseidonConfig = class("LevelPoseidonConfig", LevelConfigData)
LevelPoseidonConfig.m_repsinSocrePro = nil
LevelPoseidonConfig.m_repsinTotleWeight = nil

function LevelPoseidonConfig:ctor()
      LevelConfigData.ctor(self)
end

function LevelPoseidonConfig:parseSelfConfigData(colKey,colValue) 
end

return  LevelPoseidonConfig