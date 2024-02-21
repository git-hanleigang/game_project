--[[--
    剁手星期一折扣券
]]
local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_cyberMonday = class("InboxItem_cyberMonday", InboxItem_ticket)
function InboxItem_cyberMonday:getCsbName()
    return "InBox/InboxItem_CyberMonday.csb"
end

function InboxItem_cyberMonday:collectMailSuccess()
    gLobalSendDataManager:getLogIap():setEnterOpen(nil,"rebatesOpen","InboxItem_cyberMonday")
    gLobalSendDataManager:getLogIap():setEntryOrder(2)
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view,"btn_collect",DotUrlType.UrlName,false)
    end
end


return InboxItem_cyberMonday