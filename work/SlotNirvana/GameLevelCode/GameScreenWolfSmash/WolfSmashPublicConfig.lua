local WolfSmashPublicConfig = {}

WolfSmashPublicConfig.SoundConfig = {
    --CTS关卡-砸小猪音效-进入关卡短乐+Piggy Bank Factory Welcomes You
    sound_WolfSmash_enterGame = "WolfSmashSounds/sound_WolfSmash_enterGame.mp3",
    --CTS关卡-砸小猪音效-中奖连线1
    sound_WolfSmash_win_line_1 = "WolfSmashSounds/sound_WolfSmash_win_line_1.mp3",
    --CTS关卡-砸小猪音效-中奖连线2
    sound_WolfSmash_win_line_2 = "WolfSmashSounds/sound_WolfSmash_win_line_2.mp3",
    --CTS关卡-砸小猪音效-中奖连线3
    sound_WolfSmash_win_line_3 = "WolfSmashSounds/sound_WolfSmash_win_line_3.mp3",
    --CTS关卡-砸小猪音效-FG中奖连线1
    sound_WolfSmash_fs_win_line_1 = "WolfSmashSounds/sound_WolfSmash_fs_win_line_1.mp3",
    --CTS关卡-砸小猪音效-FG中奖连线2
    sound_WolfSmash_fs_win_line_2 = "WolfSmashSounds/sound_WolfSmash_fs_win_line_2.mp3",
    --CTS关卡-砸小猪音效-FG中奖连线3
    sound_WolfSmash_fs_win_line_3 = "WolfSmashSounds/sound_WolfSmash_fs_win_line_3.mp3",
    -- CTS关卡-砸小猪音效-点击
    sound_WolfSmash_click = "WolfSmashSounds/sound_WolfSmash_click.mp3",
    --CTS关卡-砸小猪音效-预告中奖+Haha, get more piggy banks!
    sound_WolfSmash_base_yuGao = "WolfSmashSounds/sound_WolfSmash_base_yuGao.mp3",
    --CTS关卡-砸小猪音效-Bouns图标触发+Time to get rewards from these piggy banks!
    sound_WolfSmash_trigger_forBonus = "WolfSmashSounds/sound_WolfSmash_trigger_forBonus.mp3",
    --CTS关卡-砸小猪音效-FG弹板弹出
    sound_WolfSmash_free_select_show = "WolfSmashSounds/sound_WolfSmash_free_select_show.mp3",
    --CTS关卡-砸小猪音效-FG弹板收回
    sound_WolfSmash_free_select_hide = "WolfSmashSounds/sound_WolfSmash_free_select_hide.mp3",
    --CTS关卡-砸小猪音效-点击bonus发出粒子飞到地图上
    sound_WolfSmash_free_select_clickPig = "WolfSmashSounds/sound_WolfSmash_free_select_clickPig.mp3",
    --CTS关卡-砸小猪音效-点击bonus发出粒子飞到地图上反馈
    sound_WolfSmash_free_select_clickPig_fankui = "WolfSmashSounds/sound_WolfSmash_free_select_clickPig_fankui.mp3",
    --CTS关卡-砸小猪音效-bonus图标刷新
    sound_WolfSmash_bonus_shuaxin = "WolfSmashSounds/sound_WolfSmash_bonus_shuaxin.mp3",
    --CTS关卡-砸小猪音效-FG结算弹板弹出+You rock!
    sound_WolfSmash_fg_over_show = "WolfSmashSounds/sound_WolfSmash_fg_over_show.mp3",
    --CTS关卡-砸小猪音效-FG结算弹板收回
    sound_WolfSmash_fg_over_hide = "WolfSmashSounds/sound_WolfSmash_fg_over_hide.mp3",
    --CTS关卡-砸小猪音效-棋盘里bonus发出粒子飞到地图上
    sound_WolfSmash_bonus_add_pig = "WolfSmashSounds/sound_WolfSmash_bonus_add_pig.mp3",
    --CTS关卡-砸小猪音效-棋盘里bonus发出粒子飞到地图上反馈
    sound_WolfSmash_bonus_add_pig_fankui = "WolfSmashSounds/sound_WolfSmash_bonus_add_pig_fankui.mp3",
    --CTS关卡-砸小猪音效-totalwin金额出现
    sound_WolfSmash_fg_totalWin_show = "WolfSmashSounds/sound_WolfSmash_fg_totalWin_show.mp3",
    --CTS关卡-砸小猪音效-totalwin金额收回
    sound_WolfSmash_fg_totalWin_hide = "WolfSmashSounds/sound_WolfSmash_fg_totalWin_hide.mp3",
    --CTS关卡-砸小猪音效-totalwin金额增长+结束音
    sound_WolfSmash_fg_totalWin_jump = "WolfSmashSounds/sound_WolfSmash_fg_totalWin_jump.mp3",
    --CTS关卡-砸小猪音效-乘倍砸下
    sound_WolfSmash_fg_chengbei_down = "WolfSmashSounds/sound_WolfSmash_fg_chengbei_down.mp3",
    --CTS关卡-砸小猪音效-乘倍砸下2
    sound_WolfSmash_fg_chengbei_down2 = "WolfSmashSounds/sound_WolfSmash_fg_chengbei_down2.mp3",
    --CTS关卡-砸小猪音效-狼移动
    sound_WolfSmash_fg_wolf_move = "WolfSmashSounds/sound_WolfSmash_fg_wolf_move.mp3",
    --CTS关卡-砸小猪音效-狼砸猪动画+Smash
    sound_WolfSmash_fg_wolf_smash_pig = "WolfSmashSounds/sound_WolfSmash_fg_wolf_smash_pig.mp3",
    --CTS关卡-砸小猪音效-砸猪前小猪提示金光
    sound_WolfSmash_fg_smash_gold_lighting = "WolfSmashSounds/sound_WolfSmash_fg_smash_gold_lighting.mp3",
    --CTS关卡-砸小猪音效-complete文案出现
    sound_WolfSmash_fg_over_complete = "WolfSmashSounds/sound_WolfSmash_fg_over_complete.mp3",
    --CTS关卡-砸小猪音效-大赢前预告中奖
    sound_WolfSmash_bigWin_yugao = "WolfSmashSounds/sound_WolfSmash_bigWin_yugao.mp3",
    --CTS关卡-砸小猪音效-新手引导文案弹出
    sound_WolfSmash_select_yindao_show = "WolfSmashSounds/sound_WolfSmash_select_yindao_show.mp3",
    --CTS关卡-砸小猪音效-新手引导文案收回
    sound_WolfSmash_select_yindao_hide = "WolfSmashSounds/sound_WolfSmash_select_yindao_hide.mp3",
    --CTS关卡-砸小猪音效-FG里预告中奖+You got this!
    sound_WolfSmash_freeSpin_yugao = "WolfSmashSounds/sound_WolfSmash_freeSpin_yugao.mp3",
    --CTS关卡-砸小猪音效-FG回到BG过场动画+Look at their full belly!
    sound_WolfSmash_fgTobase_guochang = "WolfSmashSounds/sound_WolfSmash_fgTobase_guochang.mp3",
    --CTS关卡-砸小猪音效-You're going to be rich!
    sound_WolfSmash_fg_show_fiveOrTen = "WolfSmashSounds/sound_WolfSmash_longRun_Before.mp3",
    --CTS关卡-砸小猪音效-Better luck next time.
    sound_WolfSmash_longRun_Before = "WolfSmashSounds/sound_WolfSmash_fg_show_fiveOrTen.mp3",
    --点击小猪反馈V2
    sound_WolfSmash_Click_Pig_V2 = "WolfSmashSounds/sound_WolfSmash_Click_Pig_V2.mp3",
}


return WolfSmashPublicConfig