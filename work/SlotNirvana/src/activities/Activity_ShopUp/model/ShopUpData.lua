--[[--
    FB加好友活动 数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ShopUpData = class("ShopUpData", BaseActivityData)

function ShopUpData:ctor()
    ShopUpData.super.ctor(self)
    self.p_open = true
end

return ShopUpData 