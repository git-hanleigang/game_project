--[[
    卡册数据
]]
local ShopItem = require "data.baseDatas.ShopItem"
local ParseCardData = require("GameModule.Card.data.ParseCardData")
local ParseCardClanPhaseRewardData = require("GameModule.Card.data.ParseCardClanPhaseRewardData")

local ParseCardClanData = class("ParseCardClanData")
function ParseCardClanData:ctor()
end

function ParseCardClanData:parseData(_netData)
    self.clanId = _netData.clanId
    self.year = _netData.year
    self.season = _netData.season
    self.albumId = _netData.albumId
    self.getReward = _netData.getReward
    self.coins = tonumber(_netData.coins)
    self.logo = _netData.logo
    self.wild = _netData.wild
    self.name = _netData.name
    self.type = _netData.type

    self.cards = {}
    if _netData.cards and #_netData.cards > 0 then
        for i = 1, #_netData.cards do
            local pcData = ParseCardData:create()
            pcData:parseData(_netData.cards[i])
            table.insert(self.cards, pcData)
        end
    end

    self.rewards = {}
    if _netData.rewards and #_netData.rewards > 0 then
        for i = 1, #_netData.rewards do
            local sItem = ShopItem:create()
            sItem:parseData(_netData.rewards[i])
            table.insert(self.rewards, sItem)
        end
    end

    self.quantityRewards = {}
    if _netData.quantityRewards and #_netData.quantityRewards > 0 then
        for i = 1, #_netData.quantityRewards do
            local pp = ParseCardClanPhaseRewardData:create()
            pp:parseData(_netData.quantityRewards[i])
            table.insert(self.quantityRewards, pp)
        end
    end
end

function ParseCardClanData:isGetAllCards()
    if self.cards and #self.cards > 0 then
        for i = 1, #self.cards do
            local cardData = self.cards[i]
            if cardData:getCount() == 0 then
                return false
            end
        end
    end
    return true
end

return ParseCardClanData
