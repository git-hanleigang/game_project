-- 新版新关挑战 邮件
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_PipeConnectRank = class("InboxItem_PipeConnectRank", InboxItem_base)

function InboxItem_PipeConnectRank:getCsbName()
    return "InBox/InboxItem_PipeConnect_Race.csb"
end

-- 描述说明
function InboxItem_PipeConnectRank:getDescStr()
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

function InboxItem_PipeConnectRank:getCardSource()
    return {"Pipe Connect Rank"}
end

return InboxItem_PipeConnectRank
