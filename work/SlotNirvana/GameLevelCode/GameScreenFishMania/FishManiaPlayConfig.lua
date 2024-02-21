--FishManiaConfig.lua

local FishManiaConfig = {}

FishManiaConfig.FishItemId = {
    HawaiiId    = 1, 
    PiratesId   = 2, 
    GreeceId    = 3, 
    CustomId    = 4,
}
--[[--

    新增装饰品流程      
    1. FishManiaConfig.ToySpineName       填写对应spine 
       FishManiaConfig.ToySpinePngName    填写对应spine的png (选填)
    2. FishManiaConfig.ToyMove            移动参数           (选填)
    3. FishManiaConfig.FishToyCfg         商店展示的名称, 商店/界面 使用 静态图/工程 的资源索引, 商店的缩放, 购买弹板的缩放, 

    4. 工程内新增 FishToy/FishMania_wuToy_%d.csd            
    5. 资源内新增 common/FishMania_shop_ui_gang%d.png 静态图
    6. 工程 FishToy/FishMania_wu%d 内新增装饰品界面挂点
]]  
-- commodityId = 商品type + 1,这个配置会在服务器下发数据后重新初始化一遍
FishManiaConfig.ToyId = {
    [1] = {}, -- 25,1,2,3,4,5,
    [2] = {}, -- 6,7,8,9,10,11,12,13,
    [3] = {}, -- 14,15,16,17,18,19,20,21,22,23,24,
    [4] = {}, -- 1,2,3,4,25,5,  6,7,8,9,10,11,12,13,  14,15,16,17,18,19,20,21,22,23,24,
}
-- 关卡事件列表
FishManiaConfig.EventName = {
    SHOPLISTVIEW_SHOW_HIDE   = "SHOPLISTVIEW_SHOW_HIDE",
    UPDATE_MACHINE_FISH_TANK = "UPDATE_MACHINE_FISH_TANK",
    PICKSCORE_CHANGE = "PICKSCORE_CHANGE",
    FISHBOX_CLICK = "FISHBOX_CLICK",
}

-- [commodityId] = {道具类型标签《4种》, 资源类型ID《25种》, 商店缩放, 弹板缩放, 摆放层级, }
FishManiaConfig.FishToyCfg = {
    [1] =  {name = "DECOR",   shopIcon = 1,  shopScale = 0.25, bonusScale = 0.70, order = 3, },
    [2] =  {name = "STATUE",  shopIcon = 2,  shopScale = 0.20, bonusScale = 0.50, order = 1, },
    [3] =  {name = "CORAL",   shopIcon = 3,  shopScale = 0.25, bonusScale = 0.94, order = 2, },
    [4] =  {name = "PALM",    shopIcon = 4,  shopScale = 0.20, bonusScale = 0.60, order = 4, },
    [5] =  {name = "FISH",    shopIcon = 5,  shopScale = 0.44, bonusScale = 1.30, order = 5, },

    [6] =  {name = "DECOR",   shopIcon = 6,  shopScale = 0.25, bonusScale = 0.60, order = 9, },
    [7] =  {name = "PIRATE",  shopIcon = 7,  shopScale = 0.15, bonusScale = 0.50, order = 11, },
    [8] =  {name = "DECOR",   shopIcon = 8,  shopScale = 0.25, bonusScale = 0.84, order = 10, },
    [9] =  {name = "DECOR",   shopIcon = 9,  shopScale = 0.25, bonusScale = 0.84, order = 6, },
    [10] = {name = "DECOR",   shopIcon = 10, shopScale = 0.25, bonusScale = 0.88, order = 7, },
    [11] = {name = "DECOR",   shopIcon = 11, shopScale = 0.25, bonusScale = 0.92, order = 8, },
    [12] = {name = "PIRATE",  shopIcon = 12, shopScale = 0.40, bonusScale = 1.30, order = 12, },
    [13] = {name = "PIRATE",  shopIcon = 13, shopScale = 0.40, bonusScale = 1.30, order = 13, },

    [14] = {name = "CORAL",   shopIcon = 14, shopScale = 0.25, bonusScale = 0.92, order = 17, },
    [15] = {name = "CORAL",   shopIcon = 15, shopScale = 0.25, bonusScale = 0.83, order = 20, },
    [16] = {name = "STATUE",  shopIcon = 16, shopScale = 0.25, bonusScale = 0.70, order = 15, },
    [17] = {name = "DECOR",   shopIcon = 17, shopScale = 0.25, bonusScale = 0.88, order = 18, },
    [18] = {name = "DECOR",   shopIcon = 18, shopScale = 0.20, bonusScale = 0.65, order = 16, },
    [19] = {name = "DECOR",   shopIcon = 19, shopScale = 0.25, bonusScale = 0.82, order = 19, },
    [20] = {name = "STATUE",  shopIcon = 20, shopScale = 0.19, bonusScale = 0.55, order = 14, },
    [21] = {name = "DECOR",   shopIcon = 21, shopScale = 0.25, bonusScale = 0.85, order = 21, },
    [22] = {name = "WARRIOR", shopIcon = 22, shopScale = 0.40, bonusScale = 1.00, order = 22, },
    [23] = {name = "WARRIOR", shopIcon = 23, shopScale = 0.40, bonusScale = 1.10, order = 23, },
    [24] = {name = "WARRIOR", shopIcon = 24, shopScale = 0.40, bonusScale = 1.10, order = 24, },

    [25] = {name = "FISH",    shopIcon = 25, shopScale = 0.40, bonusScale = 1.30, order = 6, },
}

--动效缩放
FishManiaConfig.ToySpineScale = 0.66

-- [commodityId] = "动画名称"
FishManiaConfig.ToySpineName = {
    [1] = "FishMania_shop_ui_gang1",
    [2] = "FishMania_shop_ui_gang2",
    [3] = "FishMania_shop_ui_gang3",
    [4] = "FishMania_shop_ui_gang4",
    [5] = "Socre_FishMania_9",
    [6] = "FishMania_shop_ui_gang6",
    [7] = "FishMania_shop_ui_gang7",
    [8] = "FishMania_shop_ui_gang8",
    [9] = "FishMania_shop_ui_gang9",
    [10] = "FishMania_shop_ui_gang10",
    [11] = "FishMania_shop_ui_gang11",
    [12] = "Socre_FishMania_9_haidao",
    [13] = "Socre_FishMania_6_haidao",
    [14] = "FishMania_shop_ui_gang14",
    [15] = "FishMania_shop_ui_gang15",
    [16] = "FishMania_shop_ui_gang16",
    [17] = "FishMania_shop_ui_gang17",
    [18] = "FishMania_shop_ui_gang18",
    [19] = "FishMania_shop_ui_gang19",
    [20] = "FishMania_shop_ui_gang20",
    [21] = "FishMania_shop_ui_gang21",
    [22] = "Socre_FishMania_9_zhanshi",
    [23] = "Socre_FishMania_6_zhanshi",
    [24] = "Socre_FishMania_7_zhanshi",
    [25] = "Socre_FishMania_7",
}
--png名称 有时多个spine会共用png 
FishManiaConfig.ToySpinePngName = {
    [12] = "Socre_FishMania_9",
    [13] = "Socre_FishMania_6",
    [22] = "Socre_FishMania_9",
    [23] = "Socre_FishMania_6",
    [24] = "Socre_FishMania_7",
}

-- 装饰品沿当前高度左右移动的参数 (默认不移动)
-- [commodityId] = {moveParams}
FishManiaConfig.ToyMove = {
    --[[
        [1] = {
            dir = 1,     --默认朝向 1:右 -1:左 (给的资源有些默认朝向不一致)
        },
    ]]
    [5] = {
        dir = 1,
    },
    [12] = {
        dir = 1,
    },
    [13] = {
        dir = 1,
    },
    [22] = {
        dir = 1,
    },
    [23] = {
        dir = 1,
    },
    [24] = {
        dir = 1,
    },
    [25] = {
        dir = 1,
    },
}

return FishManiaConfig
