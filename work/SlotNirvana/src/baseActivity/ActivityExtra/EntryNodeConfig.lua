-- FIX IOS 139
-- 关卡能量收集条 配置

local EntryNodeConfig = class("EntryNodeConfig")

-- 关卡能量收集条 状态
EntryNodeConfig.NODE_STATE = {
    NORMAL = "normal",
    SMALL = "small"
}

-- 积满弹板显示状态
EntryNodeConfig.COLLECT_MAX_STATE = {
    WILL_SHOW = "DEFAULT", -- 等待显示
    ON_SHOW = "SHOW", -- 可以显示
    SHOW_OVER = "CANNOT" -- 不能显示
}

--------------------------------- FIXIT 第一步 添加活动必要信息 ---------------------------------
--[[
    GameInit 文件
    1 活动类型定义 ACTIVITY_TYPE
    2 活动和促销引用名 ACTIVITY_REF
]]
--------------------------------- FIXIT 第二步 配置关卡能量收集条相关信息(日志 跳转 收集特效) ---------------------------------
EntryNodeConfig.data_config = {
    [ACTIVITY_REF.Word] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "WordStageIcon", -- 活动左边条 打点传入参数
        lua_file = "WordMainUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/Other/word_collect_icon.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.DinnerLand] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "DinnerLandStageIcon", -- 活动左边条 打点传入参数
        lua_file = "DinnerLandGameUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/DinnerLand/img/gamesceneui/DinnerLand_GameSceneUI_CoinIcon.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.Blast] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "BlastStageIcon", -- 活动左边条 打点传入参数
        lua_file = "BlastMainUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/Blast/shouji.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.Bingo] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "BingoStageIcon", -- 活动左边条 打点传入参数
        lua_file = "BingoGameUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/Other/bingo_progress_ball.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.CoinPusher] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "CoinPusherStageIcon", -- 活动左边条 打点传入参数
        lua_file = "CoinPusherSelectUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/coinpusher/CoinPusherCollect.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.RichMan] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "RichManStageIcon", -- 活动左边条 打点传入参数
        lua_file = "RichManMain", -- 活动主界面lua名称
        fly_effect_name = "Activity/richman_other/dice.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.WorldTrip] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "WorldTripStageIcon", -- 活动左边条 打点传入参数
        lua_file = "WorldTripMainUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/WorldTrip/other/WorldTrip_dice.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.DiningRoom] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "DiningRoomStageIcon", -- 活动左边条 打点传入参数
        lua_file = "DiningRoomGameUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/Diningroom/img/main/DinnerLand_Maxinum_CoinIcon.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.BalloonRush] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "BalloonRushStageIcon", -- 活动左边条 打点传入参数
        --lua_file = "Activity_BalloonRush", -- 活动主界面lua名称
        --fly_effect_name = "Activity/BalloonRush/other/icon_balloon_fly.png", -- 飞行动画索引路径
        lua_file = "Activity_RainbowRush", -- 活动主界面lua名称  -- 临时修改
        fly_effect_name = "Activity/RainbowRush/Rainbow_icon/icon_rainbow_fly.png", -- 飞行动画索引路径  -- 临时修改
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.NewCoinPusher] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "NewCoinPusherStageIcon", -- 活动左边条 打点传入参数
        lua_file = "NewCoinPusherSelectUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/CoinPusher_New/coinpusher/CoinPusherCollect.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.PipeConnect] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "PipeConnectStageIcon", -- 活动左边条 打点传入参数
        lua_file = "PipeConnectGameUI", -- 活动主界面lua名称
        fly_effect_name = "Activity_PipeConnect/ui/shouji.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.Zombie] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "ZombieStageIcon", -- 活动左边条 打点传入参数
        lua_file = "ZomBieInfoUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/Zombie/shouji.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.OutsideCave] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "OutsideCaveStageIcon", -- 活动左边条 打点传入参数
        lua_file = "OCMainLayer", -- 活动主界面lua名称
        fly_effect_name = "Activity_OutsideCave/other/bone.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    },
    [ACTIVITY_REF.EgyptCoinPusher] = {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "EgyptCoinPusherStageIcon", -- 活动左边条 打点传入参数
        lua_file = "EgyptCoinPusherSelectUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/CoinPusher_Egypt/coinpusher/CoinPusherCollect.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    }
}

--------------------------------- FIXIT 第四步 配置关卡活动弹板信息(升级弹板 收集以及集满弹板) ---------------------------------
-- ！！！ 关卡弹框列表 只有继承了EntryNodeBase的活动类才有效
EntryNodeConfig.popup_config = {
    [ACTIVITY_REF.Word] = {
        ["levelUp"] = "Activity/Activity_Word", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "Activity/WordGame/Activity_WordCollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "WordMainUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/Word/csd/Word_GetWord/Word_GetWord.csb", -- 横版资源路径
            ["portrait"] = "Activity/Word/csd/Word_GetWord/Word_GetWord_Portrait.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity/WordGame/Activity_WordCollectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "WordMainUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/Word/csd/Word_GetWord/Word_GetWordMax.csb", -- 横版资源路径
            ["portrait"] = "Activity/Word/csd/Word_GetWord/Word_GetWordMax_Portrait.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.DinnerLand] = {
        ["levelUp"] = "Activity/Activity_DinnerLand", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            --"baseActivity/ActivityExtra/Activity_CollectPop"
            ["lua_file"] = "Activity/DinnerLandGame/DinnerMaxEnergy", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["horizontal"] = "Activity/DinnerLand/csb/DinnerMaximum2.csb", -- 横版资源路径
            ["portrait"] = "Activity/DinnerLand/csb/DinnerMaximum2_Portrait.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            -- "baseActivity/ActivityExtra/Activity_CollectMaxPop"
            ["lua_file"] = "Activity/DinnerLandGame/DinnerMaxCoin", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["horizontal"] = "Activity/DinnerLand/csb/DinnerMaximum.csb", -- 横版资源路径
            ["portrait"] = "Activity/DinnerLand/csb/DinnerMaximum_Portrait.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.Bingo] = {
        ["levelUp"] = "Activity/Activity_Bingo", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "BingoGameUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/csd/Bingo_PopupBoards/Activity_CollectPop_Bingo.csb", -- 横版资源路径
            ["portrait"] = "Activity/csd/Bingo_PopupBoards/Activity_CollectPop_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "BingoGameUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/csd/Bingo_PopupBoards/Activity_CollectMaxPop_Bingo.csb", -- 横版资源路径
            ["portrait"] = "Activity/csd/Bingo_PopupBoards/Activity_CollectMaxPop_Portralt.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.CoinPusher] = {
        ["levelUp"] = "Activity/Activity_CoinPusher", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "Activity/CoinPusherGame/CoinPusherMaxEnergy", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "CoinPusherSelectUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/CoinPusher_CollectPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/CoinPusher_CollectPop_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity/CoinPusherGame/CoinPusherMaxCoin", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "CoinPusherSelectUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/CoinPusher_CollectMaxPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/CoinPusher_CollectMaxPop_Portralt.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.RichMan] = {
        ["levelUp"] = "Activity/Activity_RichMan", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "Activity/RichManGame/Activity_RichManCollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "RichManMain", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/richman/Activity_CollectPop_rM.csb", -- 横版资源路径
            ["portrait"] = "Activity/richman/Activity_CollectPop_rM_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity/RichManGame/Activity_RichManCollectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "RichManMain", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/richman/Activity_CollectMaxPop_rM.csb", -- 横版资源路径
            ["portrait"] = "Activity/richman/Activity_CollectMaxPop_rM_Portralt.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.WorldTrip] = {
        ["levelUp"] = "Activity/Activity_WorldTrip", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "WorldTripMainUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/WorldTrip/csd/drop/Activity_CollectPop_WorldTrip.csb", -- 横版资源路径
            ["portrait"] = "Activity/WorldTrip/csd/drop/Activity_CollectPop_WorldTrip_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "WorldTripMainUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/WorldTrip/csd/drop/Activity_CollectMaxPop_WorldTrip.csb", -- 横版资源路径
            ["portrait"] = "Activity/WorldTrip/csd/drop/Activity_CollectMaxPop_WorldTrip_Portralt.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.DiningRoom] = {
        ["levelUp"] = "Activity/Activity_DiningRoom", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "DiningRoomGameUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/Diningroom/csb/collect/Activity_CollectPop_DiningRoom.csb", -- 横版资源路径
            ["portrait"] = "Activity/Diningroom/csb/collect/Activity_CollectPop_DiningRoom_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "DiningRoomGameUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/Diningroom/csb/collect/Activity_CollectMaxPop_DiningRoom.csb", -- 横版资源路径
            ["portrait"] = "Activity/Diningroom/csb/collect/Activity_CollectMaxPop_DiningRoom_Portralt.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.NewCoinPusher] = {
        ["levelUp"] = "Activity/Activity_NewCoinPusher", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "Activity/NewCoinPusherGame/NewCoinPusherMaxEnergy", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "NewCoinPusherSelectUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/CoinPusher_New/csd/slots/CoinPusher_CollectPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/CoinPusher_New/csd/slots/CoinPusher_CollectPop_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity/NewCoinPusherGame/NewCoinPusherMaxCoin", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "NewCoinPusherSelectUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/CoinPusher_New/csd/slots/CoinPusher_CollectMaxPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/CoinPusher_New/csd/slots/CoinPusher_CollectMaxPop_Portralt.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.PipeConnect] = {
        ["levelUp"] = "Activity/Activity_PipeConnect", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "PipeConnectGameUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity_PipeConnect/csd/PipeConnect_PopupBoards/Activity_CollectPop_Pipe.csb", -- 横版资源路径
            ["portrait"] = "Activity_PipeConnect/csd/PipeConnect_PopupBoards/Activity_CollectPop_Pipe_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity/PipeConnectGame/PipeConnectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "PipeConnectGameUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity_PipeConnect/csd/PipeConnect_PopupBoards/Activity_CollectMaxPop_Pipe.csb", -- 横版资源路径
            ["portrait"] = "Activity_PipeConnect/csd/PipeConnect_PopupBoards/Activity_CollectMaxPop_Pipe_Portralt.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.OutsideCave] = {
        ["levelUp"] = "Activity_OutsideCave_loading/Activity_OutsideCave", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {--"PopUp/OutsideCaveCollectPop"
            ["lua_file"] = "Activity_OutsideCave/PopUp/OutsideCaveCollectPop", 
            ["game_file"] = "OCMainLayer", -- 跳转活动主界面名称
            ["horizontal"] = "Activity_OutsideCave/csd/PopupBoards/Activity_CollectPop_OutsideCave.csb", -- 横版资源路径
            ["portrait"] = "Activity_OutsideCave/csd/PopupBoards/Activity_CollectPop_OutsideCave_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity_OutsideCave/PopUp/OutsideCaveMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "OCMainLayer", -- 跳转活动主界面名称
            ["horizontal"] = "Activity_OutsideCave/csd/PopupBoards/Activity_CollectMaxPop_OutsideCave.csb", -- 横版资源路径
            ["portrait"] = "Activity_OutsideCave/csd/PopupBoards/Activity_CollectMaxPop_OutsideCave_Portralt.csb" -- 竖版资源路径
        }
    },
    [ACTIVITY_REF.EgyptCoinPusher] = {
        ["levelUp"] = "Activity/Activity_EgyptCoinPusher", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "Activity/EgyptCoinPusherGame/EgyptCoinPusherMaxEnergy", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "EgyptCoinPusherSelectUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/CoinPusher_Egypt/csd/Slots_Egypt/CoinPusher_CollectPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/CoinPusher_Egypt/csd/Slots_Egypt/CoinPusher_CollectPop_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity/EgyptCoinPusherGame/EgyptCoinPusherMaxCoin", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "EgyptCoinPusherSelectUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/CoinPusher_Egypt/csd/Slots_Egypt/CoinPusher_CollectMaxPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/CoinPusher_Egypt/csd/Slots_Egypt/CoinPusher_CollectMaxPop_Portralt.csb" -- 竖版资源路径
        }
    }
}

-- 多主题需要刷新某些资源 写这里了
function EntryNodeConfig.reloadFile(_themeName, _actRefType)
    _actRefType = _actRefType or ACTIVITY_REF.Blast
    if _actRefType == ACTIVITY_REF.Blast then
        EntryNodeConfig.reloadFile_Blast(_themeName)
    elseif _actRefType == ACTIVITY_REF.CoinPusher then
        EntryNodeConfig.reloadFile_CoinPusher(_themeName)
    elseif _actRefType ==  ACTIVITY_REF.NewCoinPusher then
        EntryNodeConfig.reloadFile_NewCoinPusher(_themeName)
    end
end
function EntryNodeConfig.reloadFile_Blast(themeName)
    local blast_dataConfig = EntryNodeConfig.data_config[ACTIVITY_REF.Blast]
    local levelUpRes = "Activity/Activity_Blast"
    local res_path = "Activity/Blast/" -- 重新指定资源路径
    -- blast 修改收集道具特效资源路径
    if themeName == "Activity_Blast" then
        -- 海洋主题
        blast_dataConfig.fly_effect_name = "Activity/Blast/shouji.png" -- 飞道具
        levelUpRes = "Activity/Activity_Blast"
        res_path = "Activity/Blast/"
    elseif themeName == "Activity_BlastHalloween" then
        -- 万圣节主题
        blast_dataConfig.fly_effect_name = "Activity/Blast_Halloween/shouji.png" -- 飞道具
        levelUpRes = "Activity/Activity_BlastHalloween"
        res_path = "Activity/Blast_Halloween/"
    elseif themeName == "Activity_BlastThanksGiving" then
        -- 感恩节主题
        blast_dataConfig.fly_effect_name = "Activity/Blast_ThanksGiving/shouji.png" -- 飞道具
        levelUpRes = "Activity/Activity_BlastThanksGiving"
        res_path = "Activity/Blast_ThanksGiving/"
    elseif themeName == "Activity_BlastChristmas" then
        -- 圣诞节主题
        blast_dataConfig.fly_effect_name = "Activity/Blast_Christmas/shouji.png" -- 飞道具
        levelUpRes = "Activity/Activity_BlastChristmas"
        res_path = "Activity/Blast_Christmas/"
    elseif themeName == "Activity_BlastEaster" then
        -- 复活节主题
        blast_dataConfig.fly_effect_name = "Activity/Blast_Easter/shouji.png" -- 飞道具
        levelUpRes = "Activity/Activity_BlastEaster"
        res_path = "Activity/Blast_Easter/"
    elseif themeName == "Activity_Blast3RD" then
        -- 复活节主题
        blast_dataConfig.fly_effect_name = "Activity/Blast_3RD/shouji.png" -- 飞道具
        levelUpRes = "Activity/Activity_Blast3RD"
        res_path = "Activity/Blast_3RD/"
    elseif themeName == "Activity_BlastBlossom" then
        -- 阿凡达
        blast_dataConfig.fly_effect_name = "Activity/Blast_Blossom/shouji.png" -- 飞道具
        levelUpRes = "Activity/Activity_BlastBlossom"
        res_path = "Activity/Blast_Blossom/"
    elseif themeName == "Activity_BlastMermaid" then
        -- 人鱼
        blast_dataConfig.fly_effect_name = "Activity/Blast_Mermaid/shouji.png" -- 飞道具
        levelUpRes = "Activity/Activity_BlastMermaid"
        res_path = "Activity/Blast_Mermaid/"
    end

    EntryNodeConfig.popup_config[ACTIVITY_REF.Blast] = {
        ["levelUp"] = levelUpRes, -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "Activity/BlastGame/Activity_BlastCollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "BlastMainUI", -- 跳转活动主界面名称
            ["horizontal"] = res_path .. "Activity_CollectPop_Blast.csb", -- 横版资源路径
            ["portrait"] = res_path .. "Activity_CollectPop_Blast_Portralt.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "Activity/BlastGame/Activity_BlastCollectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "BlastMainUI", -- 跳转活动主界面名称
            ["horizontal"] = res_path .. "Activity_CollectMaxPop_Blast.csb", -- 横版资源路径
            ["portrait"] = res_path .. "Activity_CollectMaxPop_Blast_Portralt.csb" -- 竖版资源路径
        }
    }
end
function EntryNodeConfig.reloadFile_CoinPusher(themeName)
    if themeName == ACTIVITY_REF.CoinPusher then
        return
    elseif themeName == "Activity_CoinPusher_Easter" then
        EntryNodeConfig.data_config[ACTIVITY_REF.CoinPusher].fly_effect_name = "Activity/coinPusher_easter/coinpusher/CoinPusherCollect.png" -- 飞行动画索引路径
        EntryNodeConfig.popup_config[ACTIVITY_REF.CoinPusher] = {
            ["levelUp"] = "Activity/Activity_CoinPusher_Easter", -- 升级弹板lua文件路径
            -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
            ["collect"] = {
                ["lua_file"] = "Activity/CoinPusherGame/CoinPusherMaxEnergy", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
                ["game_file"] = "CoinPusherSelectUI", -- 跳转活动主界面名称
                ["horizontal"] = "Activity/coinPusher_easter/csb/CoinPusher_CollectPop.csb", -- 横版资源路径
                ["portrait"] = "Activity/coinPusher_easter/csb/CoinPusher_CollectPop_Portralt.csb" -- 竖版资源路径
            },
            -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
            ["collect_max"] = {
                ["lua_file"] = "Activity/CoinPusherGame/CoinPusherMaxCoin", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
                ["game_file"] = "CoinPusherSelectUI", -- 跳转活动主界面名称
                ["horizontal"] = "Activity/coinPusher_easter/csb/CoinPusher_CollectMaxPop.csb", -- 横版资源路径
                ["portrait"] = "Activity/coinPusher_easter/csb/CoinPusher_CollectMaxPop_Portralt.csb" -- 竖版资源路径
            }
        }
    elseif themeName == "Activity_CoinPusher_Liberty" then
        EntryNodeConfig.data_config[ACTIVITY_REF.CoinPusher].fly_effect_name = "Activity/coinPusher_liberty/coinpusher/CoinPusherCollect.png" -- 飞行动画索引路径
        EntryNodeConfig.popup_config[ACTIVITY_REF.CoinPusher] = {
            ["levelUp"] = "Activity/Activity_CoinPusher_Liberty", -- 升级弹板lua文件路径
            -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
            ["collect"] = {
                ["lua_file"] = "Activity/CoinPusherGame/CoinPusherMaxEnergy", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
                ["game_file"] = "CoinPusherSelectUI", -- 跳转活动主界面名称
                ["horizontal"] = "Activity/coinPusher_liberty/csb/CoinPusher_CollectPop.csb", -- 横版资源路径
                ["portrait"] = "Activity/coinPusher_liberty/csb/CoinPusher_CollectPop_Portralt.csb" -- 竖版资源路径
            },
            -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
            ["collect_max"] = {
                ["lua_file"] = "Activity/CoinPusherGame/CoinPusherMaxCoin", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
                ["game_file"] = "CoinPusherSelectUI", -- 跳转活动主界面名称
                ["horizontal"] = "Activity/coinPusher_liberty/csb/CoinPusher_CollectMaxPop.csb", -- 横版资源路径
                ["portrait"] = "Activity/coinPusher_liberty/csb/CoinPusher_CollectMaxPop_Portralt.csb" -- 竖版资源路径
            }
        }
    end
end

function EntryNodeConfig.reloadFile_NewCoinPusher(themeName)
    if themeName == ACTIVITY_REF.NewCoinPusher then
        return
    end
end

-- 增加配置 给多主题用
function EntryNodeConfig.addDataConfig(_activityRefName, _dataConfig)
    if EntryNodeConfig.data_config[_activityRefName] ~= nil then
        EntryNodeConfig.data_config[_activityRefName] = nil
    end
    EntryNodeConfig.data_config[_activityRefName] = _dataConfig
end

-- 增加配置 给多主题用
function EntryNodeConfig.addPopConfig(_activityRefName, _popConfig)
    if EntryNodeConfig.popup_config[_activityRefName] ~= nil then
        EntryNodeConfig.popup_config[_activityRefName] = nil
    end
    EntryNodeConfig.popup_config[_activityRefName] = _popConfig
end

return EntryNodeConfig
