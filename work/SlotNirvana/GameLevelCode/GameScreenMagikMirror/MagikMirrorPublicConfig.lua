local MagikMirrorPublicConfig = {}

MagikMirrorPublicConfig.SoundConfig = {
    --superMusic
    music_MagikMirror_superFreeBgm = "MagikMirrorSounds/music_MagikMirror_superFreeBgm.mp3",
    --freeMusic
    music_MagikMirror_freeBgm = "MagikMirrorSounds/music_MagikMirror_freeBgm.mp3",
    --进入关卡短乐+What lovely apples!
    music_MagikMirror_enter = "MagikMirrorSounds/music_MagikMirror_enter.mp3",
    -- CTS关卡-白雪公主音效-BG中奖连线
    sound_MagikMirror_base_line_1 = "MagikMirrorSounds/sound_MagikMirror_base_line_1.mp3",
    sound_MagikMirror_base_line_2 = "MagikMirrorSounds/sound_MagikMirror_base_line_2.mp3",
    sound_MagikMirror_base_line_3 = "MagikMirrorSounds/sound_MagikMirror_base_line_3.mp3",
    --CTS关卡-白雪公主音效-FG中奖连线
    sound_MagikMirror_free_line_1 = "MagikMirrorSounds/sound_MagikMirror_free_line_1.mp3",
    sound_MagikMirror_free_line_2 = "MagikMirrorSounds/sound_MagikMirror_free_line_2.mp3",
    sound_MagikMirror_free_line_3 = "MagikMirrorSounds/sound_MagikMirror_free_line_3.mp3",
    --CTS关卡-白雪公主音效-SFG中奖连线
    sound_MagikMirror_super_line_1 = "MagikMirrorSounds/sound_MagikMirror_super_line_1.mp3",
    sound_MagikMirror_super_line_2 = "MagikMirrorSounds/sound_MagikMirror_super_line_2.mp3",
    sound_MagikMirror_super_line_3 = "MagikMirrorSounds/sound_MagikMirror_super_line_3.mp3",
    --CTS关卡-白雪公主音效-点击
    sound_MagikMirror_click = "MagikMirrorSounds/sound_MagikMirror_click.mp3",
    --CTS关卡-白雪公主音效-预告中奖+Take a bite of the sweet apple
    sound_MagikMirror_yugao = "MagikMirrorSounds/sound_MagikMirror_yugao.mp3",
    --CTS关卡-白雪公主音效-SFG次数收集栏增加
    sound_MagikMirror_freeBar_addNum = "MagikMirrorSounds/sound_MagikMirror_freeBar_addNum.mp3",
    --FG开始弹板弹出
    sound_MagikMirror_freeView_show = "MagikMirrorSounds/sound_MagikMirror_freeView_show.mp3",
    -- FG开始弹板收回
    sound_MagikMirror_freeView_hide = "MagikMirrorSounds/sound_MagikMirror_freeView_hide.mp3",
    --BG进入FG过场动画+Go after the gold apples.
    sound_MagikMirror_baseToFree_guochang = "MagikMirrorSounds/sound_MagikMirror_baseToFree_guochang.mp3",
    --点击玫瑰反馈
    sound_MagikMirror_flower_click = "MagikMirrorSounds/sound_MagikMirror_flower_click.mp3",
    --增加FG次数收集到上方反馈
    sound_MagikMirror_free_addNum = "MagikMirrorSounds/sound_MagikMirror_free_addNum.mp3",
    --增加PICK次数收集到上方反馈
    sound_MagikMirror_pick_addNum = "MagikMirrorSounds/sound_MagikMirror_pick_addNum.mp3",
    --玫瑰消失
    sound_MagikMirror_hide_allFlower = "MagikMirrorSounds/sound_MagikMirror_hide_allFlower.mp3",
    --FG次数栏下移
    sound_MagikMirror_freeView_move = "MagikMirrorSounds/sound_MagikMirror_freeView_move.mp3",
    --FG次数栏中次数闪烁一下
    sound_MagikMirror_freeView_buling = "MagikMirrorSounds/sound_MagikMirror_freeView_buling.mp3",
    --魔镜变化动画
    sound_MagikMirror_Mirror_change = "MagikMirrorSounds/sound_MagikMirror_Mirror_change.mp3",
    --bonus收集动画1
    sound_MagikMirror_bonus_collect = "MagikMirrorSounds/sound_MagikMirror_bonus_collect.mp3",
    --魔镜收集反馈动画+Mirror, Mirror, tell me all
    sound_MagikMirror_Mirror_collect_fankui = "MagikMirrorSounds/sound_MagikMirror_Mirror_collect_fankui.mp3",
    --普通图标变金色
    sound_MagikMirror_symbol_changeGold = "MagikMirrorSounds/sound_MagikMirror_symbol_changeGold.mp3",
    --普通图标闪烁（1下）
    sound_MagikMirror_symbol_buling = "MagikMirrorSounds/sound_MagikMirror_symbol_buling.mp3",
    --魔镜再生魔镜动画
    sound_MagikMirror_mirror_changeMirror = "MagikMirrorSounds/sound_MagikMirror_mirror_changeMirror.mp3",
    --魔镜最终展示
    sound_MagikMirror_mirror_overShow = "MagikMirrorSounds/sound_MagikMirror_mirror_overShow.mp3",
    --魔镜合一
    sound_MagikMirror_mirror_over = "MagikMirrorSounds/sound_MagikMirror_mirror_over.mp3",
    --大赢前预告中奖
    sound_MagikMirror_bigWin_yugao = "MagikMirrorSounds/sound_MagikMirror_bigWin_yugao.mp3",
    --普通图标变成wild动画
    sound_MagikMirror_symbol_changeWild = "MagikMirrorSounds/sound_MagikMirror_symbol_changeWild.mp3",
    --大JP弹板弹出+MAJOR JACKPOT!
    sound_MagikMirror_jackpotWin_major = "MagikMirrorSounds/sound_MagikMirror_jackpotWin_major.mp3",
    --大JP弹板弹出+GRAND JACKPOT!
    sound_MagikMirror_jackpotWin_grand = "MagikMirrorSounds/sound_MagikMirror_jackpotWin_grand.mp3",
    sound_MagikMirror_jackpotWin_minor = "MagikMirrorSounds/sound_MagikMirror_jackpotWin_minor.mp3",
    sound_MagikMirror_jackpotWin_mini = "MagikMirrorSounds/sound_MagikMirror_jackpotWin_mini.mp3",
    --JP数字滚动
    sound_MagikMirror_jackpot_num_jump = "MagikMirrorSounds/sound_MagikMirror_jackpot_num_jump.mp3",
    --JP数字滚动结束音
    sound_MagikMirror_jackpot_num_jumpOver = "MagikMirrorSounds/sound_MagikMirror_jackpot_num_jumpOver.mp3",
    --大JP弹板收回
    sound_MagikMirror_jackpotWin_hide = "MagikMirrorSounds/sound_MagikMirror_jackpotWin_hide.mp3",
    --FG结算弹板弹出+Good for you
    sound_MagikMirror_freeOver_show = "MagikMirrorSounds/sound_MagikMirror_freeOver_show.mp3",
    --FG结算弹板收回
    sound_MagikMirror_freeOver_hide = "MagikMirrorSounds/sound_MagikMirror_freeOver_hide.mp3",
    --FG回到BG过场动画
    sound_MagikMirror_freeTobase_guochang = "MagikMirrorSounds/sound_MagikMirror_freeTobase_guochang.mp3",
    --BET锁定
    sound_MagikMirror_bet_lock = "MagikMirrorSounds/sound_MagikMirror_bet_lock.mp3",
    --BET解锁
    sound_MagikMirror_bet_unlock = "MagikMirrorSounds/sound_MagikMirror_bet_unlock.mp3",
    --进度条集满+You're blessed
    sound_MagikMirror_collectBar_All = "MagikMirrorSounds/sound_MagikMirror_collectBar_All.mp3",
    --SFG开始弹板弹出
    sound_MagikMirror_superfreeView_show = "MagikMirrorSounds/sound_MagikMirror_superfreeView_show.mp3",
    --SFG开始弹板收回
    sound_MagikMirror_superfreeView_hide = "MagikMirrorSounds/sound_MagikMirror_superfreeView_hide.mp3",
    --BG进入SFG过场动画+Go after the gold apples.
    sound_MagikMirror_baseTosuper_guochang = "MagikMirrorSounds/sound_MagikMirror_baseTosuper_guochang.mp3",
    --SFG结算弹板弹出+Good for you
    sound_MagikMirror_superfreeOver_show = "MagikMirrorSounds/sound_MagikMirror_superfreeOver_show.mp3",
    --SFG结算弹板收回
    sound_MagikMirror_superfreeOver_hide = "MagikMirrorSounds/sound_MagikMirror_superfreeOver_hide.mp3",
    --SFG回到BG过场动画
    sound_MagikMirror_superTobase_guochang = "MagikMirrorSounds/sound_MagikMirror_superTobase_guochang.mp3",
    --棋盘赢钱超过10倍时播
    sound_MagikMirror_Fantastic = "MagikMirrorSounds/sound_MagikMirror_Fantastic.mp3",
    --魔镜复制超过3个时的第一次播
    sound_MagikMirror_Terrific = "MagikMirrorSounds/sound_MagikMirror_Terrific.mp3",
    --魔镜最后转到的是白雪公主的时候和大赢前预告中奖一起播
    sound_MagikMirror_Impressive = "MagikMirrorSounds/sound_MagikMirror_Impressive.mp3",
    --魔镜最后转到的是皇后的时候和大赢前预告中奖一起播
    sound_MagikMirror_heehee = "MagikMirrorSounds/sound_MagikMirror_heehee.mp3",
    --30%的概率和魔镜再生魔镜动画一起播
    sound_MagikMirror_happening = "MagikMirrorSounds/sound_MagikMirror_happening.mp3",

    --再生魔镜飞到上方
    sound_MagikMirror_Mirror_fly = "MagikMirrorSounds/sound_MagikMirror_Mirror_fly.mp3",
    --魔镜再生魔镜（未成功)
    sound_MagikMirror_mirror_changeMirror2 = "MagikMirrorSounds/sound_MagikMirror_mirror_changeMirror2.mp3",
    -- 魔镜再生魔镜JP动画
    sound_MagikMirror_mirror_changejp = "MagikMirrorSounds/sound_MagikMirror_mirror_changejp.mp3",
    --JP结算前展示
    sound_MagikMirror_jackpot_actionframe = "MagikMirrorSounds/sound_MagikMirror_jackpot_actionframe.mp3",
}


return MagikMirrorPublicConfig