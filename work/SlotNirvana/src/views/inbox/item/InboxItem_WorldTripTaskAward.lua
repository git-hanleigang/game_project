-- 新版大富翁活动任务奖励结算邮件

local InboxItem_WorldTripTaskAward = class("InboxItem_WorldTripTaskAward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_WorldTripTaskAward:getCsbName()
    return "InBox/InboxItem_WorldTripTask.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_WorldTripTaskAward:getCardSource()
    return {"World Trip Mission"}
end
-- 描述说明
function InboxItem_WorldTripTaskAward:getDescStr()
    return "HERE'S YOUR REWARD"
end

return InboxItem_WorldTripTaskAward
