local BaseActAndSale = require("baseActivity.BaseActAndSale")
local BaseActivityData = class("BaseActivityData", BaseActAndSale)

function BaseActivityData:ctor()
    BaseActivityData.super.ctor(self)
    -- 剩余时间
    self.p_expire = 0
    -- 到期时间
    self.p_expireAt = 0
end

-- 解析数据
function BaseActivityData:parseData(data)
    self.p_open = true
    self.data = data
    if not self.p_id then
        self.p_id = data.activityId
    end
    if data.activityName and data.activityName ~= "" and not self:getRefName() then
        -- 这是个特殊处理，因为服务器可能没发这个字段
        self:setRefName(data.activityName)
    end
    self.p_expire = tonumber(data.expire) or 0
    local _expireAt = tonumber(data.expireAt) or 0
    if _expireAt > 0 and tonumber(self.p_expireAt) <= 0 then
        self.p_expireAt = _expireAt
    end

    if data.rank then
        self:setRank(data.rank)
    end
    if data.rankUp then
        self:setRankUp(data.rankUp)
    end
end

-- 解析普通活动类数据，暂时从ActivityItemConfig拷贝
function BaseActivityData:parseNormalActivityData(data)
    for k, v in pairs(data) do
        if k ~= "class" then
            self[k] = v
        end
    end
end

function BaseActivityData:setOpenFlag(isOpen)
    self.p_open = isOpen
end

function BaseActivityData:getOpenFlag()
    return self.p_open
end

-- buff状态
function BaseActivityData:getBuffFlag()
    return false
end

function BaseActivityData:getData()
    return self.data
end

function BaseActivityData:getID()
    return self.p_id or ""
end

function BaseActivityData:getActivityID()
    return self.p_id or ""
end

function BaseActivityData:getType()
    return self.p_activityType
end

function BaseActivityData:getRank()
    return self.rank
end

function BaseActivityData:setRank(rank)
    self.rank = rank
end

function BaseActivityData:getRankUp()
    return self.rankUp
end

function BaseActivityData:setRankUp(rankUp)
    self.rankUp = rankUp
end

function BaseActivityData:getRankJackpotCoins()
    return self.rankJackPotCoins
end

function BaseActivityData:setRankJackpotCoins(coins)
    self.rankJackPotCoins = coins
end

function BaseActivityData:getRankCoins()
    return self.rankJackPotCoins
end

function BaseActivityData:isRunning()
    if not self:checkOpenLevel() then
        return false
    end

    if self:getOpenFlag() or self:getBuffFlag() then
        if self:isIgnoreExpire() then
            return true
        end

        if self:getExpireAt() > 0 then
            return self:getLeftTime() > 0
        else
            return false
        end
    else
        return false
    end
end

-- 是否忽略等级
function BaseActivityData:isIgnoreLevel()
    return globalData.constantData:checkIsIgnoreActLevel()
end

-- 检查开启等级
function BaseActivityData:checkOpenLevel()
    if self:isIgnoreLevel() then
        return true
    end

    local curLevel = globalData.userRunData.levelNum
    if not curLevel then
        return false
    end

    local needLevel = self:getOpenLevel()

    -- if not needLevel then
    --     printInfo("needLevel is nil!!!")
    -- end

    if curLevel >= needLevel then
        return true
    end

    return false
end

return BaseActivityData
