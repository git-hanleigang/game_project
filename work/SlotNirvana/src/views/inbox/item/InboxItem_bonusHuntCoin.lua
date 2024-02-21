--[[
    author:JohnnyFred
    time:2019-11-08 15:39:42
]]

local InboxItem_bonusHuntCoin = class("InboxItem_bonusHuntCoin", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_bonusHuntCoin:getCsbName( )
    return "InBox/InboxItem_BonusHuntCoin.csb"
end

-- 描述说明
function InboxItem_bonusHuntCoin:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_bonusHuntCoin