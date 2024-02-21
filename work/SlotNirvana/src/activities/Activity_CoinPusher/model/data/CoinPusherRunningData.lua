local CoinPusherRunningData = class("CoinPusherRunningData")

function CoinPusherRunningData:ctor(  )
    self._RunningData = {}
end

function CoinPusherRunningData:getRunningData()
    return self._RunningData
end

--运行时数据赋值  从存档中取 或者 coinpusherData(getRuningData())中取 
function CoinPusherRunningData:setRunningData(data)
    self._RunningData = data
end

--目前进行章节
function CoinPusherRunningData:getStage(  )
    return self._RunningData.Stage
end

--第几个轮回
function CoinPusherRunningData:getRound(  )
    return self._RunningData.Round
end

--可push次数
function CoinPusherRunningData:getPushes(  )
    return self._RunningData.Pushes
end

function CoinPusherRunningData:setPushes(_nPushes)
    self._RunningData.Pushes = _nPushes
end

--最大可push次数
function CoinPusherRunningData:getMaxPushes(  )
    return self._RunningData.MaxPushes
end

--当前能量
function CoinPusherRunningData:getEnergy(  )
    return self._RunningData.Energy
end

--最大能量
function CoinPusherRunningData:getMaxEnergy(  )
    return self._RunningData.MaxEnergy
end

--本章节状态
function CoinPusherRunningData:getPlaneState(  )
    return self._RunningData.Status
end

function CoinPusherRunningData:getPlaneCoins(  )
    return self._RunningData.Coins
end

function CoinPusherRunningData:getPlaneBaseCoins(  )
    return self._RunningData.BaseCoins
end

function CoinPusherRunningData:getPlaneStageCoins(  )
    return self._RunningData.StageCoins
end

--自定义数据、
function CoinPusherRunningData:getPlaneData(  )
    return self._RunningData.Data
end

function CoinPusherRunningData:getPlaneScore(  )
    return self._RunningData.Score
end

function CoinPusherRunningData:getPlaneTargetScore(  )
    return self._RunningData.TargetScore
end

return CoinPusherRunningData