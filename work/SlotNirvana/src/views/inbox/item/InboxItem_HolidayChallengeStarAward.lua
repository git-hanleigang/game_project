--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-30 17:53:40
]]
local InboxItem_HolidayChallengeStarAward = class("InboxItem_HolidayChallengeStarAward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_HolidayChallengeStarAward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_HolidayChallengeStarAward:getCardSource()
    return ""
end
-- 描述说明
function InboxItem_HolidayChallengeStarAward:getDescStr()
    return self.m_mailData.title or "Collect your HOLIDAY CHALLENGE gift!"
end

return InboxItem_HolidayChallengeStarAward