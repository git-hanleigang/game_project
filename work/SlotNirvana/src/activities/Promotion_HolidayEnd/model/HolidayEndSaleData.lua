--[[
    聚合挑战结束促销
]]

local BaseGameModel = require("GameBase.BaseGameModel")
local HolidayEndSaleData = class("HolidayEndSaleData", BaseGameModel)

function HolidayEndSaleData:ctor()
    HolidayEndSaleData.super.ctor(self)

    self.p_reference = G_REF.HolidayEnd
end

-- message ChristmasTourDeposit {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string key = 3; //付费Key
--     optional string keyId = 4; //付费标识
--     optional string price = 5; //价格
--     optional int32 points = 6; //多的点数
--     optional int64 originalCoins = 7; //基础金币
--     optional int32 discount = 8; //折扣
--     optional int64 coins = 9; //金币
--     optional bool pay = 10; //是否付费
--   }

function HolidayEndSaleData:parseData(data)
    self.m_expire = tonumber(data.expire)
    self.m_expireAt = tonumber(data.expireAt)
    self.m_keyId  = data.keyId     -- 付费点
    self.m_key    = data.key       -- 付费点
    self.m_price  = data.price     -- 价格
    self.m_freeCoins = tonumber(data.originalCoins)
    self.m_payCoins = tonumber(data.coins)
    self.m_discount = data.discount
    self.m_isPay = data.pay
end

function HolidayEndSaleData:getExpireAt()
    return (self.m_expireAt or 0) / 1000
end

function HolidayEndSaleData:getPrice()
    return self.m_price or 99.99
end

function HolidayEndSaleData:getFreeCoins()
    return self.m_freeCoins or 0
end

function HolidayEndSaleData:getPayCoins()
    return self.m_payCoins or 0
end

function HolidayEndSaleData:getDiscounts()
    return self.m_discount or 0
end

function HolidayEndSaleData:getBuyKey()
    return self.m_key
end

function HolidayEndSaleData:getPrice()
    return self.m_price
end

function HolidayEndSaleData:isRunning()
    if self:getExpireAt() > 0 then
        return self:getLeftTime() > 0
    else
        return false
    end
end

function HolidayEndSaleData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function HolidayEndSaleData:getKeyId()
    return self.m_keyId
end

function HolidayEndSaleData:isPay()
    return self.m_isPay
end

return HolidayEndSaleData
