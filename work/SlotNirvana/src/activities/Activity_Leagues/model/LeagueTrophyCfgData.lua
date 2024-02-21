--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-16 16:55:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-16 16:55:42
FilePath: /SlotNirvana/src/activities/Activity_Leagues/model/LeagueTrophyCfgData.lua
Description: 
--]]
local LeagueTrophyCfgData = class("LeagueTrophyCfgData")

function LeagueTrophyCfgData:ctor()
    self.m_minRank = 0 --最小排名
    self.m_maxRank = 0 --最大排名
    self.m_trophyType = "" --奖杯类型
end

function LeagueTrophyCfgData:parseData(_data)
    self.m_minRank = _data.minRank
    self.m_maxRank = _data.maxRank
    self.m_trophyType = string.lower(_data.trophyType or "")
end

function LeagueTrophyCfgData:checkRankIn(_rank)
    if not _rank then
        return false
    end

    return _rank >= self.m_minRank and _rank <= self.m_maxRank
end

function LeagueTrophyCfgData:getTrophyType(_rank)
    return self.m_trophyType
end

return LeagueTrophyCfgData