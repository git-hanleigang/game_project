--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-22 11:51:52
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-22 11:52:14
FilePath: /SlotNirvana/src/activities/Activity_Leagues/model/LeagueSummitLastRankData.lua
Description: 巅峰赛 上一期 排名
--]]
local RankCellData = class("RankCellData")
function RankCellData:ctor()
    self.m_name = "" --名称
    self.m_head = 0 --图像
    self.m_uid = "" --用户id
    self.m_udid = "" --用户udid
    self.m_frameId = "" --用户头像框
    self.m_vipLevel = 1 --用户VIP等级
    self.m_facebookId = "" --facebook ID
    self.m_level = 0 --等级
    self.m_rank = 0 --最大排名
    self.m_score = 0 -- 分数
end
function RankCellData:parseData(_data)
    if not _data then
        return
    end

    self.m_name = _data.name --名称
    self.m_head = _data.head --图像
    self.m_robotHead = _data.robot --机器人头像
    self.m_uid = _data.uid --用户id
    self.m_udid = _data.udid --用户udid
    self.m_frameId = _data.frame --用户头像框
    self.m_vipLevel = _data.vipLevel --用户VIP等级
    self.m_facebookId = _data.facebookId --facebook ID
    self.m_level = _data.level --等级
    self.m_rank = math.max(1, tonumber(_data.rank) or 1) --排名
    self.m_score = _data.points or 0
    self.m_bMe = self.m_udid ==  globalData.userRunData.userUdid
end

function RankCellData:getRank()
    return self.m_rank
end

function RankCellData:getUserUdid()
    return self.m_udid
end
function RankCellData:getUserName()
    if self.m_bMe then
        self.m_name = globalData.userRunData.nickName
    end
    return self.m_name
end
function RankCellData:getUserHead()
    if self.m_bMe then
        self.m_head = globalData.userRunData.HeadName
    end
    return self.m_head
end
function RankCellData:getUserFBId()
    return self.m_facebookId
end
function RankCellData:getRobotHead()
    return self.m_robotHead
end
function RankCellData:getUserFrameId()
    if self.m_bMe then
        self.m_frameId = globalData.userRunData.avatarFrameId
    end
    return self.m_frameId
end
function RankCellData:getScore()
    return tonumber(self.m_score) or 0
end


local LeagueSummitLastRankData = class("LeagueSummitLastRankData")

function LeagueSummitLastRankData:ctor()
    self.m_beginTime = ""-- 开始时间
    self.m_endTime = ""  -- 结束时间
    self.m_rankList = {} -- 榜单
end

function LeagueSummitLastRankData:parseData(_data)
    if not _data then
        return
    end

    self.m_beginTime = _data["begin"] or ""
    self.m_endTime = _data["end"] or ""
    self:parseRankList(_data.rankUsers or {})
end

function LeagueSummitLastRankData:parseRankList(_list)
    self.m_rankList = {}
    
    for i=1, #_list do
        local cellRankInfo = _list[i]
        local cellRankData = RankCellData:create()
        cellRankData:parseData(cellRankInfo)
        table.insert(self.m_rankList, cellRankData)
    end
end

-- 开始时间
function LeagueSummitLastRankData:getBeginTime()
    return self.m_beginTime
end
-- 结束时间
function LeagueSummitLastRankData:getEndTime()
    return self.m_endTime
end
function LeagueSummitLastRankData:getTimeStr()
    return self.m_beginTime .. " - " .. self.m_endTime
end

-- 工会榜单
function LeagueSummitLastRankData:getTeamRankList()
    return self.m_rankList
end

return LeagueSummitLastRankData