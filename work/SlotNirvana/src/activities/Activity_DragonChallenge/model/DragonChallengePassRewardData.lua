--[[
    
    author:{author}
    time:2023-08-28 22:47:29
]]
local ShopItem = require "data.baseDatas.ShopItem"
local DragonChallengePassRewardData = class("DragonChallengePassRewardData")

function DragonChallengePassRewardData:parseData(_data)
    self.p_level = tonumber(_data.level)
    self.p_params = tonumber(_data.params)
    self.p_collected = _data.collected
    self.p_type = _data.type
    self.p_coins = (_data.coinsV2 and _data.coinsV2 ~= "") and _data.coinsV2 or tonumber(_data.coins)
    self.p_items = self:parseItemsData(_data.items)
    --是否是高级奖励  1是高级奖励 0是低级奖励
    self.p_label = _data.label
    --奖励描述
    self.p_description = _data.description
end

function DragonChallengePassRewardData:parseItemsData(_items)
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

function DragonChallengePassRewardData:isCollected()
    return self.p_collected
end

function DragonChallengePassRewardData:getItems()
    return self.p_items
end

function DragonChallengePassRewardData:getParams()
    return self.p_params
end

function DragonChallengePassRewardData:getCoins()
    return self.p_coins
end

function DragonChallengePassRewardData:getLevel()
    return self.p_level
end

function DragonChallengePassRewardData:getDescription()
    return self.p_description
end

--是否为高级奖励
function DragonChallengePassRewardData:getIsPremiumReward()
    if self.p_label == "1" then
        return true
    else
        return false
    end
end

return DragonChallengePassRewardData
