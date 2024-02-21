--[[
    装修排行奖励
]]

local InboxItem_redecorRank = class("InboxItem_redecorRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_redecorRank:getCsbName()
    return "InBox/InboxItem_redecorRank.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_redecorRank:getCardSource()
    return {"Redecorate Rank Rewards"}
end
-- 描述说明
function InboxItem_redecorRank:getDescStr()
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

return InboxItem_redecorRank
