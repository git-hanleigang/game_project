--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-08 15:59:16
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-08 15:59:46
FilePath: /SlotNirvana/src/data/clanData/ClanRankTopMembersInfoData.lua
Description: 最强百人排行 数据
--]]
local ClanRankTopMembersInfoData = class("ClanRankTopMembersInfoData")
local ClanRankTopUserData = util_require("data.clanData.ClanRankTopUserData")
-- message ClanRankTopResponse {
--     required ResponseCode code = 1 [default = SUCCEED]; //返回码
--     optional string description = 2; //返回码的描述信息
--     repeated ClanRank ranks = 3; //工会榜单
--     optional string begin = 4; //开始时间
--     optional string end = 5; //结束时间
--     optional ClanRank myRank = 6;
--     repeated ClanUserTopRank userRanks = 7;//百强个人
--     optional ClanUserTopRank userMyRank = 8;
--   }
function ClanRankTopMembersInfoData:ctor()
    self.m_beginTime = "" -- 开始时间
    self.m_endTime = "" -- 结束时间
    self.m_teamRankList = {} -- 百人榜单
    self.m_selfRankInfo = ClanRankTopUserData:create() -- 玩家所在公会信息
end

function ClanRankTopMembersInfoData:parseData(_data, _selfTeamId)
    if not _data then
        return
    end

    self.m_beginTime = _data.begin or ""
    self.m_endTime = _data["end"] or ""
    self.m_selfTeamId = _selfTeamId
    self:parseRankList(_data.userRanks or {})
    if _data.userMyRank then
        self.m_selfRankInfo:parseData(_data.userMyRank, true)
    end
end

function ClanRankTopMembersInfoData:parseRankList(_list)
    self.m_teamRankList = {}
    
    for i=1, #_list do
        local cellRankInfo = _list[i]
        local cellRankData = ClanRankTopUserData:create()
        cellRankData:parseData(cellRankInfo, true)
        table.insert(self.m_teamRankList, cellRankData)
    end

    -- for i=1, 100 do
    --     local cellRankInfo = _list[i]
    --     local cellRankData = ClanRankTopUserData:create()
    --     cellRankData.m_clanId = "TEST" .. i --工会ID
    --     cellRankData.m_clanName = "TEST" .. i --工会名称
    --     cellRankData.m_clanHead = util_random(1, 18) --工会徽章
    --     cellRankData.m_name = "Guest00" .. i --玩家名字
    --     cellRankData.m_facebookId = "" --玩家facebookId
    --     cellRankData.m_udid = "" --玩家udid
    --     cellRankData.m_head = util_random(1, 10) --玩家头像
    --     cellRankData.m_frame = "" --玩家头像框
    --     cellRankData.m_rank = i --玩家排名
    --     cellRankData.m_points = 1000 - i --点数

    --     table.insert(self.m_teamRankList, cellRankData)
    -- end
end

-- 开始时间
function ClanRankTopMembersInfoData:getBeginTime()
    return self.m_beginTime
end

-- 结束时间
function ClanRankTopMembersInfoData:getEndTime()
    return self.m_endTime
end

function ClanRankTopMembersInfoData:getTimeStr()
    return self.m_beginTime .. " - " .. self.m_endTime
end

-- 百人榜单
function ClanRankTopMembersInfoData:getTeamRankList()
    return self.m_teamRankList
end

function ClanRankTopMembersInfoData:getTeamRankInfoByIdx(_idx)
    return self.m_teamRankList[_idx]
end

function ClanRankTopMembersInfoData:getSelfTeamRankInfo()
    return self.m_selfRankInfo
end

return ClanRankTopMembersInfoData