-- bingo比赛 数据

local BaseActivityRankCfg = require("baseActivity.BaseActivityRankCfg")
local BingoRushHallData = require("activities.Activity_BingoRush.model.BingoRushHallData")
local BingoRushGameData = require("activities.Activity_BingoRush.model.BingoRushGameData")
local BingoRushLevelData = require("activities.Activity_BingoRush.model.BingoRushLevelData")
local BingoRushSaleData = require("activities.Activity_BingoRush.model.BingoRushSaleData")
local BingoRushPassData = require("activities.Activity_BingoRush.model.BingoRushPassData")
local BaseActivityData = require "baseActivity.BaseActivityData"
local BingoRushData = class("BingoRushData", BaseActivityData)

function BingoRushData:ctor()
    BingoRushData.super.ctor(self)
    -- 房间数据
    self.hall_data = BingoRushHallData.new()
    -- bingo游戏数据
    self.bingo_data = BingoRushGameData.new()

    --关卡数据
    self.m_levelData = BingoRushLevelData.new()

    -- 促销数据
    self.m_saleData = BingoRushSaleData.new()
    -- 促销数据
    self.m_saleNoCoinData = BingoRushSaleData.new()
    -- pass数据
    self.m_passData = BingoRushPassData.new()
end

--message BingoRush {
--    optional int32 expire = 1;
--    optional int64 expireAt = 2;
--    optional string activityId = 3;
--    optional int32 curRound = 4;// 当前轮数 1 2 3 ...
--    repeated BingoRushBet bingoRushBets = 5;// 三档Bet
--    optional int32 curBetIndex = 6;// 当前Bet
--    optional string rushRoomId = 7;// 房间号
--    optional int32 chairId = 8;// 座位号
--    optional int32 zone = 11;  //排行榜 赛区
--    optional int32 roomType = 12;  //排行榜 房间类型
--    optional int32 roomNum = 13;  //排行榜 房间数
--    optional int32 rankUp = 14; //排行榜排名上升的幅度
--    optional int32 rank = 15; //排行榜排名
--    optional int32 points = 16; //排行榜点数
--    optional BingoRushSale sale = 17; //促销
--    optional BingoRushPass pass = 18; //pass
--}
function BingoRushData:parseData(data, isJson, isNetData)
    if not data then
        return
    end
    BaseActivityData.parseData(self, data, isJson)
 
    -- 解析数据
    self.bingoRushBets = self:parseBets(data.bingoRushBets) -- bet列表
    self.curBetIndex = data.curBetIndex -- 当前选定bet
    self.chairId = data.chairId -- 座位号
    self.rankUp = data.rankUp
    self.rank = data.rank
    self.points = data.points

    self.m_saleData:parseData(data.sale) -- 促销数据
    self.m_passData:parseData(self.points, data.pass) -- pass数据

    -- 刷新数据
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.BingoRush})
end

--message BingoRushBet {
--    optional int32 index = 1;
--    repeated int64 gameBets = 2;// 前两关的Bet
--    optional int64 prizePool = 3;// 预估奖池
--    optional int64 transCoins = 4;// 兑换比例
--}
function BingoRushData:parseBets(bets)
    local betsList = {}
    for i, bet_data in ipairs(bets) do
        local bet = {}
        bet.index = bet_data.index
        bet.gameBets = {}
        for __, p_bet in ipairs(bet_data.gameBets) do
            table.insert(bet.gameBets, p_bet)
        end
        bet.prizePool = bet_data.prizePool
        bet.transCoins = bet_data.transCoins

        betsList[bet.index] = bet
    end
    return betsList
end

function BingoRushData:getChairId()
    return self.chairId
end

function BingoRushData:getBetsData()
    return self.bingoRushBets
end

function BingoRushData:getBetsDataByIdx(idx)
    local betsData = self:getBetsData()
    if betsData then
        return betsData[idx]
    end
end

function BingoRushData:getCurBetData()
    return self:getBetsDataByIdx(self.curBetIndex)
end

function BingoRushData:getBetIdx()
    return self.curBetIndex
end

-------------------------------------------------- 排行榜数据 ----------------------------------------------------
function BingoRushData:parseMatchRankConfig(data)
    if data == nil then
        return
    end

    if not self.matchRankConfig then
        self.matchRankConfig = BaseActivityRankCfg:create()
    end
    self.matchRankConfig:parseData(data)

    local myRankConfigInfo = self.matchRankConfig:getMyRankConfig()
    if myRankConfigInfo ~= nil then
        self:setRank(myRankConfigInfo.p_rank)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.BingoRush})
end

function BingoRushData:getRankCfg()
    return self.matchRankConfig
end

function BingoRushData:getRank()
    return self.rank
end

function BingoRushData:getRankUp()
    return self.rankUp
end

-------------------------------------------------- 排行榜数据 ----------------------------------------------------

-------------------------------------------------- 比赛房间数据 ----------------------------------------------------

function BingoRushData:parseHallData(data)
    if not data then
        return
    end
    self.hall_data:parseData(data)
end

function BingoRushData:getHallData()
    return self.hall_data
end

-------------------------------------------------- 比赛房间数据 ----------------------------------------------------

function BingoRushData:setSpinData(data)
    self.spin_data = data
end

function BingoRushData:getSpinData()
    return self.spin_data
end

-------------------------------------------------- bingo游戏数据 ----------------------------------------------------
-- 解析bingo游戏数据
function BingoRushData:parseBingoData(data)
    if not data then
        return
    end
    self.bingo_data:parseData(data)
end

function BingoRushData:getBingoGameData()
    return self.bingo_data
end

-------------------------------------------------- bingo关卡数据 ----------------------------------------------------

--获取入口位置 1：左边，0：右边
--function BingoRushData:getPositionBar()
--    return 1
--end

--[[
    解析关卡数据
]]
function BingoRushData:parseLevelGameData(data)
    if not data then
        return
    end

    self.m_levelData:parseData(data)
end

--[[
    获取关卡数据
]]
function BingoRushData:getLevelData()
    return self.m_levelData
end

-------------------------------------------------- bingo付费数据 ----------------------------------------------------
-- 获取促销数据
function BingoRushData:getSaleData()
    return self.m_saleData
end

-- 获取促销数据
function BingoRushData:getSaleNoCoinData()
    return self.m_saleNoCoinData
end

-- 获取pass数据
function BingoRushData:getPassData()
    return self.m_passData
end
-------------------------------------------------- bingo付费数据 ----------------------------------------------------

return BingoRushData
