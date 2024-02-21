--[[--
    新年签到钻石商城送优惠券活动邮件
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_NewYear_Gem_Coupon = class("InboxItem_NewYear_Gem_Coupon", InboxItem_ticket)
function InboxItem_NewYear_Gem_Coupon:getCsbName()
    return "InBox/InboxItem_NewYear2022_Gem_Coupon.csb"
end

--重写打开商城
function InboxItem_NewYear_Gem_Coupon:openShop()
    G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
end

--重写活动监听
function InboxItem_NewYear_Gem_Coupon:onEnter()
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

function InboxItem_NewYear_Gem_Coupon:onExit()
    InboxItem_NewYear_Gem_Coupon.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_NewYear_Gem_Coupon
