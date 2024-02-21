--新版钻石挑战
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local BaseActivityData = require "baseActivity.BaseActivityData"
local ShopItem = require "data.baseDatas.ShopItem"

local NewDCPassData = require("activities.Activity_NewDiamondChallenge.model.NewDCPassData")
local NewDCTaskSaleData = require("activities.Activity_NewDiamondChallenge.model.NewDCTaskSaleData")
local NewDCTaskMainData = require("activities.Activity_NewDiamondChallenge.model.NewDCTaskMainData")
local NewDCStoreData = require("activities.Activity_NewDiamondChallenge.model.NewDCStoreData")
local NewDCDiceGameData = require("activities.Activity_NewDiamondChallenge.model.DiceGame.NewDCDiceGameData")
local NewDCCoinGuessData = require("activities.Activity_NewDiamondChallenge.model.CoinGuessGame.NewDCCoinGuessData")
local NewDCPickGameData = require("activities.Activity_NewDiamondChallenge.model.PickGame.NewDCPickGameData")

local NewDChallengeData = class("NewDChallengeData", BaseActivityData)

--[[
    message LuckyChallengeV2 {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional LuckyChallengeV2Task task = 4;//任务
        repeated LuckyChallengeRefreshSale refreshSaleList = 5;//刷新促销
        optional LuckyChallengeV2Pass pass = 6;//pass
        optional LuckyChallengeV2Store store = 7;//商店
        repeated LuckyChallengeV2CoinGuess coinGuessList = 8;// 猜硬币小游戏
        repeated LuckyChallengeV2PickBonus pickBonusList = 9;// pick小游戏
        repeated LuckyChallengeV2DiceBonus diceBonusList = 10;// 股子小游戏
        optional int32 season = 11;//赛季
    }
]]
function NewDChallengeData:ctor()
    NewDChallengeData.super.ctor(self)
end

function NewDChallengeData:parseData(data)
    NewDChallengeData.super.parseData(self, data)
    --解析任务数据
    if data:HasField("task") then
        self:parseTask(data.task)
    end
    --解析任务促销数据
    if data.refreshSaleList and #data.refreshSaleList > 0 then
        self:parseTaskSale(data.refreshSaleList)
    end
    --解析奖励数据
    if data:HasField("pass") then
        self:parsePass(data.pass)
    end
    --解析商店数据
    if data:HasField("store") then
        self:parseStore(data.store)
        self:parseCoinGuessList(data.coinGuessList)
        self:parsePickBonusList(data.pickBonusList)
        self:parseDiceBonusList(data.diceBonusList)
        self.m_season = data.season
    end
end

function NewDChallengeData:parseTask(_data)
    self.m_task = NewDCTaskMainData:create()
    self.m_task:parseData(_data)
end

function NewDChallengeData:parseTaskSale(_data)
    self.m_taskSale = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local item = NewDCTaskSaleData:create()
            item:parseData(v)
            table.insert(self.m_taskSale,item)
        end
    end
end

function NewDChallengeData:parseSingleTaskData(data)
    if not data then
        return
    end
    if data.taskList then
        local mytask = self.m_task:getTaskList()
        if #data.taskList > 0 and #mytask > 0 then
            for i = 1, #data.taskList do
                local item = data.taskList[i]
                for k,v in ipairs(mytask) do
                    if item.process and item.index == v:getIndex() then
                        v:setProgress(item.process)
                        if v:getParam()[1] and tonumber(item.process[1]) >= tonumber(v:getParam()[1]) then
                            v:setCompleted()
                        end
                    end
                end
            end
        end
    end
end

function NewDChallengeData:parsePass(_data)
    if _data then
        if not self.m_pass then
            self.m_pass = NewDCPassData:create()
        end
        self.m_pass:parseData(_data)
    end
end

function NewDChallengeData:parseStore(_data)
    if _data then
        if not self.m_store then
            self.m_store = NewDCStoreData:create()
        end
        self.m_store:parseData(_data)
    end
end

-- 解析排行榜信息
function NewDChallengeData:parseRankConfig(_data)
    if not _data then
        return
    end

    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self:setRank(myRankConfigInfo.p_rank)
    end
end

-- 解析猜硬币小游戏
function NewDChallengeData:parseCoinGuessList(_data)
    self.p_coinGuessList = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local coinGuessData = NewDCCoinGuessData:create()
            coinGuessData:parseData(v)
            table.insert(self.p_coinGuessList, coinGuessData)
        end
    end
end

-- 解析pick小游戏
function NewDChallengeData:parsePickBonusList(_data)
    self.p_pickBonusList = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local pickData = NewDCPickGameData:create()
            pickData:parseData(v)
            local _lv = pickData:getLevel()
            self.p_pickBonusList["" .. _lv] = pickData
        end
    end
end

-- 解析股子小游戏
function NewDChallengeData:parseDiceBonusList(_data)
    self.p_diceBonusList = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local diceData = NewDCDiceGameData:create()
            diceData:parseData(v)
            table.insert(self.p_diceBonusList, diceData)
        end
    end
end

function NewDChallengeData:getTaskList()
    return self.m_task or {}
end

function NewDChallengeData:getTaskSaleList()
    return self.m_taskSale or {}
end

function NewDChallengeData:getPass()
    return self.m_pass or {}
end

function NewDChallengeData:getStore()
    return self.m_store or {}
end

function NewDChallengeData:getRankCfg()
    return self.p_rankCfg
end

function NewDChallengeData:getSeason()
    return self.m_season or 1
end

function NewDChallengeData:getCoinGuessList()
    return self.p_coinGuessList or {}
end

function NewDChallengeData:getPickBonusList()
    return self.p_pickBonusList or {}
end

function NewDChallengeData:getPickDataByLevelId(levelId)
    return self.p_pickBonusList["" .. levelId]
end

function NewDChallengeData:getDiceBonusList()
    return self.p_diceBonusList or {}
end

function NewDChallengeData:getDiceDataByLevelId(levelId)
    local diceBonusList = self:getDiceBonusList()
    for k, v in ipairs(diceBonusList) do
        if v:getLevel() == levelId then
            return v
        end
    end
    return nil
end

function NewDChallengeData:geCoinGuessDataByLevelId(levelId)
    local coinGuessList = self:getCoinGuessList()
    for k, v in ipairs(coinGuessList) do
        if v:getLevel() == levelId then
            return v
        end
    end
    return nil
end

function NewDChallengeData:getPlayingMiniGameData()
    local diceBonusList = self:getDiceBonusList()
    local coinGuessList = self:getCoinGuessList()
    local pickBonusList = self:getPickBonusList()
    for k, v in ipairs(diceBonusList) do
        if v:isPlayingStatus() then
            return v
        end
    end
    for k, v in ipairs(coinGuessList) do
        if v:isPlayingStatus() then
            return v
        end
    end
    for k, v in pairs(pickBonusList) do
        if v:isPlayingStatus() then
            return v
        end
    end
    return nil
end

--获取入口位置 1：左边，0：右边
function NewDChallengeData:getPositionBar()
    return 1
end

function NewDChallengeData:isOpen()
    return self:isRunning()
end

function NewDChallengeData:getTotal()
    return self.m_pass:getCurExp() or 0
end

return NewDChallengeData
