--[[
    LuckySpinUpgrade
--]]
local LuckySpinUpgradeMgr = class("LuckySpinUpgradeMgr", BaseActivityControl)

function LuckySpinUpgradeMgr:ctor()
    LuckySpinUpgradeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckySpinUpgrade)
end

return LuckySpinUpgradeMgr
