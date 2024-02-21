local NewCoinPusherPopRoundRewardViewData = class("NewCoinPusherPopRoundRewardViewData", util_require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function NewCoinPusherPopRoundRewardViewData:ctor()
    NewCoinPusherPopRoundRewardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function NewCoinPusherPopRoundRewardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function NewCoinPusherPopRoundRewardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function NewCoinPusherPopRoundRewardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

return NewCoinPusherPopRoundRewardViewData
