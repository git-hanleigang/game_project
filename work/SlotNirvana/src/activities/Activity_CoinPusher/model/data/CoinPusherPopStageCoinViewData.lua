local CoinPusherPopStageCoinViewData = class("CoinPusherPopStageCoinViewData", util_require("activities.Activity_CoinPusher.model.data.CoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function CoinPusherPopStageCoinViewData:ctor()
    CoinPusherPopStageCoinViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function CoinPusherPopStageCoinViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function CoinPusherPopStageCoinViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function CoinPusherPopStageCoinViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

function CoinPusherPopStageCoinViewData:getAddStageCoinPercent(baseCoins)
    local data = self:getActionData()
    local addCoins = data.rewardCoinsEnd - data.rewardCoinsStart
    local percent = addCoins / baseCoins * 100
    percent = math.floor(percent + 0.5000000001)
    return percent
end

function CoinPusherPopStageCoinViewData:getRewardCoinsEnd()
    local data = self:getActionData()
    return data.rewardCoinsEnd
end

function CoinPusherPopStageCoinViewData:getRewardCoinsPercent(baseCoins)
    local data = self:getActionData()
    local percent = (data.rewardCoinsEnd - baseCoins) / baseCoins * 100
    return percent
end

return CoinPusherPopStageCoinViewData
