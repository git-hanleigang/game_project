--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-08 15:59:16
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-08 15:59:46
FilePath: /SlotNirvana/src/data/clanData/ClanRankTopInfoData.lua
Description: 最强公会排行 数据
--]]
local ClanRankTopInfoData = class("ClanRankTopInfoData")
local ClanRankCellData = util_require("data.clanData.ClanRankCellData")
-- message ClanRankTopResponse {
--     required ResponseCode code = 1 [default = SUCCEED]; //返回码
--     optional string description = 2; //返回码的描述信息
--     repeated ClanRank ranks = 3; //工会榜单
--     optional string begin = 4; //开始时间
--     optional string end = 5; //结束时间
--     optional ClanRank myRank = 6;
--   }
function ClanRankTopInfoData:ctor()
    self.m_beginTime = "" -- 开始时间
    self.m_endTime = "" -- 结束时间
    self.m_teamRankList = {} -- 工会榜单
    self.m_selfRankInfo = ClanRankCellData:create() -- 玩家所在公会信息
    self:parseData({}, 1)
end

function ClanRankTopInfoData:parseData(_data, _selfTeamId)
    if not _data then
        return
    end

    self.m_beginTime = _data.begin or ""
    self.m_endTime = _data["end"] or ""
    self.m_selfTeamId = _selfTeamId
    self:parseRankList(_data.ranks or {})
    if _data.myRank then
        self.m_selfRankInfo:parseData(_data.myRank, true)
    end

    -- self.m_selfRankInfo.m_rank = 10
end

function ClanRankTopInfoData:parseRankList(_list)
    self.m_teamRankList = {}
    
    for i=1, #_list do
        local cellRankInfo = _list[i]
        local cellRankData = ClanRankCellData:create()
        cellRankData:parseData(cellRankInfo, true)
        table.insert(self.m_teamRankList, cellRankData)
    end

    -- for i=1, 100 do
    --     local cellRankInfo = _list[i]
    --     local cellRankData = ClanRankCellData:create()
        
    --     cellRankData.m_cid = "TEST" .. i --工会ID
    --     cellRankData.m_name = "TEST" .. i --工会名称
    --     cellRankData.m_head = util_random(1, 18) --工会徽章
    --     cellRankData.m_division = util_random(1, 8) --段位
    --     cellRankData.m_members = util_random(1, 10) --成员数量
    --     cellRankData.m_memberLimit = 10 --最大成员数
    --     cellRankData.m_rank = i --排名
    --     cellRankData.m_points = 1000 - i --点数

    --     table.insert(self.m_teamRankList, cellRankData)
    -- end
end

-- 开始时间
function ClanRankTopInfoData:getBeginTime()
    return self.m_beginTime
end

-- 结束时间
function ClanRankTopInfoData:getEndTime()
    return self.m_endTime
end

function ClanRankTopInfoData:getTimeStr()
    return self.m_beginTime .. " - " .. self.m_endTime
end

-- 工会榜单
function ClanRankTopInfoData:getTeamRankList()
    return self.m_teamRankList
end
function ClanRankTopInfoData:getTeamRankInfoByIdx(_idx)
    return self.m_teamRankList[_idx]
end

function ClanRankTopInfoData:getSelfTeamRankInfo()
    return self.m_selfRankInfo
end

return ClanRankTopInfoData