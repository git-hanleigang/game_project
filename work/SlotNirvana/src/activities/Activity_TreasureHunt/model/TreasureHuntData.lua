--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-15 14:56:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-15 16:00:26
FilePath: /SlotNirvana/src/activities/Activity_TreasureHunt/model/TreasureHuntData.lua
Description: 寻宝之旅 数据
--]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local TreasureHuntLevelTask = class("TreasureHuntLevelTask")
--   message TreasureHuntLevel {
--     optional int32 seq = 1; //序号（服务器生成）
--     optional int32 level = 2; //任务层级
--     optional int32 unlockLevel = 3; //解锁等级
--     optional string taskDescription = 4; //任务描述
--     optional string bet = 5; //解锁Bet
--     optional int32 times = 6; //要求次数
--     optional int32 progress = 7; //累计进度
--     repeated ShopItem item = 8; //奖励物品
--     optional string coin = 9; //奖励金币
--   }
function TreasureHuntLevelTask:ctor(_taskData)
    self._seq = _taskData.seq or 0
    self._level = _taskData.level or 0
    self._unlockLevel = _taskData.unlockLevel or 0
    self._taskDesc = _taskData.taskDescription or ""
    self._bet = tonumber(_taskData.bet) or 0
    self._times = _taskData.times or 0
    self._progress = _taskData.progress or 0
    self._coins = tonumber(_taskData.coin) or 0
    self:parseRewardList(_taskData.item or {})
end

-- 奖励道具
function TreasureHuntLevelTask:parseRewardList(_list)
    self._rewardList = {} -- 物品奖励
    if self._coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self._coins, 3))
        table.insert(self._rewardList, itemData)
    end

    for k, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self._rewardList, shopItem)
    end
end

function TreasureHuntLevelTask:getSeq()
    return self._seq
end
function TreasureHuntLevelTask:getLevel()
    return self._level
end
function TreasureHuntLevelTask:getUnlockLevel()
    return self._unlockLevel
end
function TreasureHuntLevelTask:getTaskDesc()
    return self._taskDesc
end
function TreasureHuntLevelTask:getBet()
    return self._bet
end
function TreasureHuntLevelTask:getTimes()
    return self._times
end
function TreasureHuntLevelTask:getProgress()
    if self._progress > self._times then
        self._progress = self._times
    end
    return self._progress
end
function TreasureHuntLevelTask:getProgPercent()
    local percent = 100
    if self._times > 0 then
        percent = math.floor(self._progress / self._times * 100)
    end
    return percent 
end
function TreasureHuntLevelTask:getCoins()
    return self._coins
end
function TreasureHuntLevelTask:getRewardList()
    return self._rewardList
end
function TreasureHuntLevelTask:checkUnlock()
    local unlockLv = self:getUnlockLevel()
    local bLock = globalData.userRunData.levelNum < unlockLv
    if bLock then
        return false
    end

    local machineData = globalData.slotRunData.machineData
    if not machineData then
        return false
    end

    local curSlotMaxBet = tonumber(machineData:getMaxBet()) or 0
    local needBet =self:getBet()
    return needBet <= curSlotMaxBet
end


local BaseActivityData = require("baseActivity.BaseActivityData")
local TreasureHuntData = class("TreasureHuntData", BaseActivityData)

-- message TreasureHunt {
--     optional int32 currentLevel = 1; // 当前层级
--     optional bool close = 2; // 功能关闭标记
--     repeated TreasureHuntLevel levels = 3; // 任务列表
--     optional string levelCoins = 4;// 层级奖励金币
--   }
function TreasureHuntData:parseData(_data)
    TreasureHuntData.super.parseData(self, _data)
    if not _data then
        return
    end

    self._curLv = _data.currentLevel or 0 -- 当前层级
    self._bOpen = not _data.close -- 功能关闭标记
    self:parseLevelTaskData(_data.levels or {}) --任务列表
    self._lvCoins = tonumber(_data.levelCoins) or 0 -- 层级奖励金币
end

function TreasureHuntData:parseLevelTaskData(_list)
    self._taskList = {}
    self._unlockLv = 99999999999
    local totalCount = #_list
    for _idx = 1, #_list do
        local taskData = _list[_idx]
        local data = TreasureHuntLevelTask:create(taskData)
        self._unlockLv = math.min(self._unlockLv, data:getUnlockLevel())
        self._taskList[_idx] = data
    end
    table.sort(self._taskList, function(a, b)
        return a:getBet() < b:getBet()
    end)
end

function TreasureHuntData:getCurLv()
    return self._curLv
end
function TreasureHuntData:getUnlockLv()
    return self._unlockLv
end
function TreasureHuntData:getCoins()
    return self._lvCoins
end
function TreasureHuntData:getLevelTaskList()
    return self._taskList or {}
end

-- 获取完成度 最好的任务
function TreasureHuntData:getBestTaskData()
    local machineData = globalData.slotRunData.machineData
    if not machineData then
        return
    end

    local bestTaskData
    for i=1, #self._taskList do
        local taskData = self._taskList[i]
        local bUnlock = taskData:checkUnlock()

        if bUnlock then
            if not bestTaskData then
                bestTaskData = taskData
            elseif taskData:getProgPercent() >= bestTaskData:getProgPercent() then
                bestTaskData = taskData
            end
        end
        
    end

    return bestTaskData
end

-- 获取 当前betValue 可激活的任务
function TreasureHuntData:getCurBetTaskData(_betValue)
    _betValue = _betValue or 0

    local curBetTaskData
    for i=1, #self._taskList do
        local taskData = self._taskList[i]
        local bet = taskData:getBet()
        if bet <= _betValue then
            curBetTaskData = taskData
        end
    end

    return curBetTaskData
end


-- spin 更新任务信息
function TreasureHuntData:spinUpdateLevelTaskInfo(_levelTaskInfo)
    if type(_levelTaskInfo) ~= "table" then
        return
    end

    local updateSeq = _levelTaskInfo.seq
    for k, taskData in pairs(self._taskList) do
        if taskData:getSeq() == updateSeq then
            self._taskList[k] = TreasureHuntLevelTask:create(_levelTaskInfo)
            break
        end 
    end
end

function TreasureHuntData:isRunning()
    local bRunning = TreasureHuntData.super.isRunning(self)
    if bRunning then
        return self._bOpen and #self._taskList == 3
    end
    return false
end

--获取入口位置 1：左边，0：右边
function TreasureHuntData:getPositionBar()
    -- 默认右边，修改重写该方法
    return 1
end

return TreasureHuntData