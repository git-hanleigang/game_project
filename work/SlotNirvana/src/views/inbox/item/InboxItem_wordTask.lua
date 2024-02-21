--[[
    活动任务邮件
]]

local InboxItem_wordTask = class("InboxItem_wordTask", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_wordTask:getCsbName( )
    return "InBox/InboxItem_wordTask.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_wordTask:getCardSource()
    return {"Word Mission"}
end
-- 描述说明
function InboxItem_wordTask:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_wordTask