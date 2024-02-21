local LuckySpinSpecialManager = class("LuckySpinSpecialManager", BaseActivityControl)

function LuckySpinSpecialManager:ctor()
    LuckySpinSpecialManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckySpinSpecial)
end

return LuckySpinSpecialManager
