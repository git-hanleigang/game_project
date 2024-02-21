--[[
    商城促销缺卡活动数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local StoreSaleRandomCardData = class("StoreSaleRandomCardData", BaseActivityData)

function StoreSaleRandomCardData:ctor()
    StoreSaleRandomCardData.super.ctor(self)
    self.m_maxDiscount = 0
    self.m_cardResultTable = {}
    self.m_lastPurchasePos = nil
end

function StoreSaleRandomCardData:parseData(data)
    if not data then
        return
    end
    StoreSaleRandomCardData.super.parseData(self, data)

    self.m_maxDiscount = data.maxDiscount
    if data.lastPurchasePos > 0 then
        self.m_lastPurchasePos = data.lastPurchasePos
    end

    self.m_cardResultTable = {}
    for i = 1, #(data.cardResults or {}) do
        local cardResultInfo = data.cardResults[i]
        local cardResultData = {
            position = cardResultInfo.position,
            cardResult = self:parseCardInfoData(cardResultInfo.cardResult)
        }
        table.insert(self.m_cardResultTable, cardResultData)
    end

    if data:HasField("lastCard") then
        self.m_lastPurchaseCardInfo = {position = data.lastCard.position, cardResult = self:parseCardInfoData(data.lastCard.cardResult)}
    end
    print("------ StoreSaleRandomCardData:parseData end")
end

function StoreSaleRandomCardData:parseCardInfoData(_data)
    local card = {}
    card.cardId = _data.cardId
    card.number = _data.number
    card.year = _data.year
    card.season = _data.season
    card.clanId = _data.clanId
    card.albumId = _data.albumId
    card.type = _data.type
    card.star = _data.star
    card.name = _data.name
    card.icon = _data.icon
    card.count = _data.count
    card.linkCount = _data.linkCount
    card.newCard = _data.newCard
    card.description = _data.description
    card.source = _data.source
    card.firstDrop = _data.firstDrop
    card.nadoCount = _data.nadoCount
    card.gift = _data.gift
    card.greenPoint = _data.greenPoint
    card.goldPoint = _data.goldPoint
    return card
end

function StoreSaleRandomCardData:getMaxDiscount()
    return self.m_maxDiscount
end

function StoreSaleRandomCardData:getCardInfoList()
    return self.m_cardResultTable
end

function StoreSaleRandomCardData:getLastPurchasePos()
    return self.m_lastPurchasePos
end

function StoreSaleRandomCardData:getLastPurchaseCardInfo()
    return self.m_lastPurchaseCardInfo
end

return StoreSaleRandomCardData
