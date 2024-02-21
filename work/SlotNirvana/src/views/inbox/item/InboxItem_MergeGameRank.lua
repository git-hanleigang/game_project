--
-- Author:zhangkankan
-- Date: 2021-09-06 14:30:45
--

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_MergeGameRank = class("InboxItem_MergeGameRank", InboxItem_base)

function InboxItem_MergeGameRank:getCsbName( )
    return "InBox/InboxItem_mergeRank.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_MergeGameRank:getCardSource()
    return {"HighLimitMerge Rank Rewards", "Merge Rank Rewards"}
end
-- 描述说明
function InboxItem_MergeGameRank:getDescStr()
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

return InboxItem_MergeGameRank

