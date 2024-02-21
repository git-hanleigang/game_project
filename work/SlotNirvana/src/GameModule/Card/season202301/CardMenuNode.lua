--[[
    集卡系统 菜单
    201904赛季
--]]
local CardMenuNode201903 = require("GameModule.Card.season201903.CardMenuNode")
local CardMenuNode = class("CardMenuNode", CardMenuNode201903)

-- 可重写
function CardMenuNode:getCsbName()
    return string.format(CardResConfig.seasonRes.CardMenuNodeRes, "season202301")
end

-- 可重写
function CardMenuNode:getRuleLua()
    return "GameModule.Card.season202301.CardMenuRule"
end

-- 可重写
function CardMenuNode:getPrizeLua()
    return "GameModule.Card.season202301.CardMenuPrize"
end

return CardMenuNode
