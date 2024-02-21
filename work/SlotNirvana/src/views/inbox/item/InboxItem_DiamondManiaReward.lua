local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_DiamondManiaReward = class("InboxItem_DiamondManiaReward", InboxItem_base)

function InboxItem_DiamondManiaReward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_DiamondManiaReward:getCardSource()
    return {"Diamond Mania"}
end
-- 描述说明
function InboxItem_DiamondManiaReward:getDescStr()
    return self.m_mailData.title or ""
end

return InboxItem_DiamondManiaReward
