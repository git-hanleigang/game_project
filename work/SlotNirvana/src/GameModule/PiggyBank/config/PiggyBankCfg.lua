--[[
]]
_G.PiggyBankCfg = {}

-- 道具名字，投放道具后免费生效
PiggyBankCfg.FREE_ICON = "PiggyBank_Free"

-- 自定义事件
ViewEventType.PIGGY_BANK_BUY_FREE = "PIGGY_BANK_BUY_FREE" -- 小猪免费购买
ViewEventType.PIGGY_DATA_UPDATE = "PIGGY_DATA_UPDATE"

-- 网络协议
NetType.PiggyBank = "PiggyBank"
NetLuaModule.PiggyBank = "GameModule.PiggyBank.net.PiggyBankNet"
