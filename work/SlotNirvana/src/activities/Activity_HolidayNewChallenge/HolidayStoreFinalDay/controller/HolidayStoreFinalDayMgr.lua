--[[
    商店宣传2
]]
local HolidayStoreFinalDayMgr = class("HolidayStoreFinalDayMgr", BaseActivityControl)

function HolidayStoreFinalDayMgr:ctor()
    HolidayStoreFinalDayMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidayStore_FinalDay)
end

function HolidayStoreFinalDayMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return HolidayStoreFinalDayMgr
