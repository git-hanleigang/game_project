--[[
    自选任务
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_PickTask = class("InboxItem_PickTask", InboxItem_base)

function InboxItem_PickTask:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_PickTask:getCardSource()
    return {"Optional Task"}
end
-- 描述说明
function InboxItem_PickTask:getDescStr()
    return "ADVENTURE WITH ALICE REWARD"
end

return InboxItem_PickTask
