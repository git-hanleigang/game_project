--参数配置
local ClawStallPublicConfig = {}

ClawStallPublicConfig.itemList = {
    [1] = { --红色小鸟
        modelPath   = "physicsRes/Items/wawaji_hongniao.c3b",
        texPath     = "physicsRes/Items/wawaji_hongniao.png",
        scale       = 18,
        mass        = 1.0,
    },
    [2] = { -- 黄色小鸟
        modelPath   = "physicsRes/Items/wawaji_huangniao.c3b",
        texPath     = "physicsRes/Items/wawaji_huangniao.png",
        scale       = 18,
        mass        = 1.0,
    },
    
    [3] = { --粉色小鸟
        modelPath   = "physicsRes/Items/wawaji_fenniao.c3b",
        texPath     = "physicsRes/Items/wawaji_fenniao.png",
        scale       = 18,
        mass        = 1.0,
    },
    [4] = { --蓝色小鸟
        modelPath   = "physicsRes/Items/wawaji_lanniao.c3b",
        texPath     = "physicsRes/Items/wawaji_lanniao.png",
        scale       = 18,
        mass        = 1.0,
    },
    [5] = { -- 绿色小鸟
        modelPath   = "physicsRes/Items/wawaji_lvniao.c3b",
        texPath     = "physicsRes/Items/wawaji_lvniao.png",
        scale       = 18,
        mass        = 1.0,
    },
    [6] = { --普通小球
        modelPath   = "physicsRes/Items/blueball.c3b",
        texPath     = "physicsRes/Items/blueball.png",
        scale       = 0.3,
        mass        = 1.0,
    },
}

ClawStallPublicConfig.moveSpeedFactor = 0.2 --爪子移动速度
ClawStallPublicConfig.moveDownSpeed = 12 --下落速度
ClawStallPublicConfig.moveUpSpeed = 9 --上升速度
ClawStallPublicConfig.moveBackSpeed = 12 --爪子移回时每秒移动的像素
ClawStallPublicConfig.clawCloseAngle = -93 -- 爪子的闭合角度
ClawStallPublicConfig.itemRadius = 3.5 --娃娃模型半径
ClawStallPublicConfig.countDownTime = 20 --倒计时时长
ClawStallPublicConfig.machineOffset = 10 --机台偏移量
ClawStallPublicConfig.itemScale = 19.4 --娃娃缩放
ClawStallPublicConfig.ballScale = 0.35 --小球缩放

return ClawStallPublicConfig