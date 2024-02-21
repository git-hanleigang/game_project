local NewCoinPusherRunningData = class("NewCoinPusherRunningData")

function NewCoinPusherRunningData:ctor(  )
    self._RunningData = {}
end

function NewCoinPusherRunningData:getRunningData()
    return self._RunningData
end

--运行时数据赋值  从存档中取 或者 coinpusherData(getRuningData())中取 
function NewCoinPusherRunningData:setRunningData(data)
    self._RunningData = data
end

--目前进行章节
function NewCoinPusherRunningData:getStage(  )
    return self._RunningData.Stage
end

--第几个轮回
function NewCoinPusherRunningData:getRound(  )
    return self._RunningData.Round
end

--可push次数
function NewCoinPusherRunningData:getPushes(  )
    return self._RunningData.Pushes
end

function NewCoinPusherRunningData:setPushes(_nPushes)
    self._RunningData.Pushes = _nPushes
end

--最大可push次数
function NewCoinPusherRunningData:getMaxPushes(  )
    return self._RunningData.MaxPushes
end

--当前能量
function NewCoinPusherRunningData:getEnergy(  )
    return self._RunningData.Energy
end

--最大能量
function NewCoinPusherRunningData:getMaxEnergy(  )
    return self._RunningData.MaxEnergy
end

--本章节状态
function NewCoinPusherRunningData:getPlaneState(  )
    return self._RunningData.Status
end

function NewCoinPusherRunningData:getPlaneCoins(  )
    return self._RunningData.Coins
end

function NewCoinPusherRunningData:getPlaneBaseCoins(  )
    return self._RunningData.BaseCoins
end

function NewCoinPusherRunningData:getPlaneStageCoins(  )
    return self._RunningData.StageCoins
end

--自定义数据、
function NewCoinPusherRunningData:getPlaneData(  )
    return self._RunningData.Data
end

function NewCoinPusherRunningData:getPlaneScore(  )
    return self._RunningData.Score
end

function NewCoinPusherRunningData:getPlaneTargetScore(  )
    return self._RunningData.TargetScore
end

return NewCoinPusherRunningData