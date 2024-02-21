---
--island
--2019年3月14日
--InboxItem_repartJackpot.lua

local InboxItem_repartJackpot = class("InboxItem_repartJackpot", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_repartJackpot:getCsbName()
    local csbName = "InBox/InboxItem_RepartJackpot.csb" --默认皮肤
    return csbName
end

-- 描述说明
function InboxItem_repartJackpot:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_repartJackpot