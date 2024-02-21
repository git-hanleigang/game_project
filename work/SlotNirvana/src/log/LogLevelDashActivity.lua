--
-- LevelDash活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local NetworkLog = require "network.NetworkLog"
local LogLevelDashActivity = class("LogLevelDashActivity",NetworkLog)

function LogLevelDashActivity:ctor()
      NetworkLog.ctor(self)
end

function LogLevelDashActivity:sendLevelDashPopupLog()
      local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
      local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
      local messageData = {
            activityName = levelDashData.p_activityName,
            order = levelDashData.p_totalFinishTimes,
            pageName = "LevelDashPopup",
            entryType = entryData.entryType, 
            entryName = entryData.entryName, 
            entryOpen = entryData.entryOpen,
      }
      self:sendLevelDashActivityLog("LevelDashPopup", messageData)
end

--发送log
function LogLevelDashActivity:sendLevelDashActivityLog(eventAction, messageData)
      if messageData == nil then
            messageData = {}
      end

      gL_logData:syncUserData()
      gL_logData:syncEventData(eventAction)
      gL_logData.p_data = messageData
      globalFireBaseManager:checkSendFireBaseLog(messageData)
      self:sendLogData()
end

return  LogLevelDashActivity