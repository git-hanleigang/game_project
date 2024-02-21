---
--island
--2019年3月14日
--InboxItem_luckyChipsDrawCoins.lua

local InboxItem_luckyChipsDrawCoins = class("InboxItem_luckyChipsDrawCoins", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_luckyChipsDrawCoins:getCsbName()
    local csbName = "InBox/InboxItem_LuckChipsDraw.csb" --默认皮肤
    return csbName
end

-- 描述说明
function InboxItem_luckyChipsDrawCoins:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_luckyChipsDrawCoins
