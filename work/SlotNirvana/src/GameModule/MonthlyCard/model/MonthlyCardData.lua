--[[
    月卡 数据层
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseGameModel = require("GameBase.BaseGameModel")
local MonthlyCardData = class("MonthlyCardData", BaseGameModel)

--[[
    message MonthlyCard {
        optional int32 openLevel = 1;//开启等级
        optional bool unlock = 2;//是否解锁
        optional MonthlyCardInfo standard = 3;//标准版
        optional MonthlyCardInfo deluxe = 4;//豪华版
        optional int32 maxDays = 5;//累积天数上限
    }
]]
function MonthlyCardData:parseData(_data)
    self.p_openLevel = _data.openLevel
    self.p_unlock = _data.unlock
    self.p_standard = self:parseMonthlyCardInfo(_data.standard)
    self.p_deluxe = self:parseMonthlyCardInfo(_data.deluxe)
    self.p_maxDays = tonumber(_data.maxDays)
    self.p_buyType = "" --standard 标准版  deluxe 豪华版
end

--[[
    message MonthlyCardInfo {
        optional string key = 1;
        optional string keyId = 2;
        optional string price = 3;
        optional int64 coins = 4;//购买后立即领取-金币
        optional int64 gems = 5;//购买后立即领取-第二货币
        optional int64 dailyCoins = 6;//每日奖励-金币
        optional int64 dailyGems = 7;//每日奖励-第二货币
        repeated MonthlyCardInterests interestsList = 8;//权益
        optional int64 expireAt = 9;//过期时间戳
        optional bool buy = 10;//是否购买
        optional bool collect = 11;//是否领取每日奖励
        optional int32 discount = 12;// 降档折扣
    }
]]
function MonthlyCardData:parseMonthlyCardInfo(_data)
    local tempData = {}
    if _data then
        tempData.key = _data.key
        tempData.keyId = _data.keyId
        tempData.price = _data.price
        tempData.coins = tonumber(_data.coins)
        tempData.gems = tonumber(_data.gems)
        tempData.dailyCoins = tonumber(_data.dailyCoins)
        tempData.dailyGems = tonumber(_data.dailyGems)
        tempData.interestsList = self:parseInterestsList(_data.interestsList)
        tempData.expireAt = tonumber(_data.expireAt) / 1000
        tempData.buy = _data.buy
        tempData.collect = _data.collect
        tempData.discount = tonumber(_data.discount)
    end
    return tempData
end

--[[
    message MonthlyCardInterests {
        optional string type = 1;//权益类型 COUPON/CASH/PASS/ARENA/SEND_COIN/SHARK/SEND_CARD
        optional string value = 2;
        repeated ShopItem items = 3;//COUPON专用
        optional int32 openLevel = 4;//对应功能开启等级
        optional bool unlock = 5;//是否解锁对应功能
    }
]]
function MonthlyCardData:parseInterestsList(_data)
    local tempList = {}
    if _data then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.type = v.type
            tempData.value = v.value
            tempData.items = self:parseItems(v.items)
            tempData.openLevel = tonumber(v.openLevel)
            tempData.unlock = v.unlock
            table.insert(tempList, tempData)
        end
    end
    return tempList
end

function MonthlyCardData:parseItems(_items)
    local tempData = {}
    if _items and #_items > 0 then
        for i, v in ipairs(_items) do
            local temp = ShopItem:create()
            temp:parseData(v)
            table.insert(tempData, temp)
        end
    end
    return tempData
end

-- 根据类型获取数据
function MonthlyCardData:getInfoByType(_type)
    if type(_type) == "string" then
        if _type == "standard" or _type == "normal" then --标准版
            return self.p_standard
        elseif _type == "deluxe" or _type == "deluexe" then --豪华版
            return self.p_deluxe
        end
    elseif type(_type) == "number" then
        if _type == 1 then --标准版
            return self.p_standard
        elseif _type == 2 then --豪华版
            return self.p_deluxe
        end
    end
    return self.p_standard
end

-- 根据类型获取权益
function MonthlyCardData:getInterestsListByType(_type)
    local info = self:getInfoByType(_type)
    return info.interestsList or {}
end

-- 根据类型获取权益值(权益类型 COUPON/CASH/PASS/ARENA/SEND_COIN/SHARK/SEND_CARD)
function MonthlyCardData:getInterestsValueByType(_type, _bonusType)
    local isUnlock = true
    local openLevel = 0
    local value = ""
    local list = self:getInterestsListByType(_type)
    for i, v in ipairs(list) do
        local type = v.type
        if _bonusType == type then
            isUnlock = v.unlock
            openLevel = v.openLevel
            value = v.value
            if type == "PASS" or type == "ARENA" then
                value = "" .. tonumber(value) * 100
            elseif type == "COUPON" then
                value = ""
            elseif type == "CASH" then
                value = ""
            end
        end
    end
    return value, isUnlock, openLevel
end

-- 月卡购买最大天数
function MonthlyCardData:getMaxDays()
    return self.p_maxDays or 60
end

-- 获得比赛加成
function MonthlyCardData:getLeagueAddition()
    local addition = 1
    local isBuyMonthlyCardDeluxe = self:isBuyMonthlyCardDeluxe()
    if isBuyMonthlyCardDeluxe then
        if self.p_deluxe then
            for i, v in ipairs(self.p_deluxe.interestsList) do
                if v.type == "ARENA" then
                    addition = addition + tonumber(v.value)
                end
            end
        end
    end
    return addition
end

-- 获得Pass积分加成
function MonthlyCardData:getPassAddition()
    local addition = 1
    local isBuyMonthlyCardNormal = self:isBuyMonthlyCardNormal()
    if isBuyMonthlyCardNormal then
        if self.p_standard then
            for i, v in ipairs(self.p_standard.interestsList) do
                if v.type == "PASS" then
                    addition = addition + tonumber(v.value)
                end
            end
        end
    end
    return addition
end

-- 获得送金币 or 卡次数（type = "COIN" or "CARD"）
function MonthlyCardData:getSendNumsByType(type)
    local num = 0
    local isBuyMonthlyCardNormal = self:isBuyMonthlyCardNormal()
    if isBuyMonthlyCardNormal then
        if self.p_standard then
            for i, v in ipairs(self.p_standard.interestsList) do
                if v.type == "SEND_" .. type then
                    num = num + tonumber(v.value)
                end
            end
        end
    end
    return num
end

-- 是否有奖励可领取(return isHasReward--是否有奖励领取, redPoint--奖励个数)
function MonthlyCardData:isHasReward()
    local num = 0
    local isStandardCollect = self:isHasRewardNormal()
    local isDeluxeCollect = self:isHasRewardDeluxe()
    if isStandardCollect then
        num = num + 1
    end
    if isDeluxeCollect then
        num = num + 1
    end
    return (isStandardCollect or isDeluxeCollect), num
end

-- 是否普通版有奖励领取
function MonthlyCardData:isHasRewardNormal()
    local standardData = self.p_standard
    local isStandardCollect = false
    if standardData then
        isStandardCollect = standardData.buy and (not standardData.collect)
    end
    return isStandardCollect
end

-- 是否豪华版有奖励领取
function MonthlyCardData:isHasRewardDeluxe()
    local deluxeData = self.p_deluxe
    local isDeluxeCollect = false
    if deluxeData then
        isDeluxeCollect = deluxeData.buy and (not deluxeData.collect)
    end
    return isDeluxeCollect
end

-- 是否购买普通版
function MonthlyCardData:isBuyMonthlyCardNormal()
    local standardData = self.p_standard
    local isBuy = false
    if standardData then
        isBuy = standardData.buy
    end
    return isBuy
end

-- 是否购买豪华版
function MonthlyCardData:isBuyMonthlyCardDeluxe()
    local deluxeData = self.p_deluxe
    local isBuy = false
    if deluxeData then
        isBuy = deluxeData.buy
    end
    return isBuy
end

-- 检查开启等级
function MonthlyCardData:checkOpenLevel()
    if self:isIgnoreLevel() then
        return true
    end

    local curLevel = globalData.userRunData.levelNum
    if not curLevel then
        return false
    end

    local needLevel = self:getOpenLevel()

    if curLevel >= needLevel then
        return true
    end

    return false
end

function MonthlyCardData:isRunning()
    if not self:checkOpenLevel() then
        return false
    end
    local standard = self.p_standard
    local deluxe = self.p_deluxe
    return table.nums(standard) > 0 and table.nums(deluxe) > 0
end

return MonthlyCardData
