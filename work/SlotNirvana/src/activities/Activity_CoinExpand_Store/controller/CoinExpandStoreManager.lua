local CoinExpandStoreManager = class(" CoinExpandStoreManager", BaseActivityControl)

function CoinExpandStoreManager:ctor()
    CoinExpandStoreManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinExpand_Store)
end

return CoinExpandStoreManager