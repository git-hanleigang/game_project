local CoinPusherConfig = require("activities.Activity_CoinPusher.config.CoinPusherConfig")

-- 各种金币相关属性 --
CoinPusherConfig.CoinModelAtt   = {
    --基础金币
["NORMAL"] = { Name    = "NORMAL" , 
        Mass    = 150.0 * CoinPusherConfig.RatioMass ,
        Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
        Model   = "Activity/coinPusher_easter/coinpusher/CoinGold.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/NormalCoin.png" ,
        Scale   = 10 , 
        palne   = 6,
        PhysicSize = cc.p(3,0.5) },
["COINS"] = { Name    = "COINS" , 
        Mass    = 150.0 * CoinPusherConfig.RatioMass,
        Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
        Model   = "Activity/coinPusher_easter/coinpusher/CoinSlot.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/Coins.png" ,
        Scale   = 10 , 
        palne   = 6,
        PhysicSize = cc.p(4,0.5) },
["STAGE_COINS"] = { Name    = "STAGE_COINS" , 
        Mass    = 150.0 * CoinPusherConfig.RatioMass,
        Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
        Model   = "Activity/coinPusher_easter/coinpusher/CoinSlot.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/StageCoins.png" ,    
        Scale   = 10 , 
        palne   = 6,
        PhysicSize = cc.p(4,0.5) },
["SLOTS"] = { Name    = "SLOTS" , 
        Mass    = 150.0 * CoinPusherConfig.RatioMass,
        Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
        Model   = "Activity/coinPusher_easter/coinpusher/CoinSlot.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/Slots.png" ,
        Scale   = 10 , 
        palne   = 6,
        PhysicSize = cc.p(4,0.5) },
["CARD"] = { Name    = "CARD" , 
        Mass    = 150.0 * CoinPusherConfig.RatioMass,
        Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
        Model   = "Activity/coinPusher_easter/coinpusher/CoinSlot.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/Card.png" ,
        Scale   = 10 , 
        palne   = 6,
        PhysicSize = cc.p(4,0.5) },
["BIG"] = { Name    = "BIG" , 
        Mass    = 150.0 * CoinPusherConfig.RatioMass,
        Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
        Model   = "Activity/coinPusher_easter/coinpusher/CoinGiant.c3b" ,     
        Texture = "Activity/coinPusher_easter/coinpusher/NormalCoinBig.png" ,
        Scale   = 10 , 
        palne   = 6,
        PhysicSize = cc.p(6.5,1) },
[7] = { Name    = "CoinChipStack4" , 
        Mass    = 400.0 ,
        Friction= 0.3 , 
        Model   = "Activity/coinPusher_easter/coinpusher/CoinChipStack4.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/CoinChipStack4.png" ,
        Scale   = 10 , 
        PhysicSize = cc.p(4,2) },
["EASTER"] = { Name    = "EASTER" , 
        Mass    = 600.0 * CoinPusherConfig.RatioMass,
        Friction= 0.3 * CoinPusherConfig.RatioFrichtion, 
        Model   = "Activity/coinPusher_easter/coinpusher/c3b_easter_egg.c3b", 
        Texture = "Activity/coinPusher_easter/coinpusher/img_easter_egg.png",
        Scale   = 2 , 
        palne   = 8,
        PhysicSize = cc.p(4, 0.5) },
}

-- 各种道具属性 --
CoinPusherConfig.ItemModelAtt  = {
[1] = { Name    = "PrizeElephantBlue" , 
        Mass    = 1000.0 ,
        Friction= 0. , 
        Model   = "Activity/coinPusher_easter/coinpusher/PrizeElephantBlue.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/PrizeElephantBlue.png" ,
        Scale   = 10 , 
        PhysicSize = {  type    = "box" , 
                        size    = cc.vec3(4.0, 4.0, 6) , 
                        off     = cc.vec3(0.0, -1 , -0.5) , 
                        angle   =  cc.vec3(-90.0, 180.0,  0.0)} 
        },
[2] = { Name    = "PrizeHeartGemPurple" , 
        Mass    = 1000.0 ,
        Friction= 0.6 , 
        Model   = "Activity/coinPusher_easter/coinpusher/PrizeHeartGemPurple.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/PrizeHeartGemPurple.png" ,
        Scale   = 10 , 
        PhysicSize = {  type    = "box" , 
                        size    = cc.vec3(4.5, 4.5, 1.8) , 
                        off     = cc.vec3(0.0, 0 , 0) , 
                        angle   =  cc.vec3(-90.0, 180.0,  0.0)} 
        },
[3] = { Name    = "PrizeJetWhite" , 
        Mass    = 1000.0 ,
        Friction= 0.6 , 
        Model   = "Activity/coinPusher_easter/coinpusher/PrizeJetWhite.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/PrizeJetWhite.png" ,
        Scale   = 10 , 
        PhysicSize = {  type = "box" , 
                        size = cc.vec3(5, 3, 5) , 
                        off = cc.vec3(0.0, 0 , 0) , 
                        angle =  cc.vec3(-0.0, 180.0,  0.0)} 
        },
[4] = { Name    = "PrizeTiaraPurple" , 
        Mass    = 1000.0 ,
        Friction= 0.6 , 
        Model   = "Activity/coinPusher_easter/coinpusher/PrizeTiaraPurple.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/PrizeTiaraPurple.png" ,
        Scale   = 10 , 
        PhysicSize = {  type = "cylinder" , 
                        size = cc.p(4,3) , 
                        off = cc.vec3(0.0, -0.2 , 0) , 
                        angle =  cc.vec3(-0.0, 180.0,  0.0)} 
        },
[5] = { Name    = "PrizeWatchWhite" , 
        Mass    = 1000.0 ,
        Friction= 0.6 , 
        Model   = "Activity/coinPusher_easter/coinpusher/PrizeWatchWhite.c3b" , 
        Texture = "Activity/coinPusher_easter/coinpusher/PrizeWatchWhite.png" ,
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
                    Model   = "Activity/coinPusher_easter/coinpusher/taizi.c3b"      , 
                    Texture = "Activity/coinPusher_easter/coinpusher/MachineJackpot.png" ,
                    Friction= 0.3 * CoinPusherConfig.PlatformFrichtion,
                    BorderFriction = 0.3 * CoinPusherConfig.BorderPlatformFrichtion,
                    FrontFriction = 0.3 * CoinPusherConfig.FrontFriction,
                    BackFriction = 0.3 * CoinPusherConfig.BackFriction,
                    MiddleFriction = 0.3 * CoinPusherConfig.MiddleFriction,
                    Scale   = 10 },
    Jackpot     = { Mass    = 0.0 ,  
                    Model   = "Activity/coinPusher_easter/coinpusher/beijingui.c3b"  , 
                    Texture = "Activity/coinPusher_easter/coinpusher/MachineJackpot.png" ,
                    Scale   = 10 },
    Background  = { Mass    = 0.0 ,  
                    Model   = "Activity/coinPusher_easter/coinpusher/beijing.c3b"    , 
                    Texture = "Activity/coinPusher_easter/coinpusher/CDJ_MachineBacker.png" ,
                    Scale   = 10 },
    Pusher      = { Mass    = 0.0 ,  
                    Model   = "Activity/coinPusher_easter/coinpusher/zuoyi.c3b"      , 
                    Texture = "Activity/coinPusher_easter/coinpusher/MachineJackpot.png" ,
                    Scale   = 1000 },
    Lifter      = { Mass    = 0.0 ,  
                    Model   = "Activity/coinPusher_easter/coinpusher/lifter.c3b"     , 
                    Texture = "Activity/coinPusher_easter/coinpusher/MachineJackpot.png" ,
                    Scale   = 10 },
    ReelUnit    = { Mass    = 0.0 ,  
                    Model   = "Activity/coinPusher_easter/coinpusher/reelunit.c3b"   , 
                    Texture = "" ,
                    Scale   = 10 },
}

-- 信号块纹理属性 --
CoinPusherConfig.SymbolRes  ={
    [1] = { Name = "1" , Csb = "Activity/coinPusher_easter/csb/CoinPusher_SlotItem1.csb"},
    [2] = { Name = "2" , Csb = "Activity/coinPusher_easter/csb/CoinPusher_SlotItem2.csb"},
    [3] = { Name = "3" , Csb = "Activity/coinPusher_easter/csb/CoinPusher_SlotItem3.csb"},
    [4] = { Name = "4" , Csb = "Activity/coinPusher_easter/csb/CoinPusher_SlotItem4.csb"},
    [5] = { Name = "5" , Csb = "Activity/coinPusher_easter/csb/CoinPusher_SlotItem5.csb"},
}

-- 特效属性 --
CoinPusherConfig.Effect = {
    Hammer          = {
            ID      = 1,
            Type    = "Model",   
            Model   = "Activity/coinPusher_easter/coinpusher/hammer.c3b" , 
            Texture = "Activity/coinPusher_easter/coinpusher/chuizi.png",
            Scale   = 5,
            ModelGuang = "Activity/coinPusher_easter/coinpusher/hammerguang.c3b",
            ModelBaozha= "Activity/coinPusher_easter/coinpusher/hammerbaozha.c3b" },
    FlashLight      = { 
            ID      = 2,
            Type    = "Model",  
            Model   = "Activity/coinPusher_easter/coinpusher/flashlight.c3b" , 
            Texture = "Activity/coinPusher_easter/coinpusher/pian_tt.png",
            Scale   = 10 },
    JackpotEffectPanel= {
            ID      = 3,
            Type    = "Model", 
            Model   = "Activity/coinPusher_easter/coinpusher/jackpotEffectPanel.c3b", 
            Texture = "Activity/coinPusher_easter/coinpusher/jackpotEffectPanel.png" ,
            Scale   = 10 },
    FrontEffectPanel= { 
            ID      = 4,
            Type    = "Model", 
            Model   = "Activity/coinPusher_easter/coinpusher/frontEffectPanel.c3b", 
            Texture = "Activity/coinPusher_easter/coinpusher/dengA.png" ,
            Scale   = 10 },
    TapHere= { 
            ID      = 5,
            Type    = "Model", 
            Model   = "Activity/coinPusher_easter/coinpusher/taphere.c3b", 
            Texture = "Activity/coinPusher_easter/coinpusher/tap_here.png" ,
            Scale   = 10 },

}

-- 台前 序列帧特效 --
CoinPusherConfig.FrontEffectPic = {
    Idle    = {
            "Activity/coinPusher_easter/coinpusher/dengA_01.png",
            "Activity/coinPusher_easter/coinpusher/dengA_02.png",
            "Activity/coinPusher_easter/coinpusher/dengA_03.png",
            "Activity/coinPusher_easter/coinpusher/dengA_04.png",
            "Activity/coinPusher_easter/coinpusher/dengA_05.png",
            "Activity/coinPusher_easter/coinpusher/dengA_04.png",
            "Activity/coinPusher_easter/coinpusher/dengA_03.png",
            "Activity/coinPusher_easter/coinpusher/dengA_02.png",
            "Activity/coinPusher_easter/coinpusher/dengA_01.png"
    },
    IdleInterval = 0.5,
    Flash   = {
            "Activity/coinPusher_easter/coinpusher/dengB_01.png",
            "Activity/coinPusher_easter/coinpusher/dengB_02.png",
            "Activity/coinPusher_easter/coinpusher/dengB_03.png",
            "Activity/coinPusher_easter/coinpusher/dengB_04.png",
            "Activity/coinPusher_easter/coinpusher/dengB_05.png",
            "Activity/coinPusher_easter/coinpusher/dengB_06.png",
            "Activity/coinPusher_easter/coinpusher/dengB_05.png",
            "Activity/coinPusher_easter/coinpusher/dengB_04.png",
            "Activity/coinPusher_easter/coinpusher/dengB_03.png",
            "Activity/coinPusher_easter/coinpusher/dengB_02.png",
    },
    FlashInterval = 0.1
}


-- jackpot 序列帧特效 --
CoinPusherConfig.JackPotEffectPic = {
    Idle    = {
            "Activity/coinPusher_easter/coinpusher/dengB1.png",
            "Activity/coinPusher_easter/coinpusher/dengB2.png",
            "Activity/coinPusher_easter/coinpusher/dengB3.png",
            "Activity/coinPusher_easter/coinpusher/dengB2.png",
            "Activity/coinPusher_easter/coinpusher/dengB1.png"
    },
    IdleInterval = 0.5,
    Flash   = {
            "Activity/coinPusher_easter/coinpusher/dengB1.png",
            "Activity/coinPusher_easter/coinpusher/dengB2.png",
            "Activity/coinPusher_easter/coinpusher/dengB3.png",
            "Activity/coinPusher_easter/coinpusher/dengB2.png",
            "Activity/coinPusher_easter/coinpusher/dengB1.png"
    },
    FlashInterval = 0.1
}

CoinPusherConfig.BlackFNT = "Activity/coinPusher_easter/coinpusher/font_arialblack.fnt"

-- 调试面板按钮图片 --
CoinPusherConfig.debugBtnRes = "Activity/coinPusher_easter/coinpusher/btn.png"

--烟花特效配置
CoinPusherConfig.FireWorksCsb = {
    "Activity/coinPusher_easter/csb/CoinPusher_YanHa_huang.csb",
    "Activity/coinPusher_easter/csb/CoinPusher_YanHa_lan.csb",
    "Activity/coinPusher_easter/csb/CoinPusher_YanHa_zi.csb",
}

--光圈特效配置
CoinPusherConfig.LightRingCsb = {
    "Activity/coinPusher_easter/csb/CoinPusher_Dhuangg.csb",
    "Activity/coinPusher_easter/csb/CoinPusher_Dlanguang.csb",
}

--CSB
CoinPusherConfig.UICsbPath = {
    MainUI = "Activity/coinPusher_easter/csb/CoinPusher_MainLayer.csb",
    MainUITitle = "Activity/coinPusher_easter/csb/CoinPusher_MainLayerTitle.csb", 
    SelectUI = "Activity/coinPusher_easter/csb/CoinPusher_Chapter.csb",
    SelectUIPortrait = "Activity/coinPusher_easter/csb/CoinPusher_Chapter_Portralt.csb",
    SelectUIItem  = "Activity/coinPusher_easter/csb/CoinPusher_Chapter_Item1.csb",
    SelectUIItemPortrait  = "Activity/coinPusher_easter/csb/CoinPusher_Chapter_Item1_Portralt.csb",
    EntryNode = "Activity/coinPusher_easter/csb/CoinPusher_GameSceneUI.csb",
    NewGuide = "Activity/coinPusher_easter/csb/CoinPusher_NewGuide.csb",

    RankLogo      = "Activity/coinPusher_easter/CoinPusher_rank/CoinPusherItem.csb",    -- 排行榜LOGO
    RankMainLayer = "Activity/coinPusher_easter/CoinPusher_rank/CoinPusher_Rank.csb",   -- 排行榜主界面
    RankTitle     = "Activity/coinPusher_easter/CoinPusher_rank/CoinPusherTitle.csb",   -- 排行榜标题
    RankInfo      = "Activity/coinPusher_easter/CoinPusher_rank/CoinPusher_help.csb",   -- 排行榜说明
    RankCell0     = "Activity/coinPusher_easter/CoinPusher_rank/CoinPusher_item0.csb",  -- 
    RankCell1     = "Activity/coinPusher_easter/CoinPusher_rank/CoinPusher_item1.csb",  -- 
    RankCell2     = "Activity/coinPusher_easter/CoinPusher_rank/CoinPusher_item2.csb",  -- 

    ------------------------------- 新增pass -------------------------------
    PassMainLayer = "Activity/coinPusher_easter/PassCoinPusher_Easter/PassCoinPusher_Easter_MainUI.csb",   -- PASS主界面
    PassReward    = "Activity/coinPusher_easter/PassCoinPusher_Easter/PassCoinPusher_Easter_Rewards.csb",   -- PASS奖励界面
    PassRule      = "Activity/coinPusher_easter/PassCoinPusher_Easter/PassCoinPusher_Easter_Rule.csb",   -- PASS规则界面
    PassGuide     = "Activity/coinPusher_easter/PassCoinPusher_Easter/Pass_Guide.csb",  --新手引导 
    PassProgress  = "Activity/coinPusher_easter/PassCoinPusher_Easter/Pass_MainLeftProgress.csb",  --进度条 
    PassCell      = "Activity/coinPusher_easter/PassCoinPusher_Easter/PassCell.csb",  --cell 
    PassSafe      = "Activity/coinPusher_easter/PassCoinPusher_Easter/Pass_Safe.csb",  --cell 
    PassLevelProgress = "Activity/coinPusher_easter/PassCoinPusher_Easter/Pass_LevelProgress.csb",  --主进度条 
    PassEntry = "Activity/coinPusher_easter/PassCoinPusher_Easter/Pass_Logo.csb",  --入口
    PassEntryFlyParticle = "Activity/coinPusher_easter/PassCoinPusher_Easter/Pass_flyPartical.csb",  --入口
    PassCellClaim = "Activity/coinPusher_easter/PassCoinPusher_Easter/PassCell_claim.csb",
    PassSafeCell = "Activity/coinPusher_easter/PassCoinPusher_Easter/Pass_Safe_Cell.csb",
    ------------------------------- 新增pass -------------------------------
}

-- 排行榜前三名
CoinPusherConfig.rankPng = {
    Bg_1 = "Activity/coinPusher_easter/ui_rank/CoinPusher_rank_itembg1.png",
    Bg_2 = "Activity/coinPusher_easter/ui_rank/CoinPusher_rank_itembg2.png",
    Bg_3 = "Activity/coinPusher_easter/ui_rank/CoinPusher_rank_itembg3.png",
    Rank_1 = "Activity/coinPusher_easter/ui_rank/CoinPusher_itemRank1.png",
    Rank_2 = "Activity/coinPusher_easter/ui_rank/CoinPusher_itemRank2.png",
    Rank_3 = "Activity/coinPusher_easter/ui_rank/CoinPusher_itemRank3.png",
    reward_1 = "Activity/coinPusher_easter/ui_rank/CoinPusher_rank_1.png",
    reward_2 = "Activity/coinPusher_easter/ui_rank/CoinPusher_rank_2.png",
    reward_3 = "Activity/coinPusher_easter/ui_rank/CoinPusher_rank_3.png",
}

--combo 图片路径
CoinPusherConfig.ComboEffectPng = {
    "Activity/coinPusher_easter/coinpusher/CoinPusherCoinAttack1.png",
    "Activity/coinPusher_easter/coinpusher/CoinPusherCoinAttack2.png", 
    "Activity/coinPusher_easter/coinpusher/CoinPusherCoinAttack3.png",
    "Activity/coinPusher_easter/coinpusher/CoinPusherCoinAttack4.png",
    "Activity/coinPusher_easter/coinpusher/CoinPusherCoinAttack5.png",
    "Activity/coinPusher_easter/coinpusher/CoinPusherCoinAttack6.png"
}

--弹窗csb
CoinPusherConfig.PopCsbPath = {
    Stage = {
            Type = "Stage",
            Path = "Activity/coinPusher_easter/csb/CoinPusher_Reward_Cell.csb",
    } ,
    Coin = {
            Type = "Coin",
            Path = "Activity/coinPusher_easter/csb/CoinPusher_Reward_Cell.csb",
    } ,
    Card =  {
            Type = "Card",
            Path = "Activity/coinPusher_easter/csb/CoinPusher_Reward_Cell.csb",
    },
    Level = {
            Type = "Level",
            Path = "Activity/coinPusher_easter/csb/CoinPusher_Reward_Level.csb",

    },
    Round = {
            Type = "Round",
            Path = "Activity/coinPusher_easter/csb/CoinPusher_Reward_Final.csb",
    },
}

---BUFF
CoinPusherConfig.BuffResPath = 
{
        GAME =  "Activity/coinPusher_easter/csb/CoinPusher_Powerup.csb",
        ENTRY = "Activity/coinPusher_easter/csb/CoinPusher_PowerupEntry.csb"
}

-- lifterStatus
CoinPusherConfig.UICsbPath.StageCsb = "Activity/coinPusher_easter/csb/CoinPusher_jiacheng.csb"

CoinPusherConfig.RES = {
    CoinPusherCardLayer_sp_rIcon = "Activity/coinPusher_easter/ui_reward/CoinPusher%s.png",
    CoinPusherDesktopDebug_CSB = "Activity/coinPusher_easter/csb/DesktopDebug.csb",
    CoinPusherEffect_SprayEffectL = "Activity/coinPusher_easter/csb/CoinPusher_zyliziLeft.csb",
    CoinPusherEffect_SprayEffectR = "Activity/coinPusher_easter/csb/CoinPusher_zyliziRight.csb",
    CoinPusherEffect_LightBeamL = "Activity/coinPusher_easter/csb/CoinPusher_FSdeng.csb",
    CoinPusherEffect_LightBeamR = "Activity/coinPusher_easter/csb/CoinPusher_FSdeng_0.csb",
    CoinPusherEffect_LightDrop = "Activity/coinPusher_easter/csb/CoinPusher_DG.csb",
    CoinPusherEffect_winDropEffect = "Activity/coinPusher_easter/csb/CoinPusher_XFlizi.csb",
    CoinPusherEffect_BonusSlotEffect = "Activity/coinPusher_easter/csb/CoinPusher_SlotTile.csb",
    CoinPusherEffect_EffectLine = "Activity/coinPusher_easter/csb/CoinPusher_tubiao_lizi.csb",
    CoinPusherGamePromtView_CSB = "Activity/coinPusher_easter/csb/CoinPusher_Rule.csb",
    CoinPusherGuideView_SPINE_Finger = "Activity/coinPusher_easter/coinpusher/DailyBonusGuide",
    CoinPusherLoading_CSB = "Activity/coinPusher_easter/csb/CoinPusher_GameLoading.csb",
    CoinPusherMainUI_combolAnima = "Activity/coinPusher_easter/csb/CoinPusher_tanzi.csb",
    CoinPusherMainUI_winDropEffect1 = "Activity/coinPusher_easter/csb/CoinPusher_XFlizi.csb",
    CoinPusherMainUI_winDropEffect2 = "Activity/coinPusher_easter/csb/CoinPusher_XFlizi1.csb",
    CoinPusherMainUI_passEffect = "Activity/coinPusher_easter/csb/CoinPusher_passEffect.csb",
    CoinPusherSelectItemUI_SpCellTitle = "Activity/coinPusher_easter/ui_Chapter_Cell/Timer_choose_%s.png",
    CoinPusherSelectItemUI_SpCellTitlePortrait = "Activity/coinPusher_easter/ui_Chapter_Cell/Timer_chooseshu_%s.png",

    --------------------------- 任务 -----------------------
    CoinPusherTaskMainLayer_Main_CSB = "Activity/coinPusher_mission_easeter/csb/coinPusherMission_mainLayer.csb",
    CoinPusherTaskMainLayer_Title_CSB = "Activity/coinPusher_mission_easeter/csb/coinPusherMission_title.csb",
    CoinPusherTaskMainLayer_Bubble_CSB = "Activity/coinPusher_mission_easeter/csb/coinPusherMission_qipao.csb",
    CoinPusherTaskMainLayer_Reward_CSB = "Activity/coinPusher_mission_easeter/csb/coinPusherMission_rewardLayer.csb",
    --------------------------- 任务 -----------------------
    --------------------------- 促销 -----------------------
    CoinPusherSaleMgr_NoPusherBuyView = "Activity/coinPusher_easter/csb/CoinPusher_NoPusherBuyView.csb",
    CoinPusherSaleMgr_NoPusherBuyView_Cell = "Activity/coinPusher_easter/csb/CoinPusher_NoPusherBuyView_Cell.csb",
    --------------------------- 促销 -----------------------
}

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
        PASS_UNLOCK = "Activity/Sound/CoinPusherPassUnlock.mp3",
        PASS_REWARD = "Activity/Sound/CoinPusherPassReward.mp3",
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

CoinPusherConfig.getThemeName = function()
        return "Activity_CoinPusher_Easter"        
end

return CoinPusherConfig