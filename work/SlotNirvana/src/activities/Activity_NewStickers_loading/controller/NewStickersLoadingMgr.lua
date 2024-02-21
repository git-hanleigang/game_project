--[[
    公会表情宣传
]]
local NewStickersLoadingMgr = class("NewStickersLoadingMgr", BaseActivityControl)

function NewStickersLoadingMgr:ctor()
    NewStickersLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewStickersLoading)
end

function NewStickersLoadingMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function NewStickersLoadingMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function NewStickersLoadingMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return NewStickersLoadingMgr
