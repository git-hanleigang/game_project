local CoinExpandCashBonusManager = class(" CoinExpandCashBonusManager", BaseActivityControl)

function CoinExpandCashBonusManager:ctor()
    CoinExpandCashBonusManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinExpandCashBonus)
end

return CoinExpandCashBonusManager