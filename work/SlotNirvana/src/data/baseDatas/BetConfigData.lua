--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 17:52:13
--
local BetConfigData = class("BetConfigData")

BetConfigData.p_gameID = nil
BetConfigData.p_betId = nil
BetConfigData.p_totalBetValue = nil
BetConfigData.p_multiple = nil -- 倍数
BetConfigData.p_unlockAt = nil -- 解锁等级
BetConfigData.p_hideAt = nil -- 在多少级隐藏  , 如果未-1 ， 表明不會進行隱藏

BetConfigData.p_multipleExp = nil -- 增倍器升级经验

BetConfigData.p_unlockJackpot = nil -- 解锁的jackpot 档位标识， 具体各个关卡自己进行定义
BetConfigData.p_unlockFeature = nil -- 解锁的feature标识， 具体各个关卡自行定义

function BetConfigData:ctor()
end

function BetConfigData:parseData(data)
    self.p_betId = data.betId
    self.p_totalBetValue = tonumber(data.totalBet)
    self.p_multiple = data.multiple -- 倍数
    self.p_unlockAt = data.unlockAt -- 解锁等级
    self.p_hideAt = data.hideAt -- 在多少级隐藏

    self.p_unlockJackpot = data.jackpot -- 解锁的jackpot 档位标识， 具体各个关卡自己进行定义
    self.p_unlockFeature = data.unlockFeature --
    self.p_unlockFeature = data.unlockFeature --

    self.p_multipleExp = tonumber(data.multipleExp)

    self.p_gameID = data.gameId
    -- 关卡比赛分数
    if data.arenaScores and #data.arenaScores > 0 then
        self.p_arenaScores = data.arenaScores
    end

    -- 红蓝对决
    if data.factionFightScore then
        self.p_factionFightScore = tonumber(data.factionFightScore)
    end

    self.p_balloonRushScores = {}
    if data.betPoints ~= nil and #data.betPoints > 0 then
        for i, data in ipairs(data.betPoints) do
            local score_data = {}
            score_data.iconNum = data.iconNum
            score_data.point = data.point
            table.insert(self.p_balloonRushScores, score_data)
        end
    end
end

function BetConfigData:getLeagueScores()
    return self.p_arenaScores
end

function BetConfigData:getFactionFightScore()
    return self.p_factionFightScore
end

return BetConfigData
