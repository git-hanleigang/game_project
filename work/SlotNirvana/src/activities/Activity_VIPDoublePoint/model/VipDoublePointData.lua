--[[
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local VipDoublePointData = class("VipDoublePointData", BaseActivityData)

function VipDoublePointData:ctor()
    VipDoublePointData.super.ctor(self)
    self:setOpenFlag(true)
end

return VipDoublePointData
