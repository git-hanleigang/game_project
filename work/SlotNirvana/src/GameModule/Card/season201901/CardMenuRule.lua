--[[
    卡片收集规则界面  一些玩法说明 --
]]
local BaseCardMenuRule = util_require("GameModule.Card.baseViews.BaseCardMenuRule")
local CardMenuRule = class("CardMenuRule", BaseCardMenuRule)

-- 初始化UI --
function CardMenuRule:getCsbName()
    return CardResConfig.CardCollectRuleRes
end

return CardMenuRule
