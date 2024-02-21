--[[
    卡片收集规则界面  一些玩法说明 --
]]
local CardMenuRule201903 = util_require("GameModule.Card.season201903.CardMenuRule")
local CardMenuRule = class("CardMenuRule", CardMenuRule201903)

function CardMenuRule:getCsbName()
    return string.format(CardResConfig.seasonRes.CardRuleRes, "season202103")  
end

return CardMenuRule