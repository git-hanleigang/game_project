--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-04-01 13:13:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-04-01 13:15:46
FilePath: /SlotNirvana/src/views/inbox/InboxItem_IceBrokenSale.lua
Description: 新版破冰促销 邮件
--]]
local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_IceBrokenSale = class("InboxItem_IceBrokenSale", InboxItem_baseReward)

function InboxItem_IceBrokenSale:getCsbName()
    return "InBox/InboxItem_IceBroken.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_IceBrokenSale:getCardSource()
    return {"Ice Broken Sale"}
end

-- 描述说明
function InboxItem_IceBrokenSale:getDescStr()
    return self.m_mailData.title or "TRIFECTA SALE"
end

return InboxItem_IceBrokenSale