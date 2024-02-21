local CardTagNew = class("CardTagNew", util_require("base.BaseView"))

function CardTagNew:getCsbName()
    --移动资源到包内
    return "CardsBase201903/CardRes/season201903/cash_card_tag_new.csb"
    -- return string.format(CardResConfig.seasonRes.CardMiniTagNewRes, "season201903")
end

function CardTagNew:initUI()
    self:createCsbNode(self:getCsbName())
end

function CardTagNew:playShow()
    self:runCsbAction("show", false, function()
        self:runCsbAction("idle")
    end)
end

function CardTagNew:playIdle()
    self:runCsbAction("idle")
end

return CardTagNew
