--[[
    CoinPusher Config
    tm
]]
local EgyptCoinPusherConfig = {}

-- 调试状态
EgyptCoinPusherConfig.Debug = false --debug界面
EgyptCoinPusherConfig.DebugCoinCount = false --debug界面
EgyptCoinPusherConfig.FixCarmer = true --固定视角
EgyptCoinPusherConfig.ConfigInitDisk = true --配置初始化盘面

--推币机版本
EgyptCoinPusherConfig.Version = "V1"
--------------------------------推币机参数 START-------------------------------------
-- 推币机速度
EgyptCoinPusherConfig.PusherSpeed = 5
EgyptCoinPusherConfig.Gravity = -20

EgyptCoinPusherConfig.PointerSpeed = 70 --指针旋转角度 速度
EgyptCoinPusherConfig.PointerRotMax_Z = 90 --指针旋转最大角度

EgyptCoinPusherConfig.BasketSpeed = 3 --篮筐移动 速度
EgyptCoinPusherConfig.BasketPosMax_X = 1.5 --篮筐左右移动 最大距离 远离中心

--质量系数(金币)
EgyptCoinPusherConfig.RatioMass = 1

--摩擦力系数
EgyptCoinPusherConfig.RatioFrichtion = 2 --金币
EgyptCoinPusherConfig.PlatformFrichtion = 1 --地板中间部分
EgyptCoinPusherConfig.BorderPlatformFrichtion = 10 --地板两侧
EgyptCoinPusherConfig.FrontFriction = 0.2 --地板前部
EgyptCoinPusherConfig.BackFriction = 0.3 --地板后部
EgyptCoinPusherConfig.MiddleFriction = 1 --地板中部

--金币 mask标记起始 常量数值
EgyptCoinPusherConfig.IconMaskBegin = 10000000 --地板中部
EgyptCoinPusherConfig.WinFloorMask = 100 --地板成功
EgyptCoinPusherConfig.LoseFloorMask = 1000 --地板失败

--------------------------------推币机参数 END-------------------------------------
-----------------------

--掉落实体类型
EgyptCoinPusherConfig.EntityType = {
    COIN = 1,
    ITEM = 2
}

--掉落实体类型
EgyptCoinPusherConfig.EntityDropType = {
    WIN = 1,
    LOSE = 2
}

--触发动画类型
EgyptCoinPusherConfig.CoinEffectRefer = {
    NORMAL = "NORMAL",
    COINS = "COINS",
    STAGE_COINS = "STAGE_COINS",
    SLOTS = "SLOTS",
    CARD = "CARD",
    BIG = "BIG_COINS",
    DROP = "DROP" --点击掉落金币
}

EgyptCoinPusherConfig.SlotEffectRefer = {
    SLOT = "SLOT", --水果机滚动
    JACKPOT = "NORMAL", --触发jp 奖励coins
    BIGCOIN = "BIG_COINS", --掉落打金币
    HAMMER = "HAMMER", --锤子
    STAGE_COIN = "STAGE_COINS", --加成道具
    SMALLCOIN = "COINS",
     -- 小钱硬币
    LONGPUSHER = "LONGPUSHER"
    -- 长推板
}

--掉落实体类型
EgyptCoinPusherConfig.CoinModelRefer = {
    "NORMAL",
    "COINS",
    "STAGE_COINS",
    "CARD",
    "BIG_COINS"
}

EgyptCoinPusherConfig.CoinPreCreateConfig = {
    NORMAL = 10,
    COINS = 10,
    STAGE_COINS = 10,
    SLOTS = 10,
    CARD = 10,
    BIG = 5
}

-- 各种金币相关属性 --
EgyptCoinPusherConfig.CoinModelAtt = {
    --基础金币
    ["NORMAL"] = {
        Name = "NORMAL",
        Mass = 1.0 * EgyptCoinPusherConfig.RatioMass,
        Friction = 0.3 * EgyptCoinPusherConfig.RatioFrichtion,
        Model = "Activity/CoinPusher_Egypt/models/coin/jinbi_g2.c3b", --jinbi
        Texture = "Activity/CoinPusher_Egypt/models/coin/normalCoin.png",
        Scale = 14,
        palne = 12,
        PhysicSize = cc.p(0.8, 0.18)
    },
    ["COINS"] = {
        Name = "COINS",
        Mass = 1.0 * EgyptCoinPusherConfig.RatioMass,
        Friction = 0.3 * EgyptCoinPusherConfig.RatioFrichtion,
        Model = "Activity/CoinPusher_Egypt/models/coin/jinbi_g2.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/coin/Coins.png",
        Scale = 15,
        palne = 6,
        PhysicSize = cc.p(0.8, 0.18)
    },
    ["STAGE_COINS"] = {
        Name = "STAGE_COINS",
        Mass = 1.0 * EgyptCoinPusherConfig.RatioMass,
        Friction = 0.3 * EgyptCoinPusherConfig.RatioFrichtion,
        Model = "Activity/CoinPusher_Egypt/models/coin/jinbi_g2.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/coin/StageCoins.png",
        Scale = 15,
        palne = 6,
        PhysicSize = cc.p(0.8, 0.18)
    },
    ["CARD"] = {
        Name = "CARD",
        Mass = 1.0 * EgyptCoinPusherConfig.RatioMass,
        Friction = 0.3 * EgyptCoinPusherConfig.RatioFrichtion,
        Model = "Activity/CoinPusher_Egypt/models/coin/jinbi_g2.c3b", --jinbi
        Texture = "Activity/CoinPusher_Egypt/models/coin/Material__42_Base_color.png",
        Scale = 10,
        palne = 12,
        PhysicSize = cc.p(0.8, 0.18)
    },
    ["BIG_COINS"] = {
        Name = "BIG_COINS",
        Mass = 3.0 * EgyptCoinPusherConfig.RatioMass,
        Friction = 0.3 * EgyptCoinPusherConfig.RatioFrichtion,
        Model = "Activity/CoinPusher_Egypt/models/coin/djb_s.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/coin/jinbi_ts_Base_color.png",
        Scale = 20,
        palne = 12,
        PhysicSize = cc.p(1.1, 0.18)
    },
    [7] = {
        Name = "CoinChipStack4",
        Mass = 400.0,
        Friction = 0.3,
        Model = "Activity/CoinPusher_Egypt/coinpusher/CoinChipStack4.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/CoinChipStack4.png",
        Scale = 2,
        PhysicSize = cc.p(0.8, 0.18)
    }
}

-- 各种道具属性 --
EgyptCoinPusherConfig.ItemModelAtt = {
    [1] = {
        Name = "PrizeElephantBlue",
        Mass = 1000.0,
        Friction = 0.,
        Model = "Activity/CoinPusher_Egypt/coinpusher/PrizeElephantBlue.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/PrizeElephantBlue.png",
        Scale = 10,
        PhysicSize = {
            type = "box",
            size = cc.vec3(4.0, 4.0, 6),
            off = cc.vec3(0.0, -1, -0.5),
            angle = cc.vec3(-90.0, 180.0, 0.0)
        }
    },
    [2] = {
        Name = "PrizeHeartGemPurple",
        Mass = 1000.0,
        Friction = 0.6,
        Model = "Activity/CoinPusher_Egypt/coinpusher/PrizeHeartGemPurple.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/PrizeHeartGemPurple.png",
        Scale = 10,
        PhysicSize = {
            type = "box",
            size = cc.vec3(4.5, 4.5, 1.8),
            off = cc.vec3(0.0, 0, 0),
            angle = cc.vec3(-90.0, 180.0, 0.0)
        }
    },
    [3] = {
        Name = "PrizeJetWhite",
        Mass = 1000.0,
        Friction = 0.6,
        Model = "Activity/CoinPusher_Egypt/coinpusher/PrizeJetWhite.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/PrizeJetWhite.png",
        Scale = 10,
        PhysicSize = {
            type = "box",
            size = cc.vec3(5, 3, 5),
            off = cc.vec3(0.0, 0, 0),
            angle = cc.vec3(-0.0, 180.0, 0.0)
        }
    },
    [4] = {
        Name = "PrizeTiaraPurple",
        Mass = 1000.0,
        Friction = 0.6,
        Model = "Activity/CoinPusher_Egypt/coinpusher/PrizeTiaraPurple.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/PrizeTiaraPurple.png",
        Scale = 10,
        PhysicSize = {
            type = "cylinder",
            size = cc.p(4, 3),
            off = cc.vec3(0.0, -0.2, 0),
            angle = cc.vec3(-0.0, 180.0, 0.0)
        }
    },
    [5] = {
        Name = "PrizeWatchWhite",
        Mass = 1000.0,
        Friction = 0.6,
        Model = "Activity/CoinPusher_Egypt/coinpusher/PrizeWatchWhite.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/PrizeWatchWhite.png",
        Scale = 10,
        PhysicSize = {
            type = "cylinder",
            size = cc.p(4.5, 2.8),
            off = cc.vec3(0.0, -0.0, 0),
            angle = cc.vec3(-0.0, 180.0, 0.0)
        }
    }
}

-- 静态场景属性 --
EgyptCoinPusherConfig.PlatformModelAtt = {
    Platform = {
        Mass = 0.0,
        Model = "Activity/CoinPusher_Egypt/models/zhuti/zhuti.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Friction = 0.3 * EgyptCoinPusherConfig.PlatformFrichtion,
        BorderFriction = 0.3 * EgyptCoinPusherConfig.BorderPlatformFrichtion,
        FrontFriction = 0.3 * EgyptCoinPusherConfig.FrontFriction,
        BackFriction = 0.3 * EgyptCoinPusherConfig.BackFriction,
        MiddleFriction = 0.3 * EgyptCoinPusherConfig.MiddleFriction,
        Scale = 2.5
    },
    Slope = {
        Mass = 0.0, --斜坡
        Model = "Activity/CoinPusher_Egypt/models/zhuti/xiepo.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 2.5
    },
    Jackpot = {
        Mass = 0.0,
        Model = "Activity/CoinPusher_Egypt/coinpusher/beijingui.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/MachineJackpot.png",
        Scale = 10
    },
    Pusher = {
        Mass = 0.0,
        Model = "Activity/CoinPusher_Egypt/models/tuiban/tuibi.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 2.5
    },
    Lifter = {
        Mass = 0.0,
        Model = "Activity/CoinPusher_Egypt/models/buf_ban/taimianqiang.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 2.05
    },
    ReelUnit = {
        Mass = 0.0,
        Model = "Activity/CoinPusher_Egypt/coinpusher/reelunit.c3b",
        Texture = "",
        Scale = 10
    },
    Nail = {
        Mass = 0.0, --钉子
        Model = "Activity/CoinPusher_Egypt/models/zhuzi/xiaozhuzi.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 0.96
    },
    SwallowHole = {
        Mass = 0.0, --吞币口
        Model = "Activity/CoinPusher_Egypt/models/basket/tubikou.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 2.5
    },
    SpitHole = {
        Mass = 0.0, --吐币口
        Model = "Activity/CoinPusher_Egypt/models/zhuti/xiangzi.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 2.5
    },
    pointer = {
        Mass = 0.0, --摆动指针
        Model = "Activity/CoinPusher_Egypt/models/zhuzi/xiaozhuzi.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 2.5
    },
    slot = {
        Mass = 0.0, --摆动指针
        Model = "Activity/CoinPusher_Egypt/models/basket/gunlun.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 2.5
    },
    bug = {
        Mass = 0.0, --摆动指针
        Model = "Activity/CoinPusher_Egypt/models/bug/chong.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
        Scale = 5
    }
}

-- Slot轮盘相关 --
EgyptCoinPusherConfig.ReelRollSpeed = -40
EgyptCoinPusherConfig.ReelJumpUpTime = 0.3
EgyptCoinPusherConfig.ReelTopPos = 7.2
EgyptCoinPusherConfig.ReelBottomPos = -7.2
EgyptCoinPusherConfig.ReelStopPos = 0
EgyptCoinPusherConfig.ReelTableCenter = cc.vec3(0, 15, -30)
EgyptCoinPusherConfig.ReelUnitCenter = {
    cc.vec3(-7.2, 0, 0),
    cc.vec3(0, 0, 0),
    cc.vec3(7.2, 0, 0)
}
EgyptCoinPusherConfig.ReelUnitConfig = {
    {cc.vec3(0, 0, 0), cc.vec3(0, 7.2, 0)},
    {cc.vec3(0, 0, 0), cc.vec3(0, 7.2, 0)},
    {cc.vec3(0, 0, 0), cc.vec3(0, 7.2, 0)}
}

EgyptCoinPusherConfig.ReelJumpConfig = {
    {DelayTime = 0, DestPosY = 2},
    {DelayTime = 0.1, DestPosY = 2},
    {DelayTime = 0.2, DestPosY = 2}
}

-- 假滚数据 --
EgyptCoinPusherConfig.ReelDataConfig = {
    {1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5},
    {1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5},
    {1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5}
}
-- 滚动停止间隔 --
EgyptCoinPusherConfig.ReelStopOffset = {9, 13, 19}
EgyptCoinPusherConfig.ReelDataNums = {
    table.nums(EgyptCoinPusherConfig.ReelDataConfig[1]),
    table.nums(EgyptCoinPusherConfig.ReelDataConfig[2]),
    table.nums(EgyptCoinPusherConfig.ReelDataConfig[3])
}
EgyptCoinPusherConfig.ReelStatus = {
    Idle = 0,
    JumpUp = 1,
    Running = 2,
    JumpDown = 3,
    Stoping = 4
}

EgyptCoinPusherConfig.SlotType = {
    ["FREESPIN"] = 1,
    ["COINS"] = 2,
    ["HUMMER"] = 3
}
--老虎机滚动个数
EgyptCoinPusherConfig.SlotRunCount = {14, 18, 22}

-- 事件声明 --
EgyptCoinPusherConfig.Event = {
    EgyptCoinPusherGetDropCoinsReward = "EgyptCoinPusherGetDropCoinsReward",
    EgyptCoinPusherDropCoins = "EgyptCoinPusherDropCoins",
    EgyptCoinPusherTriggerEffect = "EgyptCoinPusherTriggerEffect",
    EgyptCoinPusherEffectEnd = "EgyptCoinPusherEffectEnd",
    EgyptCoinPusherSaveEntity = "EgyptCoinPusherSaveEntity",
    EgyptCoinPusherUpdateMainUI = "EgyptCoinPusherUpdateMainUI",
    EgyptCoinPusherStageLayer = "EgyptCoinPusherStageLayer",
    EgyptCoinPusherRoundLayer = "EgyptCoinPusherRoundLayer",
    --章节加成奖励
    EgyptCoinPusherStageBuffOpen = "EgyptCoinPusherStageBuffOpen",
    EgyptCoinPusherStageBuffClose = "EgyptCoinPusherStageBuffClose",
    EgyptCoinPusherCollectReward = "EgyptCoinPusherCollectReward" -- 收集奖励
}

-- 特效属性 --
EgyptCoinPusherConfig.Effect = {
    Hammer = {
        ID = 1,
        Type = "Model",
        Model = "Activity/CoinPusher_Egypt/models/effect/hammer.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/effect/chuizi.png",
        Scale = 3,
        ModelGuang = "Activity/CoinPusher_Egypt/models/effect/hammerguang.c3b",
        ModelBaozha = "Activity/CoinPusher_Egypt/models/effect/hammerbaozha.c3b"
    },
    FlashLight = {
        ID = 2,
        Type = "Model",
        Model = "Activity/CoinPusher_Egypt/coinpusher/flashlight.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/pian_tt.png",
        Scale = 10
    },
    FrontEffectPanel = {
        ID = 4,
        Type = "Model",
        Model = "Activity/CoinPusher_Egypt/coinpusher/frontEffectPanel.c3b",
        Texture = "Activity/CoinPusher_Egypt/coinpusher/dengA.png",
        Scale = 10
    },
    TapHere = {
        ID = 5,
        Type = "Model",
        Model = "Activity/CoinPusher_Egypt/models/effect/taphere.c3b",
        Texture = "Activity/CoinPusher_Egypt/models/effect/tap_here.png",
        Scale = 10
    }
}

-- 台前 序列帧特效 --
EgyptCoinPusherConfig.FrontEffectPic = {
    Idle = {
        "Activity/CoinPusher_Egypt/coinpusher/dengA_01.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengA_02.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengA_03.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengA_04.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengA_05.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengA_04.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengA_03.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengA_02.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengA_01.png"
    },
    IdleInterval = 0.5,
    Flash = {
        "Activity/CoinPusher_Egypt/coinpusher/dengB_01.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_02.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_03.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_04.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_05.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_06.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_05.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_04.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_03.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB_02.png"
    },
    FlashInterval = 0.1
}

-- jackpot 序列帧特效 --
EgyptCoinPusherConfig.JackPotEffectPic = {
    Idle = {
        "Activity/CoinPusher_Egypt/coinpusher/dengB1.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB2.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB3.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB2.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB1.png"
    },
    IdleInterval = 0.5,
    Flash = {
        "Activity/CoinPusher_Egypt/coinpusher/dengB1.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB2.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB3.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB2.png",
        "Activity/CoinPusher_Egypt/coinpusher/dengB1.png"
    },
    FlashInterval = 0.1
}

EgyptCoinPusherConfig.jackpotPosOri = cc.vec3(0.0, 0.0, 0)
EgyptCoinPusherConfig.jackpotPosDest = cc.vec3(0.0, 6.5, 0)

EgyptCoinPusherConfig.jackpotEffectPos = cc.vec3(0, -1.5, 0.0)
EgyptCoinPusherConfig.BlackFNT = "Activity/CoinPusher_Egypt/models/effect/font_arialblack.fnt"

-- 调试面板按钮图片 --
EgyptCoinPusherConfig.debugBtnRes = "Activity/CoinPusher_Egypt/coinpusher/btn.png"

--玩法状态
EgyptCoinPusherConfig.PlayState = {
    IDLE = 1, --未开始
    PLAYING = 2, --播放状态
    DONE = 3 --结束
}

--烟花特效配置
EgyptCoinPusherConfig.FireWorksCsb = {
    "Activity/CoinPusher_Egypt/csd/CoinPusher_YanHa_huang.csb",
    "Activity/CoinPusher_Egypt/csd/CoinPusher_YanHa_lan.csb",
    "Activity/CoinPusher_Egypt/csd/CoinPusher_YanHa_zi.csb"
}

--光圈特效配置
EgyptCoinPusherConfig.LightRingCsb = {
    "Activity/CoinPusher_Egypt/CoinPusher_Dhuangg.csb",
    "Activity/CoinPusher_Egypt/CoinPusher_Dlanguang.csb"
}

--章节状态
EgyptCoinPusherConfig.PlanesState = {
    COMPLETED = "COMPLETED",
    PLAY = "PLAY",
    LOCKD = "LOCKD"
}

--CSB
EgyptCoinPusherConfig.UICsbPath = {
    MainUI = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_MainLayer.csb",
    MainUITitle = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_MainLayerTitle.csb",
    MainUIProgress = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_MainLayerPrograss.csb",
    SelectUI = "Activity/CoinPusher_Egypt/csd/Chapter_Egypt/CoinPusher_Chapter.csb",
    SelectUIPortrait = "Activity/CoinPusher_Egypt/csd/Chapter_Egypt/CoinPusher_Chapter_Portralt.csb",
    SelectUIItem = "Activity/CoinPusher_Egypt/csd/Chapter_Egypt/CoinPusher_Chapter_Item1.csb",
    SelectUIItemPortrait = "Activity/CoinPusher_Egypt/csd/Chapter_Egypt/CoinPusher_Chapter_Item1_Portralt.csb",
    EntryNode = "Activity/CoinPusher_Egypt/csd/Slots_Egypt/CoinPusher_GameSceneUI.csb",
    NewGuide = "Activity/CoinPusher_Egypt/csd/CoinPusher_NewGuide.csb",
    CoinUI = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_Coin.csb",
    FruitCell = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_MainLayer_gezi.csb",
    FruitCellLight = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_MainLayer_light.csb",
    Bomb = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_MainLayer_bomb.csb",
    RankLogo = "Activity/CoinPusher_Egypt/csd/Rank_Egypt/CoinPusherItem.csb", -- 排行榜LOGO
    RankMainLayer = "Activity/CoinPusher_Egypt/csd/Rank_Egypt/CoinPusher_Rank.csb", -- 排行榜主界面
    RankTitle = "Activity/CoinPusher_Egypt/csd/Rank_Egypt/CoinPusherTitle.csb", -- 排行榜标题
    RankInfo = "Activity/CoinPusher_Egypt/csd/Rank_Egypt/CoinPusher_help.csb", -- 排行榜说明
    RankTime = "Activity/CoinPusher_Egypt/csd/Rank_Egypt/CoinPusherTime.csb", -- 排行榜时间
    RankCell1 = "Activity/CoinPusher_Egypt/csd/Rank_Egypt/CoinPusher_item1.csb", -- 排行榜 玩家cell
    RankCell2 = "Activity/CoinPusher_Egypt/csd/Rank_Egypt/CoinPusher_item2.csb", -- 排行榜 奖励cell
    RankTop = "Activity/CoinPusher_Egypt/csd/Rank_Egypt/CoinPusher_Top%d.csb", -- 排行榜 前三名cell
    GiftNode = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_EntryCollect.csb",
    GiftBubbleNode = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_EntryCollect_Bubble.csb",
    FlyParticle = "Activity/CoinPusher_Egypt/csd/CoinPusher_tuowei.csb",
}

-- 排行榜前三名
EgyptCoinPusherConfig.rankPng = {
    Bg_1 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_rank_itembg1.png",
    Bg_2 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_rank_itembg2.png",
    Bg_3 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_rank_itembg3.png",
    Rank_1 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_itemRank1.png",
    Rank_2 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_itemRank2.png",
    Rank_3 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_itemRank3.png",
    reward_1 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_rank_1.png",
    reward_2 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_rank_2.png",
    reward_3 = "Activity/CoinPusher_Egypt/ui/ui_rank/CoinPusher_rank_3.png"
}

--combo 图片路径
EgyptCoinPusherConfig.ComboEffectPng = {
    "Activity/CoinPusher_Egypt/coinpusher/CoinPusherCoinAttack1.png",
    "Activity/CoinPusher_Egypt/coinpusher/CoinPusherCoinAttack2.png",
    "Activity/CoinPusher_Egypt/coinpusher/CoinPusherCoinAttack3.png",
    "Activity/CoinPusher_Egypt/coinpusher/CoinPusherCoinAttack4.png",
    "Activity/CoinPusher_Egypt/coinpusher/CoinPusherCoinAttack5.png",
    "Activity/CoinPusher_Egypt/coinpusher/CoinPusherCoinAttack6.png"
}
EgyptCoinPusherConfig.ComboFreshDt = 3

--弹窗csb
EgyptCoinPusherConfig.PopCsbPath = {
    Stage = {
        Type = "Stage",
        Path = "Activity/CoinPusher_Egypt/csd/Reward_Egypt/CoinPusher_Reward_Cell.csb"
    },
    Coin = {
        Type = "Coin",
        Path = "Activity/CoinPusher_Egypt/csd/Reward_Egypt/CoinPusher_Reward_Cell.csb"
    },
    Card = {
        Type = "Card",
        Path = "Activity/CoinPusher_Egypt/csd/Reward_Egypt/CoinPusher_Reward_Cell.csb"
    },
    Level = {
        Type = "Level",
        Path = "Activity/CoinPusher_Egypt/csd/Reward_Egypt/CoinPusher_Reward_Level.csb"
    },
    Round = {
        Type = "Round",
        Path = "Activity/CoinPusher_Egypt/csd/Reward_Egypt/CoinPusher_Reward_Final.csb"
    },
    Collect = {
        Type = "Collect",
        Path = "Activity/CoinPusher_Egypt/csd/Reward_Egypt/CoinPusher_Reward_Cell.csb"
    }
}

--mainUI zorder
EgyptCoinPusherConfig.MainUIZorder = {
    WinLight = 100,
    Combo = 100,
    CardLayer = 200,
    ViewLayer = 300
}

---BUFF
EgyptCoinPusherConfig.BuffResPath = {
    GAME = "Activity/CoinPusher_Egypt/csd/Promotion_Egypt/CoinPusher_Powerup.csb",
    ENTRY = "Activity/CoinPusher_Egypt/csd/Promotion_Egypt/CoinPusher_PowerupEntry.csb"
}
--buff 监听倒计时  times/BuffUpdateTime
EgyptCoinPusherConfig.BuffUpdateTime = 1.0
EgyptCoinPusherConfig.TapUpdateTime = 10.0

EgyptCoinPusherConfig.PusherDisVec3 = {
    ORI = cc.vec3(0.0, 15, -21.5),
    DEST = cc.vec3(0.0, 15, -19),
    DEST_L = cc.vec3(0.0, 15, -12.5)
}

-- lifterStatus
EgyptCoinPusherConfig.UICsbPath.StageCsb = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_jiacheng.csb"

----声音
EgyptCoinPusherConfig.SoundConfig = {
    WALL_UP = "Activity/CoinPusher_Egypt/Sound/CoinPusherWallUp.mp3",
    HAMMER_DOWN = "Activity/CoinPusher_Egypt/Sound/CoinPusherHammer.mp3",
    SEPCIAL_COIN_DOWN = "Activity/CoinPusher_Egypt/Sound/CoinPusherSpecialCoinDown.mp3",
    BGM = "Activity/CoinPusher_Egypt/Sound/CoinPusherBGM.mp3",
    BIG_COIN_DOWN = "Activity/CoinPusher_Egypt/Sound/CoinPusherBigCoinDown.mp3",
    COIN_PUSH_DOWN = "Activity/CoinPusher_Egypt/Sound/CoinPusherCoinDown.mp3",
    SPECIAL_PUSH_DOWN = "Activity/CoinPusher_Egypt/Sound/CoinPusherSpecialCoinPush.mp3",
    LEVELPASS = "Activity/CoinPusher_Egypt/Sound/CoinPusherLevelPass.mp3",
    ROUNDPASS = "Activity/CoinPusher_Egypt/Sound/CoinPusherRoundPass.mp3",
    REWARD = "Activity/CoinPusher_Egypt/Sound/CoinPusherReward.mp3",
    COMBO = "Activity/CoinPusher_Egypt/Sound/CoinPusherCombo.mp3",
    NORMALCOINDOWN = "Activity/CoinPusher_Egypt/Sound/CoinPusherNormalCoinDown.mp3",
    PASSEFFECT = "Activity/CoinPusher_Egypt/Sound/CoinPusherPassEffect.mp3",
    SELECT_COMPLETE = "Activity/CoinPusher_Egypt/Sound/complete.mp3",
    SELECT_UNLOCK = "Activity/CoinPusher_Egypt/Sound/unlock.mp3",
    DROP_COINS= "Activity/CoinPusher_Egypt/Sound/drop_Coin.mp3",
    SLOTS = "Activity/CoinPusher_Egypt/Sound/slots_Start.mp3", -- SLOTS开始转动
    SLOTS_END = "Activity/CoinPusher_Egypt/Sound/slots_Over.mp3", -- Slost单个滚轴停止转动
    SLOTS_CRASH = "Activity/CoinPusher_Egypt/Sound/crash.mp3", -- 硬币碰撞到蓝色小柱子上
    SLOTS_ENTER = "Activity/CoinPusher_Egypt/Sound/Enter.mp3", -- 硬币进入金币口，播放紫色光效
    SLOTS_WIN = "Activity/CoinPusher_Egypt/Sound/slots_Win.mp3", -- Slots连成线不断闪烁
    SLOTS_COINS = "Activity/CoinPusher_Egypt/Sound/slots_Coins.mp3", -- 出币口播放光效

    SLOTS_COINSSHOWER = "Activity/CoinPusher_Egypt/Sound/Coinshower.mp3", -- 
    SLOTS_HUGECOINS = "Activity/CoinPusher_Egypt/Sound/Shakethemup.mp3", --
    SLOTS_SHAKE = "Activity/CoinPusher_Egypt/Sound/Slot_Pusher1.mp3", --
    SLOTS_LONGPUSHE = "Activity/CoinPusher_Egypt/Sound/Slot_Pusher2.mp3",
    SLOTS_RESULT = "Activity/CoinPusher_Egypt/Sound/Slot_Result.mp3",
}

EgyptCoinPusherConfig.RES = {
    EgyptCoinPusherFlyEffect_Coins_Icon = "Activity/CoinPusher_Egypt/other/CoinPusherCoin.png",
    EgyptCoinPusherCardLayer_sp_rIcon = "Activity/CoinPusher_Egypt/other/CoinPusher%s.png",
    EgyptCoinPusherDesktopDebug_CSB = "Activity/CoinPusher_Egypt/csd/DesktopDebug.csb",
    EgyptCoinPusherEffect_SprayEffectL = "Activity/CoinPusher_Egypt/csd/CoinPusher_zyliziLeft.csb",
    EgyptCoinPusherEffect_SprayEffectR = "Activity/CoinPusher_Egypt/csd/CoinPusher_zyliziRight.csb",
    EgyptCoinPusherEffect_LightBeamL = "Activity/CoinPusher_Egypt/CoinPusher_FSdeng.csb",
    EgyptCoinPusherEffect_LightBeamR = "Activity/CoinPusher_Egypt/CoinPusher_FSdeng_0.csb",
    EgyptCoinPusherEffect_LightDrop = "Activity/CoinPusher_Egypt/CoinPusher_DG.csb",
    EgyptCoinPusherEffect_winDropEffect = "Activity/CoinPusher_Egypt/csd/CoinPusher_XFlizi.csb",
    EgyptCoinPusherEffect_BonusSlotEffect = "Activity/CoinPusher_Egypt/CoinPusher_SlotTile.csb",
    EgyptCoinPusherEffect_EffectLine = "Activity/CoinPusher_Egypt/csd/CoinPusher_tubiao_lizi.csb",
    EgyptCoinPusherGamePromtView_CSB = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_Rule.csb",
    EgyptCoinPusherGuideView_SPINE_Finger = "Activity/CoinPusher_Egypt/coinpusher/DailyBonusGuide",
    EgyptCoinPusherLoading_CSB = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_GameLoading.csb",
    EgyptCoinPusherMainUI_combolAnima = "Activity/CoinPusher_Egypt/csd/CoinPusher_tanzi.csb",
    EgyptCoinPusherMainUI_winDropEffect1 = "Activity/CoinPusher_Egypt/csd/CoinPusher_XFlizi1.csb",
    EgyptCoinPusherMainUI_passEffect = "Activity/CoinPusher_Egypt/csd/tip.csb",
    EgyptCoinPusherSelectItemUI_SpCellTitle = "Activity/CoinPusher_Egypt/other/Timer_choose_%s.png",
    EgyptCoinPusherSelectItemUI_SpCellTitlePortrait = "Activity/CoinPusher_Egypt/other/Timer_choose_%s_Portralt.png",
    EgyptCoinPusherMainUI_BombDebris = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_suixie.csb",
    EgyptCoinPusherMainUI_FruitWin = "Activity/CoinPusher_Egypt/csd/Main_Egypt/CoinPusher_tips.csb",
    --------------------------- 任务 -----------------------
    EgyptCoinPusherTaskMainLayer_Main_CSB = "Activity_EgyptCoinPusherTask/Activity/csb/CoinPusherMission_mainLayer.csb",
    EgyptCoinPusherTaskMainLayer_Title_CSB = "Activity_EgyptCoinPusherTask/Activity/csb/CoinPusherMission_title.csb",
    EgyptCoinPusherTaskMainLayer_Bubble_CSB = "Activity_EgyptCoinPusherTask/Activity/csb/CoinPusherMission_qipao.csb",
    EgyptCoinPusherTaskMainLayer_Reward_CSB = "Activity_EgyptCoinPusherTask/Activity/csb/CoinPusherMission_rewardLayer.csb",
    --------------------------- 任务 -----------------------
    --------------------------- 促销 -----------------------
    EgyptCoinPusherSaleMgr_NoPusherBuyView = "Activity/CoinPusher_Egypt/csd/Promotion_Egypt/CoinPusher_NoPusherBuyView.csb",
    EgyptCoinPusherSaleMgr_NoPusherBuyView_Cell = "Activity/CoinPusher_Egypt/csd/Promotion_Egypt/CoinPusher_NoPusherBuyView_Cell.csb",
    EgyptCoinPusherSaleMgr_NoPusherBuyView_PACK_Cell = "Activity/CoinPusher_Egypt/csd/Promotion_Egypt/CoinPusher_NoPusherBuyView_SaleCell.csb"
    --------------------------- 促销 -----------------------
}

EgyptCoinPusherConfig.getThemeName = function()
    return "Activity_EgyptCoinPusher"
end

return EgyptCoinPusherConfig
