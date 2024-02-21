--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-30 17:53:40
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_CouponChallenge = class("InboxItem_CouponChallenge", InboxItem_base)

function InboxItem_CouponChallenge:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 描述说明
function InboxItem_CouponChallenge:getDescStr()
    return "HERE'S YOUR REWARD"
end

return InboxItem_CouponChallenge