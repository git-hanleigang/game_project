local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_LuckyRace = class("InboxItem_LuckyRace", InboxItem_base)

function InboxItem_LuckyRace:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 描述说明
function InboxItem_LuckyRace:getDescStr()
    return self.m_mailData.title or "LUCKY RACE REWARDS"
end

return InboxItem_LuckyRace