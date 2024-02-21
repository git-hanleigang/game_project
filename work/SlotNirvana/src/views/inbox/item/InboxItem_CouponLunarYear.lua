--[[--
    春节优惠卷
]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_CouponLunarYear = class("InboxItem_CouponLunarYear", InboxItem_cyberMonday)

function InboxItem_CouponLunarYear:getCsbName()
    return "InBox/InboxItem_LunarYear_TwoCoupons.csb"
end

return InboxItem_CouponLunarYear