--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{dhs}
    time:2021-11-19 15:39:29
    filepath:/SlotNirvana/src/views/inbox/InboxItem_LotteryRewards.lua
]]

local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")

local InboxItem_LotteryRewards = class("InboxItem_LotteryRewards",InboxItem_baseReward)

function InboxItem_LotteryRewards:getCsbName()
    return "InBox/InboxItem_LotteryRewards.csb"
end

-- 描述说明
function InboxItem_LotteryRewards:getDescStr()
    return self.m_mailData.content
end

return InboxItem_LotteryRewards