--[[

    author:{author}
    time:2021-09-28 14:22:08
]]
local CardEndSpecialMgr = class("CardEndSpecialMgr", BaseActivityControl)

function CardEndSpecialMgr:ctor()
    CardEndSpecialMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CardEndSpecial)
end

function CardEndSpecialMgr:getPopPath(popName)
    return "Activity/" .. popName
end

return CardEndSpecialMgr
