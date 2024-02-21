-- 农场关闭返还 邮件
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_FarmBackAward = class("InboxItem_FarmBackAward", InboxItem_base)

function InboxItem_FarmBackAward:getCsbName()
    return "InBox/InboxItem_Farm.csb"
end

-- 描述说明
function InboxItem_FarmBackAward:getDescStr()
    return "FARM BUY-BACK"
end

return InboxItem_FarmBackAward
