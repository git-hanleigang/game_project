--[[
    卡牌基础信息
]]
local ParseCardData = class("ParseCardData")
function ParseCardData:ctor()
end

function ParseCardData:parseData(tInfo)
    self.cardId = tInfo.cardId
    self.number = tInfo.number
    self.year = tInfo.year
    self.season = tInfo.season
    self.clanId = tInfo.clanId
    self.albumId = tInfo.albumId
    self.type = tInfo.type
    self.star = tInfo.star
    self.name = tInfo.name
    self.icon = tInfo.icon
    self.count = tInfo.count
    self.linkCount = tInfo.linkCount
    self.newCard = tInfo.newCard
    self.description = tInfo.description
    self.source = tInfo.source
    self.firstDrop = tInfo.firstDrop
    self.nadoCount = tInfo.nadoCount
    self.gift = tInfo.gift
    self.greenPoint = tInfo.greenPoint
    self.goldPoint = tInfo.goldPoint
    self.exchangeCoins = tonumber(tInfo.exchangeCoins or 0)
    self.round = tInfo.round
end

function ParseCardData:getCardId()
    return self.cardId
end

function ParseCardData:getAlbumId()
    return self.albumId
end

function ParseCardData:getCount()
    return self.count
end

function ParseCardData:setCount(_count)
    self.count = _count
end

function ParseCardData:getNewCard()
    return self.newCard
end

function ParseCardData:setNewCard(_isNew)
    self.newCard = _isNew
end

return ParseCardData
