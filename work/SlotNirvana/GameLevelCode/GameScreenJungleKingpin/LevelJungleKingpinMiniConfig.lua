local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelJungleKingpinlMiniConfig = class("LevelJungleKingpinlMiniConfig", LevelConfigData)

LevelJungleKingpinlMiniConfig.m_gameLevel = nil

function LevelJungleKingpinlMiniConfig:ctor()
      LevelConfigData.ctor(self)
end




return  LevelJungleKingpinlMiniConfig