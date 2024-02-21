local InboxItem_boostme = class("InboxItem_boostme", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_boostme:getCsbName()
    return "InBox/InboxItem_boostme.csb"
end

-- 描述说明
function InboxItem_boostme:getDescStr()
    return "Cashback Rewards"
end

return  InboxItem_boostme