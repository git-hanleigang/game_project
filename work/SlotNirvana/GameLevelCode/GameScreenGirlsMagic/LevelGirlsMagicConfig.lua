--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelGirlsMagicConfig = class("LevelGirlsMagicConfig", LevelConfigData)

function LevelGirlsMagicConfig:ctor()
      LevelConfigData.ctor(self)
end

return  LevelGirlsMagicConfig