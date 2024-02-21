--[[--
    
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_Easter_Gem = class("InboxItem_Easter_Gem", InboxItem_ticket)
function InboxItem_Easter_Gem:getCsbName()
    return "InBox/InboxItem_3Coupons_Easter_Gem.csb"
end

--重写打开商城
function InboxItem_Easter_Gem:openShop()
    G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
end

--重写活动监听
function InboxItem_Easter_Gem:onEnter()
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

function InboxItem_Easter_Gem:onExit()
    InboxItem_Easter_Gem.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_Easter_Gem
