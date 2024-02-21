local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_DragonChallengeTeam = class("InboxItem_DragonChallengeTeam", InboxItem_base)

function InboxItem_DragonChallengeTeam:getCsbName()
    return "InBox/InboxItem_DragonChallenge.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_DragonChallengeTeam:getCardSource()
    return {"Dragon Challenge Rewards"}
end
-- 描述说明
function InboxItem_DragonChallengeTeam:getDescStr()
    return self.m_mailData.title or ""
end

return InboxItem_DragonChallengeTeam
