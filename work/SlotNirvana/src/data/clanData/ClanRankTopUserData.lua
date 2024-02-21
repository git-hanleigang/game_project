local  ClanRankTopUserData = class("ClanRankTopUserData")

--[[
    message ClanUserTopRank {
        optional int32 rank = 1;
        optional string name = 2;
        optional int32 points = 3;
        optional string facebookId = 4;
        optional string udid = 5;
        optional string head = 6; //头像
        optional string frame = 7; //头像框
        optional string clanId = 8; //公会id
        optional string clanName = 9; //公会名称
        optional string clanHead = 10; //公会头像
    }
]]
function ClanRankTopUserData:ctor()
    self.m_rank = 0 --玩家排名
    self.m_name = "" --玩家名字
    self.m_points = 0 --玩家公会点数
    self.m_facebookId = "" --玩家facebookId
    self.m_udid = "" --玩家udid
    self.m_head = 0 --玩家头像
    self.m_frame = "" --玩家头像框
    self.m_clanId = "" --工会ID
    self.m_clanName = "" --工会名称
    self.m_clanHead = "" --工会徽章
end

--@_bTrueRank: 排行界面内 本公会没排名默认第一名， 最强公会无排名--
function ClanRankTopUserData:parseData(_data, _bTrueRank)
    if not _data then
        return
    end

    if _bTrueRank then
        self.m_rank = tonumber(_data.rank) or 0
    else
        self.m_rank = math.max(1, tonumber(_data.rank) or 1) --排名
    end
    self.m_name = _data.name or "" --玩家名字
    self.m_points = _data.points or 0 --玩家公会点数
    self.m_facebookId = _data.facebookId or "" --玩家facebookId
    self.m_udid = _data.udid or "" --玩家udid
    self.m_head = _data.head or 0 --玩家头像
    self.m_frame = _data.frame or "" --玩家头像框
    self.m_clanId = _data.clanId or "" --工会ID
    self.m_clanName = _data.clanName or "" --工会名称
    self.m_clanHead = _data.clanHead or "" --工会徽章
    self.m_bMe = self.m_udid == globalData.userRunData.userUdid
end

function ClanRankTopUserData:checkIsBMe()
    return self.m_bMe
end

--工会ID
function ClanRankTopUserData:getCid()
    return self.m_clanId
end

--工会名称
function ClanRankTopUserData:getName()
    return self.m_clanName
end

--工会徽章
function ClanRankTopUserData:getClanLogo()
    return self.m_clanHead
end

--排名
function ClanRankTopUserData:getRank()
    return self.m_rank
end

--点数
function ClanRankTopUserData:getPoints()
    return self.m_points
end

--玩家名字
function ClanRankTopUserData:getUserName()
    if self.m_bMe then
        self.m_name = globalData.userRunData.nickName
    end
    return self.m_name
end

--玩家facebookId
function ClanRankTopUserData:getFacebookId()
    return self.m_facebookId
end

--玩家头像
function ClanRankTopUserData:getUserHead()
    if self.m_bMe then
        self.m_head = globalData.userRunData.HeadName
    end
    return self.m_head
end

--玩家头像框
function ClanRankTopUserData:getUserFrame()
    if self.m_bMe then
        self.m_frame = globalData.userRunData.avatarFrameId
    end
    return self.m_frame
end

--玩家Udid
function ClanRankTopUserData:getUdid()
    return self.m_udid
end

return ClanRankTopUserData