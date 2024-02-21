--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFoodStreetConfig = class("LevelFoodStreetConfig", LevelConfigData)



function LevelFoodStreetConfig:parseSelfConfigData(colKey, colValue)

    if string.find( colKey, "reel2_cloumn" ) ~= nil then
        self.m_baseHeightReel = self.m_baseHeightReel  or {}
        self.m_baseHeightReel[colKey] = self:parseSelfDefinePron(colValue)
    end
end

return  LevelFoodStreetConfig