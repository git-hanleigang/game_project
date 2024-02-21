local CoinExpandLoadingManager = class("CoinExpandLoadingManager", BaseActivityControl)

function CoinExpandLoadingManager:ctor()
    CoinExpandLoadingManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinExpandLoading)
end

return CoinExpandLoadingManager