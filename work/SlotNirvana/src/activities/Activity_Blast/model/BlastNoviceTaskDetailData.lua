--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-27 14:20:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-29 17:54:43
FilePath: /SlotNirvana/src/activities/Activity_Blast/model/BlastNoviceTaskDetailData.lua
Description: 新手blast 任务 阶段任务数据
--]]
local BlastNoviceTaskDetailData = class("BlastNoviceTaskDetailData")
local ShopItem = require("data.baseDatas.ShopItem")

-- 任务状态 0：未开启、1：开启、2：结束
BlastNoviceTaskDetailData.TASK_STATUS = {
    LOCK = 0,
    OPEN = 1,
    OVER = 2
}

function BlastNoviceTaskDetailData:ctor()
    self.m_activityType = ""
    self.m_missionType = "" -- //任务类型
    self.m_bCompleted = false -- //完成标识
    self.m_bReward = false -- //奖励发放标识
    self.m_phase = 1 -- //阶段
    self.m_content = "" -- //任务描述
    self.m_params = {} -- //任务参数
    self.m_process = {} -- //任务进度
    self.m_items = {} --物品奖励
    self.m_propsBagist = {} --高倍场合成道具
    self.m_coins = 0 --金币奖励
    self.m_displayItems = {} --展示物品奖励
end

function BlastNoviceTaskDetailData:parseData(_data)
    if not _data then
        return
    end

    self.m_activityType = _data.activityType or "" -- 小活动类型
    self.m_missionType = _data.missionType or "" -- //任务类型
    self.m_bCompleted = _data.completed or false -- //完成标识
    self.m_bReward = _data.reward or false -- //奖励发放标识
    self.m_phase = _data.phase or 1 -- //阶段
    self.m_content = _data.content or "" -- //任务描述
    self.m_params = _data.params or {} -- //任务参数
    self.m_process = _data.process or {} -- //任务进度
    self.m_coins = tonumber(_data.coins) or 0 --金币奖励
    
    --物品奖励
    self:parseRewardList(_data.items or {}, _data.displayItems or {}) 
end

--物品奖励
function BlastNoviceTaskDetailData:parseRewardList(_list, _displayList)
    self.m_items = {}
    self.m_propsBagist = {}

    for _, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        if string.find(shopItem.p_icon, "Pouch") then
            table.insert(self.m_propsBagist, shopItem)
        end

        table.insert(self.m_items, shopItem)
    end

    --展示物品奖励
    self.m_displayItems = {} 
    for _, data in ipairs(_displayList) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self.m_displayItems, shopItem)
    end
end

function BlastNoviceTaskDetailData:getActivityType()
    return self.m_activityType
end
function BlastNoviceTaskDetailData:getMissionType()
    return self.m_missionType
end
function BlastNoviceTaskDetailData:checkCompleted()
    return self.m_bCompleted
end
function BlastNoviceTaskDetailData:checkHadSendReward()
    return self.m_bReward
end
function BlastNoviceTaskDetailData:getPhase()
    return self.m_phase
end
function BlastNoviceTaskDetailData:getContent()
    return self.m_content
end
function BlastNoviceTaskDetailData:getProcessMax()
    return self.m_params[1] or 1
end
function BlastNoviceTaskDetailData:getCurProcess()
    return self.m_process[1] or 0
end
function BlastNoviceTaskDetailData:getCoins()
    return self.m_coins
end
function BlastNoviceTaskDetailData:getRewardList()
    return self.m_items
end
function BlastNoviceTaskDetailData:getDelxueMergePropBagList()
    return self.m_propsBagist
end
function BlastNoviceTaskDetailData:getDisplayRewardList()
    return self.m_displayItems
end

return BlastNoviceTaskDetailData