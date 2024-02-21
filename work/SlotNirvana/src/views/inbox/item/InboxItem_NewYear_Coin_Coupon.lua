--[[--
    新年签到优惠卷
]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_NewYear_Coin_Coupon = class("InboxItem_NewYear_Coin_Coupon", InboxItem_cyberMonday)

function InboxItem_NewYear_Coin_Coupon:getCsbName()
    return "InBox/InboxItem_NewYear2022_Coin_Coupon.csb"
end

return InboxItem_NewYear_Coin_Coupon