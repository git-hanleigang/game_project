--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMoneyBallConfig = class("LevelMoneyBallConfig", LevelConfigData)




LevelMoneyBallConfig.DebugControl    = true -- 开启调试

-- 目前按宽高比从大到小排列 --
LevelMoneyBallConfig.PerpectiveLayer =
{
    -- 0.75 --
    {
        reelSize    = cc.p( 650 , 330),     -- 轮盘真实像素宽高 --
        winSizeRate = 0.75,                 -- 屏幕比率范围 --  Ipad --
        maxUV       = 0.6,                  -- 最大UV值 --
        offsetY     = 173,                  -- 迎合轮盘显示的Y轴偏移量 --
        vertexAtt   = {                     -- 顶点位置 --
            [1] = cc.vec3(0,0,0),
            [2] = cc.vec3(0,330,0),
            [3] = cc.vec3(0,335  ,-4.6),
            [4] = cc.vec3(0,370  ,-13.8),
            [5] = cc.vec3(0,410  ,-45),
            [6] = cc.vec3(0,590  ,-1300 ),
            [7] = cc.vec3(0,690  ,-1700 ),
            [8] = cc.vec3(0,820  ,-2100 ),
            [9] = cc.vec3(0,970  ,-2500 ),
            [10]= cc.vec3(0,1040  ,-2600 )
        }
    },

    -- 0.667 --
    {
        reelSize    = cc.p( 650 , 330),     -- 轮盘真实像素宽高 --
        winSizeRate = 0.667,                -- 屏幕比率范围 --
        maxUV       = 0.75,                 -- 最大UV值 --
        offsetY     = 173,                  -- 迎合轮盘显示的Y轴偏移量 --
        vertexAtt   = {                     -- 顶点位置 --
            [1] = cc.vec3(0,0,0),
            [2] = cc.vec3(0,330,0),
            [3] = cc.vec3(0,335  ,-4.6),
            [4] = cc.vec3(0,380  ,-13.8),
            [5] = cc.vec3(0,405  ,-45),
            [6] = cc.vec3(0,565  ,-1300 ),
            [7] = cc.vec3(0,650  ,-1700 ),
            [8] = cc.vec3(0,770  ,-2100 ),
            [9] = cc.vec3(0,910  ,-2500 ),
            [10]= cc.vec3(0,980  ,-2600 )
        }
    },

    -- 0.625 --
    {
        reelSize    = cc.p( 650 , 330),     -- 轮盘真实像素宽高 --
        winSizeRate = 0.625,                -- 屏幕比率范围 --
        maxUV       = 0.83,                 -- 最大UV值 --
        offsetY     = 173,                  -- 迎合轮盘显示的Y轴偏移量 --
        vertexAtt   = {                     -- 顶点位置 --
            [1] = cc.vec3(0,0,0),
            [2] = cc.vec3(0,330,0),
            [3] = cc.vec3(0,335  ,-4.6),
            [4] = cc.vec3(0,365  ,-13.8),
            [5] = cc.vec3(0,405  ,-45),
            [6] = cc.vec3(0,565  ,-1300 ),
            [7] = cc.vec3(0,640  ,-1700 ),
            [8] = cc.vec3(0,765  ,-2100 ),
            [9] = cc.vec3(0,890  ,-2500 ),
            [10]= cc.vec3(0,960  ,-2600 )
        }
    },

    -- 0.6 --
    {
        reelSize    = cc.p( 650 , 330),     -- 轮盘真实像素宽高 --
        winSizeRate = 0.6,                  -- 屏幕比率范围 --
        maxUV       = 0.88,                 -- 最大UV值 --
        offsetY     = 173,                  -- 迎合轮盘显示的Y轴偏移量 --
        vertexAtt   = {                     -- 顶点位置 --
            [1] = cc.vec3(0,0,0),
            [2] = cc.vec3(0,330,0),
            [3] = cc.vec3(0,335  ,-4.6),
            [4] = cc.vec3(0,365  ,-13.8),
            [5] = cc.vec3(0,405  ,-45),
            [6] = cc.vec3(0,580  ,-1300 ),
            [7] = cc.vec3(0,665  ,-1700 ),
            [8] = cc.vec3(0,790  ,-2100 ),
            [9] = cc.vec3(0,910  ,-2500 ),
            [10]= cc.vec3(0,980  ,-2600 )
        }
    },

    -- 0.5859 --
    {
        reelSize    = cc.p( 650 , 330),     -- 轮盘真实像素宽高 --
        winSizeRate = 0.5859,               -- 屏幕比率范围  --
        maxUV       = 0.91,                 -- 最大UV值 --
        offsetY     = 173,                  -- 迎合轮盘显示的Y轴偏移量 --
        vertexAtt   = {                     -- 顶点位置 --
            [1] = cc.vec3(0,0,0),
            [2] = cc.vec3(0,330,0),
            [3] = cc.vec3(0,335  ,-4.6),
            [4] = cc.vec3(0,365  ,-13.8),
            [5] = cc.vec3(0,405  ,-45),
            [6] = cc.vec3(0,580  ,-1300 ),
            [7] = cc.vec3(0,665  ,-1700 ),
            [8] = cc.vec3(0,790  ,-2100 ),
            [9] = cc.vec3(0,910  ,-2500 ),
            [10]= cc.vec3(0,980  ,-2600 )
        }
    },

    -- 0.5634 --
    {
        reelSize    = cc.p( 650 , 330),     -- 轮盘真实像素宽高 --
        winSizeRate = 0.5634,               -- 屏幕比率范围 --
        maxUV       = 0.96,                 -- 最大UV值 --
        offsetY     = 173,                  -- 迎合轮盘显示的Y轴偏移量 --
        vertexAtt   = {                     -- 顶点位置 --
            [1] = cc.vec3(0,0,0),
            [2] = cc.vec3(0,330,0),
            [3] = cc.vec3(0,335  ,-4.6),
            [4] = cc.vec3(0,365  ,-13.8),
            [5] = cc.vec3(0,405  ,-45),
            [6] = cc.vec3(0,560  ,-1500 ),
            [7] = cc.vec3(0,635  ,-1900 ),
            [8] = cc.vec3(0,770  ,-2400 ),
            [9] = cc.vec3(0,910  ,-2800 ),
            [10]= cc.vec3(0,980  ,-2900 )
        }
    },

    -- 0.4618 --
    {
        reelSize    = cc.p( 650 , 330),     -- 轮盘真实像素宽高 --
        winSizeRate = 0.4618,               -- 屏幕比率范围 --
        maxUV       = 0.97,                 -- 最大UV值 --
        offsetY     = 173,                  -- 迎合轮盘显示的Y轴偏移量 --
        vertexAtt   = {                     -- 顶点位置 --
            [1] = cc.vec3(0,0,0),
            [2] = cc.vec3(0,330,0),
            [3] = cc.vec3(0,335  ,-4.6),
            [4] = cc.vec3(0,365  ,-13.8),
            [5] = cc.vec3(0,405  ,-45),
            [6] = cc.vec3(0,530  ,-1500 ),
            [7] = cc.vec3(0,580  ,-1900 ),
            [8] = cc.vec3(0,670  ,-2400 ),
            [9] = cc.vec3(0,820  ,-2800 ),
            [10]= cc.vec3(0,890  ,-2900 )
        }
    },
}

-- My test data for win Adaptation by tm --
--[[
winSize         winRate	    PtsPos	    maxUV	Yoffset		
768x1024	    0.75	    10PointsFix	0.6	    56		
768x1152	    0.667	    ..	        0.75	75		
768x1228.8	    0.6249	    ..	        0.82	75		
768x1280	    0.6	        ..	        0.9	    80		
768x1310.7199	0.5859	    ..	        0.9	    90		
768x1363.199	0.5634	    ..	        1	    95		
768x1366	    0.5622	    ..	        1	    95		
768x1662.976	0.46182	    ..	        1	    95	     iphoneXS 2436x1125	  iphoneXS Max 2688x242   iphoneXR 1792x828
]]

function LevelMoneyBallConfig:getPersLayerAtt( winRate )

    for i,v in ipairs( LevelMoneyBallConfig.PerpectiveLayer ) do
        if winRate > (v.winSizeRate - 0.01) then
            return v
        end
    end

    local endIndex = table.nums( LevelMoneyBallConfig.PerpectiveLayer )
    return LevelMoneyBallConfig.PerpectiveLayer[endIndex]
end




return  LevelMoneyBallConfig