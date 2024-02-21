--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPepperBlastConfig = class("LevelPepperBlastConfig", LevelConfigData)

function LevelPepperBlastConfig:ctor()
    LevelConfigData.ctor(self)
end

function LevelPepperBlastConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    return self[colKey]
end

return  LevelPepperBlastConfig