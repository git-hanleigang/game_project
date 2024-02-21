--[[
    集卡小猪 - 规则
]]
local ChipPiggyRuleMgr = class("ChipPiggyRuleMgr", BaseActivityControl)

function ChipPiggyRuleMgr:ctor()
    ChipPiggyRuleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChipPiggyRule)
end

function ChipPiggyRuleMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function ChipPiggyRuleMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function ChipPiggyRuleMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return ChipPiggyRuleMgr
