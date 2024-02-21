--[[
    商店宣传1
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local HolidayStoreNewItemData = class("HolidayStoreNewItemData", BaseActivityData)

function HolidayStoreNewItemData:ctor()
    HolidayStoreNewItemData.super.ctor(self)
    self.p_open = true
end

return HolidayStoreNewItemData