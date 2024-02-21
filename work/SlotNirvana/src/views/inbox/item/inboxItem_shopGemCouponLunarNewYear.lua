--[[--
    钻石商城送优惠券活动邮件
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local inboxItem_shopGemCouponLunarNewYear = class("inboxItem_shopGemCouponLunarNewYear", InboxItem_ticket)
function inboxItem_shopGemCouponLunarNewYear:getCsbName()
    return "InBox/InboxItem_LunarNewYear_ShopGemCoupon.csb"
end

--重写打开商城
function inboxItem_shopGemCouponLunarNewYear:openShop()
    G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
end

--重写活动监听
function inboxItem_shopGemCouponLunarNewYear:onEnter()
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

function inboxItem_shopGemCouponLunarNewYear:onExit()
    inboxItem_shopGemCouponLunarNewYear.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return inboxItem_shopGemCouponLunarNewYear
