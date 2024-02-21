--[[
    组队打boss pass邮件
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_DragonChallengePass = class("InboxItem_DragonChallengePass", InboxItem_base)

function InboxItem_DragonChallengePass:getCsbName()
    return "InBox/InboxItem_DragonChallenge.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_DragonChallengePass:getCardSource()
    return {"Dragon Challenge Pass"}
end

-- 描述说明
function InboxItem_DragonChallengePass:getDescStr()
    return self.m_mailData.title or "HERE'S YOUR REWARD"
end

return InboxItem_DragonChallengePass
