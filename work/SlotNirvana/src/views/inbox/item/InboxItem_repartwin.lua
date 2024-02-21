---
--island
--2019年3月14日
--InboxItem_repartwin.lua

local InboxItem_repartwin = class("InboxItem_repartwin", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_repartwin:getCsbName()
    return "InBox/InboxItem_repartwin.csb"
end

-- 描述说明
function InboxItem_repartwin:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_repartwin