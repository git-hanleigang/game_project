local CoinExpandPigManager = class(" CoinExpandPigManager", BaseActivityControl)

function CoinExpandPigManager:ctor()
    CoinExpandPigManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinExpandPig)
end

return CoinExpandPigManager