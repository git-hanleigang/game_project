--[[--
    钻石商城送优惠券活动邮件
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_shopGemCoupon = class("InboxItem_shopGemCoupon", InboxItem_ticket)
function InboxItem_shopGemCoupon:getCsbName()
    return "InBox/InboxItem_ShopGemCoupon.csb"
end

--重写打开商城
function InboxItem_shopGemCoupon:openShop()
    G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
end


return InboxItem_shopGemCoupon
