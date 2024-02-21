-- 定义一些场景上物体的属性
local CastFishingSceneConfig = {}

CastFishingSceneConfig.ShapeType = {
    Circular  = 1,     --圆形    
    Rectangle = 2,     --长方形  
}
CastFishingSceneConfig.FishLevelType = {
    Coins   = 1,     --分值
    Wild    = 2,     --wild
    Jackpot = 3,     --奖池
}
CastFishingSceneConfig.FishKindType = {
    Coins   = "credit",     --分值
    Wild    = "wild",       --wild
    Jackpot = "jackpot",    --奖池
}

CastFishingSceneConfig.Fish = {
    {
        id              = 1,                                                         --鱼的Id标识  服务器使用
        kind            = CastFishingSceneConfig.FishKindType.Coins,                 --鱼的字符标识 服务器使用
        level           = CastFishingSceneConfig.FishLevelType.Coins,                --鱼的等级
        codePath        = "CodeCastFishingSrc.CastFishingFish.CastFishingFishObj",   --代码路径
        csbPath         = "CastFishing_Fish_1.csb",                                  --工程路径
        spinePath       = "Socre_CastFishing_5",                                     --骨骼路径
        resDirection    = 1,                                                         --资源朝向 (-1:左|下, 1:右|上)
        speed           = 2,                                                         --游动速度(每帧)
        --[[
            形状:
            {
                [1] = 1,   --圆形
                [2] = 50,  --半径
            },
            {
                [1] = 2,   --长方形
                [2] = 50,  --宽
                [3] = 50,  --高
            },
        ]]
        shape           = {CastFishingSceneConfig.ShapeType.Circular, 50},                                                   
    },
    {
        id              = 2,     
        kind            = CastFishingSceneConfig.FishKindType.Coins,
        level           = CastFishingSceneConfig.FishLevelType.Coins,                                                   
        codePath        = "CodeCastFishingSrc.CastFishingFish.CastFishingFishObj",   
        csbPath         = "CastFishing_Fish_1.csb",                                  
        spinePath       = "Socre_CastFishing_6",   
        resDirection    = 1,   
        speed           = 2,   
        shape           = {CastFishingSceneConfig.ShapeType.Circular, 50},                                              
    },
    {
        id              = 3,   
        kind            = CastFishingSceneConfig.FishKindType.Coins,
        level           = CastFishingSceneConfig.FishLevelType.Coins,                                                              
        codePath        = "CodeCastFishingSrc.CastFishingFish.CastFishingFishObj",   
        csbPath         = "CastFishing_Fish_1.csb",                                  
        spinePath       = "Socre_CastFishing_8",       
        resDirection    = 1,   
        speed           = 2,  
        shape           = {CastFishingSceneConfig.ShapeType.Circular, 50},                                            
    },
    {
        id              = 4,   
        kind            = CastFishingSceneConfig.FishKindType.Wild,
        level           = CastFishingSceneConfig.FishLevelType.Wild,                                                             
        codePath        = "CodeCastFishingSrc.CastFishingFish.CastFishingFishObj",   
        csbPath         = "CastFishing_Fish_4.csb",                                  
        spinePath       = "Socre_CastFishing_7",   
        resDirection    = 1, 
        speed           = 3,    
        shape           = {CastFishingSceneConfig.ShapeType.Circular, 50},                                                    
    },
    {
        id              = 5,    
        kind            = CastFishingSceneConfig.FishKindType.Jackpot,
        level           = CastFishingSceneConfig.FishLevelType.Jackpot,                                                            
        codePath        = "CodeCastFishingSrc.CastFishingFish.CastFishingFishObj",   
        csbPath         = "CastFishing_Fish_5.csb",                                  
        spinePath       = "Socre_CastFishing_9",  
        resDirection    = 1,   
        speed           = 4,    
        shape           = {CastFishingSceneConfig.ShapeType.Circular, 50},                                                  
    },
}

CastFishingSceneConfig.Bullet = {
    -- free使用的子弹
    {
        id                  = 1,                                                         
        codePath            = "CodeCastFishingSrc.CastFishingBattery.CastFishingBulletObj",   
        csbPath             = "Socre_CastFishing_bullet_1.csb",                                  
        spinePath           = "CastFishingPD",   
        spineIdle           = "paodan",                                                       --spine的静帧时间线
        resDirection        = 1, 
        speed               = 10,   
        autoDisappearTime   = -1,                                                             --自动消失时间 (-1:不自动消失 | >=0 消失时间)
        shape               = {CastFishingSceneConfig.ShapeType.Circular, 30},                                                    
    },
    -- 2 ~5 是bonus四个等级使用的子弹
    {
        id                  = 2,                                                         
        codePath            = "CodeCastFishingSrc.CastFishingBattery.CastFishingBulletObj",   
        csbPath             = "Socre_CastFishing_bullet_1.csb",                                  
        spinePath           = "CastFishingPD",   
        spineIdle           = "paodan",                                                      
        resDirection        = 1, 
        speed               = 10,   
        autoDisappearTime   = -1,                                                            
        shape               = {CastFishingSceneConfig.ShapeType.Circular, 30},                                                    
    },
    {
        id                  = 3,                                                         
        codePath            = "CodeCastFishingSrc.CastFishingBattery.CastFishingBulletObj",   
        csbPath             = "Socre_CastFishing_bullet_1.csb",                                  
        spinePath           = "CastFishingPD",   
        spineIdle           = "paodan",                                                      
        resDirection        = 1, 
        speed               = 10,   
        autoDisappearTime   = -1,                                                            
        shape               = {CastFishingSceneConfig.ShapeType.Circular, 30},                                                    
    },
    {
        id                  = 4,                                                         
        codePath            = "CodeCastFishingSrc.CastFishingBattery.CastFishingBulletObj",   
        csbPath             = "Socre_CastFishing_bullet_1.csb",                                  
        spinePath           = "CastFishingPD",   
        spineIdle           = "paodan",                                                      
        resDirection        = 1, 
        speed               = 10,   
        autoDisappearTime   = -1,                                                            
        shape               = {CastFishingSceneConfig.ShapeType.Circular, 30},                                                    
    },
    {
        id                  = 5,                                                         
        codePath            = "CodeCastFishingSrc.CastFishingBattery.CastFishingBulletObj",   
        csbPath             = "Socre_CastFishing_bullet_1.csb",                                  
        spinePath           = "CastFishingPD",   
        spineIdle           = "paodan",                                                      
        resDirection        = 1, 
        speed               = 10,   
        autoDisappearTime   = -1,                                                            
        shape               = {CastFishingSceneConfig.ShapeType.Circular, 30},                                                    
    },
    -- bonus四个等级使用的激光
    {
        id                  = 100,                                                         
        codePath            = "CodeCastFishingSrc.CastFishingBattery.CastFishingBulletObj",   
        csbPath             = "Socre_CastFishing_bullet_100.csb",                                  
        spinePath           = "CastFishingPD",   
        spineIdle           = "paodan3",
        resDirection        = 0, 
        speed               = 0,   
        autoDisappearTime   = 0.5,
        shape               = {CastFishingSceneConfig.ShapeType.Rectangle, 100, 1370},                                                    
    },
}



return CastFishingSceneConfig