--[[
    系统奖励配置
    author:{author}
    time:2023-06-29 15:04:30
]]
local SysRewardConfig = {
    ["FBReward"] = {type = "coins", num = "1000000", describe = "", path = "Dialog/FB_signreward.csb"},
    ["newVersion"] = {type = "coins", num = "3000000", describe = "", path = "Dialog/UpdateRewardLayer.csb"},
    ["EmailReward"] = {type = "coins", num = "1000000", describe = "", path = "Dialog/EmailBindReward.csb"},
    ["NewUserProtectReward"] = {type = "coins", num = "1000000", describe = "", path = "Dialog/NewUserRewardLayer.csb"}
}

return SysRewardConfig
