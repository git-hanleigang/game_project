-- 字独数据管理器

local SlotTrialsNet = require("activities.Activity_SlotTrials.net.SlotTrialsNet")
local SlotTrialsManager = class("SlotTrialsManager", BaseActivityControl)

function SlotTrialsManager:ctor()
    SlotTrialsManager.super.ctor(self)

    self:setRefName(ACTIVITY_REF.SlotTrial)
    self.m_actNet = SlotTrialsNet:getInstance()

    self:addExtendResList("Activity_SlotTrials", "Activity_SlotTrialsCode", "Activity_SlotTrials_Theme")
end

-- function SlotTrialsManager:isDownloadLobbyRes()
--     -- 判断基础主题资源是否下载
--     if not self:isDownloadTheme("Activity_SlotTrials") then
--         return false
--     end

--     return SlotTrialsManager.super.isDownloadLobbyRes(self)
-- end

function SlotTrialsManager:showMainLayer()
    if not self:isCanShowLobbyLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_SlotTrials") then
        return
    end

    local ui_trials = util_createView("Activity.SlotTrials.Activity_SlotTrials")
    if not tolua.isnull(ui_trials) then
        return self:showLayer(ui_trials, ViewZorder.ZORDER_UI)
    end
end

function SlotTrialsManager:requestReward(taskIndex)
    local onSuccess = function(reward_data)
        self:setOnNetting(false)

        if not reward_data then
            return
        end
        local reward_layer = util_createView("Activity.SlotTrials.SlotTrialsRewardLayer", reward_data)
        if not tolua.isnull(reward_layer) then
            self:showLayer(reward_layer, ViewZorder.ZORDER_UI)
        end
    end
    local onFailed = function()
        self:setOnNetting(false)
    end
    self.m_actNet:requestReward(taskIndex, onSuccess, onFailed)
    self:setOnNetting(true)
end

function SlotTrialsManager:setOnNetting(bl_netting)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SLOT_TRIALS_REQUEST, {bl_netting = bl_netting})
end

function SlotTrialsManager:testOnComplete()
    -- local act_data = self:getRunningData()
    -- if act_data then
    --     act_data:onComplete(1)
    -- end
    -- self:showMainLayer()
end

function SlotTrialsManager:isDownloadTheme()
    return SlotTrialsManager.super.isDownloadTheme(self, "Activity_SlotTrials_Theme")
end

function SlotTrialsManager:getHallName()
    return self:getRefName()
end

function SlotTrialsManager:getSlideName()
    return self:getRefName()
end


return SlotTrialsManager
