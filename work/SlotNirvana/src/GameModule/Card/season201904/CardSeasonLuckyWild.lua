local CardSeasonLuckyWild201903 = require("GameModule.Card.season201903.CardSeasonLuckyWild")
local CardSeasonLuckyWild = class("CardSeasonLuckyWild", CardSeasonLuckyWild201903)
function CardSeasonLuckyWild:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonLuckyWildRes, "season201904") 
end
return CardSeasonLuckyWild