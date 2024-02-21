--[[--
    澳大利亚日商城优惠券：邮件
]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_AustraliaDay = class("InboxItem_AustraliaDay", InboxItem_cyberMonday)
function InboxItem_AustraliaDay:getCsbName()
    return "InBox/InboxItem_AustraliaDay_TwoCoupons.csb"
end

return InboxItem_AustraliaDay
