local GamePusherCoinsRainData = class("GamePusherCoinsRainData", util_require("CandyPusherSrc.GamePusherData.GamePusherBaseActionData"))

function GamePusherCoinsRainData:setLastCoinsNum( _num )
    if _num < 0 then
        _num = 0
    end
    self.m_tRunningData.ActionData.CoinsTotalNum = _num
end

function GamePusherCoinsRainData:getLastCoinsNum( )
    return self.m_tRunningData.ActionData.CoinsTotalNum or 0
end

return GamePusherCoinsRainData