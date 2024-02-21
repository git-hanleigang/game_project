--[[--
    情人节商城优惠券
]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_coupons_Valentine2022 = class("InboxItem_coupons_Valentine2022", InboxItem_cyberMonday)
function InboxItem_coupons_Valentine2022:getCsbName()
    return "InBox/Valentine2022/InboxItem_TwoCoupons_Valentine2022.csb"
end

return InboxItem_coupons_Valentine2022