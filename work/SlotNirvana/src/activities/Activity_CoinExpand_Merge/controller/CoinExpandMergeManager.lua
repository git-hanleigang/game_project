local CoinExpandMergeManager = class(" CoinExpandMergeManager", BaseActivityControl)

function CoinExpandMergeManager:ctor()
    CoinExpandMergeManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinExpandMerge)
end

return CoinExpandMergeManager