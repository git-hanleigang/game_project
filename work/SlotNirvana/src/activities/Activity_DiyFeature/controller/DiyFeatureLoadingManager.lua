local DiyFeatureLoadingManager = class("DiyFeatureLoadingManager", BaseActivityControl)

function DiyFeatureLoadingManager:ctor()
    DiyFeatureLoadingManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiyFeatureLoading)
    self:addPreRef(ACTIVITY_REF.DiyFeature)
end

function DiyFeatureLoadingManager:getPopName()
    return "Activity_DiyFeatureSendLayer"
end

function DiyFeatureLoadingManager:getPopPath(popName)
    return "Activity_DiyFeature_Loading/" .. popName
end

function DiyFeatureLoadingManager:getRunningData(refName)
    local data = G_GetMgr(ACTIVITY_REF.DiyFeature):getRunningData()
    if not data or not data:isRunning() then
        return nil
    end
    return DiyFeatureLoadingManager.super.getRunningData(self, refName)
end

return DiyFeatureLoadingManager
