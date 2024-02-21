-- 新版新关挑战 邮件
local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_BucksBack = class("InboxItem_BucksBack", InboxItem_baseReward)

function InboxItem_BucksBack:getCsbName()
    return "InBox/InboxItem_BucksBack.csb"
end

-- 描述说明
function InboxItem_BucksBack:getDescStr()
    return self.m_mailData.title or "CTS BUCKS SPECIAL BACK"
end

return InboxItem_BucksBack
