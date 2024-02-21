--[[
    活动任务邮件
]]
local InboxItem_coinPusher_Task = class("InboxItem_coinPusher_Task", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_coinPusher_Task:getCsbName( )
    return "InBox/InboxItem_pusherTask.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_coinPusher_Task:getCardSource()
    return {"Coin Pusher Mission"}
end
-- 描述说明
function InboxItem_coinPusher_Task:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_coinPusher_Task