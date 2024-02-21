local CardClanQuestInfo201903 = util_require("GameModule.Card.season201903.CardClanQuestInfo")
local CardClanQuestInfo = class("CardClanQuestInfo", CardClanQuestInfo201903)
-- 子类重写
function CardClanQuestInfo:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanQuestRes, "season202203")
end
return CardClanQuestInfo
