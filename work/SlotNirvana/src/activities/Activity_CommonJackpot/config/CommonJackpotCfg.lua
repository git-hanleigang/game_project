--[[
    公共jackpot
    几个关卡公用一个jackpot
]]
GD.CommonJackpotCfg = {}

-- jackpot刷新的帧数
CommonJackpotCfg.JACKPOT_FRAME = 0.08

-- 档位名字
CommonJackpotCfg.LEVEL_NAME = {
    Normal = "Normal",
    Mega = "Mega",
    Super = "Super"
}

-- jackpot时间key
CommonJackpotCfg.POOL_KEY = {
    Lobby = "lobby",
    Mega = "Mega",
    Super = "Super"
}

CommonJackpotCfg.RESPIN_SHOW_MAX = 8 -- 可累计展示的奖励个数固定为8个
CommonJackpotCfg.LEVEL_BET_MAX = 3 -- mega和super的bet档位固定为3个
CommonJackpotCfg.BUBBLE_DELAY = 10 -- 入口上气泡的停留时间

CommonJackpotCfg.luaPath = "Activity.CommonJackpot."
CommonJackpotCfg.csbRes = "Activity/CommonJackpot/csd/"
CommonJackpotCfg.otherRes = "Activity/CommonJackpot/other/"

NetType.CommonJackpot = "CommonJackpot"
NetLuaModule.CommonJackpot = "activities.Activity_CommonJackpot.net.CommonJackpotNet"

ViewEventType.NOTIFI_CJ_REQUEST_START_RESULT = "NOTIFI_CJ_REQUEST_START_RESULT"
ViewEventType.NOTIFI_CJ_DATA_CHANGED = "NOTIFI_CJ_DATA_CHANGED"
ViewEventType.NOTIFI_MACHINE_ONENTER = "NOTIFI_MACHINE_ONENTER"
ViewEventType.NOTIFI_MACHINE_WIN_RESPIN = "NOTIFI_MACHINE_WIN_RESPIN"

-- 测试新手引导
CommonJackpotCfg.TEST_GUIDE = false

-- 测试模式和测试数据
CommonJackpotCfg.TEST_MODE = false
CommonJackpotCfg.TEST_ENTER = {
    -- 档位信息
    ["levels"] = {
        {
            key = "normal",
            name = "Normal",
            rsWinAmount = {100000000, 200000000, 300000000}
        },
        {
            key = "mega",
            name = "Mega",
            bets = {1000000, 2000000, 3000000}, -- 解锁bet
            rsWinAmount = {400000000, 500000000, 600000000} -- 已累计的respin赢钱
        },
        {
            key = "super1",
            name = "Super",
            bets = {4000000, 5000000, 6000000},
            rsWinAmount = {700000000, 800000000, 900000000}
        },
        {
            key = "super2",
            name = "Super",
            bets = {4000000, 5000000, 6000000},
            rsWinAmount = {700000000, 800000000, 900000000}
        }
    },
    -- jackpot奖池
    ["coinsPool"] = {
        {
            key = "mega",
            value = 10000000000, -- 奖池金币
            offset = 1000 -- 每秒增长量
        },
        {
            key = "super1",
            value = 10000000000,
            offset = 1000
        },
        {
            key = "super2",
            value = 20000000000,
            offset = 2000
        }
    }
}
CommonJackpotCfg.TEST_SPIN = {
    -- 本次spin的档位
    ["curLevel"] = {
        key = "mega",
        name = "Mega",
        bets = {1100000, 2100000, 3100000},
        rsWinAmount = {410000000, 510000000, 610000000}
    },
    -- jackpot奖池
    ["coinsPool"] = {
        {
            key = "mega",
            value = 10000000000, -- 奖池金币
            offset = 1000 -- 每秒增长量
        },
        {
            key = "super1",
            value = 10000000000,
            offset = 1000
        },
        {
            key = "super2",
            value = 10000000000,
            offset = 1000
        }
    }
}
