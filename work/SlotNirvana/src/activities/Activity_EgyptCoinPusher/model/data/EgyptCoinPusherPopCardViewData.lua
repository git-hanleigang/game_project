local EgyptCoinPusherPopCardViewData = class("EgyptCoinPusherPopCardViewData", util_require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function EgyptCoinPusherPopCardViewData:ctor()
    EgyptCoinPusherPopCardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function EgyptCoinPusherPopCardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function EgyptCoinPusherPopCardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function EgyptCoinPusherPopCardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

function EgyptCoinPusherPopCardViewData:getDropCardData()
    local data = self:getActionData()
    return data.cardDrops
end
return EgyptCoinPusherPopCardViewData
