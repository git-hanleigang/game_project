local CardMenuWheelBubble201903 = util_require("GameModule.Card.season201903.CardMenuWheelBubble")
local CardMenuWheelBubble = class("CardMenuWheelBubble", CardMenuWheelBubble201903)

function CardMenuWheelBubble:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonLottoQipaoRes, "season202303")
end

return CardMenuWheelBubble
