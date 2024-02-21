--[[
    商店宣传2
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local HolidayStoreFinalDayData = class("HolidayStoreFinalDayData", BaseActivityData)

function HolidayStoreFinalDayData:ctor()
    HolidayStoreFinalDayData.super.ctor(self)
    self.p_open = true
end

return HolidayStoreFinalDayData