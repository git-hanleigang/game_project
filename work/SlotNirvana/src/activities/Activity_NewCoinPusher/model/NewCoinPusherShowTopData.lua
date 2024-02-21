local BaseActivityData = require("baseActivity.BaseActivityData")
local NewCoinPusherShowTopData = class("NewCoinPusherShowTopData", BaseActivityData)

function NewCoinPusherShowTopData:ctor()
    NewCoinPusherShowTopData.super.ctor(self)
    self.p_open = true
end

function NewCoinPusherShowTopData:parseNormalActivityData(_data)
    NewCoinPusherShowTopData.super.parseNormalActivityData(self,_data)
    -- self.p_openLevel = 20
end

return NewCoinPusherShowTopData