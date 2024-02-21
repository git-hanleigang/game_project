--[[
Author: dhs
Date: 2022-02-22 16:46:59
LastEditTime: 2022-02-22 17:49:21
LastEditors: your name
Description: 占卜配置文件
FilePath: /SlotNirvana/src/activities/Promotion_Divination/config/DivinationConfig.lua
--]]

local DivinationConfig = {}

DivinationConfig.EVENT_NAME = {
    DIVINATION_SALE_BUY_SUCCESS = "DIVINATION_SALE_BUY_SUCCESS",    --购买成功
    DIVINATION_SALE_BUY_FAILED = "DIVINATION_SALE_BUY_FAILED",  -- 购买失败
    DIVINATION_SALE_REWARD_INDEX = "DIVINATION_SALE_REWARD_INDEX", -- 根据当前索引弹出领取奖励界面
    DIVINATION_SALE_CLOSE_MAINLAYER = "DIVINATION_SALE_CLOSE_MAINLAYER", -- 关闭主界面
    DIVINATION_SALE_COUNT_TIME = "DIVINATION_SALE_COUNT_TIME", --通知广告轮播图此时已经活动结束
    DIVINATION_SALE_BUY_GEM_SUCCESS = "DIVINATION_SALE_BUY_GEM_SUCCESS", -- 购买第二货币成功
    DIVINATION_SALE_BUY_GEM_FAILED = "DIVINATION_SALE_BUY_GEM_FAILED" -- 购买第二货币失败
}

DivinationConfig.SOUND_RES = {
    DIVINATION_BGM = "Activity/Promotion_Divination/sounds/Promotion_Divination_Bgm.mp3",
    DIVINATION_BALL = "Activity/Promotion_Divination/sounds/Promotion_Divination_Ball.mp3",
    DIVINATION_REWARD_REFRESH = "Activity/Promotion_Divination/sounds/Promotion_Divination_RewardRefresh.mp3",
    DIVINATION_REWARD_SHOW = "Activity/Promotion_Divination/sounds/Promotion_Divination_RewardShow.mp3"
}

return DivinationConfig
