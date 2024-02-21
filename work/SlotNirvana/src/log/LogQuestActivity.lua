--
-- quest活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local NetworkLog = require "network.NetworkLog"
local LogQuestActivity = class("LogQuestActivity", NetworkLog)
LogQuestActivity.m_entry_site = "loginLobbyPush"
function LogQuestActivity:ctor()
    NetworkLog.ctor(self)
end
--暂时保留防止第一次热更不同步报错
function LogQuestActivity:initData()
end
function LogQuestActivity:clearCount()
end
function LogQuestActivity:checkFristEnter()
end
function LogQuestActivity:setActivityData()
end
function LogQuestActivity:checkCompletedTask()
end
function LogQuestActivity:updateEnterLevelCount()
end
function LogQuestActivity:updateSpinCount()
end
function LogQuestActivity:updateWinCoins()
end
function LogQuestActivity:updateBetCoins()
end
function LogQuestActivity:sendQuestTaskLog()
end
function LogQuestActivity:sendQuestAwardLog()
end
function LogQuestActivity:sendQuestRankLog()
end
function LogQuestActivity:sendQuestEmailLog()
end
--
function LogQuestActivity:sendLogMessage(...)
    local args = {...}
    --TODO 在这里组织你感兴趣的数据
    NetworkLog.sendLogData(self)
end
function LogQuestActivity:getConfigData()
    return G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end
function LogQuestActivity:isNewUserQuest()
    return false
end
--进入位置
function LogQuestActivity:sendQuestEntrySite(entry_Site)
    self.m_entry_site = entry_Site
end
function LogQuestActivity:getQuestEntrySite()
    return self.m_entry_site
end

function LogQuestActivity:sendQuestUILog(uiName, clickType, themeName)
    local questConfig = self:getConfigData()
    if questConfig == nil then
        return
    end
    gL_logData:syncUserData()

    local _themeName = "QuestPage"
    if themeName and string.len(themeName) > 0 then
        _themeName = themeName
    end
    gL_logData:syncEventData(_themeName)
    local messageData = {}
    messageData.pn = uiName
    messageData.tp = clickType
    local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
    messageData.et = entryData.entryType
    messageData.en = self.m_entry_site
    messageData.eo = self:getEnterName()
    if self:isNewUserQuest() then
        messageData["name"] = "NewUserQuest"
        messageData["day"] = math.ceil(questConfig.p_expire / 86400)
    else
        messageData["name"] = "Quest" .. self:formatActivityTime(questConfig.p_start)
        local starTimer = util_getymd_time(questConfig.p_start)
        messageData["day"] = util_daysforstart(starTimer)
    end
    messageData["s"] = questConfig.p_round
    messageData["cr"] = questConfig:getPhaseIdx()
    messageData["rd"] = questConfig:getStageIdx() or 1
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end
function LogQuestActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end
function LogQuestActivity:getEnterName()
    if self.m_entry_site == "loginLobbyPush" then
        return "PushOpen"
    elseif self.m_entry_site == "lobbyCarousel" then
        return "tapOpen"
    elseif self.m_entry_site == "lobbyDisplay" then
        return "tapOpen"
    elseif self.m_entry_site == "lobbyActivityIcon" then
        return "tapOpen"
    elseif self.m_entry_site == "gameBackLobby" then
        return "PushOpen"
    elseif self.m_entry_site == "gameLevelUpPush" then
        return "PushOpen"
    elseif self.m_entry_site == "questRushToQuestMain" or self.m_entry_site == "pushViewToQuestMain" or self.m_entry_site == "topActToQuestMain" then
        -- quest相关活动 活动点击打开quest
        return "tapOpen"
    else
        return "PushOpen"
    end
end

return LogQuestActivity
