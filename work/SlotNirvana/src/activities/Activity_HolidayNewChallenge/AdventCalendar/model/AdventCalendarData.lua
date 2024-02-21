--[[
    圣诞聚合 -- 签到
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local AdventCalendarData = class("AdventCalendarData", BaseActivityData)

-- message HolidayNewChallengeAdventCalendar {
--     optional string activityId = 1; // 活动的id
--     optional string activityName = 2;// 活动的名称
--     optional string begin = 3;// 活动的开启时间
--     optional string end = 4;// 活动的结束时间
--     optional int64 expireAt = 5; // 活动倒计时
--     optional int64 zeroPointExpired = 6; // 距离当前的零点还有多长时间
--     repeated HolidayAdventCalendarDayReward dayRewardList = 7; // 每天签到的奖励
--     repeated HolidayAdventCalendarDayReward  accumulateRewardList = 8; // 累计签到奖励
--     optional int32 curDay = 9;//当前是第几天
--     optional int32 makeUpTimes = 10;//当天的补签次数
--     repeated int32 consumeGems = 11;//消耗的第二货币数
--   }
function AdventCalendarData:parseData(_data)
    AdventCalendarData.super.parseData(self, _data)

    self.p_expireAt = tonumber(_data.expireAt)
    self.p_zeroPointExpired = tonumber(_data.zeroPointExpired)
    self.p_curDay = _data.curDay
    self.p_makeUpTimes = _data.makeUpTimes
    self.p_consumeGems = _data.consumeGems
    self.p_dayRewardList = self:parseRewardData(_data.dayRewardList)
    self.p_accumulateRewardList = self:parseRewardData(_data.accumulateRewardList)
end

-- message HolidayAdventCalendarDayReward {
--     optional int32 day = 1; // 第几天
--     repeated ShopItem items = 2;//道具
--     optional string coins = 3; // 金币
--     optional bool collected = 4; // 是否已经领取
--   }
function AdventCalendarData:parseRewardData(_data)
    local list = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_day = v.day
            temp.p_coins = v.coins
            temp.p_collected = v.collected
            temp.p_items = self:parseItems(v.items)
            table.insert(list, temp)
        end
    end
    return list
end

function AdventCalendarData:parseItems(_items)
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

function AdventCalendarData:getZeroPointExpired()
    return (self.p_zeroPointExpired or 0) / 1000
end

function AdventCalendarData:getCurDay()
    return self.p_curDay
end

function AdventCalendarData:getDayRewardList()
    return self.p_dayRewardList
end

function AdventCalendarData:getProRewardList()
    return self.p_accumulateRewardList
end

function AdventCalendarData:getMakeUpTimes()
    return self.p_makeUpTimes
end

function AdventCalendarData:getConsumeGems()
    return self.p_consumeGems
end

function AdventCalendarData:getSignPro()
    local count = #self.p_dayRewardList
    local signNum = self:getSignDays()
    return signNum / count * 100
end

function AdventCalendarData:getSignDays()
    local signNum = 0
    for i,v in ipairs(self.p_dayRewardList) do
        if v.p_collected then
            signNum = signNum + 1
        end
    end
    return signNum
end

function AdventCalendarData:canShow()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getZeroPointExpired() - curTime
    return leftTime > 0
end

return AdventCalendarData