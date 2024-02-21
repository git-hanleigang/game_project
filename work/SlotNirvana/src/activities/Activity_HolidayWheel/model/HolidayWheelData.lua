local BaseActivityData = require("baseActivity.BaseActivityData")
local HolidayWheelData = class("HolidayWheelData", BaseActivityData)

function HolidayWheelData:ctor(_data)
    HolidayWheelData.super.ctor(self,_data)
    self.p_open = true
end

return HolidayWheelData
