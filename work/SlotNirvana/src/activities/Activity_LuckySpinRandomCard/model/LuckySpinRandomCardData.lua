--[[--
    luckyspin 送卡 卡走配置
    数据
]]
-- local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require("baseActivity.BaseActivityData")
local LuckySpinRandomCardData = class("LuckySpinRandomCardData", BaseActivityData)
function LuckySpinRandomCardData:ctor()
    LuckySpinRandomCardData.super.ctor(self)

    self.m_preSpinCards = {}
    self.p_spinCards = {}
end

-- 解析数据
function LuckySpinRandomCardData:parseData(_data)
    LuckySpinRandomCardData.super.parseData(self, _data)

    self.p_buyTimes = _data.buyTimes

    if _data.spinCards and #_data.spinCards > 0 then
        self.p_spinCards = self:parseLuckySpinCardInfo(_data.spinCards[1])
    end

    if #self.m_preSpinCards <= 0 then
        self:resetPreSpinCards()
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LUCKY_SPINE_RANDOM_CARD_REFRESH)
end

function LuckySpinRandomCardData:parseLuckySpinCardInfo(_spinCardData)
    local cards = {}
    local serverCards = _spinCardData.cards or {}
    if #serverCards <= 0 then
        return cards
    end

    -- table.sort(serverCards, function(aData, bData)
    --     return tonumber(aData.cardId) < tonumber(bData.cardId)
    -- end)

    for i, cardInfo in ipairs(serverCards) do
        local prePos = self:getCardIdxByPreCards(cardInfo)
        if not prePos then
            prePos = self:getFirstNilElementIdx(cards)
        end
        local cardInfo = self:parseCardInfoData(cardInfo)
        -- cards[prePos or #cards + 1] = cardInfo
        cards[prePos] = cardInfo
    end

    return cards
end

function LuckySpinRandomCardData:getFirstNilElementIdx(_tb)
    local idx = 1
    for i, v in ipairs(_tb) do
        idx = i + 1
    end
    return idx
end

function LuckySpinRandomCardData:parseCardInfoData(tInfo)
    local card = {}
    card.cardId = tInfo.cardId
    card.number = tInfo.number
    card.year = tInfo.year
    card.season = tInfo.season
    card.clanId = tInfo.clanId
    card.albumId = tInfo.albumId
    card.type = tInfo.type
    card.star = tInfo.star
    card.name = tInfo.name
    card.icon = tInfo.icon
    card.count = tInfo.count
    card.linkCount = tInfo.linkCount
    card.newCard = tInfo.newCard
    card.description = tInfo.description
    card.source = tInfo.source
    card.firstDrop = tInfo.firstDrop
    card.nadoCount = tInfo.nadoCount
    card.gift = tInfo.gift
    card.greenPoint = tInfo.greenPoint
    card.goldPoint = tInfo.goldPoint
    card.exchangeCoins = tonumber(tInfo.exchangeCoins or 0)
    card.round = tInfo.round
    return card
end

function LuckySpinRandomCardData:getCardIdxByPreCards(newCard)
    for idx, card in ipairs(self.m_preSpinCards) do
        if card.cardId == newCard.cardId then
            return idx
        end
    end
end

function LuckySpinRandomCardData:checkCardReplaced(newCard)
    if not newCard then
        return false
    end

    for i, card in ipairs(self.m_preSpinCards) do
        if card.cardId == newCard.cardId then
            return false
        end
    end

    return true
end

-- 不分档位了 所有档位的卡都一样
function LuckySpinRandomCardData:getAllSpinCardInfo()
    return self.p_spinCards
end

function LuckySpinRandomCardData:getCardsByKey(_key)
    local temp = {}
    if self.p_spinCards and #self.p_spinCards > 0 then
        for i = 1, #self.p_spinCards do
            if _key == self.p_spinCards[i].p_key then
                return self.p_spinCards[i].p_cards
            end
        end
    end
    return temp
end

function LuckySpinRandomCardData:getLastGearCardsInfo(_idx, _bPre)
    local cardList = self:getAllSpinCardInfo()
    if _bPre then
        cardList = self.m_preSpinCards
    end

    return cardList[_idx]
end

function LuckySpinRandomCardData:resetPreSpinCards()
    self.m_preSpinCards = self.p_spinCards
end

function LuckySpinRandomCardData:isRunning()
    if not LuckySpinRandomCardData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

-- -- 检查完成条件
function LuckySpinRandomCardData:checkCompleteCondition()
    return not globalData.shopRunData:getLuckySpinIsOpen()
end

return LuckySpinRandomCardData
