--[[
    集卡小猪 - 倒计时
]]
local ChipPiggyCountDownMgr = class("ChipPiggyCountDownMgr", BaseActivityControl)

function ChipPiggyCountDownMgr:ctor()
    ChipPiggyCountDownMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChipPiggyCountDown)
end

function ChipPiggyCountDownMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function ChipPiggyCountDownMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function ChipPiggyCountDownMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return ChipPiggyCountDownMgr
