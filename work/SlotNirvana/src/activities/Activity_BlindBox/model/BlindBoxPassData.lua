--[[
    
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BlindBoxPassData = class("BlindBoxPassData")

-- message BlindBoxPass {
--     repeated BlindBoxPassPointData points = 1; //奖励数据
--     optional bool unlocked = 2; //是否付费解锁pass
--     optional string key = 3;//pass价格
--     optional string price = 4;//pass档位
--     optional string keyId = 5;
--     optional int32 curPoint = 6;//当前点数
--     optional bool open = 7; //开关
--   }
function BlindBoxPassData:parseData(_data)
    self.p_unlocked = _data.unlocked
    self.p_key = _data.key
    self.p_price = _data.price
    self.p_keyId = _data.keyId
    self.p_curPoint = _data.curPoint
    self.p_open = _data.open
    self.p_reward = self:parseListData(_data.points)
end

-- message BlindBoxPassPointData {
--     optional int32 points = 1; //一个阶段的目标值
--     optional BlindBoxPassRewardData freeReward = 2;//免费的奖励
--     optional BlindBoxPassRewardData payReward = 3;//付费的奖励
--   }
function BlindBoxPassData:parseListData(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_points = v.points
            temp.p_freeReward = self:parseReward(v.freeReward)
            temp.p_payReward = self:parseReward(v.payReward)
            table.insert(list, temp)
        end
    end
    return list
end

-- message BlindBoxPassRewardData {
--     optional string type = 1; //奖励类型
--     optional string coins = 2; //玩家的美金奖励
--     repeated ShopItem items = 3;//玩家道具奖励
--     optional bool collected = 4;//表明玩家已经领取
--   }
function BlindBoxPassData:parseReward(_data)
    local reward = {}
    if _data  then 
        reward.p_type = _data.type
        reward.p_coins = _data.coins
        reward.p_collected = _data.collected
        reward.p_items = self:parseItems(_data.items)
    end
    return reward
end

function BlindBoxPassData:parseItems(_items)
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

function BlindBoxPassData:getCurPoints()
    return self.p_curPoint
end

function BlindBoxPassData:getKey()
    return self.p_key
end

function BlindBoxPassData:getKeyId()
    return self.p_keyId
end

function BlindBoxPassData:getPrice()
    return self.p_price
end

function BlindBoxPassData:getUnlocked()
    return self.p_unlocked
end

function BlindBoxPassData:getRewardData()
    return self.p_reward
end

function BlindBoxPassData:getOpen()
    return self.p_open
end

function BlindBoxPassData:getCanCollectCount()
    local count = 0
    for i,v in ipairs(self.p_reward) do
        if v.p_points <= self.p_curPoint and not v.p_collected then
            if not v.p_freeReward.p_collected then
                count = count + 1
            end

            if not v.p_payReward.p_collected and self.p_unlocked then
                count = count + 1
            end
        end
    end

    return count
end

function BlindBoxPassData:isGetAllReward()
    local flag = true
    for i,v in ipairs(self.p_reward) do
        if not v.p_freeReward.p_collected then
            flag = false
            break
        end

        if not v.p_payReward.p_collected then
            flag = false
            break
        end
    end

    return flag
end

return BlindBoxPassData