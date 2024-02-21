--[[
    大富翁排行奖励
]]

local InboxItem_richMan_RankAward = class("InboxItem_richMan_RankAward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_richMan_RankAward:getCsbName()
    return "InBox/InboxItem_RichMan_RankAward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_richMan_RankAward:getCardSource()
    return {"Treasure Race Rank"}
end
-- 描述说明
function InboxItem_richMan_RankAward:getDescStr()
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        --名次
        self.m_rankNum = extraData.rank
        local strRank = string.format("RANK %s REWARD",self.m_rankNum)
        return strRank
    end
    return ""
end

return InboxItem_richMan_RankAward
