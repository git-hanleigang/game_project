local MinzRuleMgr = class("MinzRuleMgr", BaseActivityControl)

function MinzRuleMgr:ctor()
    MinzRuleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.MinzRule)
end

function MinzRuleMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function MinzRuleMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function MinzRuleMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return MinzRuleMgr
