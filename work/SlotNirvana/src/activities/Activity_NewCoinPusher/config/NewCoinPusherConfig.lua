--[[
    CoinPusher Config
    tm
]]
local NewCoinPusherConfig  = {}

-- 调试状态 
NewCoinPusherConfig.Debug = false                   --debug界面
NewCoinPusherConfig.DebugCoinCount = true          --debug界面
NewCoinPusherConfig.FixCarmer = false               --固定视角     
NewCoinPusherConfig.ConfigInitDisk = true          --配置初始化盘面        

--推币机版本
NewCoinPusherConfig.Version = "V1"
--------------------------------推币机参数 START-------------------------------------
-- 推币机速度
NewCoinPusherConfig.PusherSpeed = 4                        
NewCoinPusherConfig.Gravity = -30 

NewCoinPusherConfig.PointerSpeed = 70  --指针旋转角度 速度
NewCoinPusherConfig.PointerRotMax_Z =  90 --指针旋转最大角度 

NewCoinPusherConfig.BasketSpeed = 3  --篮筐移动 速度
NewCoinPusherConfig.BasketPosMax_X =  1.5 --篮筐左右移动 最大距离 远离中心

--质量系数(金币)
NewCoinPusherConfig.RatioMass = 1000000

--摩擦力系数
NewCoinPusherConfig.RatioFrichtion = 2                            --金币
NewCoinPusherConfig.PlatformFrichtion = 1                         --地板中间部分
NewCoinPusherConfig.BorderPlatformFrichtion = 10                  --地板两侧
NewCoinPusherConfig.FrontFriction = 0.15                          --地板前部
NewCoinPusherConfig.BackFriction = 0.1                            --地板后部
NewCoinPusherConfig.MiddleFriction = 1                            --地板中部

--金币 mask标记起始 常量数值
NewCoinPusherConfig.IconMaskBegin = 100000                            --地板中部
NewCoinPusherConfig.WinFloorMask = 100                           --地板成功
NewCoinPusherConfig.LoseFloorMask = 1000                           --地板失败

--------------------------------推币机参数 END-------------------------------------   
-----------------------  

--掉落实体类型
NewCoinPusherConfig.EntityType   = {       
        COIN = 1,
        ITEM = 2,
}

--掉落实体类型
NewCoinPusherConfig.EntityDropType   = {
        WIN  = 1,
        LOSE = 2,
}

--触发动画类型
NewCoinPusherConfig.CoinEffectRefer   = {
        NORMAL = "NORMAL",
        COINS =  "COINS",
        STAGE_COINS = "STAGE_COINS",
        SLOTS = "SLOTS",
        CARD = "CARD",
        BIG = "BIG_COINS",
        DROP = "DROP",         --点击掉落金币
        EASTER = "EASTER",  -- 复活节蛋  新加
        FRUITMACHINE = "FRUITMACHINE" --水果机
}

NewCoinPusherConfig.SlotEffectRefer   = {
        SLOT = "SLOT",         --水果机滚动
        JACKPOT = "NUM",      --触发jp 奖励coins
        BIGCOIN = "BIG_COINS",   --掉落打金币
        HAMMER = "HAMMER",      --锤子
        STAGE_COIN = "STAGE_COIN",      --加成道具
        CAR = "CAR",      --矿车
}

--掉落实体类型
NewCoinPusherConfig.CoinModelRefer   = {
        "NORMAL",
        "COINS",
        "STAGE_COINS",
        "CARD",
        "BIG_COINS",
        "EASTER",
}

NewCoinPusherConfig.CoinPreCreateConfig = {
        NORMAL = 10,
        COINS = 10,
        STAGE_COINS = 10,
        SLOTS = 10,
        CARD = 10,
        BIG = 5,
}


-- 各种金币相关属性 --
NewCoinPusherConfig.CoinModelAtt   = {
        --基础金币
    ["NORMAL"] = { Name    = "NORMAL" , 
            Mass    = 150.0 * NewCoinPusherConfig.RatioMass ,
            Friction= 0.3 * NewCoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/CoinPusher_New/models/coin/jinbi_g2.c3b" , --jinbi 
            Texture = "Activity/CoinPusher_New/models/coin/normalCoin.png" ,
            Scale   = 10 , 
            palne   = 12,
            PhysicSize = cc.p(0.8,0.18) },
    ["COINS"] = { Name    = "COINS" , 
            Mass    = 150.0 * NewCoinPusherConfig.RatioMass,
            Friction= 0.3 * NewCoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/CoinPusher_New/models/coin/jinbi_g2.c3b" , 
            Texture = "Activity/CoinPusher_New/models/coin/Coins.png" ,
            Scale   = 10 , 
            palne   = 6,
            PhysicSize = cc.p(0.8,0.18) },
    ["STAGE_COINS"] = { Name    = "STAGE_COINS" , 
            Mass    = 150.0 * NewCoinPusherConfig.RatioMass,
            Friction= 0.3 * NewCoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/CoinPusher_New/models/coin/jinbi_g2.c3b" , 
            Texture = "Activity/CoinPusher_New/models/coin/StageCoins.png" ,    
            Scale   = 10 , 
            palne   = 6,
            PhysicSize = cc.p(0.8,0.18) },
    ["CARD"] = { Name    = "CARD" , 
            Mass    = 150.0 * NewCoinPusherConfig.RatioMass ,
            Friction= 0.3 * NewCoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/CoinPusher_New/models/coin/jinbi_g2.c3b" , --jinbi 
            Texture = "Activity/CoinPusher_New/models/coin/Material__42_Base_color.png" ,
            Scale   = 10 , 
            palne   = 12,
            PhysicSize = cc.p(0.8,0.18) },
    ["BIG_COINS"] = { Name    = "BIG_COINS" , 
            Mass    = 150.0 * NewCoinPusherConfig.RatioMass,
            Friction= 0.3 * NewCoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/CoinPusher_New/models/coin/djb_s.c3b" ,     
            Texture = "Activity/CoinPusher_New/models/coin/jinbi_ts_Base_color.png" ,
            Scale   = 20 , 
            palne   = 12,
            PhysicSize = cc.p(1.1,0.18) },
    [7] = { Name    = "CoinChipStack4" , 
            Mass    = 400.0 ,
            Friction= 0.3 , 
            Model   = "Activity/CoinPusher_New/coinpusher/CoinChipStack4.c3b" , 
            Texture = "Activity/CoinPusher_New/coinpusher/CoinChipStack4.png" ,
            Scale   = 2 , 
            PhysicSize = cc.p(0.8,0.18) },
}

-- 各种道具属性 --
NewCoinPusherConfig.ItemModelAtt  = {
    [1] = { Name    = "PrizeElephantBlue" , 
            Mass    = 1000.0 ,
            Friction= 0. , 
            Model   = "Activity/CoinPusher_New/coinpusher/PrizeElephantBlue.c3b" , 
            Texture = "Activity/CoinPusher_New/coinpusher/PrizeElephantBlue.png" ,
            Scale   = 10 , 
            PhysicSize = {  type    = "box" , 
                            size    = cc.vec3(4.0, 4.0, 6) , 
                            off     = cc.vec3(0.0, -1 , -0.5) , 
                            angle   =  cc.vec3(-90.0, 180.0,  0.0)} 
            },
    [2] = { Name    = "PrizeHeartGemPurple" , 
            Mass    = 1000.0 ,
            Friction= 0.6 , 
            Model   = "Activity/CoinPusher_New/coinpusher/PrizeHeartGemPurple.c3b" , 
            Texture = "Activity/CoinPusher_New/coinpusher/PrizeHeartGemPurple.png" ,
            Scale   = 10 , 
            PhysicSize = {  type    = "box" , 
                            size    = cc.vec3(4.5, 4.5, 1.8) , 
                            off     = cc.vec3(0.0, 0 , 0) , 
                            angle   =  cc.vec3(-90.0, 180.0,  0.0)} 
            },
    [3] = { Name    = "PrizeJetWhite" , 
            Mass    = 1000.0 ,
            Friction= 0.6 , 
            Model   = "Activity/CoinPusher_New/coinpusher/PrizeJetWhite.c3b" , 
            Texture = "Activity/CoinPusher_New/coinpusher/PrizeJetWhite.png" ,
            Scale   = 10 , 
            PhysicSize = {  type = "box" , 
                            size = cc.vec3(5, 3, 5) , 
                            off = cc.vec3(0.0, 0 , 0) , 
                            angle =  cc.vec3(-0.0, 180.0,  0.0)} 
            },
    [4] = { Name    = "PrizeTiaraPurple" , 
            Mass    = 1000.0 ,
            Friction= 0.6 , 
            Model   = "Activity/CoinPusher_New/coinpusher/PrizeTiaraPurple.c3b" , 
            Texture = "Activity/CoinPusher_New/coinpusher/PrizeTiaraPurple.png" ,
            Scale   = 10 , 
            PhysicSize = {  type = "cylinder" , 
                            size = cc.p(4,3) , 
                            off = cc.vec3(0.0, -0.2 , 0) , 
                            angle =  cc.vec3(-0.0, 180.0,  0.0)} 
            },
    [5] = { Name    = "PrizeWatchWhite" , 
            Mass    = 1000.0 ,
            Friction= 0.6 , 
            Model   = "Activity/CoinPusher_New/coinpusher/PrizeWatchWhite.c3b" , 
            Texture = "Activity/CoinPusher_New/coinpusher/PrizeWatchWhite.png" ,
            Scale   = 10 ,
            PhysicSize = { type = "cylinder" , 
                            size = cc.p(4.5,2.8) , 
                            off = cc.vec3(0.0, -0.0 , 0) ,
                            angle =  cc.vec3(-0.0, 180.0,  0.0)} 
            },
}

-- 静态场景属性 --
NewCoinPusherConfig.PlatformModelAtt = {
    Platform    = { Mass    = 0.0 ,  
                    Model   = "Activity/CoinPusher_Egypt/models/zhuti/zhuti.c3b", 
                    Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png" ,
                    Friction= 0.3 * NewCoinPusherConfig.PlatformFrichtion,
                    BorderFriction = 0.3 * NewCoinPusherConfig.BorderPlatformFrichtion,
                    FrontFriction = 0.3 * NewCoinPusherConfig.FrontFriction,
                    BackFriction = 0.3 * NewCoinPusherConfig.BackFriction,
                    MiddleFriction = 0.3 * NewCoinPusherConfig.MiddleFriction,
                    Scale   = 2.5 },
    Jackpot     = { Mass    = 0.0 ,  
                    Model   = "Activity/CoinPusher_Egypt/coinpusher/beijingui.c3b"  , 
                    Texture = "Activity/CoinPusher_Egypt/coinpusher/MachineJackpot.png" ,
                    Scale   = 10 },
    Background  = { Mass    = 0.0 ,  
                    Model   = "Activity/CoinPusher_Egypt/models/beijinqiang.c3b"    , 
                    Texture = "Activity/CoinPusher_Egypt/models/22 - Default_2D_View.png" ,
                    Scale   = 10 },
    Pusher      = { Mass    = 0.0 ,  
                    Model   = "Activity/CoinPusher_Egypt/models/tuiban/tuibi.c3b", 
                    Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png" ,
                    Scale   = 2.5 },
--     Lifter      = { Mass    = 0.0 ,  
--                     Model   = "Activity/CoinPusher_Egypt/models/zhuzi/xiaozhuzi.c3b"     , 
--                     Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png",
--                     Scale   = 10 },
    ReelUnit    = { Mass    = 0.0 ,  
                    Model   = "Activity/CoinPusher_Egypt/coinpusher/reelunit.c3b"   , 
                    Texture = "" ,
                    Scale   = 10 },

    Nail       = { Mass    = 0.0 ,   --钉子
                    Model   = "Activity/CoinPusher_Egypt/models/zhuzi/xiaozhuzi.c3b"   , 
                    Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png" ,
                    Scale   = 2.5 },
        SlotBasket      = {     Mass    = 0.0 ,   --篮筐小
                        Model   = "Activity/CoinPusher_Egypt/models/basket/tubikou.c3b" , 
                        Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png" ,
                        Scale   = 2.5 },
        SlotBasket_Big  = {     Mass    = 0.0 ,  --篮筐大
                                Model   = "Activity/CoinPusher_Egypt/models/basket/gunlun.c3b" , 
                                Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png" ,
                                Scale   = 2.5 },
        pointer  = {     Mass    = 0.0 ,   --摆动指针
                Model   = "Activity/CoinPusher_Egypt/models/zhuzi/xiaozhuzi.c3b" , 
                Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png" ,
                Scale   = 2.5 },

        slot  = {     Mass    = 0.0 ,   --摆动指针
                Model   = "Activity/CoinPusher_Egypt/models/basket/gunlun.c3b" , 
                Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png" ,
                Scale   = 2.5 },
        bug  = {     Mass    = 0.0 ,   --摆动指针
                Model   = "Activity/CoinPusher_Egypt/models/bug/chong.c3b" , 
                Texture = "Activity/CoinPusher_Egypt/models/dimop_2D_View.png" ,
                Scale   = 2.5 },



}

-- Slot轮盘相关 --
NewCoinPusherConfig.ReelRollSpeed  = -40
NewCoinPusherConfig.ReelJumpUpTime  = 0.3
NewCoinPusherConfig.ReelTopPos     = 7.2
NewCoinPusherConfig.ReelBottomPos  = -7.2
NewCoinPusherConfig.ReelStopPos    = 0
NewCoinPusherConfig.ReelTableCenter= cc.vec3( 0 , 10 , 43.7 )
NewCoinPusherConfig.ReelUnitCenter = { 
    cc.vec3(-7.2 , 0, 0 ) ,
    cc.vec3(   0 , 0, 0 ) ,
    cc.vec3( 7.2 , 0, 0 ) ,
}
NewCoinPusherConfig.ReelUnitConfig = {
    {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0,  7.2 , 0 ) },
    {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0 , 7.2 , 0 ) },
    {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0 , 7.2 , 0 ) },
}

NewCoinPusherConfig.ReelJumpConfig = {
        { DelayTime = 0,   DestPosY = 2},
        { DelayTime = 0.1, DestPosY = 2},
        { DelayTime = 0.2, DestPosY = 2},
}

-- 假滚数据 --
NewCoinPusherConfig.ReelDataConfig = {
    { 1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5},
    { 1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5},
    { 1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5},
}
-- 滚动停止间隔 --
NewCoinPusherConfig.ReelStopOffset = { 9,13,19 }
NewCoinPusherConfig.ReelDataNums   = { 
    table.nums(NewCoinPusherConfig.ReelDataConfig[1] ) , 
    table.nums(NewCoinPusherConfig.ReelDataConfig[2] ) ,
    table.nums(NewCoinPusherConfig.ReelDataConfig[3] ) 
}
NewCoinPusherConfig.ReelStatus = {
    Idle    = 0,
    JumpUp  = 1,
    Running = 2,
    JumpDown= 3,
    Stoping = 4
}

NewCoinPusherConfig.SlotType = {
        ["FREESPIN"] = 1,
        ["COINS"] = 2,
        ["HUMMER"] = 3,
    }
--老虎机滚动个数 
NewCoinPusherConfig.SlotRunCount = {14, 18, 22}

-- 事件声明 --
NewCoinPusherConfig.Event = {
    NewCoinPusherGetDropCoinsReward = "NewCoinPusherGetDropCoinsReward",
    NewCoinPusherDropCoins = "NewCoinPusherDropCoins",
    NewCoinPuserTriggerEffect = "NewCoinPuserTriggerEffect",
    NewCoinPuserEffectEnd = "NewCoinPuserEffectEnd",
    NewCoinPuserGuideFinished = "NewCoinPuserGuideFinished",
    NewCoinPuserSaveEntity = "NewCoinPuserSaveEntity",
    NewCoinPuserUpdateMainUI = "NewCoinPuserUpdateMainUI",
    NewCoinPuserStageLayer = "NewCoinPuserStageLayer",
    NewCoinPuserRoundLayer = "NewCoinPuserRoundLayer",

    --章节加成奖励
    NewCoinPuserStageBuffOpen = "NewCoinPuserStageBuffOpen",
    NewCoinPuserStageBuffClose = "NewCoinPuserStageBuffClose",

    --推币机PASS 事件
    NewCoinPuserPassGetReward = "NewCoinPuserPassGetReward",
    NewCoinPuserPassUiBarFinish = "NewCoinPuserPassUiBarFinish",
    NewCoinPuserPassGuideFinish = "NewCoinPuserPassGuideFinish",
    NewCoinPuserPassGuideTwo = "NewCoinPuserPassGuideTwo",
    NewCoinPuserPassAllUnlock = "NewCoinPuserPassAllUnlock",

    --水果机
    NewCoinPuserRequestFruitMachineFinish = "NewCoinPuserRequestFruitMachineFinish"
}

-- 特效属性 --
NewCoinPusherConfig.Effect = {
        Hammer          = {
                ID      = 1,
                Type    = "Model",   
                Model   = "Activity/CoinPusher_New/models/effect/hammer.c3b" , 
                Texture = "Activity/CoinPusher_New/models/effect/chuizi.png",
                Scale   = 2,
                ModelGuang = "Activity/CoinPusher_New/models/effect/hammerguang.c3b",
                ModelBaozha= "Activity/CoinPusher_New/models/effect/hammerbaozha.c3b" },
        FlashLight      = { 
                ID      = 2,
                Type    = "Model",  
                Model   = "Activity/CoinPusher_New/coinpusher/flashlight.c3b" , 
                Texture = "Activity/CoinPusher_New/coinpusher/pian_tt.png",
                Scale   = 10 },
        FrontEffectPanel= { 
                ID      = 4,
                Type    = "Model", 
                Model   = "Activity/CoinPusher_New/coinpusher/frontEffectPanel.c3b", 
                Texture = "Activity/CoinPusher_New/coinpusher/dengA.png" ,
                Scale   = 10 },
        TapHere= { 
                ID      = 5,
                Type    = "Model", 
                Model   = "Activity/CoinPusher_New/models/effect/taphere.c3b", 
                Texture = "Activity/CoinPusher_New/models/effect/tap_here.png" ,
                Scale   = 10 },
    
}

-- 台前 序列帧特效 --
NewCoinPusherConfig.FrontEffectPic = {
        Idle    = {
                "Activity/CoinPusher_New/coinpusher/dengA_01.png",
                "Activity/CoinPusher_New/coinpusher/dengA_02.png",
                "Activity/CoinPusher_New/coinpusher/dengA_03.png",
                "Activity/CoinPusher_New/coinpusher/dengA_04.png",
                "Activity/CoinPusher_New/coinpusher/dengA_05.png",
                "Activity/CoinPusher_New/coinpusher/dengA_04.png",
                "Activity/CoinPusher_New/coinpusher/dengA_03.png",
                "Activity/CoinPusher_New/coinpusher/dengA_02.png",
                "Activity/CoinPusher_New/coinpusher/dengA_01.png"
        },
        IdleInterval = 0.5,
        Flash   = {
                "Activity/CoinPusher_New/coinpusher/dengB_01.png",
                "Activity/CoinPusher_New/coinpusher/dengB_02.png",
                "Activity/CoinPusher_New/coinpusher/dengB_03.png",
                "Activity/CoinPusher_New/coinpusher/dengB_04.png",
                "Activity/CoinPusher_New/coinpusher/dengB_05.png",
                "Activity/CoinPusher_New/coinpusher/dengB_06.png",
                "Activity/CoinPusher_New/coinpusher/dengB_05.png",
                "Activity/CoinPusher_New/coinpusher/dengB_04.png",
                "Activity/CoinPusher_New/coinpusher/dengB_03.png",
                "Activity/CoinPusher_New/coinpusher/dengB_02.png",
        },
        FlashInterval = 0.1
}


-- jackpot 序列帧特效 --
NewCoinPusherConfig.JackPotEffectPic = {
        Idle    = {
                "Activity/CoinPusher_New/coinpusher/dengB1.png",
                "Activity/CoinPusher_New/coinpusher/dengB2.png",
                "Activity/CoinPusher_New/coinpusher/dengB3.png",
                "Activity/CoinPusher_New/coinpusher/dengB2.png",
                "Activity/CoinPusher_New/coinpusher/dengB1.png"
        },
        IdleInterval = 0.5,
        Flash   = {
                "Activity/CoinPusher_New/coinpusher/dengB1.png",
                "Activity/CoinPusher_New/coinpusher/dengB2.png",
                "Activity/CoinPusher_New/coinpusher/dengB3.png",
                "Activity/CoinPusher_New/coinpusher/dengB2.png",
                "Activity/CoinPusher_New/coinpusher/dengB1.png"
        },
        FlashInterval = 0.1
}

NewCoinPusherConfig.jackpotPosOri    = cc.vec3(0.0, 0.0, 0 )
NewCoinPusherConfig.jackpotPosDest   = cc.vec3(0.0, 6.5, 0 )

NewCoinPusherConfig.jackpotEffectPos =   cc.vec3( 0 , -1.5,  0.0)
NewCoinPusherConfig.BlackFNT = "Activity/CoinPusher_New/models/effect/font_arialblack.fnt"

-- 调试面板按钮图片 --
NewCoinPusherConfig.debugBtnRes = "Activity/CoinPusher_New/coinpusher/btn.png"


--玩法状态
NewCoinPusherConfig.PlayState   = {
        IDLE    = 1,    --未开始
        PLAYING = 2,    --播放状态
        DONE    = 3,    --结束
}

--烟花特效配置
NewCoinPusherConfig.FireWorksCsb = {
        "Activity/CoinPusher_New/CoinPusher_YanHa_huang.csb",
        "Activity/CoinPusher_New/CoinPusher_YanHa_lan.csb",
        "Activity/CoinPusher_New/CoinPusher_YanHa_zi.csb",
}

--光圈特效配置
NewCoinPusherConfig.LightRingCsb = {
        "Activity/CoinPusher_New/CoinPusher_Dhuangg.csb",
        "Activity/CoinPusher_New/CoinPusher_Dlanguang.csb",
}

--章节状态
NewCoinPusherConfig.PlanesState = {
        COMPLETED = "COMPLETED",
        PLAY  = "PLAY",
        LOCKD =  "LOCKD",
}

--CSB
NewCoinPusherConfig.UICsbPath = {
        MainUI = "Activity/CoinPusher_New/csd/main/CoinPusher_MainLayer.csb",
        MainUITitle = "Activity/CoinPusher_New/csd/main/CoinPusher_MainLayerTitle.csb", 
        SelectUI = "Activity/CoinPusher_New/csd/chapter/CoinPusher_Chapter.csb",
        SelectUIPortrait = "Activity/CoinPusher_New/csd/chapter/CoinPusher_Chapter_Portralt.csb",
        SelectUIItem  = "Activity/CoinPusher_New/csd/chapter/CoinPusher_Chapter_Item1.csb",
        SelectUIItemPortrait  = "Activity/CoinPusher_New/csd/chapter/CoinPusher_Chapter_Item1_Portralt.csb",
        EntryNode = "Activity/CoinPusher_New/csd/slots/CoinPusher_GameSceneUI.csb",
        NewGuide = "Activity/CoinPusher_New/csd/guide/CoinPusher_guide.csb",
        CoinUI = "Activity/CoinPusher_New/csd/main/CoinPusher_Coin.csb",
        FruitCell = "Activity/CoinPusher_New/csd/main/CoinPusher_MainLayer_gezi.csb",
        FruitCellLight = "Activity/CoinPusher_New/csd/main/CoinPusher_MainLayer_light.csb",
        Bomb = "Activity/CoinPusher_New/csd/main/CoinPusher_MainLayer_bomb.csb",

        RankLogo      = "Activity/CoinPusher_New/csd/rank/CoinPusherItem.csb",    -- 排行榜LOGO
        RankMainLayer = "Activity/CoinPusher_New/csd/rank/CoinPusher_Rank.csb",   -- 排行榜主界面
        RankTitle     = "Activity/CoinPusher_New/csd/rank/CoinPusherTitle.csb",   -- 排行榜标题
        RankInfo      = "Activity/CoinPusher_New/csd/rank/CoinPusher_help.csb",   -- 排行榜说明
        RankCell0     = "Activity/CoinPusher_New/csd/rank/CoinPusher_item0.csb",  -- 
        RankCell1     = "Activity/CoinPusher_New/csd/rank/CoinPusher_item1.csb",  -- 
        RankCell2     = "Activity/CoinPusher_New/csd/rank/CoinPusher_item2.csb",  -- 
}

-- 排行榜前三名
NewCoinPusherConfig.rankPng = {
        Bg_1 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_rank_itembg1.png",
        Bg_2 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_rank_itembg2.png",
        Bg_3 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_rank_itembg3.png",
        Rank_1 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_itemRank1.png",
        Rank_2 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_itemRank2.png",
        Rank_3 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_itemRank3.png",
        reward_1 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_rank_1.png",
        reward_2 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_rank_2.png",
        reward_3 = "Activity/CoinPusher_New/ui/ui_rank/CoinPusher_rank_3.png",
}

--combo 图片路径
NewCoinPusherConfig.ComboEffectPng = {
        "Activity/CoinPusher_New/coinpusher/CoinPusherCoinAttack1.png",
        "Activity/CoinPusher_New/coinpusher/CoinPusherCoinAttack2.png", 
        "Activity/CoinPusher_New/coinpusher/CoinPusherCoinAttack3.png",
        "Activity/CoinPusher_New/coinpusher/CoinPusherCoinAttack4.png",
        "Activity/CoinPusher_New/coinpusher/CoinPusherCoinAttack5.png",
        "Activity/CoinPusher_New/coinpusher/CoinPusherCoinAttack6.png"
}
NewCoinPusherConfig.ComboFreshDt = 3

--弹窗csb
NewCoinPusherConfig.PopCsbPath = {
        Stage = {
                Type = "Stage",
                Path = "Activity/CoinPusher_New/csd/rewards/CoinPusher_Reward_Cell.csb",
        } ,
        Coin = {
                Type = "Coin",
                Path = "Activity/CoinPusher_New/csd/rewards/CoinPusher_Reward_Cell.csb",
        } ,
        Card =  {
                Type = "Card",
                Path = "Activity/CoinPusher_New/csd/rewards/CoinPusher_Reward_Cell.csb",
        },
        Level = {
                Type = "Level",
                Path = "Activity/CoinPusher_New/csd/rewards/CoinPusher_Reward_Level.csb",

        },
        Round = {
                Type = "Round",
                Path = "Activity/CoinPusher_New/csd/rewards/CoinPusher_Reward_Final.csb",
        },
}

--mainUI zorder
NewCoinPusherConfig.MainUIZorder = {
        WinLight = 100,
        Combo = 100,
        CardLayer = 200,
        ViewLayer = 300,
}

---BUFF
NewCoinPusherConfig.BuffResPath = 
{
        GAME =  "Activity/CoinPusher_New/csd/main/CoinPusher_Powerup.csb",
        ENTRY = "Activity/CoinPusher_New/csd/main/CoinPusher_PowerupEntry.csb"
}
--buff 监听倒计时  times/BuffUpdateTime
NewCoinPusherConfig.BuffUpdateTime = 1.0
NewCoinPusherConfig.TapUpdateTime = 10.0

NewCoinPusherConfig.PusherDisVec3 = 
{
        PUSHER =  cc.vec3(0.0, 15, -12 ),
        ORI = cc.vec3(0.0, 15, -10),
}


-- lifterStatus
NewCoinPusherConfig.UICsbPath.StageCsb = "Activity/CoinPusher_New/csd/main/CoinPusher_jiacheng.csb"

----声音
NewCoinPusherConfig.SoundConfig = {
       WALL_UP = "Activity/CoinPusher_New/Sound/CoinPusherWallUp.mp3",
       HAMMER_DOWN = "Activity/CoinPusher_New/Sound/CoinPusherHammer.mp3",
       SEPCIAL_COIN_DOWN = "Activity/CoinPusher_New/Sound/CoinPusherSpecialCoinDown.mp3",
       BGM = "Activity/CoinPusher_New/Sound/CoinPusherBGM.mp3",
       BIG_COIN_DOWN = "Activity/CoinPusher_New/Sound/CoinPusherBigCoinDown.mp3",
       BGM_BUFF = "Activity/CoinPusher_New/Sound/CoinPusherBuffBGM.mp3",
       COIN_PUSH_DOWN = "Activity/CoinPusher_New/Sound/CoinPusherCoinDown.mp3",
       SPECIAL_PUSH_DOWN = "Activity/CoinPusher_New/Sound/CoinPusherSpecialCoinPush.mp3",
       LEVELPASS = "Activity/CoinPusher_New/Sound/CoinPusherLevelPass.mp3",
       ROUNDPASS = "Activity/CoinPusher_New/Sound/CoinPusherRoundPass.mp3",
       REWARD = "Activity/CoinPusher_New/Sound/CoinPusherReward.mp3",
       COMBO = "Activity/CoinPusher_New/Sound/CoinPusherCombo.mp3",
       NORMALCOINDOWN = "Activity/CoinPusher_New/Sound/CoinPusherNormalCoinDown.mp3",
       PASSEFFECT = "Activity/CoinPusher_New/Sound/CoinPusherPassEffect.mp3",
       FIRE = "Activity/CoinPusher_New/Sound/CoinPusherFire.mp3",
       FRUIT_TURN = "Activity/CoinPusher_New/Sound/CoinPusherFruitTurn.mp3",
       SELECT_COMPLETE = "Activity/CoinPusher_New/Sound/complete.mp3",
       SELECT_UNLOCK = "Activity/CoinPusher_New/Sound/unlock.mp3",
}

--新手引导
NewCoinPusherConfig.NewGuide = {
        ONE = {
                ID = 1,
                CLIP_SIZE = cc.size(300, 110)
        },
        TWO = {
                ID = 2,
                CLIP_SIZE = cc.size(300, 300)
        },
        THREE = {
                ID = 3,
                CLIP_SIZE = cc.size(320, 170)
        },
}

NewCoinPusherConfig.RES = {
        NewCoinPusherCardLayer_sp_rIcon = "Activity/CoinPusher_New/ui/ui_reward/CoinPusher%s.png",
        NewCoinPusherDesktopDebug_CSB = "Activity/CoinPusher_New/csd/DesktopDebug.csb",
        NewCoinPusherEffect_SprayEffectL = "Activity/CoinPusher_New/CoinPusher_zyliziLeft.csb",
        NewCoinPusherEffect_SprayEffectR = "Activity/CoinPusher_New/CoinPusher_zyliziRight.csb",
        NewCoinPusherEffect_LightBeamL = "Activity/CoinPusher_New/CoinPusher_FSdeng.csb",
        NewCoinPusherEffect_LightBeamR = "Activity/CoinPusher_New/CoinPusher_FSdeng_0.csb",
        NewCoinPusherEffect_LightDrop = "Activity/CoinPusher_New/CoinPusher_DG.csb",
        NewCoinPusherEffect_winDropEffect = "Activity/CoinPusher_New/csd/main/CoinPusher_XFlizi.csb",
        NewCoinPusherEffect_BonusSlotEffect = "Activity/CoinPusher_New/CoinPusher_SlotTile.csb",
        NewCoinPusherEffect_EffectLine = "Activity/CoinPusher_New/CoinPusher_tubiao_lizi.csb",
        NewCoinPusherGamePromtView_CSB = "Activity/CoinPusher_New/csd/main/CoinPusher_Rule.csb",
        NewCoinPusherGuideView_SPINE_Finger = "Activity/CoinPusher_New/coinpusher/DailyBonusGuide",
        NewCoinPusherLoading_CSB = "Activity/CoinPusher_New/csd/main/CoinPusher_GameLoading.csb",
        NewCoinPusherMainUI_combolAnima = "Activity/CoinPusher_New/csd/main/CoinPusher_tanzi.csb",
        NewCoinPusherMainUI_winDropEffect1 = "Activity/CoinPusher_New/csd/main/CoinPusher_XFlizi.csb",
        NewCoinPusherMainUI_winDropEffect2 = "Activity/CoinPusher_New/csd/main/CoinPusher_XFlizi1.csb",
        NewCoinPusherMainUI_passEffect = "Activity/CoinPusher_New/csd/tip.csb",
        NewCoinPusherSelectItemUI_SpCellTitle = "Activity/CoinPusher_New/ui/ui_Chapter_Cell/Timer_choose_%s.png",
        NewCoinPusherSelectItemUI_SpCellTitlePortrait = "Activity/CoinPusher_New/ui/ui_Chapter_Cell/Timer_choose_%s_Portralt.png",
        NewCoinPusherMainUI_BombDebris = "Activity/CoinPusher_New/csd/main/CoinPusher_suixie.csb",
        NewCoinPusherMainUI_FruitWin = "Activity/CoinPusher_New/csd/main/CoinPusher_tips.csb",

        --------------------------- 任务 -----------------------
        NewCoinPusherTaskMainLayer_Main_CSB = "Activity/csb/NewcoinPusherMission_mainLayer.csb",
        NewCoinPusherTaskMainLayer_Title_CSB = "Activity/csb/NewcoinPusherMission_title.csb",
        NewCoinPusherTaskMainLayer_Bubble_CSB = "Activity/csb/NewcoinPusherMission_qipao.csb",
        NewCoinPusherTaskMainLayer_Reward_CSB = "Activity/csb/NewcoinPusherMission_rewardLayer.csb",
        --------------------------- 任务 -----------------------
        --------------------------- 促销 -----------------------
        NewCoinPusherSaleMgr_NoPusherBuyView = "Activity/CoinPusher_New/csd/main/CoinPusher_NoPusherBuyView.csb",
        NewCoinPusherSaleMgr_NoPusherBuyView_Cell = "Activity/CoinPusher_New/csd/main/CoinPusher_NoPusherBuyView_Cell.csb",
        --------------------------- 促销 -----------------------

}

NewCoinPusherConfig.getThemeName = function()
        return "Activity_NewCoinPusher"        
end

    -- 模型贴图
   NewCoinPusherConfig.ModelsImage = {
       main_all      = "Activity/CoinPusher_New/models/Basecolor1.png",                            -- 主贴图
       coin_normal   = "Activity/CoinPusher_New/models/coin/Material__44_Base_color.png",          -- 普通金币贴图
    }

    NewCoinPusherConfig.Animation3D = {
        car_MoveIn              = "Activity/CoinPusher_New/models/che/CAR_chuchang_ting_ani_max_new.c3b",          -- 小车进入 
        car_Bomb                = "Activity/CoinPusher_New/models/che/CAR_baozha_ani_max_new.c3b",                 -- 小车爆炸 
        car_TurnOver            = "Activity/CoinPusher_New/models/che/CAR_qingdao_ani_max_new.c3b",                -- 小车倾倒 
        car_MoveOut             = "Activity/CoinPusher_New/models/che/CAR_yidongchu_ani_max_new.c3b",              -- 小车跑出 
        coin_MoveIn             = "Activity/CoinPusher_New/models/che/Jinbi_budong_ani_max_new.c3b",               -- 金币进入 
        coin_Bomb               = "Activity/CoinPusher_New/models/che/Jinbi_baozha_ani_max_new.c3b",               -- 金币爆炸
     }
return NewCoinPusherConfig