--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-27 17:26:17
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-27 17:28:35
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/model/IcebreakerSaleData.lua
Description: 新破冰促销 数据
--]]
local IcebreakerSaleRewardData = util_require("GameModule.IcebreakerSale.model.IcebreakerSaleRewardData")
local IcebreakerSaleData = class("IcebreakerSaleData")

-- message IceBrokenSale {
--     optional bool pay = 1;//是否付费
--     optional string key = 2;//支付相关
--     optional string keyId = 3;//支付相关
--     optional string price = 4;//支付相关
--     optional int32 discount = 5;//显示折扣
--     repeated IceBrokenSaleReward rewards = 6;//等级奖励
        -- optional int32 expire = 7;
        -- optional int64 expireAt = 8;
--   }
function IcebreakerSaleData:parseData(_data)
    self.m_bPay = _data.pay -- 是否付费
    self.m_key = _data.key -- 支付相关
    self.m_keyId = _data.keyId -- 支付相关
    self.m_price = _data.price -- 支付相关
    self.m_discount = _data.discount -- 显示折扣
    self.m_expireAt = tonumber( _data.expireAt) or util_getCurrnetTime() * 1000
    if self.m_bPay then
        self.m_expireAt = self.m_expireAt + 100 * 86400000
    end
    self:parseRewardList(_data.rewards)
end

function IcebreakerSaleData:parseRewardList(_list)
    self.m_rewardList = {} -- 等级奖励
    self.m_bOver = #_list ~= 3
    for i=1, #_list do
        local rewardData = IcebreakerSaleRewardData:create()
        local serverData = _list[i]
        rewardData:parseData(serverData, i-1)
        table.insert(self.m_rewardList, rewardData)

        if i == #_list then
            self.m_bOver = rewardData:checkHadCollected()
        end
    end
end

-- 支付相关 是否付费
function IcebreakerSaleData:checkHadPay()
    return self.m_bPay
end
-- 支付相关 key
function IcebreakerSaleData:getKey()
    return self.m_key or ""
end
-- 支付相关 keyId
function IcebreakerSaleData:getKeyId()
    return self.m_keyId or ""
end
-- 获取价格
function IcebreakerSaleData:getPrice()
    return self.m_price or ""
end
-- 获取价格
function IcebreakerSaleData:getDiscount()
    return self.m_discount or 0
end
-- 获取道具
function IcebreakerSaleData:getRewardList()
    return self.m_rewardList or {}
end
function IcebreakerSaleData:getExpireAt()
    return self.m_expireAt
end

function IcebreakerSaleData:isRunning()
    if self.m_bOver then
        return false
    end

    local rewardList = self:getRewardList()
    return #rewardList == 3
end

function IcebreakerSaleData:checkCanCollectList()
    if not self.m_bPay then
        return {}
    end

    local list = {}
    for i=1, #self.m_rewardList do
        local rewardData = self.m_rewardList[i]
        local bCanCol = rewardData:checkCanCollect()
        if bCanCol then
            table.insert(list, rewardData)
        end
    end

    return list
end

function IcebreakerSaleData:setSaleDataOver()
    self.m_bOver = true
    for i=1, #self.m_rewardList do
        local rewardData = self.m_rewardList[i]
        rewardData:setColSate()
    end
end

function IcebreakerSaleData:checkTimeOut()
    if self.m_expireAt then
        return util_getCurrnetTime()*1000 > self.m_expireAt
    end

    return true
end
return IcebreakerSaleData