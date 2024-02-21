--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-26 11:32:14
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-26 11:41:47
FilePath: /SlotNirvana/src/activities/Activity_NoviceTrail/config/ActNoviceTrailConfig.lua
Description: 新手期三日任务 config
--]]
local ActNoviceTrailConfig = {}

ActNoviceTrailConfig.TASK_STATUS = {
    UN_DONE = 1, -- 未完成
    DONE = 2, -- 完成
    COLLECTED = 3, -- 已领取
}

ActNoviceTrailConfig.EVENT_NAME = {
    COLLECT_NOVICE_TRAIL_SUCCESS = "COLLECT_NOVICE_TRAIL_SUCCESS", -- 新手三日任务领取成功
    REQ_TRAIL_NEW_DATA_SUCCESS = "REQ_TRAIL_NEW_DATA_SUCCESS", -- 请求 新手三日最新数据

    NOTIFY_NOVICE_TRAIL_TASK_UPDATE = "NOTIFY_NOVICE_TRAIL_TASK_UPDATE", -- 新手三日更新任务气泡
}
return ActNoviceTrailConfig