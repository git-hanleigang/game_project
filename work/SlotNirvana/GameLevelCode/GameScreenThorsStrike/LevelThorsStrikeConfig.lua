
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelThorsStrikeConfig = class("LevelThorsStrikeConfig", LevelConfigData)
LevelThorsStrikeConfig.m_fsModel = nil

function LevelThorsStrikeConfig:getBetLevel()
end

function LevelThorsStrikeConfig:setFsModel(model)
    self.m_fsModel = model
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelThorsStrikeConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    return self[colKey]
end

  ---
  -- 获取freespin model 对应的reel 列数据
  --
  function LevelThorsStrikeConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
    local colKey = string.format("freespinModeId_%d_%d", self.m_fsModel, columnIndex)
    return self[colKey]
end



return  LevelThorsStrikeConfig