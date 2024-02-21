local EgyptCoinPusherPopLevelRewardViewData = class("EgyptCoinPusherPopLevelRewardViewData", util_require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function EgyptCoinPusherPopLevelRewardViewData:ctor()
    EgyptCoinPusherPopLevelRewardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function EgyptCoinPusherPopLevelRewardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function EgyptCoinPusherPopLevelRewardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function EgyptCoinPusherPopLevelRewardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end
-- function EgyptCoinPusherPopLevelRewardViewData:setStageData(data)
--     local data = self:getActionData()
--     data.stage = data
-- end

-- function EgyptCoinPusherPopLevelRewardViewData:setRoundData(data)
--     local data = self:getActionData()
--     data.round = data
-- end

return EgyptCoinPusherPopLevelRewardViewData
