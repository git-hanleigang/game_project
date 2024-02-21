--[[
    付费排行榜邮件
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_PayRank = class("InboxItem_PayRank", InboxItem_base)

function InboxItem_PayRank:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_PayRank:getCardSource()
    return {
        "Grand Finale" -- 赛季末返新卡
    }
end
-- 描述说明
function InboxItem_PayRank:getDescStr()    
    return self.m_mailData.title or ""
end

function InboxItem_PayRank:collectMailSuccess()
    local extra = self.m_mailData.extra
    local extraData = util_cjsonDecode(extra)
    local rank = extraData.rank or 4
    local layer = util_createFindView("InBox/PayRank/PayRankReward", self.m_coins, rank)
    gLobalViewManager:showUI(layer, ViewZorder.ZORDER_UI)

    self:removeSelfItem()
end

return InboxItem_PayRank
