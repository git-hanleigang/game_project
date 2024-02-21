local BaseActivityData = require "baseActivity.BaseActivityData"
local CoinExpandCashBonusData = class("CoinExpandCashBonusData", BaseActivityData)

function CoinExpandCashBonusData:ctor()
    CoinExpandCashBonusData.super.ctor(self)
    self.p_open = true
end

return CoinExpandCashBonusData