local BaseActivityData = require "baseActivity.BaseActivityData"
local CoinExpandLoadingData = class("CoinExpandLoadingData", BaseActivityData)

function CoinExpandLoadingData:ctor()
    CoinExpandLoadingData.super.ctor(self)
    self.p_open = true
end

return CoinExpandLoadingData