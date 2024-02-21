--[[
    
]]

_G.HolidaySideGameConfig = {}

HolidaySideGameConfig.GameTime = 15 -- 秒

-- 叶子类型
HolidaySideGameConfig.LeafType = {
    Normal = "NORMAL",
    Golden = "HIGH",
}

-- 叶子状态：等待，飞，休眠
HolidaySideGameConfig.LeafStatus = {
    Wait = 1,
    Fly = 2,
    Sleep = 3,
}

-- 点击粒子的状态
HolidaySideGameConfig.LiziStatus = {
    Active = 1,
    Sleep = 2,
}

-- 服务器定义的游戏状态
HolidaySideGameConfig.GameStatus = {
    Init = "INIT",
    Start = "START",
    Play = "PLAYING",
    Finish = "FINISH",
}

NetType.HolidaySideGame = "HolidaySideGame"
NetLuaModule.HolidaySideGame = "activities.Activity_HolidayNewChallenge.HolidaySideGame.net.HolidaySideGameNet"

ViewEventType.NOTIFY_HOLIDAYSIDEGAME_COLLECT = "NOTIFY_HOLIDAYSIDEGAME_COLLECT"
ViewEventType.NOTIFY_HOLIDAYSIDEGAME_CLOSEUI = "NOTIFY_HOLIDAYSIDEGAME_CLOSEUI"