local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPiratelMiniConfig = class("LevelPiratelMiniConfig", LevelConfigData)

LevelPiratelMiniConfig.m_gameLevel = nil

function LevelPiratelMiniConfig:ctor()
      LevelConfigData.ctor(self)
end




return  LevelPiratelMiniConfig