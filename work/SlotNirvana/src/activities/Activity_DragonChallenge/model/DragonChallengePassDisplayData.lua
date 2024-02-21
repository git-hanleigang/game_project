local DragonChallengePassDisplayData = class("DragonChallengePassDisplayData")
local ShopItem = require "data.baseDatas.ShopItem"

-- message DragonChallengePassDisplayResult {
--     optional string type = 1; // 奖励的类型
--     optional int64 coins = 2; //金币
--     repeated ShopItem items = 3; // 物品
--     optional string label = 4;// 1是高级奖励 0是低级奖励
--     optional string description = 5;// 奖励描述
--     optional string coinsV2 = 6; //金币
--   }

function DragonChallengePassDisplayData:parseData(_data)
    self.p_type = _data.type
    self.p_coins = (_data.coinsV2 and _data.coinsV2 ~= "") and _data.coinsV2 or _data.coins
    self.p_items = self:parseItemsData(_data.items)
    self.p_label = _data.label
    self.p_description = _data.description
end

function DragonChallengePassDisplayData:parseItemsData(_items)
    local itemsData = {}
    if _items and #_items > 0 then
        for i, v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function DragonChallengePassDisplayData:getType()
    return self.p_type
end

function DragonChallengePassDisplayData:getCoins()
    return self.p_coins
end

function DragonChallengePassDisplayData:getItems()
    return self.p_coins
end

return DragonChallengePassDisplayData