
--[[
    author:JohnnyFred
    time:2019-11-08 15:39:42
]]

local InboxItem_luckyChallengeCoins = class("InboxItem_luckyChallengeCoins", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_luckyChallengeCoins:getCsbName()
    return "InBox/InboxItem_DiamondChallenge_rewards.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_luckyChallengeCoins:getCardSource()
    return {"Diamond Challenge"}
end
-- 描述说明
function InboxItem_luckyChallengeCoins:getDescStr()
    return "Diamond Chanllenge Rewards"
end

return  InboxItem_luckyChallengeCoins