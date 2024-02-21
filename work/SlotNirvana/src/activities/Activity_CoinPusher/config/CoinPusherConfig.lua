--[[
    CoinPusher Config
    tm
]]
local CoinPusherConfig  = {}

-- 调试状态 
CoinPusherConfig.Debug = false                   --debug界面
CoinPusherConfig.DebugCoinCount = false          --debug界面
CoinPusherConfig.FixCarmer = true               --固定视角     
CoinPusherConfig.ConfigInitDisk = true          --配置初始化盘面        

--推币机版本
CoinPusherConfig.Version = "V1"
--------------------------------推币机参数 START-------------------------------------
-- 推币机速度
CoinPusherConfig.PusherSpeed = 6                        
CoinPusherConfig.Gravity = -30 

--质量系数(金币)
CoinPusherConfig.RatioMass = 1000000

--摩擦力系数
CoinPusherConfig.RatioFrichtion = 2                            --金币
CoinPusherConfig.PlatformFrichtion = 1                         --地板中间部分
CoinPusherConfig.BorderPlatformFrichtion = 10                  --地板两侧
CoinPusherConfig.FrontFriction = 0.15                          --地板前部
CoinPusherConfig.BackFriction = 0.1                            --地板后部
CoinPusherConfig.MiddleFriction = 1                            --地板中部
--------------------------------推币机参数 END-------------------------------------     

--掉落实体类型
CoinPusherConfig.EntityType   = {       
        COIN = 1,
        ITEM = 2,
}

--掉落实体类型
CoinPusherConfig.EntityDropType   = {
        WIN  = 1,
        LOSE = 2,
}

--触发动画类型
CoinPusherConfig.CoinEffectRefer   = {
        NORMAL = "NORMAL",
        COINS =  "COINS",
        STAGE_COINS = "STAGE_COINS",
        SLOTS = "SLOTS",
        CARD = "CARD",
        BIG = "BIG",
        DROP = "DROP",         --点击掉落金币
        EASTER = "EASTER",  -- 复活节蛋  新加
}

CoinPusherConfig.SlotEffectRefer   = {
        SLOT = "SLOT",         --老虎机滚动
        JACKPOT = "COINS",      --触发jp 奖励coins
        BIGCOIN = "BIG_COIN",   --掉落打金币
        HAMMER = "HAMMER"      --锤子
}

--掉落实体类型
CoinPusherConfig.CoinModelRefer   = {
        "NORMAL",
        "COINS",
        "STAGE_COINS",
        "SLOTS",
        "CARD",
        "BIG",
        "EASTER",
}

CoinPusherConfig.CoinPreCreateConfig = {
        NORMAL = 10,
        COINS = 10,
        STAGE_COINS = 10,
        SLOTS = 10,
        CARD = 10,
        BIG = 5,
}


-- 各种金币相关属性 --
CoinPusherConfig.CoinModelAtt   = {
        --基础金币
    ["NORMAL"] = { Name    = "NORMAL" , 
            Mass    = 150.0 * CoinPusherConfig.RatioMass ,
            Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/coinpusher/CoinGold.c3b" , 
            Texture = "Activity/coinpusher/NormalCoin.png" ,
            Scale   = 10 , 
            palne   = 6,
            PhysicSize = cc.p(3,0.5) },
    ["COINS"] = { Name    = "COINS" , 
            Mass    = 150.0 * CoinPusherConfig.RatioMass,
            Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/coinpusher/CoinSlot.c3b" , 
            Texture = "Activity/coinpusher/Coins.png" ,
            Scale   = 10 , 
            palne   = 6,
            PhysicSize = cc.p(4,0.5) },
    ["STAGE_COINS"] = { Name    = "STAGE_COINS" , 
            Mass    = 150.0 * CoinPusherConfig.RatioMass,
            Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/coinpusher/CoinSlot.c3b" , 
            Texture = "Activity/coinpusher/StageCoins.png" ,    
            Scale   = 10 , 
            palne   = 6,
            PhysicSize = cc.p(4,0.5) },
    ["SLOTS"] = { Name    = "SLOTS" , 
            Mass    = 150.0 * CoinPusherConfig.RatioMass,
            Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/coinpusher/CoinSlot.c3b" , 
            Texture = "Activity/coinpusher/Slots.png" ,
            Scale   = 10 , 
            palne   = 6,
            PhysicSize = cc.p(4,0.5) },
    ["CARD"] = { Name    = "CARD" , 
            Mass    = 150.0 * CoinPusherConfig.RatioMass,
            Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/coinpusher/CoinSlot.c3b" , 
            Texture = "Activity/coinpusher/Card.png" ,
            Scale   = 10 , 
            palne   = 6,
            PhysicSize = cc.p(4,0.5) },
    ["BIG"] = { Name    = "BIG" , 
            Mass    = 150.0 * CoinPusherConfig.RatioMass,
            Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
            Model   = "Activity/coinpusher/CoinGiant.c3b" ,     
            Texture = "Activity/coinpusher/NormalCoinBig.png" ,
            Scale   = 10 , 
            palne   = 6,
            PhysicSize = cc.p(6.5,1) },
    [7] = { Name    = "CoinChipStack4" , 
            Mass    = 400.0 ,
            Friction= 0.3 , 
            Model   = "Activity/coinpusher/CoinChipStack4.c3b" , 
            Texture = "Activity/coinpusher/CoinChipStack4.png" ,
            Scale   = 10 , 
            PhysicSize = cc.p(4,2) },
}

-- 各种道具属性 --
CoinPusherConfig.ItemModelAtt  = {
    [1] = { Name    = "PrizeElephantBlue" , 
            Mass    = 1000.0 ,
            Friction= 0. , 
            Model   = "Activity/coinpusher/PrizeElephantBlue.c3b" , 
            Texture = "Activity/coinpusher/PrizeElephantBlue.png" ,
            Scale   = 10 , 
            PhysicSize = {  type    = "box" , 
                            size    = cc.vec3(4.0, 4.0, 6) , 
                            off     = cc.vec3(0.0, -1 , -0.5) , 
                            angle   =  cc.vec3(-90.0, 180.0,  0.0)} 
            },
    [2] = { Name    = "PrizeHeartGemPurple" , 
            Mass    = 1000.0 ,
            Friction= 0.6 , 
            Model   = "Activity/coinpusher/PrizeHeartGemPurple.c3b" , 
            Texture = "Activity/coinpusher/PrizeHeartGemPurple.png" ,
            Scale   = 10 , 
            PhysicSize = {  type    = "box" , 
                            size    = cc.vec3(4.5, 4.5, 1.8) , 
                            off     = cc.vec3(0.0, 0 , 0) , 
                            angle   =  cc.vec3(-90.0, 180.0,  0.0)} 
            },
    [3] = { Name    = "PrizeJetWhite" , 
            Mass    = 1000.0 ,
            Friction= 0.6 , 
            Model   = "Activity/coinpusher/PrizeJetWhite.c3b" , 
            Texture = "Activity/coinpusher/PrizeJetWhite.png" ,
            Scale   = 10 , 
            PhysicSize = {  type = "box" , 
                            size = cc.vec3(5, 3, 5) , 
                            off = cc.vec3(0.0, 0 , 0) , 
                            angle =  cc.vec3(-0.0, 180.0,  0.0)} 
            },
    [4] = { Name    = "PrizeTiaraPurple" , 
            Mass    = 1000.0 ,
            Friction= 0.6 , 
            Model   = "Activity/coinpusher/PrizeTiaraPurple.c3b" , 
            Texture = "Activity/coinpusher/PrizeTiaraPurple.png" ,
            Scale   = 10 , 
            PhysicSize = {  type = "cylinder" , 
                            size = cc.p(4,3) , 
                            off = cc.vec3(0.0, -0.2 , 0) , 
                            angle =  cc.vec3(-0.0, 180.0,  0.0)} 
            },
    [5] = { Name    = "PrizeWatchWhite" , 
            Mass    = 1000.0 ,
            Friction= 0.6 , 
            Model   = "Activity/coinpusher/PrizeWatchWhite.c3b" , 
            Texture = "Activity/coinpusher/PrizeWatchWhite.png" ,
            Scale   = 10 ,
            PhysicSize = { type = "cylinder" , 
                            size = cc.p(4.5,2.8) , 
                            off = cc.vec3(0.0, -0.0 , 0) ,
                            angle =  cc.vec3(-0.0, 180.0,  0.0)} 
            },
}

-- 静态场景属性 --
CoinPusherConfig.PlatformModelAtt = {
    Platform    = { Mass    = 0.0 ,  
                    Model   = "Activity/coinpusher/taizi.c3b", 
                    Texture = "Activity/coinpusher/MachineJackpot.png" ,
                    Friction= 0.3 * CoinPusherConfig.PlatformFrichtion,
                    BorderFriction = 0.3 * CoinPusherConfig.BorderPlatformFrichtion,
                    FrontFriction = 0.3 * CoinPusherConfig.FrontFriction,
                    BackFriction = 0.3 * CoinPusherConfig.BackFriction,
                    MiddleFriction = 0.3 * CoinPusherConfig.MiddleFriction,
                    Scale   = 10 },
    Jackpot     = { Mass    = 0.0 ,  
                    Model   = "Activity/coinpusher/beijingui.c3b"  , 
                    Texture = "Activity/coinpusher/MachineJackpot.png" ,
                    Scale   = 10 },
    Background  = { Mass    = 0.0 ,  
                    Model   = "Activity/coinpusher/beijing.c3b"    , 
                    Texture = "Activity/coinpusher/CDJ_MachineBacker.png" ,
                    Scale   = 10 },
    Pusher      = { Mass    = 0.0 ,  
                    Model   = "Activity/coinpusher/zuoyi.c3b"      , 
                    Texture = "Activity/coinpusher/MachineJackpot.png" ,
                    Scale   = 1000 },
    Lifter      = { Mass    = 0.0 ,  
                    Model   = "Activity/coinpusher/lifter.c3b"     , 
                    Texture = "Activity/coinpusher/MachineJackpot.png" ,
                    Scale   = 10 },
    ReelUnit    = { Mass    = 0.0 ,  
                    Model   = "Activity/coinpusher/reelunit.c3b"   , 
                    Texture = "" ,
                    Scale   = 10 },
}

-- 信号块纹理属性 --
CoinPusherConfig.SymbolRes  ={
    [1] = { Name = "1" , Csb = "Activity/CoinPusher_SlotItem1.csb"},
    [2] = { Name = "2" , Csb = "Activity/CoinPusher_SlotItem2.csb"},
    [3] = { Name = "3" , Csb = "Activity/CoinPusher_SlotItem3.csb"},
    [4] = { Name = "4" , Csb = "Activity/CoinPusher_SlotItem4.csb"},
    [5] = { Name = "5" , Csb = "Activity/CoinPusher_SlotItem5.csb"},
}

-- Slot轮盘相关 --
CoinPusherConfig.ReelRollSpeed  = -40
CoinPusherConfig.ReelJumpUpTime  = 0.3
CoinPusherConfig.ReelTopPos     = 7.2
CoinPusherConfig.ReelBottomPos  = -7.2
CoinPusherConfig.ReelStopPos    = 0
CoinPusherConfig.ReelTableCenter= cc.vec3( 0 , 11.8 , -23.7 )
CoinPusherConfig.ReelUnitCenter = { 
    cc.vec3(-7.2 , 0, 0 ) ,
    cc.vec3(   0 , 0, 0 ) ,
    cc.vec3( 7.2 , 0, 0 ) ,
}
CoinPusherConfig.ReelUnitConfig = {
    {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0,  7.2 , 0 ) },
    {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0 , 7.2 , 0 ) },
    {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0 , 7.2 , 0 ) },
}

CoinPusherConfig.ReelJumpConfig = {
        { DelayTime = 0,   DestPosY = 2},
        { DelayTime = 0.1, DestPosY = 2},
        { DelayTime = 0.2, DestPosY = 2},
}

-- 假滚数据 --
CoinPusherConfig.ReelDataConfig = {
    { 1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5},
    { 1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5},
    { 1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5},
}
-- 滚动停止间隔 --
CoinPusherConfig.ReelStopOffset = { 9,13,19 }
CoinPusherConfig.ReelDataNums   = { 
    table.nums(CoinPusherConfig.ReelDataConfig[1] ) , 
    table.nums(CoinPusherConfig.ReelDataConfig[2] ) ,
    table.nums(CoinPusherConfig.ReelDataConfig[3] ) 
}
CoinPusherConfig.ReelStatus = {
    Idle    = 0,
    JumpUp  = 1,
    Running = 2,
    JumpDown= 3,
    Stoping = 4
}

CoinPusherConfig.SlotType = {
        ["FREESPIN"] = 1,
        ["COINS"] = 2,
        ["HUMMER"] = 3,
    }
--老虎机滚动个数 
CoinPusherConfig.SlotRunCount = {14, 18, 22}

-- 事件声明 --
CoinPusherConfig.Event = {
    CoinPusherGetDropCoinsReward = "CoinPusherGetDropCoinsReward",
    CoinPusherDropCoins = "CoinPusherDropCoins",
    CoinPuserTriggerEffect = "CoinPuserTriggerEffect",
    CoinPuserEffectEnd = "CoinPuserEffectEnd",
    CoinPuserGuideFinished = "CoinPuserGuideFinished",
    CoinPuserSaveEntity = "CoinPuserSaveEntity",
    CoinPuserUpdateMainUI = "CoinPuserUpdateMainUI",
    CoinPuserStageLayer = "CoinPuserStageLayer",
    CoinPuserRoundLayer = "CoinPuserRoundLayer",

    --章节加成奖励
    CoinPuserStageBuffOpen = "CoinPuserStageBuffOpen",
    CoinPuserStageBuffClose = "CoinPuserStageBuffClose",

    --推币机PASS 事件
    CoinPuserPassGetReward = "CoinPuserPassGetReward",
    CoinPuserPassUiBarFinish = "CoinPuserPassUiBarFinish",
    CoinPuserPassGuideFinish = "CoinPuserPassGuideFinish",
    CoinPuserPassGuideTwo = "CoinPuserPassGuideTwo",
    CoinPuserPassAllUnlock = "CoinPuserPassAllUnlock"
}

-- 特效属性 --
CoinPusherConfig.Effect = {
        Hammer          = {
                ID      = 1,
                Type    = "Model",   
                Model   = "Activity/coinpusher/hammer.c3b" , 
                Texture = "Activity/coinpusher/chuizi.png",
                Scale   = 5,
                ModelGuang = "Activity/coinpusher/hammerguang.c3b",
                ModelBaozha= "Activity/coinpusher/hammerbaozha.c3b" },
        FlashLight      = { 
                ID      = 2,
                Type    = "Model",  
                Model   = "Activity/coinpusher/flashlight.c3b" , 
                Texture = "Activity/coinpusher/pian_tt.png",
                Scale   = 10 },
        JackpotEffectPanel= {
                ID      = 3,
                Type    = "Model", 
                Model   = "Activity/coinpusher/jackpotEffectPanel.c3b", 
                Texture = "Activity/coinpusher/jackpotEffectPanel.png" ,
                Scale   = 10 },
        FrontEffectPanel= { 
                ID      = 4,
                Type    = "Model", 
                Model   = "Activity/coinpusher/frontEffectPanel.c3b", 
                Texture = "Activity/coinpusher/dengA.png" ,
                Scale   = 10 },
        TapHere= { 
                ID      = 5,
                Type    = "Model", 
                Model   = "Activity/coinpusher/taphere.c3b", 
                Texture = "Activity/coinpusher/tap_here.png" ,
                Scale   = 10 },
    
}

-- 台前 序列帧特效 --
CoinPusherConfig.FrontEffectPic = {
        Idle    = {
                "Activity/coinpusher/dengA_01.png",
                "Activity/coinpusher/dengA_02.png",
                "Activity/coinpusher/dengA_03.png",
                "Activity/coinpusher/dengA_04.png",
                "Activity/coinpusher/dengA_05.png",
                "Activity/coinpusher/dengA_04.png",
                "Activity/coinpusher/dengA_03.png",
                "Activity/coinpusher/dengA_02.png",
                "Activity/coinpusher/dengA_01.png"
        },
        IdleInterval = 0.5,
        Flash   = {
                "Activity/coinpusher/dengB_01.png",
                "Activity/coinpusher/dengB_02.png",
                "Activity/coinpusher/dengB_03.png",
                "Activity/coinpusher/dengB_04.png",
                "Activity/coinpusher/dengB_05.png",
                "Activity/coinpusher/dengB_06.png",
                "Activity/coinpusher/dengB_05.png",
                "Activity/coinpusher/dengB_04.png",
                "Activity/coinpusher/dengB_03.png",
                "Activity/coinpusher/dengB_02.png",
        },
        FlashInterval = 0.1
}


-- jackpot 序列帧特效 --
CoinPusherConfig.JackPotEffectPic = {
        Idle    = {
                "Activity/coinpusher/dengB1.png",
                "Activity/coinpusher/dengB2.png",
                "Activity/coinpusher/dengB3.png",
                "Activity/coinpusher/dengB2.png",
                "Activity/coinpusher/dengB1.png"
        },
        IdleInterval = 0.5,
        Flash   = {
                "Activity/coinpusher/dengB1.png",
                "Activity/coinpusher/dengB2.png",
                "Activity/coinpusher/dengB3.png",
                "Activity/coinpusher/dengB2.png",
                "Activity/coinpusher/dengB1.png"
        },
        FlashInterval = 0.1
}

CoinPusherConfig.jackpotPosOri    = cc.vec3(0.0, 0.0, 0 )
CoinPusherConfig.jackpotPosDest   = cc.vec3(0.0, 6.5, 0 )

CoinPusherConfig.jackpotEffectPos =   cc.vec3( 0 , -1.5,  0.0)
CoinPusherConfig.BlackFNT = "Activity/coinpusher/font_arialblack.fnt"

-- 调试面板按钮图片 --
CoinPusherConfig.debugBtnRes = "Activity/coinpusher/btn.png"


--玩法状态
CoinPusherConfig.PlayState   = {
        IDLE    = 1,    --未开始
        PLAYING = 2,    --播放状态
        DONE    = 3,    --结束
}

--烟花特效配置
CoinPusherConfig.FireWorksCsb = {
        "Activity/CoinPusher_YanHa_huang.csb",
        "Activity/CoinPusher_YanHa_lan.csb",
        "Activity/CoinPusher_YanHa_zi.csb",
}

--光圈特效配置
CoinPusherConfig.LightRingCsb = {
        "Activity/CoinPusher_Dhuangg.csb",
        "Activity/CoinPusher_Dlanguang.csb",
}

--章节状态
CoinPusherConfig.PlanesState = {
        COMPLETED = "COMPLETED",
        PLAY  = "PLAY",
        LOCKD =  "LOCKD",
}

--CSB
CoinPusherConfig.UICsbPath = {
        MainUI = "Activity/CoinPusher_MainLayer.csb",
        MainUITitle = "Activity/CoinPusher_MainLayerTitle.csb", 
        SelectUI = "Activity/CoinPusher_Chapter.csb",
        SelectUIPortrait = "Activity/CoinPusher_Chapter_Portralt.csb",
        SelectUIItem  = "Activity/CoinPusher_Chapter_Item1.csb",
        SelectUIItemPortrait  = "Activity/CoinPusher_Chapter_Item1_Portralt.csb",
        EntryNode = "Activity/CoinPusher_GameSceneUI.csb",
        NewGuide = "Activity/CoinPusher_NewGuide.csb",

        RankLogo      = "Activity/CoinPusher_rank/CoinPusherItem.csb",    -- 排行榜LOGO
        RankMainLayer = "Activity/CoinPusher_rank/CoinPusher_Rank.csb",   -- 排行榜主界面
        RankTitle     = "Activity/CoinPusher_rank/CoinPusherTitle.csb",   -- 排行榜标题
        RankInfo      = "Activity/CoinPusher_rank/CoinPusher_help.csb",   -- 排行榜说明
        RankCell0     = "Activity/CoinPusher_rank/CoinPusher_item0.csb",  -- 
        RankTimer     = "Activity/CoinPusher_rank/CoinPusherTime.csb",  -- 
        RankCell1     = "Activity/CoinPusher_rank/CoinPusher_item1.csb",  -- 
        RankCell2     = "Activity/CoinPusher_rank/CoinPusher_item2.csb",  -- 
        RankTop       = "Activity/CoinPusher_rank/CoinPusher_Top%d.csb"
}

-- 排行榜前三名
CoinPusherConfig.rankPng = {
        Bg_1 = "Activity/ui_rank/CoinPusher_rank_itembg1.png",
        Bg_2 = "Activity/ui_rank/CoinPusher_rank_itembg2.png",
        Bg_3 = "Activity/ui_rank/CoinPusher_rank_itembg3.png",
        Rank_1 = "Activity/ui_rank/CoinPusher_itemRank1.png",
        Rank_2 = "Activity/ui_rank/CoinPusher_itemRank2.png",
        Rank_3 = "Activity/ui_rank/CoinPusher_itemRank3.png",
        reward_1 = "Activity/ui_rank/CoinPusher_rank_1.png",
        reward_2 = "Activity/ui_rank/CoinPusher_rank_2.png",
        reward_3 = "Activity/ui_rank/CoinPusher_rank_3.png",
}

--combo 图片路径
CoinPusherConfig.ComboEffectPng = {
        "Activity/coinpusher/CoinPusherCoinAttack1.png",
        "Activity/coinpusher/CoinPusherCoinAttack2.png", 
        "Activity/coinpusher/CoinPusherCoinAttack3.png",
        "Activity/coinpusher/CoinPusherCoinAttack4.png",
        "Activity/coinpusher/CoinPusherCoinAttack5.png",
        "Activity/coinpusher/CoinPusherCoinAttack6.png"
}
CoinPusherConfig.ComboFreshDt = 3

--弹窗csb
CoinPusherConfig.PopCsbPath = {
        Stage = {
                Type = "Stage",
                Path = "Activity/CoinPusher_Reward_Cell.csb",
        } ,
        Coin = {
                Type = "Coin",
                Path = "Activity/CoinPusher_Reward_Cell.csb",
        } ,
        Card =  {
                Type = "Card",
                Path = "Activity/CoinPusher_Reward_Cell.csb",
        },
        Level = {
                Type = "Level",
                Path = "Activity/CoinPusher_Reward_Level.csb",

        },
        Round = {
                Type = "Round",
                Path = "Activity/CoinPusher_Reward_Final.csb",
        },
}

--mainUI zorder
CoinPusherConfig.MainUIZorder = {
        WinLight = 100,
        Combo = 100,
        CardLayer = 200,
        ViewLayer = 300,
}

---BUFF
CoinPusherConfig.BuffResPath = 
{
        GAME =  "Activity/CoinPusher_Powerup.csb",
        ENTRY = "Activity/CoinPusher_PowerupEntry.csb"
}
--buff 监听倒计时  times/BuffUpdateTime
CoinPusherConfig.BuffUpdateTime = 1.0
CoinPusherConfig.TapUpdateTime = 10.0

CoinPusherConfig.PusherDisVec3 = 
{
        PUSHER =  cc.vec3(0.0, 0.0, 6 ),
        ORI = cc.vec3(0.0, 0.0, 0.5),

}
-- lifterStatus
CoinPusherConfig.UICsbPath.StageCsb = "Activity/CoinPusher_jiacheng.csb"

----声音
CoinPusherConfig.SoundConfig = {
       WALL_UP = "Activity/Sound/CoinPusherWallUp.mp3",
       HAMMER_DOWN = "Activity/Sound/CoinPusherHammer.mp3",
       SLOT_RUN = "Activity/Sound/CoinPusherSlotRun.mp3",
       SLOT_UP =  "Activity/Sound/CoinPusherSlotUp.mp3",
       SLOT_EFFECT =  "Activity/Sound/CoinPusherSlotEffect.mp3",
       SEPCIAL_COIN_DOWN = "Activity/Sound/CoinPusherSpecialCoinDown.mp3",
       BGM = "Activity/Sound/CoinPusherBGM.mp3",
       BIG_COIN_DOWN = "Activity/Sound/CoinPusherBigCoinDown.mp3",
       BGM_BUFF = "Activity/Sound/CoinPusherBuffBGM.mp3",
       COIN_PUSH_DOWN = "Activity/Sound/CoinPusherCoinDown.mp3",
       SPECIAL_PUSH_DOWN = "Activity/Sound/CoinPusherSpecialCoinPush.mp3",
       LEVELPASS = "Activity/Sound/CoinPusherLevelPass.mp3",
       ROUNDPASS = "Activity/Sound/CoinPusherRoundPass.mp3",
       REWARD = "Activity/Sound/CoinPusherReward.mp3",
       SLOTSTART = "Activity/Sound/CoinPusherSlotStart.mp3",
        COMBO = "Activity/Sound/CoinPusherCombo.mp3",
        SLOTLINE = "Activity/Sound/CoinPusherSlotLine.mp3",
        NORMALCOINDOWN = "Activity/Sound/CoinPusherNormalCoinDown.mp3",
        PASSEFFECT = "Activity/Sound/CoinPusherPassEffect.mp3",
}

--新手引导
CoinPusherConfig.NewGuide = {
        SELECT = {
                ID = 1,
                POS = cc.p(0,0)
        },
        TAP_DROPCOIN = {
                ID = 2,
                --这样做有问题 初始化时就赋值 display转换屏幕会变化
                -- POS = cc.p(display.width/ 2 - 10,display.height + 50)
        },
        COIN_WIN = {
                ID = 3,
                -- POS = cc.p(display.width/ 2,520)
        },
        ENERGY= {
                ID = 4,
                -- POS = cc.p(display.width/ 2 + 10,display.height * 2/ 3)
        },
        SPECIAL_COIN_WIN = {
                ID = 5,
                -- POS = cc.p(display.width/ 2,560)
        },
        TOTLE_COUNT = 6,
}

CoinPusherConfig.RES = {
        CoinPusherCardLayer_sp_rIcon = "Activity/ui_reward/CoinPusher%s.png",
        CoinPusherDesktopDebug_CSB = "Activity/DesktopDebug.csb",
        CoinPusherEffect_SprayEffectL = "Activity/CoinPusher_zyliziLeft.csb",
        CoinPusherEffect_SprayEffectR = "Activity/CoinPusher_zyliziRight.csb",
        CoinPusherEffect_LightBeamL = "Activity/CoinPusher_FSdeng.csb",
        CoinPusherEffect_LightBeamR = "Activity/CoinPusher_FSdeng_0.csb",
        CoinPusherEffect_LightDrop = "Activity/CoinPusher_DG.csb",
        CoinPusherEffect_winDropEffect = "Activity/CoinPusher_XFlizi.csb",
        CoinPusherEffect_BonusSlotEffect = "Activity/CoinPusher_SlotTile.csb",
        CoinPusherEffect_EffectLine = "Activity/CoinPusher_tubiao_lizi.csb",
        CoinPusherGamePromtView_CSB = "Activity/CoinPusher_Rule.csb",
        CoinPusherGuideView_SPINE_Finger = "Activity/coinpusher/DailyBonusGuide",
        CoinPusherLoading_CSB = "Activity/CoinPusher_GameLoading.csb",
        CoinPusherMainUI_combolAnima = "Activity/CoinPusher_tanzi.csb",
        CoinPusherMainUI_winDropEffect1 = "Activity/CoinPusher_XFlizi.csb",
        CoinPusherMainUI_winDropEffect2 = "Activity/CoinPusher_XFlizi1.csb",
        CoinPusherMainUI_passEffect = "Activity/CoinPusher_passEffect.csb",
        CoinPusherSelectItemUI_SpCellTitle = "Activity/ui_Chapter_Cell/Timer_choose_%s.png",
        CoinPusherSelectItemUI_SpCellTitlePortrait = "Activity/ui_Chapter_Cell/Timer_choose_%s_Portralt.png",

        --------------------------- 任务 -----------------------
        CoinPusherTaskMainLayer_Main_CSB = "Activity/csb/coinPusherMission_mainLayer.csb",
        CoinPusherTaskMainLayer_Title_CSB = "Activity/csb/coinPusherMission_title.csb",
        CoinPusherTaskMainLayer_Bubble_CSB = "Activity/csb/coinPusherMission_qipao.csb",
        CoinPusherTaskMainLayer_Reward_CSB = "Activity/csb/coinPusherMission_rewardLayer.csb",
        --------------------------- 任务 -----------------------
        --------------------------- 促销 -----------------------
        CoinPusherSaleMgr_NoPusherBuyView = "Activity/CoinPusher_NoPusherBuyView.csb",
        CoinPusherSaleMgr_NoPusherBuyView_Cell = "Activity/CoinPusher_NoPusherBuyView_Cell.csb",
        --------------------------- 促销 -----------------------

}

CoinPusherConfig.getThemeName = function()
        return "Activity_CoinPusher"        
end

return CoinPusherConfig