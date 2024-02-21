--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-02-08 19:37:45
    2022总统日商城优惠券
]]

local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_President22 = class("InboxItem_President22", InboxItem_cyberMonday)
function InboxItem_President22:getCsbName()
    return "InBox/InboxItem_President22_TwoCoupons.csb"
end

return InboxItem_President22
