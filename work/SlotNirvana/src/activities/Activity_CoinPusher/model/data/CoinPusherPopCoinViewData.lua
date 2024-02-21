local CoinPusherPopCoinViewData = class("CoinPusherPopCoinViewData", util_require("activities.Activity_CoinPusher.model.data.CoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function CoinPusherPopCoinViewData:ctor()
    CoinPusherPopCoinViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function CoinPusherPopCoinViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function CoinPusherPopCoinViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function CoinPusherPopCoinViewData:getCoinsCount()
    local data = self:getActionData()
    return data.coins
end

function CoinPusherPopCoinViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

return CoinPusherPopCoinViewData
