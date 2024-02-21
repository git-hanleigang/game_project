--
-- LevelDash活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local NetworkLog = require "network.NetworkLog"
local LogDeluxe = class("LogDeluxe",NetworkLog)

function LogDeluxe:ctor()
      NetworkLog.ctor(self)
end

function LogDeluxe:sendDeluxeClubLog()
      local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
      local times = globalData.deluexeClubData.p_expireAt
      local dayNum = util_leftDays(times / 1000)
      local messageData = {
            type = "Enter", 
            days = dayNum, 
            expireAt = times,
      }
      self:sendLevelDashActivityLog("ClubLogin", messageData)
end

--发送log
function LogDeluxe:sendLevelDashActivityLog(eventAction, messageData)
      if messageData == nil then
            messageData = {}
      end

      gL_logData:syncUserData()
      gL_logData:syncEventData(eventAction)
      gL_logData.p_data = messageData
      globalFireBaseManager:checkSendFireBaseLog(messageData)
      self:sendLogData()
end

return  LogDeluxe