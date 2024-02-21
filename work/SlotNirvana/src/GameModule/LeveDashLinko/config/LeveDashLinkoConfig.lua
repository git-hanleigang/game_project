--[[
    配置
]]
_G.LeveDashLinkoConfig = {}

LeveDashLinkoConfig.luaPath = "ItemGame.PlinkoCode."
LeveDashLinkoConfig.csbPath = "Activity/BeerPlinko/csd/"
LeveDashLinkoConfig.otherPath = "Activity/BeerPlinko/other/"

-- 游戏状态:INIT, PLAYING,FINISH（服务器定义）
LeveDashLinkoConfig.GameStatus = {
    Init = "INIT",
    Playing = "PLAYING",
    Finish = "FINISH"
}

-- 游戏类型 免费， 付费
LeveDashLinkoConfig.UIStatus = {
    Free = 0,
    Pay = 1
}

LeveDashLinkoConfig.event = {
    NOTIFY_PERLINK_PAY = "NOTIFY_PERLINK_PAY", --付费成功
    NOTIFY_PERLINK_CLOUSE = "NOTIFY_PERLINK_CLOUSE", --关闭界面
    NOTIFY_PERLINK_RESPIN = "NOTIFY_PERLINK_RESPIN", --结束一次spin
    NOTIFY_PERLINK_RESPIN_RESULT = "NOTIFY_PERLINK_RESPIN_RESULT", --关闭界面
    NOTIFY_PERLINK_RESPIN_RIGHT = "NOTIFY_PERLINK_RESPIN_RIGHT", --更新显示
    NOTIFY_PERLINK_REWARD_SUCCESS = "NOTIFY_PERLINK_REWARD_SUCCESS", --更新显示
    NOTIFY_PERLINK_PAY_LAYOUT = "NOTIFY_PERLINK_PAY_LAYOUT", --支付显示
    NOTIFY_PERLINK_PAY_LAYOUT_SUCCESS = "NOTIFY_PERLINK_PAY_LAYOUT_SUCCESS", --支付显示成功
    NOTIFY_PERLINK_PAY_QUIET = "NOTIFY_PERLINK_PAY_QUIET", --支付显示成功
}
