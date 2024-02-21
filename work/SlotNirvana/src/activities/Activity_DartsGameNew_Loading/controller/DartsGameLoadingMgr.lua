local DartsGameLoadingMgr = class(" DartsGameLoadingMgr", BaseActivityControl)

function DartsGameLoadingMgr:ctor()
    DartsGameLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DartsGameNewLoading)
end

return DartsGameLoadingMgr