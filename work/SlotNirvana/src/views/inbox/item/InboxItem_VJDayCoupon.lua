--[[
    Description: 剁手星期一折扣券: 对日战争胜利日
    FilePath: /SlotNirvana/src/views/inbox/InboxItem_VJDayCoupon.lua
--]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_VJDayCoupon = class("InboxItem_VJDayCoupon", InboxItem_cyberMonday)
function InboxItem_VJDayCoupon:getCsbName()
    return "InBox/InboxItem_VJDayCoupon.csb"
end

return InboxItem_VJDayCoupon
