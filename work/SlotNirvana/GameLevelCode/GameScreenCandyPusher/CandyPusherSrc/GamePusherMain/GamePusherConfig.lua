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

GamePusherConfig.PusherRequestSaveId    = "SendOver" -- 推币机发送消息时存储本地

GamePusherConfig.EntityIndex            = 1000 -- 金币索引起始(碰撞Mask) 1001 ~ --
GamePusherConfig.TbFloorIndex           = 1    -- 地板索引起始(碰撞Mask) 1 ~ 99--
GamePusherConfig.PusherIndex            = 200  -- 推板索引起始(碰撞Mask) 200 ~ 300--

-- 自动掉落
GamePusherConfig.AutoWaitTime = 0.2
GamePusherConfig.AutoIntervalTime = 0.2

-- 推币机速度
GamePusherConfig.PusherSpeed            = 9     
GamePusherConfig.BaseReelSpeed          = 10  
GamePusherConfig.CoinsRainSpeed         = 15 
GamePusherConfig.PusherRainPullSpeed    = GamePusherConfig.PusherSpeed * 2
                
GamePusherConfig.Gravity                = -30
-- 墙道具时间最大值
GamePusherConfig.PropWallMaxCount       = 15
-- 剩余多少个之后不出墙道具
GamePusherConfig.DelWallLeftNum         = 10

-- comBo
GamePusherConfig.ComBoDelayTime         = 0.5
GamePusherConfig.ComBoLevel             = {10,20,50}


--质量系数(金币)
GamePusherConfig.RatioMass   = 1000000

--摩擦力系数
GamePusherConfig.RatioFrichtion          = 2          --金币
GamePusherConfig.PlatformFrichtion       = 0.4          --地板中间部分
GamePusherConfig.BorderPlatformFrichtion = 20         --地板两侧
GamePusherConfig.FrontFriction           = 0.05       --地板前部
GamePusherConfig.BackFriction            = 0.05        --地板后部
GamePusherConfig.MiddleFriction          = 0.6          --地板中部

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
        BIG = 50,
        SLOTS = 0,
}


--触发动画类型
GamePusherConfig.CoinEffectRefer   = {
        NORMAL          = "NORMAL",     
        COINSPILE        = "COINSPILE",           -- 随机掉落小金币堆玩法
        SLOTS           = "SLOTS",              -- 小老虎机
        BIGCOINS        = "BIGCOINS",           -- 掉落大金币       
        DROP            = "DROP",               -- 点击掉落金币
        WALL            = "WALL",               -- 两侧城墙
        SHAKE           = "SHAKE",              -- 大锤子凿桌面
        COINSRAIN       = "COINSRAIN",          -- 掉落金币雨玩法
        JACKPOT         = "JACKPOT",            -- Jackopt玩法 mini minor major grand
        COINSTOWER      = "COINSTOWER",         -- 掉落金币塔玩法
}

GamePusherConfig.SlotEffectRefer   = {
        BIGCOIN         = "BIG_COIN",      --掉落打金币
        HAMMER          = "HAMMER" ,        --锤子
}

--掉落金币类型
GamePusherConfig.CoinModelRefer   = {
        NORMAL          = "NORMAL",                          -- 普通金币
        BIG             = "BIG",                             -- 大金币
        SLOTS           = "SLOTS",                           -- 小老虎机金币
}



-- 各种金币相关属性 --
GamePusherConfig.CoinModelAtt   = {
        --基础金币
        ["NORMAL"] = { Name    = "NORMAL" , 
                Mass    = 150.0 * GamePusherConfig.RatioMass ,
                Friction= 0.3 * GamePusherConfig.RatioFrichtion, 
                Model   = "CandyPusher_C3b/CoinGold.c3b" , 
                Texture = "CandyPusher_C3b/NormalCoin.png" ,
                Scale   = 10 , 
                palne   = 6,
                PhysicSize = cc.p(3,0.5) },
      
        ["BIG"] = { Name    = "BIG" , 
                Mass    = 150.0 * GamePusherConfig.RatioMass,
                Friction= 0.3 * GamePusherConfig.RatioFrichtion, 
                Model   = "CandyPusher_C3b/CoinGiant.c3b" ,     
                Texture = "CandyPusher_C3b/NormalCoinBig.png" ,
                Scale   = 10 , 
                palne   = 6,
                PhysicSize = cc.p(6.5,1) },
        ["SLOTS"] = { Name    = "SLOTS" , 
                Mass    = 150.0 * GamePusherConfig.RatioMass,
                Friction= 0.3 * GamePusherConfig.RatioFrichtion, 
                Model   = "CandyPusher_C3b/CoinSlot.c3b" , 
                Texture = "CandyPusher_C3b/Slots.png" ,
                Scale   = 10 , 
                palne   = 6,
                PhysicSize = cc.p(4,0.5) },
}


-- 静态场景属性 --
GamePusherConfig.PlatformModelAtt = {
        Platform    = { Mass    = 0.0 ,  
                        Model   = "CandyPusher_C3b/taizi1203.c3b"      , 
                        Texture = "CandyPusher_C3b/MachineJackpot.png" ,
                        Friction= 0.3 * GamePusherConfig.PlatformFrichtion,
                        BorderFriction = 0.3 * GamePusherConfig.BorderPlatformFrichtion,
                        FrontFriction = 0.3 * GamePusherConfig.FrontFriction,
                        BackFriction = 0.3 * GamePusherConfig.BackFriction,
                        MiddleFriction = 0.3 * GamePusherConfig.MiddleFriction,
                        Scale   = 10 },

        Jackpot     = { Mass    = 0.0 ,  
                        Model   = "CandyPusher_C3b/beijingui.c3b"  , 
                        Texture = "CandyPusher_C3b/MachineJackpot.png" ,
                        Scale   = 10 },

        Background  = { Mass    = 0.0 ,  
                        Model   = "CandyPusher_C3b/dipian.c3b"    , 
                        Texture = "CandyPusher_C3b/MachineJackpot_dipian.png" ,
                        Scale   = 3500 },

        Pusher      = { Mass    = 0.0 ,  
                        Model   = "CandyPusher_C3b/zuoyi.c3b"      , 
                        Texture = "CandyPusher_C3b/MachineJackpot.png" ,
                        Scale   = 10 },

        Lifter      = { Mass    = 0.0 ,  
                        Model   = "CandyPusher_C3b/lifter.c3b"     , 
                        Texture = "CandyPusher_C3b/MachineJackpot.png" ,
                        Scale   = 10 },

        ReelUnit    = { Mass    = 0.0 ,  
                        Model   = "CandyPusher_C3b/reelunit.c3b"   , 
                        Texture = "" ,
                        Scale   = 10 },
}


-- 事件声明 --
GamePusherConfig.Event = {

        GamePusherAddPlayList                   = "GamePusherAddPlayList",
        GamePusherTriggerEffect                 = "GamePusherTriggerEffect",
        GamePusherEffectEnd                     = "GamePusherEffectEnd",
        GamePusherUpdateMainUI                  = "GamePusherUpdateMainUI",
        GamePusherSaveEntity                    = "GamePusherSaveEntity",
        GamePusherTestSaveData                  = "GamePusherTestSaveData",

        GamePusher_Sync_Dirty_Data                 = "GamePusher_Sync_Dirty_Data",  --同步脏数据
        
        GamePusherMainUI_UpdateLeftFreeCoinsTimes               = "GamePusherMainUI_UpdateLeftFreeCoinsTimes",

        GamePusherMainUI_UpdateOverTimes                        = "GamePusherMainUI_UpdateOverTimes",
        GamePusherMainUI_Rest_WallPos                           = "GamePusherMainUI_Rest_WallPos",
        GamePusherMainUI_Update_WheelJpBar                      = "GamePusherMainUI_Update_WheelJpBar",
        GamePusherMainUI_JumpLeftFreeCoinsTimes                 = "GamePusherMainUI_JumpLeftFreeCoinsTimes",

        

        GamePusherMainUI_updateTotaleCoins                      = "GamePusherMainUI_updateTotaleCoins"

        
}

GamePusherConfig.BlackFNT = "CandyPusher_C3b/font_arialblack.fnt"

-- 特效属性 --
GamePusherConfig.Effect = {
        Hammer          = {
                ID      = 1,
                Type    = "Model",   
                Model   = "CandyPusher_C3b/hammer.c3b" , 
                Texture = "CandyPusher_C3b/chuizi.png",
                Scale   = 5,
                ModelGuang = "CandyPusher_C3b/hammerguang.c3b",
                ModelBaozha= "CandyPusher_C3b/hammerbaozha.c3b" },
        FlashLight      = { 
                ID      = 2,
                Type    = "Model",  
                Model   = "CandyPusher_C3b/pian2.c3b" , 
                Texture = "CandyPusher_C3b/dengAn.png",
                Texture2 = "CandyPusher_C3b/dengC.png",
                Scale   = 10 },
        JackpotEffectPanel= {
                ID      = 3,
                Type    = "Model", 
                Model   = "CandyPusher_C3b/jackpotEffectPanel.c3b", 
                Texture = "CandyPusher_C3b/jackpotEffectPanel.png" ,
                Scale   = 10 },
        FrontEffectPanel= { 
                ID      = 4,
                Type    = "Model", 
                Model   = "CandyPusher_C3b/frontEffectPanel.c3b", 
                Texture = "CandyPusher_C3b/dengA.png" ,
                Scale   = 10 },
        TapHere= { 
                ID      = 5,
                Type    = "Model", 
                Model   = "CandyPusher_C3b/taphere.c3b", 
                Texture = "CandyPusher_C3b/tap_here.png" ,
                Scale   = 10 },

        
    
}

-- 台前 序列帧特效 --
GamePusherConfig.FrontEffectPic = {
        Idle    = {
                "CandyPusher_C3b/dengA_01.png",
                "CandyPusher_C3b/dengA_02.png",
                "CandyPusher_C3b/dengA_03.png",
                "CandyPusher_C3b/dengA_04.png",
                "CandyPusher_C3b/dengA_05.png",
                "CandyPusher_C3b/dengA_04.png",
                "CandyPusher_C3b/dengA_03.png",
                "CandyPusher_C3b/dengA_02.png",
                "CandyPusher_C3b/dengA_01.png"
        },
        IdleInterval = 0.5,
        Flash   = {
                "CandyPusher_C3b/dengB_01.png",
                "CandyPusher_C3b/dengB_02.png",
                "CandyPusher_C3b/dengB_03.png",
                "CandyPusher_C3b/dengB_04.png",
                "CandyPusher_C3b/dengB_05.png",
                "CandyPusher_C3b/dengB_06.png",
                "CandyPusher_C3b/dengB_05.png",
                "CandyPusher_C3b/dengB_04.png",
                "CandyPusher_C3b/dengB_03.png",
                "CandyPusher_C3b/dengB_02.png",
        },
        FlashInterval = 0.1,
}


-- jackpot 序列帧特效 --
GamePusherConfig.JackPotEffectPic = {
        Idle    = {
                "CandyPusher_C3b/dengB1.png",
                "CandyPusher_C3b/dengB2.png",
                "CandyPusher_C3b/dengB3.png",
                "CandyPusher_C3b/dengB2.png",
                "CandyPusher_C3b/dengB1.png"
        },
        IdleInterval = 0.5,
        Flash   = {
                "CandyPusher_C3b/dengB1.png",
                "CandyPusher_C3b/dengB2.png",
                "CandyPusher_C3b/dengB3.png",
                "CandyPusher_C3b/dengB2.png",
                "CandyPusher_C3b/dengB1.png"
        },
        FlashInterval = 0.1
}

-- 调试面板按钮图片 --
GamePusherConfig.debugBtnRes      = "CandyPusher_C3b/btn.png"


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
        MainUI          = "CandyPusherMainUI/CoinPusher_MainLayer.csb",
        SelectUI        = "CandyPusherMainUI/CoinPusher_Chapter.csb",
        SelectUIItem    = "CandyPusherMainUI/CoinPusher_Chapter_Item1.csb",
        EntryNode       = "CandyPusherMainUI/CoinPusher_GameSceneUI.csb",
        DeBugLayer      = "CandyPusherMainUI/DesktopDebug.csb",
        LeftCoinsCsb    = "CandyPusher_mianfei_jinbi.csb",
        JpLogoCsbCsb    = "CandyPusher_jackpot_logo.csb",
        ShowSocreCsb    = "CandyPusher_coins.csb",
        totalWinCsb     = "CandyPusher_TotalWin.csb",
        BonusSpinCsb    = "CandyPusher_BonusSpin.csb",
        DropCoinsLight  = "CandyPusherMainUI/CoinPusher_DG.csb",
        
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

-- 推板
GamePusherConfig.PusherPosVec3 = cc.vec3(0.0, 0.0, -11.5 )
GamePusherConfig.PusherDisVec3 = {
        PUSHER =  cc.vec3(0.0, 0.0, 26 ),
        ORI = cc.vec3(0.0, 0.0, 0.5),
}
GamePusherConfig.PusherStatus = {
        Idle =  1,
        Push =  2,
        Pull =  3,
}


----声音
GamePusherConfig.SoundConfig = {
       
        COIN_PUSH_DOWN          = "CandyPusherSounds/CoinPusherCoinDown.mp3",
        WallUp                  = "CandyPusherSounds/sound_CandyPusher_WallUp.mp3",    
}

--弹窗配置
GamePusherConfig.PopViewConfig = {
        JACKPOT = {
                Path = " ",-- 弹框资源路径
        }
}


-- UI脚本路径配置
GamePusherConfig.ViewPathConfig = 
{
        Main             = "CandyPusherSrc.GamePusherMain.GamePusherMainLayer",                                -- 主界面
        MainUI           = "CandyPusherSrc.GamePusherMain.GamePusherMainUI",
        WallBar          = "CandyPusherSrc.GamePusherMain.GamePusherWallBarView",
        ShowView         = "CandyPusherSrc.GamePusherMain.GamePusherShowView",
        Effect           = "CandyPusherSrc.GamePusherMain.GamePusherEffect",
        DesktopDebug     = "CandyPusherSrc.GamePusherMain.GamePusherDesktopDebug",
        Debug            = "CandyPusherSrc.GamePusherMain.GamePusherDebug",
        
        
        
}

-- 玩法数据脚本路径
GamePusherConfig.ActionDataPathConfig = 
{
        BaseActionData    = "CandyPusherSrc.GamePusherData.GamePusherBaseActionData",                     
        PopCoinViewData   = "CandyPusherSrc.GamePusherData.GamePusherPopCoinViewData",
        CoinsPileData     = "CandyPusherSrc.GamePusherData.GamePusherCoinsPileData",
        SlotData          = "CandyPusherSrc.GamePusherData.CoinPusherSlotData",
        WallData          = "CandyPusherSrc.GamePusherData.GamePusherWallData",
        CoinsRainData     = "CandyPusherSrc.GamePusherData.GamePusherCoinsRainData",
        JackData          = "CandyPusherSrc.GamePusherData.GamePusherJackData",
        CoinsTowerData    = "CandyPusherSrc.GamePusherData.GamePusherCoinsTowerData",
}

GamePusherConfig.ConfigPath = "CandyPusherSrc/GamePusherMain/GamePusherInitDiskConfig.json"             -- 初始盘面配置文件

-- 随机除大金币之外金币角度
GamePusherConfig.randomCoinRotate = function(  )
        local nRotateX =  math.random(0, 360)
        local nRotateY =  0 
        local nRotateZ =  math.random(30, 150)
        return cc.vec3(nRotateX, nRotateY, nRotateZ)
end

GamePusherConfig.BigCoinRotate = cc.vec3(-90, 0, 0)
GamePusherConfig.CoinsPileDropCenter = cc.vec3( 0, 10.0, -15)

-- 金币雨相关
GamePusherConfig.CoinsRainMaxDrop = 300  -- 最大掉落个数
GamePusherConfig.CoinsRainMaxTimes = 20    -- 最大掉落时间
GamePusherConfig.CoinsRainMinTimes = 18    -- 最小掉落时间
GamePusherConfig.CoinsRainDropCenter = cc.vec3( 0, 10.0, -15)
GamePusherConfig.CoinsRainRotate = function(  )
        local nRotateX =  math.random(0, 0)
        local nRotateY =  math.random(0, 0) 
        local nRotateZ =  math.random(0, 0)
        return cc.vec3(nRotateX, nRotateY, nRotateZ)
end

-- 金币塔相关
GamePusherConfig.CoinTowerAnimStates= {
        TablePush = 0,
        TowerDrop = 1
} 

-- 初始盘面配置 DesktopDebug
GamePusherConfig.DeskTopConfig = {
        NORMAL        = 30,
        RANDOM        = 2,
        BIG           = 1,
}

-- 信号块值，外部使用 --
GamePusherConfig.slotsSymbolType  ={
        Wall      = 101,
        Shake     = 102,
        BigCoin   = 103,
        CoinTower = 104,
        CoinRain  = 105,
        CoinPile  = 106,
        Jackpot   = 107,
        Grand     = 204,
        Major     = 203,
        Minor     = 202,
        Mini      = 201,
}


-- 信号块纹理属性 --
GamePusherConfig.SymbolRes  ={

        [101] = { Name = "墙Wall" , Path = "Socre_CandyPusher_Wall.csb",isSpine = false},
        [102] = { Name = "锤子Shake" , Path = "Socre_CandyPusher_Shake.csb",isSpine = false},
        [103] = { Name = "大金币bigCoin" , Path = "Socre_CandyPusher_BigCoin.csb",isSpine = false},
        [104] = { Name = "金币塔coinTower" , Path = "Socre_CandyPusher_CoinTowe.csb",isSpine = false},
        [105] = { Name = "金币雨coinRain" , Path = "Socre_CandyPusher_CoinRain.csb",isSpine = false},
        [106] = { Name = "小金币堆coinPile" , Path = "Socre_CandyPusher_CoinPile.csb",isSpine = false},

        [107] = { Name = "jackpot玩法信号:无资源"},

        [204] = { Name = "Grand" , Path = "Socre_CandyPusher_Grand.csb",isSpine = false},
        [203] = { Name = "Major" , Path = "Socre_CandyPusher_Major.csb",isSpine = false},
        [202] = { Name = "Minor" , Path = "Socre_CandyPusher_Minor.csb",isSpine = false},
        [201] = { Name = "Mini" , Path = "Socre_CandyPusher_Mini.csb",isSpine = false},
}
    
-- Slot轮盘相关 --
GamePusherConfig.ReelRollSpeed  = -40
GamePusherConfig.ReelJumpUpTime  = 0.3
GamePusherConfig.ReelTopPos     = 7.2
GamePusherConfig.ReelBottomPos  = -7.2
GamePusherConfig.ReelStopPos    = 0
GamePusherConfig.ReelTableCenter= cc.vec3( 0 , 11.8 , -23.7 )
GamePusherConfig.ReelUnitCenter = { 
        cc.vec3(-7.2 , 0, 0 ) ,
        cc.vec3(   0 , 0, 0 ) ,
        cc.vec3( 7.2 , 0, 0 ) ,
}
GamePusherConfig.ReelUnitConfig = {
        {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0,  7.2 , 0 ) },
        {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0 , 7.2 , 0 ) },
        {  cc.vec3(   0 , 0 , 0 ) ,cc.vec3(   0 , 7.2 , 0 ) },
}

GamePusherConfig.ReelJumpConfig = {
        { DelayTime = 0,   DestPosY = 2},
        { DelayTime = 0.1, DestPosY = 2},
        { DelayTime = 0.2, DestPosY = 2},
}

-- 假滚数据 --
GamePusherConfig.ReelDataConfig = {
        { 101,102,103,104,105,106,201,202,203,204,101,102,103,104,105,106,201,202,203,204},
        { 101,102,103,104,105,106,201,202,203,204,101,102,103,104,105,106,201,202,203,204},
        { 101,102,103,104,105,106,201,202,203,204,101,102,103,104,105,106,201,202,203,204},
}

-- 滚动停止间隔 --
GamePusherConfig.ReelStopOffset = { 9,12,15 }


GamePusherConfig.ReelDataNums   = { 
        table.nums(GamePusherConfig.ReelDataConfig[1] ) , 
        table.nums(GamePusherConfig.ReelDataConfig[2] ) ,
        table.nums(GamePusherConfig.ReelDataConfig[3] ) 
}

-- 滚轴指针 暂且随机一个值 --
GamePusherConfig.ReelDataIndexPointer = {
        [1] = math.random(1, 10),-- grand
        [2] = math.random(1, 10),
        [3] = math.random(1, 10),
}

GamePusherConfig.ReelStatus = {
        Idle    = 0,
        JumpUp  = 1,
        Running = 2,
        JumpDown= 3,
        Stoping = 4
}

GamePusherConfig.SlotType = {
        ["FREESPIN"] = 1,
        ["COINS"] = 2,
        ["HUMMER"] = 3,
}


return GamePusherConfig