local CardSeasonNadoWheel201903 = require("GameModule.Card.season201903.CardSeasonNadoWheel")
local CardSeasonNadoWheel = class("CardSeasonNadoWheel", CardSeasonNadoWheel201903)

function CardSeasonNadoWheel:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonNadoWheelRes, "season202103") 
end

function CardSeasonNadoWheel:getRedPointLua()
    return "GameModule.Card.season202103.CardRedPoint"
end

return CardSeasonNadoWheel