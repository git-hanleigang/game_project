local BaseActivityData = require "baseActivity.BaseActivityData"
local CoinExpandStartData = class("CoinExpandStartData", BaseActivityData)

function CoinExpandStartData:ctor()
    CoinExpandStartData.super.ctor(self)
    self.p_open = true
end

return CoinExpandStartData