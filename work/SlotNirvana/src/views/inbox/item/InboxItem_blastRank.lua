-- blast 排行榜结算邮件

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_blastRank = class("InboxItem_blastRank", InboxItem_base)

-- 如果有掉卡，在这里设置来源
function InboxItem_blastRank:getCardSource()
    return {"Blast Rank Rewards"}
end
-- 描述说明
function InboxItem_blastRank:getDescStr()
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

function InboxItem_blastRank:getCsbName()
    local csbName = "InBox/InboxItem_Blast.csb"
    return csbName
end

return InboxItem_blastRank
