--[[
    刮刮卡邮件
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_ScratchCards = class("InboxItem_ScratchCards", InboxItem_base)

function InboxItem_ScratchCards:getCsbName()
    return "InBox/InboxItem_ScratchCrads.csb"
end

-- 描述说明
function InboxItem_ScratchCards:getDescStr()
    return "SCRATCH FOR REWARDS!"
end

function InboxItem_ScratchCards:initView()
    InboxItem_ScratchCards.super.initView(self)
    self:findChild("node_reward"):setVisible(false)
    self:findChild("label_num"):setString("x" .. self.m_mailData.m_num)
end

-- -- 结束时间(单位：秒)
-- function InboxItem_ScratchCards:getExpireTime()
--     -- inx:索引刮刮卡对应档位信息
--     local inx = self.m_mailData.m_index
--     local data = G_GetMgr(ACTIVITY_REF.ScratchCards):getData()
--     if data then
--         local gearPurchase = data:getGearPurchaseByIndex(inx, "inbox")
--         if gearPurchase then
--             local expireTime = gearPurchase.expirationTime or 0
--             return math.max(math.floor(expireTime / 1000), 0)
--         else
--             return 0
--         end
--     else
--         return 0
--     end
-- end

function InboxItem_ScratchCards:clickFunc(sender)
    -- 判断资源是否下载
    if not G_GetMgr(ACTIVITY_REF.ScratchCards):isDownloadRes() then
        return
    end

    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        local inx = self.m_mailData.m_index
        G_GetMgr(ACTIVITY_REF.ScratchCards):showOperationMainLayer(inx, "inbox")
        self:closeInbox()
    end
end

function InboxItem_ScratchCards:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

return InboxItem_ScratchCards
