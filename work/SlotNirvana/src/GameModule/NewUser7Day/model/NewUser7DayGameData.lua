--[[
Author: dhs
Date: 2022-05-09 17:00:38
LastEditTime: 2022-05-26 22:09:18
LastEditors: bogon
Description: 游戏数据
    optional int32 day = 1; // 第几天
    optional int64 taskId = 2;//任务Id
    optional string description = 3;//任务描述
    optional int64 param = 4;//任务参数
    optional int64 progress = 5;//任务进度
    optional int32 status = 6; // 任务状态 0未开启 1已开启 2已完成 3已领奖
    optional int64 startTimeAt = 7;//任务开始于某个时间
    optional int32 startTime = 8; // 任务时间s
    optional int64 coins = 9;//奖励金币
    optional ShopItem item = 10; // 奖励物品
FilePath: /SlotNirvana/src/GameModule/NewUser7Day/model/NewUser7DayGameData.lua
--]]
local ShopItem = require("data.baseDatas.ShopItem")
local NewUser7DayGameData = class("NewUser7DayGameData")

function NewUser7DayGameData:parseData(_data)
    self.m_day = tonumber(_data.day)
    self.m_taskId = tonumber(_data.taskId)
    self.m_description = _data.description
    self.m_param = tonumber(_data.param)
    self.m_progress = tonumber(_data.progress)
    self.m_status = tonumber(_data.status)
    self.m_startTimeAt = tonumber(_data.startTimeAt)
    self.m_startTime = tonumber(_data.startTime)
    self.m_coins = tonumber(_data.coins)
    if _data.item then
        self.m_itemList = self:parseItemList(_data.item)
    end
end

function NewUser7DayGameData:parseItemList(_data)
    if not _data then
        return nil
    end

    local itemList = {}

    local shopItem = ShopItem:create()
    shopItem:parseData(_data)
    table.insert(itemList, shopItem)

    return itemList
end

function NewUser7DayGameData:getDay()
    return self.m_day or 0
end

function NewUser7DayGameData:getTaskId()
    return self.m_taskId or 0
end

function NewUser7DayGameData:getDescription()
    return self.m_description
end

function NewUser7DayGameData:getTaskParam()
    return self.m_param
end

function NewUser7DayGameData:getTaskProgress()
    return self.m_progress or 0
end

function NewUser7DayGameData:getTaskStatus()
    return self.m_status
end

function NewUser7DayGameData:getStartTimeAt()
    return self.m_startTimeAt or 0
end

function NewUser7DayGameData:getStartTime()
    return self.m_startTime or 0
end

function NewUser7DayGameData:getCoins()
    return self.m_coins or 0
end

function NewUser7DayGameData:getItemList()
    return self.m_itemList or nil
end

return NewUser7DayGameData
