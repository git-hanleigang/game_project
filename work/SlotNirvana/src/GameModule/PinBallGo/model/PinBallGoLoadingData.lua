
local BaseActivityData = require "baseActivity.BaseActivityData"
local PinBallGoLoadingData = class("PinBallGoLoadingData", BaseActivityData)

function PinBallGoLoadingData:ctor()
    PinBallGoLoadingData.super.ctor(self)
    self.p_open = true
end

return PinBallGoLoadingData