local NetworkLog = require "network.NetworkLog"
local LogSpinBonusActivity = class("LogSpinBonusActivity",NetworkLog)

function LogSpinBonusActivity:ctor()
      NetworkLog.ctor(self)
end

function LogSpinBonusActivity:sendSpinBonusPopupLog(pageName,entryTheme)
      if not globalData.spinBonusData then
            return
      end
      local reward = 0
      if globalData.spinBonusData.p_rewards and globalData.spinBonusData.p_rewards.p_coins then
            reward = globalData.spinBonusData.p_rewards.p_coins
      end

      local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
      local messageData = {
            activityName = globalData.spinBonusData.p_activityName,
            order = globalData.spinBonusData.p_totalFinishTimes,
            pageName = pageName,
            entryType = entryData.entryType,
            entryName = entryData.entryName,
            entryOpen = entryData.entryOpen,
            spinTimes = globalData.spinBonusData.p_target,
            entryTheme = entryTheme,
            rewardCoins = reward
      }
      self:sendSpinBonusActivityLog("SpinBounsPopup", messageData)
end

--发送log
function LogSpinBonusActivity:sendSpinBonusActivityLog(eventAction, messageData)
      if messageData == nil then
            messageData = {}
      end

      gL_logData:syncUserData()
      gL_logData:syncEventData(eventAction)
      gL_logData.p_data = messageData
      globalFireBaseManager:checkSendFireBaseLog(messageData)
      self:sendLogData()
end

return  LogSpinBonusActivity