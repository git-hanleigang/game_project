--[[
Author: cxc
Date: 2021-06-11 14:18:30
LastEditTime: 2021-06-18 16:55:06
LastEditors: Please set LastEditors
Description: 活动 config
FilePath: /SlotNirvana/src/activities/Activity_RippleDash/config/Activity_RippleDashConfig.lua
--]]

local Activity_RippleDashConfig = {}

-- 奖励 状态
Activity_RippleDashConfig.RewardState = {
	LOCK = 1, -- 锁定状态
	UN_COMPLETE = 2, -- 未完成
	UN_GAIN = 3, -- 完成未领取
	GAIN = 4, -- 已领取
	GO_GAIN = 5, --去领取
}

Activity_RippleDashConfig.EventName = {
	NOTIFY_COLLECT_RD_REWARD_SUCCESS = "NOTIFY_COLLECT_RD_REWARD_SUCCESS", -- 领取奖励成功
	NOTIFY_RIPPLE_DASH_BUY_SUCCESS = "NOTIFY_RIPPLE_DASH_BUY_SUCCESS", -- 充值成功

	NOTIFY_HIDE_OTHER_BUBBLE_TIP = "NOTIFY_HIDE_OTHER_BUBBLE_TIP", -- 隐藏气泡
}

return Activity_RippleDashConfig