-- 新版新关挑战 邮件
local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_MegaWinReward = class("InboxItem_MegaWinReward", InboxItem_baseReward)

function InboxItem_MegaWinReward:getCsbName()
    return "InBox/InboxItem_MegaWinParty.csb"
end

-- 描述说明
function InboxItem_MegaWinReward:getDescStr()
    return self.m_mailData.title or "Power Jar Rewards"
end

function InboxItem_MegaWinReward:getCardSource()
    return {"Power Jar Rewards"} 
end

return InboxItem_MegaWinReward
