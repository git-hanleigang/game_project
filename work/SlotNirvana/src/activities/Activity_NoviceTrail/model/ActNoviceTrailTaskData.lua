--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-29 15:24:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-29 15:44:44
FilePath: /SlotNirvana/src/activities/Activity_NoviceTrail/model/ActNoviceTrailTaskData.lua
Description: 新手期三日任务 任务数据
--]]
local ActNoviceTrailTaskData = class("ActNoviceTrailTaskData")
local ActNoviceTrailConfig = util_require("activities.Activity_NoviceTrail.config.ActNoviceTrailConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

function ActNoviceTrailTaskData:ctor(_serverData, _mainData)
    if not _serverData then
        return
    end

    self._mainData = _mainData
    self:parseData(_serverData)
end

function ActNoviceTrailTaskData:parseData(_serverData)
    if not _serverData then
        return
    end

    self.m_taskId = tonumber(_serverData.id) or 0 --任务 id
    self.m_description = _serverData.description or "" --任务描述
    self.m_description = string.gsub(self.m_description, "%%S", "%%s")
    self.m_params = tonumber(_serverData.params[1]) or 0 --任务参数
    self.m_process = tonumber(_serverData.process[1]) or 0 --任务进度
    self.m_bCompleted = _serverData.completed --是否完成
    self.m_points = _serverData.points or 0 --点数奖励
    self.m_bCollect = _serverData.collect --是否领取
    self.m_day = _serverData.day or 0 --第几天

    self.m_coins = tonumber(_serverData.coins) or 0 --奖励金币 价值
    -- 奖励道具
    self:parseRewardList(_serverData.items or {})
end

-- 奖励道具
function ActNoviceTrailTaskData:parseRewardList(_list)
    self.m_rewardList = {} -- 物品奖励
    self.m_rewardNoCoinsList = {} -- 物品奖励 不带金币
    if self.m_coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", "$"..self.m_coins)
        table.insert(self.m_rewardList, itemData)
    end

    for k, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self.m_rewardList, shopItem)
        table.insert(self.m_rewardNoCoinsList, shopItem)
    end
end

function ActNoviceTrailTaskData:getTaskId()
    return self.m_taskId
end
function ActNoviceTrailTaskData:getTaskDesc()
    return self.m_description
end
function ActNoviceTrailTaskData:getCurProg()
    return self.m_process
end
function ActNoviceTrailTaskData:getTaskLimit()
    return self.m_params
end
function ActNoviceTrailTaskData:checkIsCompleted()
    return self.m_bCompleted
end
function ActNoviceTrailTaskData:getCurPoints()
    return self.m_points
end
function ActNoviceTrailTaskData:getCheckCollected()
    return self.m_bCollect
end
function ActNoviceTrailTaskData:getDay()
    return self.m_day
end
function ActNoviceTrailTaskData:getCoins()
    return self.m_coins
end
function ActNoviceTrailTaskData:getRewardList()
    return self.m_rewardList
end

function ActNoviceTrailTaskData:getProg()
    if self:getTaskLimit() == 0 then
        return 0
    end
    return self:getCurProg() / self:getTaskLimit()
end

function ActNoviceTrailTaskData:getStatus()
    local curDay = self._mainData:getOpenDay()
    if curDay < self.m_day then
        -- 未解锁的天
        return ActNoviceTrailConfig.TASK_STATUS.UN_DONE
    end
    
    if self.m_bCollect then
        return ActNoviceTrailConfig.TASK_STATUS.COLLECTED
    elseif self.m_bCompleted then
        return ActNoviceTrailConfig.TASK_STATUS.DONE
    end
    return ActNoviceTrailConfig.TASK_STATUS.UN_DONE
end

return ActNoviceTrailTaskData