-- 新关挑战 任务数据

local ShopItem = util_require("data.baseDatas.ShopItem")
local SlotTrialsTaskData = class("SlotTrialsTaskData")

------------------------------------    游戏登录下发数据    ------------------------------------

-- message NewSlotChallengeTask {
--     optional int32 index = 1; //任务索引
--     optional string taskDesc = 2;//任务描述
--     optional int64 param = 3; //任务参数
--     optional int64 process = 4; //任务进度
--     optional int64 coins = 5; //金币奖励
--     repeated ShopItem itemList = 6; //物品奖励
--     optional string status = 7; //任务状态 INIT,PROCESSING,FINISH
--     optional bool collect = 8;//是否领奖
--     optional bool bigReward = 9;//是否是大奖
-- }
-- 解析数据
function SlotTrialsTaskData:parseData(data)
    self.index = data.index
    self.taskDesc = data.taskDesc
    self.max = tonumber(data.param)
    self.process = tonumber(data.process)
    self.status = data.status
    self.collect = data.collect
    self.bigReward = data.bigReward
    self.rewards = self:parseReward(data)
end

function SlotTrialsTaskData:parseReward(data)
    local rewards = {}
    rewards.coins = tonumber(data.coins) or 0
    rewards.items = {}
    if data.itemList and #data.itemList > 0 then
        for idx, item_data in ipairs(data.itemList) do
            local shopItem = ShopItem:create()
            shopItem:parseData(item_data, true)
            table.insert(rewards.items, shopItem)
        end
    end
    return rewards
end

function SlotTrialsTaskData:getProcess()
    if self:getStatus() == "FINISH" then
        return self:getProcessMax()
    end
    return self.process
end

function SlotTrialsTaskData:getProcessMax()
    return self.max
end

function SlotTrialsTaskData:getRewards()
    return self.rewards
end

function SlotTrialsTaskData:getStatus()
    return self.status
end

function SlotTrialsTaskData:getTaskDesc()
    return self.taskDesc
end

function SlotTrialsTaskData:isCollected()
    return self.collect
end

function SlotTrialsTaskData:getRewardType()
    if self.bigReward then
        return "SPECIAL"
    else
        return "NORMAL"
    end
end

function SlotTrialsTaskData:isFirstTask()
    return self.index == 1
end

function SlotTrialsTaskData:getTaskId()
    return self.index
end

return SlotTrialsTaskData
