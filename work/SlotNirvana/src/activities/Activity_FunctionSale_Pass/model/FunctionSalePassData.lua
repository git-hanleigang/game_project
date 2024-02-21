-- 大活动PASS

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local FunctionSalePassData = class("FunctionSalePassData", BaseActivityData)

-- message FunctionSalePass {
--     optional string activityId = 1;//活动id
--     optional int64 expireAt = 2;//过期时间
--     optional int32 expire = 3;//剩余秒数
--     optional int32 totalExp = 4;//总经验
--     optional int32 curExp = 5;//经验
--     repeated FunctionSalePassReward payReward = 6;//付费奖励
--     repeated FunctionSalePassReward freeReward = 7;//免费奖励
--     optional bool payUnlocked = 8;//付费奖励解锁标识
--     optional string key = 9;
--     optional string keyId = 10;
--     optional string price = 11;
--     optional string activityCommonType = 12; //小活动类型
--   }
function FunctionSalePassData:parseData(_data)
    FunctionSalePassData.super.parseData(self, _data)

    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_payUnlocked = _data.payUnlocked
    self.p_totalExp = tonumber(_data.totalExp)
    self.p_curExp = tonumber(_data.curExp)

    self.p_payReward = self:parseRewardData(_data.payReward)
    self.p_freeReward = self:parseRewardData(_data.freeReward)

    self:updateSelectItem()

    if self.m_lastExp then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FUNCTION_SALE_PASS_UPDATE, self.p_curExp - self.m_lastExp)
    end

    if not self.m_lastShowLevel then
        self.m_lastShowLevel = self:getCompleteLevel()
    end

    self.m_lastExp = self.p_curExp
end

-- message FunctionSalePassReward {
--     optional int32 level = 1;//等级
--     optional int32 exp = 2;//所需经验
--     optional bool collected = 3;
--     optional string coins = 4;
--     repeated ShopItem items = 5;
--     optional string description = 6;//奖励描述
--   }
function FunctionSalePassData:parseRewardData(_data)
    local reward = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local info = {}
            info.p_level = v.level
            info.p_exp = v.exp
            info.p_coins = tonumber(v.coins) or 0
            info.p_collected = v.collected
            info.p_description = v.description
            info.p_items = self:parseItemData(v.items)
            info.p_needSelect = #info.p_items > 1
            info.p_selectIndex = 0
            table.insert(reward, info)
        end
    end
    return reward
end 

function FunctionSalePassData:updateSelectItem()
    local taData = gLobalDataManager:getStringByField("FunctionSalePassInfo", "{}")
    local seveInfo = util_cjsonDecode(taData) or {}
    local saveTime = gLobalDataManager:getNumberByField("FunctionSalePassTime", 0)
    local expireAt = self.p_expireAt
    if expireAt > saveTime then 
        seveInfo = {}
        gLobalDataManager:setNumberByField("FunctionSalePassTime", expireAt)
    end

    for i,v in ipairs(seveInfo) do
        local level = v.level
        local type = v.type
        local index = v.index
        if type == "free" then
            local data = self.p_freeReward[level] or {}
            data.p_selectIndex = index
        else
            local data = self.p_payReward[level] or {}
            data.p_selectIndex = index
        end
    end
end

function FunctionSalePassData:saveSelectIdx(_type, _level, _idx)
    if _type == "free" then
        local rewards = self.p_freeReward
        local rewardData = rewards[_level]
        rewardData.p_selectIndex = _idx
    else
        local rewards = self.p_payReward
        local rewardData = rewards[_level]
        rewardData.p_selectIndex = _idx
    end

    local taData = gLobalDataManager:getStringByField("FunctionSalePassInfo", "{}")
    local seveInfo = util_cjsonDecode(taData) or {}
    local sFlag = true
    for i,v in ipairs(seveInfo) do
        if v.level == _level and v.type == _type then
            sFlag = false
            v.index = _idx
            break
        end
    end

    if sFlag then
        local temp = {
            level = _level,
            type = _type,
            index = _idx
        }
        table.insert(seveInfo, temp)
    end

    local strInfo = cjson.encode(seveInfo)
    gLobalDataManager:setStringByField("FunctionSalePassInfo", strInfo)
end

function FunctionSalePassData:parseItemData(_items)
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

function FunctionSalePassData:getCanCollectCount()
    local count = 0
    for i,v in ipairs(self.p_freeReward) do
        if v.p_exp <= self.p_curExp and not v.p_collected then
            count = count + 1
        end
    end

    if self.p_payUnlocked then
        for i,v in ipairs(self.p_payReward) do
            if v.p_exp <= self.p_curExp and not v.p_collected then
                count = count + 1
            end
        end
    end

    return count
end

function FunctionSalePassData:getCompleteLevel()
    local level = 0

    for i,v in ipairs(self.p_freeReward) do
        if v.p_exp <= self.p_curExp then
            level = i
        else
            break
        end
    end

    return level, level == #self.p_freeReward
end

function FunctionSalePassData:getShwoProgressData()
    local data = {}
    data.level = 0
    data.curExp = 1
    data.totalExp = 1
    data.lastExp = 0
    data.allReward = true

    for i,v in ipairs(self.p_freeReward) do
        if v.p_exp <= self.p_curExp then
            data.curExp = self.p_curExp - data.lastExp
            data.totalExp = v.p_exp - data.lastExp
            data.level = i
            data.lastExp = v.p_exp
        else
            data.curExp = self.p_curExp - data.lastExp
            data.totalExp = v.p_exp - data.lastExp
            data.allReward = false
            break
        end
    end

    return data
end

function FunctionSalePassData:getPayRewardItems()
    local items = {}
    local coins = 0
    for i,v in ipairs(self.p_payReward) do
        coins = coins + v.p_coins
        for i2,v2 in ipairs(v.p_items) do
            local item = clone(v2)
            table.insert(items, item) 
        end
    end

    local mergeItems = self:mergeItems(items)
    return {coins = coins, items = mergeItems}
end

function FunctionSalePassData:mergeItems(_data)
    local items = {}
    local temp = {}

    for i, v in ipairs(_data) do
        local key = v.p_icon
        local itemInfo = temp[key]
        if itemInfo then
            if v.p_type == "Buff" then
                itemInfo.p_buffInfo.buffExpire = itemInfo.p_buffInfo.buffExpire + v.p_buffInfo.buffExpire
            else
                itemInfo.p_num = itemInfo.p_num + v.p_num
            end
        else
            temp[key] = v
        end
    end

    for i, v in pairs(temp) do
        table.insert(items, v)
    end

    return items
end

function FunctionSalePassData:getLastShowLevel()
    return self.m_lastShowLevel or 0
end

function FunctionSalePassData:setLastShowLevel()
    self.m_lastShowLevel = self:getCompleteLevel()
end

function FunctionSalePassData:getFreeReward()
    return self.p_freeReward
end

function FunctionSalePassData:getPayReward()
    return self.p_payReward
end

function FunctionSalePassData:getCurExp()
    return self.p_curExp
end 

function FunctionSalePassData:getTotalExp()
   return self.p_totalExp 
end

function FunctionSalePassData:getPayUnlocked()
    return self.p_payUnlocked
end 

function FunctionSalePassData:getKeyId()
    return self.p_keyId
end

function FunctionSalePassData:getPrice()
    return self.p_price
end

return FunctionSalePassData
