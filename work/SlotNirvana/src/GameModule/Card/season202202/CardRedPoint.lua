
local CardRedPoint201903 = require("GameModule.Card.season201903.CardRedPoint")
local CardRedPoint = class("CardRedPoint", CardRedPoint201903)
function CardRedPoint:getCsbName()
    return string.format(CardResConfig.seasonRes.CardRedPointRes, "season202202")  
end
return CardRedPoint