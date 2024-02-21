--[[
    CoinPusher Config
    tm
]]
local GamePusherConfig  = {}

-- 调试状态 
GamePusherConfig.Debug          = false            --debug界面
GamePusherConfig.DebugCoinCount = false            --debug界面
GamePusherConfig.FixCarmer      = true             --固定视角     

--------------------------------推币机参数 START-------------------------------------

GamePusherConfig.PusherRequestSaveId             = "SendOver" -- 推币机发送消息时存储本地

-- 推币机速度
GamePusherConfig.PusherSpeed = 5     
GamePusherConfig.BonusPusherSpeed = 10  
                
GamePusherConfig.Gravity     = -30
-- 道具进度最大值
GamePusherConfig.PropWallMaxCount     = 15

--质量系数(金币)
GamePusherConfig.RatioMass   = 1000000

--摩擦力系数
GamePusherConfig.RatioFrichtion          = 2          --金币
GamePusherConfig.PlatformFrichtion       = 0.4          --地板中间部分
GamePusherConfig.BorderPlatformFrichtion = 15         --地板两侧
GamePusherConfig.FrontFriction           = 0.1       --地板前部
GamePusherConfig.BackFriction            = 0.05        --地板后部
GamePusherConfig.MiddleFriction          = 0.75          --地板中部

GamePusherConfig.BackPushRestitution     = 0.4        --弹性系数  地板后部 , 推的板子
GamePusherConfig.CoinsRestitutionInit    = 0.003       --弹性系数  金币(初始化时)
GamePusherConfig.CoinsRestitution        = 0.556      --弹性系数  金币(游戏正式开始时)
--------------------------------推币机参数 END-------------------------------------     

--结束倒计时
GamePusherConfig.OverTimes = 12
GamePusherConfig.FirstShowOverTimes = 12
GamePusherConfig.SecondShowOverTimes = 6

GamePusherConfig.ShowTipTimes = 11
GamePusherConfig.FirstShowTipTimes = 11
GamePusherConfig.SecondShowTipTimes = 3
--掉落实体类型
GamePusherConfig.EntityType   = {       
        COIN = 1
}

--道具id类型 0：震动 ，1墙， 2大金币 
GamePusherConfig.PropType   = {       
        WALL            = 1,
        SHAKE           = 0,
        BIGCOINS        = 2,
}


--掉落实体类型
GamePusherConfig.EntityDropType   = {
        WIN  = 1,
        LOSE = 2,
}

--收集金币对应进度
GamePusherConfig.CollectCoinsProgress   = {       
        NORMAL = 1,
        BIG = 10,
}

--触发动画类型
GamePusherConfig.CoinEffectRefer   = {
        NORMAL          = "NORMAL",
        JACKPOT         = "JACKPOT",
        RANDOM          = "RANDOM",
        BIG             = "BIG",
        DROP            = "DROP",         --点击掉落金币
}

GamePusherConfig.SlotEffectRefer   = {
        BIGCOIN         = "BIG_COIN",      --掉落打金币
        HAMMER          = "HAMMER" ,        --锤子
}

--掉落金币类型
GamePusherConfig.CoinModelRefer   = {
        NORMAL          = "NORMAL",                          -- 普通金币
        JACKPOT         = "JACKPOT",                         -- 转盘奖励
        RANDOM          = "RANDOM",                          -- 随机掉落金币
        BIG             = "BIG",                             -- 大金币
}

GamePusherConfig.CoinPreCreateConfig = {
        NORMAL          = 10,
        JACKPOT         = 10,
        RANDOM          = 10,
        BIG             = 5,
}

-- 各种金币相关属性 --
GamePusherConfig.CoinModelAtt   = {
        --基础金币
        ["NORMAL"] = { Name    = "NORMAL" , 
                Mass    = 150.0 * GamePusherConfig.RatioMass ,
                Friction= 0.3 * GamePusherConfig.RatioFrichtion, 
                Model   = "CoinPusher_C3b/CoinGold_youhuamax.c3b" , 
                Texture = "CoinPusher_C3b/NormalCoin.png" ,
                Scale   = 10 , 
                palne   = 6,
                PhysicSize = cc.p(3,0.5) },
        ["JACKPOT"] = { Name    = "JACKPOT" , 
                Mass    = 150.0 * GamePusherConfig.RatioMass,
                Friction= 0.3 * GamePusherConfig.RatioFrichtion, 
                Model   = "CoinPusher_C3b/CoinSlot.c3b"  , 
                Texture = "CoinPusher_C3b/CoinCircus_jackpot.png" ,
                Scale   = 10 , 
                palne   = 6,
                PhysicSize = cc.p(4,0.5) },
        ["RANDOM"] = { Name    = "RANDOM" , 
                Mass    = 150.0 * GamePusherConfig.RatioMass ,
                Friction= 0.3 * GamePusherConfig.RatioFrichtion, 
                Model   = "CoinPusher_C3b/CoinSlot.c3b" , 
                Texture = "CoinPusher_C3b/CoinCircus_random.png" ,
                Scale   = 10 , 
                palne   = 6,
                PhysicSize = cc.p(4,0.5) },
        ["BIG"] = { Name    = "BIG" , 
                Mass    = 150.0 * GamePusherConfig.RatioMass,
                Friction= 0.3 * GamePusherConfig.RatioFrichtion, 
                Model   = "CoinPusher_C3b/CoinGiant.c3b" ,     
                Texture = "CoinPusher_C3b/NormalCoinBig.png" ,
                Scale   = 10 , 
                palne   = 6,
                PhysicSize = cc.p(6.5,1) }
}

-- 各种道具属性 --
GamePusherConfig.ItemModelAtt  = {
   
}

-- 静态场景属性 --
GamePusherConfig.PlatformModelAtt = {
    Platform    = { Mass    = 0.0 ,  
                    Model   = "CoinPusher_C3b/taizi0427.c3b"      , 
                    Texture = "CoinPusher_C3b/MachineJackpot.png" ,
                    Friction= 0.3 * GamePusherConfig.PlatformFrichtion,
                    BorderFriction = 0.3 * GamePusherConfig.BorderPlatformFrichtion,
                    FrontFriction = 0.3 * GamePusherConfig.FrontFriction,
                    BackFriction = 0.3 * GamePusherConfig.BackFriction,
                    MiddleFriction = 0.3 * GamePusherConfig.MiddleFriction,
                    Scale   = 10 },
    Background  = { Mass    = 0.0 ,  
                    Model   = "CoinPusher_C3b/dipian.c3b"    , 
                    Texture = "CoinPusher_C3b/MachineJackpot_dipian.png" ,
                    Scale   = 35 },
    Pusher      = { Mass    = 0.0 ,  
                    Model   = "CoinPusher_C3b/zuoyi.c3b"      , 
                    Texture = "CoinPusher_C3b/MachineJackpot.png" ,
                    Scale   = 1000 },
    Lifter      = { Mass    = 0.0 ,  
                    Model   = "CoinPusher_C3b/lifter.c3b"     , 
                    Texture = "CoinPusher_C3b/MachineJackpot.png" ,
                    Scale   = 10 }
}


-- 事件声明 --
GamePusherConfig.Event = {

        GamePusherDropCoins                     = "GamePusherDropCoins",
        GamePusherTriggerEffect                 = "GamePusherTriggerEffect",
        GamePusherEffectEnd                     = "GamePusherEffectEnd",
        GamePusherSaveEntity                    = "GamePusherSaveEntity",
        GamePusherUpdateMainUI                  = "GamePusherUpdateMainUI",

        GamePusherTestSaveData                  = "GamePusherTestSaveData",

        GamePusher_Sync_Dirty_Data                 = "GamePusher_Sync_Dirty_Data",  --同步脏数据

        GamePusherUseProp                       = "GamePusherUseProp",

        GamePusherMainUI_UpdateLeftFreeCoinsTimes               = "GamePusherMainUI_UpdateLeftFreeCoinsTimes",
        GamePusherMainUI_UpdateProgressCount                    = "GamePusherMainUI_UpdateProgressCount",
        GamePusherMainUI_UpdateProp_BigCoins                    = "GamePusherMainUI_UpdateProp_BigCoins",
        GamePusherMainUI_UpdateProp_Wall                        = "GamePusherMainUI_UpdateProp_Wall",
        GamePusherMainUI_UpdateProp_Shake                       = "GamePusherMainUI_UpdateProp_Shake",
        GamePusherMainUI_PropSpecTouchEnabled                   = "GamePusherMainUI_PropSpecTouchEnabled",
        GamePusherMainUI_PropTouchEnabled                       = "GamePusherMainUI_PropTouchEnabled",
        GamePusherMainUI_UpdateJPCollect                        = "GamePusherMainUI_UpdateJPCollect",
        GamePusherMainUI_ShowWheelView                          = "GamePusherMainUI_ShowWheelView",
        GamePusherMainUI_UpdateOverTimes                        = "GamePusherMainUI_UpdateOverTimes",
        GamePusherMainUI_SetProgressViewVisible                 = "GamePusherMainUI_SetProgressViewVisible",
        GamePusherMainUI_SetPropViewVisible                     = "GamePusherMainUI_SetPropViewVisible",
        GamePusherMainUI_SetLeftFreeCoinsViewVisible            = "GamePusherMainUI_SetLeftFreeCoinsViewVisible",
        GamePusherMainUI_PlayPropViewAnim                       = "GamePusherMainUI_PlayPropViewAnim",
        GamePusherMainUI_PlayLeftFreeCoinsViewAnim              = "GamePusherMainUI_PlayLeftFreeCoinsViewAnim",
        GamePusherMainUI_PlayProgressViewAnim                   = "GamePusherMainUI_PlayProgressViewAnim",
        GamePusherMainUI_updatePropPrice                        = "GamePusherMainUI_updatePropPrice",
        GamePusherMainUI_PlayBaoXiangAnim                       = "GamePusherMainUI_PlayBaoXiangAnim",
        GamePusherMainUI_PlayPropCollectJpCoinsAnim             = "GamePusherMainUI_PlayPropCollectJpCoinsAnim",
        GamePusherMainUI_PlayTopCoinsViewAnim                   = "GamePusherMainUI_PlayTopCoinsViewAnim",
        GamePusherMainUI_setTopCoinsViewVisible                 = "GamePusherMainUI_setTopCoinsViewVisible",
        GamePusherMainUI_UpdateJPCollectDarkImg                 = "GamePusherMainUI_UpdateJPCollectDarkImg",
        GamePusherMainUI_Rest_WallPos                           = "GamePusherMainUI_Rest_WallPos",
        GamePusherMainUI_Update_WheelJpBar                      = "GamePusherMainUI_Update_WheelJpBar",
        GamePusherMainUI_JumpLeftFreeCoinsTimes                 = "GamePusherMainUI_JumpLeftFreeCoinsTimes",
        GamePusherMainUI_PlayProp_WallLoadingAni                = "GamePusherMainUI_PlayProp_WallLoadingAni",
        GamePusherMainUI_PlayPropCollectJpCoinsTriggerAnim      = "GamePusherMainUI_PlayPropCollectJpCoinsTriggerAnim",
        GamePusherMainUI_QuickClosePropTip                      = "GamePusherMainUI_QuickClosePropTip",
        
        GamePusherMainUI_CollectData                            = "GamePusherMainUI_CollectData",
        
        GamePusherEffect_HammerPlayEnd                          = "GamePusherEffect_HammerPlayEnd",
        GamePusherEffect_BigCoinsPlayEnd                        = "GamePusherEffect_BigCoinsPlayEnd",

        GamePusherMainUI_PropTip                                = "GamePusherMainUI_PropTip"

}

-- 特效属性 --
GamePusherConfig.Effect = {
        Hammer          = {
                ID      = 1,
                Type    = "Model",   
                Model   = "CoinPusher_C3b/hammer.c3b" , 
                Texture = "CoinPusher_C3b/chuizi.png",
                Scale   = 5,
                ModelGuang = "CoinPusher_C3b/hammerguang.c3b",
                ModelBaozha= "CoinPusher_C3b/hammerbaozha.c3b" },
        FlashLight      = { 
                ID      = 2,
                Type    = "Model",  
                Model   = "CoinPusher_C3b/pian2.c3b" , 
                Texture = "CoinPusher_C3b/dengAn.png",
                Texture2 = "CoinPusher_C3b/dengC.png",
                Scale   = 10 },
        FrontEffectPanel= { 
                ID      = 4,
                Type    = "Model", 
                Model   = "CoinPusher_C3b/frontEffectPanel.c3b", 
                Texture = "CoinPusher_C3b/dengA.png" ,
                Scale   = 10 },
        TapHere= { 
                ID      = 5,
                Type    = "Model", 
                Model   = "CoinPusher_C3b/taphere.c3b", 
                Texture = "CoinPusher_C3b/tap_here.png" ,
                Scale   = 10 },
    
}

-- 台前 序列帧特效 --
GamePusherConfig.FrontEffectPic = {
        Idle    = {
                "CoinPusher_C3b/dengA_01.png",
                "CoinPusher_C3b/dengA_02.png",
                "CoinPusher_C3b/dengA_03.png",
                "CoinPusher_C3b/dengA_04.png",
                "CoinPusher_C3b/dengA_05.png",
                "CoinPusher_C3b/dengA_04.png",
                "CoinPusher_C3b/dengA_03.png",
                "CoinPusher_C3b/dengA_02.png",
                "CoinPusher_C3b/dengA_01.png"
        },
        IdleInterval = 0.5,
        Flash   = {
                "CoinPusher_C3b/dengB_01.png",
                "CoinPusher_C3b/dengB_02.png",
                "CoinPusher_C3b/dengB_03.png",
                "CoinPusher_C3b/dengB_04.png",
                "CoinPusher_C3b/dengB_05.png",
                "CoinPusher_C3b/dengB_06.png",
                "CoinPusher_C3b/dengB_05.png",
                "CoinPusher_C3b/dengB_04.png",
                "CoinPusher_C3b/dengB_03.png",
                "CoinPusher_C3b/dengB_02.png",
        },
        FlashInterval = 0.1,
}


-- 调试面板按钮图片 --
GamePusherConfig.debugBtnRes      = "CoinPusher_C3b/btn.png"


--玩法状态
GamePusherConfig.PlayState   = {
        IDLE    = 1,    --未开始
        PLAYING = 2,    --播放状态
        DONE    = 3,    --结束
}



--章节状态
GamePusherConfig.PlanesState = {
        COMPLETED = "COMPLETED",
        PLAY      = "PLAY",
        LOCKD     =  "LOCKD",
}

--CSB
GamePusherConfig.UICsbPath = {
        MainUI          = "CoinPusher/CoinPusher_MainLayer.csb",
        SelectUI        = "CoinPusher/CoinPusher_Chapter.csb",
        SelectUIItem    = "CoinPusher/CoinPusher_Chapter_Item1.csb",
        EntryNode       = "CoinPusher/CoinPusher_GameSceneUI.csb",
        DeBugLayer      = "CoinPusher/DesktopDebug.csb",
        DropCoinsLight  = "CoinPusher/CoinPusher_DG.csb",
        LeftCoinsCsb    = "CoinCircus_mianfei_jinbi.csb",
        OverLeftCsb     = "CoinCircus_daojishi.csb",
        OverLeftLabCsb     = "CoinCircus_daojishi_shuzi.csb",
        
        ProgressCsb     = "CoinCircus_jindutiao.csb",
        SecondPayCsb    = "CoinCircus_shang_ui.csb",
        ComboCsb        = "CoinPusher/CoinPusher_tanzi.csb",
        JpCollectAniCsb = "CoinCircus_daoju_shouji_0.csb",
        CollectLightCsb = "CoinCircus_daoju_shouji_L.csb",
        WheelDark       = "CoinCircus_jackpot_zhuanpan_dark.csb",
}

--SPINE
GamePusherConfig.UISpinePath = {
        WheelMain1      = "CoinCircus_juese",
        WheelMain2      = "CoinCircus_juese2",
}

--combo 图片路径
GamePusherConfig.ComboEffectPng = {
        "CoinPusher_C3b/CoinPusherCoinAttack1.png",
        "CoinPusher_C3b/CoinPusherCoinAttack2.png", 
        "CoinPusher_C3b/CoinPusherCoinAttack3.png",
        "CoinPusher_C3b/CoinPusherCoinAttack4.png",
        "CoinPusher_C3b/CoinPusherCoinAttack5.png",
        "CoinPusher_C3b/CoinPusherCoinAttack6.png"
}
GamePusherConfig.ComboFreshDt = 3

--mainUI zorder
GamePusherConfig.MainUIZorder = {
        WinLight  = 100,
        Combo     = 200,
        ViewLayer = 300,
}

---BUFF
GamePusherConfig.BuffResPath = 
{
  
}
--buff 监听倒计时  times/BuffUpdateTime
GamePusherConfig.BuffUpdateTime = 0
GamePusherConfig.TapUpdateTime  = 10.0

GamePusherConfig.PusherDisVec3 = 
{
        PUSHER =  cc.vec3(0.0, 0.0, 6 ),
        ORI = cc.vec3(0.0, 0.0, 0.5),

}

----声音
GamePusherConfig.SoundConfig = {
        HAMMER_DOWN             = "CoinCircusSounds/CoinPusherHammer.mp3",
        SEPCIAL_COIN_DOWN       = "CoinCircusSounds/CoinPusherSpecialCoinDown.mp3",
        BIG_COIN_DOWN           = "CoinCircusSounds/CoinPusherBigCoinDown.mp3",
        COIN_PUSH_DOWN          = "CoinCircusSounds/CoinPusherCoinDown.mp3",
        SPECIAL_PUSH_DOWN       = "CoinCircusSounds/CoinPusherSpecialCoinPush.mp3",
        REWARD                  = "CoinCircusSounds/CoinPusherReward.mp3",
        COMBO                   = "CoinCircusSounds/CoinPusherCombo.mp3",
        NORMALCOINDOWN          = "CoinCircusSounds/CoinPusherNormalCoinDown.mp3",
}

--弹窗配置
GamePusherConfig.PopViewConfig = {
        JACKPOT = {
                Type = "JACKPOT",
                Path = " ",-- 弹框资源路径
        }
}


-- UI脚本路径配置
GamePusherConfig.ViewPathConfig = 
{
        Main             = "CoinCircusSrc.GamePusherMain.GamePusherMain",                                -- 主界面
        MainUI           = "CoinCircusSrc.GamePusherMain.GamePusherMainUI",
        ShowView         = "CoinCircusSrc.GamePusherMain.GamePusherShowView",
        Effect           = "CoinCircusSrc.GamePusherMain.GamePusherEffect",
        PropView         = "CoinCircusSrc.GamePusherMain.GamePusherPropView",
        PropTipView      = "CoinCircusSrc.GamePusherMain.GamePusherPropTipView",
        PropLoadingView  = "CoinCircusSrc.GamePusherMain.GamePusherPropLoadingBarView",
        WheelView        = "CoinCircusSrc.GamePusherMain.Wheel.CoinCircusWheelView",
        WheelAction      = "CoinCircusSrc.GamePusherMain.Wheel.CoinCircusWheelAction",
        WheelJpBar       = "CoinCircusSrc.GamePusherMain.Wheel.CoinCircusWheelJackPotBarView",
        DesktopDebug     = "CoinCircusSrc.GamePusherMain.GamePusherDesktopDebug",
        Debug            = "CoinCircusSrc.GamePusherMain.GamePusherDebug",
        
}

-- 玩法数据脚本路径
GamePusherConfig.ActionDataPathConfig = 
{
        BaseActionData    = "CoinCircusSrc.GamePusherData.GamePusherBaseActionData",                     
        DropCoinData      = "CoinCircusSrc.GamePusherData.GamePusherDropCoinData",
        PopCoinViewData   = "CoinCircusSrc.GamePusherData.GamePusherPopCoinViewData",
        RandomData        = "CoinCircusSrc.GamePusherData.GamePusherRandomData",
}

GamePusherConfig.ConfigPath = "CoinCircusSrc/GamePusherMain/GamePusherInitDiskConfig.json"             -- 初始盘面配置文件

-- 随机除大金币之外金币角度
GamePusherConfig.randomCoinRotate = function(  )
        local nRotateX =  math.random(0, 360)
        local nRotateY =  0 -- math.random(-180, 180)
        local nRotateZ =  math.random(30, 150)
        return cc.vec3(nRotateX, nRotateY, nRotateZ)
end

GamePusherConfig.BigCoinRotate = cc.vec3(-90, 0, 0)
GamePusherConfig.SpecialCoinV3 = cc.vec3( 0, 10.0, -15)

-- 初始盘面配置 DesktopDebug
GamePusherConfig.DeskTopConfig = {
        NORMAL        = 30,
        JACKPOT       = 5,
        RANDOM        = 2,
        BIG           = 1,
}



return GamePusherConfig