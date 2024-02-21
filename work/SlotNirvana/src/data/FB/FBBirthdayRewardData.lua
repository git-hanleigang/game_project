--[[
    FB生日礼物
]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local FBBirthdayRewardData = class("FBBirthdayRewardData")

function FBBirthdayRewardData:ctor()
    self.p_coins = 0
end

function FBBirthdayRewardData:parseData(_data)
    self.p_coins = tonumber(_data.coins)  -- 金币数
end

function FBBirthdayRewardData:getCoins()
    return self.p_coins
end

function FBBirthdayRewardData:parseItems(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

return FBBirthdayRewardData