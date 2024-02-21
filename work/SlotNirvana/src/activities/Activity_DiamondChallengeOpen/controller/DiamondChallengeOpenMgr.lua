
local DiamondChallengeOpenMgr = class("DiamondChallengeOpenMgr", BaseActivityControl)

function DiamondChallengeOpenMgr:ctor()
    DiamondChallengeOpenMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiamondChallengeClose)
end

return DiamondChallengeOpenMgr
