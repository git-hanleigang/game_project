--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-05 14:04:21
]]
local InboxItem_EgyptCoinPusherTask = class("InboxItem_EgyptCoinPusherTask", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_EgyptCoinPusherTask:getCsbName( )
    return "InBox/InboxItem_pusherTaskEgypt.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_EgyptCoinPusherTask:getCardSource()
    return {"Coin Egypt Mission"}
end
-- 描述说明
function InboxItem_EgyptCoinPusherTask:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_EgyptCoinPusherTask