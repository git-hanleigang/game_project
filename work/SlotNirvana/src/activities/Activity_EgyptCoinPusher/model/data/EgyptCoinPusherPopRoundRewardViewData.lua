local EgyptCoinPusherPopRoundRewardViewData = class("EgyptCoinPusherPopRoundRewardViewData", util_require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function EgyptCoinPusherPopRoundRewardViewData:ctor()
    EgyptCoinPusherPopRoundRewardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function EgyptCoinPusherPopRoundRewardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function EgyptCoinPusherPopRoundRewardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function EgyptCoinPusherPopRoundRewardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

return EgyptCoinPusherPopRoundRewardViewData
