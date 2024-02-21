--[[
    排名榜玩家排名信息
    author:徐袁
    time:2020-12-21 12:03:55
]]
local LeagueUserInfo = class("LeagueUserInfo")

function LeagueUserInfo:ctor()
    self.m_fbId = ""
    self.m_name = ""
    self.m_points = nil
    self.m_rank = nil
    self.m_udid = ""
    self.m_head = 0
    self.m_robotHeadName = nil
    self.m_frameId = nil
    self.m_status = LeagueRankStatus.Same
end

function LeagueUserInfo:parseData(data)
    if not data then
        return
    end
    self.m_fbId = data.facebookId
    self.m_name = data.name
    self.m_points = data.points
    self.m_rank = data.rank
    self.m_udid = data.udid
    self.m_head = tonumber(data.head or 0)
    self.m_robotHeadName = data.robotHead
    self.m_frameId = data.frame -- 头像框
    if data.status and data.status ~= LeagueRankStatus.Same then
        self.m_status = data.status
    end

    -- 自己的头像
    if self.m_udid == globalData.userRunData.userUdid then
        self.m_head = globalData.userRunData.HeadName or 1
        self.m_frameId = globalData.userRunData.avatarFrameId
        self.m_name = globalData.userRunData.nickName
    end
end

function LeagueUserInfo:getStatus()
    return self.m_status or LeagueRankStatus.Same
end

function LeagueUserInfo:getFbId()
    return self.m_fbId or ""
end

function LeagueUserInfo:getName()
    return self.m_name or ""
end

-- 积分
function LeagueUserInfo:getPoints()
    return self.m_points or 0
end

-- 排名
function LeagueUserInfo:getRankId()
    return self.m_rank or 0
end

function LeagueUserInfo:getUdid()
    return self.m_udid or ""
end

-- 头像_本地
function LeagueUserInfo:getHead()
    return self.m_head or 0
end

-- 头像_机器人
function LeagueUserInfo:getRobotHeadName()
    return self.m_robotHeadName or ""
end

-- 头像框id
function LeagueUserInfo:getFrameId()
    return self.m_frameId
end

return LeagueUserInfo
