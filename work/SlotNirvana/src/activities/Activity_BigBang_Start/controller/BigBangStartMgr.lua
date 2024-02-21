--[[
    膨胀宣传 主图
]]
local BigBangStartMgr = class("BigBangStartMgr", BaseActivityControl)

function BigBangStartMgr:ctor()
    BigBangStartMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BigBang_Start)
end

function BigBangStartMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function BigBangStartMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function BigBangStartMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return BigBangStartMgr
