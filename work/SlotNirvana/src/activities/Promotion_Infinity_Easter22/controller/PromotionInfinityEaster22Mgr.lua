--[[
    控制类
]]
util_require("activities.Promotion_Infinity_Easter22.config.PromotionInfinityEaster22Config")
local PromotionInfinityEaster22Mgr = class("PromotionInfinityEaster22Mgr", BaseActivityControl)
function PromotionInfinityEaster22Mgr:ctor()
    PromotionInfinityEaster22Mgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.EasterEggInfinitySale)
end

return PromotionInfinityEaster22Mgr
