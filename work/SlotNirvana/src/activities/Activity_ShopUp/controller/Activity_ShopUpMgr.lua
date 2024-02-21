
local Activity_ShopUpMgr = class("Activity_ShopUpMgr", BaseActivityControl)

function Activity_ShopUpMgr:ctor()
    Activity_ShopUpMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ShopUp)
end

function Activity_ShopUpMgr:getPopPath(popName)
    return "Activity_ShopUp/" .. popName
end

return Activity_ShopUpMgr
