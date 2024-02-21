--[[
    des: 邮件中卡牌
    author:{author}
    time:2019-09-03 16:04:12
]]
local InboxItem_cardLink = class("InboxItem_cardLink", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_cardLink:getCsbName()
    return "InBox/InboxItem_cardLink.csb"
end

-- 描述说明
function InboxItem_cardLink:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_cardLink