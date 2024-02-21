local CoinPusherDropCoinData = class("CoinPusherDropCoinData", util_require("activities.Activity_CoinPusher.model.data.CoinPusherBaseActionData"))
local TAG_EVENT = "DropCoins"

function CoinPusherDropCoinData:ctor()
    CoinPusherDropCoinData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function CoinPusherDropCoinData:setActionData(data)
    self._RunningData.ActionData = data

    --初始化掉金币状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

function CoinPusherDropCoinData:setCoinActionState(state)
    --初始化掉金币状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function CoinPusherDropCoinData:getDropCoinState()
    --初始化掉金币状态
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

function CoinPusherDropCoinData:reduceCoinsCount(coinType)
    local actionData = self:getActionData()
    local coinsData = actionData[1]
    local bNotDrop = false

    for k, v in pairs(coinsData) do
        if k == coinType and v > 0 then
            coinsData[k] = v - 1
        end
        if v > 0 then
            bNotDrop = true
        end
    end
    --全部都create了 掉金币状态置为Done
    if not bNotDrop then
        self:setCoinActionState(self._Config.PlayState.DONE)
    end
end

return CoinPusherDropCoinData
