-- Desc:    字独排行榜的邮件

local InboxItem_word_Rank = class("InboxItem_word_Rank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_word_Rank:getCsbName()
    return "InBox/InboxItem_Word.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_word_Rank:getCardSource()
    return {"Word Rank Rewards"}
end
-- 描述说明
function InboxItem_word_Rank:getDescStr()
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

return InboxItem_word_Rank
