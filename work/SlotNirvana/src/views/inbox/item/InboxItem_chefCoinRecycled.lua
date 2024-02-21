--[[
    老版餐厅厨师币兑换奖励邮件
]]
local InboxItem_chefCoinRecycled = class("InboxItem_chefCoinRecycled", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_chefCoinRecycled:getCsbName( )
    return "InBox/InboxItem_ChefCoinRecycled.csb"
end

-- 描述说明
function InboxItem_chefCoinRecycled:getDescStr()
    return "CHEF COINS RECYCLED"
end

return  InboxItem_chefCoinRecycled