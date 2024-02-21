--[[
    回归签到pass补发邮件
]]

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_ReturnPassReward = class("InboxItem_ReturnPassReward", InboxItem_base)

function InboxItem_ReturnPassReward:getCsbName()
    return "InBox/InboxItem_returnPass.csb"
end

-- 描述说明
function InboxItem_ReturnPassReward:getDescStr()
    return self.m_mailData.title or "BLACK PASS REWARD"
end

function InboxItem_ReturnPassReward:getCardSource()
    return {"Return Pass Reward"}
end

return  InboxItem_ReturnPassReward