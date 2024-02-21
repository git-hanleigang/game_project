
--[[
    author:JohnnyFred
    time:2019-11-08 15:39:42
    ]]

local InboxItem_luckyChallengeRush = class("InboxItem_luckyChallengeRush", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_luckyChallengeRush:getCsbName()
    return "InBox/InboxItem_DiamondChallenge_rush.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_luckyChallengeRush:getCardSource()
    return {"Diamond Rush"}
end
-- 描述说明
function InboxItem_luckyChallengeRush:getDescStr()
    return "Diamond Rush Rewards"
end

return  InboxItem_luckyChallengeRush
