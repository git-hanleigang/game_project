--[[
    膨胀宣传 集卡
]]
local MonsterAlbumMgr = class("MonsterAlbumMgr", BaseActivityControl)

function MonsterAlbumMgr:ctor()
    MonsterAlbumMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Monster_Album)
end

function MonsterAlbumMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function MonsterAlbumMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function MonsterAlbumMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return MonsterAlbumMgr
