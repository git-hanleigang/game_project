--[[

    author:{author}
    time:2021-09-28 14:22:08
]]
local CardsOneKeyRecoverMgr = class("CardsOneKeyRecoverMgr", BaseActivityControl)

function CardsOneKeyRecoverMgr:ctor()
    CardsOneKeyRecoverMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CardsOneKeyRecover)
end

return CardsOneKeyRecoverMgr
