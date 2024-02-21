--[[--
    集卡排行榜
]]
local InboxItem_CardRank = class("InboxItem_CardRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_CardRank:getCsbName()
    return "InBox/InboxItem_CardRankReward.csb"
end
-- 描述说明
function InboxItem_CardRank:getDescStr()
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
-- 如果有掉卡，在这里设置来源
function InboxItem_CardRank:getCardSource()
    return {"Card Rank Rewards"}
end

return InboxItem_CardRank
