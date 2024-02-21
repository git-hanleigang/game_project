--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-16 15:17:40
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-16 15:17:54
FilePath: /SlotNirvana/src/activities/Activity_Leagues/model/LeagueDataSummit.lua
Description: 比赛 巅峰赛数据
--]]
local LeagueUserInfo = require("activities.Activity_Leagues.model.LeagueUserInfo")
local LeagueRewardInfo = require("activities.Activity_Leagues.model.LeagueRewardInfo")
local LeagueDivisionInfo = require("activities.Activity_Leagues.model.LeagueDivisionInfo")
local LeagueTrophyCfgData = require("activities.Activity_Leagues.model.LeagueTrophyCfgData")
local LeagueCollectResultInfo = require("activities.Activity_Leagues.model.LeagueCollectResultInfo")

local BaseActivityData = require("baseActivity.BaseActivityData")
local LeagueDataSummit = class("LeagueDataSummit", BaseActivityData)

function LeagueDataSummit:ctor()
    LeagueDataSummit.super.ctor(self)
    
    self.m_season = 0 --赛季
    self.m_division = 0 --段位
    self.m_points = 0 --积分
    self.m_bCollect = false --是否领取上赛季奖励 true：领取；false：不领取
    self.m_rankInLevel = {} --关卡内用户排行榜列表
    self.m_bOpenRank = false --排行榜是否开启 true：开启，false：未开启
    self.m_storeDiscount = 0 --金币商城加成系数
    self.m_cashBonusDiscount = 0 --Cashbonus加成系数
    self.m_openRankMinPoints = 0 -- // 准入门槛分
    
    self.m_myRankId = 0 -- 我的排名
    self.m_myRankStatus = LeagueRankStatus.Same -- 我的排名变化状态
    self.m_trophyCfgList = {} -- 奖杯数据

    -- ====== 排行榜数据 ======
    -- 我的排名信息
    self.m_myRank = nil
    -- 榜单玩家
    self.m_rankUsers = {}
    -- 奖励信息排行
    self.m_rankAwards = {}
    -- jackpot pool初始值
    self.m_baseJackpotPool = 0
    -- =======================
    
    self.m_winCupInfo = nil -- 获得奖杯的信息

    self.m_collectResult = nil -- 领取奖励结构

    self.m_actType = "Summit"
end

function LeagueDataSummit:parseData(_data)
    if not _data then
        return
    end

    LeagueDataSummit.super.parseData(self, _data)

    self.m_season = _data.season --赛季
    self.m_division = _data.division --段位
    self.m_points = tonumber(_data.points) or 0 --积分
    self.m_bCollect = _data.collect--是否领取上赛季奖励 true：领取；false：不领取
    self:updateRankInLevel(_data.userRanks or {}) --关卡内用户排行榜列表
    self.m_bOpenRank = _data.openRank --排行榜是否开启 true：开启，false：未开启
    self.m_storeDiscount = tonumber(_data.storeDiscount) or 0 --金币商城加成系数
    self.m_cashBonusDiscount = tonumber(_data.cashBonusDiscount) or 0 --Cashbonus加成系数
    self.m_openRankMinPoints = tonumber(_data.openRankMinPoints) or 0 -- // 准入门槛分
    self:parseTrophyCfg(_data.trophy or {}) --奖杯数据

    G_GetMgr(G_REF.LeagueCtrl):setMyDivision(self.m_division)
end

-- 解析奖杯数据
function LeagueDataSummit:parseTrophyCfg(_cfgList)
    self.m_trophyCfgList = {}

    for i,v in ipairs(_cfgList) do
        local trophyCfgData = LeagueTrophyCfgData:create()
        trophyCfgData:parseData(v)
        table.insert(self.m_trophyCfgList, trophyCfgData)
    end
end
function LeagueDataSummit:getTrophyCfgList()
    return self.m_trophyCfgList
end

-- 是否可领取上赛季奖励
function LeagueDataSummit:isCanCollect()
    return self.m_bCollect
end
function LeagueDataSummit:setCanCollect(flag)
    self.m_bCollect = flag
end

-- 我的积分
function LeagueDataSummit:setMyPoints(points)
    self.m_points = points
end
function LeagueDataSummit:getMyPoints()
    return self.m_points
end

-- 自身段位
function LeagueDataSummit:getMyDivision()
    return self.m_division
end

-- 巅峰赛 是否开启排行(0分也开)
function LeagueDataSummit:isOpenRank()
    return true
end
function LeagueDataSummit:updateOpenRank(openRank)
    self.m_bOpenRank = openRank
end

-- 准入门槛分
function LeagueDataSummit:getOpenMinPoints()
    return math.max(self.m_openRankMinPoints or 0, 100)
end

-- CashBonus加成
function LeagueDataSummit:getCashBonusDis()
    return math.max(self.m_cashBonusDis or 0, 0)
end
-- coinStore加成
function LeagueDataSummit:getStoreDis()
    return math.max(self.m_storeDis or 0, 0)
end

-- 关卡内排行榜
function LeagueDataSummit:getRankListInLevel()
    return self.m_rankInLevel
end
-- 获取关卡内排行信息
function LeagueDataSummit:getRankInfoInLevel(udid)
    for i = 1, #self.m_rankInLevel do
        local info = self.m_rankInLevel[i]
        if info:getUdid() == udid then
            return info
        end
    end

    return nil
end

-- 解析 排行榜数据
function LeagueDataSummit:parseRankData(data)
    if not data then
        return
    end
    -- 我的排行
    if not self.m_myRank then
        self.m_myRank = LeagueUserInfo:create()
    end
    self.m_myRank:parseData(data.myRank)

    -- 更新排名
    self:setMyRankId(self.m_myRank:getRankId())
    self:setMyRankStatus(self.m_myRank:getStatus())

    -- 玩家排行列表
    self.m_rankUsers = {}
    for i = 1, #(data.rankUsers or {}) do
        local _info = LeagueUserInfo:create()
        _info:parseData(data.rankUsers[i])
        table.insert(self.m_rankUsers, _info)
    end

    -- 关卡排名列表
    self:updateRankInLevel(data.userRanks)

    -- 排行奖励列表
    self.m_rankAwards = {}
    for i = 1, #(data.rewards or {}) do
        local _info = LeagueRewardInfo:create(true)
        _info:parseData(data.rewards[i])
        table.insert(self.m_rankAwards, _info)
    end

    -- 玩家当前段位
    self.m_curDivision = data.division
    -- 玩家下一段位
    self.m_nextDivision = data.nextDivision
    -- 升段位最低排名
    self.m_upDiviRank = data.upDivisonIndex
    -- 降段位最高排名
    self.m_downDiviRank = data.downDivisionIndex

    self.m_baseJackpotPool = data.poolCoins
end

-- 更新关卡内排行榜
function LeagueDataSummit:updateRankInLevel(_rankData)
    self.m_rankInLevel = {}
    for i = 1, #(_rankData or {}) do
        local _info = LeagueUserInfo:create()
        _info:parseData(_rankData[i])
        table.insert(self.m_rankInLevel, _info)
    end

    self:updateMyRankInfo()
end

-- 更新我的排名信息
function LeagueDataSummit:updateMyRankInfo()
    -- 更新排名id
    local rankInfo = self:getRankInfoInLevel(globalData.userRunData.userUdid)
    if rankInfo then
        self.m_myRankId = rankInfo:getRankId()
        self.m_myRankStatus = rankInfo:getStatus()
    end
end
-- 自身排名信息
function LeagueDataSummit:getMyRankInfo()
    return self.m_myRank
end
function LeagueDataSummit:setMyRankId(id)
    self.m_myRankId = id
end
function LeagueDataSummit:getMyRankId()
    return self.m_myRankId
end
function LeagueDataSummit:setMyRankStatus(status)
    self.m_myRankStatus = status
end
function LeagueDataSummit:getMyRankStatus()
    return self.m_myRankStatus
end

-- 玩家排名
function LeagueDataSummit:getRankUsers()
    return self.m_rankUsers or {}
end

-- 获得排名索引index
function LeagueDataSummit:getRankIndex(udid)
    if not udid or udid == "" then
        return nil
    end
    for i = 1, #self.m_rankUsers do
        local _info = self.m_rankUsers[i]
        if _info:getUdid() == udid then
            return i
        end
    end

    return nil
end

-- 获取玩家排名 所在的奖励idx
function LeagueDataSummit:getRankAwardsKey(_rank)
    local rankAwards = self:getRankAwards()
    for idx, awardInfoData in ipairs(rankAwards) do
        local minRank = awardInfoData:getMinRank()
        local maxRank = awardInfoData:getMaxRank()
        if _rank >= minRank and _rank <= maxRank then
            return idx
        end
    end

    return 0
end

-- 奖励排名
function LeagueDataSummit:getRankAwards(_idx)
    local rankAwards = self.m_rankAwards or {}
    if not _idx then
        return rankAwards
    end

    return rankAwards[_idx] or {}
end

-- 解析奖励数据
function LeagueDataSummit:parseCollectResult(_data)
    if not self.m_collectResult then
        self.m_collectResult = LeagueCollectResultInfo:create()
    end
    self.m_collectResult:parseData(_data)
end
function LeagueDataSummit:getCollectResult()
    return self.m_collectResult
end

-- 设置奖杯信息
function LeagueDataSummit:setWinCupInfo(cupInfo)
    self.m_winCupInfo = cupInfo
end
function LeagueDataSummit:getWinCupInfo()
    return self.m_winCupInfo
end

function LeagueDataSummit:getBaseJackpotPool()
    return self.m_baseJackpotPool or 0
end
function LeagueDataSummit:getCurJackpotPool()
    local pool = self.m_curJackpotPool or 0
    if pool < self:getBaseJackpotPool() then
        self.m_curJackpotPool = self:getBaseJackpotPool()
    end
    return self.m_curJackpotPool
end
function LeagueDataSummit:setCurJackpotPool(pool)
    self.m_curJackpotPool = pool
end

--获取入口位置 1：左边，0：右边
function LeagueDataSummit:getPositionBar()
    return 1
end
-- 是否可删除
function LeagueDataSummit:isCanDelete()
    if self:isCanCollect() then
        return false
    end

    if not LeagueDataSummit.super.isCanDelete(self) then
        return false
    end

    return true
end
-- 是否忽略到期
function LeagueDataSummit:isIgnoreExpire()
    local isIgnor = LeagueDataSummit.super.isIgnoreExpire(self)
    if isIgnor then
        return true
    end

    if self:isCanCollect() and self:getLeftTime() <= 0 then
        -- 当前时间过期且可领取奖励，忽略到期时间
        return true
    end

    return false
end
-- 是否可显示关卡入口
function LeagueDataSummit:isCanShowEntry()
    if self:isCanCollect() or self:getLeftTime() <= 0 then
        return false
    else
        return true
    end
end

function LeagueDataSummit:isSleeping()
    if self:getLeftTime() <= 2 and (not self:isCanCollect()) then
        return true
    end

    return false
end

return LeagueDataSummit