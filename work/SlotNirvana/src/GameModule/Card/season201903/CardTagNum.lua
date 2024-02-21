local CardTagNum = class("CardTagNum", util_require("base.BaseView"))
function CardTagNum:initUI()
    self:createCsbNode(self:getCsbName())
end

function CardTagNum:getCsbName()
    --移动资源到包内
    return "CardsBase201903/CardRes/season201903/cash_card_tag_num.csb"
    -- return string.format(CardResConfig.seasonRes.CardMiniTagNumRes, "season201903")
end

function CardTagNum:updateNum(num)
    local lb = self:findChild("BitmapFontLabel_1")
    lb:setString("X"..num)
    self:updateLabelSize({label=lb},45)
end

return CardTagNum
