--[[
Author: dhs
Date: 2022-02-22 12:13:50
LastEditTime: 2022-02-22 12:13:51
LastEditors: your name
Description: 商城优惠券圣帕特里克主题邮件
FilePath: /SlotNirvana/src/views/inbox/InboxItem_Patrick.lua
--]]
local InboxItem_cyberMonday = util_require("views.inbox.item.InboxItem_cyberMonday")
local InboxItem_Patrick = class("InboxItem_Patrick", InboxItem_cyberMonday)
function InboxItem_Patrick:getCsbName()
    return "InBox/InboxItem_TwoCoupons_Patrick.csb"
end

return InboxItem_Patrick
