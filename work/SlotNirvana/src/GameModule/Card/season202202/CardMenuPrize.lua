--[[
    卡片收集规则中 收集全卡后 奖励说明
]]
local CardMenuPrize201903 = util_require("GameModule.Card.season201903.CardMenuPrize")
local CardMenuPrize = class("CardMenuPrize", CardMenuPrize201903)

-- function CardMenuPrize:getCsbName()
--     return string.format(CardResConfig.seasonRes.CardPrizeRes, "season202202")
-- end

function CardMenuPrize:initDatas()
    CardMenuPrize.super.initDatas(self)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardPrizeRes, "season202202"))
end

function CardMenuPrize:getSliderIcon()
    return CardResConfig.otherRes.PrizeSliderBg, CardResConfig.otherRes.PrizeSliderBg, CardResConfig.otherRes.PrizeSliderMark
end

function CardMenuPrize:getPrizeCellCsbName()
    return string.format(CardResConfig.seasonRes.CardPrizeCellRes, "season202202")
end

function CardMenuPrize:getTotalSets()
    return 22
end

return CardMenuPrize
