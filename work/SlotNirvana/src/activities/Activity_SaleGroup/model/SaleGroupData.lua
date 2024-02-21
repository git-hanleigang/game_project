--[[--
    空壳促销弹板活动
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local SaleGroupData = class("SaleGroupData", BaseActivityData)
function SaleGroupData:ctor()
    -- 
    SaleGroupData.super.ctor(self)
    self.p_open = true
end
return SaleGroupData
