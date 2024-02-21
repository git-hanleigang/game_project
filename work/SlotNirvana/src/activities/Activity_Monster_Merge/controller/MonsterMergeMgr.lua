--[[
    膨胀宣传 合成
]]
local MonsterMergeMgr = class("MonsterMergeMgr", BaseActivityControl)

function MonsterMergeMgr:ctor()
    MonsterMergeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Monster_Merge)
end

function MonsterMergeMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function MonsterMergeMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function MonsterMergeMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return MonsterMergeMgr
