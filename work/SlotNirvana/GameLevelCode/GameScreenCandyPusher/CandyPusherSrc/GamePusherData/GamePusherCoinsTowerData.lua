local GamePusherCoinsTowerData = class("GamePusherCoinsTowerData", util_require("CandyPusherSrc.GamePusherData.GamePusherBaseActionData"))

function GamePusherCoinsTowerData:setAnimateStates( _state )
    self.m_tRunningData.ActionData.AnimateStates = _state
end

function GamePusherCoinsTowerData:getAnimateStates( )
    return self.m_tRunningData.ActionData.AnimateStates or 0
end

return GamePusherCoinsTowerData