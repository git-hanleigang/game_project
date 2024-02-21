-- CardTagStar
local CardTagStar = class("CardTagStar", util_require("base.BaseView"))
function CardTagStar:initUI()
    self:createCsbNode(self:getCsbName())
    self.m_star0Node = self:findChild("star0")
    self.m_star1Node = self:findChild("star1")
end

function CardTagStar:getCsbName()
    --移动资源到包内
    return "CardsBase201903/CardRes/season201903/cash_card_star.csb"
    -- return string.format(CardResConfig.seasonRes.CardMiniTagStarRes, "season201903")
end

function CardTagStar:updateUI(cardData,forceStarLight)
    if cardData.count > 0 or forceStarLight then
        self.m_star0Node:setVisible(false)
        self.m_star1Node:setVisible(true)
        for i=1,5 do
            local sp = self.m_star1Node:getChildByName("Sprite_"..i)
            sp:setVisible(cardData.star == i)
        end
    else
        self.m_star0Node:setVisible(true)
        self.m_star1Node:setVisible(false)
        for i=1,5 do
            local sp = self.m_star0Node:getChildByName("Sprite_"..i)
            sp:setVisible(cardData.star == i)
        end
    end
end

-- 提供一个接口给小猪送缺卡改星星遮罩
function CardTagStar:setStarOpciaty(_color,_opacity)
    self.m_star1Node:setColor(util_changeHexToColor(_color))
    self.m_star1Node:setOpacity(_opacity)
end

return CardTagStar