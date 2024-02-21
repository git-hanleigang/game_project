--[[
    红蓝对决排行奖励
]]
local InboxItem_FactionFightRank = class("InboxItem_FactionFightRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_FactionFightRank:getCsbName()
    return "InBox/InboxItem_FactionFightRankReward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_FactionFightRank:getCardSource()
    return {"Faction Fight"}
end
-- 描述说明
function InboxItem_FactionFightRank:getDescStr()
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

return  InboxItem_FactionFightRank