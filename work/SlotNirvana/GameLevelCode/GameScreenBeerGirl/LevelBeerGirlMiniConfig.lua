--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于MiracleEgyptConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelBeerGirlMiniConfig = class("LevelBeerGirlMiniConfig", LevelConfigData)

LevelBeerGirlMiniConfig.m_gameLevel = nil

function LevelBeerGirlMiniConfig:ctor()
      LevelConfigData.ctor(self)
end




return  LevelBeerGirlMiniConfig