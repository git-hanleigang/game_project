-- bonus玩法打点

local NetworkLog = require "network.NetworkLog"
local BankCrazeChooseRewardLog = class("BankCrazeChooseRewardLog", NetworkLog)

function BankCrazeChooseRewardLog:ctor()
    BankCrazeChooseRewardLog.super.ctor(self)
end

-- 选择类型打点
function BankCrazeChooseRewardLog:sendChooseRewardLog(_ctp, _eo, _moduleName)
    gL_logData:syncUserData()
    gL_logData:syncEventData("GameAction")

    local log_data = {}
    log_data.tp = "Click" -- 点击
    log_data.game = _moduleName --关卡名称
    log_data.ctp = _ctp
    log_data.eo = _eo

    gL_logData.p_data = log_data
    self:sendLogData()
end

return BankCrazeChooseRewardLog
