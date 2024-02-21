--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于MiracleEgyptConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelAZTECConfig = class("LevelAZTECConfig", LevelConfigData)

LevelAZTECConfig.m_fsModel = nil

function LevelAZTECConfig:getBetLevel()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local betLevel = 1
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and #self.m_specialBets > 1 then
        betLevel = #self.m_specialBets + 1
        for i = 1, #self.m_specialBets, 1 do
            if totalBet < self.m_specialBets[i].p_totalBetValue then 
                betLevel = i
                break
            end
        end
    else
        betLevel = 5
    end
    return betLevel
end

function LevelAZTECConfig:setFsModel(model)
    self.m_fsModel = model
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelAZTECConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local betLevel = self:getBetLevel()
    local colKey = "reel_cloumn_"..betLevel.."_"..columnIndex
    return self[colKey]
end

  ---
  -- 获取freespin model 对应的reel 列数据
  --
  function LevelAZTECConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
  
    local colKey = string.format("freespinModeId_%d_%s_%d", fsModelID, self.m_fsModel, columnIndex)

    return self[colKey]
end

return  LevelAZTECConfig