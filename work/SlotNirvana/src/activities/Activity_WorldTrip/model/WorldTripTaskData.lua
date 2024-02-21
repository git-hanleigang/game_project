-- 新版大富翁数据解析

local ShopItem = util_require("data.baseDatas.ShopItem")
local WorldTripTaskData = class("WorldTripTaskData")

-- message WorldTripTask {
--     optional string taskDesc = 1; //任务描述
--     optional int64 param = 2; //目标
--     optional int64 process = 3; //进度
--     optional bool completed = 4; //是否完成
--     optional WorldTripGameReward reward = 5; //奖励
-- }
function WorldTripTaskData:parseData(data)
    if not data then
        return
    end
    self.taskDesc = data.taskDesc
    self.tar_point = tonumber(data.param or 0)
    self.cur_point = tonumber(data.process or 0)
    self.bl_complete = data.completed
    self.rewards = self:parseRewards(data.reward)
end

-- message WorldTripGameReward {
--     optional int64 coins = 1; //金币奖励
--     repeated ShopItem itemList = 2; //物品奖励
-- }
function WorldTripTaskData:parseRewards(data)
    if not data then
        return
    end
    local rewards = {coins = 0, items = {}}
    if data then
        if data.coins and tonumber(data.coins) > 0 then
            rewards.coins = tonumber(data.coins)
        end
        if data.itemList and table.nums(data.itemList) > 0 then
            for _, item_data in ipairs(data.itemList) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data)
                table.insert(rewards.items, shopItem)
            end
        end
    end
    return rewards
end

-- 地图上制掷骰子结果
function WorldTripTaskData:parsePlayData(data)
    if not data then
        return
    end
    if data.taskProcess and data.taskProcess >= 0 then
        self.cur_point = data.taskProcess
    end
    if data.taskParam and data.taskParam >= 0 then
        self.tar_point = data.taskParam
    end
    if data.taskCompleted ~= nil then
        self.bl_complete = data.taskCompleted
    end
end

return WorldTripTaskData
