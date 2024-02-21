--[[
    钻石小猪 - 倒计时
]]
local GemPiggyCountDownMgr = class("GemPiggyCountDownMgr", BaseActivityControl)

function GemPiggyCountDownMgr:ctor()
    GemPiggyCountDownMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GemPiggyCountDown)
end

function GemPiggyCountDownMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function GemPiggyCountDownMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function GemPiggyCountDownMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return GemPiggyCountDownMgr
