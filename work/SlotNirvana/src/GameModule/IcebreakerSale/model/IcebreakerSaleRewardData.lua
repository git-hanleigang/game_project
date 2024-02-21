--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-30 20:00:53
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-30 20:04:45
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/model/IcebreakerSaleRewardData.lua
Description: 新破冰促销 奖励数据
--]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local IcebreakerSaleRewardData = class("IcebreakerSaleRewardData")
  
--   message IceBrokenSaleReward {
--     optional int64 collectAt = 1;//可领取时间
--     optional int32 day = 2;//第几天
--     optional bool collect = 3;//是否领取
--     optional int64 coins = 4;//奖励金币
--     repeated ShopItem items = 5;//奖励物品
--   }
function IcebreakerSaleRewardData:parseData(_data, _pos)
    self.m_collectAt = tonumber(_data.collectAt) or 0 -- 可领取时间
    self.m_day = _data.day -- 第几天
    self.m_bCollect = _data.collect -- 是否领取
    self.m_coins = tonumber(_data.coins) or 0 -- 奖励金币
    self.m_pos = _pos

    self.m_itemList = {} -- 物品奖励
    self.m_itemNoCoinsList = {} -- 物品奖励 不带金币
    if self.m_coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self.m_coins, 6))
        table.insert(self.m_itemList, itemData)
    end
    for k, data in ipairs(_data.items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self.m_itemList, shopItem)
        table.insert(self.m_itemNoCoinsList, shopItem)
    end

end

function IcebreakerSaleRewardData:getPosition()
    return self.m_pos or 0
end

-- 获取金币
function IcebreakerSaleRewardData:getCoins()
    return self.m_coins or 0
end

-- 获取物品奖励
function IcebreakerSaleRewardData:getItemList()
    return self.m_itemList or {}
end

-- 获取物品奖励 不带金币
function IcebreakerSaleRewardData:getItemNoCoinsList()
    return self.m_itemNoCoinsList or {}
end

-- 可领取时间
function IcebreakerSaleRewardData:getColTimeAt()
    return self.m_collectAt or 0
end

-- 第几天
function IcebreakerSaleRewardData:getDay()
    return self.m_day
end

-- 是否领取
function IcebreakerSaleRewardData:checkHadCollected()
    return self.m_bCollect
end

-- 检查是否可领取
function IcebreakerSaleRewardData:checkCanCollect()
    if self:checkHadCollected() then
        return false
    end

    local colAt = self:getColTimeAt()
    local curTime = util_getCurrnetTime()
    return curTime >= math.floor(colAt*0.001)
end

function IcebreakerSaleRewardData:setColSate()
    self.m_bCollect = true
end

return IcebreakerSaleRewardData