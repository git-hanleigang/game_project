--[[
    LevelDash
]]
local PromotionLevelDashMgr = class("PromotionLevelDashMgr", BaseActivityControl)

function PromotionLevelDashMgr:ctor()
    PromotionLevelDashMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LevelDash)

    self:addExtendResList("Activity_LevelDash", "Activity_LevelDash_Code")
end

return PromotionLevelDashMgr
