-- 新版新关挑战 邮件
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_SlotTrials = class("InboxItem_SlotTrials", InboxItem_base)

function InboxItem_SlotTrials:getCsbName()
    return "InBox/InboxItem_SlotTrialsReward.csb"
end

-- 描述说明
function InboxItem_SlotTrials:getDescStr()
    return "Slot Trials"
end

function InboxItem_SlotTrials:getCardSource()
    return {"Slot Trials"}
end

return InboxItem_SlotTrials
