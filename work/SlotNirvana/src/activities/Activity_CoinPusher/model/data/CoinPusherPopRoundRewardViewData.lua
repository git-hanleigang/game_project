local CoinPusherPopRoundRewardViewData = class("CoinPusherPopRoundRewardViewData", util_require("activities.Activity_CoinPusher.model.data.CoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function CoinPusherPopRoundRewardViewData:ctor()
    CoinPusherPopRoundRewardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function CoinPusherPopRoundRewardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function CoinPusherPopRoundRewardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function CoinPusherPopRoundRewardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

return CoinPusherPopRoundRewardViewData
