

---
-- 这里只定义 slots 里面的属性
--  island create on 2018-07-04 17:57:31

GD.TAG_SYMBOL_TYPE =
{
    SYMBOL_SCORE_9 = 0, -- 分值最高信号
    SYMBOL_SCORE_8 = 1,
    SYMBOL_SCORE_7 = 2,
    SYMBOL_SCORE_6 = 3,
    SYMBOL_SCORE_5 = 4,
    SYMBOL_SCORE_4 = 5,
    SYMBOL_SCORE_3 = 6,
    SYMBOL_SCORE_2 = 7,
    SYMBOL_SCORE_1 = 8,

    SYMBOL_SCATTER = 90,
    SYMBOL_BONUS = 91,
    SYMBOL_WILD = 92,
    --=================!!!!!这部分信号没有加入随机中!!!!!====================--
    SYMBOL_INVALID_TYPE = 93 ,
    SYMBOL_NIL_TYPE = -1000
}
--表中数据-----------------------------------------
GD.ORDINARY_SYMBOL_NUM = 9 -- 普通信号的个数
GD.SPECIAL_SYMBOL_NUM = 3  --特殊信号的个数
GD.TRIGGER_ONCE_COUNT_LIMIT  = 100 --生成一个的bouns scatter的找位置次数，超过跳出
----- symbol 信息  end
--Rhnio
GD.RAND_CHANGE_WILD = 8

-- bonusPro 和 scatterPro 索引值
GD.RANDOM_TOTAL = 1
GD.RANDOM_ONE = 2
GD.RANDOM_TWO = 3
GD.RANDOM_THREE = 4
GD.RANDOM_FOUR = 5
GD.RANDOM_FIVE = 6
GD.RANDOM_ARRAY = 6
---- Five prob 信息 这三个参数都是索引值  table从1开始 ， 之前是从0 开始的
GD.FIVE_OF_THE_KIND_RANDOM_LENGTH = 1
GD.FIVE_OF_THE_KIND_NUM = 2
GD.FIVE_OF_THE_KIND_ARRAY_NUM = 3


GD.SYMBOL_ACTION_MAX_SIZE = 9
GD.REEL_COLUMN_NUMBER = 10 --支持的最大reel数目
GD.REEL_MAX_ROW_NUMBER = 10   --每个reel支持的最大symbol个数，只用于定义数组!!!!!!!!!!!

GD.BIG_WIN_COIN_LIMIT = 8
GD.MEGA_WIN_COIN_LIMIT = 16
GD.EPIC_WIN_COIN_LIMIT = 24
GD.LEGENDARY_WIN_COIN_LIMIT = 100
--通知自己赢钱的倍数
GD.NOTIFY_WIN_COIN_LIMIT = 50

GD.MATRIX_MODE_3X3 = "3x3"
GD.MATRIX_MODE_3X5 = "3x5"
GD.MATRIX_MODE_4X5 = "4x5"
GD.MATRIX_MODE_4X6 = "4x6"
GD.MATRIX_MODE_7X5 = "7x5"
GD.MATRIX_MODE_8X5 = "8x5"
GD.MATRIX_MODE_5X3 = "5x3"

GD.MATRIX_MODE_2X3X3X3X2 = "2-3-3-3-2"
GD.MATRIX_MODE_3X4X4X4X3 = "3-4-4-4-3"
GD.MATRIX_MODE_3X4X5X6X7X7 = "3-4-5-6-7-7"
GD.MATRIX_MODE_4X3X4X3X4 = "4-3-4-3-4"
GD.MATRIX_MODE_3X4X3X4X3 = "3-4-3-4-3"
GD.MATRIX_MODE_4X3X3X3X4 = "4-3-3-3-4"
GD.MATRIX_MODE_3X4X4X4X4X3 = "3-4-4-4-4-3"
GD.MATRIX_MODE_3X4X5X4X3 = "3-4-5-4-3"
GD.MATRIX_MODE_4X5X6X5X4 = "4-5-6-5-4"
GD.MATRIX_MODE_3X5X5X5X3 = "3-5-5-5-3"

GD.VALID_LINE_SYM_NUM = 3
GD.VALID_LINE_SYM_NUM_FOUR = 4
GD.VALID_LINE_SYM_NUM_FIVE = 5
GD.VALID_MAY_BE_NUM = 2
-------------------------------------------表中数据

-- 游戏内触发动画优先顺序序列  0 到 7 是游戏的基础effect
GD.GameEffect = {
    EFFECT_NONE = -100,
    EFFECT_IDLE = 0,

    EFFECT_COLLECT_SIGN = 50, --收集角标(活动用)

    EFFECT_SELF_EFFECT = 100,  -- 播放自定义的动画内容，创建与标记都由自己关卡来完成
    EFFECT_SPECIAL_RESPIN = 150, --触发 respin 玩法 而且 填满 轮盘

    EFFECT_LINE_FRAME = 200, --显示线 ,框效果
    EFFECT_BIG_WIN_LIGHT = 205, --显示线 ,框效果

    --- 下面三种win effect 只会同时出现一个
    EFFECT_NORMAL_WIN = 210, --赢钱掉金币  如果有 bigwin  megawin 那么久不在出 normal 动画了
    EFFECT_BIGWIN = 212,    --赢钱bigwin
    EFFECT_MEGAWIN = 214,  --赢钱nergewin
    EFFECT_EPICWIN = 216, --赢钱epicwin
    EFFECT_LEGENDARY = 218, --赢钱epicwin
    ---

    EFFECT_FIVE_OF_KIND = 230, --线上5个相同图标触发

    EFFECT_NEWBIETASK_COMPLETE = 235,  --完成新手任务

    EFFECT_LEVELUP = 240,   --升级

    EFFECT_BONUS = 250, --Bonus小游戏动画

    EFFECT_FREE_SPIN = 260,--触发freespin动画

    EFFECT_RESPIN = 270 , -- respin 玩法

    --- 各个关卡的效果可以自定义到各自的类中去
    EFFECT_RESPIN_OVER = 280, -- respin 结束动画

    EFFECT_FREE_SPIN_OVER = 290, -- freespin结束动画

    EFFECT_DELAY_SHOW_BIGWIN = 295 , -- 当 feature 结束弹板出来后 ，显示大赢这些加个延迟

    EFFECT_Unlock = 300 , -- 解锁关卡
    -- 推送关卡
    EFFECT_PushSlot = 301 , 

    MISSION_LOCK_OPEN = 310,  --解锁每日任务

    QUEST_COMPLETE_TIP = 320 , --quest完成

    EFFECT_QUEST_DONE = 330, --quest完成

    EFFECT_REWARD_FS_START = 340, --活动赠送免费spin次数 开始

    EFFECT_REWARD_FS_OVER  = 341, --活动赠送免费spin次数 结束
    
}


-- 当前spin时处于那种状态。
GD.NORMAL_SPIN_MODE = 0
GD.AUTO_SPIN_MODE = 1
GD.FREE_SPIN_MODE = 2
GD.RESPIN_MODE = 3
GD.REWAED_SPIN_MODE = 4
GD.SPECIAL_SPIN_MODE = 5  -- 特殊玩法 spin 
GD.REWAED_FREE_SPIN_MODE = 6 -- 活动免费送奖的spin状态

--ENUM_SPIN_STAGE   slots 处于的状态
GD.WAIT_RUN = -1
GD.IDLE = 0
GD.GAME_MODE_ONE_RUN = 1
GD.STOP_RUN = 2
GD.QUICK_RUN = 3 --快速运行模式
GD.WAITING_DATA = 4 --等待网络数据返回

GD.REEL_RESILIENT_SPEED_Down = 600 -- 回弹速度 每秒
GD.REEL_RESILIENT_SPEED = 450 -- 回弹速度 每秒

-- 关卡进入入口
GD.FROM_LOBBY = 1
GD.FROM_QUEST = 2

GD.REEL_ANIMATION_SLIDE_TIMES = 15  --  //reel滑动次数，表示无效reel个数，有效reel按照需要插入
GD.REEL_ANIMATION_SLIDE_TIMES_STACKED_MODE = 15  --
GD.REEL_RANDOM_STACKED_NUM = 15  --
--====================初始化排列是B-0-1-2-3.....SEL_BLOCK..... 其中B是在显示界面上的===================//
GD.REEL_NORMAL_SLIDE_TIMES = 2  --  --表示是reel中的从0开始的第4block显示在界面上-表示正常时候滑动的长度+1
GD.REEL_NORMAL_SLIDE_TIMES_STACKED_MODE = 2  --
GD.REEL_BONUS_SLIDE_TIMES = GD.REEL_ANIMATION_SLIDE_TIMES-1  --//表示遇到bonus的时候滑动最大长度(第五个reel)
GD.REEL_BONUS_SLIDE_TIMES_STACKED_MODE = GD.REEL_ANIMATION_SLIDE_TIMES_STACKED_MODE - 1  --

GD.REEL_RUN_INTERVAL = 0.05 --
GD.REEL_RUN_INTERVAL_IN_LEVEL = 0  --

GD.REEL_LONG_RUN_LEN_MUTI = 8  --长滚是长度递增倍数
GD.REEL_LONG_RUN_ENLARGE_PX = 40 --快滚时reel wild变大px像素


GD.NORMAL_WIN_TIME = 0.45
GD.MACHINE_LINE_EFFECT_WAIT_TIME = 1

-- 连线类型
GD.E_GAME_LINE_TYPE = {
      LINE_3X5X20_TYPE    =   "3X5X20",
      LINE_3X5X30_TYPE    =   "3X5X30",
      LINE_3X5X30_2_TYPE  =   "3X5X30_2",
      LINE_3X5X30_3_TYPE  =   "3X5X30_3",
      LINE_3X5X50_TYPE    =   "3X5X50",
      LINE_3X5X100_TYPE   =   "3X5X100",
      LINE_4X5X50_TYPE    =   "4X5X50",
      LINE_4X6X80_TYPE    =  "4X6X80",
  }
GD.GAME_START_REQUEST_STATE = 0 --开始请求数据
GD.GAME_EFFECT_OVER_STATE = 1 --所以gameeffect都结束