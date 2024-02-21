local TurkeyDayPublicConfig = {}

TurkeyDayPublicConfig.SoundConfig = {
    --CTS关卡-老母鸡感恩节-音乐-Basegame 3.0（C，145）
    Music_Base_Bg = "TurkeyDaySounds/TurkeyDay_base_music.mp3",
    --CTS关卡-老母鸡感恩节-音乐-Freegame（C，142）
    Music_FG_Bg = "TurkeyDaySounds/TurkeyDay_fg_music.mp3",
    --CTS关卡-老母鸡感恩节-音乐-多福多彩（C，175）
    Music_Jackpot_Bg = "TurkeyDaySounds/TurkeyDay_jackpot_music.mp3",
    --CTS关卡-老母鸡感恩节-进入关卡短乐+Happy Thanksgiving
    Music_Enter_Game = "TurkeyDaySounds/TurkeyDay_enter_game.mp3",
    
    --CTS关卡-老母鸡感恩节-点击
    Music_Normal_Click = "TurkeyDaySounds/TurkeyDay_normal_click.mp3",
    -- CTS关卡-老母鸡感恩节-BG中奖连线1
    sound_TurkeyDay_winLines1 = "TurkeyDaySounds/sound_TurkeyDay_winLines1.mp3",
    -- CTS关卡-老母鸡感恩节-BG中奖连线2
    sound_TurkeyDay_winLines2 = "TurkeyDaySounds/sound_TurkeyDay_winLines2.mp3",
    -- CTS关卡-老母鸡感恩节-BG中奖连线3
    sound_TurkeyDay_winLines3 = "TurkeyDaySounds/sound_TurkeyDay_winLines3.mp3",
    -- CTS关卡-卡通熊猫-FG中奖连线1
    sound_TurkeyDay_free_winLines1 = "TurkeyDaySounds/sound_TurkeyDay_free_winLines1.mp3",
    -- CTS关卡-卡通熊猫-FG中奖连线2
    sound_TurkeyDay_free_winLines2 = "TurkeyDaySounds/sound_TurkeyDay_free_winLines2.mp3",
    -- CTS关卡-卡通熊猫-FG中奖连线3
    sound_TurkeyDay_free_winLines3 = "TurkeyDaySounds/sound_TurkeyDay_free_winLines3.mp3",
    --CTS关卡-老母鸡感恩节-scatter图标落地1
    --CTS关卡-老母鸡感恩节-scatter图标落地2
    --CTS关卡-老母鸡感恩节-scatter图标落地3
    Music_Scatter_Buling = {
        "TurkeyDaySounds/sound_TurkeyDay_scatter_buling_1.mp3",
        "TurkeyDaySounds/sound_TurkeyDay_scatter_buling_2.mp3",
        "TurkeyDaySounds/sound_TurkeyDay_scatter_buling_3.mp3",
    },
    --CTS关卡-老母鸡感恩节-FG预告中奖+Baby Chicks are coming !
    Music_YuGao_Sound = "TurkeyDaySounds/TurkeyDay_yuGao_sound.mp3",
    --CTS关卡-老母鸡感恩节-普通bonus变金额bonus动画
    Music_Bonus_Coins_Sound = "TurkeyDaySounds/TurkeyDay_bonus_coins_sound.mp3",
    --CTS关卡-老母鸡感恩节-特殊bonus蛋壳裂开
    Music_Bonus_Speicla_Sound = "TurkeyDaySounds/TurkeyDay_bonus_special_sound.mp3",
    --CTS关卡-老母鸡感恩节-BUFF特殊bonus蛋壳裂
    Music_Bonus_Buff_Sound = "TurkeyDaySounds/TurkeyDay_bonus_buff_sound.mp3",
    --CTS关卡-老母鸡感恩节-蛋裂开但没碎
    Music_Bonus_Crack_Sound = "TurkeyDaySounds/TurkeyDay_bonus_crack_sound.mp3",
    --CTS关卡-老母鸡感恩节-buff bonus触发动画
    Music_BuffBonus_Trigger_Sound = "TurkeyDaySounds/TurkeyDay_buffBonus_trigger_sound.mp3",
    --CTS关卡-老母鸡感恩节-buff施加动画
    Music_Add_Buff_Sound = "TurkeyDaySounds/TurkeyDay_add_buff_sound.mp3",
    --CTS关卡-老母鸡感恩节-buff施加反馈动画
    Music_Add_Buff_FeedBack_Sound = "TurkeyDaySounds/TurkeyDay_add_buff_feedBack_sound.mp3",
    --CTS关卡-老母鸡感恩节-草窝出现
    Music_BonusHouse_Appear_Sound = "TurkeyDaySounds/TurkeyDay_bonusHouseAppear_sound.mp3",
    --CTS关卡-老母鸡感恩节-金额bonus收集到草窝+反馈
    Music_CollectBonusCoins_Sound = "TurkeyDaySounds/TurkeyDay_collectBonusCoins_sound.mp3",
    --CTS关卡-老母鸡感恩节-大赢前预告中奖
    Music_Celebrate_Win = "TurkeyDaySounds/TurkeyDay_celebrate_win.mp3",
    --CTS关卡-老母鸡感恩节-进入FG过场动画
    Music_Base_Fg_CutScene = "TurkeyDaySounds/TurkeyDay_baseToFree.mp3",
    --CTS关卡-老母鸡感恩节-FG开始弹板弹出
    Music_Fg_StartStart = "TurkeyDaySounds/TurkeyDay_fgStart_start.mp3",
    --CTS关卡-老母鸡感恩节-FG开始弹板收回
    Music_Fg_StartOver = "TurkeyDaySounds/TurkeyDay_fgStart_over.mp3",
    --CTS关卡-老母鸡感恩节-FG里Scatter图标触发+Lots of luck
    Music_FgMore_ScatterTrigger = "TurkeyDaySounds/TurkeyDay_fgMore_scatterTrigger.mp3",
    --CTS关卡-老母鸡感恩节-FG More开始弹板弹出+收回
    Music_FgMore_Auto = "TurkeyDaySounds/TurkeyDay_fgMore_auto.mp3",
    --CTS关卡-老母鸡感恩节-FG次数增加
    Music_FgTime_Add = "TurkeyDaySounds/TurkeyDay_fgTime_add.mp3",
    --CTS关卡-老母鸡感恩节-FG结算弹板弹出+Congratulations
    Music_Fg_OverStart = "TurkeyDaySounds/TurkeyDay_fgOver_start.mp3",
    --CTS关卡-老母鸡感恩节-FG结算弹板收回
    Music_Fg_OverOver = "TurkeyDaySounds/TurkeyDay_fgOver_over.mp3",
    --CTS关卡-老母鸡感恩节-退出FG过场动画+Slowly~slowly
    Music_Fg_Base_CutScene = "TurkeyDaySounds/TurkeyDay_freeToBase.mp3",
    --CTS关卡-老母鸡感恩节-右侧母鸡拿出箱子
    Music_Role_ShowBox = "TurkeyDaySounds/TurkeyDay_role_showBox.mp3",
    --CTS关卡-老母鸡感恩节-棋盘中图标收集到右侧箱子
    Music_Collect_SpecialBonus = "TurkeyDaySounds/TurkeyDay_collect_specialBonus.mp3",
    --CTS关卡-老母鸡感恩节-棋盘中图标收集到右侧箱子反馈
    Music_Collect_SpecialBonusFeedBack = "TurkeyDaySounds/TurkeyDay_collect_specialBonusFeedBack.mp3",
    --CTS关卡-老母鸡感恩节-多福多彩触发动画+wooow, my precious
    Music_Trigger_ColofulGame = "TurkeyDaySounds/TurkeyDay_trigger_colofulGame.mp3",
    --CTS关卡-老母鸡感恩节-进入多福多彩玩法过场动画
    Music_Base_Colorful_CutScene = "TurkeyDaySounds/TurkeyDay_base_colorful.mp3",
    --CTS关卡-老母鸡感恩节-多福多彩开始弹板弹出+收回
    Music_Colorful_Auto = "TurkeyDaySounds/TurkeyDay_colorful_auto.mp3",
    --CTS关卡-老母鸡感恩节-点击PICK反馈
    Music_Pick_Click = "TurkeyDaySounds/TurkeyDay_pick_click.mp3",
    --CTS关卡-老母鸡感恩节-JP图标收集到JP栏反馈
    Music_CollectJackpot_FeedBack = "TurkeyDaySounds/TurkeyDay_collectJackpot_feedBack.mp3",
    --CTS关卡-老母鸡感恩节-REMOVE LEVEL触发
    Music_RemovePick_Trigger = "TurkeyDaySounds/TurkeyDay_removePick_trigger.mp3",
    --CTS关卡-老母鸡感恩节-REMOVE LEVEL小鸡跳到地面移除动画+Take a baby away
    Music_RemovePick_Jump = "TurkeyDaySounds/TurkeyDay_removePick_jump.mp3",
    --CTS关卡-老母鸡感恩节-移除动画对应的JP图标小鸡触发动画
    Music_RemovePick_JackpotTrigger = "TurkeyDaySounds/TurkeyDay_removePick_jackpotTrigger.mp3",
    --CTS关卡-老母鸡感恩节-移除动画对应的JP图标小鸡落地消失动画
    Music_RemovePick_JackpotJump = "TurkeyDaySounds/TurkeyDay_removePick_jackpotJump.mp3",
    --CTS关卡-老母鸡感恩节-JP图标小鸡落地后消失动画
    Music_RemovePick_JackpotDisappear = "TurkeyDaySounds/TurkeyDay_removePick_jackpotDisappear.mp3",
    --CTS关卡-老母鸡感恩节-中JP动画
    Music_Pick_RewardJackpot = "TurkeyDaySounds/TurkeyDay_pick_removeJackpot.mp3",
    --CTS关卡-老母鸡感恩节-JP弹板弹出+GRAND JACKPOT!
    --CTS关卡-老母鸡感恩节-JP弹板弹出+MEGA JACKPOT!
    --CTS关卡-老母鸡感恩节-JP弹板弹出+MAJOR JACKPOT!
    --CTS关卡-老母鸡感恩节-JP弹板弹出+MINOR JACKPOT!
    --CTS关卡-老母鸡感恩节-JP弹板弹出+MINI JACKPOT!
    Music_Jackpot_Reward = {
        "TurkeyDaySounds/TurkeyDay_jackpot_1.mp3",
        "TurkeyDaySounds/TurkeyDay_jackpot_2.mp3",
        "TurkeyDaySounds/TurkeyDay_jackpot_3.mp3",
        "TurkeyDaySounds/TurkeyDay_jackpot_4.mp3",
        "TurkeyDaySounds/TurkeyDay_jackpot_5.mp3",
    },
    --CTS关卡-老母鸡感恩节-JP数字滚动
    Music_Jackpot_Jump_Coins = "TurkeyDaySounds/TurkeyDay_jackpotJumpCoins.mp3",
    --CTS关卡-老母鸡感恩节-JP数字滚动结束音
    Music_Jackpot_Jump_Stop = "TurkeyDaySounds/TurkeyDay_jackpotJumpStop.mp3",
    --CTS关卡-老母鸡感恩节-JP弹板收回
    Music_Jackpot_Over = "TurkeyDaySounds/TurkeyDay_jackpot_over.mp3",
    --CTS关卡-老母鸡感恩节-退出PICK过场动画+Slowly~slowly
    Music_Colorful_Base_CutScene = "TurkeyDaySounds/TurkeyDay_colorful_base.mp3",
    --CTS关卡-老母鸡感恩节-Cooool--程序：30%的概率和大赢前预告中奖一起播
    Music_Celebrate_Win_Effect = "TurkeyDaySounds/TurkeyDay_celebrate_winEffect.mp3",
    --CTS关卡-老母鸡感恩节-Boost
    --CTS关卡-老母鸡感恩节-Big boost
    --CTS关卡-老母鸡感恩节-Super boost
    Music_Buff_Trigger = {
        "TurkeyDaySounds/TurkeyDay_buff_trigger_1.mp3",
        "TurkeyDaySounds/TurkeyDay_buff_trigger_2.mp3",
        "TurkeyDaySounds/TurkeyDay_buff_trigger_3.mp3",
    },
    --CTS关卡-老母鸡感恩节-Oh-yeah
    --CTS关卡-老母鸡感恩节-Yeehee
    Music_BonusCoins_Effect = {
        "TurkeyDaySounds/TurkeyDay_bonusCoinsEffect_1.mp3",
        "TurkeyDaySounds/TurkeyDay_bonusCoinsEffect_2.mp3",
    },
    --CTS关卡-老母鸡感恩节-JP蛋壳破碎
    Music_Pick_Jackpot_Sound = "TurkeyDaySounds/TurkeyDay_pick_jackpot_sound.mp3",
    --CTS关卡-老母鸡感恩节-FG次数增加动画
    Music_RightFree_Trigger_Sound = "TurkeyDaySounds/TurkeyDay_rightFreeTrigger_sound.mp3",
    --CTS关卡-老母鸡感恩节-bonus收集到草窝后数字增长
    Music_RewardCoins_Jump_Sound = "TurkeyDaySounds/TurkeyDay_rewardCoins_jump_sound.mp3",
    --CTS关卡-老母鸡感恩节-母鸡欢呼动画
    Music_PlayRole_Sound = "TurkeyDaySounds/TurkeyDay_playRole_sound.mp3",
    --CTS关卡-老母鸡感恩节-bonus集满棋盘背景庆祝动画
    Music_FullScreenBonus_Sound = "TurkeyDaySounds/TurkeyDay_fullScreenBonus_sound.mp3",
}

return TurkeyDayPublicConfig
