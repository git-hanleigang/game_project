--[[
    合成转盘
--]]
local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_MagicGardenReward = class("InboxItem_MagicGardenReward", InboxItem_baseReward)

function InboxItem_MagicGardenReward:getCsbName()
    return "InBox/InboxItem_MagicGarden.csb"
end

-- 描述说明
function InboxItem_MagicGardenReward:getDescStr()
    return self.m_mailData.title
end

return InboxItem_MagicGardenReward