--
-- quest活动打点
-- Author:{author}
-- Date: 2019-06-24 21:40:00
--
local LogQuestActivity = require "log.LogQuestActivity"
local LogQuestNewUserActivity = class("LogQuestNewUserActivity", LogQuestActivity)
function LogQuestNewUserActivity:getConfigData()
    local _data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if _data and _data:isNewUserQuest() then
        return _data
    else
        return nil
    end
end
function LogQuestNewUserActivity:isNewUserQuest()
    return true
end
return LogQuestNewUserActivity
