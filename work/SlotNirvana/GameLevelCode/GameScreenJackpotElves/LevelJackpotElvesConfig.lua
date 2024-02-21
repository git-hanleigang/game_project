local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelJackpotElvesConfig = class("LevelJackpotElvesConfig", LevelConfigData)
local VEC_WILD_TYPE = {102, 103, 104, 105, 202, 203, 204, 205}

function LevelJackpotElvesConfig:ctor()
    LevelConfigData.ctor(self)
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelJackpotElvesConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    local rundata = self[colKey]
    for index = 1, #rundata, 1 do
        if rundata[index] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            local randomID = math.random(1, #VEC_WILD_TYPE)
            rundata[index] = VEC_WILD_TYPE[randomID]
        end
    end
    return rundata
end


return  LevelJackpotElvesConfig