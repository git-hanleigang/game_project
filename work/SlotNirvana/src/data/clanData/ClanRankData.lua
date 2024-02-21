--[[
Author: cxc
Date: 2022-02-26 14:43:19
LastEditTime: 2022-02-26 14:43:20
LastEditors: cxc
Description: 公会排行数据
FilePath: /SlotNirvana/src/data/clanData/ClanRankData.lua
--]]
local ClanRankData = class("ClanRankData")
local ClanConfig = util_require("data.clanData.ClanConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")
local ClanRankCellData = util_require("data.clanData.ClanRankCellData")
local ClanRankRewardData = util_require("data.clanData.ClanRankRewardData")
-- message ClanRankInfo {
--     optional ClanRank myRank = 1 ; //自己工会的排名
--     repeated ClanRank rankClans = 2; //工会榜单
--     repeated ClanRankReward rewards = 3; //排名奖励
--     optional int64 prizePool = 4; //奖励金币
--     optional int32 divisionUp = 5; //段位上升排名
--     optional int32 divisionDown = 6; //段位下降排名
-- optional int64 expireAt = 7; //排行榜过期时间
--   optional int32 expire = 8; //排行榜过期时间
--   }
  
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
  
--   message ClanRankReward {
--     optional int32 minRank = 1; //最小排名
--     optional int32 maxRank = 2; //最大排名
--     optional int32 coins = 3; //奖励金币
    -- repeated ShopItem items = 4; //物品奖励  废弃
    -- repeated int32 points = 4; //高倍场点数
--   }

function ClanRankData:ctor()
    self.m_myRank = ClanRankCellData:create() -- 自己工会的排名
    self.m_curRoomDivision = 1
    self.m_rankClans = {} -- 工会榜单
    self.m_rewards = {} -- 排名奖励
    self.m_prizePool = 0 -- 奖励金币
    self.m_divisionUp = 0 -- 段位上升排名
    self.m_divisionDown = 999999 -- 段位下降排名

    self.m_rankUPList = {}
    self.m_rankUnchangedList = {}
    self.m_rankDownList = {}
    self.m_expireAt = -1
end

function ClanRankData:parseData(_data, _curRoomDivision, _selfTeamCid, _selfTeamPoints)
    if not _data then
        return
    end

    self.m_curRoomDivision = _curRoomDivision
    self.m_myRank:parseData(_data.myRank, _selfTeamCid, _selfTeamPoints) -- 自己工会的排名
    if not _curRoomDivision then
        self.m_curRoomDivision = self.m_myRank:getDivision()
    end
    self:syncMyRankInfo()
    self:parseRankCellDataList(_data.rankClans or {}, _selfTeamCid, _selfTeamPoints)    -- 工会榜单
    self:parseRankRewardDataList(_data.rewards or {})  -- 排名奖励
    self.m_prizePool = _data.prizePool or {} -- 奖励金币
    self.m_divisionUp = _data.divisionUp or 0 -- 段位上升排名
    self.m_divisionDown = _data.divisionDown or 999999 -- 段位下降排名
    self:parseRankListByUpDown()

    self.m_expireAt = _data.expireAt --排行榜过期时间
end

-- 同步我的 公会信息 （clanData）
function ClanRankData:syncMyRankInfo()
    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    ClanManager:syncMyRankInfo(self.m_myRank)
end
function ClanRankData:getMyRankInfo()
    return self.m_myRank
end

-- 工会榜单
function ClanRankData:parseRankCellDataList(_rewardList, _selfTeamCid, _selfTeamPoints)
    self.m_rankClans = {} 
    for i=1, #_rewardList do
        local cellRankInfo = _rewardList[i]
        local cellRankData = ClanRankCellData:create()
        cellRankData:parseData(cellRankInfo, _selfTeamCid, _selfTeamPoints)
        table.insert(self.m_rankClans, cellRankData)
    end

    table.sort(self.m_rankClans, function(aMData, bMData)
        return aMData:getPoints() > bMData:getPoints()
    end)
end
function ClanRankData:getRankDataList()
    return self.m_rankClans
end

-- 排名奖励
function ClanRankData:parseRankRewardDataList(_rewardList)
    self.m_rewards = {} 
    for i=1, #_rewardList do
        local rewardInfo = _rewardList[i]
        local rewardData = ClanRankRewardData:create()
        rewardData:parseData(rewardInfo)
        table.insert(self.m_rewards, rewardData)
    end
end
function ClanRankData:getRankRewardDataList()
    return self.m_rewards or {}    
end
-- 获取 某一名次对应的奖励
function ClanRankData:getRankRewardDataByRank(_rank)
    if not _rank then
        return
    end

    for i=1, #self.m_rewards do
        local data = self.m_rewards[i]
        if data:checkRankIn(_rank) then
            return data
        end
    end

end

-- 解析 公会段位升级下降不变的 公会
function ClanRankData:parseRankListByUpDown()
    self.m_rankUPList = {}
    self.m_rankUnchangedList = {}
    self.m_rankDownList = {}

    for i=1, #self.m_rankClans do
        local singleRankData = self.m_rankClans[i]
        local rank = singleRankData:getRank()
        if rank <= self.m_divisionUp and self.m_curRoomDivision < #ClanConfig.RANK_DIVISION_DESC then
            -- 有上升权益并且不是最高段位
            table.insert(self.m_rankUPList, singleRankData)
        elseif rank >= self.m_divisionDown and self.m_curRoomDivision > 1 then
            -- 有下降惩罚并且不是最低段位
            table.insert(self.m_rankDownList, singleRankData)
        else
            table.insert(self.m_rankUnchangedList, singleRankData)
        end
    end

end

-- 段位上升的公会
function ClanRankData:getRankUpList()
    return self.m_rankUPList
end
-- 段位下降的公会
function ClanRankData:getRankDownList()
    return self.m_rankDownList
end
-- 段位不变的公会
function ClanRankData:getRankUnchangedList()
    return self.m_rankUnchangedList
end

-- 排行榜时间
function ClanRankData:getRankExpireAt()
    return self.m_expireAt
end

return ClanRankData