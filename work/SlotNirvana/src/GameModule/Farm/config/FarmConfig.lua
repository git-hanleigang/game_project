--[[
    农场配置
]]
local FarmConfig  = {}

FarmConfig.GUIDE = true

FarmConfig.crops = {
    [1] = {
        name = "WHEAT", -- 小麦
        spinePaht = "Activity_Farm/spine/zuowu/Farm_wheat",         -- spine 
        growPath = "Activity_Farm/img/img_crop/crop_1_%s.png",      -- 作物三种状态资源路径
        cropPath = "Activity_Farm/img/img_crop/icon_crop_1.png",    -- 作物资源路径
        seedPath = "Activity_Farm/img/img_crop/seed/seed_1_1.png",    -- 种子资源路径
        seedPath2 = "Activity_Farm/img/img_crop/seed/seed_1_2.png",    -- 种子资源路径
    },
    [2] = {
        name = "CORN",  -- 玉米
        spinePaht = "Activity_Farm/spine/zuowu/Farm_corn",          -- spine 
        growPath = "Activity_Farm/img/img_crop/crop_2_%s.png",      -- 作物三种状态资源路径
        cropPath = "Activity_Farm/img/img_crop/icon_crop_2.png",    -- 作物资源路径
        seedPath = "Activity_Farm/img/img_crop/seed/seed_2_1.png",    -- 种子资源路径
        seedPath2 = "Activity_Farm/img/img_crop/seed/seed_2_2.png",    -- 种子资源路径
    },
    [3] = {
        name = "CARROT",  -- 胡萝卜
        spinePaht = "Activity_Farm/spine/zuowu/Farm_carrot",        -- spine 
        growPath = "Activity_Farm/img/img_crop/crop_3_%s.png",      -- 作物三种状态资源路径
        cropPath = "Activity_Farm/img/img_crop/icon_crop_3.png",    -- 作物资源路径
        seedPath = "Activity_Farm/img/img_crop/seed/seed_3_1.png",    -- 种子资源路径
        seedPath2 = "Activity_Farm/img/img_crop/seed/seed_3_2.png",    -- 种子资源路径
    },
    [4] = {
        name = "CHILLI",  -- 辣椒
        spinePaht = "Activity_Farm/spine/zuowu/Farm_chilli",        -- spine 
        growPath = "Activity_Farm/img/img_crop/crop_4_%s.png",      -- 作物三种状态资源路径
        cropPath = "Activity_Farm/img/img_crop/icon_crop_4.png",    -- 作物资源路径
        seedPath = "Activity_Farm/img/img_crop/seed/seed_4_1.png",    -- 种子资源路径
        seedPath2 = "Activity_Farm/img/img_crop/seed/seed_4_2.png",    -- 种子资源路径
    },
    [5] = {
        name = "TOMATO",  -- 西红柿
        spinePaht = "Activity_Farm/spine/zuowu/Farm_tomato",        -- spine 
        growPath = "Activity_Farm/img/img_crop/crop_5_%s.png",      -- 作物三种状态资源路径
        cropPath = "Activity_Farm/img/img_crop/icon_crop_5.png",    -- 作物资源路径
        seedPath = "Activity_Farm/img/img_crop/seed/seed_5_1.png",    -- 种子资源路径
        seedPath2 = "Activity_Farm/img/img_crop/seed/seed_5_2.png",    -- 种子资源路径
    },
    [6] = {
        name = "PUMPKIN",  -- 南瓜
        spinePaht = "Activity_Farm/spine/zuowu/Farm_pumpkin",       -- spine 
        growPath = "Activity_Farm/img/img_crop/crop_6_%s.png",      -- 作物三种状态资源路径
        cropPath = "Activity_Farm/img/img_crop/icon_crop_6.png",    -- 作物资源路径
        seedPath = "Activity_Farm/img/img_crop/seed/seed_6_1.png",    -- 种子资源路径
        seedPath2 = "Activity_Farm/img/img_crop/seed/seed_6_2.png",    -- 种子资源路径
    },
    [7] = {
        name = "ROSE",  -- 玫瑰
        spinePaht = "Activity_Farm/spine/zuowu/Farm_rose",          -- spine 
        growPath = "Activity_Farm/img/img_crop/crop_7_%s.png",      -- 作物三种状态资源路径
        cropPath = "Activity_Farm/img/img_crop/icon_crop_7.png",    -- 作物资源路径
        seedPath = "Activity_Farm/img/img_crop/seed/seed_7_1.png",    -- 种子资源路径
        seedPath2 = "Activity_Farm/img/img_crop/seed/seed_7_2.png",    -- 种子资源路径
    },
    [8] = {
        name = "COINTREE",  -- 金钱树
        spinePaht = "Activity_Farm/spine/zuowu/Farm_cointree",      -- spine 
        growPath = "Activity_Farm/img/img_crop/crop_8_%s.png",      -- 作物三种状态资源路径
        cropPath = "Activity_Farm/img/img_crop/icon_crop_8.png",    -- 作物资源路径
        seedPath = "Activity_Farm/img/img_crop/seed/seed_8_1.png",    -- 种子资源路径
        seedPath2 = "Activity_Farm/img/img_crop/seed/seed_8_2.png",    -- 种子资源路径
    },
    -- 镰刀,一定放最后
    [9] = {
        name = "",
        seedPath = "Activity_Farm/img/img_main/Activity_Farm_Main_bottom_icon2.png", -- 镰刀icon资源
    }
}

FarmConfig.cashFarm = {
    bgPath = "Activity_Farm/img/img_friends/friends_cash_di.png",
    name = "MR.CASH",
    framePath = "Activity_Farm/img/img_friends/frame_cash.png",
    kuangPath = "Activity_Farm/img/img_friends/friends_cash_kuang.png",
    frameScale = 0.75,
    farmLevel = 90,
    udid = "CASH_FARM"
}

FarmConfig.cashFarmData = {
    othersData = {
        steal = 1,
        farmLevel = 90,
        framePath = "Activity_Farm/img/img_friends/frame_cash.png",
        name =  "MR.CASH",
        udid =  "CASH_FARM",
        cashFarm = true,
        infoScale = 0.67,
        frameScale = 0.37
    },
    resData = {
        expireAt = 0,
        friendType = 2,
        expire = 0,
        info = {
            level = 90,
            levelMax = 90,
            exp = 100,
            expMax = 100,
            name = "MR:CASH"
        },
        lands = {
            [1] = {
                matureAt = 0,
                id = 1,
                status = 1,
                unlockLevel = 1,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [2] = {
                matureAt = 0,
                id = 2,
                status = 1,
                unlockLevel = 2,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [3] = {
                matureAt = 0,
                id = 3,
                status = 1,
                unlockLevel = 5,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [4] = {
                matureAt = 0,
                id = 4,
                status = 1,
                unlockLevel = 10,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [5] = {
                matureAt = 0,
                id = 5,
                status = 1,
                unlockLevel = 15,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [6] = {
                matureAt = 0,
                id = 6,
                status = 1,
                unlockLevel = 20,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [7] = {
                matureAt = 0,
                id = 7,
                status = 1,
                unlockLevel = 25,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [8] = {
                matureAt = 0,
                id = 8,
                status = 1,
                unlockLevel = 30,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [9] = {
                matureAt = 0,
                id = 9,
                status = 1,
                unlockLevel = 35,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [10] = {
                matureAt = 0,
                id = 2,
                status = 1,
                unlockLevel = 40,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [11] = {
                matureAt = 0,
                id = 11,
                status = 1,
                unlockLevel = 45,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [12] = {
                matureAt = 0,
                id = 12,
                status = 1,
                unlockLevel = 50,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [13] = {
                matureAt = 0,
                id = 13,
                status = 1,
                unlockLevel = 55,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [14] = {
                matureAt = 0,
                id = 14,
                status = 1,
                unlockLevel = 60,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [15] = {
                matureAt = 0,
                id = 15,
                status = 1,
                unlockLevel = 65,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [16] = {
                matureAt = 0,
                id = 16,
                status = 1,
                unlockLevel = 70,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [17] = {
                matureAt = 0,
                id = 17,
                status = 1,
                unlockLevel = 75,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [18] = {
                matureAt = 0,
                id = 18,
                status = 1,
                unlockLevel = 80,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [19] = {
                matureAt = 0,
                id = 19,
                status = 1,
                unlockLevel = 85,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            },
            [20] = {
                matureAt = 0,
                id = 20,
                status = 1,
                unlockLevel = 90,
                protect = 0,
                left = 25,
                crop = 8,
                bound = 25,
                protectAt = 1200000,
                mature = 0
            }
        },
        stats = {
            [1] = {
                description = "HARVESTED CROPS",
                value = 999
            },
            [2] = {
                description = "STOLEN CROPS",
                value = 999
            },
            [3] = {
                description = "FIELDS",
                value = 20
            }
        }
    },
    type = 0
}

FarmConfig.friendFarm = {
    bgPath = "Activity_Farm/img/img_friends/Activity_Farm_Friends_bg5.png",
    kuangPath = "Activity_Farm/img/img_friends/friends_kuangi.png"
}

FarmConfig.achieveIcon = {
    "Activity_Farm/img/img_main/Activity_Farm_Main_bottom_icon2.png",
    "Activity_Farm/img/img_farm_Information/steal.png",
    "Activity_Farm/img/img_farm_Information/land.png",
}

return FarmConfig