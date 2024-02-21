--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-19 11:51:03
    describe:品质头像框挑战
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_SpecialFrame_Challenge = class("InboxItem_SpecialFrame_Challenge", InboxItem_base)

function InboxItem_SpecialFrame_Challenge:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_SpecialFrame_Challenge:getCardSource()
    return {"Special Frame Challenge"}
end
-- 描述说明
function InboxItem_SpecialFrame_Challenge:getDescStr()
    return "QUALITY FRAME CHALLENGE REWARD"
end

return InboxItem_SpecialFrame_Challenge
