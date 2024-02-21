--[[
]]
local BaseInboxGroup = util_require("views.inbox.group.BaseInboxGroup")
local InboxGroup_coupon = class("InboxGroup_coupon", BaseInboxGroup)

function InboxGroup_coupon:getCsbName()
    return "InBox/Group/InboxGroup_Coupon.csb"
end

return InboxGroup_coupon