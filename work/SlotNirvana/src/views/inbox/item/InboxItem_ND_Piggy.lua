--[[
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_ND_Piggy = class("InboxItem_ND_Piggy", InboxItem_ticket)

function InboxItem_ND_Piggy:getCsbName()
    return "InBox/InboxItem_NiceDice_Piggy_Coupon.csb"
end

--重写打开商城
function InboxItem_ND_Piggy:openShop()
    G_GetMgr(G_REF.PiggyBank):showMainLayer()
end

function InboxItem_ND_Piggy:onExit()
    InboxItem_ND_Piggy.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_ND_Piggy
