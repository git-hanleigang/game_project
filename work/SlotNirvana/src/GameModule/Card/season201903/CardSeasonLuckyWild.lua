local CardSeasonLuckyWild = class("CardSeasonLuckyWild", util_require("base.BaseView"))
-- 
function CardSeasonLuckyWild:initUI()
    self:createCsbNode(self:getCsbName())

    self:runCsbAction("idle_0")
end

function CardSeasonLuckyWild:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonLuckyWildRes, "season201903") 
end

return CardSeasonLuckyWild