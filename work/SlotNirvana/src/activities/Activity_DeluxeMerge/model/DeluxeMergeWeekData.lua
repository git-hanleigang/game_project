--[[
Author: cxc
Date: 2022-02-14 15:03:22
LastEditTime: 2022-02-14 15:03:39
LastEditors: cxc
Description: 高倍场 合成小游戏 合成周卡活动 数据
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/model/DeluxeMergeWeekData.lua
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DeluxeMergeWeekData = class("DeluxeMergeWeekData", BaseActivityData)
local DeluxeMergeWeekDayData = require("activities.Activity_DeluxeMerge.model.DeluxeMergeWeekDayData")

-- message MergeWeek {
--     optional string activityId = 1;
--     optional int32 expire = 2;
--     optional int64 expireAt = 3;
--     optional int32 purchaseExpire = 4; //付费结束时间
--     optional int64 purchaseExpireAt = 5; //付费结束时间
--     optional string keyId = 6;
--     optional string key = 7; //付费点key
--     optional string price = 8; //价格
--     optional bool buy = 9;// 是否已经购买
--     repeated MergeWeekReward rewards = 10;// 奖励
--   }
function DeluxeMergeWeekData:ctor()
    DeluxeMergeWeekData.super.ctor(self)

    self.m_goodsId = ""
    self.m_price = ""
    self.m_purchaseExpireAt = 0
    self.m_bPay = false
    self.m_curDay = 1
    self.m_dayList = {}
    self.m_bAllCollected = false
end

function DeluxeMergeWeekData:parseData(_data)
    if not _data then
        return
    end
    self.m_configExpireAt = tonumber(_data.expireAt) or 0
    DeluxeMergeWeekData.super.parseData(self, _data)

    self.m_goodsId = _data.key or ""
    self.m_price = _data.price or ""
    self.m_purchaseExpireAt = _data.purchaseExpireAt or 0
    self.m_bPay = _data.buy or false
    if not self.m_bPay then
        -- 玩家未付费，活动时间为 可付费的截止时间
        self.p_expireAt = self.m_purchaseExpireAt 
    else
        self.p_expireAt = _data.expireAt or 0
    end

    self:parseDayData(_data.rewards or {})
end

-- 解析每天的数据
function DeluxeMergeWeekData:parseDayData(_list)
    self.m_curDay = 1
    self.m_dayList = {}
    self:setOpenFlag(false)
    for i=1, #_list do
        local data =  _list[i]
        local dayData = DeluxeMergeWeekDayData:create()
        dayData:parseData(data)
        local day = dayData:getCurDay()
        local status = dayData:getStatus()
        -- 状态：0未激活 1未领取 2已领取
        if self.m_bPay and status == 1 then
            self.m_curDay = day
        end
        if status ~= 2 then
            self:setOpenFlag(true)
            self.m_bAllCollected = false
        end 
        self.m_dayList[day] = dayData
    end
end

-- 付费点key
function DeluxeMergeWeekData:getGoodsId()
    return self.m_goodsId
end

-- 价格
function DeluxeMergeWeekData:getPrice()
    return self.m_price
end

-- 是否已经购买
function DeluxeMergeWeekData:checkIsPay()
    return self.m_bPay
end

-- 获取当前 可领取 天数
function DeluxeMergeWeekData:getCurDay()
    return self.m_curDay
end

-- 获取 每天的数据
function DeluxeMergeWeekData:getDayList()
    return self.m_dayList
end
function DeluxeMergeWeekData:getDayDataByIdx(_idx)
    return self.m_dayList[_idx]
end

-- 7天全部领取完活动不开
function DeluxeMergeWeekData:setAllCollected()
    self.m_bAllCollected = true
end

function DeluxeMergeWeekData:checkCompleteCondition()
    return self.m_bAllCollected
end    

-- 是否有未领取的 自动弹领取面板
function DeluxeMergeWeekData:checkCanCollect()
    local bCanCollect = false
    for i=1, #self.m_dayList do
        local dayData = self.m_dayList[i]
        if dayData:checkCanCollect() then
            bCanCollect = true
            break
        end 
    end
    return bCanCollect
end     

-- 获取运营配置的 活动结束时间
function DeluxeMergeWeekData:getConfigExpireAt()
    return (self.m_configExpireAt or 0) / 1000
end

return DeluxeMergeWeekData