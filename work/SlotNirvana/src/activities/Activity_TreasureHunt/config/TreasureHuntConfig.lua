--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-15 14:56:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-15 16:00:13
FilePath: /SlotNirvana/src/activities/Activity_TreasureHunt/config/TreasureHuntConfig.lua
Description: 寻宝之旅 配置
--]]
local TreasureHuntConfig = {}

TreasureHuntConfig.EVENT_NAME = {
    ONRECIEVE_COLLECT_TREASURE_DASH_RQE = "ONRECIEVE_COLLECT_TREASURE_DASH_RQE", -- 寻宝之旅任务领取成功
    NOTICE_UPDATE_TREASURE_DASH_MACHINE_ENTRY = "NOTICE_UPDATE_TREASURE_DASH_MACHINE_ENTRY", --更新 关卡入口进度
}

return TreasureHuntConfig