--[[
    3倍VIP点数
]]
local TripleVipMgr = class("TripleVipMgr", BaseActivityControl)

function TripleVipMgr:ctor()
    TripleVipMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TripleVip)
end

function TripleVipMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function TripleVipMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function TripleVipMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return TripleVipMgr
