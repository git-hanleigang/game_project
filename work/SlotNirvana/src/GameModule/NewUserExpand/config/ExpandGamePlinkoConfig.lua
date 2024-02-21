--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 16:23:20
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 16:23:42
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/config/ExpandGamePlinkoConfig.lua
Description: 扩圈小游戏 弹珠 配置
--]]

local ExpandGamePlinkoConfig = {}

-- 游戏状态
ExpandGamePlinkoConfig.GAME_STATE = {
    START = 1,
    IDLE = 2,
    DROP_BALL = 3,
    OVER = 4,
}

-- 发射器状态
ExpandGamePlinkoConfig.LAUNCH_STATE = {
    MOVE = 1,
    LAUNCH = 2,
    STOP = 3,
}

-- 球 和 钉子半径 以此求球偏移位置
ExpandGamePlinkoConfig.RADIUS = {
    BALL = 11,
    DING = 23
}

ExpandGamePlinkoConfig.EVENT_NAME = {

    SPIN_SUCCESS_AND_DROP_BALL = "SPIN_SUCCESS_AND_DROP_BALL", -- spin掉球

}

ExpandGamePlinkoConfig.SOUNDS = {
    BGM = "PlinkoGame/sounds/expand_game_plinko_bgm.mp3",
    BTN_PRESS_START = "PlinkoGame/sounds/expand_game_plinko_Start.mp3", -- 砸spin start按钮
    BTN_PRESS_STOP = "PlinkoGame/sounds/expand_game_plinko_Stop.mp3", -- 砸spin stop按钮
    LAUNCH_MOVE = "PlinkoGame/sounds/expand_game_plinko_ready.mp3", -- 界面上方出球口滑动
    DROP_BALL = "PlinkoGame/sounds/expand_game_plinko_Ball_Go.mp3", -- 出球口吐出金币
    BALL_DING = "PlinkoGame/sounds/expand_game_plinko_Ding.mp3", -- 金币与钉子碰撞出现的音效
    BALL_REWARD = "PlinkoGame/sounds/expand_game_plinko_Ball_End.mp3", -- 金币落入奖励槽，奖励槽发光
    COIN_CHANGE = "PlinkoGame/sounds/expand_game_plinko_Reward_title.mp3", -- 上UI发光，金币滚动上涨（不需要滚动音效）
}

return ExpandGamePlinkoConfig