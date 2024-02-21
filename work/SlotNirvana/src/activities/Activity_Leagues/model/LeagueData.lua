--[[
    关卡联赛数据
]]
-- GD.LeagueControl = require("activities.Activity_Leagues.controller.LeagueControl"):getInstance()

local LeagueUserInfo = require("activities.Activity_Leagues.model.LeagueUserInfo")
local LeagueRewardInfo = require("activities.Activity_Leagues.model.LeagueRewardInfo")
local LeagueDivisionInfo = require("activities.Activity_Leagues.model.LeagueDivisionInfo")
local LeagueCollectResultInfo = require("activities.Activity_Leagues.model.LeagueCollectResultInfo")

local BaseActivityData = require("baseActivity.BaseActivityData")
local LeagueData = class("LeagueData", BaseActivityData)

function LeagueData:ctor()
    LeagueData.super.ctor(self)
    -- 赛季
    self.m_season = 0
    -- 段位
    self.m_division = 0
    -- 积分
    self.m_points = 0
    -- 领取上赛季奖励
    self.m_collect = false
    -- 排行榜是否开启
    self.m_isOpenRank = false
    -- 商店加成
    self.m_storeDis = 0
    -- cashBonus加成
    self.m_cashBonusDis = 0
    -- 关卡内榜单
    self.m_rankInLevel = nil

    -- ====== 排行榜数据 ======
    -- 我的排名信息
    self.m_myRank = nil
    -- 榜单玩家
    self.m_rankUsers = {}
    -- 奖励信息排行
    self.m_rankAwards = {}
    -- 段位信息排行
    self.m_rankDivisions = {}
    -- =======================
    -- 领取奖励结构
    self.m_collectResult = nil

    -- jackpot pool初始值
    self.m_baseJackpotPool = 0

    -- =======================
    -- 引导步骤
    self.m_guideStep = gLobalDataManager:getNumberByField("GuideLeagueStep", 1)
    self.m_maxGuideStep = 6

    -- =========运行时数据===============
    -- jackpot pool 当前值
    self.m_curJackpotPool = 0

    -- 我的排名
    self.m_myRankId = 0
    -- 我的排名变化状态
    self.m_myRankStatus = LeagueRankStatus.Same

    -- 获得奖杯的信息
    self.m_winCupInfo = nil

    -- 比赛类型 资格赛或者普通赛
    self.m_actType = ""

    --进入巅峰赛排名门槛
    self.m_summitLimitRank = 3
end

-- 设置奖杯信息
function LeagueData:setWinCupInfo(cupInfo)
    self.m_winCupInfo = cupInfo
end

-- 获得奖杯信息
function LeagueData:getWinCupInfo()
    return self.m_winCupInfo
end

-- 获取引导步骤
function LeagueData:getGuideStep()
    return self.m_guideStep
end

-- 获取最大引导步骤
function LeagueData:getMaxGuideStep()
    return self.m_maxGuideStep
end

-- 设置引导步骤
function LeagueData:setGuideStep(step)
    self.m_guideStep = step
    gLobalDataManager:setNumberByField("GuideLeagueStep", step)
end

-- 引导完成
function LeagueData:isGuideCompleted()
    return self.m_guideStep >= self.m_maxGuideStep
end

-- 自身段位
function LeagueData:getMyDivision()
    return self.m_division
end

-- 关卡内排行榜
function LeagueData:getRankListInLevel()
    return self.m_rankInLevel
end

-- 获取关卡内排行信息
function LeagueData:getRankInfoInLevel(udid)
    for i = 1, #self.m_rankInLevel do
        local info = self.m_rankInLevel[i]
        if info:getUdid() == udid then
            return info
        end
    end
    return nil
end

--[[
    @desc: 解析活动数据
    author:徐袁
    time:2020-12-21 11:49:32
    --@data: 
    @return:
]]
function LeagueData:parseData(data)
    if not data then
        return
    end

    LeagueData.super.parseData(self, data)

    self.m_season = data.season
    self.m_division = data.division
    self.m_points = data.points
    self.m_collect = data.collect
    self.m_isOpenRank = data.openRank
    self.m_storeDis = data.storeDiscount
    self.m_cashBonusDis = data.cashBonusDiscount
    self.m_openRankMinPoints = data.openRankMinPoints
    self.m_actType  = data.type
    self.m_summitLimitRank = data.summitLimitRank or 3
    
    self:updateRankInLevel(data.userRanks)
    G_GetMgr(G_REF.LeagueCtrl):setMyDivision(self.m_division)
end

-- CashBonus加成
function LeagueData:getCashBonusDis()
    return math.max(self.m_cashBonusDis or 0, 0)
end

-- coinStore加成
function LeagueData:getStoreDis()
    return math.max(self.m_storeDis or 0, 0)
end

-- 是否可领取上赛季奖励
function LeagueData:isCanCollect()
    return self.m_collect
    -- return true
end

-- 设置可领取状态
function LeagueData:setCanCollect(flag)
    self.m_collect = flag
end

function LeagueData:getMyPoints()
    return self.m_points
end

function LeagueData:setMyPoints(points)
    self.m_points = points
end

function LeagueData:isOpenRank()
    return self.m_isOpenRank
end

function LeagueData:updateOpenRank(openRank)
    self.m_isOpenRank = openRank
end

function LeagueData:getOpenMinPoints()
    return math.max(self.m_openRankMinPoints or 0, 100)
end

-- 更新关卡内排行榜
function LeagueData:updateRankInLevel(_rankData)
    self.m_rankInLevel = {}
    for i = 1, #(_rankData or {}) do
        local _info = LeagueUserInfo:create()
        _info:parseData(_rankData[i])
        table.insert(self.m_rankInLevel, _info)
    end

    self:updateMyRankInfo()
end

-- 更新我的排名信息
function LeagueData:updateMyRankInfo()
    -- 更新排名id
    local rankInfo = self:getRankInfoInLevel(globalData.userRunData.userUdid)
    if rankInfo then
        self:setMyRankId(rankInfo:getRankId())
        self:setMyRankStatus(rankInfo:getStatus())
    end
end

-- ===========================================
--[[
    @desc: 解析排行榜数据
    author:徐袁
    time:2020-12-21 11:50:05
    --@data: 
    @return:
]]
function LeagueData:parseRankData(data)
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
        local _info = LeagueRewardInfo:create()
        _info:parseData(data.rewards[i])
        table.insert(self.m_rankAwards, _info)
    end

    -- 排行段位列表
    self.m_rankDivisions = {}
    for i = 1, #(data.divisions or {}) do
        local _info = LeagueDivisionInfo:create()
        _info:parseData(data.divisions[i])
        table.insert(self.m_rankDivisions, _info)
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

    self:initUpAndDownDiviIndex()
end

-- 获得排名索引index
function LeagueData:getRankIndex(udid)
    local rankIdx = nil
    udid = udid or ""

    local nCount = #self.m_rankUsers
    for i = 1, nCount do
        local _info = self.m_rankUsers[i]
        if _info:getUdid() == udid then
            rankIdx = i
            break
        end
    end

    assert(rankIdx, string.format("not find my rank idx, udid = %s, ranks count = %d", udid, nCount))

    return rankIdx
end

-- 计算升降段位索引
function LeagueData:initUpAndDownDiviIndex()
    if not self.m_upDiviRank or not self.m_downDiviRank then
        return
    end 
    
    -- 上升index
    for i = 1, (#self.m_rankUsers) do
        local _info = self.m_rankUsers[i]

        if _info:getRankId() > self.m_upDiviRank then
            self.m_upDiviRankIndex = i
            break
        end
    end

    -- 下降index
    for i = #self.m_rankUsers, 1, -1 do
        local _info = self.m_rankUsers[i]

        if _info:getRankId() < self.m_downDiviRank then
            self.m_downDiviRankIndex = i + 1
            break
        end
    end
end

-- 升段位列表index
function LeagueData:getUpDiviRankIndex()
    if self:getMyDivision() == 10 then
        return 0
    end
    return self.m_upDiviRankIndex or 0
end

-- 降段位列表index
function LeagueData:getDownDiviRankIndex()
    return self.m_downDiviRankIndex or 0
end

-- 自身排名信息
function LeagueData:getMyRankInfo()
    return self.m_myRank
end

function LeagueData:setMyRankId(id)
    self.m_myRankId = id
end

function LeagueData:getMyRankId()
    return self.m_myRankId
end

function LeagueData:setMyRankStatus(status)
    self.m_myRankStatus = status
end

function LeagueData:getMyRankStatus()
    return self.m_myRankStatus
end

-- 玩家排名
function LeagueData:getRankUsers()
    return self.m_rankUsers or {}
end

-- 获取玩家排名 所在的奖励idx
function LeagueData:getRankAwardsKey(_rank)
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
function LeagueData:getRankAwards(_idx)
    local rankAwards = self.m_rankAwards or {}
    if not _idx then
        return rankAwards
    end

    return rankAwards[_idx] or {}
end

-- 段位排名列表
function LeagueData:getRankDivisions()
    return self.m_rankDivisions or {}
end

-- 段位信息
function LeagueData:getDivisionInfo(divisionId)
    return self.m_rankDivisions[divisionId]
end

-- 段位索引
function LeagueData:getDivisionIndex(divisionId)
    for index = 1, #self.m_rankDivisions do
        local info = self.m_rankDivisions[index]
        if divisionId == info:getDivision() then
            return index
        end
    end

    return -1
end

--
function LeagueData:getRankCurDivision()
    return self.m_curDivision or 0
end

--
function LeagueData:getRankNextDivision()
    return self.m_nextDivision or 0
end
-- =====================================================
-- 解析奖励数据
function LeagueData:parseCollectResult(data)
    if not self.m_collectResult then
        self.m_collectResult = LeagueCollectResultInfo:create()
    end
    self.m_collectResult:parseData(data)
end

function LeagueData:getCollectResult()
    return self.m_collectResult
end

-- =======================================================
function LeagueData:getBaseJackpotPool()
    return self.m_baseJackpotPool or 0
end

function LeagueData:getCurJackpotPool()
    local pool = self.m_curJackpotPool or 0
    if pool < self:getBaseJackpotPool() then
        self.m_curJackpotPool = self:getBaseJackpotPool()
    end
    return self.m_curJackpotPool
end

function LeagueData:setCurJackpotPool(pool)
    self.m_curJackpotPool = (pool or 0)
end

--获取入口位置 1：左边，0：右边
function LeagueData:getPositionBar()
    return 1
end

-- 是否可删除
function LeagueData:isCanDelete()
    if self:isCanCollect() then
        return false
    end

    if not LeagueData.super.isCanDelete(self) then
        return false
    end

    return true
end

-- 是否忽略到期
function LeagueData:isIgnoreExpire()
    local isIgnor = LeagueData.super.isIgnoreExpire(self)
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
function LeagueData:isCanShowEntry()
    if self:isCanCollect() or self:getLeftTime() <= 0 then
        return false
    else
        return true
    end
end

-- 检测玩家是否可以参加资格赛 (最高段位可参加)
function LeagueData:checkCanJoinQualified()
    local myRank = self:getMyRankId()

    return false
end

-- (前三名 入围 巅峰赛)
function LeagueData:getJoinSummitLimitIdx()
    return math.max(self.m_summitLimitRank, 3)
end
-- 检测玩家是否入围巅峰赛 (前三名 入围)
function LeagueData:checkCanJoinSummit()
    local myRank = self:getMyRankId()
    if self.m_actType == "LEAGUES_QUALIFIED" and myRank <= self:getJoinSummitLimitIdx() then
        return true
    end
    return false
end

function LeagueData:isSleeping()
    if self:getLeftTime() <= 2 and (not self:isCanCollect()) then
        return true
    end

    return false
end

return LeagueData
