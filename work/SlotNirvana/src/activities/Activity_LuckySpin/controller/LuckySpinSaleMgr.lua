--[[
    SuperSpin奖励活动
--]]
local LuckySpinSaleMgr = class("LuckySpinSaleMgr", BaseActivityControl)

function LuckySpinSaleMgr:ctor()
    LuckySpinSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckySpinSale)
end

return LuckySpinSaleMgr
