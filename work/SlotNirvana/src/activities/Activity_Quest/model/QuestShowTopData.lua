--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local BaseActivityData = require("baseActivity.BaseActivityData")
local QuestShowTopData = class("QuestShowTopData", BaseActivityData)

function QuestShowTopData:ctor()
    QuestShowTopData.super.ctor(self)
    self.p_open = true
end

function QuestShowTopData:isRunning()
    if not QuestShowTopData.super.isRunning(self) then
        return false
    end

    local questData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not questData or questData:isNewUserQuest() then
        return false
    end

    return true
end

return QuestShowTopData
