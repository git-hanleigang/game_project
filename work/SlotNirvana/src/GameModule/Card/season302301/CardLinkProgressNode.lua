
local CardLinkProgressNode201903 = util_require("GameModule.Card.season201903.CardLinkProgressNode")
local CardLinkProgressNode = class("CardLinkProgressNode", CardLinkProgressNode201903)

function CardLinkProgressNode:getTotal()
    return 5
end

return CardLinkProgressNode