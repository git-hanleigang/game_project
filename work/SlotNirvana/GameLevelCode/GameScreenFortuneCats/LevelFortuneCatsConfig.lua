--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFortuneCatsConfig = class("LevelFortuneCatsConfig", LevelConfigData)

function LevelFortuneCatsConfig:ctor()
    LevelConfigData.ctor(self)
end

function LevelFortuneCatsConfig:getNormalRespinCloumnByColumnIndex(rowIndex,columnIndex)

    if (rowIndex == 3 and columnIndex == 1)
    or (rowIndex == 2 and columnIndex == 2)
    or (rowIndex == 1 and columnIndex == 3)
    or (rowIndex == 1 and columnIndex == 1)
    or (rowIndex == 3 and columnIndex == 3)
    then
        local randomNum = xcyy.SlotsUtil:getArc4Random() % 5 + 1
        local colKey = "reel_cloumn"..randomNum
        local data = self[colKey]
        return data
    else
        local randomNum = xcyy.SlotsUtil:getArc4Random() % 5 + 1
        local colKey = "reel_cloumn"..randomNum .."2"
        local data = self[colKey]
        return data
    end

end

function LevelFortuneCatsConfig:getNormalFreeSpinRespinCloumnByColumnIndex(rowIndex,columnIndex)
    
    local randomNum = xcyy.SlotsUtil:getArc4Random() % 5 + 1
    local colKey = "freespinModeId_0_"..randomNum
    local data = self[colKey]
    

    return data
end

return  LevelFortuneCatsConfig