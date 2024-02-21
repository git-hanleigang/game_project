-- Desc:    字独排行榜的邮件

local InboxItem_bingoRush_Rank = class("InboxItem_bingoRush_Rank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_bingoRush_Rank:getCsbName()
    return "InBox/InboxItem_bingoRush_rank.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_bingoRush_Rank:getCardSource()
    return {"Bingo Rush Rank Rewards"}
end
-- 描述说明
function InboxItem_bingoRush_Rank:getDescStr()
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

return InboxItem_bingoRush_Rank
