local EgyptCoinPusherPopStageCoinViewData = class("EgyptCoinPusherPopStageCoinViewData", util_require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function EgyptCoinPusherPopStageCoinViewData:ctor()
    EgyptCoinPusherPopStageCoinViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function EgyptCoinPusherPopStageCoinViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function EgyptCoinPusherPopStageCoinViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function EgyptCoinPusherPopStageCoinViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

function EgyptCoinPusherPopStageCoinViewData:getAddStageCoinPercent(baseCoins)
    local data = self:getActionData()
    local addCoins = tonumber(data.rewardCoinsEnd) - tonumber(data.rewardCoinsStart)
    local bCoins = clone(baseCoins)
    if iskindof(baseCoins, "LongNumber") then
        bCoins = tonumber(baseCoins.lNum)
    end
    local percent = addCoins * 100 / bCoins
    percent = math.floor(percent + 0.5)
    return percent
end

function EgyptCoinPusherPopStageCoinViewData:getRewardCoinsEnd()
    local data = self:getActionData()
    return data.rewardCoinsEnd
end

return EgyptCoinPusherPopStageCoinViewData
