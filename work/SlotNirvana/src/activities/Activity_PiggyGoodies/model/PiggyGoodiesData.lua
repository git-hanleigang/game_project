--[[
    新版小猪挑战
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local PiggyGoodiesData = class("PiggyGoodiesData",BaseActivityData)

-- message PiggyGoodies {
--     optional string activityId = 1; // 活动的id
--     optional string activityName = 2;// 活动的名称
--     optional string begin = 3;// 活动的开启时间
--     optional string end = 4;// 活动的结束时间
--     optional int64 expireAt = 5; // 活动倒计时
--     optional int32 payTimes = 6;// 总的付费次数
--     optional PiggyGoodiesWheelResult wheelData = 7;// 每轮的任务
--     optional PiggyGoodiesRewardResult rewardData = 8; // 奖励数据
--   }
function PiggyGoodiesData:parseData(_data)
    PiggyGoodiesData.super.parseData(self, _data)

    self.p_payTimes = _data.payTimes
    self.p_stageList = self:parseStageData(_data.wheelData)
    self.p_rewardList = self:parseRewardList(_data.rewardData)
end

-- message PiggyGoodiesWheelResult {
--     optional int32 wheel = 1; // 第几轮
--     optional int32 curProgress= 2;// 当前进度
--     optional int32 params = 3; // 目标参数
--     optional int32 collectTimes = 4; // 领奖次数
--     optional bool finished = 5;// 是否完成
--   }
function PiggyGoodiesData:parseStageData(_data)
    local stageList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_round = v.wheel
            temp.p_curProgress = v.curProgress
            temp.p_params = v.params
            temp.p_collectTimes = v.collectTimes
            temp.p_finished = v.finished
            table.insert(stageList, temp)
        end
    end

    table.sort(stageList, function (a, b)
        return a.p_round < b.p_round
    end)

    return stageList
end

-- message PiggyGoodiesRewardResult {
--     optional string type = 1; // 奖励的类型
--     optional int32 seq = 2; // 奖励的序号
--     optional int64 coins = 3; // 金币
--     repeated ShopItem items = 4; // 道具
--     optional bool collected = 5; //是否领取
--   }
function PiggyGoodiesData:parseRewardList(_data)
    local rewardList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_type = v.type
            temp.p_seq = v.seq
            temp.p_collected = v.collected
            temp.p_coins = tonumber(v.coins)
            temp.p_items = self:parseItems(v.items)
            table.insert(rewardList, temp)
        end
    end

    table.sort(rewardList, function (a, b)
        return a.p_seq < b.p_seq
    end)

    return rewardList
end

function PiggyGoodiesData:parseItems(_items)
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

function PiggyGoodiesData:getPayTimes()
    return self.p_payTimes
end

function PiggyGoodiesData:getStageList()
    return self.p_stageList
end

function PiggyGoodiesData:getRewardList()
    return self.p_rewardList
end

function PiggyGoodiesData:getCurStageData()
    local stage = 1
    for i,v in ipairs(self.p_stageList) do
        if not v.p_finished then
            stage = i
            break
        end
    end

    return stage
end

return PiggyGoodiesData
