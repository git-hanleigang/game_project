--[[--
    调查问卷
]]
local InboxItem_YearEndSummary = class("InboxItem_YearEndSummary", util_require("views.inbox.item.InboxItem_baseNoReward"))

function InboxItem_YearEndSummary:getCsbName()
    return "InBox/InboxItem_YearEndSummary.csb"
end
-- 描述说明
function InboxItem_YearEndSummary:getDescStr()
    return self.m_mailData.title or "Click to see your 2023 annual summary!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_YearEndSummary:getExpireTime()
--     local Data = G_GetActivityDataByRef(ACTIVITY_REF.YearEndSummary)
--     if Data then
--         return tonumber(Data:getExpireAt())
--     else
--         return 0
--     end
-- end

function InboxItem_YearEndSummary:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_inbox" then
        G_GetMgr(ACTIVITY_REF.YearEndSummary):showPopByEmail()
    end
end

function InboxItem_YearEndSummary:onEnter()
    InboxItem_YearEndSummary.super.onEnter(self)
end

return InboxItem_YearEndSummary
