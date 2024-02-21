
local PinBallGosLoadingMgr = class("PinBallGosLoadingMgr", BaseActivityControl)

function PinBallGosLoadingMgr:ctor()
    PinBallGosLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PinBallGoLoading)
end

-- function PinBallGosLoadingMgr:showPopLayer()
--     G_GetMgr(ACTIVITY_REF.ScratchCards):showMainLayer()
-- end

return PinBallGosLoadingMgr
