--通用活动奖励
local ShopItem = require "data.baseDatas.ShopItem"
local CommonRewards = class("CommonRewards")
CommonRewards.p_coins = nil --奖励金币
CommonRewards.p_items = nil --奖励道具
CommonRewards.p_coinsValue = nil --金币价值
function CommonRewards:ctor()
end
function CommonRewards:parseData(data)
    self.p_coins = tonumber(data.coins) or 0
    self.p_items = self:parseItems(data.items)
    self.p_coinsValue = data.coinValue
    --兼容xw代码
    self.coins = self.p_coins
    self.items = self.p_items
end

function CommonRewards:parseItems(data)
    local items = {}
    if data ~= nil and #data > 0 then
        for i = 1, #data do
            local shopItemCell = ShopItem:create()
            shopItemCell:parseData(data[i])
            items[i] = shopItemCell
        end
    end
    return items
end

function CommonRewards:getCoins()
    return self.p_coins
end

function CommonRewards:getItems()
    return self.p_items
end

function CommonRewards:isRewardEffective()
    if self.p_coins > 0 or #self.p_items > 0 then
        return true
    end
    return false
end
return CommonRewards
