--[[
    钻石小猪 - 规则
]]
local GemPiggyRuleMgr = class("GemPiggyRuleMgr", BaseActivityControl)

function GemPiggyRuleMgr:ctor()
    GemPiggyRuleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GemPiggyRule)
end

function GemPiggyRuleMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function GemPiggyRuleMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function GemPiggyRuleMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return GemPiggyRuleMgr


