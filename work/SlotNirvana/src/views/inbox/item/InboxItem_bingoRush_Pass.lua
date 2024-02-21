-- Desc:    字独排行榜的邮件

local InboxItem_bingoRush_Pass = class("InboxItem_bingoRush_Pass", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_bingoRush_Pass:getCsbName()
    return "InBox/InboxItem_bingoRush_pass.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_bingoRush_Pass:getCardSource()
    return {"Bingo Rush Pass Rewards"}
end
-- 描述说明
function InboxItem_bingoRush_Pass:getDescStr()
    return "HERE'S YOUR REWARD"
end

return InboxItem_bingoRush_Pass
