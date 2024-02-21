--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:26:36
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/model/TrillionChallengeTaskData.lua
Description: 亿万赢钱挑战 宝箱任务数据
--]]
local TrillionChallengeTaskData = class("TrillionChallengeTaskData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function TrillionChallengeTaskData:ctor(_taskData)
    self._taskOrder = _taskData.taskOrder or 0 -- 任务顺序
    self._taskText = _taskData.taskText or "" -- 任务文本
    self._taskParam = tonumber(_taskData.taskParam) or 0 -- 任务要求
    self._taskCoins = tonumber(_taskData.rewardCoin) or 0 -- 金币奖励
    self._bCollect = _taskData.collect -- 领取标记

    -- 道具奖励
    self:parseTaskItems(_taskData.rewardItem or {})
end

-- 奖励道具
function TrillionChallengeTaskData:parseTaskItems(_list)
    self._taskItems = {} -- 物品奖励
    if self._taskCoins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self._taskCoins, 3)) 
        table.insert(self._taskItems, itemData)
    end

    for k, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self._taskItems, shopItem)
    end
end

function TrillionChallengeTaskData:getTaskOrder()
    return self._taskOrder or 0
end
function TrillionChallengeTaskData:getTaskText()
    return self._taskText or ""
end
function TrillionChallengeTaskData:getTaskParam()
    return self._taskParam or 0
end
function TrillionChallengeTaskData:getTaskCoins()
    return self._taskCoins or 0
end
function TrillionChallengeTaskData:checkCanCol(_cur)
    _cur = _cur or 0
    local bCanCol = _cur >= self._taskParam and (not self._bCollect)
    return bCanCol
end
function TrillionChallengeTaskData:checkHadCol()
    return self._bCollect
end
function TrillionChallengeTaskData:getTaskItems()
    return self._taskItems or {}
end
return TrillionChallengeTaskData