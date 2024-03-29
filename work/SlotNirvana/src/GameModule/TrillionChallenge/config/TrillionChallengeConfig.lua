--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:03:51
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/config/TrillionChallengeConfig.lua
Description: 亿万赢钱挑战 配置
--]]
local TrillionChallengeConfig = {}

TrillionChallengeConfig.EVENT_NAME = {
    ONRECIEVE_TRILLION_CHALLENGE_SUCCESS = "ONRECIEVE_TRILLION_CHALLENGE_SUCCESS", --收到最新排行榜信息
    ONRECIEVE_TRILLION_BOX_TASK_COL_SUCCESS = "ONRECIEVE_TRILLION_BOX_TASK_COL_SUCCESS", --领取到宝箱奖励
    NOTIFY_TRILLION_CHALLENGE_ENTRY_RANK_UP = "NOTIFY_TRILLION_CHALLENGE_ENTRY_RANK_UP", -- 更新入口排行变化
    NOTIFY_TRILLION_CHALLENGE_ENTRY_RANK_UP_RESET = "NOTIFY_TRILLION_CHALLENGE_ENTRY_RANK_UP_RESET", -- 更新入口排行变化
    NOTIFY_REMOVE_TRILLION_CHALLENGE_HALL = "NOTIFY_REMOVE_TRILLION_CHALLENGE_HALL", -- 移除展示图
    NOTIFY_TRILLION_CHALLENGE_HIDE_OTHER_BUBBLE = "NOTIFY_TRILLION_CHALLENGE_HIDE_OTHER_BUBBLE", --隐藏 bubble
}

return TrillionChallengeConfig