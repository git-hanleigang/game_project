local ClanConfig = require "data.clanData.ClanConfig"
local ClanMemberData = class("ClanMemberData")

function ClanMemberData:ctor()
    self.m_name = "" --成员名称
    self.m_head = 0 --图像
    self.m_uid = "" --用户id
    self.m_udid = "" --用户udid
    self.m_frameId = "" --用户头像框
    self.m_facebookId = "" --facebook ID
    self.m_level = 0 --等级
    self.m_bMe = false
    
    -------------- ClanUser or ClanRankUser --------------
    self.m_identity = ClanConfig.userIdentity.MEMBER --身份(leader/e/member)
    self.m_vipLevel = 1 --用户VIP等级
    self.m_points = 0 --个人公会点数
    -------------- ClanUser or ClanRankUser --------------

    -------------- ClanUser --------------
    self.m_applyTime = 0 -- 申请时间
    self.m_lastLogin = 0 --上次登录时间
    self.m_bOnline = 0 --是否在线
    -------------- ClanUser --------------

    -------------- ClanRankUser --------------
    self.m_rank = 1 --最大排名
    self.m_coins = 0 --奖励金币
    self.m_highLimitPoints = 0 --高倍场点数
    -------------- ClanRankUser --------------
end


function ClanMemberData:parseData(_data, _type)
    if not _data then
        return
    end

    if self.m_udid == _data.udid and _type == "ClanRankUser" then
        -- ClanRankUser 排行榜数据 可能有缓存 数据滞后
        local points = tonumber(_data.points) or 0 --个人公会点数
        if self.m_points > points then
            _data.points = self.m_points
        end
    end

    self.m_name = _data.name or "" --成员名称
    self.m_head = _data.head or 0 --图像
    self.m_uid = _data.uid or "" --用户id
    self.m_udid = _data.udid or "" --用户udid
    self.m_frameId = _data.frame or "" --用户头像框
    self.m_facebookId = _data.facebookId or "" --facebook ID
    self.m_level = _data.level or 1 --等级
    self.m_bMe = self.m_udid == globalData.userRunData.userUdid

    if _type == "ClanUser" or _type == "ClanRankUser" then
        self.m_vipLevel = _data.vipLevel or 1 --用户VIP等级
        -- self.m_identity = _data.identity --身份(leader/elite/member)
        self.m_identity = _data.position or ClanConfig.userIdentity.MEMBER --身份(leader/elite/member)
        self.m_points = tonumber(_data.points) or 0 --个人公会点数
    end

    if _type == "ClanUser" then
        self.m_applyTime = tonumber(_data.applyTime) or 0 -- 申请时间
        self.m_lastLogin = tonumber(_data.lastLogin) or 0 --上次登录时间
        self.m_bOnline = _data.online or false --是否在线
    end

    if _type == "ClanRankUser" then
        self.m_rank = math.max(1, tonumber(_data.order) or 1) --排名
        self.m_coins = tonumber(_data.coins) or 0 --奖励金币
        self.m_highLimitPoints = _data.highLimitPoints or 0 --高倍场点数
    end

    -- manager记录的 会长id
    if self:checkIsLeader() then
        local ClanManager = util_require("manager.System.ClanManager"):getInstance()
        ClanManager:setLearderUdid(self.m_udid)
    end
end

function ClanMemberData:checkIsBMe()
    return self.m_bMe
end

--成员名称
function ClanMemberData:getName()
    if self.m_bMe then
        self.m_name = globalData.userRunData.nickName
    end
    return self.m_name
end
--图像
function ClanMemberData:getHead()
    if self.m_bMe then
        self.m_head = globalData.userRunData.HeadName
    end
    return self.m_head
end
--用户id
function ClanMemberData:getUid()
    return self.m_uid
end
--用户udid
function ClanMemberData:getUdid()
    return self.m_udid
end
--用户头像框
function ClanMemberData:getFrameId()
    if self.m_bMe then
        self.m_frameId = globalData.userRunData.avatarFrameId
    end
    return self.m_frameId
end
--facebook ID
function ClanMemberData:getFacebookId()
    return self.m_facebookId
end
--等级
function ClanMemberData:getLevel()
    return self.m_level
end

-------------- ClanUser or ClanRankUser --------------
--用户VIP等级
function ClanMemberData:getVipLevel()
    return self.m_vipLevel
end
--身份(leader/elite/member)
function ClanMemberData:getIdentity()
    return self.m_identity
end
function ClanMemberData:checkIsLeader()
    return ClanConfig.userIdentity.LEADER == self.m_identity
end
function ClanMemberData:checkIsElite()
    return ClanConfig.userIdentity.ELITE == self.m_identity
end
--个人公会点数
function ClanMemberData:getPoints()
    return self.m_points
end
-------------- ClanUser or ClanRankUser --------------

-------------- ClanUser --------------
-- 用户申请加入公会时间
function ClanMemberData:getApplyTime()
    return self.m_applyTime or 0
end
--上次登录时间
function ClanMemberData:getLastLoginTime()
    return self.m_lastLogin
end
function ClanMemberData:checkIsOnline()
    return self.m_bOnline
end
-------------- ClanUser --------------

-------------- ClanRankUser --------------
--排名
function ClanMemberData:getRank()
    return self.m_rank
end
--奖励金币
function ClanMemberData:getCoins()
    return self.m_coins
end
--高倍场点数
function ClanMemberData:getHighLimitPoints()
    return self.m_highLimitPoints
end
-------------- ClanRankUser --------------

return ClanMemberData