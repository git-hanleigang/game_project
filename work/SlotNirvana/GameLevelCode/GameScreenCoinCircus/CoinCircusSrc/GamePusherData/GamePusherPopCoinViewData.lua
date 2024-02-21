local GamePusherPopCoinViewData = class("GamePusherPopCoinViewData", util_require("CoinCircusSrc.GamePusherData.GamePusherBaseActionData"))
local TAG_EVENT = "PopView"

function GamePusherPopCoinViewData:ctor(  )
    GamePusherPopCoinViewData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function GamePusherPopCoinViewData:setActionData(data)
    self.m_tRunningData.ActionData = data

    --初始弹窗状态
    -- local extraActionStates = self:getExtraActionState()
    -- extraActionStates[TAG_EVENT] = self.m_pConfig.PlayState.IDLE
end

-- --设置弹窗状态
-- function GamePusherPopCoinViewData:setPopViewActionState(state)
--    local extraActionStates = self:getExtraActionState()
--    extraActionStates[TAG_EVENT] = state
-- end

function GamePusherPopCoinViewData:getCoinsCount()
    local data = self:getActionData()
    return data.coins
end

-- function GamePusherPopCoinViewData:getPopViewState()
--    local extraActionStates = self:getExtraActionState()
--    return extraActionStates[TAG_EVENT]
-- end

return GamePusherPopCoinViewData