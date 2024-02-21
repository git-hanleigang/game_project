--[[--
    剁手星期一折扣券:复活节主题
]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_easterDay = class("InboxItem_presidentDay", InboxItem_cyberMonday)
function InboxItem_easterDay:getCsbName()
    return "InBox/InboxItem_EasterDay.csb"
end

return InboxItem_easterDay