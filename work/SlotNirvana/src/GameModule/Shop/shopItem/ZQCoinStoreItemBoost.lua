local ZQCoinStoreItemBoost = class("ZQCoinStoreItemBoost",util_require("base.BaseView"))

function ZQCoinStoreItemBoost:initUI()
    self:createCsbNode("Shop_Res/CoinStore_Boosted.csb")
end

return ZQCoinStoreItemBoost