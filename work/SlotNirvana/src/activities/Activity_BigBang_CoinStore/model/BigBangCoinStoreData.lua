--[[
    膨胀宣传 金币商店
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BigBangCoinStoreData = class("BigBangCoinStoreData", BaseActivityData)

function BigBangCoinStoreData:ctor()
    BigBangCoinStoreData.super.ctor(self)
    self.p_open = true
end

return BigBangCoinStoreData