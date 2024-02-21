--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelDwarfFairyConfig = class("LevelDwarfFairyConfig", LevelConfigData)
LevelDwarfFairyConfig.m_repsinSocrePro = nil
LevelDwarfFairyConfig.m_repsinTotleWeight = nil
LevelDwarfFairyConfig.m_specialBets = nil
function LevelDwarfFairyConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelDwarfFairyConfig:getSpecialBet()
      if not self.m_specialBets then
            --只有第一次获取服务器数据
            self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
      end
      if self.m_specialBets and self.m_specialBets[1] then
          return self.m_specialBets[1].p_totalBetValue
      end
      return 1000000
  end
---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelDwarfFairyConfig:getNormalReelDatasByColumnIndex(columnIndex)
      local colKey = "reel_cloumn_0_"..columnIndex
      local totalBet = globalData.slotRunData:getCurTotalBet()
      if totalBet >= self:getSpecialBet() then
            colKey = "reel_cloumn_1_"..columnIndex
      end
      return self[colKey]
  end
  
  ---
  -- 获取freespin model 对应的reel 列数据
  --
  function LevelDwarfFairyConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
  
      local totalBet = globalData.slotRunData:getCurTotalBet()
      if totalBet >= self:getSpecialBet() then
            fsModelID = 1
      end
      local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
  
      return self[colKey]
  end


return  LevelDwarfFairyConfig