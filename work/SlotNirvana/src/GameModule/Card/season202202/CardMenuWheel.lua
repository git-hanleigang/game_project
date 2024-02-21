local CardMenuWheel201903 = require("GameModule.Card.season201903.CardMenuWheel")
local CardMenuWheel = class("CardMenuWheel", CardMenuWheel201903)

function CardMenuWheel:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonLottoRes, "season202202")
end

function CardMenuWheel:getBubbleLua()
    return "GameModule.Card.season202202.CardMenuWheelBubble"
end

function CardMenuWheel:getRedPointLua()
    return "GameModule.Card.season202202.CardRedPoint"
end

return CardMenuWheel
