--
-- 新quest活动打点   梦幻Quest 
-- Author:{author}
-- 2022 -12-20
--
local NetworkLog = require "network.NetworkLog"
local LogQuestNewActivity = class("LogQuestNewActivity", NetworkLog)
LogQuestNewActivity.m_entry_site = "loginLobbyPush"
function LogQuestNewActivity:ctor()
    NetworkLog.ctor(self)
end
--暂时保留防止第一次热更不同步报错
function LogQuestNewActivity:initData()
end
function LogQuestNewActivity:clearCount()
end
function LogQuestNewActivity:checkFristEnter()
end
function LogQuestNewActivity:setActivityData()
end
function LogQuestNewActivity:checkCompletedTask()
end
function LogQuestNewActivity:updateEnterLevelCount()
end
function LogQuestNewActivity:updateSpinCount()
end
function LogQuestNewActivity:updateWinCoins()
end
function LogQuestNewActivity:updateBetCoins()
end
function LogQuestNewActivity:sendQuestTaskLog()
end
function LogQuestNewActivity:sendQuestAwardLog()
end
function LogQuestNewActivity:sendQuestRankLog()
end
function LogQuestNewActivity:sendQuestEmailLog()
end
--
function LogQuestNewActivity:sendLogMessage(...)
    local args = {...}
    --TODO 在这里组织你感兴趣的数据
    NetworkLog.sendLogData(self)
end
function LogQuestNewActivity:getConfigData()
    return G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
end

--进入位置
function LogQuestNewActivity:sendQuestEntrySite(entry_Site)
    self.m_entry_site = entry_Site
end
function LogQuestNewActivity:getQuestEntrySite()
    return self.m_entry_site
end

function LogQuestNewActivity:sendQuestUILog(uiName, clickType, themeName)
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
    messageData["name"] = "FantasyQuest" .. self:formatActivityTime(questConfig.p_start)
    local starTimer = util_getymd_time(questConfig.p_start)
    messageData["day"] = util_daysforstart(starTimer)
    messageData["s"] = questConfig.p_round
    messageData["cr"] = questConfig:getCurrentChapterID()
    messageData["rd"] = questConfig:getStageIdx() or 1
    gL_logData.p_data = messageData
    globalFireBaseManager:checkSendFireBaseLog(messageData)
    self:sendLogData()
end
function LogQuestNewActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end
function LogQuestNewActivity:getEnterName()
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

return LogQuestNewActivity
