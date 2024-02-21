--[[--
    历史界面 卡牌汇总
]]
local CARD_STAR_WIDTH = 60 -- 星星资源宽度
local CARD_STAR_INTERVAL = 10 -- 星星之间的间隙
local CardHistoryCard201902 = class("CardHistoryCard201902", BaseView)
function CardHistoryCard201902:initUI()
    CardHistoryCard201902.super.initUI(self)
end

function CardHistoryCard201902:getCsbName()
    return "CardsBase201903/CardRes/season201903/cash_card_history201902.csb"
end

function CardHistoryCard201902:initCsbNodes()
    self.m_nodeCard = self:findChild("Node")
end

function CardHistoryCard201902:updateUI(cardData)
    local bgNode = self.m_nodeCard:getChildByName("Node_bg")
    self:updateBg(bgNode, cardData.type)

    local spLine = self.m_nodeCard:getChildByName("sp_line")
    if cardData.type == CardSysConfigs.CardType.puzzle then
        spLine:setVisible(false)
    else
        spLine:setVisible(true)
        util_changeTexture(spLine, string.format(CardResConfig.ClanCardNormalLinePath, cardData.clanId))
    end

    local spCard = self.m_nodeCard:getChildByName("Node_icon"):getChildByName("sp_card")
    if cardData.type == CardSysConfigs.CardType.puzzle then
        util_changeTexture(spCard, CardResConfig.getCardIcon(cardData.cardId, true))
    else
        util_changeTexture(spCard, CardResConfig.getCardIcon(cardData.cardId))
    end

    local lb_name = self.m_nodeCard:getChildByName("Node_name"):getChildByName("lb_name")
    if cardData.type == CardSysConfigs.CardType.puzzle then
        lb_name:setString("")
    else
        lb_name:setString(cardData.name)
    end

    local starNode = self.m_nodeCard:getChildByName("Node_star")
    if cardData.type == CardSysConfigs.CardType.puzzle then
        starNode:setVisible(false)
    else
        starNode:setVisible(true)
        self:updateStar201902(starNode, cardData)
    end
end

function CardHistoryCard201902:updateBg(bgNode, cardType)
    local bgLink = bgNode:getChildByName("bg_link")
    if bgLink then
        bgLink:setVisible(cardType == CardSysConfigs.CardType.link)
    end
    local bgGolden = bgNode:getChildByName("bg_golden")
    if bgGolden then
        bgGolden:setVisible(cardType == CardSysConfigs.CardType.golden)
    end
    local bgNormal = bgNode:getChildByName("bg_normal")
    if bgNormal then
        bgNormal:setVisible(cardType == CardSysConfigs.CardType.normal)
    end
    local bgPuzzle = bgNode:getChildByName("bg_puzzle")
    if bgPuzzle then
        bgPuzzle:setVisible(cardType == CardSysConfigs.CardType.puzzle)
    end
end

function CardHistoryCard201902:updateName(name1, name2, name3, cardName)
    name1:setVisible(false)
    name2:setVisible(false)
    name3:setVisible(false)
    local nameStrs = string.split(cardName, "|")
    if #nameStrs == 1 then
        name3:setVisible(true)
        name3:setString(nameStrs[1])
    else
        name1:setVisible(true)
        name2:setVisible(true)
        name1:setString(nameStrs[1])
        name2:setString(nameStrs[2])
    end
end

function CardHistoryCard201902:updateStar201902(starNode, cardData)
    local starNum = cardData.star
    -- 根据奇数偶数分别排版
    local firstPosX = 0
    if starNum % 2 == 0 then
        -- 偶数
        firstPosX = -(CARD_STAR_WIDTH / 2 + CARD_STAR_INTERVAL / 2) * (starNum - 1)
    else
        -- 奇数
        firstPosX = -(CARD_STAR_WIDTH + CARD_STAR_INTERVAL) * (starNum - 1) * 0.5
    end

    local children = starNode:getChildren()
    if not children or #children == 0 then
        for i = 1, 5 do
            local sprite = self:createCardStarIcon(starNum)
            sprite:setName("sp_star_" .. i)
            starNode:addChild(sprite)
        end
    end

    local iconName = CardResConfig.CardUnitStarRes[2][starNum]
    for i = 1, 5 do
        local sp_star = starNode:getChildByName("sp_star_" .. i)
        if i <= starNum then
            sp_star:setVisible(true)
            util_changeTexture(sp_star, iconName)
            sp_star:setPositionX(firstPosX + (CARD_STAR_WIDTH + CARD_STAR_INTERVAL) * (i - 1))
        else
            sp_star:setVisible(false)
        end
    end
end

function CardHistoryCard201902:createCardStarIcon(starNum)
    local iconName = CardResConfig.CardUnitStarRes[2][starNum]
    local sprite = util_createSprite(CardResConfig.CardUnitOtherResPath .. iconName)
    sprite:setAnchorPoint(cc.p(0.5, 0.5))
    return sprite
end

return CardHistoryCard201902
