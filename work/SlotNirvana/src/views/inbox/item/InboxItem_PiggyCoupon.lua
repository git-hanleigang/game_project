--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-15 16:57:49
    describe:小猪优惠券
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_PiggyCoupon = class("InboxItem_PiggyCoupon", InboxItem_ticket)
function InboxItem_PiggyCoupon:getCsbName()
    return "InBox/InboxItem_PiggyCoupon.csb"
end

function InboxItem_PiggyCoupon:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.CyberMonday then
                if not tolua.isnull(self) and self.hideTicket then
                    self:hideTicket()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function InboxItem_PiggyCoupon:openShop()
    G_GetMgr(G_REF.PiggyBank):showMainLayer()
end

function InboxItem_PiggyCoupon:onExit()
    InboxItem_PiggyCoupon.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_PiggyCoupon
