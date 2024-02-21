--[[
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local VipResetOpenData = class("VipResetOpenData", BaseActivityData)

function VipResetOpenData:ctor()
    VipResetOpenData.super.ctor(self)
    self:setOpenFlag(true)
end

return VipResetOpenData
