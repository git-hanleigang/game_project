
--[[--
    fbFun LOG
    轮播页 fbfun 每点击一次发一次
]]

local NetworkLog = require "network.NetworkLog"
local LogGameCraze = class("LogGameCraze",NetworkLog)

function LogGameCraze:ctor()
    NetworkLog.ctor(self)

end

function LogGameCraze:sendLogMessage( ... )
    local args = {...}
    -- 在这里组织你感兴趣的数据
    NetworkLog.sendLogData(self)
end

--打开跳转界面
function LogGameCraze:sendGameCrazeLog(type)

    gL_logData:syncUserData()
    gL_logData:syncEventData("GameCrazy")

    local messageData = {
        type = type,
    }

    gL_logData.p_data = messageData
    self:sendLogData()
end

-- 外部调用接口 end   ----------------------------------------------------------

return LogGameCraze