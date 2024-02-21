--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"

local OutsideGaveRewardData = class("OutsideGaveRewardData")

function OutsideGaveRewardData:ctor()
    self.coins = toLongNumber(0)
end

-- message OutsideGaveReward {
--     optional string coins = 1; //金币数
--     optional int64 gems = 2; //钻石数
--     repeated ShopItem items = 3; //物品
-- }
function OutsideGaveRewardData:parseData(data)
    self.coins:setNum(data.coins or 0)
    self.gems = tonumber(data.gems or 0)
    self.items = {}
    if data.items and #data.items > 0 then
        for i=1,#data.items do
            local itemData = ShopItem:create()
            itemData:parseData(data.items[i])
            table.insert(self.items, itemData)
        end
    end
end

function OutsideGaveRewardData:getCoins()
    return self.coins
end

function OutsideGaveRewardData:getGems()
    return self.gems
end

function OutsideGaveRewardData:getItems()
    return self.items
end

function OutsideGaveRewardData:isEffective()
    if self:getCoins() > toLongNumber(0) then
        return true
    end
    if self.gems > 0 then
        return true
    end
    if self.items and #self.items > 0 then
        return true
    end
    return false
end

function OutsideGaveRewardData:getEggItemNum()
    local itemNum = 0
    if self.items and #self.items > 0 then
        for i=1,#self.items do
            if self.items[i].p_icon == "OutsideCave_stick" then
                itemNum = itemNum + self.items[i].p_num
            end
        end
    end
    return itemNum
end


return OutsideGaveRewardData