--[[
Author:cxc
Date: 2022-02-26 15:56:11
LastEditTime: 2022-02-26 15:56:12
LastEditors:cxc
Description: 公会排行榜段位信息
FilePath: /SlotNirvana/src/data/clanData/ClanRankCellData.lua
--]]
local  ClanRankCellData = class("ClanRankCellData")

--   message ClanRank {
--     optional string cid = 1 ; //工会ID
--     optional string name = 2 ; //工会名称
--     optional string head = 3 ; //工会徽章
--     optional int32 division = 4; //段位
--     optional int32 members = 5; //成员数量
--     optional int32 memberLimit = 6; //最大成员数
--     optional int32 rank = 7; //排名
--     optional int32 points = 8; //点数
--   }
function ClanRankCellData:ctor()
    self.m_cid = "" --工会ID
    self.m_name = "" --工会名称
    self.m_head = "" --工会徽章
    self.m_division = 1 --段位
    self.m_members = 0 --成员数量
    self.m_memberLimit = 0 --最大成员数
    self.m_rank = 0 --排名
    self.m_points = 0 --点数
end

--@_bTrueRank: 排行界面内 本公会没排名默认第一名， 最强公会无排名--
function ClanRankCellData:parseData(_data, _bTrueRank, _selfTeamCid, _selfTeamPoints)
    if not _data then
        return
    end

    self.m_cid = _data.cid or "" --工会ID
    self.m_name = _data.name or "" --工会名称
    self.m_head = _data.head or "" --工会徽章
    self.m_division = math.max(1, tonumber(_data.division) or 1) --段位
    self.m_members = _data.members or 0 --成员数量
    self.m_memberLimit = _data.memberLimit or 0 --最大成员数
    if _bTrueRank then
        self.m_rank = tonumber(_data.rank) or 0
    else
        self.m_rank = math.max(1, tonumber(_data.rank) or 1) --排名
    end
    local serverPoints = _data.points or 0 --点数
    -- if _selfTeamCid == self.m_cid and _selfTeamPoints and serverPoints < _selfTeamPoints then
    if _selfTeamCid == self.m_cid and _selfTeamPoints then
        -- 排行榜数据 可能有缓存 数据滞后 自己的功能可能点数收集更高了
        serverPoints = _selfTeamPoints
    end
    self.m_points = serverPoints --点数
end

--工会ID
function ClanRankCellData:getCid()
    return self.m_cid
end

--工会名称
function ClanRankCellData:getName()
    return self.m_name
end

--工会徽章
function ClanRankCellData:getClanLogo()
    return self.m_head
end

--段位
function ClanRankCellData:getDivision()
    return self.m_division
end

--成员数量
function ClanRankCellData:getMemberCount()
    return self.m_members
end

--最大成员数
function ClanRankCellData:getMemberLimitCount()
    return self.m_memberLimit
end

--排名
function ClanRankCellData:getRank()
    return self.m_rank
end

--点数
function ClanRankCellData:getPoints()
    return self.m_points
end

return ClanRankCellData