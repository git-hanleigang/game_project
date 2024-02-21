--[[
Author: cxc
Date: 2022-02-15 12:19:40
LastEditTime: 2022-02-15 12:19:41
LastEditors: cxc
Description: 高倍场 合成小游戏 合成周卡活动 config
FilePath: /SlotNirvana/src/activities/Activity_DeluxeMerge/config/ActivityMergeWeekConfig.lua
--]]

local ActivityMergeWeekConfig = {}

ActivityMergeWeekConfig.DAY_REWARD_STATE = {
    LOCK = 1, -- 锁状态
    UNLOCK = 2, -- 解锁

    UNDONE = 3, -- 不可领取
    CAN_COLLECT = 4, -- 可领取
    COLLECTED = 5, -- 已领取
    GO_COLLECT = 6, -- 去领取
}

ActivityMergeWeekConfig.EVENT_NAME = {
    MERGE_WEEK_BUY_SUCCESS = "MERGE_WEEK_BUY_SUCCESS", -- 合成周卡购买成功
    MERGE_WEEK_COLLECT_SUCCESS = "MERGE_WEEK_COLLECT_SUCCESS", -- 合成周卡领取成功

    MERGE_WEEK_BTN_COLLECT_ENABLED = "MERGE_WEEK_BTN_COLLECT_ENABLED", -- 更新领取按钮触摸状态
    MERGE_WEEK_SHOW_REWARD_LAYER = "MERGE_WEEK_SHOW_REWARD_LAYER", -- 领取成功弹奖励弹板
}

return ActivityMergeWeekConfig