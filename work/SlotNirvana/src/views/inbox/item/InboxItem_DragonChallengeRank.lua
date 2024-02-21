--[[
    组队boss排行奖励
]]

local InboxItem_DragonChallengeRank = class("InboxItem_DragonChallengeRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_DragonChallengeRank:getCsbName( )
    return "InBox/InboxItem_DragonChallenge.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_DragonChallengeRank:getCardSource()
    return {"Dragon Challenge Rank"}
end
-- 描述说明
function InboxItem_DragonChallengeRank:getDescStr()
    return self.m_mailData.title or ""
end

return  InboxItem_DragonChallengeRank