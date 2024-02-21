local NewCoinPusherPopStageCoinViewData = class("NewCoinPusherPopStageCoinViewData", util_require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function NewCoinPusherPopStageCoinViewData:ctor()
    NewCoinPusherPopStageCoinViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function NewCoinPusherPopStageCoinViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function NewCoinPusherPopStageCoinViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function NewCoinPusherPopStageCoinViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

function NewCoinPusherPopStageCoinViewData:getAddStageCoinPercent(baseCoins)
    local data = self:getActionData()
    local addCoins = data.rewardCoinsEnd - data.rewardCoinsStart
    local percent = addCoins / baseCoins * 100
    percent = math.floor(percent + 0.5000000001)
    return percent
end

function NewCoinPusherPopStageCoinViewData:getRewardCoinsEnd()
    local data = self:getActionData()
    return data.rewardCoinsEnd
end

function NewCoinPusherPopStageCoinViewData:getRewardCoinsPercent(baseCoins)
    local data = self:getActionData()
    local percent = (data.rewardCoinsEnd - baseCoins) / baseCoins * 100
    return percent
end

return NewCoinPusherPopStageCoinViewData
