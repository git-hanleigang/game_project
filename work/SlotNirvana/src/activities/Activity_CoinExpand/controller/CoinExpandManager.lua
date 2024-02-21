local CoinExpandManager = class("CoinExpandManager", BaseActivityControl)

function CoinExpandManager:ctor()
    CoinExpandManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinExpand_FreeCoin)
end


return CoinExpandManager