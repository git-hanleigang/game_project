
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelJackpotOGoldConfig = class("LevelJackpotOGoldConfig", LevelConfigData)
local JackpotOGoldBaseData = require "CodeJackpotOGoldSrc.JackpotOGoldBaseData"

LevelJackpotOGoldConfig.m_bnBasePro1 = nil
LevelJackpotOGoldConfig.m_bnBaseTotalWeight1 = nil

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelJackpotOGoldConfig:ctor()
      LevelConfigData.ctor(self)
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelJackpotOGoldConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local betValue = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local bonusModeData = JackpotOGoldBaseData:getInstance():getDataByKey("bonusMode")
    local key_str = "reel_cloumn%d"
    if bonusModeData[tostring(betValue)] then
        if bonusModeData[tostring(betValue)].spintime == 19 then  -- 10且高倍  key = 2
            key_str = "reel_cloumn20_%d"
        end
    end
    local colKey = string.format(key_str,columnIndex)
    return self[colKey]
end
 
return  LevelJackpotOGoldConfig