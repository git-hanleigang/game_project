--[[--
    空壳促销弹板活动
    -- 母亲节促销弹板
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local SaleGroupMothersDayData = class("SaleGroupMothersDayData", BaseActivityData)
function SaleGroupMothersDayData:ctor()
    -- 
    SaleGroupMothersDayData.super.ctor(self)
    self.p_open = true
end
return SaleGroupMothersDayData
