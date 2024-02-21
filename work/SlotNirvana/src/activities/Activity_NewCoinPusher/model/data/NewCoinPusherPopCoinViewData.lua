local NewCoinPusherPopCoinViewData = class("NewCoinPusherPopCoinViewData", util_require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function NewCoinPusherPopCoinViewData:ctor()
    NewCoinPusherPopCoinViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function NewCoinPusherPopCoinViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function NewCoinPusherPopCoinViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function NewCoinPusherPopCoinViewData:getCoinsCount()
    local data = self:getActionData()
    return data.coins
end

function NewCoinPusherPopCoinViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

return NewCoinPusherPopCoinViewData
