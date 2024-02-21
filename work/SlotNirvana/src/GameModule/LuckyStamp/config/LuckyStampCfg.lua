--[[
]]
GD.LuckyStampCfg = {}

LuckyStampCfg.TEST_MODE = false

LuckyStampCfg.csbPath = "LuckyStamp/csb/"
LuckyStampCfg.luaPath = "views.LuckyStamp."
LuckyStampCfg.otherPath = "LuckyStamp/other/"

LuckyStampCfg.StampType = {
    Normal = "NORMAL",
    Golden = "GOLDEN"
}

NetType.LuckyStamp = "LuckyStamp"
NetLuaModule.LuckyStamp = "GameModule.LuckyStamp.net.LuckyStampNet"

ViewEventType.NOTIFI_LUCKYSTAMP_TIMEOUT = "NOTIFI_LUCKYSTAMP_TIMEOUT"
