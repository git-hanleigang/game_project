--[[
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_Easter_Piggy = class("InboxItem_Easter_Piggy", InboxItem_ticket)

function InboxItem_Easter_Piggy:getCsbName()
    return "InBox/InboxItem_3Coupons_Easter_Piggy.csb"
end

--重写打开商城
function InboxItem_Easter_Piggy:openShop()
    G_GetMgr(G_REF.PiggyBank):showMainLayer()
end

function InboxItem_Easter_Piggy:onExit()
    InboxItem_Easter_Piggy.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_Easter_Piggy
