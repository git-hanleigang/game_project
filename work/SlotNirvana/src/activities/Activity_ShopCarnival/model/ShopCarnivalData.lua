--[[--
    商城膨胀弹板活动
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ShopCarnivalData = class("ShopCarnivalData", BaseActivityData)

function ShopCarnivalData:ctor()
    ShopCarnivalData.super.ctor(self)
    self.p_open = true

    self.m_factor = 3
end

function ShopCarnivalData:getFactor()
    return math.max(self.m_factor or 1, 1)
end

return ShopCarnivalData
