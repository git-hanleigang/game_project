--[[
    成长基金配置
    author:{author}
    time:2023-03-10 15:53:37
]]
GD.GrowthFundConfig = {}

GrowthFundConfig.Type = {
    Free = 1,
    Pay = 2
}

GrowthFundConfig.LEVEL_STATUS = {
    Lock = 1,
    Collect = 2,
    Complete = 3
}

NetType.GrowthFund = "GrowthFund"
NetLuaModule.GrowthFund = "GameModule.GrowthFund.net.GrowthFundNet"

ViewEventType.NOTIFY_GROWTH_FUND_UNLOCK_UPDATE = "NOTIFY_GROWTH_FUND_UNLOCK_UPDATE"
ViewEventType.NOTIFY_GROWTH_FUND_COLLECT = "NOTIFY_GROWTH_FUND_COLLECT"
