--[[

]]

local InboxItem_duckShotReward = class("InboxItem_duckShotReward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_duckShotReward:getCsbName( )
    return "InBox/InboxItem_duckShotReward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_duckShotReward:getCardSource()
    return {"Duck Shot"}
end
-- 描述说明
function InboxItem_duckShotReward:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_duckShotReward