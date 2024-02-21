--[[
    des: 邮件中卡牌 集卡小游戏
]]

local InboxItem_cashPuzzle = class("InboxItem_cashPuzzle", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_cashPuzzle:getCsbName()
    return "InBox/InboxItem_CashPuzzle.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_cashPuzzle:getCardSource()
    return {"Cash Puzzle"}
end
-- 描述说明
function InboxItem_cashPuzzle:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_cashPuzzle