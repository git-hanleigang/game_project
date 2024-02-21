--[[
Author: cxc
Date: 2022-02-14 16:32:23
LastEditTime: 2022-02-14 16:32:24
LastEditors: cxc
Description: 高倍场 合成小游戏 合成周卡活动 每天的数据
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/model/DeluxeMergeWeekDayData.lua
--]]
local DeluxeMergeWeekDayData = class("DeluxeMergeWeekDayData")
local ShopItem = util_require("data.baseDatas.ShopItem")

--   message MergeWeekReward {
--     optional int32 collectCd = 1; //开放领取时间
--     optional int64 collectCdAt = 2; //开放领取时间
--     optional int32 day = 3; //第几天
--     optional int32 status = 4; //状态：0未激活 1未领取 2已领取
--     repeated ShopItem items = 5; //奖励物品
--   }
function DeluxeMergeWeekDayData:ctor()
    self.m_openAt = 0
    self.m_curDay = 0
    self.m_status = 0
    self.m_rewardList = {}
end

function DeluxeMergeWeekDayData:parseData(_data)
    if not _data then
        return
    end

    self.m_openAt = tonumber(_data.collectCdAt or 0) * 0.001 -- 毫秒to秒
    self.m_curDay = _data.day or 0
    self.m_status = _data.status or 0

    self:parseRewardData(_data.items or {})
end

function DeluxeMergeWeekDayData:parseRewardData(_items)
    self.m_rewardList = {}
    if not _items then
        return
    end

    for i = 1, #_items do
		local itemData = _items[i]
		local rewardItem = ShopItem:create()
		rewardItem:parseData(itemData)
		table.insert(self.m_rewardList, rewardItem)
	end
end

-- 开放领取时间
function DeluxeMergeWeekDayData:getOpenAt()
    if self.m_openAt == 0 then
        self.m_openAt = util_getCurrnetTime()
    end
    return self.m_openAt
end

-- 第几天
function DeluxeMergeWeekDayData:getCurDay()
    return self.m_curDay
end

-- 状态：0未激活 1未领取 2已领取
function DeluxeMergeWeekDayData:setStatus(_status)
    self.m_status = _status
end
function DeluxeMergeWeekDayData:getStatus()
    return self.m_status
end

-- 奖励物品
function DeluxeMergeWeekDayData:getRewardList()
    return self.m_rewardList
end

-- 是否可领取
function DeluxeMergeWeekDayData:checkCanCollect()
    if self.m_status ~= 1 then
        return false
    end 

    return util_getCurrnetTime() >= self.m_openAt
end

return DeluxeMergeWeekDayData