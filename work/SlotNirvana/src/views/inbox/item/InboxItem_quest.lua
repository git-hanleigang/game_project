local InboxItem_quest = class("InboxItem_quest", util_require("views.inbox.item.InboxItem_baseReward"))

-- 如果有掉卡，在这里设置来源
function InboxItem_quest:getCardSource()
    return {"Quest Rewards"}
end
-- 描述说明
function InboxItem_quest:getDescStr()
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

function InboxItem_quest:getCsbName()
    local csbName = "InBox/InboxItem_quest.csb"
    return csbName
end

return InboxItem_quest
