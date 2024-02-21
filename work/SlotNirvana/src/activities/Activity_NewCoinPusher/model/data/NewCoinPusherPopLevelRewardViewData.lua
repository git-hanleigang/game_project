local NewCoinPusherPopLevelRewardViewData = class("NewCoinPusherPopLevelRewardViewData", util_require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function NewCoinPusherPopLevelRewardViewData:ctor()
    NewCoinPusherPopLevelRewardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function NewCoinPusherPopLevelRewardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function NewCoinPusherPopLevelRewardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function NewCoinPusherPopLevelRewardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end
-- function NewCoinPusherPopLevelRewardViewData:setStageData(data)
--     local data = self:getActionData()
--     data.stage = data
-- end

-- function NewCoinPusherPopLevelRewardViewData:setRoundData(data)
--     local data = self:getActionData()
--     data.round = data
-- end

return NewCoinPusherPopLevelRewardViewData
