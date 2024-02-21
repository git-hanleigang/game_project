--[[--
    愚人节签到钻石商城送优惠券活动邮件
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local inboxItem_Register_Fool_Gem = class("inboxItem_Register_Fool_Gem", InboxItem_ticket)
function inboxItem_Register_Fool_Gem:getCsbName()
    return "InBox/InboxItem_Fool_Gem_Coupon.csb"
end

--重写打开商城
function inboxItem_Register_Fool_Gem:openShop()
    G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
end

--重写活动监听
function inboxItem_Register_Fool_Gem:onEnter()
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

function inboxItem_Register_Fool_Gem:onExit()
    inboxItem_Register_Fool_Gem.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return inboxItem_Register_Fool_Gem
