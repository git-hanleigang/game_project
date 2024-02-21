--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-05 12:26:52
]]
--[[
    推币机排行奖励
]]

local InboxItem_NewCoinPusherRank = class("InboxItem_NewCoinPusherRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_NewCoinPusherRank:getCsbName( )
    return "InBox/InboxItem_NewCoinPusherRank.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_NewCoinPusherRank:getCardSource()
    return {"New CoinPusher Rank Reward"}
end
-- 描述说明
function InboxItem_NewCoinPusherRank:getDescStr()
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        --名次
        self.m_rankNum = extraData.rank
        local strRank = string.format("RANK %s REWARD",self.m_rankNum)
        return strRank
    end
    return ""
end

return  InboxItem_NewCoinPusherRank