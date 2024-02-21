--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"
local JewelManiaRewardData = class("JewelManiaRewardData")

function JewelManiaRewardData:ctor()
end

-- message JewelManiaReward {
--     optional string coins = 1;
--     repeated ShopItem items = 2;
--     optional bool collected = 3;//是否领取
--     optional int32 index = 4;//奖励唯一标识
--   }
function JewelManiaRewardData:parseData(_netData)
    self.p_index = _netData.index
    self.p_coins = tonumber(_netData.coins)
    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i=1,#_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.p_items, itemData)
        end
    end
    self.p_collected = _netData.collected
end

function JewelManiaRewardData:getIndex()
    return self.p_index
end

function JewelManiaRewardData:getCoins()
    return self.p_coins
end

function JewelManiaRewardData:getItems()
    return self.p_items
end

function JewelManiaRewardData:isCollected()
    return self.p_collected
end

function JewelManiaRewardData:isRewardEffective()
    if (self.p_coins and self.p_coins ~= "") or (self.p_items and #self.p_items > 0) then
        return true
    end
    return false
end

return JewelManiaRewardData