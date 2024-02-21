--[[
    推币机排行奖励
]]

local InboxItem_coinPusherRank = class("InboxItem_coinPusherRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_coinPusherRank:getCsbName( )
    return "InBox/InboxItem_CoinPusher.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_coinPusherRank:getCardSource()
    return {"CoinPusher Rank Reward"}
end
-- 描述说明
function InboxItem_coinPusherRank:getDescStr()
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

return  InboxItem_coinPusherRank