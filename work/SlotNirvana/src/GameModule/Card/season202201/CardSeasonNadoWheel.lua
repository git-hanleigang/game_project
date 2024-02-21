local CardSeasonNadoWheel201903 = require("GameModule.Card.season201903.CardSeasonNadoWheel")
local CardSeasonNadoWheel = class("CardSeasonNadoWheel", CardSeasonNadoWheel201903)

function CardSeasonNadoWheel:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonNadoWheelRes, "season202201") 
end

function CardSeasonNadoWheel:getRedPointLua()
    return "GameModule.Card.season202201.CardRedPoint"
end

return CardSeasonNadoWheel