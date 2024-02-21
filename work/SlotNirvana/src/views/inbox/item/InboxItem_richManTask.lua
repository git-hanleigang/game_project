--[[
    活动任务邮件
]]
local InboxItem_richManTask = class("InboxItem_richManTask", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_richManTask:getCsbName()
    return "InBox/InboxItem_richManTask.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_richManTask:getCardSource()
    return {"Treasure Race Mission"}
end
-- 描述说明
function InboxItem_richManTask:getDescStr()
    return "HERE'S YOUR REWARD"
end

return InboxItem_richManTask
