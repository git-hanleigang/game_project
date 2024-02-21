local CardLinkProgressMark201903 = util_require("GameModule.Card.season201903.CardLinkProgressMark")
local CardLinkProgressMark = class("CardLinkProgressMark", CardLinkProgressMark201903)

function CardLinkProgressMark:getPreStr()
    return "X"
end
return CardLinkProgressMark
