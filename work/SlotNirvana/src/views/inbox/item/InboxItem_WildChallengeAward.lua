local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_WildChallengeAward = class("InboxItem_WildChallengeAward", InboxItem_base)

function InboxItem_WildChallengeAward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_WildChallengeAward:getCardSource()
    return {"Wild Challenge Reward"}
end
-- 描述说明
function InboxItem_WildChallengeAward:getDescStr()
    return "WILD CHALLENGE REWARD"
end

return InboxItem_WildChallengeAward
