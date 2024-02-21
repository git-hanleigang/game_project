local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_GemChallengeReward = class("InboxItem_GemChallengeReward", InboxItem_base)

function InboxItem_GemChallengeReward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_GemChallengeReward:getCardSource()
    return {"Land Of Gem"}
end
-- 描述说明
function InboxItem_GemChallengeReward:getDescStr()
    return self.m_mailData.title or ""
end

return InboxItem_GemChallengeReward
