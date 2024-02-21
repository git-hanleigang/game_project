--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:25:44
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/model/TrillionChallengeModel.lua
Description: 亿万赢钱挑战 数据
--]]
local BaseGameModel = util_require("GameBase.BaseGameModel")
local TrillionChallengeModel = class("TrillionChallengeModel", BaseGameModel)
local TrillionChallengeTaskData = util_require("GameModule.TrillionChallenge.model.TrillionChallengeTaskData")
local TrillionChallengeRankUser =  util_require("GameModule.TrillionChallenge.model.TrillionChallengeRankUser")
local TrillionChallengeRankReward =  util_require("GameModule.TrillionChallenge.model.TrillionChallengeRankReward")

function TrillionChallengeModel:parseData(_data)
    if not _data then
        return
    end

    self._expireAt = tonumber(_data.expireAt) or 0 -- 结束时间
    self._curTotalWin = tonumber(_data.totalWin) or 0 -- 累计赢钱
    -- self._rankUp = _data.rankUp or 0 -- 排行榜排名上升的幅度
    self._rank = _data.rank or 0 -- 排行榜排名
    self.p_openLevel = _data.displayLevel or 0 -- 显示等级
    self._unlockWin = tonumber(_data.unlockWin) or 0 -- 排行榜解锁赢钱
    self._rankSelf = TrillionChallengeRankUser:create({
        points = self._curTotalWin,
        rank = self._rank,
        udid = globalData.userRunData.userUdid
    })

    -- 任务
    self:parseTaskData(_data.tasks or {})
end

-- 任务 数据
function TrillionChallengeModel:parseTaskData(_list)
    self._taskList = {}

    for _, _task in ipairs(_list) do
        local taskData = TrillionChallengeTaskData:create(_task)
        table.insert(self._taskList, taskData)
    end
end

-- 排行榜数据
function TrillionChallengeModel:parseRankData(_rankInfo)
    -- 个人排名信息
    self._rankSelf = TrillionChallengeRankUser:create(_rankInfo.myRank or {})
    -- 排名列表
    self._rankList = {}
    self._bInRank = false -- 玩家是否在 排行列表里
    for i,v in ipairs(_rankInfo.rankUsers or {}) do
        local rankData = TrillionChallengeRankUser:create(v or {})
        if rankData:checkIsMe() then
            self._bInRank = true -- 玩家是否在 排行列表里
        end
        table.insert(self._rankList, rankData)
    end
    table.sort(self._rankList, function(_a, _b)
        return _a:getRank() < _b:getRank()
    end)
    -- 排名奖励
    self._rankRewardList = {}
    for k,v in pairs(_rankInfo.rewards or {}) do
        local rewardData = TrillionChallengeRankReward:create(v)
        table.insert(self._rankRewardList, rewardData)
    end
    -- 奖池金币
    self._prizePool = tonumber(_rankInfo.prizePool) or 0
end

function TrillionChallengeModel:getExpireAt()
    return (self._expireAt or 0) * 0.001
end
function TrillionChallengeModel:setCurTotalWin(_value)
    self._curTotalWin = tonumber(_value) or 0
    self._rankSelf:setCurTotalWin(self._curTotalWin)
end
function TrillionChallengeModel:getCurTotalWin()
    return self._curTotalWin or 0
end
function TrillionChallengeModel:setRankUp(_rankUp)
    self._rankUp = tonumber(_rankUp) or 0
end
function TrillionChallengeModel:getRankUp()
    return self._rankUp or 0
end
function TrillionChallengeModel:setRank(_rank)
    local preRank = self:getCurRank()
    self._rank = tonumber(_rank) or 0
    self._rankSelf:setRank(self._rank)
    if preRank == 0 then
        self:setRankUp(self._rank - preRank)
    else
        self:setRankUp(preRank - self._rank)
    end
end
function TrillionChallengeModel:getCurRank()
    return self._rank or 0
end
function TrillionChallengeModel:getUnlockRankWin()
    return self._unlockWin or 0
end
function TrillionChallengeModel:getTaskList()
    return self._taskList or {}
end
function TrillionChallengeModel:getTaskDataByOrder(_taskOrder)
    local taskList = self:getTaskList()
    for i, v in pairs(self._taskList) do
        if v:getTaskOrder() == _taskOrder then
            return v
        end
    end
    return nil
end
function TrillionChallengeModel:getPrizePool()
    return self._prizePool or 0
end
function TrillionChallengeModel:getRankList()
    return self._rankList or {}
end
function TrillionChallengeModel:checkSelfInRankList()
    return self._bInRank
end
function TrillionChallengeModel:getRankSelf()
    return self._rankSelf
end
function TrillionChallengeModel:isRunning()
    if globalData.userRunData.levelNum < self:getOpenLevel() then
        return false
    end

    local curTime = util_getCurrnetTime()
    return curTime <= math.floor(self:getExpireAt())
end

function TrillionChallengeModel:getRankRewardByRank(_rank)
    if not self._rankRewardList or #self._rankRewardList <= 0 then
        return
    end

    local rewardData
    for k,v in pairs(self._rankRewardList) do
        if v:checkRankIn(_rank) then
            rewardData = v
            break
        end
    end

    return rewardData
end

-- 获取存储 大奖上涨的 key
function TrillionChallengeModel:getSaveGrandPrizeKey()
    return "TrillionChallengGrandPrizeKey_"
end

return TrillionChallengeModel