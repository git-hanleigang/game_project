local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_GetMorePayLessReward = class("InboxItem_GetMorePayLessReward", InboxItem_base)

function InboxItem_GetMorePayLessReward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_GetMorePayLessReward:getCardSource()
    return {"Get More Pay Less"}
end
-- 描述说明
function InboxItem_GetMorePayLessReward:getDescStr()
    return self.m_mailData.title or ""
end

return InboxItem_GetMorePayLessReward
