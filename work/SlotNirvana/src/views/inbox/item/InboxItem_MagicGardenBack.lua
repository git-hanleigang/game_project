--[[
    合成转盘
--]]
local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_MagicGardenBack = class("InboxItem_MagicGardenBack", InboxItem_baseReward)

function InboxItem_MagicGardenBack:getCsbName()
    return "InBox/InboxItem_MagicGarden.csb"
end

-- 描述说明
function InboxItem_MagicGardenBack:getDescStr()
    return self.m_mailData.title
end

return InboxItem_MagicGardenBack