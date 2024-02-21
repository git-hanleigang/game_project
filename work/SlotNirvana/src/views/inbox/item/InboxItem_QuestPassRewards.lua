--[[
    quest pass未领取奖励
]]

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_QuestPassRewards = class("InboxItem_QuestPassRewards", InboxItem_base)

function InboxItem_QuestPassRewards:getCsbName()
    local csbName = "InBox/InboxItem_questPass.csb"
    return csbName
end
-- 如果有掉卡，在这里设置来源
function InboxItem_QuestPassRewards:getCardSource()
    return {"Quest Pass"}
end
-- 描述说明
function InboxItem_QuestPassRewards:getDescStr()
    return "QUEST PASS REWARDS"
end

return InboxItem_QuestPassRewards
