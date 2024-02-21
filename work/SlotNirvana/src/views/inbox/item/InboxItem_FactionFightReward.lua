--[[
    红蓝对决个人奖励
]]
local InboxItem_FactionFightReward = class("InboxItem_FactionFightReward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_FactionFightReward:getCsbName()
    return "InBox/InboxItem_FactionFightProgressReward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_FactionFightReward:getCardSource()
    return {"Faction Fight"}
end
-- 描述说明
function InboxItem_FactionFightReward:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_FactionFightReward