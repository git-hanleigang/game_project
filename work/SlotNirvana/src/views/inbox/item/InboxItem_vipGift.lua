
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_vipGift = class("InboxItem_vipGift",InboxItem_base)

function InboxItem_vipGift:getCsbName()
    return "InBox/InboxItem_VIP_Rewards.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_vipGift:getCardSource()
    return {"VIP Weekly Gifts"}
end
-- 描述说明
function InboxItem_vipGift:getDescStr()
    return "VIP WEEKLY GIFTS"
end

return InboxItem_vipGift