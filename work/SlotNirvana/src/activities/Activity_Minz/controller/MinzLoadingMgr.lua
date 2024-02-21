local MinzLoadingMgr = class("MinzLoadingMgr", BaseActivityControl)

function MinzLoadingMgr:ctor()
    MinzLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.MinzLoading)
end

function MinzLoadingMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function MinzLoadingMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function MinzLoadingMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return MinzLoadingMgr
