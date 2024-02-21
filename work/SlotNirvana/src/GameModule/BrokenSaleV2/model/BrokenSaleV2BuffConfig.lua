local BrokenSaleV2BuffConfig = class("BrokenSaleV2BuffConfig")


function BrokenSaleV2BuffConfig:ctor()
    self.p_buffCoins = toLongNumber(0)
    self.p_buffCoinsLimit = toLongNumber(0)
end

--[[
    message GoBrokeSaleBuff {
        optional int32 state = 1; // 状态: 1.生效中 0.未激活
        optional string multiple = 2; // 倍数
        optional int64 count = 3; // 剩余次数
        optional string buffCoins = 4; // buff已收集金币
        optional string buffCoinsLimit = 5; // buff收集金币上限
    }
]]
function BrokenSaleV2BuffConfig:parseData(data)
    self.p_state = data.state
    self.p_multiple = tonumber(data.multiple)
    self.p_count = tonumber(data.count)
    self.p_buffCoins:setNum(data.buffCoins)
    self.p_buffCoinsLimit:setNum(data.buffCoinsLimit)
end

function BrokenSaleV2BuffConfig:parseSpinData(data)
    self.p_multiple = tonumber(data.multiple)
    self.p_count = tonumber(data.count)
    self.p_buffCoins:setNum(data.buffCoins)
    self.p_buffCoinsLimit:setNum(data.buffCoinsLimit)
end

-- 1.生效中 0.未激活
function BrokenSaleV2BuffConfig:getState()
    return self.p_state or 0
end

function BrokenSaleV2BuffConfig:getMultiple()
    local multiple = self.p_multiple or 0
    multiple = math.max(multiple - 1, 0)
    return multiple * 100
end

function BrokenSaleV2BuffConfig:getCount()
    return self.p_count or 0
end

function BrokenSaleV2BuffConfig:getBuffCoins()
    return self.p_buffCoins
end

function BrokenSaleV2BuffConfig:getBuffCoinsLimit()
    return self.p_buffCoinsLimit
end

-- 是否激活
function BrokenSaleV2BuffConfig:isActive()
    return self:getState() == 1
end

-- 是否能够领奖
function BrokenSaleV2BuffConfig:isCanCollect()
    if self:isActive() and self:getBuffCoins() > toLongNumber(0) then
        return self:getBuffCoins() >= self:getBuffCoinsLimit()
    end
    return false
end

-- 是否spin次数用完
function BrokenSaleV2BuffConfig:isNotSpinNum()
    if self:isActive() and self:getCount() <= 0 then
        return true
    end
    return false
end

-- buff完成
function BrokenSaleV2BuffConfig:isComplete()
    if self:isCanCollect() then
        return true
    end
    if self:isNotSpinNum() then
        return true
    end
    return false
end

return BrokenSaleV2BuffConfig