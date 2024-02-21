--[[
    黑曜卡幸运轮盘
]]
GD.ObsidianWheelCfg = {}

-- 服务器定义的轮盘格子类型的枚举
ObsidianWheelCfg.WHEEL_TYPE = {
    ["BLACK_CARD"] = 1, -- 黑曜单卡
    ["COIN"] = 2, -- 金币
    ["GME"] = 3, -- 宝石
    ["FULL_CARD"] = 4, -- 全卡
    ["ITEMS"] = 5
}

-- 免费一次涨一进度 付费一次涨一进度 十连抽涨十进度
ObsidianWheelCfg.PROGRESS = {
    Free = 1,
    SinglePay = 1,
    MultiPay = 10
}

-- ViewEventType.

NetType.ObsidianWheel = "ObsidianWheel"
NetLuaModule.ObsidianWheel = "activities.Activity_ObsidianWheel.net.ObsidianWheelNet"
