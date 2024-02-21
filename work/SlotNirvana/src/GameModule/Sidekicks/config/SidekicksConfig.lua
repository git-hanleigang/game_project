local SidekicksConfig = {}

-- 最新赛季 idx
SidekicksConfig.NewSeasonIdx = 1


SidekicksConfig.EVENT_NAME = {
    NOTICE_SIDEKICKS_DETAIL_LAYER_OPEN_OVER = "NOTICE_SIDEKICKS_DETAIL_LAYER_OPEN_OVER", -- 宠物详情界面打开完毕
    NOTICE_SIDEKICKS_DETAIL_LAYER_CLOSE_START = "NOTICE_SIDEKICKS_DETAIL_LAYER_CLOSE_START", -- 宠物详情界面开始关闭


    
    NOTICE_UPDATE_SIDEKICKS_DATE = "NOTICE_UPDATE_SIDEKICKS_DATE", -- 宠物数据更新

    NOTICE_FEED_PET_NET_CALL_BACK = "NOTICE_FEED_PET_NET_CALL_BACK", -- 投喂宠物升级net回调
    NOTICE_STAR_UP_PET_NET_CALL_BACK = "NOTICE_STAR_UP_PET_NET_CALL_BACK", -- 宠物突破进阶net回调
    NOTICE_STAR_UP_LAYER_CLOSE = "NOTICE_STAR_UP_LAYER_CLOSE", -- 宠物突破进阶net回调

    NOTIFY_SIDEKICKS_WHEEL_SPIN = "NOTIFY_SIDEKICKS_WHEEL_SPIN", -- 每日轮盘
    NOTIFY_SIDEKICKS_WHEEL_REWARD_CLOSE = "NOTIFY_SIDEKICKS_WHEEL_REWARD_CLOSE", -- 每日轮盘奖励关闭
    NOTIFY_SIDEKICKS_HONOR_SALE = "NOTIFY_SIDEKICKS_HONOR_SALE", -- 荣誉促销购买

    NOTIFY_SIDEKICKS_PET_SET_NAME = "NOTIFY_SIDEKICKS_PET_SET_NAME", -- 宠物改名
    NOTIFY_SIDEKICKS_STAR_UP_REWARD_CLOSE = "NOTIFY_SIDEKICKS_STAR_UP_REWARD_CLOSE", -- 升星奖励

    NOTIFY_SIDEKICKS_PET_SET_NAME_GUIDE = "NOTIFY_SIDEKICKS_PET_SET_NAME_GUIDE", -- 宠物改名__引导
    NOTIFY_SIDEKICKS_HIDE_CUR_STEP_GUIDE = "NOTIFY_SIDEKICKS_HIDE_CUR_STEP_GUIDE", -- 宠物隐藏 本步引导
}

-- 荣誉等级的icon和名字
SidekicksConfig.RANK_NAME = {
    "PUP 1",
    "PUP 2",
    "PUP 3",
    "CUB 1",
    "CUB 2",
    "CUB 3",
    "VET 1",
    "VET 2",
    "VET 3",
    "ACE 1"
}

-- 宠物点击区域,每个宠物一条配置
SidekicksConfig.PET_CLICK_RECT = {
    {x = 0, y = 16, width = 200, height = 280},
    {x = 0, y = -24, width = 220, height = 280},
}

-- 宠物切换时光效上移距离,每个赛季一条配置
SidekicksConfig.PET_CHANGE_ACT_OFFSET_Y = {
    585,
}

SidekicksConfig.PET_SKILL_INFO = {
    {
        {type = "level", offsetX = -75},   -- 等级加成
        {type = "star", offsetX = -70},    -- 星级加成
        {type = "special", offsetX = 0, bonus = "bigWin"}      -- 等级星级都加成
    },
    {
        {type = "level", offsetX = -75},   -- 等级加成
        {type = "star", offsetX = -70},    -- 星级加成
        {type = "special", offsetX = 0, bonus = "extraBet"}      -- 等级星级都加成
    }
}

return SidekicksConfig