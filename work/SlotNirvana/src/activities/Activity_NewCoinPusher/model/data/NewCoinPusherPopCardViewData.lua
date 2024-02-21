local NewCoinPusherPopCardViewData = class("NewCoinPusherPopCardViewData", util_require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function NewCoinPusherPopCardViewData:ctor()
    NewCoinPusherPopCardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function NewCoinPusherPopCardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function NewCoinPusherPopCardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function NewCoinPusherPopCardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

function NewCoinPusherPopCardViewData:getDropCardData()
    local data = self:getActionData()
    return data.cardDrops
end
return NewCoinPusherPopCardViewData
