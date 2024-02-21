--[[
    集卡赛季末聚合结束补发邮件奖励
]]

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_ChaseForChips = class("InboxItem_ChaseForChips", InboxItem_base)

function InboxItem_ChaseForChips:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 描述说明
function InboxItem_ChaseForChips:getDescStr()
    return self.m_mailData.title or "CHASE FOR CHIPS"
end

function InboxItem_ChaseForChips:getCardSource()
    return {"Chase For Chips"}
end

return  InboxItem_ChaseForChips