--[[
]]

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")

local InboxItem_PaintExchange = class("InboxItem_PaintExchange",InboxItem_base)

function InboxItem_PaintExchange:getCsbName()
    return "InBox/InboxItem_Coloring.csb"
end
-- 描述说明
function InboxItem_PaintExchange:getDescStr()
    return "WILD CHALLENGE REWARD"
end

return InboxItem_PaintExchange