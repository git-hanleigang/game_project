--[[
    author:JohnnyFred
    time:2019-11-08 15:39:42
]]
local InboxItem_bingoRank = class("InboxItem_bingoRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_bingoRank:getCsbName()
    return "InBox/InboxItem_bingoRank.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_bingoRank:getCardSource()
    return {"Bingo Rewards"}
end
-- 描述说明
function InboxItem_bingoRank:getDescStr()
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

return  InboxItem_bingoRank