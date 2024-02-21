--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于MiracleEgyptConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMiracleEgyptConfig = class("LevelMiracleEgyptConfig", LevelConfigData)
LevelMiracleEgyptConfig.m_repsinSocrePro = nil
LevelMiracleEgyptConfig.m_repsinTotleWeight = nil

function LevelMiracleEgyptConfig:ctor()
      LevelConfigData.ctor(self)
end
--
---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelMiracleEgyptConfig:getNormalReelDatasByColumnIndex(columnIndex)
      local colKey = "reel_cloumn"..columnIndex
      local totalBet = globalData.slotRunData:getCurTotalBet()
      if totalBet >= 1000000 then
            colKey = "reel_cloumn_1_"..columnIndex
      end
      return self[colKey]
end
  
  ---
  -- 获取freespin model 对应的reel 列数据
  --
  function LevelMiracleEgyptConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
  
      local totalBet = globalData.slotRunData:getCurTotalBet()
      if totalBet >= 1000000 then
            fsModelID = 1
      end
      local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
  
      return self[colKey]
  end


return  LevelMiracleEgyptConfig