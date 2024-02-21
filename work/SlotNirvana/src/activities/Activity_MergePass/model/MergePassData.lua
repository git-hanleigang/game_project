-- 合成pass

local ShopItem = require "data.baseDatas.ShopItem"
local BaseGameModel = require("GameBase.BaseGameModel")
local MergePassData = class("MergePassData", BaseGameModel)

-- message MergePass {
--     optional int64 expireAt = 1;//过期时间
--     optional int32 expire = 2;//剩余秒数
--     optional int32 totalPoints = 3;//总积分
--     optional int32 curPoints = 4;//当前积分
--     repeated MergePassReward payReward = 5;//付费奖励
--     repeated MergePassReward freeReward = 6;//免费奖励
--     optional bool payUnlocked = 7;//付费奖励解锁标识
--     optional string key = 8;
--     optional string keyId = 9;
--     optional string price = 10;
--     optional MergePassBox box = 11;//保险箱
--     optional string rewardValue = 12;//宣传图展示价值
--   }
function MergePassData:parseData(_data)
    self.p_expire = _data.expire
    self.p_expireAt = tonumber(_data.expireAt)
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_payUnlocked = _data.payUnlocked
    self.p_totalPoints = tonumber(_data.totalPoints)
    self.p_currentPoints = tonumber(_data.curPoints)
    self.p_rewardValue = _data.rewardValue

    self.p_payReward = self:parseRewardData(_data.payReward)
    self.p_freeReward = self:parseRewardData(_data.freeReward)
    self.p_boxData = self:parseBoxData(_data.box)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MERGE_PASS_UPDATE_DATA)
end

-- message MergePassReward {
--     optional int32 level = 1;//等级
--     optional int32 points = 2;//所需积分
--     optional bool collected = 3;
--     optional string coins = 4;
--     repeated ShopItem items = 5;
--     optional bool keyReward = 6;//是否展示高级奖励
--   }
function MergePassData:parseRewardData(_data)
    local reward = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local info = {}
            info.p_level = v.level
            info.p_points = tonumber(v.points)
            info.p_coins = tonumber(v.coins)
            info.p_collected = v.collected
            info.p_keyReward = v.keyReward
            info.p_items = self:parseItemData(v.items)
            table.insert(reward, info)
        end
    end
    return reward
end 

-- message MergePassBox {
--     optional string coins = 1;
--     repeated ShopItem items = 2;
--     optional int32 totalPoints = 3;//总积分
--     optional int32 curPoints = 4;//当前积分
--   }
function MergePassData:parseBoxData(_data)
    local reward = {}
    if _data then 
        reward.p_totalPoints = tonumber(_data.totalPoints)
        reward.p_curPoints = tonumber(_data.curPoints)
        reward.p_coins = tonumber(_data.coins)
        reward.p_items = self:parseItemData(_data.items)
    end
    return reward
end

function MergePassData:parseItemData(_items)
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

function MergePassData:getCanCollectCount()
    local count = 0
    for i,v in ipairs(self.p_freeReward) do
        if v.p_points <= self.p_currentPoints and not v.p_collected then
            count = count + 1
        end
    end

    if self.p_payUnlocked then
        for i,v in ipairs(self.p_payReward) do
            if v.p_points <= self.p_currentPoints and not v.p_collected then
                count = count + 1
            end
        end
    end

    if self.p_boxData.p_curPoints >= self.p_boxData.p_totalPoints then
        count = count + math.floor(self.p_boxData.p_curPoints / self.p_boxData.p_totalPoints)
    end

    return count
end

function MergePassData:getFreeReward()
    return self.p_freeReward
end

function MergePassData:getPayReward()
    return self.p_payReward
end

function MergePassData:getCurPoints()
    return self.p_currentPoints
end 

function MergePassData:getTotalPoints()
    return self.p_totalPoints
end

function MergePassData:getPayUnlocked()
    return self.p_payUnlocked
end 

function MergePassData:getKeyId()
    return self.p_keyId
end

function MergePassData:getPrice()
    return self.p_price
end

function MergePassData:getBoxData()
    return self.p_boxData
end

function MergePassData:getTotalUsd()
    return (self.p_rewardValue and self.p_rewardValue ~= "") and self.p_rewardValue or 0
end

function MergePassData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function MergePassData:getTableUseData()
    local viewData = {}
    viewData[#viewData + 1] = {
        occupied = true
    }
    for i = 1, #self.p_freeReward do
        local data = {}
        local freeReward = self.p_freeReward[i]
        local payReward = self.p_payReward[i]
        data.free = freeReward
        data.pay = payReward
        data.curExp = self.p_currentPoints
        data.payUnlocked = self.p_payUnlocked
        viewData[#viewData + 1] = data
    end

    viewData[#viewData + 1] = {
        box = self.p_boxData,
        curExp = self.p_currentPoints,
        totalExp = self.p_totalPoints,
        payUnlocked = self.p_payUnlocked
    }

    return viewData
end

function MergePassData:isGetAllReward()
    local lastReward = self.p_freeReward[#self.p_freeReward]
    local flag = false
    if lastReward.p_points <= self.p_currentPoints then
        flag = true
    end

    return flag
end

function MergePassData:getAllCanCollectReward()
    local data = {}
    local coins = 0
    local items = {}
    for i,v in ipairs(self.p_freeReward) do
        if v.p_points <= self.p_currentPoints and not v.p_collected then
           coins = coins + (v.p_coins or 0)
           table.insertto(items, clone(v.p_items))
        end
    end

    if self.p_payUnlocked then
        for i,v in ipairs(self.p_payReward) do
            if v.p_points <= self.p_currentPoints and not v.p_collected then
                coins = coins + (v.p_coins or 0)
                table.insertto(items, clone(v.p_items))
            end
        end
    end

    data.p_coins = coins
    data.p_items = items
    data.p_level = -1

    return data
end

function MergePassData:getPassInfoByIndex(_index)
    local passPointsInfo = self:getTableUseData()
    if _index and #passPointsInfo > 0 then
        return passPointsInfo[_index + 1]
    end
    return nil
end

function MergePassData:getPreviewList()
    local list = {}
    for i,v in ipairs(self.p_freeReward) do
        if v.p_keyReward then
            table.insert(list, i)
        end
    end

    return list
end

return MergePassData
