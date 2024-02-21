--[[
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local VipResetRuleData = class("VipResetRuleData", BaseActivityData)

function VipResetRuleData:ctor()
    VipResetRuleData.super.ctor(self)
    self:setOpenFlag(true)
end

return VipResetRuleData
