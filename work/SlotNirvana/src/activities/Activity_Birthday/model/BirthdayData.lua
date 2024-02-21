--[[
    生日 数据层
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActAndSale = require("baseActivity.BaseActAndSale")
local BirthdayData = class("BirthdayData", BaseActAndSale)

function BirthdayData:ctor()
    BirthdayData.super.ctor(self)
    self.p_birthdayInformation = {}
    self.p_birthdaySale = {}
    self:setIgnoreExpire(true)
end

--[[
    message Birthday {
        optional BirthdayInformation birthdayInformation = 1;
        optional BirthdaySale birthdaySale = 2;
    }
]]
function BirthdayData:parseData(_data)
    self.p_birthdayInformation = self:parseBirthdayInformation(_data.birthdayInformation)
    self.p_birthdaySale = self:parseBirthdaySale(_data.birthdaySale)
end

--[[
    message BirthdayInformation {
        optional string birthdayDate = 1; //生日日期 20230517
        optional string updateDate = 2; // 最近修改时间 20230518
        optional int32 birthdayState = 3; //当天是否是生日 0,1
        optional int32 collectState = 4; // 生日当天是否收集,0-未领取，1-已领取
        optional int64 coins = 5;
        repeated ShopItem item = 6;
    }
]]
function BirthdayData:parseBirthdayInformation(_data)
    local tempData = {}
    if _data then
        tempData.birthdayDate = _data.birthdayDate or ""
        tempData.updateDate = _data.updateDate or ""
        tempData.birthdayState = tonumber(_data.birthdayState or 0)
        tempData.collectState = _data.collectState or 0
        tempData.coins = tonumber(_data.coins or 0)
        tempData.item = self:parseItems(_data.item)
    end
    return tempData
end

--[[
    message BirthdaySale {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional int64 coins = 4;
        optional int32 discount = 5;//100
        optional string key = 6;
        optional string keyId = 7;
        optional string price = 8;
        repeated ShopItem item = 9;
        optional int32 leftTimes = 10; //剩余次数 1-0
    }
]]
function BirthdayData:parseBirthdaySale(_data)
    local tempData = {}
    if _data then
        tempData.p_activityId = _data.activityId or ""
        tempData.p_expireAt = tonumber(_data.expireAt or 0)
        tempData.p_expire = tonumber(_data.expire or 0)
        tempData.p_coins = tonumber(_data.coins or 0)
        tempData.p_discount = tonumber(_data.discount or 0)
        tempData.p_key = _data.key or ""
        tempData.p_keyId = _data.keyId or ""
        tempData.p_price = _data.price or ""
        tempData.p_item = self:parseItems(_data.item)
        tempData.p_leftTimes = tonumber(_data.leftTimes or 0)
    end
    return tempData
end

function BirthdayData:parseItems(_items)
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

-- 生日信息数据
function BirthdayData:getBirthdayInformation()
    return self.p_birthdayInformation
end

-- 促销数据
function BirthdayData:getBirthdaySaleData()
    return self.p_birthdaySale
end

function BirthdayData:getSaleExpirAt()
    local saleData = self:getBirthdaySaleData()
    if saleData and saleData.p_expireAt then
        return saleData.p_expireAt or 0
    end
    return 0
end

-- 是否有促销数据
function BirthdayData:isBirthdaySaleData()
    local isBirthdaySaleData = false
    if self:isBirthdayDay() then
        if self:getSaleExpirAt() > 0 then
            isBirthdaySaleData = true
        end
    end
    return isBirthdaySaleData
end

-- 是否领取了生日礼物
function BirthdayData:isCollectBirthdayGift()
    local isCollectBirthdayGift = false
    local birthdayInfo = self:getBirthdayInformation()
    if birthdayInfo.collectState then
        isCollectBirthdayGift = birthdayInfo.collectState == 1
    end
    return isCollectBirthdayGift
end

-- 是否生日当天
function BirthdayData:isBirthdayDay()
    local isBirthdayDay = false
    local birthdayInfo = self:getBirthdayInformation()
    if birthdayInfo.birthdayState then
        isBirthdayDay = birthdayInfo.birthdayState == 1
    end
    return isBirthdayDay
end

-- 是否设置了生日
function BirthdayData:isEditBirthdayInfo()
    local isEditBirthdayInfo = false
    local birthdayInfo = self:getBirthdayInformation()
    if birthdayInfo.birthdayDate then
        isEditBirthdayInfo = birthdayInfo.birthdayDate ~= ""
    end
    return isEditBirthdayInfo
end

-- 是否能够设置生日信息（一年一次）
function BirthdayData:isCanEditBirthdayInfo()
    local isCanEditBirthdayInfo = false
    local birthdayInfo = self:getBirthdayInformation()
    if birthdayInfo.updateDate then
        if birthdayInfo.updateDate ~= "" then
            local year = string.sub(birthdayInfo.updateDate, 1, 4)
            local month = string.sub(birthdayInfo.updateDate, 5, 6)
            local day = string.sub(birthdayInfo.updateDate, 7, 8)
            local tm = {year = tonumber(year), month = tonumber(month), day = tonumber(day)}
            local nowTime = util_getCurrnetTime()
            local nowTm = os.date("*t", nowTime)
            if nowTm.year > tm.year + 1 then -- 当前年份 > 更改生日信息年份 + 1 （不需要判断月和日）
                isCanEditBirthdayInfo = true
            elseif nowTm.year > tm.year and nowTm.month >= tm.month and nowTm.day >= tm.day then
                isCanEditBirthdayInfo = true
            end
        else
            isCanEditBirthdayInfo = true
        end
    end
    return isCanEditBirthdayInfo
end

-- 是否能够弹出生日界面
function BirthdayData:isCanPopBirthdayLayer()
    if not self:isBirthdayDay() then
        return false
    end
    if self:isCollectBirthdayGift() then
        return false
    end
    return true
end

return BirthdayData
