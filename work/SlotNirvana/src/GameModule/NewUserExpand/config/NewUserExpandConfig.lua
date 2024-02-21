--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-06 14:41:03
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-06 14:58:25
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/config/NewUserExpandConfig.lua
Description: 扩圈系统 config
--]]
local NewUserExpandConfig = {}

-- 下游戏下载key
NewUserExpandConfig.GMAE_DL_KEY = {
    wheel = "wheel",  -- 轮盘  
    -- pyi = "ExpandGamePlinko",  -- 走马灯  
    pyi = "ExpandGameMarquee",  -- 走马灯  
    tq = "ExpandGamePlinko",  -- 弹球  
    whacamole = "whacamole",  -- 砸地鼠小游戏  
    roulette = "roulette",  -- 俄罗斯转盘or轮盘赌  
    Arcade = "Arcade",  -- 射击街机  
    NDJ = "NDJ",  -- 扭蛋机  
    Rainbow = "Rainbow",  -- 综艺节目，丢彩虹  
    Cup = "Cup",  -- 民间玩法，杯子猜球  
    Bingo = "Bingo",  -- 宾果玩法  
    AngryBird = "AngryBird",  -- 愤怒的小鸟  
    SkeeBall = "SkeeBall",  -- SkeeBall  
    Darts = "Darts",  -- 飞镖  
    Throw = "Throw",  -- 抛东西玩法  
    Solitaire = "Solitaire",  -- 空当接龙等纸牌玩法  
    ShuffleBoard = "ShuffleBoard",  -- 沙壶球  
}
NewUserExpandConfig.MINI_GAME_MGR_NAME ={
    ExpandGameMarquee = "ExpandGameMarqueeMgr", -- 跑马灯游戏
    ExpandGamePlinko = "ExpandGamePlinkoMgr", --弹球游戏
}

-- 大厅 风格type
NewUserExpandConfig.LOBBY_TYPE = {
    SLOTS = 1, -- 原始显示一堆关卡
    PUZZLE = 2, -- 显示扩圈小游戏
    COL_LEVELS = 3, -- 收藏关卡
}

-- 破圈任务转态
NewUserExpandConfig.TASK_STATE = {
    LOCK = 1, -- 锁状态
    UNLOCK_ANI = 2, --解锁动画
    UNLOCK = 3, -- 解锁
    DONE_ANI = 4, --完成动画
    DONE = 5, -- 完成
}

NewUserExpandConfig.EVENT_NAME = {
    --UI
    UPDATE_LOBBY_VIEW_EXPAND_TYPE = "UPDATE_LOBBY_VIEW_EXPAND_TYPE", --更新大厅显示类型
    NOTIFY_CHECK_REFRESH_TASK_STATE = "NOTIFY_CHECK_REFRESH_TASK_STATE", --更新扩圈任务状态
    COMPLETE_MINI_GAME_BACK_EXPAND_UI = "COMPLETE_MINI_GAME_BACK_EXPAND_UI", --完成小游戏返回扩圈大厅
    LOAD_EXPAND_FEATURE = "LOAD_EXPAND_FEATURE", --加载扩圈系统
    NOTIFY_CHECK_GUIDE_EXPAND_ENTRY = "NOTIFY_CHECK_GUIDE_EXPAND_ENTRY", -- 引导 4  引导解锁障碍物完成 后 引导 扩圈入口到slots

    -- net
    ACTIVE_EXPAND_NEW_TASK_SUCCESS = "ACTIVE_EXPAND_NEW_TASK_SUCCESS", --激活扩圈任务系统
}

-- 游戏结束解锁下一关请求 actionName
NewUserExpandConfig.MINI_GAME_ACTION_NAME = {
    ExpandGameMarquee = "ExpandCirclePyiNext", -- 跑马灯游戏
    ExpandGamePlinko = "ExpandCircleTqNext", --弹球游戏
}

-- 下游戏mainUI lua Name
NewUserExpandConfig.MINI_GAME_MAIN_UI_LUA_NAME = {
    ExpandGameMarquee = "ExpandGameMarqueeMainUI", -- 跑马灯游戏
    ExpandGamePlinko = "ExpandGamePlinkoMainUI", --弹球游戏
}

NewUserExpandConfig.SOUNDS = {
    REWARD_POP = "NewUser_Expend/Activity/sounds/expand_reward_show.mp3" -- 奖励弹板
}

return NewUserExpandConfig