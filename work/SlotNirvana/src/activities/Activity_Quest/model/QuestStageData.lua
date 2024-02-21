local ShopItem = require "data.baseDatas.ShopItem"
local QuestTaskConfig = require "activities.Activity_Quest.model.QuestTaskConfig"
local QuestSkipSaleData = require "activities.Activity_Quest.model.QuestSkipSaleData"
local QuestSkipSaleData_PlanB = require "activities.Activity_Quest.model.QuestSkipSaleData_PlanB"

local QuestStageData = class("QuestStageData")

--message QuestStageInfo {
--    optional int32 id = 1; // 当前任务关卡的id
--    optional string game = 2; // 老虎机关卡
--    optional int32 gameId = 3;
--    optional string points = 4;
--    repeated ShopItem items = 5;
--    optional int64 coins = 6;
--    optional string status = 7; // 当前阶段的完成状态  INIT, FINISHED, REWARD, COMPLETE
--    repeated QuestTask tasks = 8; // 当前的任务状态
--    optional int32 taskCount = 9; //任务数量
--    optional QuestWheel wheelData = 10; // 章节轮盘奖励
--    optional int32 chips = 11; // 筹码
--    optional QuestSkipSale skipSale = 12;  //跳过促销
--    optional int64 passPoints = 13;//本关pass会获得的点数
--    optional QuestSkipSaleV3 skipSaleV3Data  = 14;// skip道具数据
--}
function QuestStageData:parseData(data, isJson)
    self.p_id = data.id
    self.p_game = globalData.GameConfig:getABTestGameName(data.game)
    self.p_gameId = globalData.GameConfig:getABTestGameId(data.gameId)
    self.p_points = tonumber(data.points) or 0

    self.p_items = {}
    if data.items ~= nil and #data.items > 0 then
        for i = 1, #data.items do
            local shopItem = ShopItem:create()
            shopItem:parseData(data.items[i], true)
            self.p_items[i] = shopItem
        end
    end

    self.p_coins = tonumber(data.coins)
    self.p_status = data.status
    self.p_passPoints = data.passPoints

    self.p_tasks = {}
    if data.tasks ~= nil and #data.tasks > 0 then
        for i = 1, #data.tasks do
            local task_data = QuestTaskConfig:create()
            task_data:parseData(data.tasks[i])
            self.p_tasks[i] = task_data
        end
    end
    self.p_taskCount = data.taskCount
    self.p_chips = data.chips

    if not isJson then
        if data:HasField("skipSale") then
            if not self.p_skipSale then
                self.p_skipSale = QuestSkipSaleData:create()
            end
            self.p_skipSale:parseData(data.skipSale)
        end
    elseif data.skipSale ~= nil then
        if not self.p_skipSale then
            self.p_skipSale = QuestSkipSaleData:create()
        end
        self.p_skipSale:parseData(data.skipSale)
    end

    if data.skipSaleV3Data then
        if not self.p_skipSale_PlanB then
            self.p_skipSale_PlanB = QuestSkipSaleData_PlanB:create()
        end
        self.p_skipSale_PlanB:parseData(data.skipSaleV3Data)
    end
end

function QuestStageData:getSkipData_PlanB()
    return self.p_skipSale_PlanB
end

function QuestStageData:setIsLast(bl_last)
    self.bl_isLast = bl_last
end

function QuestStageData:getIsLast()
    return self.bl_isLast
end

function QuestStageData:getTasks()
    return self.p_tasks
end

function QuestStageData:getSkipData()
    return self.p_skipSale
end

function QuestStageData:getState()
    return self.p_status
end

return QuestStageData
