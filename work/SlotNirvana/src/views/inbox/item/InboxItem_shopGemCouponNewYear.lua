--[[--
    钻石商城送优惠券活动邮件
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_shopGemCouponNewYear = class("InboxItem_shopGemCouponNewYear", InboxItem_ticket)
function InboxItem_shopGemCouponNewYear:getCsbName()
    return "InBox/InboxItem_NewYear2022_ShopGemCoupon.csb"
end

--重写打开商城
function InboxItem_shopGemCouponNewYear:openShop()
    G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
end

--重写活动监听
function InboxItem_shopGemCouponNewYear:onEnter()
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

function InboxItem_shopGemCouponNewYear:onExit()
    InboxItem_shopGemCouponNewYear.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_shopGemCouponNewYear
