--[[
    装修活动任务邮件
]]

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_redecorTask = class("InboxItem_redecorTask", InboxItem_base)

function InboxItem_redecorTask:getCsbName()
    local csbName = "InBox/InboxItem_redecorTask.csb"
    return csbName
end
-- 如果有掉卡，在这里设置来源
function InboxItem_redecorTask:getCardSource()
    return {"Redecorate Mission"}
end
-- 描述说明
function InboxItem_redecorTask:getDescStr()
    return "HERE'S YOUR REWARD"
end

return InboxItem_redecorTask
