----
-- 定义音乐、音效枚举 ,值适应与公共的音效
--
--

--音乐音效开关
GD.kMusic_Backgroud_Switch = "music_backgroud_switch"
GD.kSound_Effect_switdh = "sound_effect_switch"
GD.kAllow_Notifcation_switdh = "allow_notifcation_switch"
GD.kAllow_Vibration_switch = "allow_vibration_switch"

---- 各个关卡的音效不放到这里， 单独放到各个文件夹里面， 音效的enum 自己进行设置

GD.SOUND_ENUM = {
    -- sound_map_bgm1.mp3
    MUSIC_MAP_BACKGROUND_ONE = "sound_map_bgm1.mp3", -- 大厅背景音乐
    SOUND_HIDE_VIEW = "Sounds/soundHideView.mp3",
    MUSIC_BTN_CLICK = "Sounds/btn_click.mp3", -- 按钮点击音效
    MUSIC_BONUS = "bonus.mp3", -- 触发bonus
    MUSIC_SCATTER = "scatter.mp3",
    MUSIC_LAST_WIN_ONE = "sound_last_win_1.mp3",
    MUSIC_LAST_WIN_TWO = "sound_last_win_2.mp3",
    MUSIC_LAST_WIN_THR = "sound_last_win_3.mp3",
    MUSIC_LAST_WIN_FOU = "sound_last_win_4.mp3",
    MUSIC_LAST_WIN_FIV = "sound_last_win_5.mp3",
    MUSIC_LAST_WIN_SIX = "sound_last_win_6.mp3",
    MUSIC_LAST_WIN_SEV = "sound_last_win_7.mp3",
    MUSIC_LAST_WIN_EIGHT = "sound_last_win_7.mp3", --!!!!!!!!!!!!要加个8
    MUSIC_BONUS_TWO_VOICE = "Sounds/Diamonds_bonus_two.mp3", -- 快滚音效
    --  MUSIC_REEL_STOP_NINE = "reel_stop_9.mp3" , -- 快滚下落音效
    MUSIC_SPECIAL_BONUS = "special_slot_tip.mp3", -- 特殊元素 bonus 等buling 动画特效
    MUSIC_SPIN = "spin.mp3", -- 点击spin 音效
    MUSIC_BONUS_SCATTER_ONE_VOICE = "bonus_scatter_1.mp3",
    MUSIC_BONUS_SCATTER_TWO_VOICE = "bonus_scatter_2.mp3",
    MUSIC_BONUS_SCATTER_THREE_VOICE = "bonus_scatter_3.mp3",
    MUSIC_COIN_WIN_ROTATION = "sound_coin_win_rotation.mp3", -- 大赢 每次转动音乐
    MUSIC_LEVEL_UP = "Sounds/sound_slots_levelup.mp3", -- 升级
    MUSIC_TURNTABLE = "turntable.mp3", -- paytable 翻页
    MUSIC_DAILY_REWARD = "sound_daily_reward.mp3", -- 每小时奖励音效
    MUSIC_DAILY_LOTTO = "Sounds/daily_lotto.mp3", -- 每日签到 转动
    MUSIC_ATUO_SPIN_ACTIVE = "Sounds/auto_spin_active.mp3", -- auto spin 触发
    MUSIC_FIVE_OF_KIND = "five_of_kind.mp3", --
    -- 滚轮停止音效
    MUSIC_REEL_STOP_ONE = "Sounds/reel_stop_1.mp3",
    MUSIC_REEL_STOP_TWO = "reel_stop_2.mp3",
    MUSIC_REEL_STOP_THR = "reel_stop_3.mp3",
    MUSIC_REEL_STOP_FOU = "reel_stop_4.mp3",
    MUSIC_REEL_STOP_FIV = "reel_stop_5.mp3",
    MUSIC_REEL_STOP_SIX = "reel_stop_6.mp3",
    MUSIC_REEL_STOP_SEVEN = "reel_stop_7.mp3",
    MUSIC_REEL_STOP_EIGHT = "reel_stop_8.mp3",
    MUSIC_REEL_STOP_NINE = "reel_stop_9.mp3",
    -- 块停一些相关音效
    LEVEL_BG_MUSIC = "",
    LEVEL_REEL_RUN_SOUND = "",
    MUSIC_FIVE_OF_KIND_SHOW = "five_of_kind_show.mp3", -- FIVE OF KIND出现音效
    MUSIC_BIG_WIN_BG = "",
     --"big_win_bg.mp3", -- 大赢背景音乐
    MUSIC_BIG_WIN_COIN = "",
     --"big_win_coin.mp3", -- 大赢金币效果
    MUSIC_BIG_WIN_APPEAR = "big_win_appear.mp3", -- 大赢出现音效
    MUSIC_NORMAL_WIN_COIN = "normal_win_coin.mp3", -- 小赢赢钱音效
    MUSIC_HOURLY_REWARD = "hourly_reward.mp3", -- 每小时奖励音效
    MUSIC_WIN_COIN_END = "win_coin_end.mp3", -- 赢钱结束音效
    MUSIC_MENU_OPEN = "menu_open.mp3",
    MUSIC_MENU_CLOSE = "menu_close.mp3",
    MUSIC_MAX_BET = "music_max_bet.mp3", -- 点击游戏内maxbet 按钮播放音效
    MUSIC_PAYTABLE_OPEN = "music_paytable_open.mp3", -- 打开paytable
    MUSIC_PAYTABLE_CLOSE = "music_paytable_close.mp3", -- 关闭paytable
    MUSIC_COLLECT_EMAIL = "Sounds/music_collect_email.mp3", -- 收集邮件内钱
    MUSIC_ENTER_LEVEL = "music_enter_level.mp3", -- 进入关卡 loading 时播放
    MUSIC_TURN_PAGE = "music_turn_page.mp3", -- 翻页音效，一般用于paytable
    MUSIC_CONTRATULATE = "music_congratulate.mp3", -- 恭喜类音乐
    MUSIC_COIN_UPDATE = "music_lobby_coin_update.mp3", -- 主界面金币数变化音效
    MUSIC_PIG_BANK_CLICK = "music_pig_bank_clik.mp3", -- 小猪银行 储蓄罐音效
    MUSIC_WHEEL_BONUS_TURN = "Sounds/music_wheel_bouns_turn.mp3", -- cashBonus每日轮盘转动音效
    MUSIC_SPIN_ACCUMULATION_PARTICLE = "Sounds/music_spin_accumulation_particle.mp3", -- cashBonus当日累积进度条粒子音效
    MUSIC_CASH_BONUS_CALCULATION_DIGIT_JUMP_OUT = "Sounds/music_cash_bonus_calculation_digit_jump_out.mp3", -- wheelBonus免费结算
    --MUSIC_CASH_BONUS_CALCULATION_DIGIT_EXPLOSION = "Sounds/music_cash_bonus_calculation_digit_explosion.mp3", -- wheelBonus免费结算
    MUSIC_WHEEL_BONUS_TWICE_COINS_DROP_DOWN = "Sounds/music_wheel_bonus_twice_coins_drop_down.mp3", -- wheelBonus付费结算
    MUSIC_WHEEL_BONUS_LEVEL_UP = "Sounds/music_wheel_bonus_level_up.mp3", -- wheelBonus level up状态
    MUSIC_WHEEL_BONUS_LEVEL_UP_ONE = "Sounds/music_wheel_bonus_level_up_one.mp3", -- 第一个轮盘 wheelBonus level up状态
    MUSIC_WHEEL_BONUS_STOPPED = "Sounds/music_wheel_bonus_stopped.mp3",
    --大赢特效
    -- MUSIC_COMMON_WIN_KEEP1 = "Sounds/commonWinKeep1.mp3" ,
    -- MUSIC_COMMON_WIN_KEEP2 = "Sounds/commonWinKeep2.mp3" ,
    -- MUSIC_COMMON_WIN_KEEP3 = "Sounds/commonWinKeep3.mp3" ,
    MUSIC_COMMON_WIN_START1 = "Sounds/commonWinStart1.mp3",
    MUSIC_COMMON_WIN_START2 = "Sounds/commonWinStart2.mp3",
    MUSIC_COMMON_WIN_START3 = "Sounds/commonWinStart3.mp3",
    MUSIC_COMMON_WIN_OVER1 = "Sounds/commonWinOver2.mp3",
    MUSIC_COMMON_WIN_OVER2 = "Sounds/commonWinOver2.mp3",
    MUSIC_COMMON_WIN_OVER3 = "Sounds/commonWinOver2.mp3",
    MUSIC_LUCKYSTAMP_ONCE = "Sounds/luckystamp_once.mp3",
     --luckystamp 盖戳声音
    MUSIC_COMMON_BIGWIN_START1 = "Sounds/newBigwin1.mp3",
    MUSIC_COMMON_BIGWIN_START2 = "Sounds/newBigwin2.mp3",
    MUSIC_COMMON_BIGWIN_START3 = "Sounds/newBigwin3.mp3",
    MUSIC_COMMON_BIGWIN_START4 = "Sounds/newBigwin4.mp3",
    MUSIC_COMMON_BIGWIN_OVER1 = "Sounds/newBigwinEnd1.mp3",
    MUSIC_COMMON_BIGWIN_OVER2 = "Sounds/newBigwinEnd2.mp3",
    MUSIC_COMMON_BIGWIN_OVER3 = "Sounds/newBigwinEnd3.mp3",
    MUSIC_COMMON_BIGWIN_OVER4 = "Sounds/newBigwinEnd4.mp3",
    MUSIC_CASHLINK_LOADINGSOUND = "Sounds/cashlinkLoadingSound.mp3",
    MUSIC_CASHBONUS_FLYGOLD = "Sounds/cashbonus_flyGold.mp3",
    MUSIC_CASHBONUS_MERGE = "Sounds/CashBonus_merge.mp3",
    MUSIC_CASHBONUS_BZQ = "Sounds/cashbonus_bzq.mp3"
}

----  END
