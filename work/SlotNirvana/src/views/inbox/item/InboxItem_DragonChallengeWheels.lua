local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_DragonChallengeWheels = class("InboxItem_DragonChallengeWheels", InboxItem_base)

function InboxItem_DragonChallengeWheels:getCsbName()
    return "InBox/InboxItem_DragonChallenge.csb"
end

-- 描述说明
function InboxItem_DragonChallengeWheels:getDescStr()
    return self.m_mailData.title or ""
end

return InboxItem_DragonChallengeWheels
