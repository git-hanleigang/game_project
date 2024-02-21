--[[
    卡片收集规则中 收集全卡后 奖励说明
]]
local BaseCardMenuPrize = util_require("GameModule.Card.baseViews.BaseCardMenuPrize")
local CardMenuPrize = class("CardMenuPrize", BaseCardMenuPrize)

function CardMenuPrize:initDatas()
    CardMenuPrize.super.initDatas(self)
    self:setLandscapeCsbName(CardResConfig.CardPrizeRuleRes)
end

-- 初始化UI --
-- function CardMenuPrize:getCsbName()
--     return CardResConfig.CardPrizeRuleRes
-- end

function CardMenuPrize:getSliderIcon()
    return CardResConfig.RuleSliderBg, CardResConfig.RuleSliderBg, CardResConfig.RuleSliderMark
end

function CardMenuPrize:getPrizeCellCsbName()
    return CardResConfig.CardPrizeRuleCellRes
end

return CardMenuPrize
