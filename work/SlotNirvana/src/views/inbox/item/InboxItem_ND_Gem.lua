--[[--
    
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_ND_Gem = class("InboxItem_ND_Gem", InboxItem_ticket)
function InboxItem_ND_Gem:getCsbName()
    return "InBox/InboxItem_NiceDice_Gem_Coupon.csb"
end

--重写打开商城
function InboxItem_ND_Gem:openShop()
    G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
end

--重写活动监听
function InboxItem_ND_Gem:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.ShopGemCoupon then
                if not tolua.isnull(self) and self.hideTicket then
                    self:hideTicket()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function InboxItem_ND_Gem:onExit()
    InboxItem_ND_Gem.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_ND_Gem
