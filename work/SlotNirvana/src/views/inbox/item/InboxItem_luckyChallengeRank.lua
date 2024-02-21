
--[[
    author:JohnnyFred
    time:2019-11-08 15:39:42
    ]]

local InboxItem_luckyChallengeRank = class("InboxItem_luckyChallengeRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_luckyChallengeRank:getCsbName()
    return "InBox/InboxItem_DiamondChallenge_rank.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_luckyChallengeRank:getCardSource()
    return {"Diamond Challenge"}
end
-- 描述说明
function InboxItem_luckyChallengeRank:getDescStr()
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        --名次
        self.m_rankNum = extraData.rank
        local strRank = string.format("RANK %s REWARD",self.m_rankNum)
        return strRank
    end
    return "Diamond Challenge Ranking Rewards"
end

return  InboxItem_luckyChallengeRank
