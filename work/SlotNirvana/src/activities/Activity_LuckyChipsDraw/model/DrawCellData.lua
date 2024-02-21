--抽奖道具 iosfix
local ShopItem = require "data.baseDatas.ShopItem"
local DrawCellData = class("DrawCellData")
DrawCellData.m_item = nil --道具
DrawCellData.m_type = nil --类型
DrawCellData.m_cardDrop = nil --标记集卡是否拥有
DrawCellData.m_collected = nil --是否领取
DrawCellData.m_coins = nil --金币数量
DrawCellData.m_cardResult = nil --集卡数据
function DrawCellData:parseData(data)
    self.m_type = data.type --类型
    self.m_cardDrop = data.cardDrop --标记集卡是否拥有
    self.m_collected = data.collected --是否领取
    self.m_item = ShopItem:create()
    self.m_item:parseData(data.item) --道具
    self.m_coins = tonumber(data.coins) --是否领取
    if data:HasField("cardResult") then
        self.m_cardResult = self:parseCardInfoData(data.cardResult) --集卡数据
    end
end
function DrawCellData:parseTableData(data)
    self.m_type = data.type --类型
    self.m_cardDrop = data.cardDrop --标记集卡是否拥有
    self.m_collected = data.collected --是否领取
    self.m_coins = tonumber(data.coins) --是否领取
    if data.item then
        self.m_item = ShopItem:create()
        self.m_item:parseData(data.item) --道具
    end
    if data.cardResult then
        self.m_cardResult = self:parseCardInfoData(data.cardResult) --集卡数据
    end
end
--CardSysConfigs.CardClone 这里拷贝集卡
function DrawCellData:parseCardInfoData(tInfo)
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
return DrawCellData
