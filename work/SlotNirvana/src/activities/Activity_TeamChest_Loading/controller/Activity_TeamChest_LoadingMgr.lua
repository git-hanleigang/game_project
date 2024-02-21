--浇花系统宣传图
local Activity_TeamChest_LoadingMgr = class("Activity_TeamChest_LoadingMgr", BaseActivityControl)

function Activity_TeamChest_LoadingMgr:ctor()
    Activity_TeamChest_LoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TeamChestLoading)
end

function Activity_TeamChest_LoadingMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function Activity_TeamChest_LoadingMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function Activity_TeamChest_LoadingMgr:getPopPath(popName)
    return "Activity_TeamChest_Loading" .. "/" .. popName
end

return Activity_TeamChest_LoadingMgr
