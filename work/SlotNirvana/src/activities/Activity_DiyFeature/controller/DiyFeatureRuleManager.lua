local DiyFeatureRuleManager = class("DiyFeatureRuleManager", BaseActivityControl)

function DiyFeatureRuleManager:ctor()
    DiyFeatureRuleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiyFeatureRule)
    self:addPreRef(ACTIVITY_REF.DiyFeature)
end

function DiyFeatureRuleManager:getPopName()
    return "Activity_DiyFeatureRuleSendLayer"
end

function DiyFeatureRuleManager:getPopPath(popName)
    return "Activity_DiyFeature_Rule/" .. popName
end

function DiyFeatureRuleManager:getRunningData(refName)
    local data = G_GetMgr(ACTIVITY_REF.DiyFeature):getRunningData()
    if not data or not data:isRunning() then
        return nil
    end
    return DiyFeatureRuleManager.super.getRunningData(self, refName)
end

return DiyFeatureRuleManager
