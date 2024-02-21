
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelBeatlesConfig = class("LevelBeatlesConfig", LevelConfigData)
local BeatlesBaseData = require "CodeBeatlesSrc.BeatlesBaseData"

LevelBeatlesConfig.m_bnBasePro1 = nil
LevelBeatlesConfig.m_bnBaseTotalWeight1 = nil

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelBeatlesConfig:ctor()
      LevelConfigData.ctor(self)
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelBeatlesConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local spin_num = BeatlesBaseData:getInstance():getDataByKey("spin_num")
    local key_str = "reel_cloumn%d"
    if spin_num == 9 then  -- 10且高倍  key = 2
        key_str = "reel_cloumn_0_%d"
    end
    local colKey = string.format(key_str,columnIndex)
    return self[colKey]
end
 
return  LevelBeatlesConfig