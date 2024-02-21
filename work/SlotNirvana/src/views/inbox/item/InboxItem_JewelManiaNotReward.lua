--[[
    挖矿邮件  没有领奖的
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_JewelManiaNotReward = class("InboxItem_JewelManiaNotReward", InboxItem_base)

function InboxItem_JewelManiaNotReward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_JewelManiaNotReward:getCardSource()
    return {
        "Jewel Mania",
        "Jewel Mania Level 6"
    }
end

-- 描述说明
function InboxItem_JewelManiaNotReward:getDescStr()
    return "Jewel Mania Uncollected Rewards"
end

return InboxItem_JewelManiaNotReward
