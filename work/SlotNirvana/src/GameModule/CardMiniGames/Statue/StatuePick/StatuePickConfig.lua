--[[
    StatuePick小游戏
    author: 徐袁
    time: 2021-03-23 11:01:38
]]
-- 小游戏状态
GD.StatuePickStatus = {
    -- 准备
    PREPARE = "PREPARE",
    PLAYING = "PLAYING",
    FINISH = "FINISH"
}

-- 游戏请求类型
GD.StatuePickGameType = {
    -- 开始
    START = 1,
    -- 开箱子
    PLAY = 2,
    -- 结算
    FINISH = 3,
    -- 购买
    PURCHASE = 4
}

-- 更新游戏信息
ViewEventType.STATUS_PICK_GAME_UPDATE = "STATUS_PICK_GAME_UPDATE"
-- 开始游戏
ViewEventType.STATUS_PICK_GAME_START = "STATUS_PICK_GAME_START"
-- 显示箱子阵列
ViewEventType.STATUS_PICK_SHOW_BOX_ARRAY = "STATUS_PICK_SHOW_BOX_ARRAY"
-- 打开箱子
ViewEventType.STATUS_PICK_OPEN_BOX = "STATUS_PICK_OPEN_BOX"
-- 游戏次数用完
ViewEventType.STATUS_PICK_PICKS_FINISHED = "STATUS_PICK_PICKS_FINISHED"
-- 游戏购买次数结果
ViewEventType.STATUS_PICK_BUY_PICKS_RESULT = "STATUS_PICK_BUY_PICKS_RESULT"
-- 游戏领奖结果
ViewEventType.STATUS_PICK_COLLECT_REWARD_RESULT = "STATUS_PICK_COLLECT_REWARD_RESULT"
-- 领取奖励完成
ViewEventType.STATUS_PICK_COLLECT_REWARD_COMPLETED = "STATUS_PICK_COLLECT_REWARD_COMPLETED"
-- 处理箱子晃动的计时器
ViewEventType.STATUS_PICK_SHAKE_TIMER = "STATUS_PICK_SHAKE_TIMER"
