--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-13 10:25:11
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-13 10:26:32
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/config/ExpandGameMarqueeConfig.lua
Description: 扩圈小游戏 跑马灯配置
--]]
local ExpandGameMarqueeConfig = {}

-- 游戏状态
ExpandGameMarqueeConfig.GAME_STATE = {
    START = 1,
    IDLE = 2,
    SHOW_RESULT = 3,
    OVER = 4,
}

-- 奖励-Type-res-颜色：

-- 大金币-C-A-7
-- 小金币-C-B-4
-- 乘倍-X-C-1
-- 炸弹-B-D-3
ExpandGameMarqueeConfig.TYPE_NODE_NAME = {
    A = "node_coin",
    B = "node_coin",
    C = "node_X",
    D = "node_boom"
}
ExpandGameMarqueeConfig.TYPE_BG_IDX = {
    A = "7",
    B = "4",
    C = "1",
    D = "3"
}

ExpandGameMarqueeConfig.SOUNDS = {
    BGM = "MarqueeGame/sounds/expand_game_marquee_bgm.mp3",
    BTN_PRESS = "MarqueeGame/sounds/expand_game_marquee_Start.mp3", -- 砸spin按钮
    FLY_COINS = "MarqueeGame/sounds/expand_game_marquee_Coins.mp3", --选中金币 飞金币
    FLASH = "MarqueeGame/sounds/expand_game_marquee_Light.mp3", --奖励闪烁
    FLY_DOUBLE = "MarqueeGame/sounds/expand_game_marquee_Double.mp3", -- 选中成倍 飞成倍
    BOOM = "MarqueeGame/sounds/expand_game_marquee_Boom.mp3", --选中炸弹 爆炸
    COINS_DOWN = "MarqueeGame/sounds/expand_game_marquee_Boom_Fail.mp3", --选中炸弹 金币清0
}

ExpandGameMarqueeConfig.EVENT_NAME = {
    --net 
    PLAY_EXPAND_MINI_GMAE_SUCCESS = "PLAY_EXPAND_MINI_GMAE_SUCCESS", --玩游戏接口请求成功
    PLAY_EXPAND_MINI_GMAE_FAILD = "PLAY_EXPAND_MINI_GMAE_FAILD", --玩游戏接口请求成功

    COLLECT_EXPAND_MINI_GMAE_SUCCESS = "COLLECT_EXPAND_MINI_GMAE_SUCCESS", --小游戏结算成功
}
return ExpandGameMarqueeConfig