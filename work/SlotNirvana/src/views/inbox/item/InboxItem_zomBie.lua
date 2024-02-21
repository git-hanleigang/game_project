--[[
    des: zombie
    author:{author}
]]
local InboxItem_zomBie = class("InboxItem_zomBie", util_require("views.inbox.item.InboxItem_baseReward"))


function InboxItem_zomBie:initView()
    InboxItem_zomBie.super.initView(self)
end

function InboxItem_zomBie:getCsbName()
    return "InBox/InboxItem_ZombieReward.csb"
end

-- 描述说明
function InboxItem_zomBie:getDescStr()
    return "Here are your supplies saved"
end

-- 如果有掉卡，在这里设置来源
function InboxItem_zomBie:getCardSource()
    return {"Zombie Onslaught"}
end

return  InboxItem_zomBie