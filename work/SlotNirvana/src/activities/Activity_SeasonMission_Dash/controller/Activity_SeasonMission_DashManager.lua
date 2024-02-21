local Activity_SeasonMission_DashManager = class(" Activity_SeasonMission_DashManager", BaseActivityControl)

function Activity_SeasonMission_DashManager:ctor()
    Activity_SeasonMission_DashManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Activity_SeasonMission_Dash)
end

return Activity_SeasonMission_DashManager