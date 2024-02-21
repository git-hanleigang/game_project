--[[
    钻石小猪 - load宣传
]]
local GemPiggyLoadingMgr = class("GemPiggyLoadingMgr", BaseActivityControl)

function GemPiggyLoadingMgr:ctor()
    GemPiggyLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GemPiggyLoading)
end

function GemPiggyLoadingMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function GemPiggyLoadingMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function GemPiggyLoadingMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return GemPiggyLoadingMgr
