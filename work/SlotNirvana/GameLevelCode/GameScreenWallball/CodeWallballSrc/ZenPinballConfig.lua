--[[
    弹珠配置
]]

local ZenPinballConfig = {}

ZenPinballConfig.Debug              = false  -- 调试状态 

-- 小球顶部掉落时的高度偏移量 --
ZenPinballConfig.TopPositionOffset  = 50
-- 小球触底后继续移动的距离 --
ZenPinballConfig.BottomOffset       = 330

-- 渲染层级参数 --
ZenPinballConfig.DingZOder          = 0
ZenPinballConfig.BallZOder          = 5
ZenPinballConfig.SymbolZOder        = 10

-- 钉子矩阵基本属性 --
ZenPinballConfig.BaseList           = { 8,9,8,9,8,9,8,9,8,9,8,9,8,9,8,9,8 }
ZenPinballConfig.MinCol             = 8     -- 短列数量 --
ZenPinballConfig.MaxCol             = 9     -- 长列数列 --
ZenPinballConfig.Interval           = 78    -- 距离间隔 --
ZenPinballConfig.DingScale          = 1     -- 显示缩放 --
ZenPinballConfig.DingRadius         = 8     -- 物理半径 --

-- 特殊信号块资源 --
ZenPinballConfig.SpecialRes         = {
    [1] = "Wallball_board_add3str.csb",        --3星 --
    [2] = "Wallball_board_add2str.csb",        --2星 --
    [3] = "Wallball_board_multiwins.csb",      --Multiwins --
    [4] = "Wallball_board_wildstack.csb",      --Wildstack --
    [5] = "Wallball_board_Grand.csb",          --Grand --
    [6] = "Wallball_board_Minor.csb",          --Minor --
    [7] = "Wallball_board_Major.csb",          --Major --
    [8] = "Wallball_board_2spin.csb",          --2FSpin--
}

-- 钉子资源 --
ZenPinballConfig.DingOriPic         = "Symbol/ding.png"        -- 原始图片
ZenPinballConfig.DingHighLihgtPic   = "Symbol/dingFlash.png"   -- 高亮显示
ZenPinballConfig.DingDisablePic     = "Symbol/dingFlash.png"   -- 禁用图片
ZenPinballConfig.DingRouterPic      = "Symbol/dingFlash.png"   -- 必经图片

ZenPinballConfig.DingFreeSpinPic    = {     -- FreeSpin下钉子图片 --
    [1] = "Symbol/ding_fs_1.png",
    [2] = "Symbol/ding_fs_2.png",
    [3] = "Symbol/ding_fs_3.png",
    [4] = "Symbol/ding_fs_4.png",
    [5] = "Symbol/ding_fs_5.png",
    [6] = "Symbol/ding_fs_6.png",
    [7] = "Symbol/ding_fs_7.png",
    [8] = "Symbol/ding_fs_8.png",
    [9] = "Symbol/ding_fs_9.png",
    [10] = "Symbol/ding_fs_10.png",
    [11] = "Symbol/ding_fs_11.png",
    [12] = "Symbol/ding_fs_12.png",
    [13] = "Symbol/ding_fs_13.png",
    [14] = "Symbol/ding_fs_14.png",
    [15] = "Symbol/ding_fs_15.png",
    [16] = "Symbol/ding_fs_16.png",
    [17] = "Symbol/ding_fs_16.png",
    [18] = "Symbol/ding_fs_16.png",
}


-- 弹珠球背景工程资源 --
ZenPinballConfig.BaseCsbRes         = "Wallball_wangge.csb"


-- 弹球的拖尾粒子资源 --
ZenPinballConfig.BallParticle       = "Wallball_lizi_01.plist"

-- 小球资源 --
ZenPinballConfig.BallRes            = "Symbol/ball.png"
ZenPinballConfig.BallScale          = 1     -- 渲染缩放 --
ZenPinballConfig.BallRadius         = 15    -- 物理半径 --

-- Base模式下特殊信号块位置索引 需要配置  8个--
ZenPinballConfig.NormalSpecialList = 
{
    -- 3⭐️Added
    [1] = { 
        {
            ["Index"] = cc.p( 4 , 2 ),  -- 所在位置
            ["Start"] = {  cc.p( 1 , 1), cc.p( 1 , 2), cc.p( 1 , 3) },  --可触发的起点
            ["End"]   = {  cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8) },
            ["Reel"]  = { [1] = {cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8)} }
        }, 
        {
            ["Index"] = cc.p( 14 , 5 ),
            ["Start"] = {  cc.p( 1, 1), cc.p( 1 , 2), cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7) } ,
            ["Reel"]  = { [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)}  }
        }
    },
    -- 2⭐️Added
    [2] = { 
        {
            ["Index"] = cc.p( 9 , 3 ),
            ["Start"] = {  cc.p( 1, 1), cc.p( 1 , 2), cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5) },
            ["End"]   = {  cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8) },
            ["Reel"]  = { [1] = {cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8)} }
        }, 
        {
            ["Index"] = cc.p( 9 , 6 ),
            ["Start"] = {  cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8) },
            ["Reel"]  = { [1] = {cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8)} }
        }
    },
    -- MultiplyWin
    [3] = { 
        {
            ["Index"] = cc.p( 4 , 5 ),
            ["Start"] = {  cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6) },
            ["End"]   = {  cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8) } ,
            ["Reel"]  = { [1] = {cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8)} }
        }, 
        {
            ["Index"] = cc.p( 14 , 8 ),
            ["Start"] = {  cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8),cc.p( 18 , 9) } ,
            ["Reel"]  = {  [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8),cc.p( 18 , 9)} }
        }
    },
    -- WildStack
    [4] = { 
        {
            ["Index"] = cc.p( 4 , 8 ),
            ["Start"] = {  cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8) },
            ["Reel"]  = { [1] = {cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8)} }
        }, 
        {
            ["Index"] = cc.p( 14 , 2 ),
            ["Start"] = {  cc.p( 1, 1), cc.p( 1 , 2), cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5) },
            ["End"]   = {  cc.p( 18, 1), cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4) },
            ["Reel"]  = { [1] = {cc.p( 18, 1), cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} }
        }
    }
}

-- 特殊玩法模式下特殊信号块位置索引 需要配置 10个--
ZenPinballConfig.FeatureSpecialList = 
{
    -- 3⭐️Added
    [1] = { 
        {
            ["Index"] = cc.p( 7 , 3 ),  -- 所在位置
            ["Start"] = {  cc.p( 1 , 1), cc.p( 1 , 2), cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5) }, --可触发的起点
            ["End"]   = {  cc.p( 18, 1), cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7) },
            ["Reel"]  = { [1] = {cc.p( 18, 1), cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} }
        }
    },
    -- 2⭐️Added
    [2] = { 
        {
            ["Index"] = cc.p( 7 , 6 ),
            ["Start"] = {  cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8),cc.p( 18 , 9) },
            ["Reel"]  = { [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8),cc.p( 18 , 9)} }
        }
    },
    -- MultiplyWin
    [3] = { 
        {
            ["Index"] = cc.p( 4 , 2 ),
            ["Start"] = {  cc.p( 1, 1), cc.p( 1 , 2), cc.p( 1 , 3) },
            ["End"]   = {  cc.p( 18, 1), cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7) },
            ["Reel"]  = { [1] = {cc.p( 18, 1), cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} }
        }, 
        {
            ["Index"] = cc.p( 13 , 6 ),
            ["Start"] = {  cc.p( 1 , 2), cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8),cc.p( 18 , 9) } ,
            ["Reel"]  = { [2]={cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8),cc.p( 18 , 9)} }
        }
    },
    -- WildStack
    [4] = { 
        {
            ["Index"] = cc.p( 4 , 8 ),
            ["Start"] = {  cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8),cc.p( 18 , 9) },
            ["Reel"]  = { [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8),cc.p( 18 , 9)} }
        }, 
        {
            ["Index"] = cc.p( 13 , 3 ),
            ["Start"] = {  cc.p( 1 , 1),cc.p( 1 , 2), cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18, 1), cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6) } ,
            ["Reel"]  = { [1] = {cc.p( 18, 1), cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6)} }
        }
    },
    -- Grand
    [5] = { 
        {
            ["Index"] = cc.p( 4 , 5 ),
            ["Start"] = {  cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6) },
            ["End"]   = {  cc.p( 18, 1), cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8),cc.p( 18 , 9) } ,
            ["Reel"]  = { [1] = {cc.p( 18, 1), cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8),cc.p( 18 , 9)} }
        }
    },
    -- Minor
    [6] = { 
        {
            ["Index"] = cc.p( 9 , 1 ),
            ["Start"] = {  cc.p( 1, 1), cc.p( 1 , 2), cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5) },
            ["End"]   = {  cc.p( 18, 1), cc.p( 18 , 2), cc.p( 18 , 3),cc.p( 18 , 4) } ,
            ["Reel"]  = { [1] = {cc.p( 18, 1), cc.p( 18 , 2)} , [2]={cc.p( 18 , 3),cc.p( 18 , 4)} }
        }
    },
    -- Major
    [7] = { 
        {
            ["Index"] = cc.p( 9 , 8 ),
            ["Start"] = {  cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8)  },
            ["End"]   = {  cc.p( 18 , 6),cc.p( 18 , 7),cc.p( 18 , 8),cc.p( 18 , 9) } ,
            ["Reel"]  = {  [4]={cc.p( 18 , 6),cc.p( 18 , 7)} , [5]={cc.p( 18 , 8),cc.p( 18 , 9)} }
        }
    },
    -- +2Fs
    [8] = { 
        {
            ["Index"] = cc.p( 10 , 5 ),
            ["Start"] = {  cc.p( 1 , 1), cc.p( 1 , 2), cc.p( 1 , 3),cc.p( 1 , 4),cc.p( 1 , 5),cc.p( 1 , 6),cc.p( 1 , 7),cc.p( 1 , 8) },
            ["End"]   = {  cc.p( 18 , 3),cc.p( 18 , 4),cc.p( 18 , 5),cc.p( 18 , 6),cc.p( 18 , 7) },
            ["Reel"]  = {  [2]={cc.p( 18 , 3),cc.p( 18 , 4)} , [3]={cc.p( 18 , 5)} , [4]={cc.p( 18 , 6),cc.p( 18 , 7)} }
        }
    }
}

-- 简单模拟小球收到的重力加速度 --
ZenPinballConfig.AccGravity = -30

-- 定义各个运动状态的速度 --
ZenPinballConfig.JumpSpeed = 
    {
        [0] = cc.p( 0       , 0 ),  -- stop
        [1] = cc.p( 0       , 3 ),  -- mid jump
        [2] = cc.p( -180.0  , 5 ),  -- left up jump
        [3] = cc.p( 180.0   , 0 ),  -- left up reverse
        [4] = cc.p( 180.0   , 5 ),  -- right up jump
        [5] = cc.p( -180.0  , 0 ),  -- right up reverse
        [6] = cc.p( -180.0  , 2 ),  -- left down 
        [7] = cc.p( 180.0   , 2 ),  -- right down 
    }

-- 概率插入随机表现 满值100 --
ZenPinballConfig.ExtraRouter = 
    {
        ["MidJump"]     = 5,
        ["LeftUpJump"]  = 20,
        ["RightUpJump"] = 20
    }

    -- 根据球的位置 判断是哪列 --

ZenPinballConfig.Reel = 
{

    [1] = 1, [2] = 1,[3] = 2,[4] = 2,[5] = 3,[6] = 4,[7] = 4,[8] = 5,[9] = 5 

}

return ZenPinballConfig