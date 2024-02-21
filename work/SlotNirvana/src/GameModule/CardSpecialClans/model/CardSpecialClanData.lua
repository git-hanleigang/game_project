--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"
local ParseCardData = require("GameModule.Card.data.ParseCardData")
local ParseCardClanPhaseRewardData = require("GameModule.Card.data.ParseCardClanPhaseRewardData")

local CardSpecialClanData = class("CardSpecialClanData")

function CardSpecialClanData:parseData(_netData)
    self.clanId = _netData.clanId
    self.year = _netData.year
    self.season = _netData.season
    self.albumId = _netData.albumId
    self.round = _netData.round
    self.getReward = _netData.getReward
    self.coins = tonumber(_netData.coins)
    self.logo = _netData.logo
    self.wild = _netData.wild
    self.name = _netData.name
    self.type = _netData.type
    self.m_cardNum = 0
    self.cards = {}
    if _netData.cards and #_netData.cards > 0 then
        for i = 1, #_netData.cards do
            local pcData = ParseCardData:create()
            pcData:parseData(_netData.cards[i])
            table.insert(self.cards, pcData)
            self.m_cardNum = self.m_cardNum + 1
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

function CardSpecialClanData:getCoins()
    return self.coins
end

function CardSpecialClanData:getClanId()
    return self.clanId
end

function CardSpecialClanData:getAlbumId()
    return self.albumId
end

function CardSpecialClanData:getCards()
    return self.cards
end

function CardSpecialClanData:getCardNum()
    return self.m_cardNum
end

function CardSpecialClanData:getHaveCardNum()
    local count = 0
    if self.cards and #self.cards > 0 then
        for i = 1, #self.cards do
            if self.cards[i]:getCount() > 0 then
                count = count + 1
            end
        end
    end
    return count
end

function CardSpecialClanData:isCompleted()
    return self.getReward == true
end

function CardSpecialClanData:getRewardItems()
    return self.rewards
end

function CardSpecialClanData:getBuffItemByBuffType(_buffType)
    if self.rewards and #self.rewards > 0 then
        for i = 1, #self.rewards do
            local itemData = self.rewards[i]
            if itemData:isBuff() then
                local buffInfo = itemData:getBuffInfo()
                if buffInfo and buffInfo:getBuffType() == _buffType then
                    return itemData
                end
            end
        end
    end
    return 
end

-- 阶段奖励
function CardSpecialClanData:getPhaseRewards()
    return self.quantityRewards
end

-- 获取对应的阶段奖励
function CardSpecialClanData:getPhaseRewardByIndex(_index)
    return self.quantityRewards[_index]
end

-- 阶段奖励是否完成
function CardSpecialClanData:isPhaseRewardCompleted(_index)
    local haveCardNum = self:getHaveCardNum()
    local reward = self:getPhaseRewardByIndex(_index)
    if haveCardNum >= reward:getNum() then
        return true
    end
    return false
end

-- 一页上的卡
function CardSpecialClanData:getPageCards(_pageIndex, _pageCardNum)
    -- 兼容老代码
    _pageCardNum = _pageCardNum or CardSpecialClanCfg.pageCardNum
    local tb = {}
    local startIndex = 1 + (_pageIndex - 1) * _pageCardNum
    local endIndex = _pageIndex * _pageCardNum
    if self.cards and #self.cards > 0 then
        for i = 1, #self.cards do
            if i >= startIndex and i <= endIndex then
                table.insert(tb, self.cards[i])
            end
        end
    end
    return tb
end

-- 一页上的带new标签的卡
function CardSpecialClanData:getPageNewCards(_pageIndex)
    -- 一页10卡，一共3页
    local pageCards = self:getPageCards(_pageIndex)
    local newCards = {}
    if pageCards and pageCards and #pageCards >= 0 then
        for i = 1, #pageCards do
            if pageCards[i]:getNewCard() then
                table.insert(newCards, pageCards[i])
            end
        end
    end
    return newCards
end

return CardSpecialClanData
