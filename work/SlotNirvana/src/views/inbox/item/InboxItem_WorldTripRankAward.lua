-- 新版大富翁排行榜奖励结算邮件

local InboxItem_WorldTripRankAward = class("InboxItem_WorldTripRankAward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_WorldTripRankAward:getCsbName()
    return "InBox/InboxItem_WorldTripRank.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_WorldTripRankAward:getCardSource()
    return {"World Trip Rank"}
end
-- 描述说明
function InboxItem_WorldTripRankAward:getDescStr()
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        --名次
        self.m_rankNum = extraData.rank
        local strRank = string.format("RANK %s REWARD", self.m_rankNum)
        return strRank
    end
    return ""
end

return InboxItem_WorldTripRankAward
