--[[
Author: cxcs
Date: 2021-08-09 11:21:20
LastEditTime: 2021-08-09 11:21:21
LastEditors: your name
Description: In User Settings Edit
FilePath: /SlotNirvana/src/views/inbox/InboxItem_deluxeExtraTimeReward.lua
--]]

local InboxItem_deluxeExtraTimeReward = class("InboxItem_deluxeExtraTimeReward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_deluxeExtraTimeReward:getCsbName()
    return "InBox/InboxItem_deluxeExtraTimeReward.csb"
end

-- 描述说明
function InboxItem_deluxeExtraTimeReward:getDescStr()
    return "EXCESSIVE TIME RECYCLED"
end

return  InboxItem_deluxeExtraTimeReward