local CoinPusherPopLevelRewardViewData = class("CoinPusherPopLevelRewardViewData", util_require("activities.Activity_CoinPusher.model.data.CoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function CoinPusherPopLevelRewardViewData:ctor()
    CoinPusherPopLevelRewardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function CoinPusherPopLevelRewardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function CoinPusherPopLevelRewardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function CoinPusherPopLevelRewardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end
-- function CoinPusherPopLevelRewardViewData:setStageData(data)
--     local data = self:getActionData()
--     data.stage = data
-- end

-- function CoinPusherPopLevelRewardViewData:setRoundData(data)
--     local data = self:getActionData()
--     data.round = data
-- end

return CoinPusherPopLevelRewardViewData
