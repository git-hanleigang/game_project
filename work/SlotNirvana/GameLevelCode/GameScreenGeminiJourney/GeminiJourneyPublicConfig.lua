local GeminiJourneyPublicConfig = {}

GeminiJourneyPublicConfig.SoundConfig = {
    --CTS关卡-独立日-音乐-basegame1.0(75,am)
    Music_Base_Bg = "GeminiJourneySounds/GeminiJourney_base_music.mp3",
    --CTS关卡-独立日-音乐-freegame1.0(133,am)
    Music_FG_Bg = "GeminiJourneySounds/GeminiJourney_fg_music.mp3",
    --CTS关卡-独立日-音乐-特殊spin1.0(120,am)
    Music_Special_Spin_Bg = "GeminiJourneySounds/GeminiJourney_respin_music.mp3",
    --CTS关卡-双子美女-进入关卡短乐+Join us for an incredible journey to the unknown.
    Music_Enter_Game = "GeminiJourneySounds/GeminiJourney_enter_game.mp3",
    --CTS关卡-双子美女-点击
    Music_Normal_Click = "GeminiJourneySounds/GeminiJourney_normal_click.mp3",
    --CTS关卡-双子美女-BET锁定（收集栏变长）
    Music_Bet_Low = "GeminiJourneySounds/GeminiJourney_bet_low.mp3",
    --CTS关卡-双子美女-BET解锁（收集栏变短）
    Music_Bet_Hight = "GeminiJourneySounds/GeminiJourney_bet_hight.mp3",
    --CTS关卡-双子美女-玩法文案弹出
    Music_BetPlay_Show = "GeminiJourneySounds/GeminiJourney_betPlay_show.mp3",
    --CTS关卡-双子美女-玩法文案收回
    Music_BetPlay_Close = "GeminiJourneySounds/GeminiJourney_betPlay_close.mp3",
    --CTS关卡-双子美女-预告中奖+Good tidings from the stars
    Music_YuGao_Sound = "GeminiJourneySounds/GeminiJourney_yuGao_sound.mp3",
    --CTS关卡-双子美女-Scatter图标落地1
    --CTS关卡-双子美女-Scatter图标落地2
    --CTS关卡-双子美女-Scatter图标落地3
    Music_Scatter_Buling = {
        "GeminiJourneySounds/music_GeminiJourney_scatter_buling_1.mp3",
        "GeminiJourneySounds/music_GeminiJourney_scatter_buling_2.mp3",
        "GeminiJourneySounds/music_GeminiJourney_scatter_buling_3.mp3",
    },
    --CTS关卡-双子美女-Bonus图标落地
    Music_Bonus_Buling = "GeminiJourneySounds/music_GeminiJourney_bonus_buling.mp3",
    --CTS关卡-双子美女-FG里Scatter图标触发+We can't stop here
    Music_FreeMore_ScatterTrigger = "GeminiJourneySounds/GeminiJourney_freeMore_scatterTrigger.mp3",
    --CTS关卡-双子美女-FG开始弹板弹出
    Music_Fg_StartStart = "GeminiJourneySounds/GeminiJourney_fgStart_start.mp3",
    --CTS关卡-双子美女-BG进入FG过场动画
    Music_Base_Fg_CutScene = "GeminiJourneySounds/GeminiJourney_baseToFree.mp3",
    --CTS关卡-双子美女-FG MORE 开始弹板弹出+收回
    Music_FgMore_Start = "GeminiJourneySounds/GeminiJourney_fgMore_start.mp3",
    --CTS关卡-双子美女-FG次数栏次数增加
    Music_FgCount_Add = "GeminiJourneySounds/GeminiJourney_fgCount_add.mp3",
    --CTS关卡-双子美女-大赢前预告中奖
    Music_Celebrate_Win = "GeminiJourneySounds/GeminiJourney_celebrate_win.mp3",
    --CTS关卡-双子美女-Stars twinkle brightly
    Music_Celebrate_WinEffect = "GeminiJourneySounds/GeminiJourney_celebrate_winEffect.mp3",
    --CTS关卡-双子美女-FG结算弹板弹出+Nice job
    Music_Fg_OverStart = "GeminiJourneySounds/GeminiJourney_fgOver_start.mp3",
    --CTS关卡-双子美女-FG结算弹板收回
    Music_Fg_OverOver = "GeminiJourneySounds/GeminiJourney_fgOver_over.mp3",
    --CTS关卡-双子美女-FG回到BG过场动画
    Music_Fg_Base_CutScene = "GeminiJourneySounds/GeminiJourney_freeToBase.mp3",
    --CTS关卡-双子美女-Bonus图标触发+Experience the thrill of exploring the universe.
    --CTS关卡-双子美女-Bonus图标触发+The depths of space are calling!
    Music_Bonus_TriggerSound = {
        "GeminiJourneySounds/GeminiJourney_bonus_trigger_1.mp3",
        "GeminiJourneySounds/GeminiJourney_bonus_trigger_2.mp3",
    },
    --CTS关卡-双子美女-RS开始弹板弹出
    Music_Respin_StartStart = "GeminiJourneySounds/GeminiJourney_respinStart_start.mp3",
    --CTS关卡-双子美女-进入RS过场动画
    Music_Enter_Respin_CutScene = "GeminiJourneySounds/GeminiJourney_enterRespin_cutScene.mp3",
    --CTS关卡-双子美女-左侧棋盘Bonus复制动画
    Music_Respin_BonusCopy = "GeminiJourneySounds/GeminiJourney_respin_bonusCopy.mp3",
    --CTS关卡-双子美女-锁定文本出现
    Music_Respin_LockRow_Show = "GeminiJourneySounds/GeminiJourney_respin_lockRow_show.mp3",
    --CTS关卡-双子美女-Bonus落地
    Music_Bonus_buling = "GeminiJourneySounds/music_GeminiJourney_bonus_buling.mp3",
    --CTS关卡-双子美女-特殊Bonus落地
    Music_Respin_Bonus2_Buling = "GeminiJourneySounds/GeminiJourney_respin_bonus2_buling.mp3",
    --CTS关卡-双子美女-特殊Bonus解锁触发动画+The mysteries are infinite
    Music_RespinBonus2_Unlock = "GeminiJourneySounds/GeminiJourney_respinbonus2_unlock.mp3",
    --CTS关卡-双子美女-特殊Bonus出现金额
    Music_RespinBonus2_ShowScore = "GeminiJourneySounds/GeminiJourney_respinbonus2_showScore.mp3",
    --CTS关卡-双子美女-grand出现
    Music_Grand_Show = "GeminiJourneySounds/GeminiJourney_grand_show.mp3",
    --CTS关卡-双子美女-The vast sea of stars
    Music_Grand_Show_Effect = "GeminiJourneySounds/GeminiJourney_grand_showEffect.mp3",
    --CTS关卡-双子美女-集满棋盘触发Grand
    Music_Grand_Trigger = "GeminiJourneySounds/GeminiJourney_grand_trigger.mp3",
    --CTS关卡-双子美女-JP数字滚动
    Music_Jackpot_Jump_Coins = "GeminiJourneySounds/GeminiJourney_jackpotJumpCoins.mp3",
    --CTS关卡-双子美女-JP数字滚动结束音
    Music_Jackpot_Jump_Stop = "GeminiJourneySounds/GeminiJourney_jackpotJumpStop.mp3",
    --CTS关卡-双子美女-JP弹板收回
    Music_Jackpot_Over = "GeminiJourneySounds/GeminiJourney_jackpot_over.mp3",
    --CTS关卡-双子美女-Grand结算弹板弹出+GRAND JACKPOT!
    --CTS关卡-双子美女-JP弹板弹出+MEGA JACKPOT！
    --CTS关卡-双子美女-JP弹板弹出+MAJOR JACKPOT!
    --CTS关卡-双子美女-JP弹板弹出+MINOR JACKPOT!
    --CTS关卡-双子美女-JP弹板弹出+MINI JACKPOT!
    Music_Jackpot_Reward = {
        "GeminiJourneySounds/GeminiJourney_jackpot_1.mp3",
        "GeminiJourneySounds/GeminiJourney_jackpot_2.mp3",
        "GeminiJourneySounds/GeminiJourney_jackpot_3.mp3",
        "GeminiJourneySounds/GeminiJourney_jackpot_4.mp3",
        "GeminiJourneySounds/GeminiJourney_jackpot_5.mp3",
    },
    --CTS关卡-双子美女-所有Bonus图标结算动画+The vast sea of stars
    Music_AllBonus_Trigger = "GeminiJourneySounds/GeminiJourney_allBonus_trigger.mp3",
    --CTS关卡-双子美女-单个Bonus图标结算到下方赢钱框反馈
    Music_RespinCollect_BonusFeed = "GeminiJourneySounds/GeminiJourney_respinCollect_bonusFeed.mp3",
    --CTS关卡-双子美女-中JP动画+Aha!
    Music_showJackpot_Aha = "GeminiJourneySounds/GeminiJourney_showJackpot_aha.mp3",
    --CTS关卡-双子美女-RS结算弹板弹出+Sparkling trip
    Music_Respin_OverStart = "GeminiJourneySounds/GeminiJourney_respinOver_start.mp3",
    --CTS关卡-双子美女-RS结算弹板收回
    Music_Respin_OverOver = "GeminiJourneySounds/GeminiJourney_respinOver_over.mp3",
    --CTS关卡-双子美女-退出RS过场动画
    Music_Respin_Base_CutScene = "GeminiJourneySounds/GeminiJourney_respinBase_cutScene.mp3",
    --CTS关卡-双子美女-RS次数栏次数增加
    Music_RespinCount_Add = "GeminiJourneySounds/GeminiJourney_respinCount_add.mp3",
    --CTS关卡-双子美女-RS收集栏次数差最后一次期待提示
    Music_CollectBonus_Expect = "GeminiJourneySounds/GeminiJourney_collectBonus_expect.mp3",
    --CTS关卡-双子美女-RS收集栏集满+Wonderful!
    Music_CollectBonus_Full = "GeminiJourneySounds/GeminiJourney_collectBonus_full.mp3",
    --CTS关卡-双子美女-最后一格快滚框出现+WoW!
    Music_Respin_LastEffectShow = "GeminiJourneySounds/GeminiJourney_respin_lastEffectShow.mp3",
    --CTS关卡-双子美女-最后一格快滚
    Music_Respin_LastNodeQuick = "GeminiJourneySounds/GeminiJourney_respin_lastNodeQuick.mp3",
    --CTS关卡-双子美女-The mysteries are infinite
    Music_Respin_First_Unlock_Row = "GeminiJourneySounds/GeminiJourney_respin_firstUnlockRow.mp3",
    --CTS关卡-双子美女-快停
    Music_Reel_QuickStop_Sound = "GeminiJourneySounds/music_GeminiJourney_quickReelDown.mp3",
}


return GeminiJourneyPublicConfig