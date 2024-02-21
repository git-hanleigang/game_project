--[[
    膨胀宣传 集卡
]]
local BigBangAlbumMgr = class("BigBangAlbumMgr", BaseActivityControl)

function BigBangAlbumMgr:ctor()
    BigBangAlbumMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BigBang_Album)
end

function BigBangAlbumMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function BigBangAlbumMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function BigBangAlbumMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return BigBangAlbumMgr
