--[[
    
]]

local DragonChallengeConfig = {}

DragonChallengeConfig.notify_buy_buff_sale = "notify_buy_buff_sale" -- buff促销
DragonChallengeConfig.notify_buy_wheel_sale = "notify_buy_wheel_sale" -- 转盘促销
DragonChallengeConfig.notify_spin_get_wheel = "notify_spin_get_wheel" -- spin获得活动转盘
DragonChallengeConfig.notify_wheel_spin = "notify_wheel_spin" -- wheelSpin
DragonChallengeConfig.notify_attack_end = "notify_attack_end" -- 攻击结束
DragonChallengeConfig.notify_progress_box_close = "notify_progress_box_close" -- 进度宝箱领取结束
DragonChallengeConfig.notify_mission_reward_close = "notify_mission_reward_close" -- 任务奖励领取结束
DragonChallengeConfig.notify_boss_injured_end = "notify_boss_injured_end" -- boss受伤结束
DragonChallengeConfig.notify_refresh_data = "notify_refresh_data" -- 刷新数据
DragonChallengeConfig.notify_go_spin = "notify_go_spin"
DragonChallengeConfig.notify_show_reward_bubble = "notify_show_reward_bubble"
DragonChallengeConfig.notify_hide_reward_bubble = "notify_hide_reward_bubble"
DragonChallengeConfig.notify_switch_area = "notify_switch_area"
DragonChallengeConfig.notify_pass_bubble_close = "notify_dragonChallenge_pass_bubble_close" --pass气泡关闭
--pass
DragonChallengeConfig.notify_pass_get_reward = "notify_dragonChallenge_pass_get_reward" --pass领奖
DragonChallengeConfig.notify_show_buff_bubble = "notify_show_buff_bubble" -- 显示buff气泡

DragonChallengeConfig.buy_type = "DragonChallengeSale"

DragonChallengeConfig.buff_type = "DragonChallengeDamageBuff"

DragonChallengeConfig.DRAGON_TYPE = {
    "red",
    "green",
    "blue",
    "black"
}
DragonChallengeConfig.passTypeEnum = {
    ONE = 1, -- 
    TWO = 2, -- 
    THREE = 3, -- 
    FOUR = 4, -- 
}

DragonChallengeConfig.passTypeSpPath = {
    "Activity_DragonChallenge/Activity/ui/pass/main/DragonPass_PayRed2.png",
    "Activity_DragonChallenge/Activity/ui/pass/main/DragonPass_PayGreen2.png",
    "Activity_DragonChallenge/Activity/ui/pass/main/DragonPass_PayBlue2.png",
    "Activity_DragonChallenge/Activity/ui/pass/main/DragonPass_PayBlack2.png",
}
-- 龙spine的状态动画
--[[
    beat_1 切换濒死状态
    beat_2 切换死亡状态
    strong_beat_1 由免伤状态切换濒死状态
    strong_beat_2 由免伤状态切换死亡状态
    weak_beat_1 由易伤状态切换濒死状态
    weak_beat_2 由易伤状态切换死亡状态

    hit_1_1 普通攻击
    hit_1_2 暴击
    hit_1_3 连续攻击
    hit_2_1 普通攻击 -- 濒死状态
    hit_2_2 暴击
    hit_2_3 连续攻击

    idle_1 待机
    idle_2 濒死待机
    idle_3 死亡待机
    over   退场
    start  入场

    strong_1 切换减伤状态
    strong_2 切换减伤状态 -濒死状态
    strong_common_1 切换普通状态
    strong_common_2 切换普通状态 -濒死状态
    strong_weak_1 切换易伤状态
    strong_weak_2 切换易伤状态 -濒死状态
    strong_idle_1 强化 待机
    strong_idle_2 强化 待机 -濒死状态
    strong_hit_1_1 普通攻击
    strong_hit_1_2 暴击
    strong_hit_1_3 连续攻击
    strong_hit_2_1 普通攻击 -- 濒死状态
    strong_hit_2_2 暴击
    strong_hit_2_3 连续攻击


    weak_1 切换易伤状态
    weak_2 切换易伤状态 -濒死状态
    weak_common_1 切换普通状态
    weak_common_2 切换普通状态 -濒死状态
    weak_strong_1 切换免伤状态
    weak_strong_2 切换免伤状态 -濒死状态
    weak_idle_1 易伤 待机
    weak_idle_2 易伤 待机 -濒死状态
    weak_hit_1_1 普通攻击
    weak_hit_1_2 暴击
    weak_hit_1_3 连续攻击
    weak_hit_2_1 普通攻击 -- 濒死状态
    weak_hit_2_2 暴击
    weak_hit_2_3 连续攻击
]]

return DragonChallengeConfig