--[[
Author: cxc
Date: 2021-11-18 20:16:21
LastEditTime: 2021-11-18 20:18:15
LastEditors: cxc
Description: 乐透 config
FilePath: /SlotNirvana/src/GameModel/Lottery/config/LotteryConfig.lua
--]]

local LotteryConfig = {}

LotteryConfig.BALL_TYPE = {
    SHOW = 1,
    CHOOSE = 2
}

--消息事件定义
LotteryConfig.EVENT_NAME = {
    -- UI
    UPDATE_FAQ_LISTVIEW = "UPDATE_FAQ_LISTVIEW" , -- 点击faqcell右边按钮更新listView
    UPDATE_FAQ_LAST_LISTVIEW = "UPDATE_FAQ_LAST_LISTVIEW" , -- 点击faqcell右边按钮更新前一个listView
    CLOSE_OPEN_REWARD_LAYER = "CLOSE_OPEN_REWARD_LAYER", -- 关闭开奖界面
    SKIP_OPEN_REWARD_STEP = "SKIP_OPEN_REWARD_STEP", -- 跳过开奖步骤

    CHOOSE_NUMBER_SELECT = "CHOOSE_NUMBER_SELECT", --选择号码 _选择
    CHOOSE_NUMBER_CANCEL = "CHOOSE_NUMBER_CANCEL", --选择号码 _取消选择
    CHOOSE_NUMBER_UPDATE_BALL_CHOOSE_STATE = "CHOOSE_NUMBER_UPDATE_BALL_CHOOSE_STATE", -- 选择号码更新选择状态

    SHOW_OPEN_NUMBER_UI = "SHOW_OPEN_NUMBER_UI", --显示摇晃出来的号码
    MACHINE_GENERATE_NUMBER_OVER = "MACHINE_GENERATE_NUMBER_OVER", --摇号机器摇号完毕
    PLAY_REWARD_NUMBER_ACT = "PLAY_REWARD_NUMBER_ACT", --播放中奖号码特效
    STOP_PLAYER_REWARD_NUMBER_ACT = "STOP_PLAYER_REWARD_NUMBER_ACT", --停止播放中奖号码特效
    OPEN_ADD_COINS_UI = "OPEN_ADD_COINS_UI", --开奖中奖cell金币粒子飞完增加底部栏金币数

    CLOSE_TICKET_LAYER = "CLOSE_TICKET_LAYER", --关闭单独的奖券弹框

    GUIDE_EFFECT = "GUIDE_EFFECT", --新手引导第二步显示动效
    GUIDE_EFFECT_STOP = "GUIDE_EFFECT_STOP", --新手引导第三步关闭动效
    GUIDE_FINAL_STEP = "GUIDE_FINAL_STEP", --新手引导第三步关闭遮罩

    MACHINE_OVER_FORCE_STOP_NPC_AUDIO = "MACHINE_OVER_FORCE_STOP_NPC_AUDIO", --机器摇晃玩强制结束npc说话
    MACHINE_OVER_NPC_AUDIO = "MACHINE_OVER_NPC_AUDIO", --机器摇晃结束npc说话 领奖
    MACHINE_WOBBLE_NEXT_BALL = "MACHINE_WOBBLE_NEXT_BALL", -- 机器摇晃下一个球
    SHOW_FIRST_NUMBER_NPC_SAY = "SHOW_FIRST_NUMBER_NPC_SAY", -- 显示摇晃出第一个号码 - npc说话
    NPC_SAY_NUMBER_AUDIO_EVT = "NPC_SAY_NUMBER_AUDIO_EVT", -- npc读数字
    
    --广告图数据刷新
    LOTTERY_HALLNODE_UPDATE_DATA = "LOTTERY_HALLNODE_UPDATE_DATA", --大厅广告位倒数计时数据刷新

    -- NET
    RECIEVE_HISTORY_LIST = "RECIEVE_HISTORY_LIST", -- 开奖历史记录
    RECIEVE_SYNC_CHOOSE_NUMBER = "RECIEVE_SYNC_CHOOSE_NUMBER", -- 同步选择的号码
    RECIEVE_GENERATE_RANDOM_NUMBER = "RECIEVE_GENERATE_RANDOM_NUMBER", -- 机选随机的号码
    RECIEVE_COLLECT_REWARD = "RECIEVE_COLLECT_REWARD", -- 领取乐透中奖奖励
    TIME_END_CLOSE_CHOOSE_NUMBER_CODE = "TIME_END_CLOSE_CHOOSE_NUMBER_CODE", -- 选号时间结束关闭选号功能

    -- 新增
    CREATE_RANDOM_NUMBER_SUCCESS = "CREATE_RANDOM_NUMBER_SUCCESS", -- 掉落弹板界面一键选号
    CLOSE_LOTTERY_TICKET_PANEL = "CLOSE_LOTTERY_TICKET_PANEL" -- 关闭掉落弹板
}

--用来处理自动领取，玩家手动点击
ViewEventType.AUTO_RECEIVE_SIGN = "AUTO_RECEIVE_SIGN"

-- 乐透开奖 npc 音效
LotteryConfig.NPC_WORD_AUDIO_INFO = {
    -- GUO_CHANG = {path = "Lottery/sounds/reward/Lottery_start_introduce.mp3", time = 3, bWaiting=false},  -- 过场动画
    -- NPC_START = {path = "Lottery/sounds/reward/Lottery_start_npc_presenter.mp3", time = 1, bWaiting=false}, -- npc介绍自己
    -- SHOW_YOURS = {path = "Lottery/sounds/reward/Lottery_show_yours_number_list.mp3", time = 5, bWaiting=false}, -- 展示自己的下注列表
    OPEN_START = {path = "Lottery/sounds/reward/Lottery_open_start_introduce.mp3", time = 12}, -- 开奖介绍
    MACHINE_START = {path = "Lottery/sounds/reward/Lottery_machine_start.mp3", time = 0}, -- 机器开始转动
    FIRST_NUMBER = {path = "Lottery/sounds/reward/Lottery_read_first_number.mp3", time = 0}, -- 第一个数字是：
    NEXT_NUMBER = {path = "Lottery/sounds/reward/Lottery_read_next_number.mp3", time = 0}, -- 下一个数字是：
    SWITCH_BALL = {path = "Lottery/sounds/reward/Lottery_switch_red_ball.mp3", time = 5}, -- 机器开始切换到红球
    OVER = {path = "Lottery/sounds/reward/Lottery_open_reward_over.mp3", time = 6}, -- 开奖结束 下次见
}

return LotteryConfig