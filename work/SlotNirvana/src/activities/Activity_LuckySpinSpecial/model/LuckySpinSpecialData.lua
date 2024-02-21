--[[--
    luckyspin 送道具 走配置
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require("baseActivity.BaseActivityData")
local LuckySpinSpecialData = class("LuckySpinSpecialData", BaseActivityData)

function LuckySpinSpecialData:ctor()
    LuckySpinSpecialData.super.ctor(self)
    self.m_infoList = {}
end

--[[
    message SuperSpinSendItem {
        optional string activityId = 1; // 活动的id
        optional string activityName = 2;// 活动的名称
        optional string begin = 3;// 活动的开启时间
        optional string end = 4;// 活动的结束时间
        optional int64 expireAt = 5; // 活动倒计时
        optional int32 normalBuyTimes = 6; //普通的superSpin购买次数
        optional int32 normalBuyLimitTimes = 7;// 普通的购买次数限制
        optional int32 highBuyTimes = 8; //高级的superSpin购买次数
        optional int32 highBuyLimitTimes = 9;// 高级购买次数限制
        repeated ShopItem currentItem = 10; // 道具
        repeated ShopItem displayNormalItem = 11; // 展示普通道具
        repeated ShopItem displayHighItem = 12; // 展示高级道具
    }
]]
function LuckySpinSpecialData:parseData(_data)
    LuckySpinSpecialData.super.parseData(self, _data)
    self.p_currentItem = self:parseShopItem(_data.currentItem)
    self.p_displayNormalItem = self:parseShopItem(_data.displayNormalItem)
    self.p_displayHighItem = self:parseShopItem(_data.displayHighItem)
    self.p_normalBuyTimes = tonumber(_data.normalBuyTimes or 0)
    self.p_normalBuyLimitTimes = tonumber(_data.normalBuyLimitTimes or 0)
    self.p_highBuyTimes = tonumber(_data.highBuyTimes or 0)
    self.p_highBuyLimitTimes = tonumber(_data.highBuyLimitTimes or 0)
    self.m_infoList = {}
    local normalBuyTimes = math.min(self.p_normalBuyTimes, self.p_normalBuyLimitTimes)
    local highBuyTimes = math.min(self.p_highBuyTimes, self.p_highBuyLimitTimes)
    self.m_infoList[#self.m_infoList + 1] = {item = self.p_displayNormalItem, num = normalBuyTimes, limitNum = self.p_normalBuyLimitTimes}
    self.m_infoList[#self.m_infoList + 1] = {item = self.p_displayHighItem, num = highBuyTimes, limitNum = self.p_highBuyLimitTimes}
end

function LuckySpinSpecialData:parseShopItem(_items)
    local itemList = {}
    for _, data in ipairs(_items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        table.insert(itemList, shopItem)
    end
    return itemList
end

function LuckySpinSpecialData:isRunning()
    if not LuckySpinSpecialData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

-- 检查完成条件
function LuckySpinSpecialData:checkCompleteCondition()
    if not globalData.shopRunData:getLuckySpinIsOpen() then
        return true
    end
    if self:checkNormalComplete() and self:checkHighComplete() then
        return true
    end
    return false
end

-- 获得道具数据通过索引
function LuckySpinSpecialData:getInfoByIndex(_inx)
    if self.m_infoList[_inx] then
        return self.m_infoList[_inx]
    end
    return {}
end

-- 获得付费奖励
function LuckySpinSpecialData:getCurrentItem()
    return self.p_currentItem or {}
end

-- 获得普通奖励
function LuckySpinSpecialData:getDisplayNormalItem()
    return self.p_displayNormalItem or {}
end

-- 获得高级奖励
function LuckySpinSpecialData:getDisplayHighItem()
    return self.p_displayHighItem or {}
end

-- 检测普通是否完成
function LuckySpinSpecialData:checkNormalComplete()
    if self.p_normalBuyTimes and self.p_normalBuyLimitTimes then
        return self.p_normalBuyTimes >= self.p_normalBuyLimitTimes
    end
    return false
end

-- 检测高级是否完成
function LuckySpinSpecialData:checkHighComplete()
    if self.p_highBuyTimes and self.p_highBuyLimitTimes then
        return self.p_highBuyTimes >= self.p_highBuyLimitTimes
    end
    return false
end

return LuckySpinSpecialData
