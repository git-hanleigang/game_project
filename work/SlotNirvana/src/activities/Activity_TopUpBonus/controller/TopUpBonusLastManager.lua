--[[
    
    author: csc
    time: 2021-10-31 16:17:33
    聚合挑战额外一颗星 manager
]]
local TopUpBonusLastManager = class("TopUpBonusLastManager", BaseActivityControl)

function TopUpBonusLastManager:ctor()
    TopUpBonusLastManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TopUpBonusLast)
    self:addPreRef(ACTIVITY_REF.TopUpBonus)
end

return TopUpBonusLastManager
