--[[
    Flamingo Jackpot
]]
GD.FlamingoJackpotCfg = {}

FlamingoJackpotCfg.csbPath = "Activity_FlamingoJackpot/Activity/csd/"
-- jackpot刷新的帧数
FlamingoJackpotCfg.JACKPOT_FRAME = 0.08

-- jackpot和进度条切换时间间隔
FlamingoJackpotCfg.UITypeLoopTime = 10

-- 关卡上UI的节点类型
FlamingoJackpotCfg.TopUIType = {
    Jackpot = 1,
    Slot = 2,
    Bar = 3
}

-- 开关状态
FlamingoJackpotCfg.SwitchKey = "switch"
FlamingoJackpotCfg.SwitchStatus = {
    ON = 1, 
    OFF = 2
}

-- 关卡上UI的挂点的展示状态
FlamingoJackpotCfg.ArrowKey = "arrow"
FlamingoJackpotCfg.ArrowStatus = {
    UP = 1, -- 隐藏收起
    DOWN = 2 -- 展示下拉
}

-- jackpot类型
FlamingoJackpotCfg.JackpotType = {
    Mini = 1,
    Minor = 2,
    Grand = 3,
    Super = 4,
}

-- 解锁状态
FlamingoJackpotCfg.LockStatus = {
    Lock = 1, 
    Unlock = 2
}

-- 老虎机信号定义类型
FlamingoJackpotCfg.SlotSymbolType = {
    Empty = 0, -- 空
    Key = 1 -- 钥匙
}
-- 客户端老虎机中，需要将空转换为 4或者5
FlamingoJackpotCfg.SlotEmptySymbolNum = 5

NetType.FlamingoJackpot = "FlamingoJackpot"
NetLuaModule.FlamingoJackpot = "activities.Activity_FlamingoJackpot.net.FlamingoJackpotNet"
