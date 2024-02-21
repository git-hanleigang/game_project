--[[--
    注册里程碑
]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_MileStoneCoupon_Register = class("InboxItem_MileStoneCoupon_Register", InboxItem_cyberMonday)
function InboxItem_MileStoneCoupon_Register:getCsbName()
    return "InBox/InboxItem_Register_MileStoneCoupon.csb"
end

return InboxItem_MileStoneCoupon_Register