local Activity_DartsGame_LoadingManager = class(" Activity_DartsGame_LoadingManager", BaseActivityControl)

function Activity_DartsGame_LoadingManager:ctor()
    Activity_DartsGame_LoadingManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Activity_DartsGame_Loading)
end

return Activity_DartsGame_LoadingManager