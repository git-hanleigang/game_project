local StarryFestPublicConfig = {}

StarryFestPublicConfig.SoundConfig = {
    --CTS关卡-独立日-音乐-basegame1.0(75,am)
    Music_Base_Bg = "StarryFestSounds/StarryFest_base_music.mp3",
    --CTS关卡-独立日-音乐-freegame1.0(133,am)
    Music_FG_Bg = "StarryFestSounds/StarryFest_fg_music.mp3",
    --CTS关卡-独立日-音乐-特殊spin1.0(120,am)
    Music_Special_Spin_Bg = "StarryFestSounds/StarryFest_special_spin_music.mp3",
    --CTS关卡-独立日-音乐-SuperFG1.0(187,C)
    Music_SupeerFG_Bg = "StarryFestSounds/StarryFest_super_fg_music.mp3",
    --CTS关卡-独立日-进入关卡短乐+Come and join the grand celebration!
    Music_Enter_Game = "StarryFestSounds/StarryFest_enter_game.mp3",
    --CTS关卡-独立日-点击
    Music_Normal_Click = "StarryFestSounds/StarryFest_normal_click.mp3",
    --CTS关卡-独立日-预告中奖+Look! Fireworks
    Music_YuGao_Sound = "StarryFestSounds/StarryFest_yuGao_sound.mp3",
    --CTS关卡-独立日-FG开始弹板弹出
    Music_Fg_StartStart = "StarryFestSounds/StarryFest_fgStart_start.mp3",
    --CTS关卡-独立日-FG开始弹板收回
    Music_Fg_startOver = "StarryFestSounds/StarryFest_fgStart_over.mp3",
    --CTS关卡-独立日-BG进入FG过场动画
    Music_Base_Fg_CutScene = "StarryFestSounds/StarryFest_baseToFree.mp3",
    --CTS关卡-独立日-Bonus1图标锁定框生成_升级
    Music_Bonus_Lock = "StarryFestSounds/StarryFest_bonusLock.mp3",
    --CTS关卡-独立日-下方赢钱区反馈光效（星星）
    Music_Bottom_FeedBack1 = "StarryFestSounds/StarryFest_bottom_feedBack_mul_1.mp3",
    --CTS关卡-独立日-2X下方赢钱区反馈光效（星星）
    Music_Bottom_FeedBack2 = "StarryFestSounds/StarryFest_bottom_feedBack_mul_2.mp3",
    --CTS关卡-独立日-3X下方赢钱区反馈光效（星星）
    Music_Bottom_FeedBack3 = "StarryFestSounds/StarryFest_bottom_feedBack_mul_3.mp3",
    --CTS关卡-独立日-JP弹板弹出+GRAND JACKPOT!
    --CTS关卡-独立日-JP弹板弹出+SUPER JACKPOT!
    --CTS关卡-独立日-JP弹板弹出+MAXI JACKPOT!
    --CTS关卡-独立日-JP弹板弹出+MEGA JACKPOT！
    --CTS关卡-独立日-JP弹板弹出+MAJOR JACKPOT!
    --CTS关卡-独立日-JP弹板弹出+MINOR JACKPOT!
    --CTS关卡-独立日-JP弹板弹出+MINI JACKPOT!
    Music_Jackpot_Reward = {
        "StarryFestSounds/StarryFest_jackpot_1.mp3",
        "StarryFestSounds/StarryFest_jackpot_2.mp3",
        "StarryFestSounds/StarryFest_jackpot_3.mp3",
        "StarryFestSounds/StarryFest_jackpot_4.mp3",
        "StarryFestSounds/StarryFest_jackpot_5.mp3",
        "StarryFestSounds/StarryFest_jackpot_6.mp3",
        "StarryFestSounds/StarryFest_jackpot_7.mp3",
    },
    --CTS关卡-独立日-JP数字滚动
    Music_Jackpot_Jump_Coins = "StarryFestSounds/StarryFest_jackpotJumpCoins.mp3",
    --CTS关卡-独立日-JP数字滚动结束音
    Music_Jackpot_Jump_Stop = "StarryFestSounds/StarryFest_jackpotJumpStop.mp3",
    --CTS关卡-独立日-JP弹板收回
    Music_Jackpot_Over = "StarryFestSounds/StarryFest_jackpot_over.mp3",
    --CTS关卡-独立日-大赢前预告中奖
    Music_Celebrate_Win = "StarryFestSounds/StarryFest_celebrate_win.mp3",
    --CTS关卡-独立日-FG结算弹板弹出+Nice~
    Music_Fg_OverStart = "StarryFestSounds/StarryFest_fgOver_start.mp3",
    --CTS关卡-独立日-FG结算弹板收回
    Music_Fg_OverOver = "StarryFestSounds/StarryFest_fgOver_over.mp3",
    --CTS关卡-独立日-FG回到BG过场动画
    Music_Fg_Base_CutScene = "StarryFestSounds/StarryFest_freeToBase.mp3",
    --CTS关卡-独立日-SFG进度条集满触发+Super fun
    Music_SuperFg_Trigger = "StarryFestSounds/StarryFest_superFg_trigger.mp3",
    --CTS关卡-独立日-SFG开始弹板弹出
    Music_SuperFg_StartStart = "StarryFestSounds/StarryFest_superFgStart_start.mp3",
    --CTS关卡-独立日-BG进入SFG过场动画
    Music_Base_SuperFg_CutScene = "StarryFestSounds/StarryFest_baseToSuperFree.mp3",
    --CTS关卡-独立日-锁定框扩散
    Music_Bonus_Lock_Side = "StarryFestSounds/StarryFest_bonusLockSide.mp3",
    --CTS关卡-独立日-SFG结算弹板弹出+Wonderful!
    Music_SuperFg_OverStart = "StarryFestSounds/StarryFest_superFgOver_start.mp3",
    --CTS关卡-独立日-SFG回到BG过场动画
    Music_SuperFg_Base_CutScene = "StarryFestSounds/StarryFest_superFg_base.mp3",
    --CTS关卡-独立日-乘倍砸向JP栏
    Music_Jackpot_Mul_Move = "StarryFestSounds/StarryFest_jackpot_mul_move.mp3",
    --CTS关卡-独立日-SFG进度条增加
    Music_SuperCollect_Add = "StarryFestSounds/StarryFest_superCollectAdd.mp3",
    --CTS关卡-独立日-玩法文本弹出
    Music_Jackpot_PlayRule_Open = "StarryFestSounds/StarryFest_jackpot_playRuleOpen.mp3",
    --CTS关卡-独立日-玩法文本收回
    Music_Jackpot_PlayRule_Close = "StarryFestSounds/StarryFest_jackpot_playRuleClose.mp3",
    --CTS关卡-独立日-BET锁定
    Music_Jackpot_Bet_Lock = "StarryFestSounds/StarryFest_jackpot_betLock.mp3",
    --CTS关卡-独立日-BET解锁
    Music_Jackpot_Bet_UnLock = "StarryFestSounds/StarryFest_jackpot_betUnLock.mp3",
    --CTS关卡-独立日-5X锁定框结算+Shinning point~
    Music_Bonus_MaxMul_Reward = "StarryFestSounds/StarryFest_bonus_maxMul_reward.mp3",
    --CTS关卡-独立日-Shinning point~
    Music_Bonus_Shinning_Point = "StarryFestSounds/StarryFest_bonus_shinning_point.mp3",
    --CTS关卡-独立日-Aha!.mp3
    --CTS关卡-独立日-Smiling attracts luck~
    --CTS关卡-独立日-WoW!
    Music_Celebrate_Win_More = {
        "StarryFestSounds/StarryFest_celebrate_win_more_1.mp3",
        "StarryFestSounds/StarryFest_celebrate_win_more_2.mp3",
        "StarryFestSounds/StarryFest_celebrate_win_more_3.mp3",
    },
    --CTS关卡-独立日-Festivity spin 动画+Good Luck~
    --CTS关卡-独立日-Festivity spin 动画+Wish for the best~
    Music_Special_Spin_Sound =
    {
        "StarryFestSounds/StarryFest_special_spin_1.mp3",
        "StarryFestSounds/StarryFest_special_spin_2.mp3",
    } 
}


return StarryFestPublicConfig