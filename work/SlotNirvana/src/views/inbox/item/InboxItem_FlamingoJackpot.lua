--[[
    flamingo jackpot 补发邮件
]]

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_FlamingoJackpot = class("InboxItem_FlamingoJackpot", InboxItem_base)

function InboxItem_FlamingoJackpot:getCsbName()
    return "InBox/InboxItem_FlamingoJackpot.csb"
end

-- 描述说明
function InboxItem_FlamingoJackpot:getDescStr()
    return self.m_mailData.title or "FLAMINGO JACKPOT REWARD"
end

function InboxItem_FlamingoJackpot:getCardSource()
    return {"Flamingo Jackpot Reward"}
end

return  InboxItem_FlamingoJackpot