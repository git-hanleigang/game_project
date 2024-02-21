local BaseActivityData = require "baseActivity.BaseActivityData"
local CoinExpandPigData = class("CoinExpandPigData", BaseActivityData)

function CoinExpandPigData:ctor()
    CoinExpandPigData.super.ctor(self)
    self.p_open = true
end

return CoinExpandPigData