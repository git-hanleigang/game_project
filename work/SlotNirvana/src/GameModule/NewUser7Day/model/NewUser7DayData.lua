--[[
Author: dhs
Date: 2022-05-06 17:57:30
LastEditors: bogon
LastEditTime: 2022-05-26 17:59:04
FilePath: /SlotNirvana/src/GameModule/NewUser7Day/model/NewUser7DayData.lua
Description: 新手7日目标 数据解析
--]]
--[[
    optional VegasTripTask current = 1;//当前任务
    repeated VegasTripTask next = 2;//下一个任务
]]
--[[
    VegasTripTask:
    optional int32 day = 1; // 第几天
    optional int64 taskId = 2;//任务Id
    optional string description = 3;//任务描述
    optional int64 param = 4;//任务参数
    optional int64 progress = 5;//任务进度
    optional int32 status = 6; // 任务状态 0未开启 1已开启 2已完成 3已领奖
    optional int64 startTimeAt = 7;//任务开始时间
    optional int32 startTime = 8; // 任务开始时间
    optional int64 coins = 9;//奖励金币
    optional ShopItem item = 10; // 奖励物品
]]
local NewUser7DayGameData = util_require("GameModule.NewUser7Day.model.NewUser7DayGameData")
local NewUser7DayData = class("NewUser7DayData")

function NewUser7DayData:ctor(_data)
    self.m_open = false
    self.m_nextData = {}
end

function NewUser7DayData:parseData(_data)
    if not _data then
        return
    end

    if _data.current then
        local curGameData = NewUser7DayGameData:create()
        curGameData:parseData(_data.current)
        self.m_currentData = curGameData
    end

    if _data.next then
        --数组
        for i = 1, #(_data.next or {}) do
            local nextData = _data.next[i]
            local nextGameData = NewUser7DayGameData:create()
            nextGameData:parseData(nextData)
            local day = nextGameData:getDay()
            local nextTempData = {
                index = day,
                gameData = nextGameData
            }
            table.insert(self.m_nextData, nextTempData)
        end
    end
    self.m_open = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POP_NEW_USER_7DAY) -- 刷新新手7日目标TopNode红点
end

function NewUser7DayData:parseCurrentData(_data)
    if not _data then
        return
    end
    local curGameData = NewUser7DayGameData:create()
    curGameData:parseData(_data)
    self.m_currentData = curGameData
end

function NewUser7DayData:getCurrentData()
    return self.m_currentData
end

function NewUser7DayData:getNextData()
    return self.m_nextData or nil
end

-- 检查功能是否开启
function NewUser7DayData:checkFuncOpen()
    return self.m_open
end

return NewUser7DayData
