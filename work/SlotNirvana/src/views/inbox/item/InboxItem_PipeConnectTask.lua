-- 新版新关挑战 邮件
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_PipeConnectTask = class("InboxItem_PipeConnectTask", InboxItem_base)

function InboxItem_PipeConnectTask:getCsbName()
    return "InBox/InboxItem_PipeConnect.csb"
end

-- 描述说明
function InboxItem_PipeConnectTask:getDescStr()
    return "PIPE CONNECT MISSION REWARDS"
end

function InboxItem_PipeConnectTask:getCardSource()
    return {"Pipe Connect Mission"}
end

return InboxItem_PipeConnectTask
