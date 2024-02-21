-- Desc:    字独排行榜的邮件

local InboxItem_bingoRush_Game = class("InboxItem_bingoRush_Game", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_bingoRush_Game:getCsbName()
    return "InBox/InboxItem_bingoRush.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_bingoRush_Game:getCardSource()
    return {"Word Rank Rewards"}
end
-- 描述说明
function InboxItem_bingoRush_Game:getDescStr()
    return "HERE'S YOUR REWARD"
end

return InboxItem_bingoRush_Game
