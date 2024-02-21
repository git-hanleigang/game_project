local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local WantedData = class("WantedData", BaseActivityData)

-- message OneDaySpecialMissionConfig {
--     optional string activityId = 1;
--     optional int64 expireAt = 2;
--     optional int32 expire = 3;
--     optional string taskDesc = 4;//任务描述
--     optional int64 param = 5;//任务目标
--     optional int64 process = 6;//任务进度
--     optional int64 coins = 7;//金币奖励
--     repeated ShopItem itemList = 8;//道具奖励
--     optional bool complete = 9;//是否已完成
--     optional string descParam = 10; //描述替换 %s 参数
--     optional bool collected = 10;//是否已领取
-- }
function WantedData:parseData(data)
    BaseActivityData.parseData(self, data)

    self.taskDesc = data.taskDesc -- 任务描述
    self.cur_point = tonumber(data.process) -- 当前阶段任务进度
    self.max_point = tonumber(data.param) -- 目标任务进度
    self.coins = tonumber(data.coins or 0) -- 金币奖励
    self.coinsV2 = data.coins 
    self.itemList = {} -- 物品奖励
    if #data.itemList > 0 then
        for idx, rewardData in ipairs(data.itemList) do
            if rewardData then
                local shopItem = ShopItem:create()
                shopItem:parseData(rewardData, true)
                table.insert(self.itemList, shopItem)
            end
        end
    end
    self.bl_complete = data.complete -- 是否完成
    self.descParam = data.descParam -- 金币值或者bet值，需要在客户端格式化后再去替换
    self.p_collected = data.collected -- 是否已领取
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.Wanted})
end

function WantedData:isRunning()
    if not WantedData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    return true
end

function WantedData:checkCompleteCondition()
    return self.p_collected or false
end

function WantedData:isTaskComplete()
    return self.bl_complete or false
end

function WantedData:getDesc()
    if self.descParam and self.descParam ~= "" then
        return string.format(self.taskDesc, util_formatCoins(self.descParam, 3))
    end
    return self.taskDesc
end

function WantedData:getCurPoint()
    return self.cur_point
end

function WantedData:getMaxPoint()
    return self.max_point
end

function WantedData:getRewards()
    return self.coins, self.itemList
end

function WantedData:getItems()
    return self.itemList
end

function WantedData:getCoinsV2()
    return self.coinsV2
end

--是否领取
function WantedData:isReceive()
    return self.p_collected
end

function WantedData:setComplete(val)
    if val then
        self.bl_complete = true
    else
        self.bl_complete = false
    end 
end

function WantedData:setCurProcess(val)
    if val then
        self.cur_point = val
    end
end

function WantedData:setParam(val)
    self.max_point = val
end

return WantedData
