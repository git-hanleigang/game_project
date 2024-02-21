local EgyptCoinPusherRunningData = class("EgyptCoinPusherRunningData")

function EgyptCoinPusherRunningData:ctor()
    self._RunningData = {}
end

function EgyptCoinPusherRunningData:getRunningData()
    return self._RunningData
end

--运行时数据赋值  从存档中取 或者 coinpusherData(getRuningData())中取
function EgyptCoinPusherRunningData:setRunningData(data)
    self._RunningData = data
end

--目前进行章节
function EgyptCoinPusherRunningData:getStage()
    return self._RunningData.Stage
end

--第几个轮回
function EgyptCoinPusherRunningData:getRound()
    return self._RunningData.Round
end

--可push次数
function EgyptCoinPusherRunningData:getPushes()
    return self._RunningData.Pushes
end

function EgyptCoinPusherRunningData:setPushes(_nPushes)
    self._RunningData.Pushes = _nPushes
end

--最大可push次数
function EgyptCoinPusherRunningData:getMaxPushes()
    return self._RunningData.MaxPushes
end

--当前能量
function EgyptCoinPusherRunningData:getEnergy()
    return self._RunningData.Energy
end

--最大能量
function EgyptCoinPusherRunningData:getMaxEnergy()
    return self._RunningData.MaxEnergy
end

--本章节状态
function EgyptCoinPusherRunningData:getPlaneState()
    return self._RunningData.Status
end

function EgyptCoinPusherRunningData:getPlaneCoins()
    if type(self._RunningData.Coins) == "number" then
        return toLongNumber(self._RunningData.Coins)
    elseif type(self._RunningData.Coins) == "table" then
        if self._RunningData.Coins.lNum then
            return toLongNumber(self._RunningData.Coins.lNum)
        else
            return toLongNumber(0) -- 数据有问题了
        end
    elseif iskindof(self._RunningData.Coins, "LongNumber") then
        return self._RunningData.Coins
    end
    return toLongNumber(0)
end

function EgyptCoinPusherRunningData:getPlaneBaseCoins()
    if type(self._RunningData.BaseCoins) == "number" then
        return toLongNumber(self._RunningData.BaseCoins)
    elseif type(self._RunningData.BaseCoins) == "table" then
        if self._RunningData.BaseCoins.lNum then
            return toLongNumber(self._RunningData.BaseCoins.lNum)
        else
            return toLongNumber(0) -- 数据有问题了
        end
    elseif iskindof(self._RunningData.BaseCoins, "LongNumber") then
        return self._RunningData.BaseCoins
    end
    return toLongNumber(0)
end

function EgyptCoinPusherRunningData:getPlaneStageCoins()
    return self._RunningData.StageCoins
end

--自定义数据、
function EgyptCoinPusherRunningData:getPlaneData()
    return self._RunningData.Data
end

function EgyptCoinPusherRunningData:getPlaneScore()
    return self._RunningData.Score
end

function EgyptCoinPusherRunningData:getPlaneTargetScore()
    return self._RunningData.TargetScore
end

function EgyptCoinPusherRunningData:getPlaneSpinTimes()
    return self._RunningData.SpinTimes or 0
end

return EgyptCoinPusherRunningData
