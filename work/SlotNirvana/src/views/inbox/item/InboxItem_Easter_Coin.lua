--[[
--]]

local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_Easter_Coin = class("InboxItem_Easter_Coin", InboxItem_cyberMonday)
function InboxItem_Easter_Coin:getCsbName()
    return "InBox/InboxItem_3Coupons_Easter_Coin.csb"
end

return InboxItem_Easter_Coin
