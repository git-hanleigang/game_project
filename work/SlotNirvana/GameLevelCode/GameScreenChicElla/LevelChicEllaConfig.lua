
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelChicEllaConfig = class("LevelChicEllaConfig", LevelConfigData)

-- respin
---
-- 获取respin情况下滚动数据
-- @param columnIndex 列索引
function LevelChicEllaConfig:getRespinReelDatasByColumnIndex(_columnIndex)
    local colKey = "respinCloumn_0_".._columnIndex
    
    return self[colKey]
end


return  LevelChicEllaConfig