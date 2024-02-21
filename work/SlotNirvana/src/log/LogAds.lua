--
-- 发送 iap消息
-- Author:{author}
-- Date: 2019-05-16 18:13:45
--
local NetworkLog = require "network.NetworkLog"
local LogAds = class("LogAds", NetworkLog)

LogAds.m_taskOpenSite = nil
LogAds.m_taskOpenType = nil
LogAds.m_taskOpenStatus = nil
LogAds.m_adTaskStatus = nil
LogAds.m_rewardCoins = nil
LogAds.m_dialyTimes = nil
--创建本次购买唯一标识
function LogAds:createPaySessionId()
    local randomTag = xcyy.SlotsUtil:getMilliSeconds()
    local platform = device.platform
    local id = nil
    if platform == "ios" then
        id = globalPlatformManager:getIDFV() or "ID"
    else
        id = globalPlatformManager:getAndroidID() or "ID"
    end
    self.m_adsSessionId = tostring(id) .. "_ads_" .. randomTag
end

function LogAds:ctor()
    NetworkLog.ctor(self)
end

function LogAds:sendLogMessage(...)
    local args = {...}
    --TODO 在这里组织你感兴趣的数据

    NetworkLog.sendLogData(self)
end

function LogAds:setOpenSite(site)
    self.m_taskOpenSite = site
end

function LogAds:setOpenType(type)
    self.m_taskOpenType = type
end

function LogAds:setOpenStatus(status)
    self.m_taskOpenStatus = status
end

function LogAds:setadTaskStatus(status)
    self.m_adTaskStatus = status
end

function LogAds:setrewardCoins(coins)
    self.m_rewardCoins = coins
end

function LogAds:setdialyTimes(coins)
    self.m_dialyTimes = coins
end

function LogAds:sendAdsLog(noFireBase)
    gL_logData:syncUserData()
    gL_logData:syncEventData("FreeCoins")

    local messageData = {
        paySessionId = self.m_adsSessionId,
        task = "Advertisement",
        type = 15,
        taskOpenSite = self.m_taskOpenSite,
        taskOpenType = self.m_taskOpenType,
        taskOpenStatus = self.m_taskOpenStatus,
        adTaskStatus = self.m_adTaskStatus,
        rewardCoins = self.m_rewardCoins,
        dialyTimes = self.m_dialyTimes
    }
    gL_logData.p_data = messageData
    if not noFireBase then
        globalFireBaseManager:checkSendFireBaseLog(messageData)
    end
    self:sendLogData()
end

return LogAds
