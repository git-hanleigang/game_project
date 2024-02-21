--[[
Author: cxc
Date: 2022-04-12 16:53:21
LastEditTime: 2022-04-12 16:53:22
LastEditors: cxc
Description: 头像信息 config
FilePath: /SlotNirvana/src/GameModule/Avatar/config/AvatarFrameConfig.lua
--]]
local AvatarFrameConfig = {}

AvatarFrameConfig.EVENT_NAME = {
    -- ui
    UPDATE_ENTRY_PROGRESS = "UPDATE_ENTRY_PROGRESS",  -- 更新关卡入口任务进度
    CLICK_SELECT_TASK_CELL = "CLICK_SELECT_TASK_CELL", -- 点击选择头像框任务

    -- net
    RECIEVE_HOT_PLAYER_LIST_SUCCESS = "RECIEVE_HOT_PLAYER_LIST_SUCCESS", -- 请求关卡热玩玩家信息成功
} 
ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE = "NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE" --头像框相关资源下载完成
ViewEventType.NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI = "NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI" --头像卡到期卸下自己的头像框

AvatarFrameConfig.SOUND_ENUM = {
    SLOT_TASK_COMPLETE_SHOW = "Activity/sounds/slot_task_complete_show.mp3",
    SLOT_TASK_COMPLETE_REWARD = "Activity/sounds/slot_task_complete_reward.mp3"
}

-- 下载列表
AvatarFrameConfig.DownloadList = {
    "CommonAvatar",
    "AvatarFrameItem",
    "AvatarFrameSlotSeason1_6",
    "AvatarFrameSlotSeason7_12"
}

return AvatarFrameConfig