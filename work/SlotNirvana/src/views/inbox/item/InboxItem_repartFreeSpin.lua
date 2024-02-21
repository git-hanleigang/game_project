---
--island
--2019年3月14日
--InboxItem_repartFreeSpin.lua

local InboxItem_repartFreeSpin = class("InboxItem_repartFreeSpin", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_repartFreeSpin:getCsbName()
    local csbName = "InBox/InboxItem_RepartFreeSpin.csb" --默认皮肤
    return csbName
end

-- 描述说明
function InboxItem_repartFreeSpin:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_repartFreeSpin