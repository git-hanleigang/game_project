local BaseActivityData = require("baseActivity.BaseActivityData")
local QuestNewSaleData = class("QuestNewSaleData", BaseActivityData)

function QuestNewSaleData:ctor()
    QuestNewSaleData.super.ctor(self)
    self.p_open = true
end

function QuestNewSaleData:isRunning()
    if not QuestNewSaleData.super.isRunning(self) then
        return false
    end

    local questData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if not questData or questData:isNewUserQuestNew() then
        return false
    end

    return true
end

return QuestNewSaleData