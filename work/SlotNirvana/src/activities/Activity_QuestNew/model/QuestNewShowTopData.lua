--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local BaseActivityData = require("baseActivity.BaseActivityData")
local QuestNewShowTopData = class("QuestNewShowTopData", BaseActivityData)

function QuestNewShowTopData:ctor()
    QuestNewShowTopData.super.ctor(self)
    self.p_open = true
end

function QuestNewShowTopData:isRunning()
    if not QuestNewShowTopData.super.isRunning(self) then
        return false
    end

    local questData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if not questData then
        return false
    end

    return true
end

return QuestNewShowTopData
