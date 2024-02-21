--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelZooManiaConfig = class("LevelZooManiaConfig", LevelConfigData)

function LevelZooManiaConfig:ctor()
      LevelConfigData.ctor(self)
end

return  LevelZooManiaConfig