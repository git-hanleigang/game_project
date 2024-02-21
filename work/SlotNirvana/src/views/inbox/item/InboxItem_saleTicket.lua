--[[--
    4连折扣券
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_saleTicket = class("InboxItem_saleTicket", InboxItem_ticket)

function InboxItem_saleTicket:getCsbName()
    local csbName = "InBox/InboxItem_coupon.csb" --默认皮肤
    local item = globalData.GameConfig:getActivityConfigByRef("Activity_SaleTicket", ACTIVITY_TYPE.COMMON)
    if item then
        local inboxName =  item.p_inboxImage
        if inboxName ~= nil and inboxName ~= "" and  util_IsFileExist(inboxName) then
            csbName = inboxName
        end
    end
    return csbName
end

function InboxItem_saleTicket:collectMailSuccess()
    gLobalSendDataManager:getLogIap():setEnterOpen(nil,"rebatesOpen","InboxItem_saleTicket")
    gLobalSendDataManager:getLogIap():setEntryOrder(2)
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view,"btn_collect",DotUrlType.UrlName,false)
    end
end

return  InboxItem_saleTicket