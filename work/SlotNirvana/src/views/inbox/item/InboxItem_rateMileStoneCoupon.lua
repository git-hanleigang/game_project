--[[--
    剁手星期一折扣券
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_rateMileStoneCoupon = class("InboxItem_rateMileStoneCoupon", InboxItem_ticket)
function InboxItem_rateMileStoneCoupon:getCsbName()
    return "InBox/InboxItem_Rate_MileStoneCoupon.csb"
end

function InboxItem_rateMileStoneCoupon:updateCustomUI()
    local config = globalData.itemsConfig:getCommonTicket(self.m_mailData.ticketId)
    if config.p_icon and config.p_icon ~= "" then
        local icons = string.split(config.p_icon, "_")
        local lb_rate = self:findChild("m_lb_rate")
        if lb_rate then
            lb_rate:setString(icons[2] or "100")
            self:updateLabelSize({label = lb_rate, sx = 0.88, sy = 0.98}, 145)
        end
    end
end

function InboxItem_rateMileStoneCoupon:collectMailSuccess()
    gLobalSendDataManager:getLogIap():setEnterOpen(nil, "rebatesOpen", "InboxItem_rateMileStoneCoupon")
    gLobalSendDataManager:getLogIap():setEntryOrder(2)
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_collect", DotUrlType.UrlName, false)
    end
end

function InboxItem_rateMileStoneCoupon:onExit()
    InboxItem_rateMileStoneCoupon.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_rateMileStoneCoupon
