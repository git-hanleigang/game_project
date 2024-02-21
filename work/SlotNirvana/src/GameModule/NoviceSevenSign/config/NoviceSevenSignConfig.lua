--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-19 17:24:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-19 17:31:56
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/config/NoviceSevenSignConfig.lua
Description: 新手期 7日签到V2 cfg
--]]
local NoviceSevenSignConfig = {}

NoviceSevenSignConfig.DAY_STATUS = {
    LOCK = 1, --未解锁
    UNLOCK = 2, -- 解锁
    COLLECTED = 3, -- 已领取

    TO_UNLOCK = 4, -- 未解锁到解锁
    GO_COLLECT = 5, -- 去领取
}

NoviceSevenSignConfig.EVENT_NAME = {
    ONRECIEVE_COLLECT_NOVICE_SIGN_DAY_REWARD = "ONRECIEVE_COLLECT_NOVICE_SIGN_DAY_REWARD", -- 签到奖励领取成功
    NOTIFY_COLLECT_NOVICE_SENVEN_SIGN_DAY_MULTI = "NOTIFY_COLLECT_NOVICE_SENVEN_SIGN_DAY_MULTI", -- 收集签到到天 倍数
}

return NoviceSevenSignConfig