--[[
    小猪送卡活动的数据
]]
-- message PigCard {
--     optional string activityId = 1; //活动id
--     optional string activityName = 2; //活动名称
--     optional int64 expireAt = 3; //截止时间
--     optional int64 expire = 4; //剩余时间
--     repeated CardInfo cards = 5;
--     optional int32 buyTimes = 6;
--     optional int32 discount = 7;
--     optional int32 lastDiscount = 8;
--   }
local BaseActivityData = require("baseActivity.BaseActivityData")
local PigRandomCardData = class("PigRandomCardData", BaseActivityData)

-- 解析数据
function PigRandomCardData:parseData(_data)
    PigRandomCardData.super.parseData(self, _data)

    self.p_buyTimes = _data.buyTimes
    self.p_cards = {}
    if _data.cards and #_data.cards > 0 then
        for i = 1, #_data.cards do
            self.p_cards[#self.p_cards + 1] = self:parseCardInfo(_data.cards[i])
        end
    end

    if self.m_lastCards == nil then
        self.m_lastCards = clone(self.p_cards)
    end

    -- 送缺卡活动融合小猪折扣活动
    -- 添加两个字段
    self.p_discount = _data.discount
    self.p_lastDiscount = _data.lastDiscount

    if not self.m_isFirst then
        self.m_isFirst = true
        if self.p_buyTimes >= #self.p_cards then
            self:setPoped(true)
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIG_RANDOM_CARD_DATA_REFRESH)
    print(" ----- PigRandomCardData ----- ")
end

function PigRandomCardData:setPoped(_isPoped)
    self.m_isPoped = _isPoped
end

function PigRandomCardData:isPoped()
    return self.m_isPoped
end

function PigRandomCardData:checkCompleteCondition()
    if self:isPoped() then
        return true
    end
    return false
end

function PigRandomCardData:isRunning()
    if not PigRandomCardData.super.isRunning(self) then
        return false
    end
    --如果有折扣，还需显示
    if self:isCompleted() and not self:isHaveDiscount() then
        return false
    end
    return true
end

--是否有折扣
function PigRandomCardData:isHaveDiscount()
    if nil == self.p_discount or 0 == tonumber(self.p_discount) then 
        return false
    else
        return true
    end
end

function PigRandomCardData:parseCardInfo(_tInfo)
    local card = {}
    card.cardId = _tInfo.cardId
    card.number = _tInfo.number
    card.year = _tInfo.year
    card.season = _tInfo.season
    card.clanId = _tInfo.clanId
    card.albumId = _tInfo.albumId
    card.type = _tInfo.type
    card.star = _tInfo.star
    card.name = _tInfo.name
    card.icon = _tInfo.icon
    card.count = _tInfo.count
    card.linkCount = _tInfo.linkCount
    card.newCard = _tInfo.newCard
    card.description = _tInfo.description
    card.source = _tInfo.source
    card.firstDrop = _tInfo.firstDrop
    card.nadoCount = _tInfo.nadoCount
    card.gift = _tInfo.gift
    card.greenPoint = _tInfo.greenPoint
    card.goldPoint = _tInfo.goldPoint
    return card
end

function PigRandomCardData:getCards()
    return self.p_cards
end

function PigRandomCardData:getBuyTimes()
    return self.p_buyTimes
end

function PigRandomCardData:getLastCards()
    return self.m_lastCards
end

function PigRandomCardData:resetLastCards()
    self.m_lastCards = clone(self.p_cards)
end

function PigRandomCardData:getDiscount()
    return self.p_discount
end

function PigRandomCardData:getLastDiscount()
    return self.p_lastDiscount
end

function PigRandomCardData:getPiggyRandomCardSaleParam(isIgnoreNovice)
    local upperRate = 0
    if not isIgnoreNovice then
        local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
        local isInNoviceDiscount = piggyBankData and piggyBankData:checkInNoviceDiscount()
        if isInNoviceDiscount then
            upperRate = piggyBankData:getNoviceFirstDiscount() or 0
        end
    end

    local discount = self:getDiscount()
    if discount == nil then
        return upperRate
    else
        if globalData.userRunData and self.p_expireAt > globalData.userRunData.p_serverTime then --小猪未到期
            upperRate = upperRate + discount
        end
    end
    return upperRate
end

function PigRandomCardData:beingOnPiggyCommonSale()
    local discount = self:getDiscount()
    if self:isRunning() and discount and discount > 0 then
        return true
    end
    return false
end

return PigRandomCardData
