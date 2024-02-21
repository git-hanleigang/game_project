local CardClanCell201903 = util_require("GameModule.Card.season201903.CardClanCell")
local CardClanCell = class("CardClanCell", CardClanCell201903)

function CardClanCell:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanCellRes, "season201904")
end

function CardClanCell:getMiniChipLua()
    return "GameModule.Card.season201903.MiniChipUnit"
end

return CardClanCell
