local BaseActivityData = require("baseActivity.BaseActivityData")
local EgyptCoinPusherShowTopData = class("EgyptCoinPusherShowTopData", BaseActivityData)

function EgyptCoinPusherShowTopData:ctor()
    EgyptCoinPusherShowTopData.super.ctor(self)
    self.p_open = true
end

function EgyptCoinPusherShowTopData:parseNormalActivityData(_data)
    EgyptCoinPusherShowTopData.super.parseNormalActivityData(self,_data)
end

return EgyptCoinPusherShowTopData