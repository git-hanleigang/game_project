--[[
    第三方付费 免费奖励
]]
local InboxItem_AppChargeFree = class("InboxItem_AppChargeFree", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_AppChargeFree:initView()
    InboxItem_AppChargeFree.super.initView(self)
end

function InboxItem_AppChargeFree:getCsbName()
    return "InBox/InboxItem_exclusiveStore_freegift.csb"
end

-- 描述说明
function InboxItem_AppChargeFree:getDescStr()
    return "EXCLUSIVE STORE"
end

-- 如果有掉卡，在这里设置来源
function InboxItem_AppChargeFree:getCardSource()
    return {"Exclusive Store"}
end

return  InboxItem_AppChargeFree