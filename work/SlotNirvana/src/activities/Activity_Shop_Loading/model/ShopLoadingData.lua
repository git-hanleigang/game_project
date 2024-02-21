--[[--
    空壳促销弹板活动
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ShopLoadingData = class("ShopLoadingData", BaseActivityData)
function ShopLoadingData:ctor()
    ShopLoadingData.super.ctor(self)
    self.p_open = true
end
return ShopLoadingData
