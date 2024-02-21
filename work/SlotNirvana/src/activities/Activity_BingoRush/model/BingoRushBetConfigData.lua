
local BingoRushBetConfigData = class("BingoRushBetConfigData", require "data.baseDatas.MachineData")

function BingoRushBetConfigData:parseData(data)
    
    self.p_betId = data.betId
    self.p_totalBetValue = tonumber(data.totalBet)
    self.p_multiple = 1 -- 倍数
    self.p_unlockAt = -1 -- 解锁等级
    self.p_hideAt = -1 -- 在多少级隐藏

    self.p_unlockJackpot = -1 -- 解锁的jackpot 档位标识， 具体各个关卡自己进行定义
    self.p_unlockFeature = -1 --
    self.p_unlockFeature = -1 --

    self.p_multipleExp = tonumber(0)

    self.p_gameID = -1
    -- 关卡比赛分数
    self.p_arenaScores = 0
end

return BingoRushBetConfigData
