--[[
Author: cxc
Date: 2022-03-23 15:54:57
LastEditTime: 2022-03-23 15:54:58
LastEditors: cxc
Description: 3日行为付费聚合活动  config
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/config/WildChallengeConfig.lua
--]]

local WildChallengeConfig = {}

-- 事件 名
WildChallengeConfig.EVENT_NAME = {
    WILD_CHALLENGE_COLLECT_SUCCESS = "WILD_CHALLENGE_COLLECT_SUCCESS", --领取成功
    WILD_CHALLENGE_COLLECT_FAILD = "WILD_CHALLENGE_COLLECT_FAILD", --领取失败

    WILD_CHALLENGE_COLSE_MIAN_LAYER = "WILD_CHALLENGE_COLSE_MIAN_LAYER", -- 关闭主面板
}

-- 阶段任务状态
WildChallengeConfig.TASK_STATE = {
    LOCK = 1, -- 锁状态
    UNLOCK = 2, -- 解锁

    UNDONE = 3, -- 不可领取
    CAN_COLLECT = 4, -- 可领取
    COLLECTED = 5, -- 已领取
    GO_COLLECT = 6, -- 去领取
}

WildChallengeConfig.NormalPhaseInterval = 650 -- 普通章节之间的间距
WildChallengeConfig.EndPhaseInterval = 700 -- 普通章节与最终章节之间的间距
WildChallengeConfig.FirstPhaseX = 500 -- 第一个章节的x位置
WildChallengeConfig.endPhaseMapX = 1100 -- 最后一个章节在最终地图中的x的位置

WildChallengeConfig.NpcOffsetX = 300 -- npc相对于章节的偏移量

WildChallengeConfig.NormalMapWidth = 1660 -- 普通章节所在的地图的宽度
WildChallengeConfig.EndMapWidth = 1724 -- 最终章节所在的地图的宽度

return WildChallengeConfig