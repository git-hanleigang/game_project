--[[
    大活动pass促销接水管
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_FunctionSalePassPipe = class("InboxItem_FunctionSalePassPipe", InboxItem_base)

function InboxItem_FunctionSalePassPipe:getCsbName()
    return "InBox/InboxItem_PipePass.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_FunctionSalePassPipe:getCardSource()
    return {"Pipe Pass"}
end

-- 描述说明
function InboxItem_FunctionSalePassPipe:getDescStr()
    return self.m_mailData.title or "Pipe pass reward"
end

return InboxItem_FunctionSalePassPipe
