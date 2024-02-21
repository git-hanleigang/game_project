local BaseActivityData = require "baseActivity.BaseActivityData"
local CoinExpandStoreData = class("CoinExpandStoreData", BaseActivityData)

function CoinExpandStoreData:ctor()
    CoinExpandStoreData.super.ctor(self)
    self.p_open = true
end

return CoinExpandStoreData