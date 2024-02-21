--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-11 16:25:25
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-11 16:25:39
FilePath: /SlotNirvana/src/GameModule/PiggyClicker/config/PiggyClickerGameConfig.lua
Description: 快速点击小游戏 config
--]]
local PiggyClickerGameConfig = {}

-- 事件
PiggyClickerGameConfig.EVENT_NAME = {
    -- net
    PIGGY_CLICKER_BUY_SUCCESS = "PIGGY_CLICKER_BUY_SUCCESS", --付费成功
    PIGGY_CLICKER_START_GAME_SUCCESS = "PIGGY_CLICKER_START_GAME_SUCCESS", -- 开始游戏成功
    PIGGY_CLICKER_START_GAME_FAILD = "PIGGY_CLICKER_START_GAME_FAILD",-- 开始游戏失败
    PIGGY_CLICKER_COLLECT_GAME_SUCCESS = "PIGGY_CLICKER_COLLECT_GAME_SUCCESS", --付费成功

    -- UI
    PIGGY_CLICKER_TOUCH_BOSS_START_GAME = "PIGGY_CLICKER_TOUCH_BOSS_START_GAME", --点击boss开始游戏
    PIGGY_CLICKER_GAME_REFRESH_PAY_STYLE = "PIGGY_CLICKER_GAME_REFRESH_PAY_STYLE", -- 游戏 切换付费模式
    PIGGY_CLICKER_GAME_OVER_CLOSE = "PIGGY_CLICKER_GAME_OVER_CLOSE", -- 游戏结束关闭游戏
}

-- 游戏 状态
PiggyClickerGameConfig.GAME_STATE = {
    START = 1,  --开始播放过场动画
    IDLE = 2, -- 播完过场动画 静态 未点击boss
    START_CD = 3, -- 点击boss 开始游戏cd
    PLAYING = 4, -- 游戏中
    PLAYINGEND = 5, -- 游戏结束结算中
    FREE_PAY = 6, -- 免费版付费中
    OVER = 7,  --游戏结束
}

-- 产生的道具类型
PiggyClickerGameConfig.TASK_ITEM_TYPE = {
    COINS = 1,
    GEMS = 2,
    JACKPOT = 3,
}

-- 游戏所用音效
PiggyClickerGameConfig.MUSIC_ENUM = {
    GAME_BGM = "Activity/Sounds/PiggyClicker_BGM.mp3", --背景音乐
    CUTSCENE_WELCOME = "Activity/Sounds/PiggyClicker_cutscene_welcome.mp3", --CTS系统-Piggy Clicker-进入小游戏短乐+Welcome to Piggy Clicker!
    CUTSCENE_PAY = "Activity/Sounds/PiggyClicker_cutscene_pay.mp3", -- CTS系统-Piggy Clicker-转场升级
    TIME_GO = "Activity/Sounds/PiggyClicker_countdown_go.mp3", -- CTS系统-Piggy Clicker-倒计时人声：321，GO
    TIME_OVER = "Activity/Sounds/PiggyClicker_countdown_over.mp3", -- CTS系统-Piggy Clicker-游戏倒计时剩余5秒时人声提示：54321
    BOSS_HIT = "Activity/Sounds/PiggyClicker_boss_hit.mp3", -- CTS系统-Piggy Clicker-猪boss被打时的音效
    DROP_CURRENCY = "Activity/Sounds/PiggyClicker_drop_currency.mp3", -- CTS系统-Piggy Clicker-猪掉落宝石金币
    DROP_JACKPOT = "Activity/Sounds/PiggyClicker_drop_jackpot.mp3", -- CTS系统-Piggy Clicker-获得jackpot进度道具宝石的音效
    JACKPOT_ADD = "Activity/Sounds/PiggyClicker_jackpot_add.mp3", -- CTS系统-Piggy Clicker-jackpot进度增加时的音效
    JACKPOT_DONE = "Activity/Sounds/PiggyClicker_jackpot_done.mp3", -- CTS系统-Piggy Clicker-jackpot获得后的音效（jackpot的idle动画）
    REWARD_NORMAL = "Activity/Sounds/PiggyClicker_reward_normal.mp3", -- CTS系统-Piggy Clicker-普通中奖结算界面触发（喜悦）
    REWARD_PAY = "Activity/Sounds/PiggyClicker_reward_pay.mp3", -- CTS系统-Piggy Clicker-付费版中奖结算界面触发（喜悦）
    PAY_LAYER_POP = "Activity/Sounds/PiggyClicker_pay_layer_pop.mp3", -- CTS系统-Piggy Clicker-付费弹板弹出
}

return PiggyClickerGameConfig