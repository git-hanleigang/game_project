local PudgyPandaPublicConfig = {}

PudgyPandaPublicConfig.SoundConfig = {
    --CTS关卡-卡通熊猫-音乐-basegame1.0(106,C)
    Music_Base_Bg = "PudgyPandaSounds/PudgyPanda_base_music.mp3",
    --CTS关卡-卡通熊猫-音乐-freegame1.0(117,am)
    Music_FG_Bg = "PudgyPandaSounds/PudgyPanda_fg_music.mp3",
    --CTS关卡-卡通熊猫-音乐-Fortune1.0(158,C)
    Music_FatFeature_Bg = "PudgyPandaSounds/PudgyPanda_fatFeature_music.mp3",
    --CTS关卡-卡通熊猫-音乐-转盘1.0(am)
    Music_Wheel_Bg = "PudgyPandaSounds/PudgyPanda_wheel_music.mp3",
    --CTS关卡-卡通熊猫-进入关卡短乐+Do you like buns_ They're my favorite!
    Music_Enter_Game = "PudgyPandaSounds/PudgyPanda_enter_game.mp3",

    -- CTS关卡-卡通熊猫-BG中奖连线1
    sound_PudgyPanda_winLines1 = "PudgyPandaSounds/sound_PudgyPanda_winLines1.mp3",
    -- CTS关卡-卡通熊猫-BG中奖连线2
    sound_PudgyPanda_winLines2 = "PudgyPandaSounds/sound_PudgyPanda_winLines2.mp3",
    -- CTS关卡-卡通熊猫-BG中奖连线3
    sound_PudgyPanda_winLines3 = "PudgyPandaSounds/sound_PudgyPanda_winLines3.mp3",
    -- CTS关卡-卡通熊猫-FG中奖连线1
    sound_PudgyPanda_free_winLines1 = "PudgyPandaSounds/sound_PudgyPanda_free_winLines1.mp3",
    -- CTS关卡-卡通熊猫-FG中奖连线2
    sound_PudgyPanda_free_winLines2 = "PudgyPandaSounds/sound_PudgyPanda_free_winLines2.mp3",
    -- CTS关卡-卡通熊猫-FG中奖连线3
    sound_PudgyPanda_free_winLines3 = "PudgyPandaSounds/sound_PudgyPanda_free_winLines3.mp3",
    -- CTS关卡-卡通熊猫-点击
    sound_PudgyPanda_click = "PudgyPandaSounds/sound_PudgyPanda_click.mp3",
    --CTS关卡-卡通熊猫-收集Bonus收集到下方进度条反馈
    Music_CollectBonus_FeedBack = "PudgyPandaSounds/PudgyPanda_collectBonus_feedBack.mp3",
    --CTS关卡-卡通熊猫-Link移动
    Music_MoveBonus_MoveSound = "PudgyPandaSounds/PudgyPanda_moveBonus_moveSound.mp3",
    --CTS关卡-卡通熊猫-第五列收集特殊Bonus预告中奖+Hey, Eyes up here
    Music_YuGao_Free_Sound = "PudgyPandaSounds/PudgyPanda_yuGao_freeSound.mp3",
    --CTS关卡-卡通熊猫-进度条达到对应节点+We're rich, time for a shopping spree!
    Music_Trigger_Free_Action = "PudgyPandaSounds/PudgyPanda_trigger_free_action.mp3",
    --CTS关卡-卡通熊猫-收集玩法选择弹板弹出
    Music_CollectPlay_Start = "PudgyPandaSounds/PudgyPanda_collectPlay_start.mp3",
    --CTS关卡-卡通熊猫-收集玩法选择弹板选中
    Music_CollectPlay_Select = "PudgyPandaSounds/PudgyPanda_collectPlay_select.mp3",
    --CTS关卡-卡通熊猫-收集玩法选择弹板收回
    Music_CollectPlay_Over = "PudgyPandaSounds/PudgyPanda_collectPlay_over.mp3",
    --CTS关卡-卡通熊猫-收集栏界面弹出
    Music_CollectBar_ShowStart = "PudgyPandaSounds/PudgyPanda_collectPlay_showStart.mp3",
    --CTS关卡-卡通熊猫-收集栏界面收回
    Music_CollectBar_ShowOver = "PudgyPandaSounds/PudgyPanda_collectPlay_showOver.mp3",
    --CTS关卡-卡通熊猫-FG开始弹板弹出
    Music_Fg_StartStart = "PudgyPandaSounds/PudgyPanda_fgStart_start.mp3",
    --CTS关卡-卡通熊猫-FG开始弹板收回
    Music_Fg_StartOver = "PudgyPandaSounds/PudgyPanda_fgStart_over.mp3",
    --CTS关卡-卡通熊猫-进入FG过场动画
    Music_Base_Fg_CutScene = "PudgyPandaSounds/PudgyPanda_baseToFree.mp3",
    --CTS关卡-卡通熊猫-滚动前捂眼睛动画
    Music_Fg_Wild_MoveStart = "PudgyPandaSounds/PudgyPanda_fg_wild_moveStart.mp3",
    --CTS关卡-卡通熊猫-特殊Wild图标出现
    Music_Fg_Wild_Appear = "PudgyPandaSounds/PudgyPanda_fg_wild_Appear.mp3",
    --CTS关卡-卡通熊猫-特殊Wild图标移动
    Music_Fg_Wild_MoveIdle = "PudgyPandaSounds/PudgyPanda_fg_wild_moveIdle.mp3",
    --CTS关卡-卡通熊猫-fortune里特殊wild移动
    Music_FatFeature_Wild_MoveIdle = "PudgyPandaSounds/PudgyPanda_fatFeature_wild_moveIdle.mp3",
    --CTS关卡-卡通熊猫-特殊Wild图标移动结束
    Music_Fg_Wild_MoveOver = "PudgyPandaSounds/PudgyPanda_fg_wild_moveOver.mp3",
    --CTS关卡-卡通熊猫-大赢前预告中奖
    Music_Celebrate_Win = "PudgyPandaSounds/PudgyPanda_celebrate_win.mp3",
    --CTS关卡-卡通熊猫-Yeah
    --CTS关卡-卡通熊猫-Wonderful!
    Music_Celebrate_WinEffect = {
        "PudgyPandaSounds/PudgyPanda_celebrate_winEffect_1.mp3",
        "PudgyPandaSounds/PudgyPanda_celebrate_winEffect_2.mp3",
    },
    --CTS关卡-卡通熊猫-FG结算弹板弹出+What a fun day!
    Music_Fg_OverStart = "PudgyPandaSounds/PudgyPanda_fgOver_start.mp3",
    --CTS关卡-卡通熊猫-FG结算弹板收回
    Music_Fg_OverOver = "PudgyPandaSounds/PudgyPanda_fgOver_over.mp3",
    --CTS关卡-卡通熊猫-退出FG过场动画
    Music_Fg_Base_CutScene = "PudgyPandaSounds/PudgyPanda_freeToBase.mp3",
    --CTS关卡-卡通熊猫-Link图标触发+Keep up, or we'll have no seats.
    --CTS关卡-卡通熊猫-Link图标触发+You have to try my favorite buns.
    Music_Trigger_Bonus_Sound = {
        "PudgyPandaSounds/PudgyPanda_triggerBonus_1.mp3",
        "PudgyPandaSounds/PudgyPanda_triggerBonus_2.mp3",
    },
    --CTS关卡-卡通熊猫-Fortune开始弹板弹出+收回
    Music_FatFeature_StartStart = "PudgyPandaSounds/PudgyPanda_fatFeature_startStart.mp3",
    --CTS关卡-卡通熊猫-进入Fortune过场动画
    Music_Base_FatFeature_CutScene = "PudgyPandaSounds/PudgyPanda_base_fatFeature.mp3",
    --CTS关卡-卡通熊猫-收集区增加动画
    Music_FatFeature_Basket_Add = "PudgyPandaSounds/PudgyPanda_fatFeature_basket_add.mp3",
    --CTS关卡-卡通熊猫-特殊Wild移动到Link上后反馈
    Music_Wild_MoveToBonus_FeedBack = "PudgyPandaSounds/PudgyPanda_wild_moveToBonus_feedBack.mp3",
    --CTS关卡-卡通熊猫-单次熊猫吃包子
    Music_Wild_Eat_Bonus = "PudgyPandaSounds/PudgyPanda_wild_eat_bonus.mp3",
    --CTS关卡-卡通熊猫-特殊Wild升级动画
    Music_Wild_Upgrade = "PudgyPandaSounds/PudgyPanda_wild_upgrade.mp3",
    --CTS关卡-卡通熊猫-收集区集满动画
    Music_FatFeature_Basket_Full = "PudgyPandaSounds/PudgyPanda_fatFeature_basket_full.mp3",
    --CTS关卡-卡通熊猫-Fortune次数栏增加+Have more if you like
    Music_FatFeature_AddTimes = "PudgyPandaSounds/PudgyPanda_fatFeature_addTimes.mp3",
    --CTS关卡-卡通熊猫-特殊wild5触发动画+Fill your pocket after filling your belly
    Music_Trigger_Wheel_Play = "PudgyPandaSounds/PudgyPanda_trigger_wheel_play.mp3",
    --CTS关卡-卡通熊猫-转盘提示弹出
    Music_Wheel_ShowTips = "PudgyPandaSounds/PudgyPanda_wheel_showTips.mp3",
    --CTS关卡-卡通熊猫-转盘提示收回
    Music_Wheel_CloseTips = "PudgyPandaSounds/PudgyPanda_wheel_closeTips.mp3",
    --CTS关卡-卡通熊猫-转盘转动
    Music_Wheel_StartMove = "PudgyPandaSounds/PudgyPanda_wheel_startMove.mp3",
    --CTS关卡-卡通熊猫-转盘选中
    Music_Wheel_SelectReward = "PudgyPandaSounds/PudgyPanda_wheel_selectReward.mp3",
    --CTS关卡-卡通熊猫-转盘选中后展示动画
    Music_Wheel_Select_ShowReward = "PudgyPandaSounds/PudgyPanda_wheel_select_showReward.mp3",
    --CTS关卡-卡通熊猫-Fortune结算弹板弹出+It's been fun being with you
    Music_FatFeature_OverStart = "PudgyPandaSounds/PudgyPanda_fatFeature_overStart.mp3",
    --CTS关卡-卡通熊猫-JP弹板弹出+GRAND JACKPOT!
    --CTS关卡-卡通熊猫-JP弹板弹出+MEGA JACKPOT！
    --CTS关卡-卡通熊猫-JP弹板弹出+MAJOR JACKPOT!
    --CTS关卡-卡通熊猫-JP弹板弹出+MINOR JACKPOT!
    --CTS关卡-卡通熊猫-JP弹板弹出+MINI JACKPOT!
    Music_Jackpot_Reward = {
        "PudgyPandaSounds/PudgyPanda_jackpot_1.mp3",
        "PudgyPandaSounds/PudgyPanda_jackpot_2.mp3",
        "PudgyPandaSounds/PudgyPanda_jackpot_3.mp3",
        "PudgyPandaSounds/PudgyPanda_jackpot_4.mp3",
        "PudgyPandaSounds/PudgyPanda_jackpot_5.mp3",
    },
    --CTS关卡-卡通熊猫-JP数字滚动
    Music_Jackpot_Jump_Coins = "PudgyPandaSounds/PudgyPanda_jackpotJumpCoins.mp3",
    --CTS关卡-卡通熊猫-JP数字滚动结束音
    Music_Jackpot_Jump_Stop = "PudgyPandaSounds/PudgyPanda_jackpotJumpStop.mp3",
    --CTS关卡-卡通熊猫-JP弹板收回
    Music_Jackpot_Over = "PudgyPandaSounds/PudgyPanda_jackpot_over.mp3",
    --CTS关卡-卡通熊猫-JP弹板结算到下方赢钱框反馈
    Music_Bottom_JumpCoins = "PudgyPandaSounds/PudgyPanda_bottom_jumpCoins.mp3",
    --CTS关卡-卡通熊猫-Bonus预告中奖+Wow! Bun in the sky
    Music_YuGao_FatFeature_Sound = "PudgyPandaSounds/PudgyPanda_yuGao_fatFeatureSound.mp3",
    --CTS关卡-卡通熊猫-That's right! Just enjoy your life
    Music_Enjoy_Effect = "PudgyPandaSounds/PudgyPanda_enjoyEffect.mp3",
    --CTS关卡-卡通熊猫-WoW!
    --CTS关卡-卡通熊猫-Aha!
    Music_Oh_SoundEffect = {
        "PudgyPandaSounds/PudgyPanda_oh_soundEffect_1.mp3",
        "PudgyPandaSounds/PudgyPanda_oh_soundEffect_2.mp3",
    },
    --CTS关卡-卡通熊猫-轮盘选中金额下方数字滚动
    Music_Bottom_Coins_Jump = "PudgyPandaSounds/PudgyPanda_bottom_coins_jump.mp3",
    --CTS关卡-卡通熊猫-特殊Wild移动到bonus2上后反馈
    Music_JackpotBonus_FeedBack = "PudgyPandaSounds/PudgyPanda_jackpotBonus_feedBack.mp3",
}

return PudgyPandaPublicConfig
