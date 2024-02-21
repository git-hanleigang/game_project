--[[--
]]
local CardSeasonBottom201903 = require("GameModule.Card.season201903.CardSeasonBottom")
local CardSeasonBottom = class("CardSeasonBottom", CardSeasonBottom201903)

function CardSeasonBottom:getCsbName()
    return string.format(CardResConfig.seasonRes.CardBottomNodeRes, "season202101")
end

function CardSeasonBottom:getMenuNodeLua()
    return "GameModule.Card.season202101.CardMenuNode"    
end

function CardSeasonBottom:getMenuWheelLua()
    return "GameModule.Card.season202101.CardMenuWheel"    
end

function CardSeasonBottom:getSeasonNadoWheelLua()
    return "GameModule.Card.season202101.CardSeasonNadoWheel"    
end

return CardSeasonBottom
