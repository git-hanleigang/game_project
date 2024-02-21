local CoinPusherPopCardViewData = class("CoinPusherPopCardViewData", util_require("activities.Activity_CoinPusher.model.data.CoinPusherBaseActionData"))
local TAG_EVENT = "PopView"

function CoinPusherPopCardViewData:ctor()
    CoinPusherPopCardViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function CoinPusherPopCardViewData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function CoinPusherPopCardViewData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function CoinPusherPopCardViewData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

function CoinPusherPopCardViewData:getDropCardData()
    local data = self:getActionData()
    return data.cardDrops
end
return CoinPusherPopCardViewData
