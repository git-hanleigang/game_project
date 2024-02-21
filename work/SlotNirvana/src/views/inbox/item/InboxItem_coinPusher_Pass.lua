--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-11 17:23:08
]]
local InboxItem_coinPusher_Pass = class("InboxItem_coinPusher_Pass", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_coinPusher_Pass:getCsbName()
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        --主题名
        local themeName = extraData.theme
        if themeName == "Activity_CoinPusher_Liberty" then
            return "InBox/InboxItem_pusherPass_Liberty.csb"
        end
    end
    return "InBox/InboxItem_pusherPass.csb"
end

-- 描述说明
function InboxItem_coinPusher_Pass:getDescStr()
    return "HERE'S YOUR REWARD"
end

return  InboxItem_coinPusher_Pass