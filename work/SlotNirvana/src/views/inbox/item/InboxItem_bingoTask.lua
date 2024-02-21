--[[
    活动任务邮件
]]

local InboxItem_bingoTask = class("InboxItem_bingoTask", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_bingoTask:getCsbName( )
    return "InBox/InboxItem_bingoTask.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_bingoTask:getCardSource()
    return {"Bingo Mission"}
end
-- 描述说明
function InboxItem_bingoTask:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_bingoTask