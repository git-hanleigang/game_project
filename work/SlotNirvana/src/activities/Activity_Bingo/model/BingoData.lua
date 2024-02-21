--[[
    author:JohnnyFred
    time:2019-10-08 19:36:07
]]

local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"
local ShopItem = require "data.baseDatas.ShopItem"
local BingoActivityConfig = require "data.bingoData.BingoActivityConfig"
local BaseActivityData = require "baseActivity.BaseActivityData"
local BingoData = class("BingoData",BaseActivityData)

BingoData.difficulty = nil --难度

function BingoData:parseData(data,isNetData)
    self.preData = self.data
    BaseActivityData.parseData(self,data,isNetData)
    self.current = data.current
    self.panels = data.panels
    self.rewardCoins = data.rewardCoins    --首页标题显示奖励金币
    self.totalReward = data.totalReward
    self.point = tonumber(data.point)
    self.sequence = data.sequence
    self.collect = data.collect
    self.max = data.max
    self.leftBalls = data.leftBalls
    self.ballLimit = data.ballLimit
    self.spinBallLimit = data.spinBallLimit
    self.difficulty = data.difficulty
    self.maxHitBalls = data.maxHitBalls
    if data.activities then
        self.activities = BingoActivityConfig:create()
        self.activities:parseData(data.activities)
    end
    self.leftHitBalls = data.leftHitBalls
    self.wildBalls = data.wildBalls
    self.questOpenBingoFlag = data.questOpenBingo
    self.serverLogInfo = {r = data.r,bingoBet = data.bingoBet,bingoBetUsd = data.bingoBetUsd,roomType = data.roomType,roomNum = data.roomNum}
    self:setRankJackpotCoins(0)
    self.p_bIsExist = true

    self.p_saveData = data.saveData
    self.p_leftScoops = data.leftScoops -- 钥匙数量
    self.p_progressData = self:parseProgressData(data.progressData) -- 进度条奖励
    self.p_jackpots = self:parseJackpots(data.jackpots) -- jackpot奖池
    self.p_zeusGameData = self:parseZeusGameData(data.gameData) -- 宙斯小游戏

    gLobalNoticManager:postNotification( ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH,{ name = ACTIVITY_REF.Bingo } )
end

-- message BingoProgress {
--     optional int32 pick = 1;//当前收集个数
--     optional int32 total = 2; // 总进度
--     optional int32 finishTimes = 3;// 本轮集满次数
--     repeated BingoProgressRewards rewardList = 4;
--   }
function BingoData:parseProgressData(_data)
    local tempData = {}
    if _data then 
        tempData.p_pick = _data.pick
        tempData.p_total = _data.total
        tempData.p_finishTimes = _data.finishTimes
        tempData.p_rewardList = self:parseRewardList(_data.rewardList)
    end
    return tempData
end
-- message BingoProgressRewards {
--     optional int64 coins = 1;
--     repeated ShopItem items = 2;
--     optional string coinValue = 3;
--     optional int32 treasureId = 4;//宝箱id
--     optional int32 jackpotId = 5;//jackpoctId
--     optional int32 scoop = 6; //挖宝道具数量
--     optional int32 lightning = 7;//闪电图标数量
--     optional string type = 8;// 奖励类型
--   }
function BingoData:parseRewardList(_data)
    local tempData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_coins = v.coins
            temp.p_coinValue = v.coinValue
            temp.p_treasureId = v.treasureId
            temp.p_jackpotId = v.jackpotId
            temp.p_scoop = v.scoop
            temp.p_lightning = v.lightning
            temp.p_type = v.type
            temp.p_items = v.items
            table.insert(tempData, temp)
        end
    end
    table.sort(
        tempData,
        function(a, b)
            return (a.p_treasureId) < (b.p_treasureId)
        end
    )
    return tempData
end

-- message BingoJackpot {
--     optional int32 jackpot = 1;// 1：Mini 2:Minor 3 :Major 4: Grand
--     optional int32 count = 2;// 当前收集数量
--     optional string desc = 3; // 描述
--     optional int64 coins = 4; // 金币
--   }
function BingoData:parseJackpots(_data)
    local tempData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_jackpot = v.jackpot
            temp.p_coins = v.coins
            temp.p_count = v.count
            temp.p_desc = v.desc
            table.insert(tempData, temp)
        end
    end
    table.sort(
        tempData,
        function(a, b)
            return (a.p_jackpot) < (b.p_jackpot)
        end
    )
    return tempData
end

function BingoData:parseZeusGameData(_data)
    local tempData = {}
    if _data then 
        tempData.p_number = _data.number
        tempData.p_picks = _data.picks
        tempData.p_hitPicks = _data.hitPicks
        tempData.p_coins = tonumber(_data.coins)
        tempData.p_findIcons = _data.findIcons
        tempData.p_positions = self:parseBox(_data.positions)
        tempData.p_items = _data.items
    end
    return tempData
end

-- message ZeusPosition {
--     optional int32 pos = 1; // 位置
--     optional int32 type = 2; // 是否翻开 0没翻开，1翻开了
--     optional int32 icon = 3; // 翻开图标
--     optional int64 coins = 4; // 金币奖励
--     repeated ShopItem items = 5;//物品奖励
--   }
function BingoData:parseBox(_data)
    local tempData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_pos = v.pos
            temp.p_type = v.type
            temp.p_icon = v.icon
            temp.p_coins = tonumber(v.coins)
            temp.p_items = v.items
            table.insert(tempData, temp)
        end
    end
    table.sort(
        tempData,
        function(a, b)
            return (a.p_pos) < (b.p_pos)
        end
    )
    return tempData
end

function BingoData:parseItems(_items)
    -- 通用道具
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function BingoData:getLeftScoops()
    return self.p_leftScoops
end

function BingoData:getProgressData()
    return self.p_progressData
end

function BingoData:getJackpots()
    return self.p_jackpots
end

function BingoData:getZeusGameData()
    return self.p_zeusGameData
end

function BingoData:getPreData()
    return self.preData
end

function BingoData:getCurrent()
    return self.current
end

function BingoData:getPanels()
    return self.panels
end

function BingoData:getRewardCoins()
    return self.rewardCoins
end

function BingoData:getTotalReward()
    return self.totalReward
end

function BingoData:getPoint()
    return self.point
end

function BingoData:getSequence()
    return self.sequence
end

function BingoData:getCollect()
    return self.collect
end

function BingoData:getMax()
    return self.max
end

function BingoData:getLeftBalls()
    return self.leftBalls
end

function BingoData:getBallLimit()
    return self.ballLimit
end

function BingoData:getSpinBallLimit()
    return self.spinBallLimit
end

function BingoData:getDifficulty()
    return self.difficulty
end

function BingoData:getActivities()
    return self.activities
end

function BingoData:getLeftHitBalls()
    return self.leftHitBalls
end

function BingoData:getWildBalls()
    return self.wildBalls
end

function BingoData:getServerLogInfo()
    return self.serverLogInfo
end

function BingoData:getQuestOpenBingoFlag()
    return self.questOpenBingoFlag
end

function BingoData:getBuffDoubleTime()
    return globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BINGO_DOUBLEBALL)
end

function BingoData:getBuffDoubleMaxTime()
    return globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BINGO_DOUBLEBALL)
end

function BingoData:getBuffTreasureTime()
    return globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BINGO_TREASUREBUFF) 
end

function BingoData:getBuffTreasureMaxTime()
    return globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BINGO_TREASUREBUFF) 
end

function BingoData:getCurrentCardNumInfo(fireBallInfo)
    local panels = nil
    if fireBallInfo ~= nil then
        local preData = self:getPreData()
        panels = preData ~= nil and preData.panels or self:getPanels()
    else
        panels = self:getPanels()
    end
    local current = nil
    if fireBallInfo ~= nil then
        current = fireBallInfo.current or self:getCurrent()
    else
        current = self:getCurrent()
    end
    local curCardIndex = 0
    local totalCards = 0
    if current ~= nil and panels ~= nil then
        local currentRound = current.round
        for k,v in ipairs(panels) do
            if currentRound == v.round then
                totalCards = v.cards
                break
            end
        end
        curCardIndex = (totalCards - current.cards) + 1
    end
    return curCardIndex,totalCards
end

function BingoData:initBingoExtraData(extraData)
    self.p_extraData = extraData
end

function BingoData:getBingoExtraData()
    return self.p_extraData
end

function BingoData:getMaxHitBalls()
    return self.maxHitBalls
end

--获取入口位置 1：左边，0：右边
function BingoData:getPositionBar()
    return 1
end

function BingoData:parseRankData(_data)
    self.bingoRankConfig = BaseActivityRankCfg:create()
    self.bingoRankConfig:parseData(_data)
    local myRankConfigInfo = self.bingoRankConfig:getMyRankConfig()
    if myRankConfigInfo ~= nil then
        self:setRank(myRankConfigInfo.p_rank)
    end
end

function BingoData:getRankCfg()
    return self.bingoRankConfig
end

function BingoData:getGuideData()
    return (self.p_saveData and self.p_saveData ~= "") and self.p_saveData or "{}"
end

return BingoData