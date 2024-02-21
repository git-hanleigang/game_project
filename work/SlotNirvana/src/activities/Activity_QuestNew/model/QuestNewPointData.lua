local ShopItem = require "data.baseDatas.ShopItem"
local QuestNewTaskConfig = require "activities.Activity_QuestNew.model.QuestNewTaskConfig"

local QuestNewPointData = class("QuestNewPointData")

-- message FantasyQuestStage {
--   optional int32 stage = 1; 当前任务关卡的id
--   optional int32 gameId = 2;
--   optional string game = 3; 老虎机关卡
--   repeated ShopItem items = 4;
--   optional int64 coins = 5;
--   optional int32 points = 6;// 当前获得任务星星
--   optional int32 maxPoints = 7; // 当前关卡最大星星
--   repeated QuestTask tasks = 8;
-- }

function QuestNewPointData:parseData(data, maxStage,chapterId,allStageNum)
    if allStageNum then
        self.p_allStageNum = allStageNum --当前章节多少关
    end
    if chapterId then
        self.p_chapterId = chapterId --当前数据属于哪一章节
    end
    self.p_id = data.stage
    if maxStage then
        if not self.p_maxStage then
            self.p_maxStage = maxStage
            if self.p_id <= maxStage then
                self.m_unlock = true
            else
                self.m_unlock = false
            end
        else
            self:setMaxStage(maxStage)
        end
    end
    self.p_game = globalData.GameConfig:getABTestGameName(data.game)
    self.p_gameId = globalData.GameConfig:getABTestGameId(data.gameId)
    self.p_points = tonumber(data.points) or 0
    self.p_maxPoints = data.maxPoints    --当前关卡最大星星
    
    self.p_coins = tonumber(data.coins) or 0

    self.p_collected = not not data.collected --礼盒是否领取

    self.p_items = {}
    if self.p_coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_rewardCoins)
        --table.insert(self.p_items, itemData)
    end

    if data.items ~= nil and #data.items > 0 then
        for i = 1, #data.items do
            local shopItem = ShopItem:create()
            shopItem:parseData(data.items[i], true)
            self.p_items[i] = shopItem
        end
    end
    
    self.p_tasks = {}
    if data.tasks ~= nil and #data.tasks > 0 then
        for i = 1, #data.tasks do
            local task_data = QuestNewTaskConfig:create()
            task_data:parseData(data.tasks[i])
            self.p_tasks[i] = task_data
        end
    end
    if self.p_tasks then
        table.sort(
            self.p_tasks,
            function(a, b)
                return (a:getStars()) < (b:getStars())
            end
        )
    end
    
    if not self.p_initCompleted then
        self.p_initCompleted = true
        local completed_all,completed_oneMore = self:isAllTaskCompleted()
        if  self.p_points >= self.p_maxPoints and completed_all then
            self.p_completed = true
        end
        self.m_completed_oneMore = completed_oneMore
    end
end

function QuestNewPointData:refreshDataAfterSpin(data)
    self.p_points = tonumber(data.points) or 0
    self.p_tasks = {}
    if data.tasks ~= nil and #data.tasks > 0 then
        for i = 1, #data.tasks do
            local task_data = QuestNewTaskConfig:create()
            task_data:parseData(data.tasks[i])
            self.p_tasks[i] = task_data
        end
    end
    if self.p_tasks then
        table.sort(
            self.p_tasks,
            function(a, b)
                return (a:getStars()) < (b:getStars())
            end
        )
    end
    local completed_all,completed_oneMore = self:isAllTaskCompleted()
    if self.p_points >= self.p_maxPoints and completed_all then
        if self.p_completed == nil then
            self.p_willDoCompleted = true
            self.p_willShowAllTaskTip = true
        end
        self.p_completed = true
    end
    if self.m_completed_oneMore == false and completed_oneMore then
        self.p_willDoBoxOpen = true
        self.p_willShowOneTaskTip = true
        self.m_completed_oneMore = completed_oneMore
    end
end

function QuestNewPointData:isUnlock()
    return self.m_unlock
end

function QuestNewPointData:isBoxUnlock()
    return self.m_completed_oneMore
end

function QuestNewPointData:getId()
    return self.p_id
end

function QuestNewPointData:setMaxStage(maxStage)
    if self.p_id <= maxStage and self.p_maxStage <= maxStage and not self.m_unlock then
        self.m_willDoUnlock = true
        self.p_maxStage = maxStage
        if self.p_id <= maxStage then
            self.m_unlock = true
        else
            self.m_unlock = false
        end
    else
        self.p_maxStage = maxStage
    end
end

function QuestNewPointData:isWillDoUnlock()
    return not not self.m_willDoUnlock
end

function QuestNewPointData:clearWillDoUnlock()
    self.m_willDoUnlock = false
end

function QuestNewPointData:isWillDoCompleted()
    return not not self.p_willDoCompleted 
end

function QuestNewPointData:clearWillDoCompleted()
    self.p_willDoCompleted = false
end

function QuestNewPointData:isCompleted()
    return self.p_completed 
end

function QuestNewPointData:isHaveBox()
    if self.p_coins > 0 or #self.p_items > 0 then
        return true
    end
    return false
end

function QuestNewPointData:isBoxCollected()
    return self.p_collected
end

function QuestNewPointData:afterBoxCollected()
    self.p_collected = true
end

function QuestNewPointData:isBoxCompleted()
    if self:isHaveBox() then
        return self:isBoxCollected()
    end
    return true
end

function QuestNewPointData:getAllTask()
    return self.p_tasks
end
function QuestNewPointData:isAllTaskCompleted()
    local completed_all = true
    local completed_oneMore = false -- 至少完成了一个任务
    if #self.p_tasks == 0 then
        completed_all = false
    else
        for index, task in ipairs(self.p_tasks) do
            if not task.p_completed then
                if completed_all then
                    completed_all = false
                end
            else
                if not completed_oneMore then
                    completed_oneMore = true
                end
            end
        end
    end
    return completed_all , completed_oneMore
end

-- 是否播放宝箱开启
function QuestNewPointData:isWillDoBoxOpen()
    return self.p_willDoBoxOpen
end

function QuestNewPointData:clearWillDoBoxOpen()
    self.p_willDoBoxOpen = false
end

function QuestNewPointData:getTipState()
    return  self.p_willShowOneTaskTip ,self.p_willShowAllTaskTip
end

function QuestNewPointData:clearOneTipState()
    self.p_willShowOneTaskTip = false
end

function QuestNewPointData:clearAllTipState()
    self.p_willShowAllTaskTip = false
end

function QuestNewPointData:getStarRate()
    local rate = self.p_points/self.p_maxPoints *100
    return rate,self.p_points ,self.p_maxPoints
end

function QuestNewPointData:isLastStage()
    return self.p_id == self.p_allStageNum
end

return QuestNewPointData
