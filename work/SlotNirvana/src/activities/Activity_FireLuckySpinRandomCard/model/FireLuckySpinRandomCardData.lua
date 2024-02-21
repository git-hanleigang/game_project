--[[--
    SuperSpin高级版送缺卡 送卡 卡走配置
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local FireLuckySpinRandomCardData = class("FireLuckySpinRandomCardData", BaseActivityData)
function FireLuckySpinRandomCardData:ctor()
    FireLuckySpinRandomCardData.super.ctor(self)

    self.m_preSpinCards = {}
    self.p_spinCards = {}
end

-- message LuckySpinCard {
--     optional string activityId = 1; //活动id
--     optional string activityName = 2; //活动名称
--     optional int64 expireAt = 3; //截止时间
--     optional int64 expire = 4; //剩余时间
--     repeated LuckySpinCardInfo spinCards = 5;
--     optional int32 buyTimes = 6;
--   }
function FireLuckySpinRandomCardData:parseData(_data)
    FireLuckySpinRandomCardData.super.parseData(self, _data)

    self.p_buyTimes = _data.buyTimes

    if _data.spinCards and #_data.spinCards > 0 then
        self.p_spinCards = self:parseLuckySpinCardInfo(_data.spinCards[1])
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FIRE_LUCKY_SPINE_RANDOM_CARD_REFRESH)
end

function FireLuckySpinRandomCardData:parseLuckySpinCardInfo(_spinCardData)
    local cards = {}
    local serverCards = _spinCardData.cards or {}
    if #serverCards <= 0 then
        return cards
    end

    for i, cardInfo in ipairs(serverCards) do
        local cardInfo = self:parseCardInfoData(cardInfo)
        cards[cardInfo.cardId] = cardInfo
    end

    return cards
end

function FireLuckySpinRandomCardData:getFirstNilElementIdx(_tb)
    local idx = 1
    for i, v in ipairs(_tb) do
        idx = i + 1
    end
    return idx
end

function FireLuckySpinRandomCardData:parseCardInfoData(tInfo)
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

function FireLuckySpinRandomCardData:getCardIdxByPreCards(newCard)
    for idx, card in ipairs(self.m_preSpinCards) do
        if card.cardId == newCard.cardId then
            return idx
        end
    end
end

function FireLuckySpinRandomCardData:checkCardReplaced(newCard)
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
function FireLuckySpinRandomCardData:getAllSpinCardInfo()
    return self.p_spinCards
end

function FireLuckySpinRandomCardData:getCardsByKey(_key)
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

function FireLuckySpinRandomCardData:getLastGearCardsInfo(_bPre)
    if _bPre then
        return self.m_preSpinCards
    else
        return self.p_spinCards
    end
end

function FireLuckySpinRandomCardData:resetPreSpinCards()
    self.m_preSpinCards = clone(self.p_spinCards)
end

function FireLuckySpinRandomCardData:isRunning()
    if not FireLuckySpinRandomCardData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

-- -- 检查完成条件
-- function FireLuckySpinRandomCardData:checkCompleteCondition()
--     local gear = globalData.luckySpinV2.m_gear or {}
--     local times = 0
--     for i,v in ipairs(gear) do
--         if v.p_type == "HIGH" then
--             times = times + v.p_remainingTimes
--         end
--     end

--     return times <= 0
-- end

function FireLuckySpinRandomCardData:checkNeedAct(_needAct)
    if not _needAct then
        return false
    end

    local pCount = 0
    for k,v in pairs(self.p_spinCards) do
        pCount = pCount + 1
    end

    if pCount < 3 then
        return false
    end

    for k,v in pairs(self.p_spinCards) do
        local cardData = self.m_preSpinCards[k]
        if not cardData then
            return true
        end
    end

    return false
end

function FireLuckySpinRandomCardData:getRefreshData()
    local oldId = nil
    local newData = nil

    for k,v in pairs(self.p_spinCards) do
        local cardData = self.m_preSpinCards[k]
        if not cardData then
            newData = clone(v)
            break
        end
    end

    for k,v in pairs(self.m_preSpinCards) do
        local cardData = self.p_spinCards[k]
        if not cardData then
            oldId = k
            break
        end
    end

    return oldId, newData
end

return FireLuckySpinRandomCardData
