local CoinExpandStartManager = class(" CoinExpandStartManager", BaseActivityControl)

function CoinExpandStartManager:ctor()
    CoinExpandStartManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinExpandStart)
end

return CoinExpandStartManager