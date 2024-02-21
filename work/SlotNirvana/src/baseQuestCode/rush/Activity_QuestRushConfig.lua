-- FIX IOS 150 v465
local Activity_QuestRushConfig = {}

-- 奖励状态
Activity_QuestRushConfig.ITEM_STATE = {
    CANNOT = 1, -- 不能领取
    UNGAIN = 2, -- 可以领取但是未领取
    GAIN = 3 -- 已领取
}

-- 事件
Activity_QuestRushConfig.EVENT_NAME = {
    UPDATE_REWARD_ITEM_STATE = "UPDATE_REWARD_ITEM_STATE", -- 更新奖励领取状态
    RESET_ITEM_TOUCH_ENABLE = "RESET_ITEM_TOUCH_ENABLE", -- 恢复 按钮点击状态
    PLAY_ENTRY_COLLECT_STAR_ACT = "PLAY_ENTRY_COLLECT_STAR_ACT" -- 播放入口星星收集动画
}

-- quest挑战主题
Activity_QuestRushConfig.RUSH_THEME = {
    FAIRY_TALES = "Activity_QuestRush", -- 童话quest主题 挑战活动
    CHINESE_STYLE = "Activity_QuestRushChineseStyle", -- 中国风quest主题 挑战活动
    HAWAII = "Activity_QuestRushHawaii", -- 夏威夷quest主题 挑战活动
    PIRATE = "Activity_QuestRushPirate", -- 海盗quest主题 挑战活动
    EASTER = "Activity_QuestRushEaster", -- 复活节quest主题 挑战活动
    HALLOWEEN = "Activity_QuestRushHalloween", -- 万圣节quest主题 挑战活动
    THANKSGIVING = "Activity_QuestRushThanksGiving", -- 万圣节quest主题 挑战活动
    CHRISTMAS = "Activity_QuestRushChristmas", -- 万圣节quest主题 挑战活动
    ISLAND = "Activity_QuestRushIsland" -- 海盗quest主题 挑战活动
}

-- 任务类型
Activity_QuestRushConfig.RUSH_TYPE = {
    STAR = "1001", -- 累积星星完成任务
    STAGE = "1002", -- 累积过关完成任务
    CHAPTER = "1003" -- 累积章节完成任务
}

-- 任务要求选择难度
Activity_QuestRushConfig.RUSH_DIFF = {
    DEFAULT = -1, -- 默认 不区分难度
    EASY = 1, -- 简单
    NORMAL = 2, -- 普通
    HARD = 3 -- 困难
}

-- 主题-资源 对照列表
Activity_QuestRushConfig.RESOURCE = {
    -- 童话主题
    [Activity_QuestRushConfig.RUSH_THEME.FAIRY_TALES] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/QuestRushFairyTales/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/QuestRushFairyTales/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/QuestRushFairyTales/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/QuestRushFairyTales/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/QuestRushFairyTales/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/QuestRushFairyTales/csb/QuestLobbyRushPlusEntry.csb"
        }
    },
    -- 中国风主题
    [Activity_QuestRushConfig.RUSH_THEME.CHINESE_STYLE] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/ChineseStyle/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/ChineseStyle/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/ChineseStyle/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/ChineseStyle/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/ChineseStyle/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/ChineseStyle/csb/QuestLobbyRushPlusEntry.csb"
        }
    },
    -- 夏威夷主题
    [Activity_QuestRushConfig.RUSH_THEME.HAWAII] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/Hawaii/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/Hawaii/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/Hawaii/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/Hawaii/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/Hawaii/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/Hawaii/csb/QuestLobbyRushPlusEntry.csb"
        }
    },
    -- 海盗主题
    [Activity_QuestRushConfig.RUSH_THEME.PIRATE] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/Pirate/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/Pirate/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/Pirate/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/Pirate/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/Pirate/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/Pirate/csb/QuestLobbyRushPlusEntry.csb"
        }
    },
    -- 复活节主题
    [Activity_QuestRushConfig.RUSH_THEME.EASTER] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/QuestRushEaster/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/QuestRushEaster/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/QuestRushEaster/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/QuestRushEaster/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/QuestRushEaster/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/QuestRushEaster/csb/QuestLobbyRushPlusEntry.csb"
        }
    },
    -- 万圣节主题
    [Activity_QuestRushConfig.RUSH_THEME.HALLOWEEN] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/Halloween/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/Halloween/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/Halloween/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/Halloween/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/Halloween/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/Halloween/csb/QuestLobbyRushPlusEntry.csb"
        }
    },
    -- 感恩节主题
    [Activity_QuestRushConfig.RUSH_THEME.THANKSGIVING] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/ThanksGiving/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/ThanksGiving/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/ThanksGiving/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/ThanksGiving/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/ThanksGiving/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/ThanksGiving/csb/QuestLobbyRushPlusEntry.csb"
        }
    },
    -- 圣诞节主题
    [Activity_QuestRushConfig.RUSH_THEME.CHRISTMAS] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/Christmas/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/Christmas/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/Christmas/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/Christmas/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/Christmas/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/Christmas/csb/QuestLobbyRushPlusEntry.csb"
        }
    },
    -- 海岛主题
    [Activity_QuestRushConfig.RUSH_THEME.ISLAND] = {
        [Activity_QuestRushConfig.RUSH_TYPE.STAR] = {
            TASK_MAIN = "Activity/QuestRushIsland/csb/QuestRushMainlayer.csb",
            ENTRY = "Activity/QuestRushIsland/csb/QuestLobbyRushEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.STAGE] = {
            TASK_MAIN = "Activity/QuestRushIsland/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/QuestRushIsland/csb/QuestLobbyRushPlusEntry.csb"
        },
        [Activity_QuestRushConfig.RUSH_TYPE.CHAPTER] = {
            TASK_MAIN = "Activity/QuestRushIsland/csb/QuestRushPlusMainlayer.csb",
            ENTRY = "Activity/QuestRushIsland/csb/QuestLobbyRushPlusEntry.csb"
        }
    }
}

return Activity_QuestRushConfig
