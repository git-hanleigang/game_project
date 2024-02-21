--[[
--]]

local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_ND_Coin = class("InboxItem_ND_Coin", InboxItem_cyberMonday)
function InboxItem_ND_Coin:getCsbName()
    return "InBox/InboxItem_NiceDice_Coin_Coupon.csb"
end

return InboxItem_ND_Coin
