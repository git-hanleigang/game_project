--[[
    膨胀宣传 合成
]]
local BigBangMergeMgr = class("BigBangMergeMgr", BaseActivityControl)

function BigBangMergeMgr:ctor()
    BigBangMergeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BigBang_Merge)
end

function BigBangMergeMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function BigBangMergeMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function BigBangMergeMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return BigBangMergeMgr
