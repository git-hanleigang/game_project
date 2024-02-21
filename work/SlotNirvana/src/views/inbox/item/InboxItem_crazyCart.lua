--[[
    des: 邮件疯狂购物车
    author:{author}
]]
local InboxItem_crazyCart = class("InboxItem_crazyCart", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_crazyCart:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 描述说明
function InboxItem_crazyCart:getDescStr()
    return "NEW YEAR’S COUNTDOWN GIFT"
end

-- 如果有掉卡，在这里设置来源
function InboxItem_crazyCart:getCardSource()
    return {"Crazy Shopping Cart"}
end

return  InboxItem_crazyCart