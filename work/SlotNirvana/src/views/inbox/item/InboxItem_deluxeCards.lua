--[[
    author:JohnnyFred
    time:2019-11-08 15:39:42
]]

local InboxItem_deluxeCards = class("InboxItem_deluxeCards", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_deluxeCards:getCsbName()
    return "InBox/InboxItem_deluxeCards.csb"
end

-- 如果有掉卡，在这里设置来源
function InboxItem_deluxeCards:getCardSource()
    return {"Cash Club Benefit"}
end
-- 描述说明
function InboxItem_deluxeCards:getDescStr()
    return "CASH CLUB BENEFIT", "you've got a free NADO CASE"
end

function InboxItem_deluxeCards:initView()
    self:initData()
    self:initTime()
    self:initDesc()
end

return  InboxItem_deluxeCards