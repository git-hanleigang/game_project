local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_PrizeGameReward = class("InboxItem_PrizeGameReward", InboxItem_base)

function InboxItem_PrizeGameReward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_PrizeGameReward:getCardSource()
    return {""}
end
-- 描述说明
function InboxItem_PrizeGameReward:getDescStr()
    return self.m_mailData.title or ""
end

return InboxItem_PrizeGameReward
