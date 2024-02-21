local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local WildDrawData = class("WildDrawData", BaseActivityData)

-- message WildDraw {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated WildDrawReward rewardList = 4;//奖励列表（牌面数据）
--     optional WildDrawBox box = 5;//宝箱
--     optional int32 freeTimes = 6;//免费次数
--     optional string key = 7;
--     optional string keyId = 8;
--     optional string price = 9;
--   }
function WildDrawData:parseData(_data)
    WildDrawData.super.parseData(self, _data)
    
    self.p_freeTimes = _data.freeTimes
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_rewardList = self:parseRewardData(_data.rewardList)
    self.p_box = self:parseBoxData(_data.box)
end

-- message WildDrawReward {
--     optional int64 coins = 1;
--     repeated ShopItem items = 2;
--     optional int32 type = 3;//0普通1wild
--   }
function WildDrawData:parseRewardData(_data)
    local rewardList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_coins = tonumber(v.coins)
            temp.p_type = v.type
            temp.p_items = self:parseItems(v.items)
            table.insert(rewardList, temp)
        end
    end
    return rewardList
end

-- message WildDrawBox {
--     optional int32 totalStage = 1; //总阶段
--     optional int32 currentStage = 2;//当前阶段
--     optional int64 coins = 3;
--     repeated ShopItem items = 4;
--   }
function WildDrawData:parseBoxData(_data)
    local boxData = nil
    if _data then 
        boxData = {}
        boxData.p_coins = tonumber(_data.coins)
        boxData.p_currentStage = _data.currentStage
        boxData.p_totalStage = _data.totalStage
        boxData.p_items = self:parseItems(_data.items)
    end
    return boxData
end

function WildDrawData:parseItems(_items)
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

function WildDrawData:getRewardList()
    return self.p_rewardList
end

function WildDrawData:getBoxData()
    return self.p_box
end

function WildDrawData:getKeyId()
    return self.p_keyId
end

function WildDrawData:getPrice()
    return self.p_price
end

function WildDrawData:getFreeItems()
    return self.p_freeTimes
end

return WildDrawData
