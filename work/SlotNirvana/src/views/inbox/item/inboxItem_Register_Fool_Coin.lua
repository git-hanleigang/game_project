--[[--
    愚人节签到优惠卷
]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local inboxItem_Register_Fool_Coin = class("inboxItem_Register_Fool_Coin", InboxItem_cyberMonday)

function inboxItem_Register_Fool_Coin:getCsbName()
    return "InBox/InboxItem_Fool_Coin_Coupon.csb"
end

return inboxItem_Register_Fool_Coin