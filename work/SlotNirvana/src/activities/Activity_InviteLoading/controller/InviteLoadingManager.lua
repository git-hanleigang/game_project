
local InviteLoadingManager = class("InviteLoadingManager", BaseActivityControl)
function InviteLoadingManager:ctor()
    InviteLoadingManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.InviteLoading)
end

return InviteLoadingManager
