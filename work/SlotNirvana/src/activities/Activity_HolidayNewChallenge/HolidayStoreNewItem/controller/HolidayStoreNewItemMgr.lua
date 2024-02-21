--[[
    商店宣传1
]]
local HolidayStoreNewItemMgr = class("HolidayStoreNewItemMgr", BaseActivityControl)

function HolidayStoreNewItemMgr:ctor()
    HolidayStoreNewItemMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidayStore_NewItem)
end

function HolidayStoreNewItemMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return HolidayStoreNewItemMgr
