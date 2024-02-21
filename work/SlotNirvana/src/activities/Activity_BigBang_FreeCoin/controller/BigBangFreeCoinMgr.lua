--[[
    膨胀宣传 免费金币
]]
local BigBangFreeCoinMgr = class("BigBangFreeCoinMgr", BaseActivityControl)

function BigBangFreeCoinMgr:ctor()
    BigBangFreeCoinMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BigBang_FreeCoin)
end

function BigBangFreeCoinMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function BigBangFreeCoinMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function BigBangFreeCoinMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return BigBangFreeCoinMgr
