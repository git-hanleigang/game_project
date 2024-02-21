local BaseActivityData = require("baseActivity.BaseActivityData")
local CoinPusherShowTopData = class("CoinPusherShowTopData", BaseActivityData)

function CoinPusherShowTopData:ctor()
    CoinPusherShowTopData.super.ctor(self)
    self.p_open = true
end

function CoinPusherShowTopData:parseNormalActivityData(_data)
    CoinPusherShowTopData.super.parseNormalActivityData(self,_data)
    -- self.p_openLevel = 20
end

return CoinPusherShowTopData