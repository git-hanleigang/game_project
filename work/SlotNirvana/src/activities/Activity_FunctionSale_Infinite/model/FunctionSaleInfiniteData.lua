-- 无限促销

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local FunctionSaleInfiniteData = class("FunctionSaleInfiniteData", BaseActivityData)

-- message FunctionSaleInfinite {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional string activityCommonType = 4; //小活动类型
--     repeated FunctionSaleInfiniteReward rewardList = 5;//奖励列表
--   }
function FunctionSaleInfiniteData:parseData(_data)
    FunctionSaleInfiniteData.super.parseData(self, _data)

    self.p_rewardList = self:parseRewardList(_data.rewardList)
end

-- message FunctionSaleInfiniteReward {
--     optional int32 index = 1;
--     optional bool ifPay = 2;//免费付费
--     optional string type = 3;//奖励类型
--     optional string coins = 4;
--     repeated ShopItem items = 5;
--     optional string key = 6;
--     optional string keyId = 7;
--     optional string price = 8;
--     optional bool collected = 9;//是否领取
--   }
function FunctionSaleInfiniteData:parseRewardList(_data)
    local reward = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local info = {}
            info.p_index = v.index
            info.p_isPay = v.ifPay
            info.p_type = v.type
            info.p_key = v.key
            info.p_keyId = v.keyId
            info.p_price = v.price
            info.p_collected = v.collected
            info.p_coins = tonumber(v.coins)
            info.p_items = self:parseItemData(v.items)

            if info.p_coins and info.p_coins > 0 then
                local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
                itemData:setTempData({p_limit = 3})
                table.insert(info.p_items, itemData)
            end

            table.insert(reward, info)
        end
    end
    return reward
end 

function FunctionSaleInfiniteData:parseItemData(_items)
    -- 通用道具
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

function FunctionSaleInfiniteData:getRewardList()
    return self.p_rewardList
end 

return FunctionSaleInfiniteData
