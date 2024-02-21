local Activity_FBVideoManager = class(" Activity_FBVideoManager", BaseActivityControl)

function Activity_FBVideoManager:ctor()
    Activity_FBVideoManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ActivityFBVideo)
end

return Activity_FBVideoManager