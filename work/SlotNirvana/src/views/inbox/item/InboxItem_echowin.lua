
-- Echo Win 邮件

local InboxItem_echowin = class("InboxItem_echowin", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_echowin:getCsbName()
    return "InBox/InboxItem_EchoWin.csb"
end

-- 描述说明
function InboxItem_echowin:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_echowin
