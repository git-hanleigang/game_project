--钻石挑战任务界面数据
local NewDCTaskMainData = class("NewDCTaskMainData")
local NewDCTaskData = require("activities.Activity_NewDiamondChallenge.model.NewDCTaskData")
local ShopItem = require "data.baseDatas.ShopItem"

-- message LuckyChallengeV2Task {
--   optional int32 boostLevel = 1;//倍增器当前等级
--   repeated LuckyChallengeV2Boost boostList = 2;//倍增器加成列表
--   repeated LuckyChallengeV2TaskInfo taskList = 3;//任务列表
--   optional int32 payRefreshNum = 4;//付费刷新次数
--   optional int32 todayNeedFinishNum = 5;//今日需完成任务数
--   optional int32 todayFinishedNum = 6;//今日已完成任务数
--   optional int32 yesterdayBoostLevel = 7;//倍增器昨天等级
--   optional int32 totalRefreshTimes = 8;//总免费刷新次数
--   optional int32 remainingRefreshTimes = 9;//剩余免费刷新次数
-- }

function NewDCTaskMainData:parseData(_data)
    self.p_boostLevel = _data.boostLevel
    self.p_payRefreshNum = _data.payRefreshNum
    self.p_todayNeedFinishNum = _data.todayNeedFinishNum --需要完成的任务数
    self.p_todayFinishedNum = _data.todayFinishedNum --今日已经完成的任务数
    self.p_yesterdayBoostLevel = _data.yesterdayBoostLevel --昨日等级
    self.p_totalRefreshTimes = _data.totalRefreshTimes --总免费刷新次数
    self.p_remainingRefreshTimes = _data.remainingRefreshTimes -- 剩余免费刷新次数
    if _data.boostList and #_data.boostList > 0 then
        self.p_boost = {}
        for i,v in ipairs(_data.boostList) do
            local item = {}
            item.p_level = v.level
            item.p_multiply = v.multiply
            table.insert(self.p_boost,item)
        end
    end
    if _data.taskList and #_data.taskList > 0 then
        self.p_taskList = {}
        for i,v in ipairs(_data.taskList) do
            local item = NewDCTaskData:create()
            item:parseData(v)
            table.insert(self.p_taskList,item)
        end
    end
end

function NewDCTaskMainData:getBoostLevel()
    return self.p_boostLevel or 0
end

function NewDCTaskMainData:getPayRefreshNum()
    return self.p_payRefreshNum or 0
end

function NewDCTaskMainData:getTodayNeedFinishNum()
    return self.p_todayNeedFinishNum or 0
end

function NewDCTaskMainData:getTodayFinishedNum()
    return self.p_todayFinishedNum or 0
end

function NewDCTaskMainData:getYesterdayBoostLevel()
    return self.p_yesterdayBoostLevel or 0
end

function NewDCTaskMainData:getTotalRefreshTimes()
    return self.p_totalRefreshTimes or 0
end

function NewDCTaskMainData:getRemainingRefreshTimes()
    return self.p_remainingRefreshTimes or 0
end

function NewDCTaskMainData:getBoostList()
    return self.p_boost or {}
end

function NewDCTaskMainData:getTaskList()
    return self.p_taskList or {}
end


return NewDCTaskMainData