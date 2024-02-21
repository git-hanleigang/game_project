--[[
    -- 赛季结束倒计时
    --
]]
local CardSeasonTime201903 = util_require("GameModule.Card.season201903.CardSeasonTime")
local CardSeasonTime = class("CardSeasonTime", CardSeasonTime201903)

function CardSeasonTime:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonTimeRes, "season202304")
end

return CardSeasonTime
