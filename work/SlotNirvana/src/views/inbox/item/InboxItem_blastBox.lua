-- blast 排行榜结算邮件

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_blastBox = class("InboxItem_blastBox", InboxItem_base)

function InboxItem_blastBox:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 如果有掉卡，在这里设置来源
function InboxItem_blastBox:getCardSource()
    return {"Blast Play"}
end

function InboxItem_blastBox:getDescStr()
    local extra = self.m_mailData.title
    return extra
end

return InboxItem_blastBox
