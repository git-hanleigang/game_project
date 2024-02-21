--[[
Author: cxc
Date: 2022-04-15 15:43:55
LastEditTime: 2022-04-15 15:43:56
LastEditors: cxc
Description: 头像框 统计 数据
FilePath: /SlotNirvana/src/GameModule/Avatar/model/AvatarFrameStatsData.lua
--]]
local AvatarFrameStatsData = class("AvatarFrameStatsData")

-- message AvatarFrameStats {
--     optional string register = 1; //注册时间
--     optional int64 spinTimesTotal = 2; //总spin数
--     optional int64 winTimesTotal = 3; //Win次数
--     optional int64 maximumWinMultiple = 4; //最大赢钱倍
--     optional int64 maximumWin = 5; //最大赢钱数
--   }

function AvatarFrameStatsData:ctor()
    self.m_register = 0
    self.m_spinTimesTotal = ""
    self.m_winTimesTotal = 0
    self.m_maximumWinMultiple = 0
    self.m_maximumWin = 0
    self.m_bigwin = 0
    self.m_megawin = 0
    self.m_epicwin = 0
    self.m_jackpot = 0
    self.m_legendaryWinTimesTotal = 0
end

function AvatarFrameStatsData:parseData(_data)
    if not _data then
        return
    end
    self.m_register = tonumber(_data.register) or 0
    self.m_spinTimesTotal = tonumber(_data.spinTimesTotal) or 0
    self.m_winTimesTotal = tonumber(_data.winTimesTotal) or 0
    self.m_maximumWinMultiple = tonumber(_data.maximumWinMultiple) or 0
    self.m_maximumWin = tonumber(_data.maximumWin) or 0
    self.m_bigwin = tonumber(_data.bigWinTimesTotal) or 0
    self.m_megawin = tonumber(_data.megaWinTimesTotal) or 0
    self.m_epicwin = tonumber(_data.epicWinTimesTotal) or 0
    self.m_jackpot = tonumber(_data.jackpotTimes) or 0
    self.m_legendaryWinTimesTotal = tonumber(_data.legendaryWinTimesTotal) or 0
end

-- get 注册时间
function AvatarFrameStatsData:getRegister()
    return self.m_register
end
-- get 总spin数
function AvatarFrameStatsData:getSpinTimesTotal()
    return self.m_spinTimesTotal
end
-- get Win次数
function AvatarFrameStatsData:getWinTimesTotal()
    return self.m_winTimesTotal
end
-- get 最大赢钱倍
function AvatarFrameStatsData:getMaximumWinMultiple()
    return self.m_maximumWinMultiple
end
-- get 最大赢钱数
function AvatarFrameStatsData:getMaximumWin()
    return self.m_maximumWin
end

return AvatarFrameStatsData