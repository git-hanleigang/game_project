--[[
    宠物-7日任务
]]

local ShopItem = require "data.baseDatas.ShopItem"
local PetMissionConfig = require("activities.Activity_PetMission.config.PetMissionConfig")
local BaseActivityData = require("baseActivity.BaseActivityData")
local PetMissionData = class("PetMissionData",BaseActivityData)

-- message PetMission {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 points = 4; //获取的总点数
--     repeated PetMissionDailyMission dailyMissions = 5; //每天任务信息
--     repeated PetMissionPoint pointRewards = 6; //点数奖励
-- }
function PetMissionData:parseData(_data)
    PetMissionData.super.parseData(self, _data)

    self.p_points = _data.points
    self.p_dailyMissions = self:parseMissionData(_data.dailyMissions)
    self.p_pointRewards = self:parsePointRewards(_data.pointRewards)

    gLobalNoticManager:postNotification(PetMissionConfig.notify_update_data)
end

-- message PetMissionDailyMission {
--     optional bool unlock = 1;//是否解锁
--     repeated PetMissionMission missions = 2;//任务信息
-- }
function PetMissionData:parseMissionData(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_unlock = v.unlock
            temp.p_missions = self:parseMission(v.missions)
            table.insert(list, temp)
        end
    end

    return list
end

function PetMissionData:parseSpinMissionData(_data)
    self.p_dailyMissions = self:parseMissionData(_data)
end

-- message PetMissionMission {
--     optional int32 missionId = 1; //任务id
--     optional string cur = 2; //进度
--     optional string total = 3; //总进度
--     optional string text = 4; //任务文本(total替换%s)
--     optional int32 point = 5; //点数
--     optional bool completed = 6; //完成标识
--     optional bool collected = 7; //领取标识
--     optional string coins = 8; //金币
--     repeated ShopItem items = 9; //道具
-- }
function PetMissionData:parseMission(_data)
    local missionList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_id = v.missionId
            temp.p_cur = v.cur
            temp.p_total = v.total
            temp.p_text = v.text
            temp.p_point = v.point
            temp.p_completed = v.completed
            temp.p_collected = v.collected
            temp.p_coins = v.coins
            temp.p_items = self:parseItems(v.items)
            table.insert(missionList, temp)
        end
    end
    return missionList
end

-- message PetMissionPoint {
--     optional int32 points = 1; //领取点数
--     optional bool collected = 2; //领取标识
--     optional string coins = 3; //金币
--     repeated ShopItem items = 4; //道具
-- }
function PetMissionData:parsePointRewards(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_points = v.points
            temp.p_collected = v.collected
            temp.p_coins = v.coins
            temp.p_items = self:parseItems(v.items)
            table.insert(list, temp)
        end
    end
    return list
end

function PetMissionData:parseItems(_items)
    local itemList = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemList, tempData)
        end
    end
    return itemList
end

function PetMissionData:getCurPoints()
    return self.p_points
end

function PetMissionData:getMissions()
    return self.p_dailyMissions
end

function PetMissionData:getPassRewards()
    return self.p_pointRewards
end

function PetMissionData:getMissionByDay(_day)
    local dailyMission = self.p_dailyMissions[_day]
    local collectList = {}
    local completedList = {}
    local uncompletedList = {}
    for i,v in ipairs(dailyMission.p_missions) do
        if v.p_collected then
            table.insert(collectList, v)
        elseif v.p_completed then
            table.insert(completedList, v)
        else
            table.insert(uncompletedList, v)
        end
    end
    
    local missionList = {}
    for i,v in ipairs(completedList) do
        table.insert(missionList, v)
    end
    for i,v in ipairs(uncompletedList) do
        table.insert(missionList, v)
    end
    for i,v in ipairs(collectList) do
        table.insert(missionList, v)
    end

    return dailyMission.p_unlock, missionList
end

function PetMissionData:getRewardNum()
    local num = 0
    local count = #self.p_dailyMissions
    for i = 1, count do
        local dailyMission = self.p_dailyMissions[i]
        for i,v in ipairs(dailyMission.p_missions) do
            if v.p_completed and not v.p_collected then
                num = num + 1
            end
        end
    end
    return num
end

function PetMissionData:getShowDay()
    local day = 1
    local count = #self.p_dailyMissions
    for i = 1, count do
        local dailyMission = self.p_dailyMissions[i]
        for k, v in ipairs(dailyMission.p_missions) do
            if v.p_completed and not v.p_collected then
                day = i
                return day
            end
        end
    end

    return day
end

return PetMissionData
