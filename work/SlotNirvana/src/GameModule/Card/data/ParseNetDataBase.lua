local ShopItem = require "data.baseDatas.ShopItem"
local ParseCollectNado = require("GameModule.Card.data.ParseCollectNado")
local ParseNetDataBase = class("ParseNetDataBase")
function ParseNetDataBase:ctor()
    ParseNetDataBase.super.ctor(self)
end

-- 卡牌数据解析基类
function ParseNetDataBase:parseData(data)
end

-- 解析卡片基础信息 --
function ParseNetDataBase:parseCardsInfo(cards)
    local temp = {}
    if not cards then
        return temp
    end
    for i = 1, #cards do
        local cardData = cards[i]
        temp[i] = CardSysConfigs.CardClone(cardData)
    end
    return temp
end

-- 解析奖励基本信息 --
function ParseNetDataBase:parseShopItem(rewards)
    local temp = {}
    if not rewards or #rewards <= 0 then
        return temp
    end
    for i = 1, #rewards do
        temp[i] = self:parseShopReward(rewards[i])
    end
    return temp
end

function ParseNetDataBase:parseShopReward(rewardData)
    local sItem = ShopItem:create()
    sItem:parseData(rewardData)
    return sItem:getData()
end

-- 解析卡册集全奖励数据 --
function ParseNetDataBase:ParseCardAlbumRewardInfo(albumReward)
    local temp = {}
    if not albumReward then
        return nil
    end

    if not albumReward.id or albumReward.id == "" then
        return nil
    end

    temp.id = albumReward.id
    temp.coins = tonumber(albumReward.coins)
    temp.rewards = self:parseShopItem(albumReward.rewards)
    return temp
end

-- 解析卡册集全奖励数据 --
function ParseNetDataBase:ParseCardClanRewardInfo(clanReward)
    local temp = {}
    if not clanReward then
        return temp
    end
    for i = 1, #clanReward do
        local cRewardData = clanReward[i]
        temp[i] = {}
        if cRewardData.id then
            temp[i].id = cRewardData.id
        end
        if cRewardData.coins then
            temp[i].coins = tonumber(cRewardData.coins)
        end
        if cRewardData.rewards then
            temp[i].rewards = self:parseShopItem(cRewardData.rewards)
        end
        if cRewardData.cardDrop then -- 加判断防止死循环，shabi策划提的需求。
            temp[i].cardDrop = self:parseDropInfo(cRewardData.cardDrop)
        end
    end
    return temp
end

return ParseNetDataBase
