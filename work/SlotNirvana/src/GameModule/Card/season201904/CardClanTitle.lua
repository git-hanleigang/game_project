--[[
    卡组的标题
    201904
]]
local CardClanTitle201903 = util_require("GameModule.Card.season201903.CardClanTitle")
local CardClanTitle = class("CardClanTitle", CardClanTitle201903)

function CardClanTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanTitleRes, "season201904")
end

-- 不需要灯光
function CardClanTitle:initTitleLight()
end

-- 子类重写
function CardClanTitle:getQuestInfoLua()
    return "GameModule.Card.season201904.CardClanQuestInfo"
end


return CardClanTitle