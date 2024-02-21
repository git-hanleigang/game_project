--[[
    集卡小猪 - load宣传
]]
local ChipPiggyLoadingMgr = class("ChipPiggyLoadingMgr", BaseActivityControl)

function ChipPiggyLoadingMgr:ctor()
    ChipPiggyLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChipPiggyLoading)
end

function ChipPiggyLoadingMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function ChipPiggyLoadingMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function ChipPiggyLoadingMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return ChipPiggyLoadingMgr
