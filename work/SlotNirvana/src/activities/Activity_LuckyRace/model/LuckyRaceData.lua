--[[
    单人限时比赛 数据
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local LuckyRaceData = class("LuckyRaceData", BaseActivityData)
local ShopItem = require("data.baseDatas.ShopItem")

function LuckyRaceData:ctor()
    LuckyRaceData.super.ctor(self)
    self.m_myRankStatus = LuckyRaceRankStatus.Same
    self.m_addPoints = 0
end

--[[
    message LuckyRace {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional string jackpotCoins = 4;//房间总金币奖励
        optional int32 rank = 5; //排行榜排名
        optional int32 points = 6; //排行榜 积分
        optional int32 maxPoints = 7; //房间最大积分
        repeated LuckyRaceRankUser rankList = 8;//排行榜
        repeated LuckyRaceRankReward rankRewardList = 9;//排行榜奖励
        optional LuckyRaceSale sale = 10;//促销
        optional int64 avgBet2 = 11;//金币与积分兑换比例
        optional int32 round = 12;//轮次
        optional int64 startTime = 13;//比赛开始时间（最晚）
        optional int64 endTime = 14;//比赛结束时间（最晚）
        optional bool collected = 15;//是否领取奖励
        optional int64 startResponseTime = 16;//开始确认时间
        optional string status = 17;//状态PENDING_RESPONSE(待响应)、RESPONDED(已响应)
        repeated int32 gameIds = 18;//开放的关卡id
    }
]]
function LuckyRaceData:parseData(_data)
    LuckyRaceData.super.parseData(self, _data)
    self.p_jackpotCoins = _data.jackpotCoins
    self.p_rank = tonumber(_data.rank)
    self.p_points = tonumber(_data.points)
    self.p_maxPoints = tonumber(_data.maxPoints)
    self.p_rankList = self:parseRankUser(_data.rankList)
    self.p_rankRewardList = self:parseRankReward(_data.rankRewardList)
    self.p_sale = self:parseRaceSale(_data.sale)
    self.p_avgBet2 = tonumber(_data.avgBet2)
    self.p_round = tonumber(_data.round)
    self.p_startTime = tonumber(_data.startTime)
    self.p_endTime = tonumber(_data.endTime)
    self.p_collected = _data.collected
    self.p_gameIds = _data.gameIds

    self:updateRankList()
    self:initRankList()

    -- 开始确认时间 (玩家 >= startResponseTime && < startTime) 为匹配时间
    self.p_startResponseTime = tonumber(_data.startResponseTime) or util_getCurrnetTime() * 1000
    -- 本轮 玩家是否 可以玩
    self.p_bCurRoundCanPlay = _data.status == "RESPONDED" -- 状态PENDING_RESPONSE(待响应)、RESPONDED(已响应)

    self:initLocalData()
end

--[[
    addPoints = 1 -- 增加积分
    totalPoints = 2 -- 总积分
    rankList = 5 -- 排行榜列表
    rank = 6 -- 排名
    refreshPart = 7 -- true只刷新部分数据, false刷新全部数据
    winType = 8 -- 赢钱类型 "Spin" or 大赢
    5，6 数据只有在自己排名有变化后才会返回
]]
function LuckyRaceData:parseSpinData(_data)
    self:setAddPoints(_data.addPoints)
    self:setPoints(_data.totalPoints)
    self:setRankList(_data.rankList)
    self:setMyRank(_data.rank)

    -- 有新玩家进入房间 同步本地榜单数据
    self:syncLocalRankListNewPlayer()
end

--[[
    startTime = 3 -- 房间开启时间
    endTime = 4 -- 房间结束时间
    optional int64 startResponseTime = 16;//开始确认时间
]]
function LuckyRaceData:parseHeartBeatData(_data)
    self:setRoomStartTime(_data.startTime)
    self:setRoomEndTime(_data.endTime)
    self:setStartResponseTime(_data.startResponseTime)
end

function LuckyRaceData:initRankList()
    if self:checkIsReadyStatus() then -- 比赛开始玩家，按泳道排序后再进行宝箱id和rank赋值
        for i, v in ipairs(self.p_rankList) do
            v.boxId = tonumber(i)
            v.rank = tonumber(i)
        end
    end
end

function LuckyRaceData:initLocalData()
    if not self.p_localRankList or #self.p_localRankList == 0 then
        self.p_localRankList = self.p_rankList
    end
    if not self.p_localRound then
        self.p_localRound = self.p_round
    end
    if not self.p_localRank then
        self.p_localRank = self.p_rank
    end

    -- 新的一轮开始了
    if self.p_localRound ~= self.p_round then
        self.p_localRound = self.p_round
        self.p_localRank = self.p_rank
        self.p_localRankList = self.p_rankList
    end

    -- 有新玩家进入榜单 同步本地数据
    self:syncLocalRankListNewPlayer()

    self:refreshMyRankStatus()
end

-- 有新玩家进入榜单 同步本地数据
function LuckyRaceData:syncLocalRankListNewPlayer()
    if self.p_rankList and self.p_localRankList and #self.p_rankList > #self.p_localRankList then
        for i = 1, #self.p_rankList do
            local serverUserInfo = self.p_rankList[i]
            if serverUserInfo.udid then
                local bExit = self:checkInLocalRankList(serverUserInfo.udid)
                if not bExit then
                    table.insert(self.p_localRankList, serverUserInfo)
                end
            end
        end
    end
end
-- 判断玩家 udid 是否在本地列表里
function LuckyRaceData:checkInLocalRankList(_udid)
    for i, v in ipairs(self.p_localRankList) do
        if v.udid == _udid then
            return true
        end
    end

    return false
end

function LuckyRaceData:refreshMyRankStatus()
    if not self.p_localRank then
        self.p_localRank = self.p_rank
    end
    local myRankStatus = self.m_myRankStatus
    if self.p_rank ~= self.p_localRank then
        myRankStatus = self.p_rank < self.p_localRank and LuckyRaceRankStatus.Up or LuckyRaceRankStatus.Down
    else
        myRankStatus = LuckyRaceRankStatus.Same
    end
    if self.m_myRankStatus ~= myRankStatus then
        self.m_myRankStatus = myRankStatus
    end
    self.p_localRank = self.p_rank
end

--[[
    message LuckyRaceRankUser {
        optional int32 rank = 1;
        optional string name = 2;
        optional int32 points = 3;
        optional string facebookId = 4;
        optional string head = 5;
        optional string frame = 6;
        optional string udid = 7;
        optional int32 raceTrack = 8;//赛道
        optional string robotHead = 9;//机器人头像
    }
]]
function LuckyRaceData:parseRankUser(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.rank = v.rank
            tempData.name = v.name
            tempData.points = tonumber(v.points)
            tempData.facebookId = v.facebookId
            tempData.head = v.head -- 奖励物品
            tempData.frame = v.frame
            tempData.udid = v.udid
            tempData.raceTrack = v.raceTrack
            tempData.robotHead = v.robotHead
            tempData.boxId = tonumber(i)
            if v.udid == globalData.userRunData.userUdid then
                tempData.name = globalData.userRunData.nickName
                tempData.head = globalData.userRunData.HeadName
                tempData.frame = globalData.userRunData.avatarFrameId
                tempData.facebookId = globalData.userRunData.facebookBindingID
            end
            table.insert(list, tempData)
        end
        table.sort(
            list,
            function(a, b)
                return a.raceTrack < b.raceTrack
            end
        )
    end
    return list
end

--[[
    message LuckyRaceRankReward {
        optional int32 rank = 1;//排名
        optional string coins = 2;
        repeated ShopItem items = 3;
    }
]]
function LuckyRaceData:parseRankReward(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.rank = tonumber(v.rank)
            tempData.coins = tonumber(v.coins)
            tempData.items = self:parseItemsData(v.items)
            table.insert(list, tempData)
        end
    end
    return list
end

--[[
    message LuckyRaceSale {
        repeated ShopItem items = 1;
        optional int64 gems = 2;
    }
]]
function LuckyRaceData:parseRaceSale(_data)
    local saleData = {}
    if _data then
        saleData.items = self:parseItemsData(_data.items)
        saleData.gems = tonumber(_data.gems)
    end
    return saleData
end

-- 解析道具数据
function LuckyRaceData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function LuckyRaceData:setPoints(_points)
    if _points then
        self.p_points = _points
    end
end

function LuckyRaceData:getPoints()
    return self.p_points
end

function LuckyRaceData:getMaxPoints()
    return self.p_maxPoints
end

function LuckyRaceData:getCoinRatio()
    return self.p_avgBet2
end

function LuckyRaceData:setMyRank(_rank)
    if _rank then
        self.p_rank = tonumber(_rank)
    end
end

function LuckyRaceData:getMyRank()
    return self.p_rank or 0
end

function LuckyRaceData:setRankList(_rankList)
    if _rankList and #_rankList > 0 then
        self.p_rankList = self:parseRankUser(_rankList)
        self:updateRankList()
        self:initRankList()
    end
end

function LuckyRaceData:getRankList()
    return self.p_rankList
end

function LuckyRaceData:getRankRewardList()
    return self.p_rankRewardList
end

function LuckyRaceData:getSaleData()
    return self.p_sale
end

function LuckyRaceData:getRound()
    return self.p_round
end

function LuckyRaceData:setRoomStartTime(_startTime)
    if _startTime then
        self.p_startTime = tonumber(_startTime)
    end
end

function LuckyRaceData:getRoomStartTime()
    return math.floor(self.p_startTime / 1000)
end

function LuckyRaceData:setRoomEndTime(_endTime)
    if _endTime then
        self.p_endTime = tonumber(_endTime)
    end
end

function LuckyRaceData:getRoomEndTime()
    return math.floor(self.p_endTime / 1000)
end

function LuckyRaceData:setStartResponseTime(_startResponseTime)
    if _startResponseTime then
        self.p_startResponseTime = tonumber(_startResponseTime)
    end
end
function LuckyRaceData:getStartResponseTime()
    return math.floor(self.p_startResponseTime / 1000)
end

-- 本轮 玩家是否 可以玩
function LuckyRaceData:checkCurRoundCanPlay()
    return self.p_bCurRoundCanPlay
end

function LuckyRaceData:getCollected()
    return self.p_collected
end

function LuckyRaceData:isOverMaxPoints()
    return self:getPoints() >= self:getMaxPoints()
end

function LuckyRaceData:getBoxRewardById(_boxId)
    if _boxId then
        for i, v in ipairs(self.p_rankRewardList) do
            if v.rank == _boxId then
                return v
            end
        end
    end
    return nil
end

function LuckyRaceData:checkIsCanCollectReward()
    if self:getMyRank() > 0 and self:getMyRank() <= 3 and not self.p_collected and self.p_points >= self.p_maxPoints then
        return true
    end
    return false
end

function LuckyRaceData:checkIsInRaceTime()
    local curTime = util_getCurrnetTime()
    -- if curTime >= self:getRoomStartTime() and curTime < self:getRoomEndTime() then
    -- 开启时间未到 也 可玩
    if curTime < self:getRoomEndTime() then
        return true
    end
    return false
end

function LuckyRaceData:checkIsReadyStatus()
    local rankList = self:getRankList()
    for i, v in ipairs(rankList) do
        if v.points > 0 then
            return false
        end
    end
    return true
end

function LuckyRaceData:getMyRankStatus()
    return self.m_myRankStatus
end

-- 设置spin加的积分
function LuckyRaceData:setAddPoints(_addPoints)
    self.m_addPoints = _addPoints
end

-- 获得spin加的积分
function LuckyRaceData:getAddPoints()
    return self.m_addPoints or 0
end

function LuckyRaceData:getLocalRankList()
    return self.p_localRankList
end

function LuckyRaceData:refreshLocalRankList()
    self.p_localRankList = self.p_rankList
end

-- 将自己排在第一个
function LuckyRaceData:updateRankList()
    if #self.p_rankList > 0 then
        local rankInfo = self.p_rankList[1] -- 按泳道排序后，第一个不是我自己
        if rankInfo.udid ~= globalData.userRunData.userUdid then
            local raceTrack = 1
            for i = 1, #self.p_rankList do
                local rankInfo = self.p_rankList[i]
                if rankInfo.udid == globalData.userRunData.userUdid then
                    raceTrack = rankInfo.raceTrack
                    rankInfo.raceTrack = 1
                    break
                end
            end
            self.p_rankList[1].raceTrack = raceTrack
            table.sort(
                self.p_rankList,
                function(a, b)
                    return a.raceTrack < b.raceTrack
                end
            )
        end
    end
end

-- 需要进行动画的列表
function LuckyRaceData:getAnimationRankList()
    local rankList = {}
    for i = 1, #self.p_rankList do
        local rankInfo = self.p_rankList[i]
        for j = 1, #self.p_localRankList do
            local localRankInfo = self.p_localRankList[j]
            if localRankInfo.udid == rankInfo.udid then
                if localRankInfo.points < rankInfo.points then
                    rankList[#rankList + 1] = rankInfo
                end
            end
        end
    end
    if #rankList > 0 then
        table.sort(
            rankList,
            function(a, b)
                return a.rank < b.rank
            end
        )
    end
    return rankList
end

-- 23.10.16 改成所有关卡都开放
function LuckyRaceData:isLuckyRaceLevel()
    local curMachineData = globalData.slotRunData.machineData
    if curMachineData and curMachineData.p_id then
        local level_id = tonumber(curMachineData.p_id)
        for i, v in ipairs(self.p_gameIds) do
            if level_id == tonumber(v) then
                return true
            end
        end
    end
    return true
end

--获取入口位置 1：左边，0：右边
function LuckyRaceData:getPositionBar()
    return 1
end

function LuckyRaceData:isCanShowEntry()
    if not self:checkCurRoundCanPlay() then
        -- 本轮游戏不可玩
        return false
    end
    if not self:checkIsInRaceTime() then
        return false
    end
    if self:getCollected() then
        return false
    end
    return LuckyRaceData.super.isCanShowEntry(self)
end

-- 关卡入口模块
function LuckyRaceData:getEntryModule()
    if self:isCanShowEntry() then
        local _filePath = self:getRefName() .. "LuckyRaceEntryNodeCode/LuckyRaceEntryNode"
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            local _module, count = string.gsub(_filePath, "/", ".")
            return _module
        end
    end
    return ""
end

return LuckyRaceData
